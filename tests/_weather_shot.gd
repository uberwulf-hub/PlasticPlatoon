extends Node
func _ready() -> void:
    var out: String = OS.get_cmdline_user_args()[0]
    Game.squad_size = 0
    Game.free_play = true
    Game.show_news = false
    Game.weather = true
    var main = load("res://scenes/main.tscn").instantiate()
    add_child(main)
    for i in 5: await get_tree().process_frame
    for lv in [0, 1, 4, 6]:
        main.start_level(lv)
        for i in 15: await get_tree().process_frame
        var L = main.level
        L.player.invulnerable = true
        L.player.pitch = 0.32           # look up a bit to see the sky
        L.hud.visible = false
        for i in 20: await get_tree().physics_frame
        if lv == 4 and L.weather:
            L.weather._thunder_t = 999.0
            L.weather.strike()
            for i in 2: await get_tree().process_frame
        await RenderingServer.frame_post_draw
        get_viewport().get_texture().get_image().save_png(out + "/w%d.png" % lv)
        print("WEATHER L%d %s rain=%s flashes=%d" % [lv, str(L.weather != null), str(L.weather.rain != null) if L.weather else "-", L.weather.flashes if L.weather else 0])
    get_tree().quit()
