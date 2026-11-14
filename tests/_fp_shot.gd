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
    var p = main.level.player
    p.invulnerable = true
    p.pitch = -0.05
    Game.view_dist = 0.0
    for i in 40: await get_tree().physics_frame
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(out + "/fp.png")
    Game.view_dist = 3.4
    get_tree().quit()
