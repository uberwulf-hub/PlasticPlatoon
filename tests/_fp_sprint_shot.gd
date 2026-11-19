extends Node
## First person while sprinting: frames over one stride (looking for body parts in view).
func _ready() -> void:
    var out: String = OS.get_cmdline_user_args()[0]
    Game.squad_size = 0
    Game.free_play = true
    Game.show_news = false
    Game.touch_mode = false
    var main = load("res://scenes/main.tscn").instantiate()
    add_child(main)
    for i in 5: await get_tree().process_frame
    main.start_level(0)
    for i in 15: await get_tree().process_frame
    var p = main.level.player
    p.invulnerable = true
    p.pitch = -0.1
    p.rotation.y += PI * 0.5
    Game.view_dist = 0.0
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    Input.action_press("move_forward")
    Input.action_press("sprint")
    var t := 0.0
    var n := 0
    while n < 12:
        await get_tree().physics_frame
        t += get_physics_process_delta_time()
        if t > 1.0 + n * 0.09:
            await RenderingServer.frame_post_draw
            get_viewport().get_texture().get_image().save_png("%s/fps_%02d.png" % [out, n])
            n += 1
    print("SPRINTING ", p.sprinting)
    for m in p.model.find_children("*", "MeshInstance3D", true, false):
        if m.is_visible_in_tree():
            print("MESH ", m.name)
    Input.action_release("move_forward")
    Input.action_release("sprint")
    Game.view_dist = 3.4
    get_tree().quit()
