extends StaticBody3D
## Explosive barrel (Quaternius Toon Shooter "ExplodingBarrel", CC0).
## A few bullets or any blast sets it off - chain reactions welcome.

const Fx = preload("res://scripts/fx.gd")

var level: Node
var hp := 25.0
var alive := true


func setup(lvl: Node, pos: Vector3) -> void:
    level = lvl
    position = pos


func _ready() -> void:
    add_to_group("damageable")
    var ps_path := "res://assets/packs/quaternius_toon_shooter/Environment/ExplodingBarrel.gltf"
    if ResourceLoader.exists(ps_path):
        var m: Node3D = load(ps_path).instantiate()
        m.scale = Vector3.ONE * 1.15
        add_child(m)
    else:
        var mi := MeshInstance3D.new()
        var cm := CylinderMesh.new()
        cm.top_radius = 0.45
        cm.bottom_radius = 0.45
        cm.height = 1.15
        mi.mesh = cm
        var mat := StandardMaterial3D.new()
        mat.albedo_color = Color(0.8, 0.15, 0.1)
        mi.material_override = mat
        mi.position.y = 0.58
        add_child(mi)
    var cs := CollisionShape3D.new()
    var sh := CylinderShape3D.new()
    sh.radius = 0.45
    sh.height = 1.15
    cs.shape = sh
    cs.position.y = 0.58
    add_child(cs)


func take_damage(amount: float, _source: Vector3, _hit_pos: Vector3, explosive := false) -> bool:
    if not alive:
        return false
    hp -= amount
    if hp <= 0.0:
        alive = false
        remove_from_group("damageable")
        # Defer one frame so chain reactions ripple outward instead of recursing.
        get_tree().create_timer(0.08 if explosive else 0.0).timeout.connect(_explode)
    return false


func _explode() -> void:
    if not is_inside_tree():
        return
    var p := global_position + Vector3(0, 0.6, 0)
    Fx.explosion(level, p, 4.5)
    Fx.fire(level, global_position, 0.7)
    Game.play_sfx("explosion", p, 2.0)
    level.apply_explosion(p, 5.5, 120.0)
    level.make_noise(p, 60.0)
    queue_free()
