extends Node
func _ready() -> void:
    var out: String = OS.get_cmdline_user_args()[0]
    Game.squad_size = 0
    Game.show_news = false
    var main = load("res://scenes/main.tscn").instantiate()
    add_child(main)
    for i in 5: await get_tree().process_frame
    main.start_level(100)
    for i in 15: await get_tree().process_frame
    var L = main.level
    var M = L.mode
    var p = L.player
    p.invulnerable = true
    M.break_t = 999.0
    var base: Vector3 = p.global_position
    var fwd: Vector3 = -p.global_transform.basis.z
    var side: Vector3 = p.global_transform.basis.x
    var e = L.add_enemy(base + fwd * 6.0 - side * 1.3 + Vector3(0, 0.2, 0), "rifleman")
    var m = M._spawn_one("brute")
    m.global_position = base + fwd * 6.0 + side * 1.6 + Vector3(0, 0.3, 0)
    m.state = m.HUNTING
    for i in 20: await get_tree().physics_frame
    e.set_physics_process(false)
    m.set_physics_process(false)
    p.pitch = -0.22
    for i in 10: await get_tree().physics_frame
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(out + "/d0.png")
    e.take_damage(9999.0, p.global_position, e.global_position + Vector3(0, 1.2, 0), false)
    m.take_damage(99999.0, p.global_position, m.global_position + Vector3(0, 1.2, 0), false)
    var game_t := 0.0                    # game time (frames are slow here)
    var k := 1
    for at in [0.5, 1.4, 2.6, 4.0, 5.6, 7.4]:
        while game_t < at:
            await get_tree().process_frame
            game_t += get_process_delta_time()
        await RenderingServer.frame_post_draw
        get_viewport().get_texture().get_image().save_png(out + "/d%d.png" % k)
        k += 1
    get_tree().quit()
