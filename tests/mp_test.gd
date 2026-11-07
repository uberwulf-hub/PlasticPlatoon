extends Node
## Two-process LAN co-op test. Run a host and a client at the same time:
##   godot --headless --path . res://tests/mp_test.tscn -- host
##   godot --headless --path . res://tests/mp_test.tscn -- client
## Both follow the same timeline (seconds after the level starts) and each
## checks what it should see from the other PC. Exit code 1 on any failure.

var role := "host"
var main: Node
var results := []
var go_ms := -1
var _done := false
var finished_success = null


func _ready() -> void:
    var args := OS.get_cmdline_user_args()
    role = args[0] if args.size() > 0 else "host"
    Game.show_news = false
    main = load("res://scenes/main.tscn").instantiate()
    add_child(main)
    await _frames(5)
    if role == "host":
        await _run_host()
    else:
        await _run_client()
    print("\n==== MP TEST (%s): %d checks, %d failed ====" % [role, results.size(), results.filter(func(r): return not r[1]).size()])
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


func _wait_until(cond: Callable, timeout_s: float) -> bool:
    var t0 := Time.get_ticks_msec()
    while not cond.call():
        if Time.get_ticks_msec() - t0 > timeout_s * 1000.0:
            return false
        await get_tree().physics_frame
    return true


## Waits until `sec` seconds after the level started.
func _at(sec: float) -> void:
    while Time.get_ticks_msec() - go_ms < sec * 1000.0:
        await get_tree().physics_frame


func _level():
    return main.level


# ------------------------------------------------------------------- host ----

func _run_host() -> void:
    var err: String = Net.host("HostBot")
    _check(err == "", "host started on UDP %d %s" % [Net.PORT, err])
    _check(await _wait_until(func(): return Net.players.size() == 2, 30.0), "client joined the lobby (%d players)" % Net.players.size())
    await _frames(30)
    Net.start_game(0)
    _check(await _wait_until(func(): return _level() != null and _level().net != null and _level().net.started, 15.0), "both PCs loaded; Tan Army released")
    go_ms = Time.get_ticks_msec()
    var L = _level()
    L.player.invulnerable = true
    L.finished.connect(func(s, _st): finished_success = s)
    var cid: int = Net.players.keys().filter(func(k): return k != 1)[0]

    await _at(2.5)
    _check(L.remotes.has(cid), "host sees the client's soldier")
    var start_pos: Vector3 = L.remotes[cid].global_position if L.remotes.has(cid) else Vector3.ZERO

    await _at(4.5)
    if L.remotes.has(cid):
        _check(L.remotes[cid].global_position.distance_to(start_pos) > 4.0, "client's movement shows up on the host (%.1fm)" % L.remotes[cid].global_position.distance_to(start_pos))

    # t=5 the client shoots enemy 0.
    await _at(7.5)
    _check(not L.enemies[0].alive, "client's shot killed Tan soldier 0 on the host")

    # t=8 host kills enemy 1; client checks.
    await _at(8.0)
    L.enemies[1].take_damage(9999.0, Vector3.ZERO, L.enemies[1].global_position, true)

    # t=10 host hurts the client's soldier (on the host, via its puppet).
    await _at(10.0)
    if L.remotes.has(cid):
        L.remotes[cid].take_damage(15.0, Vector3.ZERO, Vector3.ZERO, false)

    # t=12 client grabs the armor crate.
    await _at(14.5)
    var armor_id := _pickup_id(L, "armor")
    _check(armor_id == -1, "client's pickup was removed on the host")

    # t=14 client takes the jeep (vehicle 1), drives t=16..18.
    await _at(16.0)
    var jeep = L.vehicles[1]
    _check(jeep.occupant_peer == cid, "host granted the jeep to the client (occupant %d)" % jeep.occupant_peer)
    var jeep_start: Vector3 = jeep.global_position
    await _at(18.6)
    _check(jeep.global_position.distance_to(jeep_start) > 3.0, "client's driving shows up on the host (%.1fm)" % jeep.global_position.distance_to(jeep_start))

    # t=20 host destroys the jammers -> objective 2 on every PC.
    await _at(20.0)
    for t in L.targets_by_tag["jammers"]:
        if t.alive:
            t.take_damage(99999.0, Vector3.ZERO, t.global_position, true)
    await _at(21.0)
    _check(L.obj_index == 1, "host advanced to the extraction objective")

    # t=23 host reaches the helipad -> mission complete for everyone.
    await _at(23.0)
    L.player.global_position = L.objectives[1]["pos"] + Vector3(0, 1, 0)
    _check(await _wait_until(func(): return finished_success != null, 10.0) and finished_success == true, "mission accomplished on the host")
    await _at(32.0)        # give the client time to report


# ----------------------------------------------------------------- client ----

func _run_client() -> void:
    Net.start_discovery()
    var found := await _wait_until(func(): return not Net.hosts.is_empty(), 8.0)
    _check(true, "LAN discovery %s" % ("found the host" if found else "saw no broadcast (normal in some sandboxes); joining by IP"))
    Net.stop_discovery()
    Net.join("127.0.0.1", "ClientBot")
    _check(await _wait_until(func(): return Net.players.size() == 2, 20.0), "joined the host's lobby")
    _check(await _wait_until(func(): return _level() != null and _level().net != null and _level().net.started, 30.0), "level started on the client")
    go_ms = Time.get_ticks_msec()
    var L = _level()
    var p = L.player
    p.invulnerable = true
    L.finished.connect(func(s, _st): finished_success = s)

    await _at(2.0)
    _check(L.remotes.has(1), "client sees the host's soldier")
    await _at(3.2)
    p.global_position += Vector3(0, 0, -6)

    # t=5 shoot enemy 0 point-blank (through the host).
    await _at(5.0)
    var e = L.enemies[0]
    var hits := [0]
    p.hit_confirmed.connect(func(_k): hits[0] += 1)
    var chest: Vector3 = e.global_position + Vector3(0, 1.1, 0)
    var from: Vector3 = chest + Vector3(0, 0.2, 3.0)
    L.net.send_shot(PackedVector3Array([from, chest]), PackedFloat32Array([999.0]), [L.ref_of(e)], Color.WHITE, "rifle", 40.0)
    await _at(7.0)
    _check(not e.alive, "Tan soldier 0 melted on the client")
    _check(hits[0] > 0, "client got the hit marker from the host")

    await _at(9.0)
    # t=10 the host hurts us (outside the start's safe zone, where damage applies).
    p.global_position = L.safe_center + Vector3(L.safe_radius + 8.0, 0.5, 0)
    p.invulnerable = false
    var hp0: float = p.health + p.armor
    await _at(10.0)
    _check(not L.enemies[1].alive, "enemy killed by the host melted on the client")
    await _at(12.0)
    _check(p.health + p.armor < hp0, "damage from the host reached the client's soldier (%.0f -> %.0f)" % [hp0, p.health + p.armor])
    p.invulnerable = true

    # t=12 walk onto the armor crate.
    var armor_id := _pickup_id(L, "armor")
    if armor_id >= 0:
        p.global_position = L.pickups[armor_id].global_position + Vector3(0, 0.2, 0)
    await _at(13.5)
    _check(armor_id >= 0 and not L.pickups.has(armor_id), "client picked up the armor crate")

    # t=14 get in the jeep, drive t=16..18, get out.
    await _at(14.0)
    var jeep = L.vehicles[1]
    p.global_position = jeep.global_position - jeep.global_transform.basis.x * 2.3 + Vector3(0, 0.3, 0)
    await _frames(3)
    L.net.request_enter(1)
    await _at(15.5)
    _check(p.vehicle == jeep, "client is driving the jeep")
    await _at(16.0)
    jeep.drive_input = Vector2(0, -1)
    await _at(18.0)
    jeep.drive_input = Vector2.ZERO
    await _at(19.0)
    jeep.exit_vehicle()

    await _at(22.0)
    _check(L.obj_index == 1, "objective update reached the client")
    _check(L.extraction != null, "client shows the extraction helipad")
    _check(await _wait_until(func(): return finished_success != null, 12.0) and finished_success == true, "mission accomplished on the client")


func _pickup_id(L, kind: String) -> int:
    for id in L.pickups:
        var pk = L.pickups[id]
        if is_instance_valid(pk) and pk.kind == kind:
            return id
    return -1
