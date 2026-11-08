extends Node3D
## MELTDOWN mode: a boarded-up window in the basement wall. Melties tear the
## planks off from outside; the player holds E on the inside to nail them back
## (and earns coins for it). A player-only blocker keeps you from walking out.

const PLANKS := 5
const BLOCK_LAYER := 16           # only the player and squad collide with this

var level: Node
var section := "A"
var normal := Vector3.BACK        # points outside
var width := 2.2
var planks := PLANKS
var outside_point := Vector3.ZERO
var inside_point := Vector3.ZERO
var _boards: Array = []           # [StaticBody3D, rest transform]


func setup(lvl: Node, pos: Vector3, n: Vector3, sec: String) -> void:
    level = lvl
    position = pos
    normal = n.normalized()
    section = sec
    outside_point = pos + normal * 1.3
    inside_point = pos - normal * 1.7


func _ready() -> void:
    rotation.y = atan2(normal.x, normal.z)      # local +Z = outside
    var wood := StandardMaterial3D.new()
    wood.albedo_color = Color(0.55, 0.4, 0.25)
    if ResourceLoader.exists("res://assets/textures/table_wood/albedo.jpg"):
        wood = level.tex("table_wood", Color(0.85, 0.7, 0.55), 2.0)
    for i in PLANKS:
        var sb := StaticBody3D.new()
        sb.collision_layer = 1
        sb.collision_mask = 0
        var y := 0.45 + i * 0.42
        sb.position = Vector3(0, y, 0)
        sb.rotation.z = deg_to_rad([-6.0, 5.0, -3.0, 7.0, -5.0][i])
        var mi := MeshInstance3D.new()
        var bm := BoxMesh.new()
        bm.size = Vector3(width + 0.5, 0.26, 0.12)
        mi.mesh = bm
        mi.material_override = wood
        sb.add_child(mi)
        var cs := CollisionShape3D.new()
        var bs := BoxShape3D.new()
        bs.size = bm.size
        cs.shape = bs
        sb.add_child(cs)
        add_child(sb)
        _boards.append([sb, sb.transform])
    # Keeps the green side inside even with every plank gone.
    var blk := StaticBody3D.new()
    blk.collision_layer = BLOCK_LAYER
    blk.collision_mask = 0
    var bcs := CollisionShape3D.new()
    var bb := BoxShape3D.new()
    bb.size = Vector3(width, 3.0, 0.3)
    bcs.shape = bb
    bcs.position.y = 1.5
    blk.add_child(bcs)
    add_child(blk)


## A Melty rips the top plank off.
func tear() -> void:
    if planks <= 0:
        return
    planks -= 1
    var b: StaticBody3D = _boards[planks][0]
    b.collision_layer = 0
    var tw := create_tween()
    tw.set_parallel(true)
    tw.tween_property(b, "position", b.position + Vector3(randf_range(-0.6, 0.6), -0.3, 1.4), 0.35)
    tw.tween_property(b, "rotation", b.rotation + Vector3(randf_range(-1, 1), randf_range(-1, 1), 1.2), 0.35)
    tw.chain().tween_callback(func(): b.visible = false)
    Game.play_sfx("reload_shotgun", global_position, -2.0)


## The player nails one back. Returns true if there was room for it.
func rebuild() -> bool:
    if planks >= PLANKS:
        return false
    var b: StaticBody3D = _boards[planks][0]
    b.transform = _boards[planks][1]
    b.visible = true
    b.collision_layer = 1
    planks += 1
    Game.play_sfx("reload_rifle", global_position, -4.0)
    return true
