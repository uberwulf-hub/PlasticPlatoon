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
    var car = null
    var bike = null
    for v in L.vehicles:
        if v.kind == "car" and car == null: car = v
        if v.kind == "bike" and bike == null: bike = v
    print("cars %d bikes %d" % [L.vehicles.filter(func(v): return v.kind == "car").size(), L.vehicles.filter(func(v): return v.kind == "bike").size()])
    # Look at a parked car and bike side by side.
    car.global_position = Vector3(0, 0.5, 80); car.rotation.y = 0.6
    bike.global_position = Vector3(4, 0.5, 80); bike.rotation.y = -0.4
    car.hp = car.max_hp * 0.55
    var tj = L.enemy_vehicles[0]
    tj.set_physics_process(false)
    tj.global_position = Vector3(-5, 0.5, 74); tj.rotation.y = 0.9
    tj.hp = tj.max_hp * 0.3
    p.global_position = Vector3(2, 0.5, 88); p.rotation.y = 0.0; p.pitch = -0.15
    for i in 20: await get_tree().physics_frame
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(out + "/parked.png")
    # Ride the bike round a bend.
    bike.enter(p)
    bike.drive_input = Vector2(-0.8, -1.0)
    for i in 40: await get_tree().physics_frame
    print("bike speed %.1f lean %.2f rider %s" % [bike.speed, bike.visual.rotation.z, bike.rider.visible])
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(out + "/riding.png")
    get_tree().quit()
