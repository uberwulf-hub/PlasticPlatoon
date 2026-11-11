extends Node
func _ready() -> void:
    var out: String = OS.get_cmdline_user_args()[0]
    Game.squad_size = 0
    var main = load("res://scenes/main.tscn").instantiate()
    add_child(main)
    for i in 10: await get_tree().process_frame
    main.show_meltdown()
    for i in 5: await get_tree().process_frame
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(out + "/md_menu.png")
    for k in [10, 11, 12]:
        main.start_level(100 + k)
        for i in 8: await get_tree().process_frame
        var p = main.level.player
        p.invulnerable = true
        for view in 2:
            if view == 1:
                var M = main.level.mode
                M.coins = 99999
                for d in M.doors.duplicate():
                    M.use(d)
                p.global_position = Vector3(0, 0.5, [0.0, 2.0, 0.0][k - 10])
                p.rotation.y = 0.0
            p.pitch = -0.12
            for i in 6: await get_tree().process_frame
            await RenderingServer.frame_post_draw
            get_viewport().get_texture().get_image().save_png(out + "/md_%d_%d.png" % [k, view])
    get_tree().quit()
