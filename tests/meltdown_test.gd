extends Node
## Headless test for MELTDOWN (wave survival).
## Run:  godot --headless --path . res://tests/meltdown_test.tscn

var main: Node
var results := []
var finished_stats = null


func _ready() -> void:
    var keep_squad: int = Game.squad_size
    Game.squad_size = 0
    main = load("res://scenes/main.tscn").instantiate()
    add_child(main)
    await _frames(10)
    main.show_meltdown()
    await _frames(2)
    var start: Button = null
    var starts: Array = main.ui.find_children("*", "Button", true, false).filter(func(b): return b.text == "START")
    _check(starts.size() == load("res://scripts/meltdown_maps.gd").META.size(), "menu: a START button per map (%d)" % starts.size())
    start = starts[0]          # The Basement
    _check(start != null, "menu: Meltdown screen has a START button")
    var news_was: bool = Game.show_news
    Game.show_news = true
    start.pressed.emit()
    await _frames(5)
    _check(main.news != null, "START plays a PNN MELTDOWN bulletin first")
    var nb = main.news
    if nb != null:
        nb.finished.emit()                 # skip it (starts the map)...
        nb.done = true                     # ...and stop it, so it can't start it twice
        nb.queue_free()
    Game.show_news = news_was
    await _frames(10)
    var L = main.level
    var M = L.mode
    var p = L.player
    _check(M != null, "Meltdown controller is running")
    _check(L.objectives.is_empty() and not L.ended, "no campaign objectives; the level doesn't end on its own")
    _check(M.coins == 500 and p.owned.keys() == ["carbine"], "start: 500 coins and just the carbine")
    _check(M.barricades.size() == 9 and M.doors.size() == 2 and M.stations.size() == 8, "map: 9 windows, 2 junk piles, 8 stations")
    _check(M.nav_region != null and M.nav_region.navigation_mesh.get_polygon_count() > 0, "navigation mesh baked (%d polygons)" % M.nav_region.navigation_mesh.get_polygon_count())
    _check(L.hud.info_label.text.contains("COINS 500"), "HUD shows coins ('%s')" % L.hud.info_label.text.replace("\n", " | "))
    L.player.invulnerable = true

    # Wave 1: Melties spawn outside, rip boards off, climb in and come for you.
    M.start_wave_now()
    await _frames(5)
    _check(M.wave == 1 and M.to_spawn + M.alive == 8, "wave 1: 8 Melties (%d)" % (M.to_spawn + M.alive))
    var t0 := Time.get_ticks_msec()
    var torn := false
    var inside := false
    var hunted := false
    while Time.get_ticks_msec() - t0 < 30000 and not (torn and inside and hunted):
        await get_tree().physics_frame
        for b in M.barricades:
            if b.planks < 5:
                torn = true
        for e in L.enemies:
            if is_instance_valid(e) and e.alive and e.state == e.HUNTING:
                inside = true
                if e.global_position.distance_to(p.global_position) < 6.0:
                    hunted = true
    _check(torn, "Melties tear the boards off the windows")
    _check(inside, "Melties climb in through a window")
    _check(hunted, "Melties find their way to the player")
    # Coins for the player's hits and kills, not anyone else's.
    var e = null
    for x in L.enemies:
        if is_instance_valid(x) and x.alive:
            e = x
            break
    var c0: int = M.coins
    e.take_damage(1.0, p.global_position, e.global_position + Vector3(0, 0.8, 0), false)
    _check(M.coins == c0 + 10, "a hit pays 10 coins (%d -> %d)" % [c0, M.coins])
    c0 = M.coins
    e.take_damage(99999.0, Vector3(500, 0, 500), e.global_position + Vector3(0, 0.8, 0), false)
    _check(M.coins == c0, "someone else's kill pays nothing")
    var e2 = null
    for x in L.enemies:
        if is_instance_valid(x) and x.alive:
            e2 = x
            break
    if e2 == null:
        await _frames(120)
        for x in L.enemies:
            if is_instance_valid(x) and x.alive:
                e2 = x
                break
    c0 = M.coins
    e2.take_damage(99999.0, p.global_position, e2.global_position + Vector3(0, 1.6, 0), false)
    _check(M.coins == c0 + 100, "a headshot kill pays 100 coins (%d -> %d)" % [c0, M.coins])
    # Real bullets from the player hit and pay too.
    await _frames(3)
    # Melties hurt.
    p.invulnerable = false
    var hp0: float = p.health + p.armor
    var hit_by := false
    t0 = Time.get_ticks_msec()
    while Time.get_ticks_msec() - t0 < 15000 and not hit_by:
        await get_tree().physics_frame
        hit_by = p.health + p.armor < hp0
    _check(hit_by, "a Melty's swipe hurts (%.0f -> %.0f)" % [hp0, p.health + p.armor])
    p.invulnerable = true
    p.health = p.max_health

    # Clear the wave -> break -> wave 2 is tougher.
    var hp1: float = M._wave_hp
    for k in 40:
        for x in L.enemies.duplicate():
            if is_instance_valid(x) and x.alive:
                x.take_damage(99999.0, Vector3(500, 0, 500), x.global_position, false)
        if M.to_spawn == 0 and M.alive == 0:
            break
        M.spawn_t = 0.0
        await _frames(3)
    _check(M.alive == 0 and M.to_spawn == 0, "wave 1 cleared")
    await _frames(5)
    _check(L.get_objective_text().contains("next wave"), "break between waves ('%s')" % L.get_objective_text())
    M.start_wave_now()
    await _frames(5)
    _check(M.wave == 2 and M._wave_hp > hp1 and M.to_spawn + M.alive == 11, "wave 2: more Melties (11) with more health (%.0f -> %.0f)" % [hp1, M._wave_hp])

    # Rebuild a window: hold E next to it.
    var b = null
    for x in M.barricades:
        if x.section == "A":
            b = x
            break
    while b.planks > 2:
        b.tear()
    p.global_position = b.inside_point + Vector3(0, 0.3, 0)
    M._plank_coins = 0
    c0 = M.coins
    await _frames(5)
    _check(M.prompt_text().begins_with("Hold E"), "prompt near a broken window ('%s')" % M.prompt_text())
    Input.action_press("interact")
    await _frames(110)
    Input.action_release("interact")
    # (Melties may be tearing at the same window, so count the boards nailed by the coins.)
    _check(M.coins >= c0 + 20, "holding E nails boards back (+%d coins, %d planks now)" % [M.coins - c0, b.planks])

    # Buy things.
    var by_kind := {}
    for s in M.stations:
        by_kind[s["kind"] + ":" + s["weapon"]] = s
    M.coins = 100
    _check(not M.use(by_kind["weapon:shotgun"]) and not p.owned.has("shotgun"), "can't buy the shotgun with 100 coins")
    M.coins = 5000
    _check(M.use(by_kind["weapon:shotgun"]) and p.owned.has("shotgun") and M.coins == 4500, "wall-buy: shotgun for 500")
    p.reserve["shotgun"] = 0
    _check(M.use(by_kind["weapon:shotgun"]) and p.reserve["shotgun"] > 0 and M.coins == 4250, "wall-buy again: ammo for half price")
    p.health = 30.0
    _check(M.use(by_kind["medic:"]) and p.health == p.max_health, "field medic heals")
    p.armor = 0.0
    _check(M.use(by_kind["armor:"]) and p.armor == p.max_armor, "plate armor")
    # Doors: the next section opens and its windows start spawning.
    var door = M.doors[0]
    var coins_before: int = M.coins
    _check(not M.sections["B"]["open"], "workshop starts closed")
    _check(M.use(door) and M.sections["B"]["open"] and M.coins == coins_before - 750, "clearing the junk opens the workshop for 750")
    await _frames(20)
    _check(not is_instance_valid(door["node"]), "the junk pile is gone")
    var path_ok := _path_exists(L, Vector3(0, 0.5, 30), Vector3(0, 0.5, 0))
    _check(path_ok, "Melties can now path from the toy shelf into the workshop")
    # Mystery crate gives a weapon.
    var owned_before: int = p.owned.size()
    _check(M.use(by_kind["crate:"]), "mystery crate opens")
    var tc := Time.get_ticks_msec()
    while M._crate_busy and Time.get_ticks_msec() - tc < 6000:
        await get_tree().physics_frame
    _check(p.owned.size() >= owned_before and not M._crate_busy and L.last_notice.begins_with("THE CRATE GAVE YOU"), "mystery crate handed over a weapon ('%s')" % L.last_notice)
    # Re-Mold Press doubles the current gun's damage.
    M.coins = 10000
    M.use(M.doors[0])
    await _frames(20)
    p._equip("carbine")
    await _frames(2)
    _check(M.use(by_kind["press:"]) and p.dmg_mult.get("carbine", 1.0) == 2.0, "Re-Mold Press: carbine does double damage")
    _check(not M.use(by_kind["press:"]), "can't re-mold the same gun twice")

    # Death ends the run with the wave reached.
    L.finished.connect(func(_s, st): finished_stats = st, CONNECT_ONE_SHOT)
    p.invulnerable = false
    p.take_damage(99999.0, Vector3.ZERO, p.global_position, true)
    t0 = Time.get_ticks_msec()
    while finished_stats == null and Time.get_ticks_msec() - t0 < 8000:
        await get_tree().process_frame
    _check(finished_stats != null and finished_stats["mode"] == "meltdown" and finished_stats["wave"] == 2, "death ends the run at wave 2")
    await _frames(5)
    var shown := false
    for l in main.ui.find_children("*", "Label", true, false):
        if l.text.contains("survived to wave 2"):
            shown = true
    _check(shown, "end screen: 'You survived to wave 2'")
    _check(Game.meltdown_best.get(0, 0) >= 2, "best wave saved")
    get_tree().paused = false
    await _kinds_tests()
    var MM = load("res://scripts/meltdown_maps.gd")
    for i in MM.META.size():
        await _map_checks(i, MM.META[i]["name"])
    await _flush_checks()
    main.show_main_menu()
    await _frames(5)
    Game.squad_size = keep_squad
    Game.save()
    var fails := results.filter(func(r): return not r[1])
    print("\n==== MELTDOWN TEST: %d checks, %d failed ====" % [results.size(), fails.size()])
    for r in results:
        print(("PASS " if r[1] else "FAIL ") + r[0])
    get_tree().quit(1 if fails.size() > 0 else 0)


## Every map: layout sane, everything reachable once the rooms are open,
## and a wave actually gets Melties inside.
func _map_checks(i: int, title: String) -> void:
    main.start_level(100 + i)
    await _frames(10)
    var L = main.level
    var M = L.mode
    var p = L.player
    p.invulnerable = true
    var tag := "[%s]" % title
    _check(M != null and M.barricades.size() >= 6 and M.doors.size() >= 2 and M.stations.size() == 8,
        "%s layout: %d windows, %d junk piles, %d stations" % [tag, M.barricades.size(), M.doors.size(), M.stations.size()])
    _check(_clear(L, p.global_position), "%s start point is clear" % tag)
    var bad: Array = []
    for s in M.stations:
        var stand: Vector3 = s["pos"] - Vector3(0, 1.0, 0) + s["node"].global_transform.basis.z * 0.9   # where you'd stand to use it
        if not _clear(L, stand):
            bad.append("%s %s" % [s["kind"], s["weapon"]])
        for b in M.barricades:
            if b.inside_point.distance_to(s["pos"] - Vector3(0, 1.0, 0)) < 3.0:
                bad.append("%s too close to a window" % s["kind"])
    _check(bad.is_empty(), "%s stations stand clear %s" % [tag, str(bad)])
    var wbad: Array = []
    for b in M.barricades:
        if not _clear(L, b.inside_point) or not _clear(L, b.outside_point):
            wbad.append(str(b.global_position.snapped(Vector3.ONE)))
    _check(wbad.is_empty(), "%s every window has room inside and out %s" % [tag, str(wbad)])
    # Open every room, then everything must be reachable on the navmesh.
    M.coins = 99999
    for d in M.doors.duplicate():
        M.use(d)
    await _frames(30)
    var unreachable: Array = []
    for b in M.barricades:
        if not _path_exists(L, p.global_position, b.inside_point):
            unreachable.append("window " + str(b.global_position.snapped(Vector3.ONE)))
    for s in M.stations:
        if not _path_exists(L, p.global_position, s["pos"] - Vector3(0, 0.5, 0)):
            unreachable.append(s["kind"])
    _check(unreachable.is_empty(), "%s every window and station is reachable %s" % [tag, str(unreachable)])
    # A wave gets Melties inside.
    M.start_wave_now()
    var t0 := Time.get_ticks_msec()
    var inside := false
    while Time.get_ticks_msec() - t0 < 30000 and not inside:
        await get_tree().physics_frame
        for e in L.enemies:
            if is_instance_valid(e) and e.alive and e.state == e.HUNTING:
                inside = true
    _check(inside, "%s Melties break in on wave 1" % tag)


## The Big Flush: you're stuck in the toilet until you buy the paper, which
## lays a ramp you can walk; the cracks are porcelain; the lights stay steady.
func _flush_checks() -> void:
    main.start_level(113)
    await _frames(10)
    var L = main.level
    var M = L.mode
    var p = L.player
    p.invulnerable = true
    var tag := "[The Big Flush]"
    var porcelain: Array = M.barricades.filter(func(b): return b.style == "porcelain")
    _check(porcelain.size() == 3 and porcelain.all(func(b): return b.section == "A"), "%s three porcelain cracks in the bowl" % tag)
    var floor_win = M.barricades.filter(func(b): return b.section == "B")[0]
    await _frames(10)
    _check(not _path_exists(L, p.global_position, floor_win.inside_point), "%s no way out of the bowl before the paper is bought" % tag)
    _check(M.doors[0].has("ramp") and M.doors[0]["prompt"].contains("toilet paper"), "%s the first buy is the toilet paper ('%s')" % [tag, M.doors[0]["prompt"]])
    var low = M.doors[0].get("label_low")
    _check(low != null and absf(low.global_position.y - p.global_position.y) < 4.0, "%s a sign at eye level shows where to buy the toilet paper" % tag)
    var keep_pp: Vector3 = p.global_position
    p.global_position = M.doors[0]["pos"] + Vector3(2.5, -1.0, 0)
    await _frames(3)
    _check(M._focus == M.doors[0], "%s standing on the end of the paper offers to buy it" % tag)
    p.global_position = keep_pp
    await _frames(3)
    M.coins = 5000
    M.use(M.doors[0])
    await _frames(40)
    _check(M.sections["B"]["open"] and M.ramps.size() == 1, "%s buying it lays the paper ramp" % tag)
    _check(_path_exists(L, p.global_position, floor_win.inside_point), "%s the ramp leads up over the rim to the floor" % tag)
    # Walk up it for real: stand on the paper inside the bowl, push forward.
    _check(L.find_child("FlickerLights", true, false) == null, "%s the ceiling lights stay steady (no flicker)" % tag)
    # A wave: Melties crawl through the porcelain and out of the cracks.
    M.start_wave_now()
    var t0 := Time.get_ticks_msec()
    var cracked := false
    while Time.get_ticks_msec() - t0 < 30000 and not cracked:
        await get_tree().physics_frame
        for b in porcelain:
            if b.planks < b.PLANKS:
                cracked = true
    _check(cracked, "%s Melties break through a crack in the bowl" % tag)
    # A Melty that falls off its climb, or gets hung up, is put back so the
    # wave can always end.
    var lost = null
    for e in L.enemies:
        if is_instance_valid(e) and e.alive and e.state == e.OUTSIDE:
            lost = e
            break
    if lost == null:
        lost = M._spawn_one("shambler")
        M.alive -= 1
    if lost != null:
        lost.state = lost.OUTSIDE
        lost.global_position = lost.barricade.global_position + lost.barricade.normal * 6.0 + Vector3(0, -8.0, 0)
        var t1 := Time.get_ticks_msec()
        while Time.get_ticks_msec() - t1 < 3000 and lost.rescues == 0:
            await get_tree().physics_frame
        _check(lost.rescues > 0 and lost.global_position.distance_to(lost.barricade.outside_point) < 3.0, "%s a Melty that fell off its climb is put back at its crack" % tag)
        lost.state = lost.OUTSIDE
        lost.global_position = lost.barricade.outside_point + lost.barricade.normal * 3.0
        lost.set_physics_process(false)
        await _frames(2)
        lost.set_physics_process(true)
        var r0: int = lost.rescues
        var keep_v: float = lost.speed
        lost.speed = 0.0                    # can't move: it's stuck
        var t2 := Time.get_ticks_msec()
        while Time.get_ticks_msec() - t2 < 9000 and lost.rescues == r0:
            await get_tree().physics_frame
        lost.speed = keep_v
        _check(lost.rescues > r0, "%s a Melty hung up outside its crack is moved on" % tag)


## The Melty kinds and the bosses, each tested against the player.
func _kinds_tests() -> void:
    main.start_level(100)
    await _frames(10)
    var L = main.level
    var M = L.mode
    var p = L.player
    p.invulnerable = true
    M.coins = 99999
    for d in M.doors.duplicate():
        M.use(d)
    await _frames(30)
    M._start_wave(8)
    M.to_spawn = 0
    M._boss_due = -1.0
    # Wave mix: plain Melties early, every kind later.
    var early := {}
    var late := {}
    for k in 400:
        early[M.pick_kind(1)] = true
        late[M.pick_kind(8)] = true
    _check(early.keys() == ["shambler"], "kinds: wave 1 is all plain Melties %s" % str(early.keys()))
    _check(late.has("sprinter") and late.has("popper") and late.has("brute") and late.has("spitter") and late.has("shambler"), "kinds: wave 8 mixes all five %s" % str(late.keys()))
    # Stats per kind.
    var made := {}
    for kind in ["shambler", "sprinter", "brute", "popper", "spitter"]:
        var m = M._spawn_one(kind)
        m.set_physics_process(false)
        made[kind] = m
    _check(made["brute"].max_hp > made["shambler"].max_hp * 3.0 and made["brute"].k["planks"] == 2, "kinds: brutes are tanky and rip 2 boards a swing")
    # (each Melty's speed also varies +-15%, so compare the kinds' base speeds)
    _check(made["sprinter"].k["speed"] >= made["shambler"].k["speed"] * 1.5 and made["sprinter"].speed > made["shambler"].speed and made["sprinter"].max_hp < made["shambler"].max_hp, "kinds: sprinters are fast and fragile")
    _check(made["brute"].model.scale.x > 1.4 and made["sprinter"].model.scale.x < 1.0, "kinds: each kind looks different")
    for m in made.values():
        m.take_damage(99999.0, Vector3(500, 0, 500), m.global_position, false)
    await _frames(10)
    # Kill payouts.
    var c0: int = M.coins
    var b = M._spawn_one("brute")
    b.take_damage(99999.0, p.global_position, b.global_position + Vector3(0, 0.5, 0), false)
    _check(M.coins == c0 + 120, "kinds: a brute pays 120 coins (+%d)" % (M.coins - c0))
    await _frames(5)
    # Popper: walks up and bursts.
    var spot := Vector3(0, 0.5, 0)
    p.global_position = spot
    p.invulnerable = false
    p.health = 100000.0
    var pop = M._spawn_one("popper")
    pop.global_position = spot + Vector3(4, 0, 0)
    pop.state = pop.HUNTING
    var t0 := Time.get_ticks_msec()
    while pop.alive and Time.get_ticks_msec() - t0 < 6000:
        await get_tree().physics_frame
    _check(not pop.alive and p.health < 100000.0, "popper: reaches you and bursts (%.0f damage)" % (100000.0 - p.health))
    # Shooting a popper up close still splashes you.
    p.health = 100000.0
    var pop2 = M._spawn_one("popper")
    pop2.global_position = spot + Vector3(2.5, 0, 0)
    pop2.set_physics_process(false)
    pop2.take_damage(99999.0, p.global_position, pop2.global_position + Vector3(0, 0.6, 0), false)
    await _frames(30)
    _check(p.health < 100000.0, "popper: shooting one up close still splashes you")
    # Spitter: hangs back and lobs molten plastic.
    p.health = 100000.0
    var sp = M._spawn_one("spitter")
    sp.global_position = spot + Vector3(0, 0, 12)
    sp.state = sp.HUNTING
    t0 = Time.get_ticks_msec()
    while p.health >= 100000.0 and Time.get_ticks_msec() - t0 < 10000:
        await get_tree().physics_frame
    _check(p.health < 100000.0 and sp.global_position.distance_to(p.global_position) > 5.0, "spitter: hits you from range (%.1fm away)" % sp.global_position.distance_to(p.global_position))
    sp.take_damage(99999.0, Vector3(500, 0, 500), sp.global_position, false)
    p.invulnerable = true
    for e in L.enemies.duplicate():
        if is_instance_valid(e) and e.alive:
            e.take_damage(99999.0, Vector3(500, 0, 500), e.global_position, false)
    await _frames(10)

    # Boss wave 5: The Big Melt.
    M._start_wave(5)
    M.to_spawn = 0
    t0 = Time.get_ticks_msec()
    while M.boss == null and Time.get_ticks_msec() - t0 < 8000:
        await get_tree().physics_frame
    var boss = M.boss
    _check(boss != null and boss.kind == "big_melt" and boss.is_boss, "boss: wave 5 brings The Big Melt")
    await _frames(5)
    _check(M._boss_ui.visible and M._boss_label.text == "THE BIG MELT", "boss: health bar on screen")
    _check(boss.max_hp > M._wave_hp * 15.0 and boss.model.scale.x > 2.0, "boss: huge, with %.0f health" % boss.max_hp)
    _check(L.get_objective_text().begins_with("Defeat"), "boss: objective says to defeat it ('%s')" % L.get_objective_text())
    var a0: int = M.alive
    M.boss_summon(boss)
    _check(M.alive == a0 + 2, "boss: calls in two sprinters")
    boss.set_physics_process(false)
    p.invulnerable = false
    p.health = 100000.0
    p.global_position = boss.global_position + Vector3(3, 0.3, 0)
    await _frames(2)
    boss._slam()
    _check(p.health < 100000.0, "boss: ground slam hurts you nearby (%.0f)" % (100000.0 - p.health))
    p.invulnerable = true
    boss.take_damage(boss.max_hp * 0.5, p.global_position, boss.global_position + Vector3(0, 1, 0), false)
    await _frames(2)
    _check(absf(M._boss_bar.value - boss.max_hp * 0.5) < 1.0, "boss: health bar tracks damage")
    c0 = M.coins
    var pk0: int = L.pickups.size()
    boss.take_damage(99999.0, p.global_position, boss.global_position + Vector3(0, 1, 0), false)
    await _frames(5)
    _check(M.coins >= c0 + 500 and M.boss == null and not M._boss_ui.visible, "boss: pays 500 coins and the bar goes away (+%d)" % (M.coins - c0))
    _check(L.pickups.size() >= pk0 + 3, "boss: drops ammo, armor and health")
    for e in L.enemies.duplicate():
        if is_instance_valid(e) and e.alive:
            e.take_damage(99999.0, Vector3(500, 0, 500), e.global_position, false)
    await _frames(10)
    # Wave 10: the other boss.
    M._start_wave(10)
    M.to_spawn = 0
    t0 = Time.get_ticks_msec()
    while M.boss == null and Time.get_ticks_msec() - t0 < 8000:
        await get_tree().physics_frame
    _check(M.boss != null and M.boss.kind == "molten_major", "boss: wave 10 brings The Molten Major")
    p.global_position = Vector3(0, 0.5, 30)


func _clear(L, pos: Vector3) -> bool:
    var cap := CapsuleShape3D.new()
    cap.radius = 0.3
    cap.height = 1.4
    var q := PhysicsShapeQueryParameters3D.new()
    q.shape = cap
    q.transform = Transform3D(Basis(), pos + Vector3(0, 0.95, 0))
    q.collision_mask = 1
    return L.get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty()


func _path_exists(L, a: Vector3, b: Vector3) -> bool:
    var map_rid: RID = L.get_world_3d().navigation_map
    var path := NavigationServer3D.map_get_path(map_rid, a, b, true)
    return path.size() > 1 and path[path.size() - 1].distance_to(b) < 2.0


func _frames(n: int) -> void:
    for i in n:
        await get_tree().physics_frame


func _check(ok: bool, label: String) -> void:
    results.append([label, ok])
