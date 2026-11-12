extends Node
const Fx = preload("res://scripts/fx.gd")
func _t(label: String, f: Callable) -> void:
    var t0 := Time.get_ticks_usec()
    f.call()
    var t1 := Time.get_ticks_usec()
    await get_tree().process_frame
    var t2 := Time.get_ticks_usec()
    await get_tree().process_frame
    var t3 := Time.get_ticks_usec()
    print("SPIKE %-28s call %6.1fms  next frame %6.1fms  frame after %6.1fms" % [label, (t1 - t0) / 1000.0, (t2 - t1) / 1000.0, (t3 - t2) / 1000.0])

func _ready() -> void:
    Game.squad_size = 0
    Game.free_play = true
    Game.show_news = false
    var main = load("res://scenes/main.tscn").instantiate()
    add_child(main)
    for i in 5: await get_tree().process_frame
    main.start_level(1)
    for i in 30: await get_tree().process_frame
    var L = main.level
    L.player.invulnerable = true
    for k in 3:
        await _t("boom %d" % k, func(): L.boom(Vector3(0, 1, 60), 4.0))
    for k in 2:
        await _t("fire %d" % k, func(): Fx.fire(L, Vector3(0, 1, 55), 1.5))
    var es: Array = L.enemies.filter(func(e): return e.alive)
    for k in 3:
        var e = es[k]
        await _t("enemy dies %d" % k, func(): e.take_damage(9999.0, e.global_position + Vector3(0, 0, 5), e.global_position + Vector3(0, 1.2, 0), true))
    for k in 3:
        var e = es[3 + k]
        await _t("enemy hit %d" % k, func(): e.take_damage(1.0, e.global_position + Vector3(0, 0, 5), e.global_position + Vector3(0.2, 1.2, 0), false))
    var vs: Array = L.enemy_vehicles.filter(func(v): return v.alive)
    for k in mini(3, vs.size()):
        var v = vs[k]
        await _t("vehicle %s destroyed" % v.kind, func(): v.take_damage(99999.0, v.global_position, v.global_position, true))
    for k in 2:
        await _t("apply_explosion %d" % k, func(): L.apply_explosion(Vector3(0, 1, 0), 6.0, 60.0))
    get_tree().quit()
