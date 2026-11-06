extends CharacterBody3D
## The player: a green plastic commando with an over-the-shoulder camera.

signal stats_changed
signal hit_confirmed(killed: bool)
signal took_damage(amount: float)
signal died

const Soldier = preload("res://scripts/plastic_soldier.gd")
const Weapons = preload("res://scripts/weapons.gd")
const Fx = preload("res://scripts/fx.gd")
const Grenade = preload("res://scripts/grenade.gd")
const Rocket = preload("res://scripts/rocket.gd")
const DroneStrike = preload("res://scripts/drone_strike.gd")

const WALK_SPEED := 5.5
const SPRINT_SPEED := 8.8
const CROUCH_SPEED := 2.6
const AIM_SPEED := 3.4
const ACCEL := 45.0
const AIR_ACCEL := 8.0
const JUMP_VELOCITY := 5.4
const GRAVITY := 16.0
const PLAYER_COLOR := Color(0.27, 0.48, 0.17)
const MAX_GRENADES := 8
const MAX_DRONES := 3
const SHOT_MASK := 1 | 4   # world + enemies

var level: Node
var max_health := 100.0
var health := 100.0
var armor := 25.0
var max_armor := 100.0
var alive := true
var invulnerable := false

var model
var col_shape: CollisionShape3D
var capsule: CapsuleShape3D
var pivot: Node3D
var spring: SpringArm3D
var camera: Camera3D

var pitch := -0.12
var aiming := false
var crouching := false
var sprinting := false

var owned := {}
var mag := {}
var reserve := {}
var current := "carbine"
var fire_cd := 0.0
var reload_t := 0.0
var grenades := 3
var drones := 1
var grenade_cd := 0.0
var bloom := 0.0
var shake := 0.0
var shots_fired := 0
var shots_hit := 0


func _ready() -> void:
    add_to_group("player")
    add_to_group("damageable")
    collision_layer = 2
    collision_mask = 1 | 4
    floor_snap_length = 0.4
    floor_max_angle = deg_to_rad(50)

    capsule = CapsuleShape3D.new()
    capsule.radius = 0.35
    capsule.height = 1.8
    col_shape = CollisionShape3D.new()
    col_shape.shape = capsule
    col_shape.position.y = 0.9
    add_child(col_shape)

    model = Soldier.create()
    add_child(model)
    model.build(PLAYER_COLOR, "rifle")

    pivot = Node3D.new()
    pivot.position = Vector3(0, 1.55, 0)
    add_child(pivot)
    spring = SpringArm3D.new()
    spring.spring_length = 3.4
    spring.collision_mask = 1
    spring.margin = 0.25
    spring.position = Vector3(0.6, 0.15, 0)
    pivot.add_child(spring)
    spring.add_excluded_object(get_rid())
    camera = Camera3D.new()
    camera.fov = 70.0
    camera.far = 900.0
    spring.add_child(camera)
    camera.current = true

    for id in Weapons.ORDER:
        var w: Dictionary = Weapons.DATA[id]
        mag[id] = w["mag"]
        reserve[id] = w["reserve"]
    if owned.is_empty():
        owned = {"carbine": true, "shotgun": true}
    _equip("carbine")


func cur() -> Dictionary:
    return Weapons.DATA[current]


func is_scoped() -> bool:
    return aiming and cur().get("scope", false) and reload_t <= 0.0


# ---------------------------------------------------------------- input ----

func _unhandled_input(event: InputEvent) -> void:
    if not alive or get_tree().paused:
        return
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        var s: float = Game.mouse_sensitivity * (0.3 if is_scoped() else (0.6 if aiming else 1.0))
        rotation.y -= event.relative.x * s
        pitch -= event.relative.y * s * (-1.0 if Game.invert_y else 1.0)
        pitch = clampf(pitch, -1.25, 0.95)
    elif event.is_action_pressed("next_weapon"):
        _cycle(1)
    elif event.is_action_pressed("prev_weapon"):
        _cycle(-1)
    else:
        for i in Weapons.ORDER.size():
            if event.is_action_pressed("weapon_%d" % (i + 1)):
                var id: String = Weapons.ORDER[i]
                if owned.has(id) and id != current:
                    _equip(id)


# -------------------------------------------------------------- physics ----

func _physics_process(delta: float) -> void:
    fire_cd = maxf(0.0, fire_cd - delta)
    grenade_cd = maxf(0.0, grenade_cd - delta)
    bloom = move_toward(bloom, 0.0, delta * 3.5)
    if not alive:
        velocity.x = 0.0
        velocity.z = 0.0
        velocity.y -= GRAVITY * delta
        move_and_slide()
        _update_camera(delta)
        return
    _move(delta)
    _combat(delta)
    _update_camera(delta)
    model.aim_pitch = pitch
    model.animate(delta, Vector2(velocity.x, velocity.z).length(), crouching)
    if global_position.y < -40.0:
        take_damage(9999.0, global_position, global_position)


func _move(delta: float) -> void:
    if Input.is_action_just_pressed("crouch"):
        crouching = not crouching
        capsule.height = 1.2 if crouching else 1.8
        col_shape.position.y = capsule.height * 0.5
    var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var dir := (transform.basis * Vector3(input.x, 0, input.y)).normalized()
    sprinting = Input.is_action_pressed("sprint") and input.y < -0.3 and not aiming \
        and not Input.is_action_pressed("fire")
    if sprinting and crouching:
        crouching = false
        capsule.height = 1.8
        col_shape.position.y = 0.9
    var speed := WALK_SPEED
    if sprinting:
        speed = SPRINT_SPEED
    elif crouching:
        speed = CROUCH_SPEED
    elif aiming:
        speed = AIM_SPEED
    var accel := ACCEL if is_on_floor() else AIR_ACCEL
    velocity.x = move_toward(velocity.x, dir.x * speed, accel * delta)
    velocity.z = move_toward(velocity.z, dir.z * speed, accel * delta)
    if is_on_floor():
        if Input.is_action_just_pressed("jump"):
            velocity.y = JUMP_VELOCITY
            if crouching:
                crouching = false
                capsule.height = 1.8
                col_shape.position.y = 0.9
    else:
        velocity.y -= GRAVITY * delta
    move_and_slide()


func _update_camera(delta: float) -> void:
    var w := cur()
    var scoped := is_scoped()
    var target_len := 0.15 if scoped else (1.7 if aiming else 3.4)
    spring.spring_length = lerpf(spring.spring_length, target_len, minf(1.0, delta * 12.0))
    var target_fov: float = w["zoom"] if aiming else 70.0
    if sprinting:
        target_fov = 76.0
    camera.fov = lerpf(camera.fov, target_fov, minf(1.0, delta * 12.0))
    pivot.position.y = lerpf(pivot.position.y, 1.05 if crouching else 1.55, minf(1.0, delta * 10.0))
    pivot.rotation.x = pitch
    model.visible = not (scoped and spring.spring_length < 0.6)
    shake = move_toward(shake, 0.0, delta * 2.5)
    camera.h_offset = randf_range(-1.0, 1.0) * shake * 0.12
    camera.v_offset = randf_range(-1.0, 1.0) * shake * 0.12


# --------------------------------------------------------------- combat ----

func _combat(delta: float) -> void:
    var w := cur()
    aiming = Input.is_action_pressed("aim") and not sprinting
    if aiming:
        model.notify_shot()
    if reload_t > 0.0:
        reload_t -= delta
        if reload_t <= 0.0:
            _finish_reload()
    var want_fire := Input.is_action_pressed("fire") if w["auto"] else Input.is_action_just_pressed("fire")
    if want_fire and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        _fire(w)
    if Input.is_action_just_pressed("reload"):
        _start_reload()
    if Input.is_action_just_pressed("grenade"):
        _throw_grenade()
    if Input.is_action_just_pressed("drone"):
        _call_drone()


func get_spread() -> float:
    var w := cur()
    var s: float = w["aim_spread"] if aiming else w["spread"]
    var hspeed := Vector2(velocity.x, velocity.z).length()
    if hspeed > 1.0:
        s *= 1.0 + hspeed / WALK_SPEED * 0.6
    if crouching:
        s *= 0.7
    if not is_on_floor():
        s *= 2.0
    return s + bloom * (0.4 if aiming else 1.0)


func _aim_point(dir: Vector3, from: Vector3, max_range: float) -> Vector3:
    var ex: Array[RID] = [get_rid()]
    var hit := Fx.ray(self, from, from + dir * max_range, SHOT_MASK, ex)
    if hit.is_empty():
        return from + dir * max_range
    return hit["position"]


func _spread_dir(fwd: Vector3, b: Basis, spread_deg: float) -> Vector3:
    var r := tan(deg_to_rad(spread_deg)) * sqrt(randf())
    var a := randf() * TAU
    return (fwd + b.x * r * cos(a) + b.y * r * sin(a)).normalized()


func _fire(w: Dictionary) -> void:
    if fire_cd > 0.0 or reload_t > 0.0:
        return
    if mag[current] <= 0:
        if reserve[current] > 0:
            _start_reload()
        else:
            fire_cd = 0.3
            Game.play_sfx("empty", global_position, -4.0)
            level.notify("Out of ammo - find an ammo crate or switch weapons", 1.5)
        return
    mag[current] -= 1
    fire_cd = w["interval"]
    shots_fired += 1
    var cam_b := camera.global_transform.basis
    var cam_pos := camera.global_position
    var fwd := -cam_b.z
    var muzzle_pos: Vector3 = model.get_muzzle_position()
    var spread := get_spread()

    if w["kind"] == "rocket":
        var target := _aim_point(_spread_dir(fwd, cam_b, spread), cam_pos, w["range"])
        var r = Rocket.new()
        r.setup(self, level, muzzle_pos, (target - muzzle_pos).normalized(), w["damage"], w["splash"])
        level.add_child(r)
    else:
        var any_hit := false
        var killed := false
        var ex: Array[RID] = [get_rid()]
        for i in int(w["pellets"]):
            var dir := _spread_dir(fwd, cam_b, spread)
            var target := _aim_point(dir, cam_pos, w["range"])
            var to := target + (target - muzzle_pos).normalized() * 0.5
            var hit := Fx.ray(self, muzzle_pos, to, SHOT_MASK, ex)
            var end_point := to
            if not hit.is_empty():
                end_point = hit["position"]
                var recv = _receiver(hit["collider"])
                if recv != null:
                    var dist := muzzle_pos.distance_to(end_point)
                    var dmg: float = w["damage"] * _falloff(w, dist)
                    if recv.take_damage(dmg, global_position, end_point, false):
                        killed = true
                    any_hit = true
                else:
                    Fx.impact(level, end_point, hit["normal"])
            if i == 0 or randf() < 0.3:
                Fx.tracer(level, muzzle_pos, end_point, w["tracer"])
        if any_hit:
            shots_hit += 1
            hit_confirmed.emit(killed)
            Game.play_ui("hit", -10.0)
    Fx.muzzle_flash(level, muzzle_pos)
    model.notify_shot()
    Game.play_sfx(w["sound"], muzzle_pos)
    level.make_noise(global_position, w["noise"])
    bloom = minf(bloom + w["bloom"], 4.0)
    var kick: float = w["recoil"] * (0.45 if aiming else 1.0)
    pitch = clampf(pitch + kick * 0.008, -1.25, 0.95)
    rotation.y += randf_range(-1.0, 1.0) * kick * 0.003
    shake = maxf(shake, kick * 0.12)
    if mag[current] == 0 and reserve[current] > 0:
        _start_reload()
    stats_changed.emit()


func _receiver(col) -> Variant:
    if col == null:
        return null
    if col.has_method("take_damage"):
        return col
    var p = col.get_parent()
    if p != null and p.has_method("take_damage"):
        return p
    return null


func _falloff(w: Dictionary, dist: float) -> float:
    var fs: float = w.get("falloff_start", 80.0)
    if dist <= fs:
        return 1.0
    var span: float = maxf(1.0, w["range"] - fs)
    return maxf(0.35, 1.0 - (dist - fs) / span * 0.65)


func _start_reload() -> void:
    if reload_t > 0.0:
        return
    var w := cur()
    if mag[current] >= w["mag"] or reserve[current] <= 0:
        return
    reload_t = w["reload"]
    Game.play_sfx(w.get("reload_sound", "reload"), global_position, -4.0)
    stats_changed.emit()


func _finish_reload() -> void:
    var w := cur()
    var take: int = mini(w["mag"] - mag[current], reserve[current])
    mag[current] += take
    reserve[current] -= take
    reload_t = 0.0
    stats_changed.emit()


func _equip(id: String) -> void:
    current = id
    reload_t = 0.0
    fire_cd = 0.25
    model.set_weapon(Weapons.DATA[id]["model"])
    stats_changed.emit()


func _cycle(step: int) -> void:
    var idx: int = Weapons.ORDER.find(current)
    for i in Weapons.ORDER.size():
        idx = wrapi(idx + step, 0, Weapons.ORDER.size())
        if owned.has(Weapons.ORDER[idx]):
            if Weapons.ORDER[idx] != current:
                _equip(Weapons.ORDER[idx])
            return


func _throw_grenade() -> void:
    if grenades <= 0:
        level.notify("No frag grenades left", 1.2)
        return
    if grenade_cd > 0.0:
        return
    grenades -= 1
    grenade_cd = 0.9
    Game.play_sfx("throw", global_position, -4.0)
    var fwd := -camera.global_transform.basis.z
    var g = Grenade.new()
    g.setup(level)
    level.add_child(g)
    g.global_position = global_position + Vector3(0, 1.6, 0) + fwd * 0.7
    g.linear_velocity = fwd * 17.0 + Vector3(0, 4.5, 0) + velocity * 0.5
    g.angular_velocity = Vector3(randf(), randf(), randf()) * 8.0
    stats_changed.emit()


func _call_drone() -> void:
    if drones <= 0:
        level.notify("No drone strikes available", 1.2)
        return
    var from := camera.global_position
    var ex: Array[RID] = [get_rid()]
    var hit := Fx.ray(self, from, from - camera.global_transform.basis.z * 450.0, 1 | 4, ex)
    if hit.is_empty():
        level.notify("Drone strike: no valid target - aim at the ground", 1.5)
        return
    drones -= 1
    var d = DroneStrike.new()
    d.setup(level, hit["position"])
    level.add_child(d)
    level.notify("REAPER DRONE: Hellfire inbound - danger close!", 2.0)
    stats_changed.emit()


# ------------------------------------------------------- damage/pickups ----

func take_damage(amount: float, _source: Vector3, _hit_pos: Vector3, _explosive := false) -> bool:
    if not alive or invulnerable:
        return false
    if armor > 0.0:
        var absorbed := minf(armor, amount * 0.6)
        armor -= absorbed
        amount -= absorbed
    health -= amount
    shake = maxf(shake, 0.35)
    took_damage.emit(amount)
    stats_changed.emit()
    if health <= 0.0:
        health = 0.0
        _die()
        return true
    return false


func _die() -> void:
    alive = false
    aiming = false
    model.visible = true
    model.melt()
    Game.play_sfx("melt", global_position)
    died.emit()


func give_pickup(kind: String) -> bool:
    match kind:
        "health":
            if health >= max_health:
                return false
            health = minf(max_health, health + 40.0)
        "armor":
            if armor >= max_armor:
                return false
            armor = minf(max_armor, armor + 50.0)
        "ammo":
            var gave := false
            for id in owned:
                var w: Dictionary = Weapons.DATA[id]
                var cap := int(w["reserve"] * 1.5)
                if reserve[id] < cap:
                    reserve[id] = mini(cap, reserve[id] + int(w["mag"]) * 2)
                    gave = true
            if not gave:
                return false
        "grenades":
            if grenades >= MAX_GRENADES:
                return false
            grenades = mini(MAX_GRENADES, grenades + 2)
        "drone":
            if drones >= MAX_DRONES:
                return false
            drones += 1
        _:
            if not Weapons.DATA.has(kind):
                return false
            var w: Dictionary = Weapons.DATA[kind]
            if owned.has(kind):
                var cap := int(w["reserve"] * 1.5)
                if reserve[kind] >= cap:
                    return false
                reserve[kind] = mini(cap, reserve[kind] + int(w["mag"]) * 2)
            else:
                owned[kind] = true
                _equip(kind)
    Game.play_ui("pickup")
    stats_changed.emit()
    return true
