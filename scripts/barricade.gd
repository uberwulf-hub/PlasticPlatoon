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
var style := "wood"               # "wood" planks, or "porcelain": a crack in a toilet bowl
var spawn_depth := Vector2(3.2, 4.4)   # how far outside the Melties appear
var spawn_side := 1.6
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
    if style == "porcelain":
        # Shards of porcelain stuck back over the crack with plaster.
        # The very same glaze as the toilet (level.mat hands back its shared
        # material), so the patch matches the bowl's colour and sheen.
        if level != null and level.has_method("mat"):
            wood = level.mat(Color(0.93, 0.95, 0.98), 0.18)
        else:
            wood.albedo_color = Color(0.93, 0.95, 0.98)
            wood.roughness = 0.18
        wood.cull_mode = BaseMaterial3D.CULL_DISABLED
    elif ResourceLoader.exists("res://assets/textures/table_wood/albedo.jpg"):
        wood = level.tex("table_wood", Color(0.85, 0.7, 0.55), 2.0)
    if style == "porcelain":
        _build_shards(wood)
    for i in (0 if style == "porcelain" else PLANKS):
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


## The crack in a toilet bowl: five jagged pieces of porcelain that fit
## together like a cracked puzzle, filling the hole. Melties knock them out
## one at a time; nailing back = plastering a piece back in.
func _build_shards(m: StandardMaterial3D) -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = int(absf(position.x * 131.0 + position.z * 17.0)) + 7
    var c := Vector2(0, 1.35)
    var rx := 1.4
    var ry := 1.35
    var cuts: Array = []                  # the cracks between pieces, centre -> edge
    for k in PLANKS:
        var a := (k + rng.randf_range(-0.2, 0.2)) * TAU / PLANKS + 0.3
        var line: Array = [c + Vector2(rng.randf_range(-0.12, 0.12), rng.randf_range(-0.12, 0.12))]
        for t in [0.35, 0.7]:
            var p: Vector2 = c + Vector2(cos(a) * rx, sin(a) * ry) * t
            line.append(p + Vector2(rng.randf_range(-0.14, 0.14), rng.randf_range(-0.14, 0.14)))
        line.append(c + Vector2(cos(a) * rx, sin(a) * ry) * 1.12)
        cuts.append([a, line])
    # Every piece shares its two cracks with its neighbours, so they fit.
    var plaster: StandardMaterial3D = m.duplicate()
    plaster.albedo_color = Color(0.5, 0.47, 0.42)       # dark lines between the pieces
    for k in PLANKS:
        var a0: float = cuts[k][0]
        var a1: float = cuts[(k + 1) % PLANKS][0] + (TAU if k == PLANKS - 1 else 0.0)
        var poly := PackedVector2Array()
        for p in cuts[k][1]:
            poly.append(p)
        for j in range(1, 6):
            var a := lerpf(a0, a1, j / 6.0)
            poly.append(c + Vector2(cos(a) * rx, sin(a) * ry) * (1.12 + rng.randf_range(-0.05, 0.05)))
        var back: Array = cuts[(k + 1) % PLANKS][1].duplicate()
        back.reverse()
        for p in back:
            poly.append(p)
        # A hairline gap between pieces (the cracks show).
        var mid := Vector2.ZERO
        for p in poly:
            mid += p
        mid /= poly.size()
        for i in poly.size():
            poly[i] = mid + (poly[i] - mid) * 0.95
        var sb := StaticBody3D.new()
        sb.collision_layer = 1
        sb.collision_mask = 0
        sb.position = Vector3(mid.x, mid.y, 0)
        var local := PackedVector2Array()
        for p in poly:
            local.append(p - mid)
        var mi := MeshInstance3D.new()
        mi.mesh = _slab(local, 0.22)
        mi.material_override = m
        sb.add_child(mi)
        var edge := MeshInstance3D.new()           # plaster round the edge of each piece
        edge.mesh = _slab(local, 0.16)
        edge.scale = Vector3(1.06, 1.06, 1.0)
        edge.material_override = plaster
        sb.add_child(edge)
        var lo := Vector2(INF, INF)
        var hi := Vector2(-INF, -INF)
        for p in local:
            lo = lo.min(p)
            hi = hi.max(p)
        var cs := CollisionShape3D.new()
        var bs := BoxShape3D.new()
        bs.size = Vector3(maxf(hi.x - lo.x, 0.3), maxf(hi.y - lo.y, 0.3), 0.25)
        cs.shape = bs
        cs.position = Vector3((hi.x + lo.x) * 0.5, (hi.y + lo.y) * 0.5, 0)
        sb.add_child(cs)
        add_child(sb)
        _boards.append([sb, sb.transform])


## A flat piece cut to a 2D outline, depth thick (drawn from both sides,
## with its own normals so it lights like the rest of the porcelain).
static func _slab(poly: PackedVector2Array, depth: float) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var tris := Geometry2D.triangulate_polygon(poly)
    if tris.is_empty():
        poly = Geometry2D.convex_hull(poly)
        tris = Geometry2D.triangulate_polygon(poly)
    var h := depth * 0.5
    for i in range(0, tris.size(), 3):
        for z in [h, -h]:
            var n := Vector3(0, 0, signf(z))
            _tri(st, n, Vector3(poly[tris[i]].x, poly[tris[i]].y, z), Vector3(poly[tris[i + 1]].x, poly[tris[i + 1]].y, z), Vector3(poly[tris[i + 2]].x, poly[tris[i + 2]].y, z))
    # Which way the outline runs decides which side of an edge is outside.
    var area := 0.0
    for i in poly.size():
        area += poly[i].cross(poly[(i + 1) % poly.size()])
    var flip := 1.0 if area < 0.0 else -1.0
    for i in poly.size():
        var a := poly[i]
        var b := poly[(i + 1) % poly.size()]
        var e := (b - a).normalized()
        var n := Vector3(e.y, -e.x, 0) * flip
        _tri(st, n, Vector3(a.x, a.y, h), Vector3(b.x, b.y, h), Vector3(b.x, b.y, -h))
        _tri(st, n, Vector3(a.x, a.y, h), Vector3(b.x, b.y, -h), Vector3(a.x, a.y, -h))
    return st.commit()


## One triangle, wound so its front face (clockwise in Godot) is the side
## its normal points to, so it lights the same from either side.
static func _tri(st: SurfaceTool, n: Vector3, a: Vector3, b: Vector3, c: Vector3) -> void:
    st.set_normal(n)
    if (b - a).cross(c - a).dot(n) < 0.0:
        var t := b
        b = c
        c = t
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)


## A Melty rips the top plank off.
func tear() -> void:
    if planks <= 0:
        return
    planks -= 1
    var b: StaticBody3D = _boards[planks][0]
    b.collision_layer = 0
    var tw := create_tween()
    tw.set_parallel(true)
    # Boards fly outward; porcelain pieces get pushed in and drop into the bowl.
    var push := Vector3(randf_range(-0.6, 0.6), -0.3, 1.4) if style != "porcelain" else Vector3(randf_range(-0.5, 0.5), -b.position.y + 0.15, -randf_range(1.2, 2.0))
    tw.tween_property(b, "position", b.position + push, 0.35)
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
