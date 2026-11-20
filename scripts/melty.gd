extends CharacterBody3D
## MELTDOWN mode enemy: a half-melted Tan soldier. It spawns outside the
## basement, shambles to its assigned barricade, tears the planks off, climbs
## through, then hunts the nearest green soldier with the navigation mesh and
## swipes at them. Later waves make them tougher, faster and harder-hitting.

const Soldier = preload("res://scripts/plastic_soldier.gd")
const Fx = preload("res://scripts/fx.gd")

const MELT_TAN := Color(0.74, 0.55, 0.36)
const GRAVITY := 16.0
const REACH := 1.7

## Melty kinds. hp / speed / dmg multiply the wave's base numbers; size scales
## the body; coins is what a kill pays (+40 for a headshot); planks is how many
## boards one swipe rips off.
const KINDS := {
    "shambler": {"hp": 1.0, "speed": 1.0, "dmg": 1.0, "size": Vector3(1.08, 0.85, 1.08), "color": MELT_TAN, "coins": 60, "planks": 1, "name": "MELTY"},
    "sprinter": {"hp": 0.6, "speed": 1.7, "dmg": 0.7, "size": Vector3(0.85, 0.95, 0.85), "color": Color(0.85, 0.72, 0.48), "coins": 50, "planks": 1, "name": "SPRINTER"},
    "popper": {"hp": 0.8, "speed": 1.1, "dmg": 0.0, "size": Vector3(1.25, 0.82, 1.25), "color": Color(0.9, 0.55, 0.25), "coins": 70, "planks": 1, "name": "POPPER"},
    "brute": {"hp": 4.0, "speed": 0.7, "dmg": 2.0, "size": Vector3(1.55, 1.35, 1.55), "color": Color(0.55, 0.38, 0.24), "coins": 120, "planks": 2, "name": "BRUTE"},
    "spitter": {"hp": 0.9, "speed": 0.9, "dmg": 0.8, "size": Vector3(1.0, 0.9, 1.0), "color": Color(0.7, 0.65, 0.35), "coins": 90, "planks": 1, "name": "SPITTER"},
    "big_melt": {"hp": 22.0, "speed": 0.75, "dmg": 2.6, "size": Vector3(2.4, 2.2, 2.4), "color": Color(0.5, 0.3, 0.2), "coins": 500, "planks": 99, "name": "THE BIG MELT", "boss": true},
    "molten_major": {"hp": 18.0, "speed": 0.8, "dmg": 2.0, "size": Vector3(2.1, 2.0, 2.1), "color": Color(0.85, 0.42, 0.15), "coins": 500, "planks": 99, "name": "THE MOLTEN MAJOR", "boss": true},
}

enum { OUTSIDE, BREAKING, CLIMBING, HUNTING }

var level: Node
var mode: Node                    # the Meltdown controller
var barricade: Node
var hp := 60.0
var max_hp := 60.0
var speed := 2.0
var damage := 20.0
var alive := true
var model
var state := OUTSIDE
var agent: NavigationAgent3D
var _attack_cd := 0.0
var _tear_cd := 0.0
var _repath_t := 0.0
var _stuck_t := 0.0
var lost_t := 0.0                 # seconds without getting any closer to where it's going
var _lost_best := INF
var rescues := 0                  # tests read it
var _groan_t := 0.0
var _target = null
var type := "melty"               # read by shared code that expects enemies to have a type
var kind := "shambler"
var k: Dictionary
var is_boss := false
var _ability_t := 0.0             # spit / slam timer
var _summon_t := 0.0
var _fuse := -1.0                 # popper: counting down to boom
var _belly: StandardMaterial3D
# ---- co-op: on non-host PCs a Melty is a puppet that follows the host ----
var net_id := 0
var net_puppet := false
var _net_pos := Vector3.ZERO
var _net_yaw := 0.0
var _net_hs := 0.0
var _net_have := false


func setup(lvl: Node, md: Node, b: Node, pos: Vector3, wave_hp: float, wave_speed: float, wave_damage: float, what := "shambler") -> void:
    level = lvl
    mode = md
    barricade = b
    position = pos
    kind = what
    k = KINDS[kind]
    is_boss = k.get("boss", false)
    hp = wave_hp * k["hp"]
    max_hp = hp
    speed = wave_speed * k["speed"]
    damage = wave_damage * k["dmg"]


func _ready() -> void:
    add_to_group("enemies")
    add_to_group("damageable")
    collision_layer = 4
    collision_mask = 1 | 4
    floor_snap_length = 0.4
    if k.is_empty():
        k = KINDS["shambler"]
    var sz: Vector3 = k["size"]
    var cap := CapsuleShape3D.new()
    cap.radius = 0.35 * minf(sz.x, 2.2) / 1.08 if sz.x > 1.1 else 0.35
    cap.height = maxf(1.7 * sz.y / 0.85, cap.radius * 2.0 + 0.1)
    var cs := CollisionShape3D.new()
    cs.shape = cap
    cs.position.y = cap.height * 0.5
    add_child(cs)
    model = Soldier.create()
    add_child(model)
    var c: Color = k["color"].lerp(Color(0.6, 0.42, 0.3), randf() * 0.25)
    model.build(c, "none")
    # Melted: shorter, lumpier, leaning forward, with drips of plastic on it.
    model.scale = sz * Vector3(1, randf_range(0.94, 1.06), 1)
    model.rotation.x = deg_to_rad(randf_range(8.0, 16.0))
    _decorate(c)
    var drip := StandardMaterial3D.new()
    drip.albedo_color = c.darkened(0.15)
    drip.roughness = 0.15
    for i in 4:
        var d := MeshInstance3D.new()
        var sm := SphereMesh.new()
        sm.radius = randf_range(0.07, 0.13)
        sm.height = sm.radius * randf_range(2.2, 3.2)
        d.mesh = sm
        d.material_override = drip
        d.position = Vector3(randf_range(-0.25, 0.25), randf_range(0.9, 1.6), randf_range(-0.2, 0.2)) * Vector3(sz.x, sz.y / 0.85, sz.z)
        add_child(d)
    agent = NavigationAgent3D.new()
    agent.path_desired_distance = 0.8
    agent.target_desired_distance = 1.2
    agent.radius = 0.4
    agent.height = 1.7
    add_child(agent)
    _groan_t = randf_range(1.0, 5.0)
    _ability_t = randf_range(2.0, 4.0)
    _summon_t = 10.0


## Extra looks per kind: the popper's glowing belly, the spitter's green
## drool, the bosses' glowing eyes and crown of drips.
func _decorate(c: Color) -> void:
    var sz: Vector3 = k["size"]
    match kind:
        "popper":
            _belly = StandardMaterial3D.new()
            _belly.albedo_color = Color(1.0, 0.55, 0.1)
            _belly.emission_enabled = true
            _belly.emission = Color(1.0, 0.45, 0.05)
            _belly.emission_energy_multiplier = 1.5
            _blob(Vector3(0, 0.95, -0.25), 0.42, _belly)
        "spitter":
            var green := StandardMaterial3D.new()
            green.albedo_color = Color(0.5, 0.9, 0.2)
            green.emission_enabled = true
            green.emission = Color(0.4, 0.9, 0.1)
            green.emission_energy_multiplier = 0.8
            for i in 3:
                _blob(Vector3(randf_range(-0.12, 0.12), 1.3 - i * 0.12, -0.3), 0.07, green)
        "big_melt", "molten_major":
            var eye := StandardMaterial3D.new()
            eye.albedo_color = Color(1.0, 0.3, 0.1) if kind == "big_melt" else Color(1.0, 0.9, 0.2)
            eye.emission_enabled = true
            eye.emission = eye.albedo_color
            eye.emission_energy_multiplier = 3.0
            for x in [-0.12, 0.12]:
                _blob(Vector3(x * sz.x, 1.62 * sz.y / 0.85, -0.3 * sz.z), 0.06 * sz.x, eye)
            var drip := StandardMaterial3D.new()
            drip.albedo_color = c.darkened(0.25)
            drip.roughness = 0.1
            for i in 6:
                var a := i * TAU / 6.0
                _blob(Vector3(cos(a) * 0.3 * sz.x, 1.9 * sz.y / 0.85, sin(a) * 0.3 * sz.z), 0.12 * sz.x, drip)


func _blob(pos: Vector3, r: float, m: Material) -> void:
    var d := MeshInstance3D.new()
    var sm := SphereMesh.new()
    sm.radius = r
    sm.height = r * 2.0
    d.mesh = sm
    d.material_override = m
    d.position = pos
    add_child(d)


func _physics_process(delta: float) -> void:
    if not alive:
        return
    if net_puppet:
        var kk := minf(1.0, delta * 12.0)
        position = position.lerp(_net_pos, kk) if position.distance_to(_net_pos) < 8.0 else _net_pos
        rotation.y = lerp_angle(rotation.y, _net_yaw, kk)
        model.animate(delta, _net_hs, false)
        return
    if not is_on_floor():
        velocity.y -= GRAVITY * delta
    else:
        velocity.y = -0.5
    _attack_cd = maxf(0.0, _attack_cd - delta)
    _groan_t -= delta
    if _groan_t <= 0.0:
        _groan_t = randf_range(4.0, 9.0)
        Game.play_sfx("melt", global_position, -16.0)
    var dir := Vector3.ZERO
    var spd := speed
    match state:
        OUTSIDE:
            var to: Vector3 = barricade.outside_point - global_position
            to.y = 0.0
            if to.length() < 0.9:
                state = BREAKING
            else:
                dir = to.normalized()
        BREAKING:
            _face(barricade.inside_point - global_position)
            if barricade.planks <= 0:
                state = CLIMBING
            else:
                _tear_cd -= delta
                if _tear_cd <= 0.0:
                    _tear_cd = 1.4
                    model.gesture("Punch")
                    for i in mini(k["planks"], barricade.planks):
                        barricade.tear()
                    if is_boss:
                        mode.boss_smash(self)
        CLIMBING:
            var to2: Vector3 = barricade.inside_point - global_position
            to2.y = 0.0
            if barricade.planks > 0:
                state = BREAKING     # boarded up again before we got through
            elif to2.length() < 0.8:
                state = HUNTING
            else:
                dir = to2.normalized()
                spd = minf(speed, 2.5)
        HUNTING:
            dir = _hunt(delta)
            dir = _abilities(delta, dir)
    velocity.x = move_toward(velocity.x, dir.x * spd, 20.0 * delta)
    velocity.z = move_toward(velocity.z, dir.z * spd, 20.0 * delta)
    move_and_slide()
    var hs := Vector2(velocity.x, velocity.z).length()
    if dir != Vector3.ZERO:
        _face(dir)
        _stuck_t = _stuck_t + delta if hs < spd * 0.15 else 0.0
        if _stuck_t > 2.5:
            _stuck_t = 0.0
            velocity += dir.cross(Vector3.UP) * [-3.0, 3.0].pick_random()   # shoulder past whatever's in the way
    _unstick(delta)
    model.animate(delta, hs, false)


## Safety net so a wave can always end: a Melty that has fallen off its
## climb, or stops getting any closer to its crack (or, once inside, to
## anyone to eat) for long enough, is put back where it can carry on.
func _unstick(delta: float) -> void:
    var goal: Vector3
    var limit := 8.0
    match state:
        OUTSIDE:
            goal = barricade.outside_point
            limit = 5.0
        CLIMBING:
            goal = barricade.inside_point
        HUNTING:
            if _target == null or not is_instance_valid(_target):
                lost_t = 0.0
                _lost_best = INF
                return
            goal = _target.global_position
            limit = 15.0
        _:
            lost_t = 0.0
            _lost_best = INF
            return
    var d := global_position.distance_to(goal)
    var fell: bool = state != HUNTING and global_position.y < barricade.global_position.y - 3.0
    if d < _lost_best - 0.75:
        _lost_best = d
        lost_t = 0.0
    else:
        lost_t += delta
    if not fell and (lost_t < limit or (state == HUNTING and d < 6.0)):
        return
    rescues += 1
    lost_t = 0.0
    _lost_best = INF
    velocity = Vector3.ZERO
    if state == HUNTING:
        # Come back in through the open crack nearest whoever it's after.
        var best = barricade
        var bd := INF
        for b in mode.barricades:
            if mode.sections[b.section]["open"]:
                var bdist: float = b.inside_point.distance_to(goal)
                if bdist < bd:
                    bd = bdist
                    best = b
        barricade = best
        global_position = best.inside_point + Vector3(0, 0.3, 0)
        _repath_t = 0.0
    else:
        global_position = barricade.outside_point + Vector3(0, 0.3, 0)
        state = BREAKING if barricade.planks > 0 else CLIMBING


func _hunt(_delta: float) -> Vector3:
    _repath_t -= _delta
    if _repath_t <= 0.0 or _target == null or not is_instance_valid(_target) or not _target.alive:
        _repath_t = 0.35
        _target = mode.nearest_prey(global_position)
        if _target != null:
            agent.target_position = _target.global_position
    if _target == null:
        return Vector3.ZERO
    var to_t: Vector3 = _target.global_position - global_position
    to_t.y = 0.0
    if to_t.length() < REACH * (1.6 if is_boss else 1.0):
        _face(to_t)
        if kind == "popper":
            _light_fuse()
            return Vector3.ZERO
        if _attack_cd <= 0.0:
            _attack_cd = 1.1
            model.gesture("Punch")
            _target.take_damage(damage, global_position, _target.global_position + Vector3(0, 1.0, 0), false)
            Game.play_sfx("hit", global_position, -6.0)
        return Vector3.ZERO
    var next := agent.get_next_path_position()
    var d := next - global_position
    d.y = 0.0
    if d.length() < 0.05 or agent.is_navigation_finished():
        d = to_t                  # no path (yet): head straight for them
    return d.normalized()


## Kind-specific moves while hunting. Returns the (possibly changed) move direction.
func _abilities(delta: float, dir: Vector3) -> Vector3:
    if _fuse >= 0.0:
        _fuse -= delta
        _belly.emission_energy_multiplier = 1.5 + 6.0 * absf(sin(_fuse * 25.0))
        if _fuse <= 0.0:
            _pop()
        return Vector3.ZERO
    if _target == null or not is_instance_valid(_target):
        return dir
    var to_t: Vector3 = _target.global_position - global_position
    var dist := to_t.length()
    match kind:
        "spitter", "molten_major":
            var keep := 11.0 if kind == "spitter" else 14.0
            _ability_t -= delta
            if dist < 26.0 and _can_see(_target):
                _face(to_t)
                if _ability_t <= 0.0:
                    _ability_t = 2.4 if kind == "spitter" else 3.5
                    var shots := 1 if kind == "spitter" else 4
                    for i in shots:
                        _spit(_target.global_position + Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5)) * (0.0 if i == 0 else 1.0))
                if dist < keep:
                    return Vector3.ZERO if kind == "molten_major" else -to_t.normalized() * 0.4
        "big_melt":
            _ability_t -= delta
            if _ability_t <= 0.0 and dist < 7.0:
                _ability_t = 6.0
                _slam()
    if is_boss:
        _summon_t -= delta
        if _summon_t <= 0.0:
            _summon_t = 14.0
            mode.boss_summon(self)
    return dir


func _can_see(t) -> bool:
    var ex: Array[RID] = [get_rid()]
    return Fx.ray(self, global_position + Vector3(0, 1.4 * k["size"].y / 0.85, 0), t.global_position + Vector3(0, 1.0, 0), 1, ex).is_empty()


func _spit(at: Vector3) -> void:
    model.gesture("Punch")
    var from: Vector3 = global_position + Vector3(0, 1.5 * k["size"].y / 0.85, 0)
    spawn_spit(level, mode, from, at, damage * (0.8 if is_boss else 1.0), false)
    if level.net != null:
        level.net.md_spit(net_id, from, at)        # co-op: everyone sees it fly


## A glob of acid. visual_only = a harmless copy on a co-op teammate's PC
## (the host's real one does the damage and the splash).
static func spawn_spit(lvl: Node, md: Node, from: Vector3, at: Vector3, dmg: float, visual_only: bool) -> void:
    var b := Spit.new()
    b.setup(lvl, md, from, at, dmg)
    b.visual_only = visual_only
    lvl.add_child(b)
    Game.play_sfx("throw", from, -4.0)


## The Big Melt: a ground slam that hurts every green soldier nearby.
func _slam() -> void:
    model.gesture("Punch")
    level.boom(global_position, 4.0, -2.0)
    for t in mode.green_targets():
        var d: float = t.global_position.distance_to(global_position)
        if d < 7.0:
            t.take_damage(damage * (1.0 - d / 9.0), global_position, t.global_position + Vector3(0, 1, 0), true)
    if level.player.global_position.distance_to(global_position) < 14.0:
        level.player.shake = maxf(level.player.shake, 1.0)


func _light_fuse() -> void:
    if _fuse < 0.0:
        _fuse = 0.7
        Game.play_sfx("empty", global_position, 2.0)


## Popper: bursts in a splash of molten plastic that hurts green soldiers only.
func _pop() -> void:
    _fuse = -2.0                  # (so _die doesn't burst it a second time)
    var p := global_position + Vector3(0, 0.8, 0)
    level.boom(p, 3.5, 0.0)
    for t in mode.green_targets():
        var d: float = t.global_position.distance_to(global_position)
        if d < 4.5:
            t.take_damage(mode.popper_damage() * (1.0 - d / 6.0), p, t.global_position + Vector3(0, 1, 0), true)
    if alive:
        _die(false, false)


func _face(d: Vector3) -> void:
    if Vector2(d.x, d.z).length() > 0.01:
        rotation.y = lerp_angle(rotation.y, atan2(-d.x, -d.z), 0.25)


## The drips, lumps and glowing bits stuck on a Melty sag and melt away with
## the body (they used to stay floating where it had been).
func _melt_extras() -> void:
    for c in get_children():
        if c is MeshInstance3D:
            var tw := c.create_tween()
            tw.tween_interval(randf_range(0.3, 0.8))
            tw.tween_property(c, "position:y", 0.05, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            tw.parallel().tween_property(c, "scale", c.scale * Vector3(1.6, 0.15, 1.6), 0.9)
            tw.tween_property(c, "scale", Vector3.ZERO, 1.5)


## Host snapshot for this Melty (non-host PCs).
func net_apply(pos: Vector3, yaw: float, hs: float, flags: int) -> void:
    _net_pos = pos
    _net_yaw = yaw
    _net_hs = hs
    if not _net_have:
        position = pos
        rotation.y = yaw
        _net_have = true
    if flags & 2:
        model.gesture("Punch")


## The host says this Melty melted: play it out here, no rewards or rules.
func die_visual() -> void:
    if not alive:
        return
    alive = false
    remove_from_group("enemies")
    remove_from_group("damageable")
    collision_layer = 0
    collision_mask = 0
    set_physics_process(false)
    model.melt()
    _melt_extras()
    Game.play_sfx("melt", global_position, -2.0)
    get_tree().create_timer(9.0).timeout.connect(func():
        if is_instance_valid(self):
            queue_free())


func hear(_pos: Vector3) -> void:
    pass                          # they're already coming for you


func take_damage(amount: float, source: Vector3, hit_pos: Vector3, explosive := false) -> bool:
    if not alive or net_puppet:
        return false              # co-op: the host decides damage
    var headshot: bool = not explosive and (hit_pos.y - global_position.y) > 1.25 * k["size"].y / 0.85
    if headshot:
        amount *= 2.0
    hp -= amount
    model.hit_flash()
    model.damage_mark(hit_pos if hit_pos.distance_to(global_position) < 3.0 * k["size"].y else global_position + Vector3(0, 1.0, 0), explosive)
    model.set_wear(1.0 - hp / max_hp)
    Fx.blood_plastic(level, hit_pos, MELT_TAN)
    var by_player: bool = mode.is_player_damage(source, explosive)
    if hp <= 0.0:
        _die(headshot, by_player)
        return true
    if by_player:
        mode.award(10, hit_pos, false)
    return false


func _die(headshot: bool, by_player: bool) -> void:
    alive = false
    remove_from_group("enemies")
    remove_from_group("damageable")
    collision_layer = 0
    collision_mask = 0
    set_physics_process(false)
    model.melt()
    _melt_extras()
    Game.play_sfx("melt", global_position, -2.0)
    level.on_enemy_killed(self, headshot)
    if by_player:
        mode.award(int(k["coins"]) + (40 if headshot else 0), global_position + Vector3(0, 1.4, 0), true)
    if kind == "popper" and _fuse != -2.0:
        _fuse = -2.0
        _pop_on_death()
    mode.on_melty_died(self)
    var t := Timer.new()
    t.wait_time = 9.0
    t.one_shot = true
    t.autostart = true
    t.timeout.connect(queue_free)
    add_child(t)



## A popper that's shot still bursts (just a beat later, where it fell).
func _pop_on_death() -> void:
    var p := global_position
    get_tree().create_timer(0.25).timeout.connect(func():
        if not is_instance_valid(level):
            return
        level.boom(p + Vector3(0, 0.6, 0), 3.5, 0.0)
        for t in mode.green_targets():
            var d: float = t.global_position.distance_to(p)
            if d < 4.5:
                t.take_damage(mode.popper_damage() * (1.0 - d / 6.0), p, t.global_position + Vector3(0, 1, 0), true))


## Molten plastic lobbed by spitters and the Molten Major: an arc that splashes
## where it lands, hurting green soldiers within 2.5 m.
class Spit extends Node3D:
    var level: Node
    var mode: Node
    var vel := Vector3.ZERO
    var damage := 15.0
    var life := 4.0
    var visual_only := false

    func setup(lvl: Node, md: Node, from: Vector3, at: Vector3, dmg: float) -> void:
        level = lvl
        mode = md
        position = from
        damage = dmg
        var flat := Vector3(at.x - from.x, 0, at.z - from.z)
        var t := clampf(flat.length() / 14.0, 0.5, 1.6)       # flight time
        vel = flat / t
        vel.y = (at.y - from.y + 0.5 * 16.0 * t * t) / t

    func _ready() -> void:
        var mi := MeshInstance3D.new()
        var sm := SphereMesh.new()
        sm.radius = 0.22
        sm.height = 0.44
        mi.mesh = sm
        var m := StandardMaterial3D.new()
        m.albedo_color = Color(1.0, 0.55, 0.1)
        m.emission_enabled = true
        m.emission = Color(1.0, 0.45, 0.05)
        m.emission_energy_multiplier = 2.5
        mi.material_override = m
        add_child(mi)

    func _physics_process(delta: float) -> void:
        life -= delta
        var step := vel * delta
        vel.y -= 16.0 * delta
        var q := PhysicsRayQueryParameters3D.create(global_position, global_position + step, 1 | 2)
        var hit := get_world_3d().direct_space_state.intersect_ray(q)
        if not hit.is_empty() or life <= 0.0:
            _splash(hit["position"] if not hit.is_empty() else global_position)
            return
        global_position += step

    func _splash(p: Vector3) -> void:
        set_physics_process(false)
        if visual_only:
            queue_free()                  # the host's copy splashes for everyone
            return
        level.boom(p, 1.2, -10.0)
        for t in mode.green_targets():
            if t.global_position.distance_to(p) < 2.5:
                t.take_damage(damage, p, t.global_position + Vector3(0, 1, 0), false)
        queue_free()
