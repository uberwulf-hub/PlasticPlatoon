extends Node3D
## Unguided rocket (AT4 / enemy RPG). Moves manually and ray-tests each step.

const Fx = preload("res://scripts/fx.gd")

var shooter: Node3D
var level: Node
var dir := Vector3.FORWARD
var speed := 48.0
var damage := 150.0
var radius := 5.0
var life := 5.0
var _smoke_t := 0.0
var _done := false
var visual_only := false       # LAN: a harmless copy; the host has the real one


func setup(src: Node3D, lvl: Node, pos: Vector3, d: Vector3, dmg: float, rad: float) -> void:
    shooter = src
    level = lvl
    position = pos
    dir = d.normalized()
    damage = dmg
    radius = rad


func _ready() -> void:
    var body := MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.top_radius = 0.07
    cm.bottom_radius = 0.07
    cm.height = 0.7
    body.mesh = cm
    var m := StandardMaterial3D.new()
    m.albedo_color = Color(0.3, 0.32, 0.26)
    body.material_override = m
    body.rotation.x = PI / 2
    add_child(body)
    var flame := MeshInstance3D.new()
    var sm := SphereMesh.new()
    sm.radius = 0.12
    sm.height = 0.3
    flame.mesh = sm
    flame.material_override = Fx.unlit(Color(1.0, 0.7, 0.3, 0.95))
    flame.position = Vector3(0, 0, 0.42)
    add_child(flame)
    var l := OmniLight3D.new()
    l.light_color = Color(1.0, 0.6, 0.3)
    l.light_energy = 2.0
    l.omni_range = 4.0
    l.position = Vector3(0, 0, 0.5)
    add_child(l)
    Fx.safe_look_at(self, global_position + dir)


func _physics_process(delta: float) -> void:
    if _done:
        return
    life -= delta
    if life <= 0.0:
        _explode(global_position)
        return
    var step := dir * speed * delta
    var ex: Array[RID] = []
    if is_instance_valid(shooter) and shooter is CollisionObject3D:
        ex.append(shooter.get_rid())
        # Green rockets fly past our own squadmates.
        if not shooter.is_in_group("enemies") and not shooter.get("ai"):
            for m in shooter.get_tree().get_nodes_in_group("squad"):
                ex.append(m.get_rid())
    var hit := Fx.ray(self, global_position, global_position + step, 1 | 2 | 4, ex)
    if not hit.is_empty():
        _explode(hit["position"] - dir * 0.2)
        return
    global_position += step
    _smoke_t -= delta
    if _smoke_t <= 0.0:
        _smoke_t = 0.035
        Fx.smoke_puff(level, global_position - dir * 0.5)


func _explode(p: Vector3) -> void:
    _done = true
    if visual_only:
        queue_free()          # the host's real rocket sends the explosion
        return
    level.boom(p, radius * 0.8)
    level.apply_explosion(p, radius, damage)
    level.make_noise(p, 70.0)
    queue_free()
