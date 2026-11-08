extends Node
## Headless test for the friendly AI squad (single-player).
## Run:  godot --headless --path . res://tests/squad_test.tscn

var main: Node
var results := []


func _ready() -> void:
    var keep_size: int = Game.squad_size
    var keep_news: bool = Game.show_news
    Game.squad_size = 2
    Game.show_news = false
    Game.free_play = true          # the ride tests use Operation 1's carrier and helicopter
    main = load("res://scenes/main.tscn").instantiate()
    add_child(main)
    await _frames(10)
    main.start_level(0)
    await _frames(10)
    var L = main.level
    var p = L.player
    p.invulnerable = true
    _check(L.squad.size() == 2, "2 squadmates deploy with the player (%d)" % L.squad.size())
    var near := true
    for m in L.squad:
        near = near and m.global_position.distance_to(p.global_position) < 8.0
    _check(near, "squad starts next to the player")
    _check(L.hud.team_label.text.begins_with("SQUAD"), "HUD shows the squad ('%s')" % L.hud.team_label.text.get_slice("\n", 0))
    for e in L.enemies + L.enemy_vehicles:
        e.set_physics_process(false)          # quiet map for the movement checks

    # Follow: walk the player north through the FOB gate; the squad keeps up.
    for k in 150:
        p.global_position += Vector3(0, 0, -0.1)
        await get_tree().physics_frame
    await _frames(90)
    var d := []
    for m in L.squad:
        d.append(snappedf(m.global_position.distance_to(p.global_position), 0.1))
    _check(d.all(func(x): return x < 7.5), "squad follows the player in formation %s" % str(d))

    # Catch-up: a squadmate far behind (and out of sight) rejoins.
    var m0 = L.squad[0]
    m0.global_position = p.global_position + Vector3(70, 0.5, 70)
    await _frames(30)
    _check(m0.global_position.distance_to(p.global_position) < 20.0, "a lost squadmate catches up (%.0fm)" % m0.global_position.distance_to(p.global_position))

    # Hold: T keeps them where they are while the player walks off.
    L.toggle_squad_order()
    _check(L.squad_hold and L.hud.team_label.text.contains("HOLDING") or L.squad_hold, "T orders the squad to hold")
    var held: Vector3 = L.squad[1].global_position
    p.global_position += Vector3(25, 0, 0)
    await _frames(120)
    _check(L.squad[1].global_position.distance_to(held) < 2.0, "squad holds position (moved %.1fm)" % L.squad[1].global_position.distance_to(held))
    L.toggle_squad_order()
    await _frames(150)
    _check(not L.squad_hold and L.squad[1].global_position.distance_to(p.global_position) < 8.0, "T again: squad comes back (%.1fm)" % L.squad[1].global_position.distance_to(p.global_position))

    # Combat: put the squad in view of a Tan soldier and let them shoot it.
    var e = null
    for x in L.enemies:
        if x.alive and x.s["speed"] > 0.0 and x.global_position.distance_to(L.safe_center) > L.safe_radius + 15.0:
            e = x
            break
    var spot := _open_spot(L, e.global_position)
    p.global_position = spot
    for m in L.squad:
        m.global_position = spot + Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5))
    var hp0: float = e.hp
    await _frames(240)
    _check(not e.alive or e.hp < hp0, "squad shoots a Tan soldier (hp %.0f -> %.0f)" % [hp0, e.hp if e.alive else 0.0])

    # The Tan Army fights back against the squad too.
    var m1 = L.squad[1]
    var e2 = null
    for x in L.enemies:
        if x.alive and x != e and x.global_position.distance_to(L.safe_center) > L.safe_radius + 15.0:
            e2 = x
            break
    m1.hold = true
    m1.hold_pos = _open_spot(L, e2.global_position, [8.0, 10.0, 12.0])   # clear line of sight to the Tan soldier
    m1.global_position = m1.hold_pos
    p.global_position = e2.global_position + Vector3(0, 0.5, 60)
    for other in L.squad:
        if other != m1:                                    # everyone else stays back with the player
            other.hold = true
            other.hold_pos = p.global_position + Vector3(2, 0, 0)
            other.global_position = other.hold_pos
    _check(L.nearest_ai_target(e2.global_position) == m1, "Tan soldiers target the nearest squadmate")
    var mh: float = m1.health
    e2.set_physics_process(true)
    e2.hp = 5000.0                                         # so the squadmate can't drop him first
    e2.hear(m1.hold_pos)                                   # turn toward him
    await _frames(360)
    _check(m1.health < mh or not m1.alive, "a Tan soldier's shots hurt a squadmate (%.0f -> %.0f)%s" % [mh, m1.health,
        "" if m1.health < mh else " [e2 alive=%s state=%d los=%s d=%.1f target=%s]" % [e2.alive, e2.state, e2.has_los, e2.global_position.distance_to(m1.global_position), e2._player()]])

    # Down and back: a melted squadmate is reinforced near the player.
    m1.take_damage(9999.0, Vector3.ZERO, m1.global_position, false)
    await _frames(2)
    _check(not m1.alive and L.hud.team_label.text.contains("DOWN"), "squadmate goes down (HUD: DOWN)")
    m1._respawn_t = 0.0
    await _frames(5)
    _check(m1.alive and m1.health >= m1.MAX_HP and m1.global_position.distance_to(p.global_position) < 10.0, "reinforcement arrives next to the player")

    # The player's rockets fly through squadmates; the squad doesn't finish missions for you.
    var R = load("res://scripts/rocket.gd")
    var r = R.new()
    var m2 = L.squad[0]
    m2.hold = true
    m2.hold_pos = p.global_position + Vector3(0, 0, -4)
    m2.global_position = m2.hold_pos
    var hp2: float = m2.health
    r.setup(p, L, p.global_position + Vector3(0, 1.2, 0), Vector3(0, 0, -1), 150.0, 4.0)
    L.add_child(r)
    await _frames(10)
    _check(m2.health >= hp2 - 60.0, "player rockets don't detonate on squadmates (hp %.0f -> %.0f)" % [hp2, m2.health])
    _check(not L.ai_targets().has(m2), "squadmates don't count as players for extraction")

    await _ride_tests(L, p)
    await _heli_tests(L, p)

    # Settings: zero squadmates means none deploy; co-op never deploys AI.
    Game.squad_size = 0
    main.start_level(1)
    await _frames(10)
    _check(main.level.squad.is_empty(), "squad size 0: no AI squadmates")
    Game.squad_size = keep_size
    Game.show_news = keep_news
    Game.free_play = false
    Game.save()
    main.show_main_menu()
    await _frames(5)
    var fails := results.filter(func(x): return not x[1])
    print("\n==== SQUAD TEST: %d checks, %d failed ====" % [results.size(), fails.size()])
    for x in results:
        print(("PASS " if x[1] else "FAIL ") + x[0])
    get_tree().quit(1 if fails.size() > 0 else 0)


## Squadmates climb into the player's vehicle, ride along, shoot from their
## seats, hop off when the player gets out, and bail out if it's destroyed.
func _ride_tests(L, p) -> void:
    var apc = null
    for v in L.vehicles:
        if v.kind == "apc" and v.alive:
            apc = v
    _check(apc != null, "Operation 1 has a troop carrier")
    if apc == null:
        return
    for m in L.squad:
        m.hold = false
    L.squad_hold = false
    p.global_position = apc.global_position - apc.global_transform.basis.x * 2.6 + Vector3(0, 0.3, 0)
    for i in L.squad.size():
        L.squad[i].global_position = p.global_position + Vector3(-3.0 - i * 1.5, 0.2, 2.0)
    await _frames(5)
    apc.enter(p)
    var aboard: Callable = func(): return L.squad.all(func(m): return m.ride == apc)
    var t0 := Time.get_ticks_msec()
    while not aboard.call() and Time.get_ticks_msec() - t0 < 6000:
        await get_tree().physics_frame
    _check(aboard.call(), "squad climbs into the troop carrier (%.1fs)" % ((Time.get_ticks_msec() - t0) / 1000.0))
    _check(apc.free_seats() == apc.passengers.size() - L.squad.size(), "carrier seats taken (%d free)" % apc.free_seats())
    await _frames(2)
    _check(L.hud.ord_label.text.contains("SQUAD ABOARD 2/2"), "HUD shows the squad aboard ('%s')" % L.hud.ord_label.text)
    _check(L.nearest_ai_target(apc.global_position) != L.squad[0], "Tan troops don't target riders directly")
    # Drive off: the riders stay in their seats.
    var start: Vector3 = apc.global_position
    apc.drive_input = Vector2(0, -1)
    await _frames(90)
    apc.drive_input = Vector2.ZERO
    var off := 0.0
    for m in L.squad:
        off = maxf(off, m.global_position.distance_to(apc.seat_transform(m.seat).origin))
    _check(apc.global_position.distance_to(start) > 5.0 and off < 0.6, "riders move with the carrier (drove %.0fm, worst seat offset %.2fm)" % [apc.global_position.distance_to(start), off])
    # Riders shoot at Tan soldiers they can see.
    var e = null
    for x in L.enemies:
        if is_instance_valid(x) and x.alive and x.s["speed"] > 0.0:
            e = x
            break
    if e != null:
        e.set_physics_process(false)
        e.global_position = apc.global_position + apc.global_transform.basis.x * 16.0 + Vector3(0, 0.2, 0)
        var hp0: float = e.hp
        await _frames(150)
        _check(not e.alive or e.hp < hp0, "riders shoot from their seats (Tan hp %.0f -> %.0f)" % [hp0, e.hp if e.alive else 0.0])
    # Get out: everyone hops off onto the ground.
    apc.exit_vehicle()
    await _frames(10)
    var off_ok: bool = L.squad.all(func(m): return m.ride == null and m.collision_layer == 2 and absf(m.global_position.y - apc.global_position.y) < 1.5)
    _check(off_ok and apc.free_seats() == apc.passengers.size(), "squad hops off when the player gets out")
    # Hold order: nobody boards.
    L.toggle_squad_order()
    apc.enter(p)
    await _frames(90)
    _check(L.squad.all(func(m): return m.ride == null), "squad on HOLD stays put when you drive off")
    L.toggle_squad_order()
    # A squadmate far away (out of sight) gets a seat straight away.
    var far = L.squad[0]
    far.global_position = apc.global_position + Vector3(0, 0.5, 120)
    p.vehicle.cam_yaw = apc.rotation.y
    t0 = Time.get_ticks_msec()
    while far.ride == null and Time.get_ticks_msec() - t0 < 4000:
        await get_tree().physics_frame
    _check(far.ride == apc, "a far-off squadmate catches the ride")
    await _frames(120)
    # Destroyed with riders aboard: they bail out and survive.
    p.invulnerable = true
    var riders: Array = L.squad.filter(func(m): return m.ride == apc)
    apc._destroy()          # (it is still inside the start safe zone, which blocks damage)
    await _frames(5)
    _check(not riders.is_empty() and riders.all(func(m): return m.ride == null and m.alive and m.health < m.MAX_HP), "riders bail out of a destroyed carrier, hurt but alive (%d)" % riders.size())
    _check(p.vehicle == null, "player bails out too")


## The helicopter: squad boards, it climbs, flies, won't let you jump out
## in mid-air, fires rockets, lands, and if shot down everyone falls clear.
func _heli_tests(L, p) -> void:
    var h = null
    for v in L.vehicles:
        if v.kind == "heli" and v.alive:
            h = v
    _check(h != null, "Operation 1 has a helicopter")
    if h == null:
        return
    for m in L.squad:
        if m.ride != null:
            m.dismount(false)
        m.hold = false
    L.squad_hold = false
    p.global_position = h.global_position - h.global_transform.basis.x * 2.6 + Vector3(0, 0.3, 0)
    for i in L.squad.size():
        L.squad[i].global_position = p.global_position + Vector3(-2.0 - i * 1.5, 0.2, 1.5)
    await _frames(5)
    h.enter(p)
    var t0 := Time.get_ticks_msec()
    while not L.squad.all(func(m): return m.ride == h) and Time.get_ticks_msec() - t0 < 6000:
        await get_tree().physics_frame
    _check(L.squad.all(func(m): return m.ride == h), "squad climbs into the helicopter")
    var ground_y: float = h.global_position.y
    h.fly_input = 1.0
    await _frames(180)
    h.fly_input = 0.0
    var alt: float = h.altitude()
    _check(alt > 15.0, "helicopter takes off (altitude %.1fm)" % alt)
    var off := 0.0
    for m in L.squad:
        off = maxf(off, m.global_position.distance_to(h.seat_transform(m.seat).origin))
    _check(off < 0.6 and L.squad[0].global_position.y > ground_y + 14.0, "door gunners ride up with it (worst seat offset %.2fm)" % off)
    # Can't bail out in mid-air with E.
    L.last_notice = ""
    await _press("interact")
    _check(p.vehicle == h and L.last_notice.begins_with("LAND FIRST"), "E in mid-air says 'land first' instead of dropping you out ('%s')" % L.last_notice)
    # Forward flight + rockets.
    var start: Vector3 = h.global_position
    h.drive_input = Vector2(0, -1)
    await _frames(120)
    h.drive_input = Vector2.ZERO
    var flat := Vector2(h.global_position.x - start.x, h.global_position.z - start.z).length()
    _check(flat > 15.0 and h.altitude() > 12.0, "flies forward at altitude (%.0fm, alt %.0fm)" % [flat, h.altitude()])
    var shots: int = p.shots_fired
    h.fire2_cd = 0.0
    h.fire_secondary()
    await _frames(3)
    _check(p.shots_fired > shots, "rocket pods fire")
    # Ceiling.
    h.fly_input = 1.0
    await _frames(420)
    h.fly_input = 0.0
    _check(h.altitude() < h.k["ceiling"] + 4.0, "altitude ceiling holds (%.0fm, ceiling %.0fm)" % [h.altitude(), h.k["ceiling"]])
    # Land and get out with E; the squad hops off on the ground.
    h.fly_input = -1.0
    t0 = Time.get_ticks_msec()
    while h.altitude() > 0.6 and Time.get_ticks_msec() - t0 < 12000:
        await get_tree().physics_frame
    await _frames(20)
    h.fly_input = 0.0
    _check(h.altitude() < 1.0, "helicopter lands (altitude %.2fm)" % h.altitude())
    await _press("interact")
    await _frames(8)
    _check(p.vehicle == null, "E after landing gets you out")
    _check(L.squad.all(func(m): return m.ride == null and absf(m.global_position.y - h.global_position.y) < 2.0), "squad hops off onto the ground")
    # Shot down with everyone aboard: they fall clear and survive.
    h.enter(p)
    t0 = Time.get_ticks_msec()
    while not L.squad.all(func(m): return m.ride == h) and Time.get_ticks_msec() - t0 < 6000:
        await get_tree().physics_frame
    h.fly_input = 1.0
    await _frames(90)
    h.fly_input = 0.0
    p.invulnerable = true
    h._destroy()
    await _frames(240)
    _check(not h.alive and p.vehicle == null and p.is_on_floor(), "shot down: the pilot falls clear")
    _check(h.is_on_floor() or h.altitude() < 1.0, "the wreck falls to the ground (alt %.1fm)" % h.altitude())
    var landed: Callable = func(): return L.squad.all(func(m): return m.ride == null and m.alive and m.is_on_floor())
    var tl := Time.get_ticks_msec()
    while not landed.call() and Time.get_ticks_msec() - tl < 6000:
        await get_tree().physics_frame
    _check(landed.call(), "shot down: door gunners land alive %s" % str(L.squad.map(func(m): return [m.ride == null, m.alive, m.is_on_floor(), m.global_position.snapped(Vector3(0.1, 0.1, 0.1)), m.velocity.y])))


func _press(action: String) -> void:
    for down in [true, false]:
        var ev := InputEventAction.new()
        ev.action = action
        ev.pressed = down
        Input.parse_input_event(ev)
        await _frames(2)


func _open_spot(L, target: Vector3, dists := [14.0, 18.0, 10.0, 22.0]) -> Vector3:
    for dist in dists:
        for k in 12:
            var a := k * TAU / 12.0
            var pos := target + Vector3(cos(a) * dist, 0.5, sin(a) * dist)
            if L.in_safe_zone(pos):
                continue
            var ray := Fx_ray(L, pos + Vector3(0, 1.4, 0), target + Vector3(0, 1.2, 0))
            if ray:
                return pos
    return target + Vector3(14, 0.5, 0)


func Fx_ray(L, a: Vector3, b: Vector3) -> bool:
    var q := PhysicsRayQueryParameters3D.create(a, b, 1)
    return L.get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func _frames(n: int) -> void:
    for i in n:
        await get_tree().physics_frame


func _check(ok: bool, label: String) -> void:
    results.append([label, ok])
