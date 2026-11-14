extends Node3D
## A playable operation: builds the map from LevelData, spawns the player,
## tracks objectives, handles pause, and reports the result to Main.

signal finished(success: bool, stats: Dictionary)
signal request_restart
signal request_menu

const Player = preload("res://scripts/player.gd")
const Enemy = preload("res://scripts/enemy.gd")
const Target = preload("res://scripts/target.gd")
const Pickup = preload("res://scripts/pickup.gd")
const HUD = preload("res://scripts/hud.gd")
const LevelData = preload("res://scripts/level_data.gd")
const Fx = preload("res://scripts/fx.gd")
const UI = preload("res://scripts/ui_util.gd")
const Barrel = preload("res://scripts/barrel.gd")
const Vehicle = preload("res://scripts/vehicle.gd")
const NetSync = preload("res://scripts/net_sync.gd")
const RemotePlayer = preload("res://scripts/remote_player.gd")
const Squadmate = preload("res://scripts/squadmate.gd")
const Meltdown = preload("res://scripts/meltdown.gd")
const TouchControls = preload("res://scripts/touch_controls.gd")
const Rocket = preload("res://scripts/rocket.gd")
const Grenade = preload("res://scripts/grenade.gd")
const DroneStrike = preload("res://scripts/drone_strike.gd")
const RESPAWN_TIME := 8.0

var level_index := 0
var info: Dictionary = {}
var player
var hud
var objectives: Array = []
var obj_index := 0
var enemies: Array = []
var vehicles: Array = []
var enemy_vehicles: Array = []   # Tan Army jeeps and tanks (AI)
var props: Array = []          # every model placed with prop(): {node, path}
var targets: Array = []        # in build order: the same index means the same target on every PC
var barrels: Array = []
var pickups := {}              # id -> Pickup
var _next_pickup_id := 0
var net = null                 # NetSync in a LAN game, else null
var remotes := {}              # peer id -> RemotePlayer (teammates)
var squad: Array = []          # friendly AI squadmates (single-player)
var squad_hold := false
var mode = null                # MELTDOWN controller in wave-survival mode
var spawn_point := Vector3.ZERO
# Safe zone around the start: Tan forces won't target, hurt or enter it.
const SAFE_EXPOSE_MS := 3000      # firing from inside exposes you for this long
var safe_center := Vector3.ZERO
var safe_radius := 0.0
var _respawn_t := 0.0
var hvts: Array = []
var reserves: Array = []       # Tan troops held back until a "defend" objective starts
var targets_by_tag := {}
var last_notice := ""            # most recent on-screen message (tests read it)
var _obj_start := 0.0          # elapsed time when the current objective began
var _rally_t := 0.0
var extraction: Node3D
var elapsed := 0.0
var kills := 0
var headshots := 0
var ended := false
var pause_layer: CanvasLayer
var _boom_t := 12.0
var _mats := {}
static var _scenes := {}


func _ready() -> void:
    Game.current_level = self
    info = LevelData.build(level_index, self)
    _apply_progression()
    if _ground_spec != null:
        _build_terrain()
    _build_environment()
    optimize_static()
    player = Player.new()
    player.level = self
    spawn_point = info["spawn"]
    safe_center = info["spawn"]
    safe_radius = info.get("safe_radius", 22.0)
    _build_safe_zone()
    if Net.active:
        # Spread the squad out a little at the start point.
        spawn_point += Vector3(2.5 * (Net.my_slot() - 1.5), 0, 0).rotated(Vector3.UP, info.get("spawn_yaw", 0.0))
    player.position = spawn_point
    player.rotation.y = info.get("spawn_yaw", 0.0)
    var start: Array = info.get("start_weapons", ["carbine", "shotgun"])
    for w in start:
        player.owned[w] = true
    player.drones = info.get("drones", 1)
    add_child(player)
    player.died.connect(_on_player_died)
    if info.get("snow", false):
        _add_snowfall()
    hud = HUD.new()
    add_child(hud)
    get_tree().create_timer(0.4).timeout.connect(_prewarm_fx)
    var touch = TouchControls.new()
    touch.setup(self)
    add_child(touch)
    hud.bind(player, self)
    objectives = info["objectives"]
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    if Net.active:
        _setup_net()
    else:
        _spawn_squad(Game.squad_size)
    if info.get("mode", "") == "meltdown":
        mode = Meltdown.new()
        mode.setup(self, info["meltdown"])
        add_child(mode)
    else:
        _begin_objective(0)
    notify(info["name"].to_upper(), 3.5)
    Game.play_music(info.get("music", ""), -8.0)
    Game.play_ambience(info.get("ambience", ""), info.get("ambience_db", -12.0))
    Game.play_ui("radio", -8.0)


func _exit_tree() -> void:
    if Game.current_level == self:
        Game.current_level = null
        Game.stop_ambience()


func is_playing() -> bool:
    return not ended and player != null and player.alive


## True on the PC that runs the simulation (single-player, or the LAN host).
func is_server() -> bool:
    return net == null or multiplayer.is_server()


# ------------------------------------------------------------- LAN co-op ----

func _setup_net() -> void:
    net = NetSync.new(self)
    add_child(net)
    if multiplayer.is_server():
        # Hold the Tan Army until everyone has loaded the map.
        for e in enemies + enemy_vehicles:
            e.set_physics_process(false)
    else:
        # Everything but our own soldier is driven by the host's snapshots.
        for e in enemies:
            e.net_puppet = true
        for v in enemy_vehicles + vehicles:
            v.net_puppet = true
        for b in barrels:
            b.net_puppet = true
        for t in targets:
            t.net_puppet = true
    hud.show_team = true


## Names a hittable thing the same way on every PC: [list, index].
func ref_of(n) -> Array:
    if n == null:
        return []
    if mode != null and n.get("net_id") != null and n.net_id > 0:
        return ["m", n.net_id]          # MELTDOWN: Melties by id (lists differ between PCs)
    for pair in [["e", enemies], ["ev", enemy_vehicles], ["v", vehicles], ["t", targets], ["b", barrels]]:
        var i: int = pair[1].find(n)
        if i >= 0:
            return [pair[0], i]
    return []


func node_of(ref: Array):
    if ref.size() != 2:
        return null
    if ref[0] == "m":
        return mode.melties.get(int(ref[1])) if mode != null else null
    var list: Array = {"e": enemies, "ev": enemy_vehicles, "v": vehicles, "t": targets, "b": barrels}.get(ref[0], [])
    var i: int = ref[1]
    if i < 0 or i >= list.size() or not is_instance_valid(list[i]):
        return null
    return list[i]


func net_go() -> void:
    if multiplayer.is_server():
        for e in enemies + enemy_vehicles:
            if is_instance_valid(e) and e.alive:
                e.set_physics_process(true)


## Everyone the Tan Army can shoot at (host only): us plus living teammates
## who aren't sheltering in the safe zone.
func ai_targets() -> Array:
    var out: Array = []
    if player != null and is_instance_valid(player) and player.alive and not is_protected(player):
        out.append(player)
    for r in remotes.values():
        if r.alive and not is_protected(r):
            out.append(r)
    return out


func in_safe_zone(pos: Vector3) -> bool:
    return safe_radius > 0.0 and Vector2(pos.x - safe_center.x, pos.z - safe_center.z).length() < safe_radius


## Inside the safe zone and hasn't fired in the last few seconds.
func is_protected(n) -> bool:
    if n == null or not is_instance_valid(n):
        return false
    var who = n
    if n.get("driver") != null:
        who = n.driver
    var last: int = who.get("last_fire_ms") if who.get("last_fire_ms") != null else -100000
    return in_safe_zone(n.global_position) and Time.get_ticks_msec() - last > SAFE_EXPOSE_MS


## Keeps a Tan destination out of the safe zone (moves it to just outside the edge).
func outside_safe_zone(dest: Vector3, from: Vector3) -> Vector3:
    if not in_safe_zone(dest):
        return dest
    var d := dest - safe_center
    d.y = 0.0
    if d.length() < 0.5:
        d = from - safe_center
        d.y = 0.0
    return safe_center + d.normalized() * (safe_radius + 6.0) + Vector3(0, dest.y - safe_center.y, 0)


func _build_safe_zone() -> void:
    if safe_radius <= 0.0:
        return
    var root := Node3D.new()
    root.name = "SafeZone"
    root.position = Vector3(safe_center.x, 0.0, safe_center.z)
    add_child(root)
    var ring := MeshInstance3D.new()
    var tm := TorusMesh.new()
    tm.inner_radius = safe_radius - 0.25
    tm.outer_radius = safe_radius
    tm.rings = 96
    ring.mesh = tm
    ring.material_override = Fx.unlit(Color(0.4, 1.0, 0.45, 0.55))
    ring.position.y = 0.08
    root.add_child(ring)
    var wall := MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.top_radius = safe_radius
    cm.bottom_radius = safe_radius
    cm.height = 2.2
    cm.cap_top = false
    cm.cap_bottom = false
    cm.radial_segments = 96
    wall.mesh = cm
    var wm := Fx.unlit(Color(0.4, 1.0, 0.45, 0.07))
    wm.cull_mode = BaseMaterial3D.CULL_DISABLED
    wall.material_override = wm
    wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    wall.position.y = 1.1
    root.add_child(wall)
    var lbl := Label3D.new()
    lbl.text = "SAFE ZONE"
    lbl.font_size = 72
    lbl.pixel_size = 0.01
    lbl.outline_size = 12
    lbl.modulate = Color(0.55, 1.0, 0.55, 0.85)
    lbl.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
    var fwd := Vector3(0, 0, -1).rotated(Vector3.UP, info.get("spawn_yaw", 0.0))
    lbl.position = fwd * safe_radius + Vector3(0, 2.8, 0)
    root.add_child(lbl)


func _spawn_squad(n: int) -> void:
    for i in clampi(n, 0, Squadmate.SLOTS.size()):
        var m = Squadmate.new()
        var off: Vector3 = Squadmate.SLOTS[i].rotated(Vector3.UP, info.get("spawn_yaw", 0.0))
        m.setup(self, i, spawn_point + off)
        add_child(m)
        squad.append(m)


## T: squad holds where they stand, or comes back to follow you.
func toggle_squad_order() -> void:
    if squad.is_empty() or not is_playing():
        return
    squad_hold = not squad_hold
    for m in squad:
        m.set_hold(squad_hold)
    notify("SQUAD: HOLD THIS POSITION" if squad_hold else "SQUAD: ON ME", 1.8)
    Game.play_ui("radio", -8.0)


func nearest_ai_target(pos: Vector3):
    # (ai_targets already leaves out anyone protected by the safe zone)
    var best = null
    var best_d := INF
    var cands := ai_targets()
    for m in squad:
        if m.alive and m.ride == null and not is_protected(m):
            cands.append(m)
    for t in cands:
        var d: float = t.global_position.distance_to(pos)
        if d < best_d:
            best_d = d
            best = t
    return best


func remote_state(id: int, d: PackedFloat32Array, vd: PackedFloat32Array) -> void:
    if not Net.players.has(id) or ended and not remotes.has(id):
        return
    var r = remotes.get(id)
    if r == null:
        r = RemotePlayer.new()
        r.setup(self, id, Vector3(d[0], d[1], d[2]))
        add_child(r)
        remotes[id] = r
    r.apply_state(d)
    var vi := int(d[10])
    if vi >= 0 and vi < vehicles.size() and vd.size() >= 7:
        vehicles[vi].net_drive_apply(vd)


func net_peer_left(id: int, who: String) -> void:
    var r = remotes.get(id)
    if r:
        r.queue_free()
        remotes.erase(id)
    for i in vehicles.size():
        if vehicles[i].occupant_peer == id:
            net_set_occupant(i, 0)
    notify("%s LEFT THE GAME" % who.to_upper(), 2.5)


func net_set_occupant(vi: int, peer: int) -> void:
    if vi < 0 or vi >= vehicles.size():
        return
    var v = vehicles[vi]
    var mine: bool = peer != 0 and peer == multiplayer.get_unique_id()
    if mine and player.vehicle == null and player.alive:
        v.occupant_peer = 0          # free while we climb in (can_enter checks it)
        v.enter(player)
    v.occupant_peer = peer
    # Whoever drives a vehicle simulates it; everyone else follows its state.
    var host: bool = multiplayer.is_server()
    if mine:
        v.net_puppet = false
    elif peer != 0:
        v.net_puppet = true
    else:
        v.net_puppet = not host


func net_objective(i: int) -> void:
    if i != obj_index:
        Game.play_ui("objective")
        _begin_objective(i)


func net_mission_end(success: bool, stats: Dictionary) -> void:
    if ended and get_meta("net_end_done", false):
        return
    set_meta("net_end_done", true)
    ended = true
    player.invulnerable = true
    notify("MISSION ACCOMPLISHED" if success else "SQUAD MELTED.  MISSION FAILED", 3.0)
    if not success:
        Game.play_ui("fail")
    var s := stats.duplicate()
    if player.shots_fired > 0:
        s["accuracy"] = float(player.shots_hit) / float(player.shots_fired) * 100.0
    var t := get_tree().create_timer(2.5)
    t.timeout.connect(func():
        if is_inside_tree():
            finished.emit(success, s))


func net_squad_wiped() -> void:
    if multiplayer.is_server() and not ended:
        net.mission_end(false, _stats())


## Effects for an explosion on this PC only.
func boom_local(pos: Vector3, radius: float, db := 0.0) -> void:
    Fx.explosion(self, pos, radius)
    _scorch(pos, radius)
    Game.play_sfx("explosion", pos, db)
    if player and is_instance_valid(player):
        var pd: float = player.global_position.distance_to(pos)
        player.shake = maxf(player.shake, clampf(1.3 - pd / 30.0, 0.0, 1.3))


# ------------------------------------------------- bullet holes and scorch ----
# Marks painted where shots and blasts land on fixed scenery (walls, ground,
# buildings): chipped bullet holes and sooty scorch (the looks picked from the
# mockups; surface_mark.gdshader draws them, no textures). Never on anything
# that moves - a mark there would be left floating. Capped in number and faded
# out after a while, so long fights don't get slower.

const MarkShader = preload("res://assets/shaders/surface_mark.gdshader")
const MAX_HOLES := 48
const MAX_SCORCH := 10
const MARK_LIFE := 40.0
var _holes: Array = []
var _scorches: Array = []


func bullet_mark(hit: Dictionary) -> void:
    if hit.is_empty() or not _marks_on(hit.get("collider")):
        return
    _add_mark(0, hit["position"], hit["normal"], randf_range(0.22, 0.3), _surface_color(hit["collider"]), _holes, MAX_HOLES)


func _scorch(pos: Vector3, radius: float) -> void:
    var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
    var q := PhysicsRayQueryParameters3D.create(pos + Vector3(0, 0.6, 0), pos + Vector3(0, -radius * 0.6, 0), 1)
    var h: Dictionary = space.intersect_ray(q)
    if h.is_empty() or not _marks_on(h["collider"]) or h["normal"].y < 0.6:
        return
    _add_mark(2, h["position"], h["normal"], clampf(radius * 0.8, 1.5, 5.0), _surface_color(h["collider"]), _scorches, MAX_SCORCH)


## Fixed scenery only: static bodies and the terrain, not soldiers, vehicles,
## barrels, targets or pickups (they move, break or have their own damage look).
func _marks_on(c) -> bool:
    return c != null and is_instance_valid(c) and c is StaticBody3D and c.get_script() == null


func _surface_color(c: Node) -> Color:
    for ch in c.get_children():
        if ch is MeshInstance3D:
            var m = ch.material_override
            if m is StandardMaterial3D:
                var col: Color = m.albedo_color
                # A textured surface's colour is only a tint (near white): guess darker.
                return col * 0.6 if m.albedo_texture != null or col.get_luminance() > 0.9 else col
    return Color(0.6, 0.58, 0.55)


func _add_mark(kind: int, pos: Vector3, normal: Vector3, size: float, col: Color, pool: Array, cap: int) -> void:
    var mi := MeshInstance3D.new()
    var qm := QuadMesh.new()
    qm.size = Vector2(size, size)
    mi.mesh = qm
    var m := ShaderMaterial.new()
    m.shader = MarkShader
    m.set_shader_parameter("kind", kind)
    m.set_shader_parameter("seed", randf() * 10.0)
    m.set_shader_parameter("surface_color", col)
    mi.material_override = m
    mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    mi.visibility_range_end = 70.0 if kind == 0 else 140.0
    add_child(mi)
    mi.global_position = pos + normal * (0.012 if kind == 0 else 0.03)
    var up := Vector3.UP if absf(normal.dot(Vector3.UP)) < 0.9 else Vector3.FORWARD
    mi.look_at(mi.global_position - normal, up)
    mi.rotate_object_local(Vector3.FORWARD, randf() * TAU)
    pool.append(mi)
    if pool.size() > cap:
        var old = pool.pop_front()
        if is_instance_valid(old):
            old.queue_free()
    var tw := mi.create_tween()
    tw.tween_interval(MARK_LIFE)
    tw.tween_method(func(f: float): m.set_shader_parameter("fade", f), 1.0, 0.0, 3.0)
    tw.tween_callback(func():
        pool.erase(mi)
        mi.queue_free())


## Marks on the map right now (tests read it).
func mark_count() -> int:
    return _holes.size() + _scorches.size()


## Explosion effects on every PC (call where the damage is decided).
func boom(pos: Vector3, radius: float, db := 0.0) -> void:
    if net != null and multiplayer.is_server():
        net.boom(pos, radius, db)
    else:
        boom_local(pos, radius, db)


## Spawns a rocket/grenade/drone strike. visual = harmless copy for display.
func spawn_projectile(kind: String, pos: Vector3, dir: Vector3, a: float, b: float, c: float, visual: bool, shooter) -> Node:
    match kind:
        "rocket":
            var r = Rocket.new()
            r.setup(shooter, self, pos, dir, a, b)
            if c > 0.0:
                r.speed = c
            r.visual_only = visual
            add_child(r)
            return r
        "grenade":
            var g = Grenade.new()
            g.setup(self)
            g.visual_only = visual
            add_child(g)
            g.global_position = pos
            g.linear_velocity = dir
            g.angular_velocity = Vector3(randf(), randf(), randf()) * 8.0
            return g
        "drone":
            var d = DroneStrike.new()
            d.setup(self, pos)
            d.visual_only = visual
            add_child(d)
            return d
    return null


# ---------------------------------------------------------- environment ----

func _build_environment() -> void:
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sm := ProceduralSkyMaterial.new()
    sm.sky_top_color = info["sky_top"]
    sm.sky_horizon_color = info["sky_horizon"]
    sm.ground_horizon_color = info["sky_horizon"]
    sm.ground_bottom_color = info["sky_horizon"].darkened(0.5)
    sky.sky_material = sm
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.ambient_light_energy = info.get("ambient", 0.9)
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.tonemap_exposure = info.get("exposure", 1.0)
    env.glow_enabled = true
    env.glow_intensity = 0.6
    env.ssao_enabled = true
    var fog: float = info.get("fog", 0.0)
    if fog > 0.0:
        env.fog_enabled = true
        env.fog_density = fog
        env.fog_light_color = info["sky_horizon"]
        env.fog_aerial_perspective = 0.4
    var we := WorldEnvironment.new()
    we.environment = env
    add_child(we)
    _env = env
    var sun := DirectionalLight3D.new()
    _sun = sun
    sun.rotation_degrees = info.get("sun_rot", Vector3(-50, 35, 0))
    sun.light_color = info.get("sun_color", Color(1, 0.96, 0.88))
    sun.light_energy = info.get("sun_energy", 1.2)
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 140.0
    add_child(sun)
    apply_graphics()


var _env: Environment
var _sun: DirectionalLight3D


## Graphics quality (Settings): the expensive screen effects and shadow range.
func apply_graphics() -> void:
    if _env == null:
        return
    var q: int = Game.graphics
    _env.ssao_enabled = q >= 2
    _env.glow_enabled = q >= 1
    _sun.directional_shadow_max_distance = [55.0, 100.0, 140.0][q]
    _sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL if q == 0 else DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS


# ------------------------------------------------------ builder helpers ----

## Plays one of every effect hidden under the ground in front of the camera,
## while the level title is up. On desktop graphics, the first time an effect
## is drawn its shaders get prepared on the spot (a hitch mid-firefight);
## this gets that done up front.
var fx_prewarmed := false


func _prewarm_fx() -> void:
    if not is_inside_tree():
        return
    var cam := get_viewport().get_camera_3d()
    if cam == null:
        return
    var p := cam.global_position - cam.global_transform.basis.z * 6.0 + Vector3(0, -6.0, 0)
    Fx.explosion(self, p, 2.0)
    Fx.die_down(Fx.fire(self, p, 0.5, 0.0), 0.5)
    Fx.puff(self, p, Color(0.8, 0.8, 0.8, 0.5), 0.5, 0.3)
    Fx.tracer(self, p, p + Vector3(0, 0, 2), Color(1.0, 0.45, 0.3))
    Fx.muzzle_flash(self, cam.global_position - cam.global_transform.basis.z * 2.0 + Vector3(0, -3.0, 0))
    fx_prewarmed = true


## Cheaper rendering for the level's fixed scenery (not soldiers, vehicles,
## targets or pickups, which have scripts). Every mesh is drawn once for the
## camera and again for each shadow split, so:
##  - flat pieces (road paint, rugs, floor slabs) don't cast shadows nobody
##    could see;
##  - small props stop drawing (and shadowing) once they're far enough away to
##    be a few pixels.
## Returns how many meshes were changed (tests read it).
func optimize_static() -> int:
    var changed := 0
    for g in find_children("*", "MeshInstance3D", true, false):
        var mi: MeshInstance3D = g
        if mi.mesh == null or _is_dynamic(mi):
            continue
        var ab: AABB = mi.global_transform * mi.get_aabb()
        var longest: float = maxf(ab.size.x, maxf(ab.size.y, ab.size.z))
        var hit := false
        if ab.size.y < 0.15:
            mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
            hit = true
        var reach := 0.0
        if longest < 1.2:
            reach = 55.0
        elif longest < 3.5:
            reach = 95.0
        elif ab.size.y < 0.15 and longest < 6.0:
            reach = 80.0
        if reach > 0.0:
            mi.visibility_range_end = reach
            mi.visibility_range_end_margin = 4.0
            hit = true
        if hit:
            changed += 1
    return changed


## Soldiers and vehicles further than this from the camera stop casting
## shadows (they're still drawn): each shadow costs a draw per shadow split,
## and from that far away it's a dot nobody can see.
const SHADOW_REACH := 45.0
var _shadow_t := 0.0
var far_shadow_off := 0           # how many movers had their shadow off last check (tests read it)


func _update_far_shadows() -> void:
    var cam := get_viewport().get_camera_3d()
    if cam == null:
        return
    var eye := cam.global_position
    far_shadow_off = 0
    for list in [enemies, enemy_vehicles, vehicles, squad]:
        for n in list:
            if not is_instance_valid(n) or not n is Node3D:
                continue
            var on: bool = eye.distance_to(n.global_position) < SHADOW_REACH
            if n.get_meta("shadow_on", true) == on:
                if not on:
                    far_shadow_off += 1
                continue
            n.set_meta("shadow_on", on)
            if not on:
                far_shadow_off += 1
            var mode := GeometryInstance3D.SHADOW_CASTING_SETTING_ON if on else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
            for g in n.find_children("*", "GeometryInstance3D", true, false):
                if g is MeshInstance3D:
                    g.cast_shadow = mode


func _is_dynamic(n: Node) -> bool:
    while n != null and n != self:
        if n.get_script() != null:
            return true
        n = n.get_parent()
    return false


func mat(color: Color, rough := 0.85, metal := 0.0) -> StandardMaterial3D:
    var key := "%s_%s_%s" % [color.to_html(), rough, metal]
    if _mats.has(key):
        return _mats[key]
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = rough
    m.metallic = metal
    _mats[key] = m
    return m


func glow_mat(color: Color, energy := 2.0) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.emission_enabled = true
    m.emission = color
    m.emission_energy_multiplier = energy
    return m


func box(pos: Vector3, size: Vector3, color: Color, rot_y := 0.0, collide := true, m: Material = null) -> Node3D:
    return box_rot(pos, size, color, Vector3(0, rot_y, 0), collide, m)


func box_rot(pos: Vector3, size: Vector3, color: Color, rot: Vector3, collide := true, m: Material = null) -> Node3D:
    var mi := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = size
    mi.mesh = bm
    mi.material_override = m if m != null else mat(color)
    if not collide:
        mi.position = pos
        mi.rotation = rot
        add_child(mi)
        return mi
    var sb := StaticBody3D.new()
    sb.collision_layer = 1
    sb.collision_mask = 0
    sb.position = pos
    sb.rotation = rot
    add_child(sb)
    sb.add_child(mi)
    var cs := CollisionShape3D.new()
    var bs := BoxShape3D.new()
    bs.size = size
    cs.shape = bs
    sb.add_child(cs)
    return sb


func cyl(pos: Vector3, r: float, h: float, color: Color, collide := true, rot := Vector3.ZERO, m: Material = null, top_r := -1.0) -> Node3D:
    var mi := MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.top_radius = r if top_r < 0.0 else top_r
    cm.bottom_radius = r
    cm.height = h
    cm.radial_segments = 24
    mi.mesh = cm
    mi.material_override = m if m != null else mat(color)
    if not collide:
        mi.position = pos
        mi.rotation = rot
        add_child(mi)
        return mi
    var sb := StaticBody3D.new()
    sb.position = pos
    sb.rotation = rot
    add_child(sb)
    sb.add_child(mi)
    var cs := CollisionShape3D.new()
    var sh := CylinderShape3D.new()
    sh.radius = r
    sh.height = h
    cs.shape = sh
    sb.add_child(cs)
    return sb


func sphere(pos: Vector3, r: float, color: Color, scale_v := Vector3.ONE, m: Material = null) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    var sm := SphereMesh.new()
    sm.radius = r
    sm.height = r * 2.0
    mi.mesh = sm
    mi.material_override = m if m != null else mat(color)
    mi.position = pos
    mi.scale = scale_v
    add_child(mi)
    return mi


## Places a model from assets/packs. `fit` (model-local axes, before rotation)
## stretches it to that size in metres; zero components keep uniform scale.
## Returns null if the file is missing so callers can fall back to boxes.
func prop(path: String, pos: Vector3, rot_y := 0.0, fit := Vector3.ZERO, collide := true, tint := Color(1, 1, 1, 0)) -> Node3D:
    var full := "res://assets/packs/" + path
    if not _scenes.has(full):
        _scenes[full] = load(full) if ResourceLoader.exists(full) else null
    var ps: PackedScene = _scenes[full]
    if ps == null:
        return null
    var root := StaticBody3D.new() if collide else Node3D.new()
    root.position = pos
    root.rotation.y = rot_y
    add_child(root)
    var inst: Node3D = ps.instantiate()
    root.add_child(inst)
    var ab := _local_aabb(root, inst)
    var s := Vector3.ONE
    if fit != Vector3.ZERO:
        var known: Array = []
        for k in 3:
            if fit[k] > 0.0 and ab.size[k] > 0.001:
                s[k] = fit[k] / ab.size[k]
                known.append(s[k])
        var avg := 1.0
        if not known.is_empty():
            avg = known.reduce(func(a, b): return a + b) / known.size()
        for k in 3:
            if fit[k] <= 0.0:
                s[k] = avg
    inst.scale = s
    inst.position = Vector3(0, -ab.position.y * s.y, 0)
    if tint.a > 0.0:
        _tint(inst, tint)
    if collide:
        _add_mesh_collision(root, inst)
    props.append({"node": root, "path": path})
    return root


## Collision that follows the model's real triangles (with its scale baked in),
## instead of one bounding box. A box around a tree spans the whole canopy down
## to the ground, which made invisible walls around trees, lamp posts, cacti,
## awnings and the water tower's legs.
func _add_mesh_collision(root: Node3D, inst: Node3D) -> void:
    var inv := root.global_transform.affine_inverse()
    var faces := PackedVector3Array()
    for m in inst.find_children("*", "MeshInstance3D", true, false):
        var mi := m as MeshInstance3D
        if mi.mesh == null:
            continue
        var xf: Transform3D = inv * mi.global_transform
        for v in mi.mesh.get_faces():
            faces.append(xf * v)
    if faces.is_empty():
        return
    var shape := ConcavePolygonShape3D.new()
    shape.set_faces(faces)
    var cs := CollisionShape3D.new()
    cs.shape = shape
    root.add_child(cs)


func _local_aabb(root: Node3D, inst: Node3D) -> AABB:
    var ab := AABB()
    var first := true
    var inv := root.global_transform.affine_inverse()
    for m in inst.find_children("*", "MeshInstance3D", true, false):
        var a: AABB = (inv * m.global_transform) * m.get_aabb()
        ab = a if first else ab.merge(a)
        first = false
    return ab


func _tint(inst: Node3D, tint: Color) -> void:
    for m in inst.find_children("*", "MeshInstance3D", true, false):
        var mi := m as MeshInstance3D
        for i in mi.mesh.get_surface_count():
            var src := mi.get_active_material(i)
            if src is BaseMaterial3D:
                var d: BaseMaterial3D = src.duplicate()
                d.albedo_color = d.albedo_color * Color(tint.r, tint.g, tint.b)
                mi.set_surface_override_material(i, d)


func wall(a: Vector3, b: Vector3, h: float, thick: float, color: Color, m: Material = null) -> void:
    var d := b - a
    var length := Vector2(d.x, d.z).length()
    var mid := (a + b) * 0.5
    box(Vector3(mid.x, a.y + h * 0.5, mid.z), Vector3(thick, h, length), color, atan2(d.x, d.z), true, m)


func bounds(half_x: float, half_z: float, y := 0.0) -> void:
    _bounds = Vector2(half_x, half_z)
    if level_index < LevelData.MELTDOWN_BASE:
        _build_edges(half_x, half_z, y)
    for s in [-1.0, 1.0]:
        var w1 := StaticBody3D.new()
        w1.position = Vector3(half_x * s, y + 25.0, 0)
        var c1 := CollisionShape3D.new()
        var b1 := BoxShape3D.new()
        b1.size = Vector3(1.0, 60.0, half_z * 2.0 + 4.0)
        c1.shape = b1
        w1.add_child(c1)
        add_child(w1)
        var w2 := StaticBody3D.new()
        w2.position = Vector3(0, y + 25.0, half_z * s)
        var c2 := CollisionShape3D.new()
        var b2 := BoxShape3D.new()
        b2.size = Vector3(half_x * 2.0 + 4.0, 60.0, 1.0)
        c2.shape = b2
        w2.add_child(c2)
        add_child(w2)


# ------------------------------------------------- edge of the battlefield ----
# The map's edge used to be an invisible wall (the ground carries on past it).
# Now a striped barrier fades in as you get close, and touching it says so.

var _bounds := Vector2.ZERO
var _edges: Array = []            # [MeshInstance3D, axis (0 = x, 1 = z), sign]
var _edge_mat: StandardMaterial3D
var _edge_msg_t := 0.0
var edge_alpha := 0.0             # strongest edge right now (tests read it)


func _build_edges(hx: float, hz: float, y: float) -> void:
    _edge_mat = StandardMaterial3D.new()
    _edge_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    _edge_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    _edge_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    _edge_mat.albedo_texture = _stripe_texture()
    _edge_mat.uv1_scale = Vector3(1, 1, 1)
    _edge_mat.albedo_color = Color(1, 1, 1, 0)
    for axis in 2:
        for sgn in [-1.0, 1.0]:
            var mi := MeshInstance3D.new()
            var qm := QuadMesh.new()
            var length: float = (hz if axis == 0 else hx) * 2.0
            qm.size = Vector2(length, 24.0)          # tall: dunes and hills rise along the edge
            mi.mesh = qm
            mi.material_override = _edge_mat.duplicate()
            mi.material_override.uv1_scale = Vector3(length / 6.0, 4, 1)
            mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
            mi.position = Vector3(hx * sgn, y + 2.0, 0) if axis == 0 else Vector3(0, y + 2.0, hz * sgn)
            mi.rotation.y = PI / 2 if axis == 0 else 0.0
            mi.visible = false
            add_child(mi)
            _edges.append([mi, axis, sgn])


## Diagonal yellow/black hazard stripes (made once, shared).
static var _stripes: ImageTexture
static func _stripe_texture() -> ImageTexture:
    if _stripes == null:
        var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
        for px in 64:
            for py in 64:
                var band := int((px + py) / 16) % 2 == 0
                img.set_pixel(px, py, Color(1.0, 0.8, 0.1, 0.9) if band else Color(0.08, 0.08, 0.08, 0.75))
        _stripes = ImageTexture.create_from_image(img)
    return _stripes


func _update_edges(delta: float) -> void:
    edge_alpha = 0.0
    if _edges.is_empty() or player == null:
        return
    var who: Node3D = player.vehicle if player.vehicle != null else player
    var p: Vector3 = who.global_position
    _edge_msg_t = maxf(0.0, _edge_msg_t - delta)
    for e in _edges:
        var mi: MeshInstance3D = e[0]
        var lim: float = _bounds.x if e[1] == 0 else _bounds.y
        var coord: float = p.x if e[1] == 0 else p.z
        var d: float = lim - coord * e[2]                   # metres to this edge
        var a: float = clampf(1.0 - (d - 1.5) / 10.0, 0.0, 1.0) * 0.6
        mi.visible = a > 0.01
        if mi.visible:
            mi.material_override.albedo_color.a = a
        edge_alpha = maxf(edge_alpha, a)
        if d < 2.2 and _edge_msg_t <= 0.0 and hud != null:
            hud.show_message("EDGE OF THE BATTLEFIELD - TURN BACK", 2.0)
            _edge_msg_t = 4.0


func add_enemy(pos: Vector3, type := "rifleman", hvt := false) -> Node:
    var e = Enemy.new()
    e.setup(self, type, pos, hvt)
    add_child(e)
    enemies.append(e)
    if hvt:
        hvts.append(e)
    return e


## A Tan soldier who waits out of the fight until a "defend" objective sends
## every reserve at the defended point.
func add_reserve(pos: Vector3, type := "rifleman") -> Node:
    var e = add_enemy(pos, type)
    reserves.append(e)
    return e


## A point light (lamps at night, glowing toys indoors).
func lamp(pos: Vector3, color: Color, rng := 14.0, energy := 2.0, bulb := true) -> OmniLight3D:
    var l := OmniLight3D.new()
    l.position = pos
    l.light_color = color
    l.light_energy = energy
    l.omni_range = rng
    l.shadow_enabled = false
    add_child(l)
    if bulb:
        sphere(pos, 0.25, color, Vector3.ONE, glow_mat(color, 3.0))
    return l


## Shallow water / puddles: a glossy plane you can wade through.
func water(pos: Vector3, size: Vector2, color := Color(0.18, 0.4, 0.55, 0.8)) -> void:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    m.roughness = 0.05
    m.metallic = 0.3
    box(pos, Vector3(size.x, 0.04, size.y), color, 0.0, false, m)


func pickups_of(kind: String) -> int:
    var n := 0
    for id in pickups:
        var pk = pickups[id]
        if is_instance_valid(pk) and not pk.is_queued_for_deletion() and pk.kind == kind:
            n += 1
    return n


func add_target(pos: Vector3, kind: String, tag: String, rot_y := 0.0) -> Node:
    var t = Target.new()
    t.setup(self, kind, tag, pos, rot_y)
    add_child(t)
    targets.append(t)
    if not targets_by_tag.has(tag):
        targets_by_tag[tag] = []
    targets_by_tag[tag].append(t)
    return t


func add_vehicle(kind: String, pos: Vector3, rot_y := 0.0, color = null) -> Node:
    var v = Vehicle.new()
    v.setup(self, kind, pos, rot_y)
    if color != null:
        v.body_color = color
    add_child(v)
    vehicles.append(v)
    return v


func add_enemy_vehicle(kind: String, pos: Vector3, rot_y := 0.0) -> Node:
    var v = Vehicle.new()
    v.setup(self, kind, pos, rot_y, "tan")
    add_child(v)
    enemy_vehicles.append(v)
    return v


func on_enemy_vehicle_destroyed(v) -> void:
    kills += 1
    notify("TAN %s DESTROYED" % v.kind.to_upper(), 2.0)


func nearest_vehicle(pos: Vector3, max_dist: float) -> Node:
    var best = null
    var best_d := max_dist
    for v in vehicles:
        if is_instance_valid(v) and v.can_enter():
            var d: float = v.global_position.distance_to(pos)
            if d < best_d:
                best_d = d
                best = v
    return best


func add_barrel(pos: Vector3) -> void:
    var b = Barrel.new()
    b.setup(self, pos)
    add_child(b)
    barrels.append(b)


func add_pickup(pos: Vector3, kind: String, id := -1) -> void:
    if id < 0:
        id = _next_pickup_id
    _next_pickup_id = maxi(_next_pickup_id, id + 1)
    if pickups.has(id):
        return
    var p = Pickup.new()
    p.setup(self, kind, pos)
    p.net_id = id
    add_child(p)
    pickups[id] = p


func remove_pickup(id: int) -> void:
    var p = pickups.get(id)
    if p != null and is_instance_valid(p):
        p.queue_free()
    pickups.erase(id)


func add_helipad(pos: Vector3) -> Node3D:
    var root := Node3D.new()
    root.position = pos
    add_child(root)
    var pad := MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.top_radius = 5.0
    cm.bottom_radius = 5.0
    cm.height = 0.1
    pad.mesh = cm
    pad.material_override = mat(Color(0.2, 0.21, 0.2))
    pad.position.y = 0.05
    root.add_child(pad)
    var white := glow_mat(Color(0.9, 0.95, 0.85), 0.6)
    for p in [[Vector3(-1.1, 0.12, 0), Vector3(0.4, 0.02, 3.2)], [Vector3(1.1, 0.12, 0), Vector3(0.4, 0.02, 3.2)], [Vector3(0, 0.12, 0), Vector3(2.2, 0.02, 0.4)]]:
        var mi := MeshInstance3D.new()
        var bm := BoxMesh.new()
        bm.size = p[1]
        mi.mesh = bm
        mi.material_override = white
        mi.position = p[0]
        root.add_child(mi)
    var beam := MeshInstance3D.new()
    var bc := CylinderMesh.new()
    bc.top_radius = 0.6
    bc.bottom_radius = 0.6
    bc.height = 80.0
    beam.mesh = bc
    beam.material_override = Fx.unlit(Color(0.3, 1.0, 0.4, 0.22))
    beam.position.y = 40.0
    root.add_child(beam)
    var smoke := Fx.fire(root, pos + Vector3(4.5, 0.2, 0), 0.6, 0.0)   # the extraction smoke keeps going
    smoke.color_ramp.set_color(0, Color(0.3, 1.0, 0.4, 0.8))
    smoke.color_ramp.set_color(1, Color(0.3, 0.9, 0.4, 0.0))
    smoke.gravity = Vector3(0, 4.0, 0)
    var heli_path := "res://assets/audio/ambience/helicopter.ogg"
    if ResourceLoader.exists(heli_path):
        var heli := AudioStreamPlayer3D.new()
        var hs: AudioStream = load(heli_path)
        if hs is AudioStreamOggVorbis:
            hs.loop = true
        heli.stream = hs
        heli.bus = "SFX"
        heli.unit_size = 25.0
        heli.max_distance = 220.0
        heli.position.y = 12.0
        heli.autoplay = true
        root.add_child(heli)
    return root


# ------------------------------------------------------------ gameplay ----

func notify(text: String, dur := 2.5) -> void:
    last_notice = text
    if hud:
        hud.show_message(text, dur)


func make_noise(pos: Vector3, radius: float) -> void:
    for e in enemies + enemy_vehicles:
        if is_instance_valid(e) and e.alive and e.global_position.distance_to(pos) < radius:
            e.hear(pos)


func apply_explosion(pos: Vector3, radius: float, damage: float) -> void:
    if not is_server():
        return          # in a LAN game the host decides all damage
    for n in get_tree().get_nodes_in_group("damageable"):
        if not is_instance_valid(n) or n.is_queued_for_deletion() or not is_ancestor_of(n):
            continue
        var center: Vector3 = n.global_position + Vector3(0, 0.9, 0)
        var d := center.distance_to(pos)
        if d < radius:
            var f := 1.0 - d / radius
            n.take_damage(damage * (0.25 + 0.75 * f), pos, center, true)
    if player and is_instance_valid(player):
        var pd: float = player.global_position.distance_to(pos)
        player.shake = maxf(player.shake, clampf(1.3 - pd / 30.0, 0.0, 1.3))


func on_enemy_killed(e, headshot: bool) -> void:
    kills += 1
    if headshot:
        headshots += 1
        notify("HEADSHOT", 0.8)
    if randf() < (0.06 if mode != null else 0.25) and is_server():
        var kind: String = ["ammo", "ammo", "health", "grenades", "armor"].pick_random()
        var id := _next_pickup_id
        _next_pickup_id += 1
        var pos: Vector3 = e.global_position + Vector3(0, 0.1, 0)
        call_deferred("add_pickup", pos, kind, id)
        if net:
            net.pickup_spawned(id, kind, pos)


func on_target_destroyed(t) -> void:
    notify("%s DESTROYED" % t.display_name, 2.0)


func enemies_alive() -> int:
    return _alive_count(enemies) + _alive_count(enemy_vehicles)


func _alive_count(arr: Array) -> int:
    var n := 0
    for x in arr:
        if is_instance_valid(x) and x.alive:
            n += 1
    return n


func _begin_objective(i: int) -> void:
    obj_index = i
    if i >= objectives.size():
        _complete()
        return
    var o: Dictionary = objectives[i]
    _obj_start = elapsed
    _rally_t = 0.0
    if o["type"] == "extract":
        extraction = add_helipad(o["pos"])
    if o["type"] == "collect" and not o.has("total"):
        o["total"] = maxi(1, pickups_of(o["kind"]))
    if o["type"] == "defend" or o["type"] == "reach":
        _build_defend_marker(o["pos"], o.get("radius", 12.0))
    if i > 0:
        notify("NEW OBJECTIVE: " + o["text"], 3.5)
        Game.play_ui("radio", -6.0)
    if net != null and multiplayer.is_server() and i > 0:
        net.objective(i)


func _process(delta: float) -> void:
    if ended:
        return
    elapsed += delta
    _update_edges(delta)
    _shadow_t -= delta
    if _shadow_t <= 0.0:
        _shadow_t = 0.25
        _update_far_shadows()
    if info.get("distant_booms", false):
        _boom_t -= delta
        if _boom_t <= 0.0:
            _boom_t = randf_range(9.0, 22.0)
            Game.play_ui("distant_boom", randf_range(-20.0, -12.0))
    _tick_respawn(delta)
    if obj_index >= objectives.size() or not is_server():
        return          # in a LAN game only the host judges objectives
    var o: Dictionary = objectives[obj_index]
    var done := false
    match o["type"]:
        "destroy":
            done = _alive_count(targets_by_tag.get(o["tag"], [])) == 0
        "kill_hvt":
            done = _alive_count(hvts) == 0
        "kill_all":
            done = enemies_alive() == 0
        "extract":
            for t in ai_targets():
                if t.global_position.distance_to(o["pos"]) < 5.5:
                    done = true
        "collect":
            done = pickups_of(o["kind"]) == 0
        "reach":
            for t in ai_targets():
                if t.global_position.distance_to(o["pos"]) < o.get("radius", 6.0):
                    done = true
        "defend":
            _rally_t -= delta
            if _rally_t <= 0.0:
                _rally_t = 3.0
                for e in reserves:
                    if is_instance_valid(e) and e.alive:
                        e.home = o["pos"]
                        e.hear(o["pos"] + Vector3(randf_range(-4, 4), 0, randf_range(-4, 4)))
            done = elapsed - _obj_start >= o["time"]
    if done:
        Game.play_ui("objective")
        _begin_objective(obj_index + 1)


func get_objective_text() -> String:
    if mode != null:
        return mode.objective_text()
    if obj_index >= objectives.size():
        return "Mission complete"
    var o: Dictionary = objectives[obj_index]
    match o["type"]:
        "destroy":
            var arr: Array = targets_by_tag.get(o["tag"], [])
            return "%s  (%d/%d)" % [o["text"], arr.size() - _alive_count(arr), arr.size()]
        "kill_all":
            return "%s  (%d left)" % [o["text"], enemies_alive()]
        "collect":
            var total: int = o.get("total", 1)
            return "%s  (%d/%d)" % [o["text"], total - pickups_of(o["kind"]), total]
        "defend":
            return "%s  (%d s)" % [o["text"], int(ceil(maxf(0.0, o["time"] - (elapsed - _obj_start))))]
    return o["text"]


func get_objective_point() -> Variant:
    if obj_index >= objectives.size() or player == null:
        return null
    var o: Dictionary = objectives[obj_index]
    var candidates: Array = []
    match o["type"]:
        "destroy":
            candidates = targets_by_tag.get(o["tag"], [])
        "kill_hvt":
            candidates = hvts
        "kill_all":
            if enemies_alive() > 6:
                return null
            candidates = enemies + enemy_vehicles
        "extract", "defend", "reach":
            return o["pos"] + Vector3(0, 1.0, 0)
        "collect":
            for id in pickups:
                var pk = pickups[id]
                if is_instance_valid(pk) and pk.kind == o["kind"]:
                    candidates.append(pk)
            var best_p = null
            var bd := INF
            for c in candidates:
                var d: float = c.global_position.distance_to(player.global_position)
                if d < bd:
                    bd = d
                    best_p = c.global_position + Vector3(0, 1.6, 0)
            return best_p
    var best = null
    var best_d := INF
    for c in candidates:
        if is_instance_valid(c) and c.alive:
            var d: float = c.global_position.distance_to(player.global_position)
            if d < best_d:
                best_d = d
                best = c.global_position + Vector3(0, 2.2, 0)
    return best


func _add_snowfall() -> void:
    var p := CPUParticles3D.new()
    p.amount = 900
    p.lifetime = 6.0
    p.preprocess = 6.0
    p.local_coords = false
    p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
    p.emission_box_extents = Vector3(35, 1, 35)
    p.position = Vector3(0, 16, 0)
    p.direction = Vector3(0.2, -1, 0.1)
    p.spread = 15.0
    p.gravity = Vector3(0.4, -1.2, 0)
    p.initial_velocity_min = 2.0
    p.initial_velocity_max = 3.5
    var qm := QuadMesh.new()
    qm.size = Vector2(0.09, 0.09)
    var m := StandardMaterial3D.new()
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
    m.albedo_color = Color(1, 1, 1, 0.9)
    m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    qm.material = m
    p.mesh = qm
    player.add_child(p)


func _build_defend_marker(pos: Vector3, radius: float) -> void:
    var ring := MeshInstance3D.new()
    var tm := TorusMesh.new()
    tm.inner_radius = radius - 0.25
    tm.outer_radius = radius
    tm.rings = 48
    ring.mesh = tm
    ring.material_override = Fx.unlit(Color(0.35, 1.0, 0.45, 0.5))
    ring.position = pos + Vector3(0, 0.1, 0)
    ring.scale = Vector3(1, 0.1, 1)
    add_child(ring)


func _stats() -> Dictionary:
    var acc := 0.0
    if player.shots_fired > 0:
        acc = float(player.shots_hit) / float(player.shots_fired) * 100.0
    return {
        "time": elapsed, "kills": kills, "total": enemies.size(),
        "headshots": headshots, "accuracy": acc, "level": level_index,
        "mode": "meltdown" if mode != null else "campaign",
        "wave": mode.wave if mode != null else 0,
        "coins": mode.coins_total if mode != null else 0,
    }


func _complete() -> void:
    if net != null:
        net.mission_end(true, _stats())
        return
    ended = true
    player.invulnerable = true
    notify("MISSION ACCOMPLISHED", 3.0)
    var t := get_tree().create_timer(2.5)
    t.timeout.connect(func():
        if is_inside_tree():
            finished.emit(true, _stats()))


func _on_player_died() -> void:
    if ended:
        return
    if net != null:
        # Co-op: you're back in a few seconds. The mission only fails if the
        # whole squad is down at once (the host checks that).
        _respawn_t = RESPAWN_TIME
        notify("YOU MELTED!  BACK IN %d SECONDS" % int(RESPAWN_TIME), 3.0)
        return
    ended = true
    notify("YOU MELTED ON WAVE %d" % mode.wave if mode != null else "YOU MELTED.  MISSION FAILED", 3.0)
    Game.play_ui("fail")
    var t := get_tree().create_timer(3.0)
    t.timeout.connect(func():
        if is_inside_tree():
            finished.emit(false, _stats()))


func _tick_respawn(delta: float) -> void:
    if _respawn_t <= 0.0:
        return
    _respawn_t -= delta
    if _respawn_t <= 0.0 and not ended:
        player.respawn(spawn_point)
        notify("BACK IN THE FIGHT", 1.5)


# ---------------------------------------------------------------- pause ----

func toggle_pause() -> void:
    if ended:
        return
    if net != null:
        _toggle_net_menu()     # a LAN game can't pause for everyone
        return
    if get_tree().paused:
        _resume()
    else:
        _pause()


func _pause() -> void:
    get_tree().paused = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    pause_layer = CanvasLayer.new()
    pause_layer.layer = 20
    pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
    add_child(pause_layer)
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.theme = UI.make_theme()
    pause_layer.add_child(root)
    var dim := ColorRect.new()
    dim.set_anchors_preset(Control.PRESET_FULL_RECT)
    dim.color = Color(0, 0, 0, 0.55)
    root.add_child(dim)
    var vb := UI.centered_panel(root, 460)
    vb.add_child(UI.label("PAUSED", 40, UI.ACCENT))
    vb.add_child(UI.label(info["name"], 20))
    vb.add_child(UI.button("Resume", _resume))
    vb.add_child(UI.button("Restart Operation", func():
        get_tree().paused = false
        request_restart.emit()))
    vb.add_child(UI.button("Quit to Main Menu", func():
        get_tree().paused = false
        request_menu.emit()))
    vb.add_child(UI.label("WASD move · Mouse aim · LMB fire · RMB aim/scope\nShift sprint · C crouch · Space jump · R reload\n1-5 / wheel weapons · G frag · F drone strike · E jeep/tank", 16, Color(0.8, 0.85, 0.75)))


func _toggle_net_menu() -> void:
    if pause_layer:
        pause_layer.queue_free()
        pause_layer = null
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
        return
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    pause_layer = CanvasLayer.new()
    pause_layer.layer = 20
    add_child(pause_layer)
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.theme = UI.make_theme()
    pause_layer.add_child(root)
    var vb := UI.centered_panel(root, 460)
    vb.add_child(UI.label("LAN GAME", 36, UI.ACCENT))
    vb.add_child(UI.label("The game keeps running for your squad.", 17))
    vb.add_child(UI.button("Back to the fight", _toggle_net_menu))
    vb.add_child(UI.button("Leave game", func():
        Net.leave()
        request_menu.emit()))


func _resume() -> void:
    get_tree().paused = false
    if pause_layer:
        pause_layer.queue_free()
        pause_layer = null
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# ------------------------------------------------- textures + terrain ----

const TEX_DIR := "res://assets/textures/"
var _ground_spec = null            # set by ground(); the terrain is built after the map
var terrain_node: StaticBody3D


## A material that projects one of assets/textures/<name> onto any surface in
## world space (triplanar), so procedural boxes need no UVs. `tile` is how
## many metres one repeat of the texture covers; `tint` multiplies its colour.
func tex(name: String, tint := Color.WHITE, tile := 6.0, rough := 0.9) -> StandardMaterial3D:
    var key := "tex|%s|%s|%.2f|%.2f" % [name, tint.to_html(), tile, rough]
    if _mats.has(key):
        return _mats[key]
    var albedo := TEX_DIR + name + "/albedo.jpg"
    if not ResourceLoader.exists(albedo):
        return mat(tint, rough)
    var m := StandardMaterial3D.new()
    m.albedo_texture = load(albedo)
    m.albedo_color = tint
    var normal := TEX_DIR + name + "/normal.jpg"
    if ResourceLoader.exists(normal):
        m.normal_enabled = true
        m.normal_texture = load(normal)
        m.normal_scale = 0.9
    m.roughness = rough
    m.uv1_triplanar = true
    m.uv1_world_triplanar = true
    m.uv1_triplanar_sharpness = 6.0
    m.uv1_scale = Vector3.ONE / tile
    m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
    _mats[key] = m
    return m


## Outdoor ground: a textured terrain `size` metres across with gentle hills
## (up to `amp` m) wherever the map is empty. Anything placed on the map, the
## start point and the objectives keep flat ground around them. `flat` is a
## list of Rect2 (x, z) areas that must stay flat too (beaches, roads...).
func ground(size: float, m: Material, amp := 2.5, seed := 1, flat: Array = [], rim := 6.0) -> void:
    _ground_spec = {"size": size, "mat": m, "amp": amp, "seed": seed, "flat": flat, "rim": rim}


## Campaign progression: keep only the vehicles, weapons and drone strikes this
## operation has unlocked, and set how tough the Tan Army is.
func _apply_progression() -> void:
    var full: bool = Net.active or Game.free_play or info.get("mode", "") == "meltdown"
    var pr: Dictionary = LevelData.FULL_PROGRESSION if full else LevelData.progression(level_index)
    Game.campaign_ramp = pr["ramp"]
    for v in vehicles.duplicate():
        if not pr["vehicles"].has(v.kind) and not LevelData.CIVILIAN.has(v.kind):
            vehicles.erase(v)
            v.free()
    for v in enemy_vehicles.duplicate():
        if not pr["tan"].has(v.kind):
            enemy_vehicles.erase(v)
            v.free()
    for id in pickups.keys():
        var pk = pickups[id]
        var k: String = pk.kind
        var swap := ""
        if LevelData.ALL_WEAPONS.has(k) and not pr["weapons"].has(k):
            swap = "ammo"
        elif k == "drone" and not pr["drones"]:
            swap = "grenades"
        if swap != "":
            var pos: Vector3 = pk.position
            pickups.erase(id)
            pk.free()
            add_pickup(pos, swap, id)
    var start: Array = pr["start"] if not pr["start"].is_empty() else info.get("start_weapons", ["carbine"])
    info["start_weapons"] = start.filter(func(w): return pr["weapons"].has(w))
    if not pr["drones"]:
        info["drones"] = 0
    if not full:
        var fresh: Array = LevelData.new_on(level_index)
        if not fresh.is_empty():
            get_tree().create_timer(4.0).timeout.connect(func():
                if is_inside_tree():
                    notify("NEW: " + ", ".join(fresh).to_upper(), 4.0))


func _build_terrain() -> void:
    var g: Dictionary = _ground_spec
    var size: float = g["size"]
    var cell := 2.0
    var n := int(size / cell) + 1
    var half := size * 0.5
    # 1. Mark every cell that has something on it (plus a margin).
    var occ := PackedByteArray()
    occ.resize(n * n)
    var mark := func(aabb: AABB, margin: float) -> void:
        var x0 := clampi(int(floor((aabb.position.x - margin + half) / cell)), 0, n - 1)
        var x1 := clampi(int(ceil((aabb.end.x + margin + half) / cell)), 0, n - 1)
        var z0 := clampi(int(floor((aabb.position.z - margin + half) / cell)), 0, n - 1)
        var z1 := clampi(int(ceil((aabb.end.z + margin + half) / cell)), 0, n - 1)
        for z in range(z0, z1 + 1):
            for x in range(x0, x1 + 1):
                occ[z * n + x] = 1
    for vi in find_children("*", "MeshInstance3D", true, false):
        var ab: AABB = vi.global_transform * vi.get_aabb()
        if ab.size.x > 120.0 or ab.size.z > 120.0 or ab.position.y > 3.0:
            continue        # the sky-high room walls, oceans and map edges don't flatten anything
        mark.call(ab, 2.0)
    var keep: Array = [[info["spawn"], 14.0]]
    for o in info.get("objectives", []):
        if o.has("pos"):
            keep.append([o["pos"], 12.0])
    for k in keep:
        var p: Vector3 = k[0]
        mark.call(AABB(p - Vector3(k[1], 0, k[1]), Vector3(k[1] * 2, 1, k[1] * 2)), 0.0)
    for r in g["flat"]:
        var rc: Rect2 = r
        mark.call(AABB(Vector3(rc.position.x, 0, rc.position.y), Vector3(rc.size.x, 1, rc.size.y)), 0.0)
    # 2. Distance (in cells) from each cell to the nearest occupied one (two-pass chamfer).
    var dist := PackedFloat32Array()
    dist.resize(n * n)
    for i in n * n:
        dist[i] = 0.0 if occ[i] else 9999.0
    for z in n:
        for x in n:
            var i := z * n + x
            var d := dist[i]
            if x > 0: d = minf(d, dist[i - 1] + 1.0)
            if z > 0: d = minf(d, dist[i - n] + 1.0)
            if x > 0 and z > 0: d = minf(d, dist[i - n - 1] + 1.414)
            if x < n - 1 and z > 0: d = minf(d, dist[i - n + 1] + 1.414)
            dist[i] = d
    for z in range(n - 1, -1, -1):
        for x in range(n - 1, -1, -1):
            var i := z * n + x
            var d := dist[i]
            if x < n - 1: d = minf(d, dist[i + 1] + 1.0)
            if z < n - 1: d = minf(d, dist[i + n] + 1.0)
            if x < n - 1 and z < n - 1: d = minf(d, dist[i + n + 1] + 1.414)
            if x > 0 and z < n - 1: d = minf(d, dist[i + n - 1] + 1.414)
            dist[i] = d
    # 3. Heights: rolling noise faded in away from anything placed, rising at the rim.
    var noise := FastNoiseLite.new()
    noise.seed = g["seed"]
    noise.frequency = 0.022
    noise.fractal_octaves = 3
    var amp: float = g["amp"]
    var rim: float = g["rim"]
    var inner := half - 22.0
    var hts := PackedFloat32Array()
    hts.resize(n * n)
    for z in n:
        for x in n:
            var i := z * n + x
            var wx := -half + x * cell
            var wz := -half + z * cell
            var meters := dist[i] * cell
            var fade := smoothstep(3.0, 16.0, meters)
            var h := (noise.get_noise_2d(wx, wz) * 0.5 + 0.5) * amp * fade
            var edge := maxf(absf(wx), absf(wz))
            h += smoothstep(inner - 6.0, half, edge) * rim * (0.6 + 0.4 * (noise.get_noise_2d(wz, wx) * 0.5 + 0.5)) * minf(1.0, fade + 0.3)
            hts[i] = h
    # 4. Mesh + matching trimesh collision.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for z in n:
        for x in n:
            st.add_vertex(Vector3(-half + x * cell, hts[z * n + x], -half + z * cell))
    for z in n - 1:
        for x in n - 1:
            var a := z * n + x
            st.add_index(a)
            st.add_index(a + 1)
            st.add_index(a + n)
            st.add_index(a + 1)
            st.add_index(a + n + 1)
            st.add_index(a + n)
    st.generate_normals()
    var mesh := st.commit()
    terrain_node = StaticBody3D.new()
    terrain_node.name = "Terrain"
    terrain_node.collision_layer = 1
    terrain_node.collision_mask = 0
    var mi := MeshInstance3D.new()
    mi.mesh = mesh
    mi.material_override = g["mat"]
    terrain_node.add_child(mi)
    var cs := CollisionShape3D.new()
    cs.shape = mesh.create_trimesh_shape()
    terrain_node.add_child(cs)
    add_child(terrain_node)


## Terrain height at (x, z) (0 if the map has none), for placing things later.
func ground_height(x: float, z: float) -> float:
    if terrain_node == null:
        return 0.0
    var from := Vector3(x, 60.0, z)
    var q := PhysicsRayQueryParameters3D.create(from, Vector3(x, -10.0, z), 1)
    var hit := get_world_3d().direct_space_state.intersect_ray(q)
    return 0.0 if hit.is_empty() else hit["position"].y
