extends Node
## World-damage mockups inside a real level: bullet holes in two styles on a
## building wall, explosion scorch on the ground and wall, and a melted jeep.
## godot --path . res://tests/_world_damage_mockup.tscn -- <outdir>
const MARK := preload("res://assets/shaders/surface_mark.gdshader")
const MELT := preload("res://assets/shaders/plastic_damage.gdshader")
var L

func _is_big_wall(c: Object) -> bool:
    if not c is StaticBody3D:
        return false
    for ch in c.get_children():
        if ch is CollisionShape3D and ch.shape is BoxShape3D:
            var sz: Vector3 = ch.shape.size
            return sz.y >= 2.5 and maxf(sz.x, sz.z) >= 5.0
    return false


## Like a real shot: cast at the wall and put the mark where it actually lands.
func shoot_mark(kind: int, aim: Vector3, n: Vector3, size: float, col: Color) -> void:
    var space: PhysicsDirectSpaceState3D = L.get_world_3d().direct_space_state
    var h: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(aim + n * 1.5, aim - n * 1.5, 1))
    if h and h["normal"].dot(n) > 0.8:
        mark(kind, h["position"], h["normal"], size, col)


func mark(kind: int, pos: Vector3, normal: Vector3, size: float, col: Color) -> void:
    var mi := MeshInstance3D.new()
    var q := QuadMesh.new()
    q.size = Vector2(size, size)
    mi.mesh = q
    var m := ShaderMaterial.new()
    m.shader = MARK
    m.set_shader_parameter("kind", kind)
    m.set_shader_parameter("seed", randf() * 10.0)
    m.set_shader_parameter("surface_color", col)
    mi.material_override = m
    mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    L.add_child(mi)
    mi.global_position = pos + normal * 0.015
    var up := Vector3.UP if absf(normal.dot(Vector3.UP)) < 0.9 else Vector3.FORWARD
    mi.look_at(mi.global_position - normal, up)
    mi.rotate_object_local(Vector3.FORWARD, randf() * TAU)

func _ready() -> void:
    seed(7)
    var out: String = OS.get_cmdline_user_args()[0]
    Game.squad_size = 0
    Game.free_play = true
    Game.show_news = false
    var main = load("res://scenes/main.tscn").instantiate()
    add_child(main)
    for i in 5: await get_tree().process_frame
    main.start_level(0)
    for i in 15: await get_tree().process_frame
    L = main.level
    var p = L.player
    p.invulnerable = true
    for e in L.enemies:
        e.set_physics_process(false)
    # Find a wall: look around from a spot near the village until a ray hits one.
    var space: PhysicsDirectSpaceState3D = L.get_world_3d().direct_space_state
    var wall_hit := {}
    var base := Vector3(0, 1.5, 20)
    for k in 72:
        var dir := Vector3.FORWARD.rotated(Vector3.UP, k * TAU / 72.0)
        for start in [Vector3(0, 1.5, 20), Vector3(20, 1.5, 0), Vector3(-20, 1.5, -10), Vector3(0, 1.5, -30)]:
            var h: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(start, start + dir * 25.0, 1))
            var tall: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(start + Vector3(0, 2.0, 0), start + Vector3(0, 2.0, 0) + dir * 25.0, 1))
            if h and _is_big_wall(h["collider"]) and absf(h["normal"].y) < 0.2 and start.distance_to(h["position"]) > 6.0:
                wall_hit = h
                base = start
                break
        if wall_hit:
            break
    var wp: Vector3 = wall_hit["position"]
    var n: Vector3 = wall_hit["normal"]
    var side := n.cross(Vector3.UP).normalized()
    var centre: Vector3 = wall_hit["collider"].global_position
    wp += side * side.dot(centre - wp)          # middle of the wall face
    var wallc := Color(0.75, 0.68, 0.55)
    for k in 9:
        shoot_mark(0, wp + side * randf_range(-2.6, -0.4) + Vector3(0, randf_range(-0.6, 1.4), 0), n, 0.3, wallc)
    for k in 9:
        shoot_mark(1, wp + side * randf_range(0.4, 2.6) + Vector3(0, randf_range(-0.6, 1.4), 0), n, 0.3, wallc)
    var g: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(wp + n * 3.0 - side * 1.0 + Vector3(0, 3, 0), wp + n * 3.0 - side * 1.0 + Vector3(0, -5, 0), 1))
    var sand := Color(0.85, 0.75, 0.55)
    mark(2, g["position"], g["normal"], 3.2, sand)
    shoot_mark(2, wp - side * 1.6 + Vector3(0, -0.5, 0), n, 1.8, wallc)
    # A jeep beside it with melted hits.
    var v = L.enemy_vehicles[0]
    for o in L.enemy_vehicles + L.vehicles:
        o.set_physics_process(false)
        o.set_process(false)
        o.hp_bar.visible = false
        if o != v:
            o.global_position = Vector3(500, -50, 500)
    v.set_physics_process(false)
    v.global_position = g["position"] + side * 6.5 + n * 0.5
    v.rotation.y = atan2(side.x, side.z)
    v.hp_bar.visible = false
    v.set_process(false)
    var hits: Array = []
    for hp in [Vector3(0.9, 1.0, -0.6), Vector3(-0.8, 0.9, 1.0), Vector3(0.2, 1.2, -1.6)]:
        var w: Vector3 = v.global_transform * hp
        hits.append(Vector4(w.x, w.y, w.z, 0.6))
    while hits.size() < 8:
        hits.append(Vector4.ZERO)
    var mm := ShaderMaterial.new()
    mm.shader = MELT
    mm.set_shader_parameter("style", 2)
    mm.set_shader_parameter("base_color", v.body_color)
    mm.set_shader_parameter("hits", hits)
    mm.set_shader_parameter("hit_count", 3)
    for mi in v.find_children("*", "MeshInstance3D", true, false):
        mi.material_overlay = mm
    var cam := Camera3D.new()
    cam.fov = 55
    L.add_child(cam)
    cam.global_position = wp + n * 11.0 + side * 2.5 + Vector3(0, 1.6, 0)
    cam.look_at(wp + n * 1.5 + side * 2.5 + Vector3(0, -0.4, 0))
    cam.current = true
    L.hud.visible = false
    for i in 12: await get_tree().process_frame
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(out + "/world_damage.png")
    cam.global_position = wp + n * 3.4 + Vector3(0, 0.4, 0)
    cam.look_at(wp + Vector3(0, 0.4, 0))
    for i in 4: await get_tree().process_frame
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(out + "/holes_close.png")
    get_tree().quit()
