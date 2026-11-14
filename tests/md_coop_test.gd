extends Node
## Two-process MELTDOWN co-op test (LAN). Run both at once:
##   godot --headless --path . res://tests/md_coop_test.tscn -- host
##   godot --headless --path . res://tests/md_coop_test.tscn -- client
## Uses the same sync as online play (only the connection differs).

var role := "host"
var main: Node
var results := []


func _ready() -> void:
    var args := OS.get_cmdline_user_args()
    role = args[0] if args.size() > 0 else "host"
    Game.show_news = false
    Game.squad_size = 0
    main = load("res://scenes/main.tscn").instantiate()
    add_child(main)
    await _frames(5)
    if role == "host":
        await _host()
    else:
        await _client()
    print("\n==== MELTDOWN CO-OP TEST (%s): %d checks, %d failed ====" % [role, results.size(), results.filter(func(r): return not r[1]).size()])
    for r in results:
        print("%s %s %s" % ["PASS" if r[1] else "FAIL", role, r[0]])
    Net.leave()
    await _frames(5)
    get_tree().quit(1 if results.any(func(r): return not r[1]) else 0)


func _check(ok: bool, label: String) -> void:
    results.append([label, ok])


func _frames(n: int) -> void:
    for i in n:
        await get_tree().physics_frame


func _wait(cond: Callable, s: float) -> bool:
    var t0 := Time.get_ticks_msec()
    while not cond.call():
        if Time.get_ticks_msec() - t0 > s * 1000.0:
            return false
        await get_tree().physics_frame
    return true


func _M():
    return main.level.mode if main.level != null else null


func _host() -> void:
    _check(Net.host("HostBot") == "", "host started")
    _check(await _wait(func(): return Net.players.size() == 2, 30.0), "client joined")
    await _frames(20)
    Net.start_game(100)            # MELTDOWN: The Basement
    _check(await _wait(func(): return _M() != null and main.level.net != null and main.level.net.started, 20.0), "MELTDOWN started for both")
    var L = main.level
    var M = _M()
    L.player.invulnerable = true
    M.coins = 99999                # plenty for the client's shopping
    M.start_wave_now()
    _check(await _wait(func(): return M.melties.size() >= 2, 20.0), "host: wave 1 Melties out (%d)" % M.melties.size())
    # Only the client shoots, buys and repairs: count what reaches the host.
    _check(await _wait(func(): return M.killed >= 1, 40.0), "client's shot killed a Melty on the host (%d)" % M.killed)
    _check(await _wait(func(): return M.teammate_buys >= 1, 40.0), "client's shotgun came out of the squad's coins (%d buys)" % M.teammate_buys)
    _check(await _wait(func(): return M.teammate_planks >= 1, 40.0), "client nailed a plank back up on the host (%d)" % M.teammate_planks)
    var doors0: int = M.doors.size()
    _check(await _wait(func(): return M.doors.size() < doors0, 40.0), "client opened a door for everyone")
    await _frames(90)


func _client() -> void:
    Net.join("127.0.0.1", "ClientBot")
    _check(await _wait(func(): return Net.players.size() == 2, 20.0), "joined the host")
    _check(await _wait(func(): return _M() != null and main.level.net != null and main.level.net.started, 30.0), "MELTDOWN started on the client")
    var L = main.level
    var M = _M()
    L.player.invulnerable = true
    _check(await _wait(func(): return M.melties.size() >= 2, 25.0), "client sees the host's Melties (%d)" % M.melties.size())
    _check(await _wait(func(): return M.wave >= 1, 10.0), "wave number reached the client (%d)" % M.wave)
    # Shoot one through the host (what the shooter sees is what it hits).
    var m = M.melties.values().filter(func(x): return is_instance_valid(x) and x.alive)[0]
    await _frames(10)
    var chest: Vector3 = m.global_position + Vector3(0, 1.0, 0)
    var muzzle: Vector3 = L.player.global_position + Vector3(0, 1.4, 0)     # fired from our own soldier
    L.net.send_shot(PackedVector3Array([muzzle, chest]), PackedFloat32Array([99999.0]), [L.ref_of(m)], Color.WHITE, "rifle", 40.0)
    _check(await _wait(func(): return not m.alive, 10.0), "the Melty melted on the client too")
    _check(await _wait(func(): return M.coins > 5000, 10.0), "squad coins reach the client (%d)" % M.coins)
    # Buy the shotgun off the wall.
    var st = M.stations.filter(func(s): return s["kind"] == "weapon" and s["weapon"] == "shotgun")[0]
    _check(M.use(st) and L.player.owned.has("shotgun"), "client bought the shotgun")
    # Nail a plank back on a window that's missing some.
    var b = M.barricades[0]
    _check(await _wait(func(): return b.planks < 5, 30.0), "client sees a window's boards torn off (%d)" % b.planks)
    var before: int = b.planks
    M.level.net.md_rebuild(0)
    _check(await _wait(func(): return b.planks > before or b.planks == 5, 10.0), "client's plank shows on the client")
    # Open the first door.
    var doors0: int = M.doors.size()
    M.use(M.doors[0])
    _check(await _wait(func(): return M.doors.size() < doors0, 10.0), "the door opened on the client")
    await _frames(30)
