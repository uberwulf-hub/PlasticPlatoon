extends Node
## Stress: the Concrete Jungle SAM firefight. Frame times while enemies, a tank
## and explosions all go off near the player.  -- <level> [rendered]
var times: Array = []
func _ready() -> void:
    Game.squad_size = 0
    Game.free_play = true
    Game.show_news = false
    var main = load("res://scenes/main.tscn").instantiate()
    add_child(main)
    for i in 5: await get_tree().process_frame
    main.start_level(1)
    for i in 20: await get_tree().process_frame
    var L = main.level
    var p = L.player
    p.invulnerable = true
    p.global_position = Vector3(-78, 0.6, 38)      # just south of SAM A
    p.rotation.y = 0.0
    var tank = null
    for v in L.vehicles:
        if v.kind == "tank":
            tank = v
    if tank != null:
        tank.global_position = Vector3(-74, 0.5, 42)
    var last := Time.get_ticks_usec()
    var nodes_max := 0
    for f in 600:
        await get_tree().process_frame
        var now := Time.get_ticks_usec()
        times.append((now - last) / 1000.0)
        last = now
        if f % 25 == 0:
            L.boom(Vector3(-78 + randf_range(-8, 8), 0.5, 25 + randf_range(-8, 8)), 4.0)
        if f % 4 == 0:
            p.fire_cd = 0.0
            p._fire(p.cur())
        nodes_max = maxi(nodes_max, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
    times.sort()
    var avg: float = times.reduce(func(a, b): return a + b) / times.size()
    var slow := times.filter(func(t): return t > 33.0).size()
    print("FIGHT avg %.1fms  p95 %.1fms  worst %.1fms  frames>33ms %d  nodes max %d  enemies hunting %d" % [avg, times[int(times.size() * 0.95)], times[-1], slow, nodes_max, L.enemies.filter(func(e): return is_instance_valid(e) and e.alive and e.state == e.HUNTING).size()])
    get_tree().quit()
