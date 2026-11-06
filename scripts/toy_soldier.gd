extends Node3D
## Procedural plastic toy soldier in modern kit (helmet w/ NVG mount, plate
## carrier, pack) built from primitives. Shared by the player and enemies.

var body_color := Color(0.24, 0.45, 0.16)
var mat: StandardMaterial3D
var gear_mat: StandardMaterial3D
var hips: Node3D
var torso: Node3D
var leg_l: Node3D
var leg_r: Node3D
var gun_root: Node3D
var muzzle: Node3D
var weapon_kind := "rifle"
var phase := 0.0
var crouch_amount := 0.0
var aim_pitch := 0.0
var _flash_t := 0.0
var hat_offset := Vector3(0, 1.0, 0)


func notify_shot() -> void:
    pass


func build(c: Color, kind := "rifle") -> void:
    body_color = c
    mat = _plastic(c)
    gear_mat = _plastic(c.darkened(0.2))

    hips = Node3D.new()
    hips.position = Vector3(0, 0.95, 0)
    add_child(hips)
    leg_l = _leg(-0.13)
    leg_r = _leg(0.13)

    torso = Node3D.new()
    hips.add_child(torso)
    _box(torso, Vector3(0, 0.33, 0), Vector3(0.46, 0.62, 0.26), mat)            # chest
    _box(torso, Vector3(0, 0.37, -0.01), Vector3(0.52, 0.42, 0.34), gear_mat)    # plate carrier
    for x in [-0.14, 0.0, 0.14]:
        _box(torso, Vector3(x, 0.24, -0.2), Vector3(0.11, 0.15, 0.07), gear_mat)  # mag pouches
    _box(torso, Vector3(0, 0.4, 0.24), Vector3(0.36, 0.44, 0.18), gear_mat)      # assault pack
    _box(torso, Vector3(0, 0.03, 0), Vector3(0.5, 0.1, 0.3), gear_mat)           # belt
    _cyl(torso, Vector3(0, 0.69, 0), 0.075, 0.12, mat)                           # neck
    _sphere(torso, Vector3(0, 0.82, 0), 0.145, mat)                              # head
    var helmet := _sphere(torso, Vector3(0, 0.88, 0.01), 0.19, gear_mat)
    helmet.scale = Vector3(1.0, 0.78, 1.08)
    _box(torso, Vector3(0, 0.96, -0.18), Vector3(0.09, 0.07, 0.06), gear_mat)    # NVG mount
    _box(torso, Vector3(0.17, 0.9, 0.0), Vector3(0.04, 0.06, 0.16), gear_mat)    # helmet rail
    _box(torso, Vector3(-0.17, 0.9, 0.0), Vector3(0.04, 0.06, 0.16), gear_mat)
    _arm(Vector3(0.28, 0.58, 0), Vector3(deg_to_rad(62), deg_to_rad(8), 0))
    _arm(Vector3(-0.28, 0.58, 0), Vector3(deg_to_rad(78), deg_to_rad(-32), 0))

    gun_root = Node3D.new()
    torso.add_child(gun_root)
    set_weapon(kind)


func set_weapon(kind: String) -> void:
    weapon_kind = kind
    for c in gun_root.get_children():
        c.queue_free()
    muzzle = Node3D.new()
    gun_root.add_child(muzzle)
    match kind:
        "launcher":
            gun_root.position = Vector3(0.2, 0.72, -0.05)
            _cyl(gun_root, Vector3.ZERO, 0.075, 1.1, gear_mat, Vector3(PI / 2, 0, 0))
            _box(gun_root, Vector3(0, -0.12, -0.15), Vector3(0.05, 0.14, 0.06), gear_mat)
            _box(gun_root, Vector3(-0.08, 0.04, -0.1), Vector3(0.05, 0.08, 0.1), gear_mat)
            muzzle.position = Vector3(0, 0, -0.58)
        "sniper":
            gun_root.position = Vector3(0.1, 0.45, -0.42)
            _box(gun_root, Vector3(0, 0, 0), Vector3(0.08, 0.12, 0.9), gear_mat)
            _cyl(gun_root, Vector3(0, 0.01, -0.62), 0.025, 0.45, gear_mat, Vector3(PI / 2, 0, 0))
            _cyl(gun_root, Vector3(0, 0.12, -0.05), 0.04, 0.34, gear_mat, Vector3(PI / 2, 0, 0))
            _box(gun_root, Vector3(0, -0.1, -0.05), Vector3(0.05, 0.12, 0.08), gear_mat)
            muzzle.position = Vector3(0, 0.01, -0.86)
        "lmg":
            gun_root.position = Vector3(0.1, 0.4, -0.4)
            _box(gun_root, Vector3(0, 0, 0), Vector3(0.11, 0.15, 0.85), gear_mat)
            _box(gun_root, Vector3(-0.06, -0.12, -0.02), Vector3(0.14, 0.16, 0.16), gear_mat)
            _box(gun_root, Vector3(0, 0.1, 0.0), Vector3(0.06, 0.05, 0.25), gear_mat)
            muzzle.position = Vector3(0, 0.0, -0.46)
        "shotgun":
            gun_root.position = Vector3(0.1, 0.42, -0.4)
            _box(gun_root, Vector3(0, 0, 0), Vector3(0.08, 0.12, 0.8), gear_mat)
            _cyl(gun_root, Vector3(0, -0.06, -0.2), 0.03, 0.4, gear_mat, Vector3(PI / 2, 0, 0))
            muzzle.position = Vector3(0, 0.02, -0.42)
        _:
            gun_root.position = Vector3(0.1, 0.42, -0.4)
            _box(gun_root, Vector3(0, 0, 0), Vector3(0.07, 0.11, 0.78), gear_mat)
            _box(gun_root, Vector3(0, -0.12, -0.08), Vector3(0.05, 0.17, 0.08), gear_mat)
            _box(gun_root, Vector3(0, 0.09, 0.0), Vector3(0.05, 0.07, 0.14), gear_mat)
            muzzle.position = Vector3(0, 0.01, -0.41)


func get_muzzle_position() -> Vector3:
    if muzzle and muzzle.is_inside_tree():
        return muzzle.global_position
    return global_position + Vector3(0, 1.4, 0)


func animate(delta: float, speed: float, crouch: bool) -> void:
    crouch_amount = move_toward(crouch_amount, 1.0 if crouch else 0.0, delta * 6.0)
    var moving := clampf(speed / 6.0, 0.0, 1.0)
    if speed > 0.2:
        phase += delta * (4.0 + speed * 1.4)
    else:
        phase = lerpf(phase, roundf(phase / PI) * PI, delta * 8.0)
    var swing := sin(phase) * moving * 0.65
    leg_l.rotation.x = swing - crouch_amount * 0.9
    leg_r.rotation.x = -swing + crouch_amount * 0.3
    hips.position.y = 0.95 - crouch_amount * 0.32 + absf(cos(phase)) * 0.04 * moving
    torso.rotation.x = lerpf(torso.rotation.x, aim_pitch * 0.55, delta * 12.0)
    if _flash_t > 0.0:
        _flash_t -= delta
        if _flash_t <= 0.0:
            mat.emission_enabled = false
            gear_mat.emission_enabled = false


func hit_flash() -> void:
    _flash_t = 0.07
    for m in [mat, gear_mat]:
        m.emission_enabled = true
        m.emission = Color(1, 1, 1)
        m.emission_energy_multiplier = 0.6


func melt() -> void:
    mat.emission_enabled = false
    gear_mat.emission_enabled = false
    var tw := create_tween().set_parallel(true)
    tw.tween_property(self, "scale", Vector3(1.9, 0.07, 1.9), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
    tw.tween_property(mat, "albedo_color", body_color.darkened(0.35), 1.6)
    tw.tween_property(gear_mat, "albedo_color", body_color.darkened(0.5), 1.6)
    tw.tween_property(mat, "roughness", 0.1, 1.6)


# ------------------------------------------------------------- builders ----

func _plastic(c: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.roughness = 0.38
    m.metallic_specular = 0.65
    m.rim_enabled = true
    m.rim = 0.25
    return m


func _leg(x: float) -> Node3D:
    var pivot := Node3D.new()
    pivot.position = Vector3(x, 0, 0)
    hips.add_child(pivot)
    _box(pivot, Vector3(0, -0.45, 0), Vector3(0.17, 0.9, 0.2), mat)
    _box(pivot, Vector3(0, -0.36, -0.11), Vector3(0.13, 0.12, 0.05), gear_mat)   # knee pad
    _box(pivot, Vector3(0, -0.89, -0.05), Vector3(0.19, 0.12, 0.31), gear_mat)   # boot
    return pivot


func _arm(shoulder: Vector3, rot: Vector3) -> void:
    var pivot := Node3D.new()
    pivot.position = shoulder
    pivot.rotation = rot
    torso.add_child(pivot)
    _box(pivot, Vector3(0, -0.22, 0), Vector3(0.12, 0.46, 0.13), mat)
    _box(pivot, Vector3(0, -0.47, 0), Vector3(0.1, 0.1, 0.1), mat)


func _box(parent: Node3D, pos: Vector3, size: Vector3, m: Material) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = size
    mi.mesh = bm
    mi.material_override = m
    mi.position = pos
    parent.add_child(mi)
    return mi


func _sphere(parent: Node3D, pos: Vector3, r: float, m: Material) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    var sm := SphereMesh.new()
    sm.radius = r
    sm.height = r * 2.0
    mi.mesh = sm
    mi.material_override = m
    mi.position = pos
    parent.add_child(mi)
    return mi


func _cyl(parent: Node3D, pos: Vector3, r: float, h: float, m: Material, rot := Vector3.ZERO) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.top_radius = r
    cm.bottom_radius = r
    cm.height = h
    cm.radial_segments = 12
    mi.mesh = cm
    mi.material_override = m
    mi.position = pos
    mi.rotation = rot
    parent.add_child(mi)
    return mi
