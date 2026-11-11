extends Node
## Per-operation cost: draw calls, objects, primitives, CPU process/physics time.
## godot --rendering-method gl_compatibility --path . res://tests/_perf.tscn -- 0,1,2
func _ready() -> void:
    Game.squad_size = 0
    Game.free_play = true
    Game.show_news = false
    var main = load("res://scenes/main.tscn").instantiate()
    add_child(main)
    for i in 10: await get_tree().process_frame
    var ids: Array = Array(OS.get_cmdline_user_args()[0].split(",")).map(func(s): return int(s))
    for i in ids:
        main.start_level(i)
        for f in 15: await get_tree().process_frame
        var L = main.level
        L.player.invulnerable = true
        var dc := 0.0; var ob := 0.0; var pr := 0.0; var tp := 0.0; var tph := 0.0; var n := 0
        var t0 := Time.get_ticks_msec()
        for f in 20:
            await get_tree().process_frame
            dc += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
            ob += Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
            pr += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
            tp += Performance.get_monitor(Performance.TIME_PROCESS)
            tph += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
            n += 1
        var ms := float(Time.get_ticks_msec() - t0) / n
        var nodes: float = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
        var lights: Array = L.find_children("*", "Light3D", true, false)
        var shadowed: int = lights.filter(func(l): return l.shadow_enabled).size()
        var shapes: int = L.find_children("*", "CollisionShape3D", true, false).size()
        print("PERF L%d draws %d objs %d prims %dk  process %.1fms physics %.1fms  frame %.1fms  nodes %d lights %d (shadow %d) shapes %d enemies %d" % [i, dc / n, ob / n, pr / n / 1000, tp / n * 1000, tph / n * 1000, ms, nodes, lights.size(), shadowed, shapes, L.enemies.size()])
    get_tree().quit()
