extends CharacterBody3D
## Drivable plastic toy vehicles: a jeep with a mounted .50 cal and a tank with a
## turret cannon + coaxial MG. Press E (interact) near one to get in or out.
## Arcade handling on a CharacterBody3D: no wheel physics, just throttle/steer.

const Fx = preload("res://scripts/fx.gd")
const Rocket = preload("res://scripts/rocket.gd")
const CameraRig = preload("res://scripts/camera_rig.gd")

const GREEN := Color(0.27, 0.48, 0.17)
const GRAVITY := 18.0

const KINDS := {
    "jeep": {
        "name": "JEEP (M2 .50 CAL)", "hp": 320.0, "bullet_armor": 1.0,
        "max_speed": 24.0, "reverse": 9.0, "accel": 14.0, "turn": 2.1, "pivot_turn": false,
        "size": Vector3(2.1, 1.6, 4.2), "cam_height": 2.3, "cam_dist": 7.0,
        "primary": "mg", "primary_interval": 0.09, "primary_damage": 30.0,
    },
    "tank": {
        "name": "TANK (120MM + COAX MG)", "hp": 1000.0, "bullet_armor": 0.15,
        "max_speed": 9.5, "reverse": 5.0, "accel": 6.0, "turn": 1.1, "pivot_turn": true,
        "size": Vector3(3.6, 2.3, 6.4), "cam_height": 3.2, "cam_dist": 10.0,
        "primary": "cannon", "primary_interval": 2.2, "primary_damage": 280.0,
        "secondary_interval": 0.08, "secondary_damage": 16.0,
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


func setup(lvl: Node, kd: String, pos: Vector3, rot_y := 0.0) -> void:
    level = lvl
    kind = kd
    position = pos
    rotation.y = rot_y


func _ready() -> void:
    k = KINDS[kind]
    hp = k["hp"]
    add_to_group("damageable")
    add_to_group("vehicles")
    collision_layer = 1
    collision_mask = 1 | 4
    floor_snap_length = 0.5
    floor_max_angle = deg_to_rad(40)
    var size: Vector3 = k["size"]
    var cs := CollisionShape3D.new()
    var bs := BoxShape3D.new()
    bs.size = size
    cs.shape = bs
    cs.position.y = size.y * 0.5
    add_child(cs)
    if kind == "tank":
        _build_tank()
    else:
        _build_jeep()

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
    var body := _mat(GREEN)
    var dark := _mat(GREEN.darkened(0.25))
    var tire := _mat(GREEN.darkened(0.5))
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
    var body := _mat(GREEN)
    var dark := _mat(GREEN.darkened(0.25))
    var track := _mat(GREEN.darkened(0.5))
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


# ------------------------------------------------------------ enter/exit ----

func can_enter() -> bool:
    return alive and driver == null


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
    level.notify("%s  -  WASD drive, mouse aim, LMB fire%s, E to exit" % [k["name"], ", RMB coax MG" if kind == "tank" else ""], 3.0)


func exit_vehicle() -> void:
    if driver == null:
        return
    var p = driver
    driver = null
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


func _physics_process(delta: float) -> void:
    fire_cd = maxf(0.0, fire_cd - delta)
    fire2_cd = maxf(0.0, fire2_cd - delta)
    _enter_cd = maxf(0.0, _enter_cd - delta)
    var throttle := 0.0
    var steer := 0.0
    if driver != null and alive:
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

    var max_fwd: float = k["max_speed"]
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

    if driver != null:
        driver.global_position = global_position + Vector3(0, 0.6, 0)
        driver.velocity = velocity
        _aim_turret(delta)
        _update_camera(delta)
        engine.pitch_scale = 0.6 + absf(speed) / max_fwd * 0.9
    elif turret:
        turret.rotation.y = lerp_angle(turret.rotation.y, 0.0, delta)


func _handle_collisions(delta: float, before: Vector3) -> void:
    for i in get_slide_collision_count():
        var c := get_slide_collision(i)
        var other = c.get_collider()
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
    var from := camera.global_position
    var dir := -camera.global_transform.basis.z
    var ex: Array[RID] = [get_rid()]
    var hit := Fx.ray(self, from, from + dir * 400.0, 1 | 4, ex)
    return hit["position"] if not hit.is_empty() else from + dir * 400.0


func fire_primary() -> void:
    if fire_cd > 0.0 or not alive:
        return
    fire_cd = k["primary_interval"]
    if k["primary"] == "cannon":
        var m := muzzle.global_position
        var dir := -muzzle.global_transform.basis.z
        var target := _aim_point()
        # Use the barrel direction once the turret has caught up with the crosshair.
        var to_target := (target - m).normalized()
        if to_target.dot(dir) > 0.97:
            dir = to_target
        var r = Rocket.new()
        r.setup(self, level, m, dir, k["primary_damage"], 7.0)
        r.speed = 90.0
        level.add_child(r)
        Fx.explosion(level, m, 1.2)
        Game.play_sfx("sniper", m, 6.0)
        Game.play_sfx("explosion", m, -4.0)
        level.make_noise(m, 90.0)
        if driver:
            driver.shake = maxf(driver.shake, 0.6)
    else:
        _bullet(muzzle.global_position, k["primary_damage"], 2.0, "lmg")


func fire_secondary() -> void:
    if not k.has("secondary_interval") or fire2_cd > 0.0 or not alive:
        return
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
    var hit := Fx.ray(self, from, to, 1 | 4, ex)
    var end := to
    if not hit.is_empty():
        end = hit["position"]
        var col = hit["collider"]
        if col != null and col.has_method("take_damage"):
            var killed: bool = col.take_damage(damage, global_position, end, false)
            if driver:
                driver.shots_hit += 1
                driver.hit_confirmed.emit(killed)
        else:
            Fx.impact(level, end, hit["normal"])
    if driver:
        driver.shots_fired += 1
    Fx.tracer(level, from, end, Color(1.0, 0.75, 0.35))
    Fx.muzzle_flash(level, from)
    Game.play_sfx(sound, from, 0.0)
    level.make_noise(from, 60.0)


# ---------------------------------------------------------------- damage ----

func take_damage(amount: float, _source: Vector3, hit_pos: Vector3, explosive := false) -> bool:
    if not alive:
        return false
    if not explosive:
        amount *= k["bullet_armor"]
        Fx.impact(level, hit_pos, Vector3.UP)
    hp -= amount
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
    Fx.explosion(level, p, 7.0)
    Fx.fire(level, p, 1.5)
    Game.play_sfx("explosion", p, 6.0)
    for m in mats:
        m.albedo_color = m.albedo_color.darkened(0.7)
        m.roughness = 0.9
    level.apply_explosion(p, 6.0, 60.0)   # before ejecting, so the driver isn't hit twice
    var d = driver
    exit_vehicle()
    if d != null:
        d.take_damage(35.0, p, d.global_position, true)
        level.notify("VEHICLE DESTROYED - BAIL OUT!", 2.0)
