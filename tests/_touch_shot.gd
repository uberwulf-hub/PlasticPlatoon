extends Node
## Screenshots of the phone controls: on foot, in a tank, and the layout editor.
## xvfb-run godot --path . --resolution 1600x720 res://tests/_touch_shot.tscn -- <outdir>
func _ready() -> void:
    var out: String = OS.get_cmdline_user_args()[0]
    Game.squad_size = 2
    Game.free_play = true
    Game.show_news = false
    Game.touch_controls = true
    Game.touch_mode = true
    Game.touch_layout = {}
    Game.touch_size = 1.0
    Game.ui_scale = 1.25
    Game.apply_ui_scale()
    var main = load("res://scenes/main.tscn").instantiate()
    add_child(main)
    for i in 5: await get_tree().process_frame
    main.show_main_menu()
    for i in 10: await get_tree().process_frame
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(out + "/touch_menu.png")
    main.show_meltdown()
    for i in 10: await get_tree().process_frame
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(out + "/touch_meltdown_menu.png")
    main.start_level(1)
    for i in 15: await get_tree().process_frame
    var L = main.level
    var p = L.player
    p.invulnerable = true
    for i in 60: await get_tree().physics_frame
    L.hud.prompt_label.text = "Tap USE to drive the JEEP"
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(out + "/touch_foot.png")
    # Into the nearest armed vehicle.
    var best = null
    for v in L.vehicles:
        if is_instance_valid(v) and not v.ai and v.k.get("primary", "none") != "none" and not v.k.get("flies", false):
            if best == null or v.global_position.distance_to(p.global_position) < best.global_position.distance_to(p.global_position):
                best = v
    if best:
        best.enter(p)
        for i in 60: await get_tree().physics_frame
        await RenderingServer.frame_post_draw
        get_viewport().get_texture().get_image().save_png(out + "/touch_vehicle.png")
    # The layout editor, with FIRE dragged somewhere else and bigger buttons.
    get_tree().paused = false
    main.level.queue_free()
    main.level = null
    Game.current_level = null
    Game.touch_size = 1.15
    Game.touch_layout = {"fire": Vector2(0.84, 0.62), "aim": Vector2(0.93, 0.85)}
    main.show_touch_layout()
    for i in 5: await get_tree().process_frame
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(out + "/touch_editor.png")
    Game.touch_layout = {}
    Game.touch_size = 1.0
    Game.touch_controls = false
    Game.touch_mode = false
    Game.ui_scale = 1.0
    Game.save()
    get_tree().quit()
