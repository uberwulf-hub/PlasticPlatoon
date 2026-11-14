extends Node
func _ready() -> void:
    var out: String = OS.get_cmdline_user_args()[0]
    Game.player_name = "Dad"
    var main = load("res://scenes/main.tscn").instantiate()
    add_child(main)
    for i in 20: await get_tree().process_frame
    main.show_multiplayer()
    for i in 10: await get_tree().process_frame
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(out + "/mp_menu.png")
    Net.stop_discovery()
    Net.host_online("Dad")
    main.show_lobby()
    while Net.room_code == "":
        await get_tree().process_frame
    for i in 10: await get_tree().process_frame
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(out + "/mp_lobby.png")
    Net.leave()
    get_tree().quit()
