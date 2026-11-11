extends Node
## Finds invisible walls: probes the map on a grid at soldier height and reports
## colliders with no visible mesh near the blocked point.
## godot --headless --path . res://tests/_walls.tscn -- <level>
func _ready() -> void:
    Game.squad_size = 0
    Game.free_play = true
    Game.show_news = false
    var main = load("res://scenes/main.tscn").instantiate()
    add_child(main)
    for i in 5: await get_tree().process_frame
    var lv := int(OS.get_cmdline_user_args()[0])
    main.start_level(lv)
    for i in 10: await get_tree().physics_frame
    var L = main.level
    var space: PhysicsDirectSpaceState3D = L.get_world_3d().direct_space_state
    var sph := SphereShape3D.new()
    sph.radius = 0.3
    var found := {}
    var hx: float = 0.0
    var hz: float = 0.0
    for c in L.get_children():
        if c is StaticBody3D and c.get_child_count() == 1 and c.get_child(0) is CollisionShape3D:
            hx = maxf(hx, absf(c.position.x)); hz = maxf(hz, absf(c.position.z))
    print("bounds ~ ", hx, " x ", hz)
    var x := -hx + 1.0
    while x < hx - 1.0:
        var z := -hz + 1.0
        while z < hz - 1.0:
            # Ground height here.
            var rq := PhysicsRayQueryParameters3D.create(Vector3(x, 60, z), Vector3(x, -5, z), 1)
            var g := space.intersect_ray(rq)
            var gy: float = g["position"].y if g else 0.0
            for hgt in [0.9, 1.6]:
                var q := PhysicsShapeQueryParameters3D.new()
                q.shape = sph
                q.transform = Transform3D(Basis(), Vector3(x, gy + hgt, z))
                q.collision_mask = 1
                for hit in space.intersect_shape(q, 8):
                    var col: Node = hit["collider"]
                    if col is CharacterBody3D or (g and col == g["collider"] and hgt < 1.0):
                        continue
                    var p := Vector3(x, gy + hgt, z)
                    var seen := false
                    for m in col.find_children("*", "GeometryInstance3D", true, false):
                        if m is MeshInstance3D and m.is_visible_in_tree() and m.mesh != null:
                            var ab: AABB = (m.global_transform * m.get_aabb()).grow(0.6)
                            if ab.has_point(p):
                                seen = true
                                break
                    if not seen:
                        var key := str(col.get_path()).get_file() + " " + str(col.get("script") != null)
                        if not found.has(key):
                            found[key] = []
                        found[key].append(p.snapped(Vector3(0.5, 0.5, 0.5)))
            z += 1.0
        x += 1.0
    for k in found:
        var pts: Array = found[k]
        var desc := ""
        var col_node = null
        print("INVISIBLE ", k, " hits ", pts.size(), " e.g. ", pts.slice(0, 4))
    get_tree().quit()
