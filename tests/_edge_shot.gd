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
    for i in 10: await get_tree().process_frame
    var L = main.level
    var p = L.player
    p.invulnerable = true
    for k in 2:
        p.global_position = Vector3(30, 8, -102.0 + k * 3.5)
        p.velocity = Vector3.ZERO
        p.rotation.y = 0.0
        p.pitch = -0.05
        for i in 20: await get_tree().physics_frame
        print("edge alpha %.2f msg '%s'" % [L.edge_alpha, L.hud.msg_label.text])
        await RenderingServer.frame_post_draw
        get_viewport().get_texture().get_image().save_png(out + "/edge_%d.png" % k)
    get_tree().quit()
