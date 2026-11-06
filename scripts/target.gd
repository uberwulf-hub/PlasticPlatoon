extends StaticBody3D
## Destructible mission objective (radar jammer, mobile SAM, signal booster).
## Bullets do reduced damage - bring explosives.

const Fx = preload("res://scripts/fx.gd")

const KINDS := {
    "jammer": {"name": "RADAR JAMMER", "hp": 260.0},
    "sam": {"name": "MOBILE SAM", "hp": 340.0},
    "booster": {"name": "SIGNAL BOOSTER", "hp": 380.0},
}

var level: Node
var kind := "jammer"
var tag := ""
var hp := 260.0
var max_hp := 260.0
var alive := true
var display_name := "TARGET"
var mats: Array = []
var blinkers: Array = []
var label: Label3D
var _blink := 0.0


func setup(lvl: Node, k: String, t: String, pos: Vector3, rot_y := 0.0) -> void:
    level = lvl
    kind = k
    tag = t
    position = pos
    rotation.y = rot_y


func _ready() -> void:
    add_to_group("damageable")
    collision_layer = 1
    collision_mask = 0
    var info: Dictionary = KINDS.get(kind, KINDS["jammer"])
    hp = info["hp"]
    max_hp = hp
    display_name = info["name"]
    match kind:
        "sam":
            _build_sam()
        "booster":
            _build_booster()
        _:
            _build_jammer()
    label = Label3D.new()
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.font_size = 64
    label.pixel_size = 0.012
    label.outline_size = 12
    label.modulate = Color(1.0, 0.85, 0.3)
    label.position = Vector3(0, _label_height(), 0)
    label.text = display_name
    label.visibility_range_end = 140.0
    add_child(label)


func _label_height() -> float:
    match kind:
        "booster":
            return 8.5
        "sam":
            return 5.5
    return 8.0


func _process(delta: float) -> void:
    if not alive:
        return
    _blink += delta
    var on := fmod(_blink, 1.0) < 0.5
    for b in blinkers:
        b.visible = on


# -------------------------------------------------------------- visuals ----

func _mat(color: Color, emissive := false) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 0.55
    if emissive:
        m.emission_enabled = true
        m.emission = color
        m.emission_energy_multiplier = 3.0
    mats.append(m)
    return m


func _box(pos: Vector3, size: Vector3, m: Material, collide := true, rot := Vector3.ZERO) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = size
    mi.mesh = bm
    mi.material_override = m
    mi.position = pos
    mi.rotation = rot
    add_child(mi)
    if collide:
        var cs := CollisionShape3D.new()
        var bs := BoxShape3D.new()
        bs.size = size
        cs.shape = bs
        cs.position = pos
        cs.rotation = rot
        add_child(cs)
    return mi


func _cyl(pos: Vector3, r: float, h: float, m: Material, collide := true, rot := Vector3.ZERO) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.top_radius = r
    cm.bottom_radius = r
    cm.height = h
    mi.mesh = cm
    mi.material_override = m
    mi.position = pos
    mi.rotation = rot
    add_child(mi)
    if collide:
        var cs := CollisionShape3D.new()
        var sh := CylinderShape3D.new()
        sh.radius = r
        sh.height = h
        cs.shape = sh
        cs.position = pos
        cs.rotation = rot
        add_child(cs)
    return mi


func _light_bulb(pos: Vector3, color: Color) -> void:
    var mi := MeshInstance3D.new()
    var sm := SphereMesh.new()
    sm.radius = 0.15
    sm.height = 0.3
    mi.mesh = sm
    mi.material_override = _mat(color, true)
    mi.position = pos
    add_child(mi)
    blinkers.append(mi)


func _build_jammer() -> void:
    var tan := _mat(Color(0.74, 0.63, 0.42))
    var dark := _mat(Color(0.25, 0.25, 0.22))
    _box(Vector3(0, 1.0, 0), Vector3(3.2, 1.4, 2.2), tan)
    _box(Vector3(0, 1.95, 0.3), Vector3(1.6, 0.5, 1.2), dark)
    for x in [-1.1, 1.1]:
        for z in [-0.9, 0.9]:
            _cyl(Vector3(x, 0.35, z), 0.35, 0.25, dark, false, Vector3(0, 0, PI / 2))
    _cyl(Vector3(0, 4.2, -0.3), 0.12, 5.0, dark)
    var dish := _cyl(Vector3(0, 6.5, -0.6), 1.1, 0.15, tan, false, Vector3(deg_to_rad(65), 0, 0))
    dish.name = "Dish"
    _box(Vector3(0, 5.6, -0.3), Vector3(2.4, 0.08, 0.08), dark, false)
    _box(Vector3(0, 5.0, -0.3), Vector3(1.8, 0.08, 0.08), dark, false)
    _light_bulb(Vector3(0, 6.8, -0.3), Color(1.0, 0.1, 0.05))


func _build_sam() -> void:
    var tan := _mat(Color(0.7, 0.6, 0.38))
    var dark := _mat(Color(0.22, 0.22, 0.2))
    _box(Vector3(0, 1.1, 0), Vector3(2.5, 1.0, 6.0), tan)
    _box(Vector3(0, 2.2, -2.2), Vector3(2.4, 1.3, 1.6), tan)
    _box(Vector3(0, 2.3, -3.0), Vector3(2.0, 0.7, 0.05), _mat(Color(0.3, 0.45, 0.55)), false)
    for z in [-2.2, -0.4, 1.4]:
        for x in [-1.25, 1.25]:
            _cyl(Vector3(x, 0.55, z), 0.55, 0.4, dark, false, Vector3(0, 0, PI / 2))
    var pod_rot := Vector3(deg_to_rad(28), 0, 0)
    _box(Vector3(0, 2.8, 1.0), Vector3(2.0, 1.4, 3.6), tan, true, pod_rot)
    for x in [-0.5, 0.5]:
        for y in [2.55, 3.15]:
            _cyl(Vector3(x, y + 0.85, -0.65), 0.28, 0.1, dark, false, pod_rot + Vector3(PI / 2, 0, 0))
    _light_bulb(Vector3(0, 3.0, -2.2), Color(1.0, 0.1, 0.05))


func _build_booster() -> void:
    var shell := _mat(Color(0.1, 0.1, 0.12))
    var tan := _mat(Color(0.74, 0.63, 0.42))
    _box(Vector3(0, 0.9, 0), Vector3(7.0, 1.8, 4.5), shell)
    _box(Vector3(0, 1.85, 0), Vector3(6.4, 0.1, 3.9), _mat(Color(0.16, 0.16, 0.18)), false)
    for i in 3:
        var x := -2.6 + i * 2.6
        _cyl(Vector3(x, 4.2, 1.8), 0.22, 5.0, shell, true, Vector3(deg_to_rad(-12), 0, deg_to_rad(-15 + i * 15)))
    for i in 6:
        var led := _box(Vector3(-2.5 + i * 0.9, 1.1, -2.26), Vector3(0.3, 0.15, 0.04), _mat(Color(0.2, 1.0, 0.35), true), false)
        if i % 2 == 0:
            blinkers.append(led)
    # Tan Army sandbag nest around their prize.
    _box(Vector3(0, 0.45, -4.2), Vector3(5.0, 0.9, 1.0), tan)
    _box(Vector3(-4.6, 0.45, 0), Vector3(1.0, 0.9, 5.0), tan)


# --------------------------------------------------------------- damage ----

func take_damage(amount: float, _source: Vector3, hit_pos: Vector3, explosive := false) -> bool:
    if not alive:
        return false
    if not explosive:
        amount *= 0.3
        Fx.impact(level, hit_pos, Vector3.UP)
    hp -= amount
    label.text = "%s  %d%%" % [display_name, int(ceil(maxf(hp, 0.0) / max_hp * 100.0))]
    if hp <= 0.0:
        _destroy()
    return false


func _destroy() -> void:
    alive = false
    remove_from_group("damageable")
    label.text = "DESTROYED"
    label.modulate = Color(0.6, 0.6, 0.6)
    for b in blinkers:
        b.visible = false
    for m in mats:
        m.emission_enabled = false
        m.albedo_color = m.albedo_color.darkened(0.75)
    var p := global_position + Vector3(0, 1.5, 0)
    Fx.explosion(level, p, 6.0)
    Game.play_sfx("explosion", p, 4.0)
    Fx.fire(level, p, 1.4)
    level.apply_explosion(p, 6.0, 50.0)
    level.on_target_destroyed(self)
    var tw := create_tween()
    tw.tween_property(self, "rotation:z", deg_to_rad(randf_range(-9.0, 9.0)), 0.4)
