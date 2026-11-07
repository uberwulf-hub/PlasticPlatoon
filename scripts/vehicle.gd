extends CharacterBody3D
## Drivable plastic toy vehicles: a jeep with a mounted .50 cal, a tank with a
## turret cannon + coaxial MG, and an open-top troop carrier. Press E
## (interact) near one to get in or out. AI squadmates ride in the seats.
## Arcade handling on a CharacterBody3D: no wheel physics, just throttle/steer.

const Fx = preload("res://scripts/fx.gd")
const Rocket = preload("res://scripts/rocket.gd")
const CameraRig = preload("res://scripts/camera_rig.gd")

const GREEN := Color(0.27, 0.48, 0.17)
const TAN := Color(0.80, 0.68, 0.44)
const GRAVITY := 18.0

const KINDS := {
    "jeep": {
        "name": "JEEP (M2 .50 CAL)", "hp": 320.0, "bullet_armor": 1.0,
        "max_speed": 24.0, "reverse": 9.0, "accel": 14.0, "turn": 2.1, "pivot_turn": false,
        "size": Vector3(2.1, 1.6, 4.2), "cam_height": 2.3, "cam_dist": 7.0,
        "primary": "mg", "primary_interval": 0.09, "primary_damage": 30.0,
        # Where passengers stand (local, at their feet): front passenger + two in the back.
        "seats": [Vector3(0.45, 1.08, 0.05), Vector3(-0.55, 1.08, 1.6), Vector3(0.55, 1.08, 1.6)],
    },
    "apc": {
        "name": "TROOP CARRIER (.50 CAL, 4 SEATS)", "hp": 700.0, "bullet_armor": 0.3,
        "max_speed": 17.0, "reverse": 7.0, "accel": 9.0, "turn": 1.5, "pivot_turn": false,
        "size": Vector3(2.7, 2.5, 6.0), "cam_height": 3.0, "cam_dist": 9.0,
        "primary": "mg", "primary_interval": 0.09, "primary_damage": 30.0,
        "seats": [Vector3(-0.72, 1.82, 0.1), Vector3(0.72, 1.82, 0.1), Vector3(-0.72, 1.82, 1.8), Vector3(0.72, 1.82, 1.8)],
    },
    "tank": {
        "name": "TANK (120MM + COAX MG)", "hp": 1000.0, "bullet_armor": 0.15,
        "max_speed": 9.5, "reverse": 5.0, "accel": 6.0, "turn": 1.1, "pivot_turn": true,
        "size": Vector3(3.6, 2.3, 6.4), "cam_height": 3.2, "cam_dist": 10.0,
        "primary": "cannon", "primary_interval": 2.2, "primary_damage": 280.0,
        "secondary_interval": 0.08, "secondary_damage": 16.0,
        # Tank riders hang on to the rear deck.
        "seats": [Vector3(-0.85, 1.5, 2.45), Vector3(0.85, 1.5, 2.45), Vector3(0, 1.5, 2.8)],
    },
}

var level: Node
var kind := "jeep"
var k: Dictionary
var hp := 300.0
var alive := true
var driver = null
var speed := 0.0
var drive_input = null           # tests can set a Vector2 to drive without a keyboard
var mats: Array[StandardMaterial3D] = []

var cam_pivot: Node3D
var camera: Camera3D
var rig = CameraRig.new()
var cam_yaw := 0.0
var cam_pitch := -0.18

var turret: Node3D               # yaw part (tank turret / jeep gun mount)
var barrel: Node3D               # pitch part
var muzzle: Node3D
var coax_muzzle: Node3D
var fire_cd := 0.0
var fire2_cd := 0.0
var engine: AudioStreamPlayer3D
var _enter_cd := 0.0
var passengers: Array = []       # one entry per seat: a squadmate or null

# ---- Tan Army AI (enemy vehicles) ----
const AI := {
    "jeep": {"hp": 260.0, "speed_scale": 0.7, "sight": 75.0, "pref_dist": 22.0, "leash": 70.0,
        "burst": 6, "burst_pause": 1.6, "mg_damage": 7.0, "mg_spread": 3.5},
    "tank": {"hp": 700.0, "speed_scale": 0.8, "sight": 95.0, "pref_dist": 40.0, "leash": 55.0,
        "cannon_cd": 4.5, "cannon_damage": 55.0, "coax_range": 45.0, "burst": 8, "burst_pause": 2.0,
        "mg_damage": 5.0, "mg_spread": 4.0},
}
var team := "green"
var ai := false
var body_color := GREEN
var home := Vector3.ZERO
var ai_alert := 0.0               # >0 while engaged / hunting
var ai_last_seen := Vector3.ZERO
var _ai_los := false
var _ai_los_t := 0.0
var _ai_aim := Vector3.ZERO
var _ai_patrol := Vector3.ZERO
var _ai_patrol_t := 0.0
var _ai_burst := 0
var _ai_burst_cd := 1.0
var _ai_orbit := 1.0
var _ai_stuck_t := 0.0
var _ai_reverse_t := 0.0
var _ai_react := 0.0
var _ai_ram_cd := 0.0
var _ai_charge_t := 0.0          # >0: give up circling and drive straight at the target
var _ai_stuck_count := 0
var _ai_stuck_decay := 0.0
var ai_shots := 0
var ai_travelled := 0.0

# ---- LAN co-op ----
var net_puppet := false           # follows sent state instead of simulating
var occupant_peer := 0            # peer driving it (0 = empty)
var last_fire_ms := -100000
var _net_pos := Vector3.ZERO
var _net_yaw := 0.0
var _net_turret := 0.0
var _net_barrel := 0.0
var _net_have := false


func setup(lvl: Node, kd: String, pos: Vector3, rot_y := 0.0, tm := "green") -> void:
    level = lvl
    kind = kd
    position = pos
    rotation.y = rot_y
    team = tm
    ai = tm == "tan"
    body_color = TAN if ai else GREEN
    home = pos


func _ready() -> void:
    k = KINDS[kind]
    hp = AI[kind]["hp"] if ai else k["hp"]
    add_to_group("damageable")
    add_to_group("vehicles")
    collision_layer = 4 if ai else 1       # tan vehicles sit on the enemies layer
    collision_mask = (1 | 2 | 4) if ai else (1 | 4)
    _ai_patrol = home
    _ai_orbit = [-1.0, 1.0].pick_random()
    floor_snap_length = 0.5
    floor_max_angle = deg_to_rad(40)
    var size: Vector3 = k["size"]
    var cs := CollisionShape3D.new()
    var bs := BoxShape3D.new()
    bs.size = size
    cs.shape = bs
    cs.position.y = size.y * 0.5
    add_child(cs)
    match kind:
        "tank":
            _build_tank()
        "apc":
            _build_apc()
        _:
            _build_jeep()
    passengers.resize(k.get("seats", []).size())

    cam_pivot = Node3D.new()
    cam_pivot.top_level = true
    add_child(cam_pivot)
    camera = Camera3D.new()
    camera.fov = 72.0
    camera.far = 900.0
    cam_pivot.add_child(camera)

    engine = AudioStreamPlayer3D.new()
    engine.stream = Game.sfx.get("engine")
    engine.bus = "SFX"
    engine.unit_size = 10.0
    engine.volume_db = -14.0
    add_child(engine)


# ---------------------------------------------------------------- models ----

func _mat(c: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.roughness = 0.38
    m.metallic_specular = 0.65
    m.rim_enabled = true
    m.rim = 0.2
    mats.append(m)
    return m


func _box(parent: Node3D, pos: Vector3, size: Vector3, m: Material, rot := Vector3.ZERO) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = size
    mi.mesh = bm
    mi.material_override = m
    mi.position = pos
    mi.rotation = rot
    parent.add_child(mi)
    return mi


func _cyl(parent: Node3D, pos: Vector3, r: float, h: float, m: Material, rot := Vector3.ZERO) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.top_radius = r
    cm.bottom_radius = r
    cm.height = h
    cm.radial_segments = 16
    mi.mesh = cm
    mi.material_override = m
    mi.position = pos
    mi.rotation = rot
    parent.add_child(mi)
    return mi


func _build_jeep() -> void:
    var body := _mat(body_color)
    var dark := _mat(body_color.darkened(0.25))
    var tire := _mat(body_color.darkened(0.5))
    _box(self, Vector3(0, 0.8, 0.1), Vector3(2.0, 0.55, 3.9), body)             # tub
    _box(self, Vector3(0, 1.12, -1.35), Vector3(1.9, 0.35, 1.3), body)          # hood
    _box(self, Vector3(0, 1.0, -2.05), Vector3(1.7, 0.5, 0.12), dark)           # grille
    for x in [-1.05, 1.05]:
        _box(self, Vector3(x, 1.0, -1.35), Vector3(0.25, 0.12, 1.5), dark)      # fenders
        _box(self, Vector3(x, 1.0, 1.35), Vector3(0.25, 0.12, 1.2), dark)
    _box(self, Vector3(0, 1.75, -0.6), Vector3(1.9, 0.08, 0.08), dark)          # windshield frame
    for x in [-0.92, 0.92]:
        _box(self, Vector3(x, 1.45, -0.6), Vector3(0.08, 0.65, 0.08), dark)
        _cyl(self, Vector3(x, 1.7, 0.9), 0.05, 1.3, dark)                        # roll bar posts
    _box(self, Vector3(0, 2.35, 0.9), Vector3(1.9, 0.1, 0.1), dark)             # roll bar top
    _box(self, Vector3(-0.45, 1.25, 0.2), Vector3(0.7, 0.35, 0.7), dark)        # seats
    _box(self, Vector3(0.45, 1.25, 0.2), Vector3(0.7, 0.35, 0.7), dark)
    _cyl(self, Vector3(0, 1.0, 2.15), 0.42, 0.3, tire, Vector3(PI / 2, 0, 0))    # spare
    for x in [-1.0, 1.0]:
        for z in [-1.35, 1.35]:
            _cyl(self, Vector3(x, 0.45, z), 0.45, 0.38, tire, Vector3(0, 0, PI / 2))
    # .50 cal on a post behind the seats, yaws with the camera.
    _cyl(self, Vector3(0, 1.55, 0.8), 0.07, 0.9, dark)
    turret = Node3D.new()
    turret.position = Vector3(0, 2.05, 0.8)
    add_child(turret)
    barrel = Node3D.new()
    turret.add_child(barrel)
    _box(barrel, Vector3(0, 0, -0.1), Vector3(0.22, 0.25, 0.8), dark)
    _cyl(barrel, Vector3(0, 0.02, -0.95), 0.05, 1.1, dark, Vector3(PI / 2, 0, 0))
    _box(barrel, Vector3(0, -0.05, 0.35), Vector3(0.5, 0.35, 0.06), dark)       # gun shield
    muzzle = Node3D.new()
    muzzle.position = Vector3(0, 0.02, -1.55)
    barrel.add_child(muzzle)


func _build_tank() -> void:
    var body := _mat(body_color)
    var dark := _mat(body_color.darkened(0.25))
    var track := _mat(body_color.darkened(0.5))
    _box(self, Vector3(0, 1.05, 0), Vector3(2.6, 0.9, 6.0), body)               # hull
    _box(self, Vector3(0, 1.2, -3.0), Vector3(2.6, 0.6, 0.6), body, Vector3(deg_to_rad(-35), 0, 0))
    for x in [-1.45, 1.45]:
        _box(self, Vector3(x, 0.6, 0), Vector3(0.75, 1.1, 6.3), track)          # tracks
        _box(self, Vector3(x, 1.2, 0), Vector3(0.95, 0.12, 6.1), body)          # skirts
        for i in 6:
            _cyl(self, Vector3(x * 1.17, 0.45, -2.4 + i * 0.96), 0.36, 0.1, dark, Vector3(0, 0, PI / 2))
    turret = Node3D.new()
    turret.position = Vector3(0, 1.55, 0.4)
    add_child(turret)
    _box(turret, Vector3(0, 0.38, 0), Vector3(2.3, 0.75, 2.9), body)
    _box(turret, Vector3(0, 0.38, -1.6), Vector3(1.9, 0.6, 0.6), body, Vector3(deg_to_rad(20), 0, 0))
    _cyl(turret, Vector3(0.55, 0.82, 0.3), 0.32, 0.15, dark)                    # hatch
    _box(turret, Vector3(-0.6, 0.95, 0.3), Vector3(0.12, 0.2, 0.7), dark)       # roof MG
    _box(turret, Vector3(0, 0.3, 1.55), Vector3(2.0, 0.5, 0.4), dark)           # bustle rack
    barrel = Node3D.new()
    barrel.position = Vector3(0, 0.38, -1.5)
    turret.add_child(barrel)
    _cyl(barrel, Vector3(0, 0, -1.9), 0.17, 3.8, dark, Vector3(PI / 2, 0, 0))
    _cyl(barrel, Vector3(0, 0, -0.9), 0.27, 0.9, dark, Vector3(PI / 2, 0, 0))   # fume extractor
    _cyl(barrel, Vector3(0, 0, -3.75), 0.24, 0.35, dark, Vector3(PI / 2, 0, 0)) # muzzle brake
    muzzle = Node3D.new()
    muzzle.position = Vector3(0, 0, -4.0)
    barrel.add_child(muzzle)
    coax_muzzle = Node3D.new()
    coax_muzzle.position = Vector3(0.45, -0.05, -0.6)
    barrel.add_child(coax_muzzle)


func _build_apc() -> void:
    var body := _mat(body_color)
    var dark := _mat(body_color.darkened(0.25))
    var tire := _mat(body_color.darkened(0.5))
    var glass := _mat(Color(0.2, 0.28, 0.3))
    _box(self, Vector3(0, 1.2, 0), Vector3(2.6, 1.2, 5.8), body)                # hull
    _box(self, Vector3(0, 1.3, -3.05), Vector3(2.6, 0.8, 0.6), body, Vector3(deg_to_rad(-40), 0, 0))
    _box(self, Vector3(0, 2.25, -1.95), Vector3(2.5, 0.9, 1.9), body)           # cab
    _box(self, Vector3(0, 2.35, -2.92), Vector3(2.1, 0.45, 0.05), glass)        # windscreen
    for x in [-1.26, 1.26]:
        _box(self, Vector3(x, 2.35, -1.95), Vector3(0.05, 0.4, 1.2), glass)
        _box(self, Vector3(x, 2.15, 0.95), Vector3(0.14, 0.7, 3.9), body)       # troop bay walls
        _box(self, Vector3(x * 0.62, 1.95, 0.95), Vector3(0.45, 0.3, 3.6), dark) # benches
        for z in [-2.1, -0.7, 0.7, 2.1]:
            _cyl(self, Vector3(x * 0.98, 0.5, z), 0.5, 0.42, tire, Vector3(0, 0, PI / 2))
    _box(self, Vector3(0, 2.15, 2.88), Vector3(2.6, 0.7, 0.14), body)           # tailgate
    _box(self, Vector3(0, 1.82, 0.95), Vector3(2.3, 0.04, 3.8), dark)           # bay floor
    _box(self, Vector3(0, 1.4, 3.0), Vector3(1.4, 0.12, 0.3), dark)             # step
    # .50 cal ring mount on the cab roof.
    _cyl(self, Vector3(0, 2.8, -1.9), 0.42, 0.18, dark)
    turret = Node3D.new()
    turret.position = Vector3(0, 3.05, -1.9)
    add_child(turret)
    barrel = Node3D.new()
    turret.add_child(barrel)
    _box(barrel, Vector3(0, 0, -0.1), Vector3(0.22, 0.25, 0.8), dark)
    _cyl(barrel, Vector3(0, 0.02, -0.95), 0.05, 1.1, dark, Vector3(PI / 2, 0, 0))
    _box(barrel, Vector3(0, -0.05, 0.35), Vector3(0.6, 0.4, 0.06), dark)
    muzzle = Node3D.new()
    muzzle.position = Vector3(0, 0.02, -1.55)
    barrel.add_child(muzzle)


# ------------------------------------------------------------- passengers ----

## Takes the first free seat for `m`; returns the seat index or -1.
func board(m) -> int:
    if not alive or ai:
        return -1
    for i in passengers.size():
        if passengers[i] == null or not is_instance_valid(passengers[i]):
            passengers[i] = m
            return i
    return -1


func unboard(m) -> void:
    var i := passengers.find(m)
    if i >= 0:
        passengers[i] = null


func free_seats() -> int:
    var n := 0
    for p in passengers:
        if p == null or not is_instance_valid(p):
            n += 1
    return n


func seat_transform(i: int) -> Transform3D:
    return global_transform * Transform3D(Basis(), k["seats"][i])


## A clear spot beside the vehicle for someone climbing off seat `i`.
func dismount_point(i: int) -> Vector3:
    var side := 1.0 if i % 2 == 1 else -1.0
    var local := Vector3(side * (k["size"].x * 0.5 + 1.1), 0.3, -1.0 + floorf(i / 2.0) * 1.8)
    var spot: Vector3 = global_transform * local
    var ex: Array[RID] = [get_rid()]
    if not Fx.ray(self, global_position + Vector3(0, 1, 0), spot + Vector3(0, 0.7, 0), 1, ex).is_empty():
        spot = global_transform * Vector3(-local.x, local.y, local.z)
        if not Fx.ray(self, global_position + Vector3(0, 1, 0), spot + Vector3(0, 0.7, 0), 1, ex).is_empty():
            spot = global_transform * Vector3(0, 0.3, k["size"].z * 0.5 + 1.2)
    return spot


# ------------------------------------------------------------ enter/exit ----

func can_enter() -> bool:
    return alive and driver == null and not ai and occupant_peer == 0


func enter(p) -> void:
    if not can_enter():
        return
    driver = p
    p.vehicle = self
    p.visible = false
    p.collision_layer = 0
    p.collision_mask = 0
    collision_layer = 2          # enemies shoot at the occupied vehicle like the player
    cam_yaw = rotation.y
    cam_pitch = -0.18
    rig.distance = k["cam_dist"]
    camera.current = true
    _enter_cd = 0.3
    engine.play()
    Game.play_ui("ui_confirm", -6.0)
    level.notify("%s  -  WASD drive, mouse aim, LMB fire%s, E to exit%s" % [k["name"], ", RMB coax MG" if kind == "tank" else "",
        "  (squad climbs aboard)" if not level.squad.is_empty() and not passengers.is_empty() else ""], 3.0)


func exit_vehicle() -> void:
    if driver == null:
        return
    var p = driver
    driver = null
    if level.net != null and occupant_peer == multiplayer.get_unique_id():
        level.net.release_vehicle(level.vehicles.find(self))
    p.vehicle = null
    collision_layer = 1
    engine.stop()
    var side := global_transform.basis.x.normalized()
    var half: float = k["size"].x * 0.5 + 1.0
    var spot := global_position - side * half
    var ex: Array[RID] = [get_rid()]
    if not Fx.ray(self, global_position + Vector3(0, 1, 0), spot + Vector3(0, 1, 0), 1, ex).is_empty():
        spot = global_position + side * half
    p.global_position = spot + Vector3(0, 0.3, 0)
    p.rotation.y = cam_yaw
    p.pitch = cam_pitch
    p.visible = true
    p.collision_layer = 2
    p.collision_mask = 1 | 4
    p.camera.current = true
    p.velocity = Vector3.ZERO


# ----------------------------------------------------------------- input ----

func _unhandled_input(event: InputEvent) -> void:
    if driver == null or get_tree().paused:
        return
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        var s: float = Game.mouse_sensitivity
        cam_yaw -= event.relative.x * s
        cam_pitch -= event.relative.y * s * (-1.0 if Game.invert_y else 1.0)
        cam_pitch = clampf(cam_pitch, -0.9, 0.35)


## Host snapshot (non-host PCs): position, turret, health and who's driving.
func net_apply(pos: Vector3, yaw: float, tur: float, bar: float, new_hp: float, is_alive: bool, spd: float, occ: int) -> void:
    hp = new_hp
    occupant_peer = occ
    if alive and not is_alive:
        _destroy_visual()
        return
    if not net_puppet:
        return               # we're driving it: our own simulation wins
    _net_follow(pos, yaw, tur, bar, spd)


## State sent by whoever is driving it: [x, y, z, yaw, turret, barrel, speed].
func net_drive_apply(vd: PackedFloat32Array) -> void:
    if net_puppet:
        _net_follow(Vector3(vd[0], vd[1], vd[2]), vd[3], vd[4], vd[5], vd[6])


func _net_follow(pos: Vector3, yaw: float, tur: float, bar: float, spd: float) -> void:
    _net_pos = pos
    _net_yaw = yaw
    _net_turret = tur
    _net_barrel = bar
    speed = spd
    if not _net_have:
        position = pos
        rotation.y = yaw
        _net_have = true


func _physics_process(delta: float) -> void:
    if net_puppet:
        if _net_have:
            var k2 := minf(1.0, delta * 12.0)
            position = position.lerp(_net_pos, k2) if position.distance_to(_net_pos) < 10.0 else _net_pos
            rotation.y = lerp_angle(rotation.y, _net_yaw, k2)
            if turret:
                turret.rotation.y = lerp_angle(turret.rotation.y, _net_turret, k2)
                barrel.rotation.x = lerpf(barrel.rotation.x, _net_barrel, k2)
            velocity = Vector3.ZERO
        return
    fire_cd = maxf(0.0, fire_cd - delta)
    fire2_cd = maxf(0.0, fire2_cd - delta)
    _enter_cd = maxf(0.0, _enter_cd - delta)
    var throttle := 0.0
    var steer := 0.0
    if ai and alive:
        var ctl := _ai_update(delta)
        throttle = ctl.x
        steer = ctl.y
    elif driver != null and alive:
        var inp: Vector2 = drive_input if drive_input != null else Input.get_vector("move_left", "move_right", "move_forward", "move_back")
        throttle = -inp.y
        steer = -inp.x
        if _enter_cd <= 0.0 and Input.is_action_just_pressed("interact"):
            exit_vehicle()
        elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
            if Input.is_action_pressed("fire"):
                fire_primary()
            if Input.is_action_pressed("aim"):
                fire_secondary()

    var max_fwd: float = k["max_speed"] * (AI[kind]["speed_scale"] if ai else 1.0)
    var max_rev: float = k["reverse"]
    if throttle > 0.0:
        speed = move_toward(speed, max_fwd * throttle, k["accel"] * delta * (2.0 if speed < 0.0 else 1.0))
    elif throttle < 0.0:
        speed = move_toward(speed, max_rev * throttle, k["accel"] * delta * (2.0 if speed > 0.0 else 1.0))
    else:
        speed = move_toward(speed, 0.0, k["accel"] * 0.6 * delta)
    if not alive:
        speed = move_toward(speed, 0.0, 20.0 * delta)

    var turn_scale := 1.0
    if not k["pivot_turn"]:
        turn_scale = clampf(absf(speed) / 6.0, 0.0, 1.0) * signf(speed)
    rotation.y += steer * k["turn"] * turn_scale * delta

    var fwd := -global_transform.basis.z
    velocity.x = fwd.x * speed
    velocity.z = fwd.z * speed
    velocity.y = -0.5 if is_on_floor() else velocity.y - GRAVITY * delta
    var before := global_position
    move_and_slide()
    _handle_collisions(delta, before)
    if ai:
        ai_travelled += (global_position - before).length()

    if driver != null:
        driver.global_position = global_position + Vector3(0, 0.6, 0)
        driver.velocity = velocity
        _aim_turret(delta)
        _update_camera(delta)
        engine.pitch_scale = 0.6 + absf(speed) / max_fwd * 0.9
    elif ai and alive:
        _aim_turret(delta)
        if ai_alert > 0.0 and not engine.playing:
            engine.play()
        engine.pitch_scale = 0.6 + absf(speed) / max_fwd * 0.9
    elif turret:
        turret.rotation.y = lerp_angle(turret.rotation.y, 0.0, delta)


func _handle_collisions(delta: float, before: Vector3) -> void:
    for i in get_slide_collision_count():
        var c := get_slide_collision(i)
        var other = c.get_collider()
        if ai:
            # Tan vehicles run down green infantry on foot.
            if other != null and other.is_in_group("player") and other.alive and absf(speed) > 6.0 and _ai_ram_cd <= 0.0:
                _ai_ram_cd = 1.0
                other.take_damage(30.0 * Game.enemy_damage_mult(), global_position, other.global_position, true)
            continue
        if other != null and other.is_in_group("enemies") and other.alive and absf(speed) > 5.0:
            other.take_damage(400.0, global_position, other.global_position + Vector3(0, 1, 0), true)
            Game.play_sfx("melt", other.global_position, -2.0)
    # Hitting a wall bleeds off speed instead of grinding along at full throttle.
    var moved := (global_position - before).length() / maxf(delta, 0.0001)
    if absf(speed) > 3.0 and moved < absf(speed) * 0.35:
        speed *= 0.6


func _aim_turret(delta: float) -> void:
    if turret == null:
        return
    var target_yaw := wrapf(cam_yaw - rotation.y, -PI, PI)
    var rate := 1.6 if kind == "tank" else 8.0
    turret.rotation.y = move_toward_angle(turret.rotation.y, target_yaw, rate * delta)
    barrel.rotation.x = lerpf(barrel.rotation.x, clampf(cam_pitch + 0.18, -0.15, 0.35), minf(1.0, delta * 8.0))


static func move_toward_angle(from: float, to: float, step: float) -> float:
    var d := wrapf(to - from, -PI, PI)
    return from + clampf(d, -step, step)


func _update_camera(delta: float) -> void:
    cam_pivot.global_position = global_position + Vector3(0, k["cam_height"], 0)
    cam_pivot.rotation = Vector3(cam_pitch, cam_yaw, 0)
    var ex: Array[RID] = [get_rid()]
    rig.update(delta, cam_pivot, camera, k["cam_dist"], Vector3(0, 0.4, 0), ex)
    var shake: float = driver.shake if driver else 0.0
    camera.h_offset = randf_range(-1.0, 1.0) * shake * 0.12
    camera.v_offset = randf_range(-1.0, 1.0) * shake * 0.12
    if driver:
        driver.shake = move_toward(driver.shake, 0.0, delta * 2.5)


# --------------------------------------------------------------- weapons ----

func _aim_point() -> Vector3:
    if ai:
        return _ai_aim
    var from := camera.global_position
    var dir := -camera.global_transform.basis.z
    var ex: Array[RID] = [get_rid()]
    var hit := Fx.ray(self, from, from + dir * 400.0, 1 | 4, ex)
    return hit["position"] if not hit.is_empty() else from + dir * 400.0


func fire_primary() -> void:
    if fire_cd > 0.0 or not alive:
        return
    if not ai and driver:
        driver.last_fire_ms = Time.get_ticks_msec()
    fire_cd = k["primary_interval"]
    if k["primary"] == "cannon":
        var m := muzzle.global_position
        var dir := -muzzle.global_transform.basis.z
        var target := _aim_point()
        # Use the barrel direction once the turret has caught up with the crosshair.
        var to_target := (target - m).normalized()
        if to_target.dot(dir) > 0.97:
            dir = to_target
        if ai:
            fire_cd = AI[kind]["cannon_cd"] * randf_range(0.85, 1.25)
            ai_shots += 1
        var dmg: float = AI[kind]["cannon_damage"] * Game.enemy_damage_mult() if ai else k["primary_damage"]
        var rad := 6.0 if ai else 7.0
        var r = Rocket.new()
        r.setup(self, level, m, dir, dmg, rad)
        r.speed = 90.0
        # LAN: a client's shell is only a visual copy; the host fires the real one.
        r.visual_only = level.net != null and not multiplayer.is_server()
        level.add_child(r)
        if level.net:
            level.net.send_projectile("rocket", m, dir, dmg, rad, 90.0)
        Fx.explosion(level, m, 1.2)
        Game.play_sfx("sniper", m, 6.0)
        Game.play_sfx("explosion", m, -4.0)
        if not ai:
            level.make_noise(m, 90.0)
        if driver:
            driver.shake = maxf(driver.shake, 0.6)
    else:
        if ai:
            _bullet(muzzle.global_position, AI[kind]["mg_damage"] * Game.enemy_damage_mult(), AI[kind]["mg_spread"] * Game.enemy_spread_mult(), "lmg")
        else:
            _bullet(muzzle.global_position, k["primary_damage"], 2.0, "lmg")


func fire_secondary() -> void:
    if not k.has("secondary_interval") or fire2_cd > 0.0 or not alive:
        return
    if not ai and driver:
        driver.last_fire_ms = Time.get_ticks_msec()
    fire2_cd = k["secondary_interval"]
    _bullet(coax_muzzle.global_position, k["secondary_damage"], 2.5, "lmg")


func _bullet(from: Vector3, damage: float, spread_deg: float, sound: String) -> void:
    var target := _aim_point()
    var dir := (target - from).normalized()
    var bx := dir.cross(Vector3.UP).normalized()
    var by := bx.cross(dir).normalized()
    var r := tan(deg_to_rad(spread_deg)) * sqrt(randf())
    var a := randf() * TAU
    dir = (dir + bx * r * cos(a) + by * r * sin(a)).normalized()
    var to := from + dir * 300.0
    var ex: Array[RID] = [get_rid()]
    var hit := Fx.ray(self, from, to, (1 | 2) if ai else (1 | 4), ex)
    var end := to
    if level.net != null and not multiplayer.is_server():
        # LAN client driving: draw it here, let the host decide what it hit.
        var ref: Array = []
        if not hit.is_empty():
            end = hit["position"]
            ref = level.ref_of(hit["collider"])
        if driver:
            driver.shots_fired += 1
        Fx.tracer(level, from, end, Color(1.0, 0.75, 0.35))
        Fx.muzzle_flash(level, from)
        Game.play_sfx(sound, from, 0.0)
        level.net.send_shot(PackedVector3Array([from, end]), PackedFloat32Array([damage]), [ref], Color(1.0, 0.75, 0.35), sound, 60.0)
        return
    if not hit.is_empty():
        end = hit["position"]
        var col = hit["collider"]
        if ai and col != null and not (col.is_in_group("player") or col.is_in_group("squad") or col.is_in_group("vehicles")):
            col = null      # Tan gunners only hurt the green side
        if col != null and col.has_method("take_damage"):
            var killed: bool = col.take_damage(damage, global_position, end, false)
            if driver:
                driver.shots_hit += 1
                driver.hit_confirmed.emit(killed)
        else:
            Fx.impact(level, end, hit["normal"])
    if driver:
        driver.shots_fired += 1
    if ai:
        ai_shots += 1
    if level.net:
        level.net.fx_shot(from, end, Color(1.0, 0.45, 0.3) if ai else Color(1.0, 0.75, 0.35), sound, -3.0 if ai else 0.0)
    else:
        Fx.tracer(level, from, end, Color(1.0, 0.45, 0.3) if ai else Color(1.0, 0.75, 0.35))
        Fx.muzzle_flash(level, from)
        Game.play_sfx(sound, from, -3.0 if ai else 0.0)
    if not ai:
        level.make_noise(from, 60.0)


# ---------------------------------------------------------------- damage ----

func take_damage(amount: float, _source: Vector3, hit_pos: Vector3, explosive := false) -> bool:
    if not alive:
        return false
    if not ai and level.is_protected(self):
        return false        # safe zone
    if not explosive:
        amount *= k["bullet_armor"]
        Fx.impact(level, hit_pos, Vector3.UP)
    hp -= amount
    if ai:
        hear(_source)
    if driver:
        driver.took_damage.emit(amount * 0.5)
        driver.shake = maxf(driver.shake, 0.25)
    if hp <= 0.0:
        _destroy()
    return false


func _destroy() -> void:
    alive = false
    hp = 0.0
    remove_from_group("damageable")
    var p := global_position + Vector3(0, 1.2, 0)
    level.boom(p, 7.0, 6.0)
    Fx.fire(level, p, 1.5)
    for m in mats:
        m.albedo_color = m.albedo_color.darkened(0.7)
        m.roughness = 0.9
    engine.stop()
    level.apply_explosion(p, 6.0, 60.0)   # before ejecting, so the driver isn't hit twice
    if ai:
        level.on_enemy_vehicle_destroyed(self)
    var d = driver
    exit_vehicle()
    if d != null:
        d.take_damage(35.0, p, d.global_position, true)
        level.notify("VEHICLE DESTROYED - BAIL OUT!", 2.0)
    for m in passengers.duplicate():
        if m != null and is_instance_valid(m):
            m.dismount(true)


## Non-host PCs: the host says this vehicle was destroyed.
func _destroy_visual() -> void:
    alive = false
    hp = 0.0
    remove_from_group("damageable")
    Fx.fire(level, global_position + Vector3(0, 1.2, 0), 1.5)
    for m in mats:
        m.albedo_color = m.albedo_color.darkened(0.7)
        m.roughness = 0.9
    engine.stop()
    var d = driver
    exit_vehicle()
    if d != null:
        d.take_damage(35.0, global_position, d.global_position, true)
        level.notify("VEHICLE DESTROYED - BAIL OUT!", 2.0)


# -------------------------------------------------------------- Tan AI ----

## Alerts this vehicle to a noise / attacker position.
func hear(pos: Vector3) -> void:
    if not ai or not alive:
        return
    if ai_alert <= 0.0:
        _ai_react = randf_range(0.6, 1.2) * Game.enemy_reaction_mult()
    ai_alert = maxf(ai_alert, 6.0)
    ai_last_seen = pos


## Whatever the AI should shoot: the player on foot, or the vehicle they drive.
func _ai_target() -> Node3D:
    var p = level.nearest_ai_target(global_position) if level else null
    if p == null or not is_instance_valid(p) or not p.alive:
        return null
    if level.is_protected(p.vehicle if p.vehicle != null else p):
        return null            # safe zone
    return p.vehicle if p.vehicle != null else p


## Returns Vector2(throttle, steer) and handles aiming/firing.
func _ai_update(delta: float) -> Vector2:
    var a: Dictionary = AI[kind]
    _ai_ram_cd = maxf(0.0, _ai_ram_cd - delta)
    _ai_react = maxf(0.0, _ai_react - delta)
    var tgt := _ai_target()
    var tpos := Vector3.ZERO
    var dist := 99999.0
    if tgt != null:
        tpos = tgt.global_position + Vector3(0, 1.0, 0)
        dist = global_position.distance_to(tpos)

    _ai_los_t -= delta
    if _ai_los_t <= 0.0:
        _ai_los_t = randf_range(0.2, 0.35)
        _ai_los = false
        if tgt != null and dist < a["sight"] * 1.3:
            var ex: Array[RID] = [get_rid()]
            var eye := global_position + Vector3(0, k["size"].y + 0.3, 0)
            var hit := Fx.ray(self, eye, tpos, 1, ex)
            _ai_los = hit.is_empty() or hit["collider"] == tgt
    if _ai_los and dist < a["sight"]:
        if ai_alert <= 0.0:
            _ai_react = randf_range(0.6, 1.2) * Game.enemy_reaction_mult()
        ai_alert = 6.0
        ai_last_seen = tpos
    else:
        ai_alert = maxf(0.0, ai_alert - delta)

    # ---- where to drive ----
    var dest := _ai_patrol
    var throttle_cap := 0.45
    var hold := false
    if ai_alert > 0.0:
        throttle_cap = 1.0
        var pref: float = a["pref_dist"]
        var to_t := ai_last_seen - global_position
        to_t.y = 0.0
        var d := to_t.length()
        if kind == "tank":
            if d > pref + 10.0 or not _ai_los:
                dest = ai_last_seen
            elif d < pref - 15.0:
                dest = global_position - to_t.normalized() * 12.0
            else:
                hold = true
        else:
            if d > pref + 12.0 or not _ai_los or _ai_charge_t > 0.0:
                dest = ai_last_seen
            else:
                # Circle the target at roughly the preferred distance, but keep the
                # circling point out in the open (not inside a building).
                var radial := -to_t.normalized()
                var tangent := radial.cross(Vector3.UP) * _ai_orbit
                dest = _ai_clear_point(ai_last_seen, ai_last_seen + radial * pref + tangent * 14.0)
        if global_position.distance_to(home) > a["leash"]:
            dest = home
    else:
        _ai_patrol_t -= delta
        if _ai_patrol_t <= 0.0 or global_position.distance_to(_ai_patrol) < 5.0:
            _ai_patrol_t = randf_range(8.0, 14.0)
            var ang := randf() * TAU
            _ai_patrol = home + Vector3(cos(ang), 0, sin(ang)) * randf_range(6.0, 18.0)

    dest = level.outside_safe_zone(dest, global_position)
    # ---- steering ----
    var to_d := dest - global_position
    to_d.y = 0.0
    var throttle := 0.0
    var steer := 0.0
    if not hold and to_d.length() > 4.0:
        var want := atan2(-to_d.x, -to_d.z)
        var diff := wrapf(want - rotation.y, -PI, PI)
        steer = clampf(diff * 2.0, -1.0, 1.0)
        throttle = throttle_cap
        if k["pivot_turn"] and absf(diff) > 0.7:
            throttle = 0.0                      # tanks turn on the spot first
        elif absf(diff) > 1.8:
            throttle *= 0.5
        steer = clampf(steer + _ai_avoid(), -1.0, 1.0)
    elif hold and ai_alert > 0.0 and k["pivot_turn"]:
        # Hold position but keep the front armour toward the target.
        var face := ai_last_seen - global_position
        var diff2 := wrapf(atan2(-face.x, -face.z) - rotation.y, -PI, PI)
        if absf(diff2) > 0.5:
            steer = clampf(diff2, -1.0, 1.0)

    _ai_charge_t = maxf(0.0, _ai_charge_t - delta)
    _ai_stuck_decay -= delta
    if _ai_stuck_decay <= 0.0:
        _ai_stuck_count = 0
    # Unstick: if we want to move but can't, back up and turn the other way.
    if _ai_reverse_t > 0.0:
        _ai_reverse_t -= delta
        throttle = -0.8
        steer = -steer if steer != 0.0 else 1.0
    elif throttle > 0.2 and Vector2(get_real_velocity().x, get_real_velocity().z).length() < 1.0:
        _ai_stuck_t += delta
        if _ai_stuck_t > 1.2:
            _ai_stuck_t = 0.0
            _ai_reverse_t = 1.3
            _ai_orbit = -_ai_orbit
            _ai_patrol_t = 0.0
            _ai_stuck_count += 1
            _ai_stuck_decay = 8.0
            if _ai_stuck_count >= 2:
                _ai_charge_t = 4.0      # circling keeps failing here; just charge
    else:
        _ai_stuck_t = 0.0

    # Never drive into the safe zone: the destination is kept outside it, but
    # chasing or circling can still cut across. At the edge, turn away (or back
    # out if we're facing in).
    if level.safe_radius > 0.0:
        var fwd := -global_transform.basis.z
        var ahead: Vector3 = global_position + fwd * (absf(speed) * 0.8 + k["size"].z)
        if level.in_safe_zone(ahead) or level.in_safe_zone(global_position):
            var out: Vector3 = global_position - level.safe_center
            out.y = 0.0
            var diff3 := wrapf(atan2(-out.x, -out.z) - rotation.y, -PI, PI)
            steer = clampf(diff3 * 2.0, -1.0, 1.0)
            throttle = 0.6 if absf(diff3) < 1.2 else -0.6

    _ai_shoot(delta, tgt, tpos, dist)
    return Vector2(throttle, steer)


## Pulls `want` back toward `from` if there's a wall in between.
func _ai_clear_point(from: Vector3, want: Vector3) -> Vector3:
    var ex: Array[RID] = [get_rid()]
    var a := from + Vector3(0, 1.0, 0)
    var hit := Fx.ray(self, a, want + Vector3(0, 1.0, 0), 1, ex)
    if hit.is_empty():
        return want
    var p: Vector3 = hit["position"]
    return Vector3(p.x, want.y, p.z) - (want - from).normalized() * 4.0


## Whisker rays ahead: steer away from whichever side is more blocked.
func _ai_avoid() -> float:
    var ex: Array[RID] = [get_rid()]
    var o := global_position + Vector3(0, 1.0, 0)
    var fwd := -global_transform.basis.z
    var look: float = 5.0 + absf(speed) * 0.5 + k["size"].z * 0.5
    var hl := Fx.ray(self, o, o + fwd.rotated(Vector3.UP, 0.45) * look, 1 | 4, ex)
    var hr := Fx.ray(self, o, o + fwd.rotated(Vector3.UP, -0.45) * look, 1 | 4, ex)
    var dl: float = look if hl.is_empty() else o.distance_to(hl["position"])
    var dr: float = look if hr.is_empty() else o.distance_to(hr["position"])
    if dl >= look and dr >= look:
        return 0.0
    return 0.8 if dl > dr else -0.8


func _ai_shoot(delta: float, tgt: Node3D, tpos: Vector3, dist: float) -> void:
    if tgt == null or ai_alert <= 0.0:
        cam_pitch = -0.18
        return
    # Aim (with some lead) and let the turret traverse toward it.
    var lead: Vector3 = tgt.velocity * clampf(dist / 90.0, 0.0, 0.6)
    var aim := (tpos if _ai_los else ai_last_seen) + lead
    var tur := turret.global_position if turret else global_position + Vector3(0, 2, 0)
    var to := aim - tur
    cam_yaw = atan2(-to.x, -to.z)
    cam_pitch = atan2(to.y, Vector2(to.x, to.z).length()) - 0.18
    if not _ai_los or _ai_react > 0.0:
        return
    var a: Dictionary = AI[kind]
    var mdir := -muzzle.global_transform.basis.z
    var aligned := mdir.dot((aim - muzzle.global_position).normalized())
    if kind == "tank":
        if aligned > 0.995 and fire_cd <= 0.0 and dist < a["sight"]:
            _ai_aim = aim + Vector3(randf_range(-1, 1), randf_range(-0.3, 0.6), randf_range(-1, 1)) * dist * 0.02 * Game.enemy_spread_mult()
            fire_primary()
        if dist < a["coax_range"] and aligned > 0.97:
            _ai_mg_burst(delta, aim, true)
    elif aligned > 0.96:
        _ai_mg_burst(delta, aim, false)


func _ai_mg_burst(delta: float, aim: Vector3, coax: bool) -> void:
    var a: Dictionary = AI[kind]
    _ai_burst_cd -= delta
    if _ai_burst <= 0:
        if _ai_burst_cd <= 0.0:
            _ai_burst = a["burst"]
        return
    _ai_aim = aim
    if coax:
        if fire2_cd <= 0.0:
            fire2_cd = 0.11
            _bullet(coax_muzzle.global_position, a["mg_damage"] * Game.enemy_damage_mult(), a["mg_spread"] * Game.enemy_spread_mult(), "lmg")
            _ai_burst -= 1
    elif fire_cd <= 0.0:
        fire_primary()              # sets its own cooldown
        fire_cd = 0.11
        _ai_burst -= 1
    if _ai_burst <= 0:
        _ai_burst_cd = a["burst_pause"] * randf_range(0.8, 1.3)
