extends RigidBody3D
## M67-style fragmentation grenade with a cook-off fuse.

const Fx = preload("res://scripts/fx.gd")

var level: Node
var fuse := 2.4
var radius := 6.5
var damage := 140.0
var _done := false


func setup(lvl: Node) -> void:
    level = lvl


func _ready() -> void:
    collision_layer = 0
    collision_mask = 1
    continuous_cd = true
    mass = 0.4
    var pm := PhysicsMaterial.new()
    pm.bounce = 0.25
    pm.friction = 0.8
    physics_material_override = pm
    var cs := CollisionShape3D.new()
    var sh := SphereShape3D.new()
    sh.radius = 0.12
    cs.shape = sh
    add_child(cs)
    var mi := MeshInstance3D.new()
    var sm := SphereMesh.new()
    sm.radius = 0.12
    sm.height = 0.24
    mi.mesh = sm
    var m := StandardMaterial3D.new()
    m.albedo_color = Color(0.2, 0.28, 0.15)
    m.roughness = 0.5
    mi.material_override = m
    add_child(mi)
    var lever := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = Vector3(0.04, 0.12, 0.05)
    lever.mesh = bm
    lever.material_override = m
    lever.position = Vector3(0.0, 0.14, 0.0)
    add_child(lever)


func _physics_process(delta: float) -> void:
    fuse -= delta
    if fuse <= 0.0 and not _done:
        _done = true
        var p := global_position
        Fx.explosion(level, p, radius * 0.75)
        Game.play_sfx("explosion", p)
        level.apply_explosion(p, radius, damage)
        level.make_noise(p, 70.0)
        queue_free()
