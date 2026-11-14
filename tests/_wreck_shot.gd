extends Node
func _ready() -> void:
    var out: String = OS.get_cmdline_user_args()[0]
    Game.squad_size = 0
    Game.free_play = true
    Game.show_news = false
    var main = load("res://scenes/main.tscn").instantiate()
    add_child(main)
    for i in 5: await get_tree().process_frame
    main.start_level(1)
    for i in 15: await get_tree().process_frame
    var L = main.level
    var p = L.player
    p.invulnerable = true
    var tank = L.vehicles.filter(func(v): return v.kind == "tank")[0]
    var car = L.vehicles.filter(func(v): return v.kind == "car")[0]
    for e in L.enemies: e.set_physics_process(false)
    for v in L.vehicles:
        if v != tank and v != car:
            v.global_position = Vector3(500, -50, 500)
    tank.global_position = Vector3(-3.5, 0.5, 30); tank.rotation.y = 0.5
    car.global_position = Vector3(3.5, 0.5, 31); car.rotation.y = -0.4
    p.global_position = Vector3(0, 0.5, 40); p.rotation.y = 0.0; p.pitch = -0.25
    for i in 20: await get_tree().physics_frame
    tank.take_damage(99999.0, tank.global_position, tank.global_position, true)
    car.take_damage(99999.0, car.global_position, car.global_position, true)
    for i in 360: await get_tree().physics_frame
    for v in [tank, car]:
        v.set_physics_process(false)
    tank.global_position.x = -3.5; tank.global_position.z = 30
    car.global_position.x = 3.5; car.global_position.z = 31
    p.global_position = Vector3(0, 0.5, 42)
    for i in 30: await get_tree().process_frame
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(out + "/wrecks.png")
    get_tree().quit()
