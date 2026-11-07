extends Node3D
## Modern support: a loitering drone marks the target, then a Hellfire lands.

const Fx = preload("res://scripts/fx.gd")

const RADIUS := 9.0
const DAMAGE := 280.0

var level: Node
var target := Vector3.ZERO
var t := 0.0
var ring: MeshInstance3D
var ring_mat: StandardMaterial3D
var beam: MeshInstance3D
var missile: MeshInstance3D
var fired := false
var exploded := false
var visual_only := false


func setup(lvl: Node, pos: Vector3) -> void:
    level = lvl
    target = pos
    position = pos


func _ready() -> void:
    ring = MeshInstance3D.new()
    var tm := TorusMesh.new()
    tm.inner_radius = RADIUS - 0.4
    tm.outer_radius = RADIUS
    ring.mesh = tm
    ring_mat = Fx.unlit(Color(1.0, 0.15, 0.1, 0.8))
    ring.material_override = ring_mat
    ring.position.y = 0.15
    add_child(ring)
    beam = MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.top_radius = 0.08
    cm.bottom_radius = 0.08
    cm.height = 120.0
    beam.mesh = cm
    beam.material_override = Fx.unlit(Color(1.0, 0.2, 0.15, 0.35))
    beam.position.y = 60.0
    add_child(beam)
    Game.play_sfx("beep", global_position, 4.0)


func _process(delta: float) -> void:
    t += delta
    ring.rotation.y += delta * 2.0
    ring_mat.albedo_color.a = 0.5 + 0.4 * sin(t * 14.0)
    if t > 2.2 and not fired:
        fired = true
        missile = MeshInstance3D.new()
        var cm := CylinderMesh.new()
        cm.top_radius = 0.0
        cm.bottom_radius = 0.18
        cm.height = 1.6
        missile.mesh = cm
        missile.material_override = Fx.unlit(Color(0.9, 0.9, 0.85))
        add_child(missile)
        missile.position = Vector3(10, 80, 6)
        missile.rotation = Vector3(PI, 0, 0)
        var tw := missile.create_tween()
        tw.tween_property(missile, "position", Vector3(0, 0.5, 0), 0.5).set_ease(Tween.EASE_IN)
    if fired and missile and not exploded and t > 2.45:
        Fx.smoke_puff(level, missile.global_position)
    if t > 2.7 and not exploded:
        exploded = true
        if visual_only:
            queue_free()
            return
        level.boom(target, RADIUS * 0.85, 6.0)
        level.apply_explosion(target, RADIUS, DAMAGE)
        level.make_noise(target, 90.0)
        queue_free()
