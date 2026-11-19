extends Node
## Screenshots of The Big Flush in the real game.
## xvfb-run godot --path . res://tests/_flush_shot.tscn -- <outdir>
func _ready() -> void:
    var out: String = OS.get_cmdline_user_args()[0]
    Game.squad_size = 2
    Game.free_play = true
    Game.show_news = false
    var main = load("res://scenes/main.tscn").instantiate()
    add_child(main)
    for i in 5: await get_tree().process_frame
    main.start_level(113)
    for i in 30: await get_tree().process_frame
    var L = main.level
    var M = L.mode
    var p = L.player
    p.invulnerable = true
    p.pitch = 0.25
    for i in 40: await get_tree().physics_frame
    await _snap(out + "/flush_1_bowl.png")
    M.coins = 99999
    M.use(M.doors[0])
    for i in 90: await get_tree().physics_frame
    var cam := Camera3D.new()
    L.add_child(cam)
    var C := Vector3(4, 0, -19)
    cam.fov = 70
    cam.global_position = C + Vector3(-4, 16, -10)
    cam.look_at(C + Vector3(0, 21, 10))
    cam.current = true
    await _snap(out + "/flush_2_ramp.png")
    cam.global_position = C + Vector3(5, 30, 18)
    cam.look_at(Vector3(-4, 0, 34))
    await _snap(out + "/flush_3_floor.png")
    for d in M.doors.duplicate():
        M.use(d)
    for i in 90: await get_tree().physics_frame
    cam.global_position = Vector3(10, 22, 40)
    cam.look_at(Vector3(-24, 6, -6))
    await _snap(out + "/flush_4_tub.png")
    cam.global_position = Vector3(26, 14, 6)
    cam.look_at(Vector3(28, 2, -30))
    await _snap(out + "/flush_5_corner.png")
    get_tree().quit()


func _snap(path: String) -> void:
    for i in 4: await get_tree().process_frame
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(path)
