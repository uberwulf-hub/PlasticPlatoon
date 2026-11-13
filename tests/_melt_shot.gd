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
    p.global_position = L.safe_center + Vector3(L.safe_radius + 8.0, 0.5, 0)
    p.rotation.y = 0.0
    p.pitch = -0.2
    for i in 10: await get_tree().physics_frame
    p.invulnerable = false
    var c: Vector3 = p.global_position
    var back: Vector3 = p.global_transform.basis.z
    for h in [c + Vector3(0, 1.3, 0) + back * 0.3, c + Vector3(0.25, 1.6, 0) + back * 0.25, c + Vector3(-0.2, 0.6, 0) + back * 0.25]:
        p.take_damage(12.0, h + back * 3.0, h, false)
    p.take_damage(15.0, c + back * 3.0, c + Vector3(0.1, 1.0, 0) + back * 0.3, true)
    p.invulnerable = true
    print("marks %d wear %.2f" % [p.model.damage_marks(), p.model._wear])
    for i in 8: await get_tree().process_frame
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(out + "/melt_still.png")
    # Walk forward: the melt must move with him.
    for f in 25:
        Input.action_press("move_forward")
        await get_tree().physics_frame
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(out + "/melt_walk.png")
    Input.action_release("move_forward")
    get_tree().quit()
