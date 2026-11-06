extends Node
## Headless smoke test: plays through every operation programmatically.
## Run:  godot --headless --path . res://tests/smoke_test.tscn

var main: Node
var results := []
var finished_result = null


func _ready() -> void:
    main = load("res://scenes/main.tscn").instantiate()
    add_child(main)
    await _frames(30)
    _audio_checks()
    var PS = load("res://scripts/plastic_soldier.gd")
    _check(PS.available(), "plastic soldier model loads")
    main.show_campaign()
    await _frames(5)
    main.show_settings()
    await _frames(5)
    main.show_controls()
    await _frames(5)
    for i in 3:
        await _play_level(i)
    # pause / restart path
    main.start_level(0)
    await _frames(20)
    main.level.toggle_pause()
    await _frames(5)
    _check(get_tree().paused, "pause works")
    main.level.toggle_pause()
    _check(not get_tree().paused, "unpause works")
    main.level.request_restart.emit()
    await _frames(20)
    _check(main.level != null and main.level.player.alive, "restart works")
    # death path
    main.level.player.take_damage(9999.0, Vector3.ZERO, Vector3.ZERO)
    await _wait_finish()
    _check(finished_result == false, "death -> mission failed")
    main.show_main_menu()
    await _frames(10)
    var fails := results.filter(func(r): return not r[1])
    print("\n==== SMOKE TEST: %d checks, %d failed ====" % [results.size(), fails.size()])
    for r in results:
        print(("PASS " if r[1] else "FAIL ") + r[0])
    get_tree().quit(1 if fails.size() > 0 else 0)


func _frames(n: int) -> void:
    for i in n:
        await get_tree().physics_frame


func _check(cond: bool, label: String) -> void:
    results.append([label, cond])


func _wait_finish() -> void:
    finished_result = null
    var lvl = main.level
    lvl.finished.connect(func(s, _st): finished_result = s, CONNECT_ONE_SHOT)
    for i in 400:
        await get_tree().physics_frame
        if finished_result != null:
            return


func _play_level(i: int) -> void:
    main.start_level(i)
    await _frames(10)
    var L = main.level
    var p = L.player
    _check(Game._ambience.playing, "L%d ambience playing" % i)
    _check(L.enemies[0].model.get("rig") != null, "L%d enemies use the plastic model" % i)
    _check(L.enemies.size() > 10, "L%d spawned %d enemies" % [i, L.enemies.size()])
    _check(p.is_on_floor() or p.global_position.y < 2.0, "L%d player grounded at %s" % [i, p.global_position])
    # Let the AI run for a few seconds with the player invulnerable.
    p.invulnerable = true
    await _frames(240)
    # Fire every owned weapon.
    for w in p.owned.keys():
        p._equip(w)
        p.fire_cd = 0.0
        p._fire(p.cur())
        await _frames(3)
    p._throw_grenade()
    p.pitch = -0.6
    p._call_drone()
    await _frames(240)
    _check(p.shots_fired > 0, "L%d weapons fired (%d shots)" % [i, p.shots_fired])
    # Teleport near an enemy and let it engage.
    var e = null
    for x in L.enemies:
        if x.alive and x.s["speed"] > 0.0:
            e = x
            break
    if e:
        p.global_position = e.global_position + Vector3(8, 0.5, 0)
        await _frames(180)
        _check(e.state != 0 or not e.alive, "L%d enemy engaged player (state %d)" % [i, e.state])
    # Complete objectives programmatically.
    var guard := 0
    while L.obj_index < L.objectives.size() and guard < 10:
        guard += 1
        var o: Dictionary = L.objectives[L.obj_index]
        var before: int = L.obj_index
        match o["type"]:
            "destroy":
                for t in L.targets_by_tag[o["tag"]]:
                    if t.alive:
                        t.take_damage(99999.0, Vector3.ZERO, t.global_position, true)
            "kill_hvt":
                for h in L.hvts:
                    if h.alive:
                        h.take_damage(99999.0, Vector3.ZERO, h.global_position, false)
            "kill_all":
                for x in L.enemies:
                    if is_instance_valid(x) and x.alive:
                        x.take_damage(99999.0, Vector3.ZERO, x.global_position + Vector3(0, 1.7, 0), false)
            "extract":
                p.global_position = o["pos"] + Vector3(0, 1.0, 0)
        await _frames(20)
        _check(L.obj_index > before, "L%d objective '%s' completed" % [i, o["type"]])
    _check(L.get_objective_text() != "", "L%d objective text" % i)
    await _wait_finish()
    _check(finished_result == true, "L%d mission accomplished -> debrief" % i)
    await _frames(5)


func _audio_checks() -> void:
    var from_files := 0
    for k in Game.SFX_FILES:
        if Game.sfx.has(k) and Game.sfx[k] is Array:
            from_files += 1
    _check(from_files == Game.SFX_FILES.size(), "recorded SFX loaded (%d/%d)" % [from_files, Game.SFX_FILES.size()])
    _check(Game._music.playing, "music playing (%s)" % Game._music_path.get_file())
