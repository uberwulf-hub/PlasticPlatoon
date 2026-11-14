extends Node
func _ready() -> void:
    var out: String = OS.get_cmdline_user_args()[0]
    Game.player_name = "Dad"
    var main = load("res://scenes/main.tscn").instantiate()
    add_child(main)
    for i in 20: await get_tree().process_frame
    Game.friend_code = "K7QM2XPA"
    Game.friends = [{"code": "B4TTL3ZZ", "name": "Jake"}, {"code": "Q9RRMX2T", "name": "Grandpa"}, {"code": "M8HHT2QW", "name": "Sam"}]
    Net.friends_online = {"B4TTL3ZZ": true}
    main.show_multiplayer()
    for i in 10: await get_tree().process_frame
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(out + "/mp_menu.png")
    Net.stop_discovery()
    Net.host_online("Dad")
    main.show_lobby()
    while Net.room_code == "":
        await get_tree().process_frame
    main.show_lobby()
    for i in 10: await get_tree().process_frame
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(out + "/mp_lobby.png")
    Net.leave()
    get_tree().quit()
