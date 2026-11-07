extends CharacterBody3D
## Tan Army soldier AI: patrol -> investigate -> combat, with line-of-sight,
## hearing, burst fire, strafing and the obligatory melting death.

const Soldier = preload("res://scripts/plastic_soldier.gd")
const Fx = preload("res://scripts/fx.gd")
const Rocket = preload("res://scripts/rocket.gd")

const TAN := Color(0.80, 0.68, 0.44)
const OFFICER_TAN := Color(0.68, 0.53, 0.30)
const GRAVITY := 16.0

const TYPES := {
    "rifleman": {"hp": 60.0, "damage": 6.0, "interval": 0.13, "burst": 3, "pause": 1.3, "range": 55.0,
        "sight": 45.0, "speed": 3.6, "spread": 3.2, "model": "rifle", "kind": "hitscan", "sound": "enemy_rifle"},
    "gunner": {"hp": 100.0, "damage": 4.5, "interval": 0.09, "burst": 8, "pause": 1.9, "range": 50.0,
        "sight": 45.0, "speed": 2.6, "spread": 4.5, "model": "lmg", "kind": "hitscan", "sound": "lmg"},
    "rocketeer": {"hp": 70.0, "damage": 32.0, "interval": 0.1, "burst": 1, "pause": 4.5, "range": 65.0,
        "sight": 50.0, "speed": 3.0, "spread": 1.5, "model": "launcher", "kind": "rocket", "sound": "rocket"},
    "sniper": {"hp": 50.0, "damage": 28.0, "interval": 0.1, "burst": 1, "pause": 3.6, "range": 120.0,
        "sight": 95.0, "speed": 0.0, "spread": 0.9, "model": "sniper", "kind": "hitscan", "sound": "sniper"},
    "officer": {"hp": 320.0, "damage": 8.0, "interval": 0.12, "burst": 4, "pause": 1.1, "range": 60.0,
        "sight": 50.0, "speed": 3.2, "spread": 2.5, "model": "rifle", "kind": "hitscan", "sound": "enemy_rifle"},
    "general": {"hp": 900.0, "damage": 6.0, "interval": 0.08, "burst": 10, "pause": 1.4, "range": 60.0,
        "sight": 55.0, "speed": 2.4, "spread": 3.5, "model": "lmg", "kind": "hitscan", "sound": "lmg"},
}

enum { PATROL, INVESTIGATE, COMBAT }

var level: Node
var type := "rifleman"
var s: Dictionary
var hp := 60.0
var alive := true
var is_hvt := false
var model
var home := Vector3.ZERO
var state := PATROL
var move_target := Vector3.ZERO
var think_t := 0.0
var fire_cd := 1.0
var burst_left := 0
var has_los := false
var los_t := 0.0
var lost_t := 0.0
var react_t := 0.0
var strafe := 0.0
var strafe_t := 0.0
var stuck_t := 0.0
var last_known := Vector3.ZERO
var look_yaw := 0.0
# LAN co-op: on non-host PCs enemies are puppets that follow the host's snapshots.
var net_puppet := false
var _net_pos := Vector3.ZERO
var _net_yaw := 0.0
var _net_hspeed := 0.0
var _net_have := false
var _net_shot := false


func setup(lvl: Node, t: String, pos: Vector3, hvt := false) -> void:
    level = lvl
    type = t
    position = pos
    home = pos
    is_hvt = hvt


func _ready() -> void:
    s = TYPES[type]
    hp = s["hp"]
    add_to_group("enemies")
    add_to_group("damageable")
    collision_layer = 4
    collision_mask = 1 | 2 | 4
    floor_snap_length = 0.4
    var cap := CapsuleShape3D.new()
    cap.radius = 0.35
    cap.height = 1.8
    var cs := CollisionShape3D.new()
    cs.shape = cap
    cs.position.y = 0.9
    add_child(cs)
    model = Soldier.create()
    add_child(model)
    model.build(OFFICER_TAN if is_hvt else TAN, s["model"])
    if is_hvt:
        model.scale = Vector3.ONE * (1.4 if type == "general" else 1.12)
        var cap_mi := MeshInstance3D.new()
        var cm := CylinderMesh.new()
        cm.top_radius = 0.22
        cm.bottom_radius = 0.2
        cm.height = 0.12
        cap_mi.mesh = cm
        var red := StandardMaterial3D.new()
        red.albedo_color = Color(0.6, 0.1, 0.08)
        cap_mi.material_override = red
        cap_mi.position = model.hat_offset
        if model.has_method("notify_shot") and model.get("rig") != null:
            cap_mi.scale = Vector3(1.9, 1.3, 1.9)
        model.torso.add_child(cap_mi)
    rotation.y = randf() * TAU
    look_yaw = rotation.y
    move_target = home
    fire_cd = randf_range(0.5, 1.5)
    think_t = randf_range(0.0, 4.0)


func _player():
    if level == null:
        return null
    var p = level.nearest_ai_target(global_position)
    if p == null or not is_instance_valid(p) or not p.alive:
        return null
    if level.is_protected(p.vehicle if p.vehicle != null else p):
        return null            # safe zone: hold fire
    return p


## Host snapshot for this soldier (non-host PCs only).
func net_apply(pos: Vector3, yaw: float, hspeed: float, flags: int) -> void:
    if not net_puppet:
        return
    _net_pos = pos
    _net_yaw = yaw
    _net_hspeed = hspeed
    if not _net_have:
        position = pos
        rotation.y = yaw
        _net_have = true
    if flags & 2:
        model.notify_shot()
    if alive and not (flags & 1):
        _die_visual()


func _physics_process(delta: float) -> void:
    if not alive:
        return
    if net_puppet:
        var k := minf(1.0, delta * 12.0)
        position = position.lerp(_net_pos, k) if position.distance_to(_net_pos) < 8.0 else _net_pos
        rotation.y = lerp_angle(rotation.y, _net_yaw, k)
        model.animate(delta, _net_hspeed, false)
        return
    var p = _player()
    var to_p := Vector3.ZERO
    var dist := 99999.0
    if p != null:
        to_p = p.global_position - global_position
        dist = to_p.length()

    if not is_on_floor():
        velocity.y -= GRAVITY * delta
    else:
        velocity.y = -0.5

    # Cheap LOD for far-away idle troops.
    if dist > 170.0 and state == PATROL:
        velocity.x = 0.0
        velocity.z = 0.0
        move_and_slide()
        return

    los_t -= delta
    if los_t <= 0.0:
        los_t = randf_range(0.15, 0.3)
        has_los = p != null and dist < s["sight"] * 1.8 and _can_see(p)

    if p != null and has_los:
        var sight: float = s["sight"] * (0.65 if p.crouching else 1.0)
        if state == COMBAT or dist < 6.0 or (dist < sight and _in_fov(to_p)):
            if state != COMBAT:
                react_t = randf_range(0.35, 0.8) * Game.enemy_reaction_mult()
                level.make_noise(global_position, 22.0)
            state = COMBAT
            last_known = p.global_position
            lost_t = 0.0
    elif state == COMBAT:
        lost_t += delta
        if lost_t > 2.5 or p == null:
            state = INVESTIGATE
            move_target = last_known

    var desired := Vector3.ZERO
    match state:
        PATROL:
            desired = _patrol(delta)
        INVESTIGATE:
            desired = _investigate(delta)
        COMBAT:
            if p == null:
                state = PATROL
            else:
                desired = _combat(delta, p, to_p, dist)

    # Never walk into the safe zone (and step back out if pushed in).
    if level.safe_radius > 0.0 and desired != Vector3.ZERO and level.in_safe_zone(global_position + desired * 2.0):
        var out: Vector3 = global_position - level.safe_center
        out.y = 0.0
        desired = out.normalized() * 0.6 if level.in_safe_zone(global_position) else Vector3.ZERO
    var spd: float = s["speed"] * (0.55 if state == PATROL else 1.0)
    velocity.x = move_toward(velocity.x, desired.x * spd, 20.0 * delta)
    velocity.z = move_toward(velocity.z, desired.z * spd, 20.0 * delta)
    move_and_slide()

    # Simple unstick: if we want to move but aren't, pick a new side-step.
    var hs := Vector2(velocity.x, velocity.z).length()
    if desired.length() > 0.1 and spd > 0.0 and hs < spd * 0.2:
        stuck_t += delta
        if stuck_t > 0.6:
            stuck_t = 0.0
            strafe = -strafe if strafe != 0.0 else 1.0
            strafe_t = 1.2
            think_t = 0.0
    else:
        stuck_t = 0.0

    rotation.y = lerp_angle(rotation.y, look_yaw, minf(1.0, delta * 7.0))
    model.animate(delta, hs, false)


func _face(dir: Vector3) -> void:
    if Vector2(dir.x, dir.z).length() > 0.01:
        look_yaw = atan2(-dir.x, -dir.z)


func _in_fov(to_p: Vector3) -> bool:
    var fwd := -global_transform.basis.z
    return fwd.dot(Vector3(to_p.x, 0, to_p.z).normalized()) > 0.3


func _can_see(p) -> bool:
    var eye := global_position + Vector3(0, 1.6, 0)
    var chest: Vector3 = p.global_position + Vector3(0, 0.8 if p.crouching else 1.3, 0)
    return Fx.ray(self, eye, chest, 1).is_empty()


func _patrol(delta: float) -> Vector3:
    if s["speed"] <= 0.0:
        think_t -= delta
        if think_t <= 0.0:
            think_t = randf_range(2.0, 5.0)
            look_yaw += randf_range(-1.2, 1.2)
        return Vector3.ZERO
    think_t -= delta
    if think_t <= 0.0:
        think_t = randf_range(3.0, 7.0)
        var a := randf() * TAU
        move_target = home + Vector3(cos(a), 0, sin(a)) * randf_range(2.0, 9.0)
    var d := move_target - global_position
    d.y = 0.0
    if d.length() < 1.0:
        return Vector3.ZERO
    _face(d)
    return d.normalized()


func _investigate(_delta: float) -> Vector3:
    var d := move_target - global_position
    d.y = 0.0
    _face(d)
    if s["speed"] <= 0.0 or d.length() < 2.0:
        state = PATROL
        home = global_position if s["speed"] > 0.0 else home
        think_t = randf_range(2.0, 4.0)
        return Vector3.ZERO
    return d.normalized()


func _combat(delta: float, p, to_p: Vector3, dist: float) -> Vector3:
    var flat := Vector3(to_p.x, 0, to_p.z).normalized()
    _face(flat)
    react_t -= delta
    var dir := Vector3.ZERO
    if s["speed"] > 0.0:
        strafe_t -= delta
        if strafe_t <= 0.0:
            strafe_t = randf_range(1.0, 2.6)
            strafe = [-1.0, 1.0].pick_random() if randf() < 0.7 else 0.0
        var side := flat.cross(Vector3.UP) * strafe
        var rng: float = s["range"]
        if not has_los:
            var d := last_known - global_position
            d.y = 0.0
            dir = d.normalized()
        elif dist > rng * 0.75:
            dir = (flat + side * 0.4).normalized()
        elif dist < rng * 0.2:
            dir = (-flat + side * 0.5).normalized()
        else:
            dir = side * 0.7
    if has_los and react_t <= 0.0 and dist < s["range"]:
        fire_cd -= delta
        if fire_cd <= 0.0:
            if burst_left <= 0:
                burst_left = s["burst"]
            _shoot(p)
            burst_left -= 1
            if burst_left > 0:
                fire_cd = s["interval"]
            else:
                fire_cd = s["pause"] * randf_range(0.8, 1.3)
    return dir


func _shoot(p) -> void:
    var muzzle: Vector3 = model.get_muzzle_position()
    if s["kind"] == "rocket":
        var aim: Vector3 = p.global_position + Vector3(0, 0.4 if p.vehicle == null else 0.2, 0) + p.velocity * 0.35
        var r = Rocket.new()
        r.setup(self, level, muzzle, (aim - muzzle).normalized(), s["damage"] * Game.enemy_damage_mult(), 4.0)
        r.speed = 30.0
        level.add_child(r)
        if level.net:
            level.net.send_projectile("rocket", muzzle, (aim - muzzle).normalized(), 0.0, 4.0, 30.0)
        Game.play_sfx("rocket", muzzle, -2.0)
        Fx.muzzle_flash(level, muzzle)
        return
    var aim2: Vector3 = p.global_position + Vector3(0, 0.75 if p.crouching else 1.15, 0)
    var spread: float = s["spread"] * Game.enemy_spread_mult()
    if Vector2(p.velocity.x, p.velocity.z).length() > 6.0:
        spread *= 1.6
    if p.crouching:
        spread *= 1.2
    var dir := (aim2 - muzzle).normalized()
    var basis_x := dir.cross(Vector3.UP).normalized()
    var basis_y := basis_x.cross(dir).normalized()
    var r2 := tan(deg_to_rad(spread)) * sqrt(randf())
    var a := randf() * TAU
    dir = (dir + basis_x * r2 * cos(a) + basis_y * r2 * sin(a)).normalized()
    var to: Vector3 = muzzle + dir * float(s["range"]) * 1.4
    var ex: Array[RID] = [get_rid()]
    var hit := Fx.ray(self, muzzle, to, 1 | 2, ex)
    var end := to
    if not hit.is_empty():
        end = hit["position"]
        var col = hit["collider"]
        var is_player_side: bool = col != null and (col.is_in_group("player") or col.is_in_group("squad") or (col.is_in_group("vehicles") and not col.ai))
        if is_player_side:
            col.take_damage(s["damage"] * Game.enemy_damage_mult(), global_position, end, false)
        else:
            Fx.impact(level, end, hit["normal"])
    model.notify_shot()
    _net_shot = true
    if level.net:
        level.net.fx_shot(muzzle, end, Color(1.0, 0.45, 0.3), s["sound"], -3.0)
    else:
        Fx.tracer(level, muzzle, end, Color(1.0, 0.45, 0.3))
        Fx.muzzle_flash(level, muzzle)
        Game.play_sfx(s["sound"], muzzle, -3.0)


func hear(pos: Vector3) -> void:
    if not alive or state == COMBAT:
        return
    state = INVESTIGATE
    move_target = pos
    var d := pos - global_position
    _face(d)


func take_damage(amount: float, source: Vector3, hit_pos: Vector3, explosive := false) -> bool:
    if not alive:
        return false
    var headshot: bool = not explosive and (hit_pos.y - global_position.y) > 1.5 * model.scale.y
    if headshot:
        amount *= 2.2
    hp -= amount
    model.hit_flash()
    Fx.blood_plastic(level, hit_pos, TAN)
    if state != COMBAT:
        state = COMBAT
        react_t = 0.15
        last_known = source
        lost_t = 0.0
        _face(source - global_position)
    if hp <= 0.0:
        _die(headshot)
        return true
    return false


## Non-host PCs: the host says this soldier is down.
func _die_visual() -> void:
    alive = false
    remove_from_group("enemies")
    remove_from_group("damageable")
    collision_layer = 0
    collision_mask = 0
    set_physics_process(false)
    model.melt()
    Game.play_sfx("melt", global_position, -4.0)
    var t := Timer.new()
    t.wait_time = 14.0
    t.one_shot = true
    t.autostart = true
    t.timeout.connect(queue_free)
    add_child(t)


func _die(headshot: bool) -> void:
    alive = false
    remove_from_group("enemies")
    remove_from_group("damageable")
    collision_layer = 0
    collision_mask = 0
    set_physics_process(false)
    model.melt()
    Game.play_sfx("melt", global_position, -4.0)
    level.on_enemy_killed(self, headshot)
    var t := Timer.new()
    t.wait_time = 14.0
    t.one_shot = true
    t.autostart = true
    t.timeout.connect(queue_free)
    add_child(t)
