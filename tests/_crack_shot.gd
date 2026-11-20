extends Node
## Screenshots of The Big Flush cracks: from inside the bowl, half broken, and from outside.
func _ready() -> void:
    var out: String = OS.get_cmdline_user_args()[0]
    Game.squad_size = 0
    Game.free_play = true
    Game.show_news = false
    var main = load("res://scenes/main.tscn").instantiate()
    add_child(main)
    for i in 5: await get_tree().process_frame
    main.start_level(113)
    for i in 30: await get_tree().process_frame
    var L = main.level
    var M = L.mode
    L.player.invulnerable = true
    L.player.visible = false
    for m in L.squad:
        m.visible = false
    var MM = load("res://scripts/meltdown_maps.gd")
    var C: Vector3 = MM.FLUSH_C
    var cam := Camera3D.new()
    L.add_child(cam)
    cam.current = true
    cam.fov = 70
    # Inside: the 45-degree crack, whole, then with three pieces knocked out.
    var b = M.barricades[1]
    cam.global_position = b.global_position - b.normal * 7.0 + Vector3(0, 2.2, 0)
    cam.look_at(b.global_position + Vector3(0, 1.3, 0))
    await _snap(out + "/crack_1_whole.png")
    for k in 3:
        b.tear()
    for i in 30: await get_tree().physics_frame
    await _snap(out + "/crack_2_broken.png")
    for k in 2:
        b.tear()
    for i in 30: await get_tree().physics_frame
    await _snap(out + "/crack_3_open.png")
    # Outside: the Melties' ramp up the side of the toilet.
    var n: Vector3 = b.normal
    cam.global_position = b.global_position + n * 26.0 + Vector3(-8, 10, 6)
    cam.look_at(b.global_position + n * 8.0 + Vector3(0, 6, 0))
    await _snap(out + "/crack_4_outside.png")
    get_tree().quit()


func _snap(path: String) -> void:
    for i in 4: await get_tree().process_frame
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(path)
