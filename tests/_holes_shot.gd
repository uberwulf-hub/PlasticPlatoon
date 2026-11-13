extends Node
func _ready() -> void:
    var out: String = OS.get_cmdline_user_args()[0]
    Game.squad_size = 0
    Game.free_play = true
    Game.show_news = false
    var main = load("res://scenes/main.tscn").instantiate()
    add_child(main)
    for i in 5: await get_tree().process_frame
    main.start_level(0)
    for i in 15: await get_tree().process_frame
    var L = main.level
    var p = L.player
    p.invulnerable = true
    for e in L.enemies: e.set_physics_process(false)
    var M = load("res://tests/_world_damage_mockup.gd").new()
    M.L = L
    var space: PhysicsDirectSpaceState3D = L.get_world_3d().direct_space_state
    var wall := {}
    for k in 72:
        var dir := Vector3.FORWARD.rotated(Vector3.UP, k * TAU / 72.0)
        for start in [Vector3(0, 1.5, 20), Vector3(20, 1.5, 0), Vector3(-20, 1.5, -10), Vector3(0, 1.5, -30)]:
            var h: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(start, start + dir * 25.0, 1))
            if h and M._is_big_wall(h["collider"]) and absf(h["normal"].y) < 0.2:
                wall = h
                break
        if wall: break
    var n: Vector3 = wall["normal"]
    var wp: Vector3 = wall["position"]
    var side := n.cross(Vector3.UP).normalized()
    wp += side * side.dot(wall["collider"].global_position - wp)
    p.global_position = wp + n * 7.0
    p.velocity = Vector3.ZERO
    p.rotation.y = atan2(n.x, n.z)
    p.pitch = -0.02
    for i in 10: await get_tree().physics_frame
    for k in 14:
        p.pitch = randf_range(-0.12, 0.12)
        p.rotation.y = atan2(n.x, n.z) + randf_range(-0.25, 0.25)
        await get_tree().physics_frame
        p.fire_cd = 0.0
        p._fire(p.cur())
        await get_tree().physics_frame
    p.rotation.y = atan2(n.x, n.z)
    p.pitch = -0.15
    L.boom_local(wp + n * 2.5 - side * 2.0 + Vector3(0, -0.5, 0), 4.0)
    for i in 60: await get_tree().physics_frame
    print("marks %d" % L.mark_count())
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(out + "/holes_ingame.png")
    get_tree().quit()
