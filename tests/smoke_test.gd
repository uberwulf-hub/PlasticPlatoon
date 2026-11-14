extends Node
## Headless smoke test: plays through every operation programmatically.
## Run:  godot --headless --path . res://tests/smoke_test.tscn

var main: Node
var results := []
var finished_result = null


func _ready() -> void:
    Game.show_news = true          # other tests may have saved it off
    Game.squad_size = 0            # the AI squad has its own test (squad_test)
    main = load("res://scenes/main.tscn").instantiate()
    add_child(main)
    await _frames(30)
    _audio_checks()
    var PS = load("res://scripts/plastic_soldier.gd")
    _check(PS.available(), "plastic soldier model loads")
    await _news_tests()
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
    # death path (outside the start's safe zone, where damage applies)
    main.level.player.global_position = main.level.safe_center + Vector3(main.level.safe_radius + 10.0, 0.5, 0)
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
    _safe_zone_test(i, L, p)
    if i == 0:
        await _edge_test(L, p)
        await _fx_budget_test(L)
        await _zoom_test(L, p)
    if i == 1:
        # Weather: Concrete Jungle has clouds and rain (a storm adds lightning).
        _check(L.weather != null and L.weather.rain != null and L.weather.sky_mat != null, "L1 weather: cloudy sky and rain")
        L.weather.w["storm"] = true
        L.weather.strike()
        await _frames(3)
        _check(L.weather.flashes == 1 and L._sun.light_energy > L.weather._base_sun, "L1 lightning flashes the map")
        L.weather.w["storm"] = false
    if i == 1:
        # Concrete Jungle lag fix: far soldiers/vehicles skip shadows, and flat or
        # small scenery is cheap to draw.
        await _street_vehicle_test(L, p)
        _check(L.far_shadow_off > 5, "L1 distant soldiers and vehicles skip shadows (%d)" % L.far_shadow_off)
        _check(L.optimize_static() > 100, "L1 small and flat scenery is optimised")
    if i == 0:
        await _plastic_damage_test(L, p)
        await _touch_test(L, p)
    if i == 0:
        await _vehicle_zone_test(L)
    if i == 0:
        await _jeep_point_blank_test(L, p)
    _one_gun_test(i, L, p)
    _invisible_wall_test(i, L)
    if i == 0:
        await _camera_wall_test(L, p)
    if L.vehicles.size() > 0:
        await _vehicle_test(i, L, p)
    if L.enemy_vehicles.size() > 0:
        await _enemy_vehicle_test(i, L, p)
    # Teleport near an enemy and let it engage.
    var e = null
    for x in L.enemies:
        if is_instance_valid(x) and x.alive and x.s["speed"] > 0.0:
            e = x
            break
    if e:
        var spot = _open_spot_near(L, e, [8.0, 12.0, 16.0])
        p.global_position = spot if spot != null else e.global_position + Vector3(8, 0.5, 0)
        await _frames(180)
        var engaged := 0
        for x in L.enemies:
            if is_instance_valid(x) and x.global_position.distance_to(p.global_position) < 30.0 and (x.state != 0 or not x.alive):
                engaged += 1
        _check(engaged > 0, "L%d nearby enemies engaged player (%d)" % [i, engaged])
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
                for x in L.enemy_vehicles:
                    if is_instance_valid(x) and x.alive:
                        x.take_damage(99999.0, Vector3.ZERO, x.global_position, true)
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



## Repro of the "camera flickers near walls" bug: stand with the right shoulder
## pressed into the FOB's east wall and jiggle the view. The camera distance
## must not jump back and forth.
func _camera_wall_test(L, p) -> void:
    p.global_position = Vector3(20.85, 0.5, 85.0)
    p.rotation.y = 0.0
    p.pitch = -0.1
    await _frames(30)
    var snaps_in := 0
    var pops_out := 0
    var last: float = p.rig.distance
    var min_d := 99.0
    for f in 120:
        p.rotation.y = sin(f * 0.7) * 0.06
        p.pitch = -0.1 + cos(f * 0.9) * 0.05
        await get_tree().physics_frame
        var d: float = p.rig.distance
        if d < last - 0.5:
            snaps_in += 1
        if d > last + 0.3:
            pops_out += 1          # the reported flicker: sudden jump back out
        last = d
        min_d = minf(min_d, d)
    _check(pops_out == 0 and snaps_in <= 1, "camera doesn't flicker against wall (%d snaps in, %d pops out)" % [snaps_in, pops_out])
    _check(min_d > 2.0, "camera stays behind player at wall (min dist %.2f)" % min_d)


func _vehicle_test(i: int, L, p) -> void:
    # Pause Tan vehicles so they can't wander over and block this driving check.
    for t in L.enemy_vehicles:
        t.set_physics_process(false)
    # Street cars/bikes are unarmed and have their own test (_street_vehicle_test).
    for v in L.vehicles.filter(func(x): return not ["car", "bike"].has(x.kind)):
        var side: Vector3 = v.global_transform.basis.x
        p.global_position = v.global_position - side * (v.k["size"].x * 0.5 + 1.2) + Vector3(0, 0.3, 0)
        await _frames(3)
        _check(L.nearest_vehicle(p.global_position, 4.5) == v, "L%d %s: E prompt in range" % [i, v.kind])
        v.enter(p)
        await _frames(2)
        _check(p.vehicle == v and v.camera.current and not p.visible, "L%d %s: entered" % [i, v.kind])
        var start: Vector3 = v.global_position
        v.drive_input = Vector2(0, -1)
        await _frames(90)
        v.drive_input = Vector2(0.6, -1)
        await _frames(30)
        v.drive_input = Vector2.ZERO
        var moved: float = start.distance_to(v.global_position)
        _check(moved > 3.0, "L%d %s: drove %.1fm%s" % [i, v.kind, moved, "" if moved > 3.0 else " [alive=%s hp=%.0f speed=%.1f floor=%s pos=%s driver=%s tan_near=%s]" % [v.alive, v.hp, v.speed, v.is_on_floor(), v.global_position.snapped(Vector3.ONE * 0.1), p.vehicle == v, _tan_near(L, v.global_position)]])
        _check(p.global_position.distance_to(v.global_position) < 1.5, "L%d %s: driver rides along" % [i, v.kind])
        var shots: int = p.shots_fired
        v.fire_cd = 0.0
        v.fire_primary()
        v.fire_secondary()
        await _frames(20)
        _check(v.kind == "tank" or p.shots_fired > shots, "L%d %s: weapon fires" % [i, v.kind])
        v.exit_vehicle()
        await _frames(3)
        _check(p.vehicle == null and p.visible and p.camera.current, "L%d %s: exited" % [i, v.kind])
    # Get back in the first vehicle and have it destroyed: driver must be ejected alive.
    var v0 = L.vehicles[0]
    v0.enter(p)
    await _frames(2)
    v0.take_damage(99999.0, Vector3.ZERO, v0.global_position, true)
    await _frames(5)
    _check(not v0.alive and p.vehicle == null and p.alive, "L%d destroyed vehicle ejects driver" % i)
    _check(not v0.can_enter(), "L%d wrecks can't be re-entered" % i)
    for t in L.enemy_vehicles:
        t.set_physics_process(true)



## Invisible walls: a player-sized capsule standing a step away from a tree trunk
## (or palm, lamp post, cactus) must not be blocked by that prop's collision.
func _invisible_wall_test(i: int, L) -> void:
    var space: PhysicsDirectSpaceState3D = L.get_world_3d().direct_space_state
    var cap := CapsuleShape3D.new()
    cap.radius = 0.35
    cap.height = 1.6
    var checked := 0
    var blocked: Array = []
    for pr in L.props:
        var path: String = pr["path"]
        var dist := 0.0
        if "tree" in path or "palm" in path or "StreetLight" in path:
            dist = 1.4
        elif "cactus" not in path:
            continue
        var node: Node3D = pr["node"]
        if "cactus" in path:
            # Probe just outside the cactus's visible width (its arms are real collision).
            var half := 0.0
            for m in node.find_children("*", "MeshInstance3D", true, false):
                var ab: AABB = (node.global_transform.affine_inverse() * m.global_transform) * m.get_aabb()
                half = maxf(half, maxf(maxf(absf(ab.position.x), absf(ab.end.x)), maxf(absf(ab.position.z), absf(ab.end.z))))
            dist = half + 0.45
        for d in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
            var q := PhysicsShapeQueryParameters3D.new()
            q.shape = cap
            q.transform = Transform3D(Basis(), node.global_position + d * dist + Vector3(0, 0.85, 0))
            q.collision_mask = 1
            checked += 1
            for hit in space.intersect_shape(q, 8):
                if hit["collider"] == node:
                    blocked.append("%s@%s" % [path.get_file(), node.global_position.snapped(Vector3.ONE)])
                    break
    if checked == 0:
        return              # map has no trees/lamps/cacti
    _check(blocked.is_empty(), "L%d no invisible walls around %d tree/lamp/cactus probes %s" % [i, checked, str(blocked.slice(0, 4)) if not blocked.is_empty() else ""])



## Tan jeeps/tanks: spot the player, drive, aim, shoot, can't be stolen, and
## count as kills when destroyed.
func _enemy_vehicle_test(i: int, L, p) -> void:
    # This checks the Tan jeep/tank AI engages; parked street cars (real cover
    # in play) can randomly block its view of the test spot, so they step
    # aside for this check.
    var parked: Array = L.vehicles.filter(func(v): return ["car", "bike"].has(v.kind))
    for v in parked:
        v.collision_layer = 0
    await _enemy_vehicle_checks(i, L, p)
    for v in parked:
        if is_instance_valid(v):
            v.collision_layer = 1


func _enemy_vehicle_checks(i: int, L, p) -> void:
    p.invulnerable = false
    p.health = 100000.0      # survive the test but still register hits
    var dmg_total := 0.0
    for v in L.enemy_vehicles:
        if not v.alive:
            continue            # already destroyed by an earlier part of the test
        _check(not v.can_enter(), "L%d tan %s can't be entered" % [i, v.kind])
        var travelled0: float = v.ai_travelled
        var shots0: int = v.ai_shots
        var spot = _open_spot_near(L, v)
        if spot == null:
            continue
        p.global_position = spot
        var hp0: float = p.health
        v.hear(p.global_position)      # it would notice you anyway; this keeps the test fast
        # 9 s is usually plenty; give a jeep that's circling behind cover up to 15 s
        # to get a clear shot (it's AI, so the timing varies from run to run).
        var spotted := false
        for f in 900:
            await get_tree().physics_frame
            spotted = spotted or v.ai_alert > 0.0
            if f >= 540 and v.ai_shots > shots0:
                break
        _check(spotted, "L%d tan %s spotted the player" % [i, v.kind])
        _check(v.ai_shots > shots0, "L%d tan %s opened fire (%d shots)%s" % [i, v.kind, v.ai_shots - shots0, "" if v.ai_shots > shots0 else " [alert=%.1f los=%s react=%.2f player_d=%.1f spot=%s]" % [v.ai_alert, v._ai_los, v._ai_react, v.global_position.distance_to(p.global_position), spot]])
        var drove: float = v.ai_travelled - travelled0
        _check(drove > 5.0 or v.kind == "tank", "L%d tan %s drove %.1fm%s" % [i, v.kind, drove, "" if drove > 5.0 or v.kind == "tank" else " [alert=%.1f los=%s charge=%.1f stuck=%d speed=%.1f home_d=%.1f pos=%s player_d=%.1f]" % [v.ai_alert, v._ai_los, v._ai_charge_t, v._ai_stuck_count, v.speed, v.global_position.distance_to(v.home), v.global_position.snapped(Vector3.ONE), v.global_position.distance_to(p.global_position)]])
        dmg_total += hp0 - p.health
    _check(dmg_total > 0.0, "L%d tan vehicles hurt the player (%.0f dmg total)" % [i, dmg_total])
    var v0 = null
    for t in L.enemy_vehicles:
        if t.alive:
            v0 = t
            break
    if v0 != null:
        var before: int = L.kills
        v0.take_damage(99999.0, Vector3.ZERO, v0.global_position, true)
        await _frames(3)
        _check(not v0.alive and L.kills >= before + 1, "L%d destroying a tan vehicle counts as a kill" % i)
    p.health = 100.0
    p.invulnerable = true



## A spot ~25 m from the vehicle that is on solid ground, not inside anything,
## and in clear view of it.
func _open_spot_near(L, v, dists := [25.0, 18.0, 32.0]):
    var space: PhysicsDirectSpaceState3D = L.get_world_3d().direct_space_state
    var cap := CapsuleShape3D.new()
    cap.radius = 0.4
    cap.height = 1.8
    var ex: Array[RID] = [v.get_rid()]
    for dist in dists:
        for k in 16:
            var dir := Vector3.FORWARD.rotated(Vector3.UP, v.rotation.y + k * TAU / 16.0)
            var pos: Vector3 = v.global_position + dir * dist
            if L.in_safe_zone(pos):
                continue        # Tan units deliberately ignore players in the safe zone
            var ground := space.intersect_ray(PhysicsRayQueryParameters3D.create(pos + Vector3(0, 3, 0), pos + Vector3(0, -2, 0), 1))
            if ground.is_empty() or absf(ground["position"].y - v.global_position.y) > 1.0:
                continue
            var q := PhysicsShapeQueryParameters3D.new()
            q.shape = cap
            q.transform = Transform3D(Basis(), ground["position"] + Vector3(0, 1.0, 0))
            q.collision_mask = 1 | 4
            if not space.intersect_shape(q, 1).is_empty():
                continue
            var los := space.intersect_ray(PhysicsRayQueryParameters3D.create(v.global_position + Vector3(0, 1.8, 0), ground["position"] + Vector3(0, 1.2, 0), 1, ex))
            if los.is_empty():
                return ground["position"] + Vector3(0, 0.3, 0)
    return null



func _tan_near(L, pos: Vector3) -> String:
    var out := []
    for t in L.enemy_vehicles:
        if t.global_position.distance_to(pos) < 12.0:
            out.append("%s %.1fm" % [t.kind, t.global_position.distance_to(pos)])
    return str(out)



## Every PNN script plays start to finish, fills its placeholders, and the
## campaign flow goes menu -> news -> briefing.
func _news_tests() -> void:
    var NS = load("res://scripts/news_scripts.gd")
    var NB = load("res://scripts/news_break.gd")
    var stat_sets := [
        {"time": 245.0, "kills": 31, "total": 34, "headshots": 9, "accuracy": 41.0, "level": 0},
        {"time": 610.0, "kills": 12, "total": 30, "headshots": 1, "accuracy": 18.0, "level": 0},
        {"time": 400.0, "kills": 25, "total": 30, "headshots": 2, "accuracy": 72.0, "level": 0},
    ]
    var scripts := []
    for op in 3:
        scripts.append(NS.intro(op))
        for st in stat_sets:
            scripts.append(NS.outro(op, true, st))
        scripts.append(NS.outro(op, false, stat_sets[0]))
    var unfilled := 0
    var played := 0
    for d in scripts:
        for b in d["beats"]:
            if "{" in b.get("line", "") or "{" in b.get("headline", ""):
                unfilled += 1
        var n = NB.new()
        n.play(d)
        var got := [false]
        n.finished.connect(func(): got[0] = true)
        add_child(n)
        await _frames(2)
        var guard := 0
        while not got[0] and guard < 40:
            n.skip_line()
            await _frames(1)
            guard += 1
        if got[0]:
            played += 1
    # The boom mic bonks Gary exactly once per dip, stops on his helmet
    # (never through him) and knocks him back a step.
    var narr_was: bool = Game.narration
    Game.narration = false
    var nb2 = NB.new()
    nb2.auto_advance = false
    nb2.play(NS.intro(0))
    add_child(nb2)
    await _frames(5)
    var home: Vector3 = nb2.gary.position
    nb2._bump_t = 0.0
    var knocked := 0.0
    for f in 70:
        await _frames(1)
        knocked = maxf(knocked, nb2.gary.position.distance_to(home))
    _check(nb2.bonks == 1, "PNN: one dip of the boom mic bonks Gary once (%d)" % nb2.bonks)
    _check(nb2.boom_gap > -0.005, "PNN: the boom mic never goes through Gary (closest %.3f m)" % nb2.boom_gap)
    _check(knocked > 0.1, "PNN: the bonk knocks Gary back (%.2f m)" % knocked)
    await _frames(60)
    _check(nb2.gary.position.distance_to(home) < 0.01, "PNN: Gary steps back to his mark")
    nb2._finish()
    Game.narration = narr_was
    _check(unfilled == 0, "PNN: all placeholders filled (%d unfilled)" % unfilled)
    _check(played == scripts.size(), "PNN: %d/%d news breaks play to the end" % [played, scripts.size()])
    # Menu -> Campaign -> Operation 1 shows the news, then the briefing.
    main.show_campaign()
    await _frames(2)
    var btn: Button = null
    for c in main.ui.find_children("*", "Button", true, false):
        if c.text.begins_with("1."):
            btn = c
    btn.pressed.emit()
    await _frames(3)
    _check(main.news != null, "PNN: news break plays before Operation 1")
    main.news._finish()
    await _frames(3)
    var deploy := false
    for c in main.ui.find_children("*", "Button", true, false):
        if c.text == "DEPLOY":
            deploy = true
    _check(deploy, "PNN: briefing appears after the news")



## Regression: the soldier model used to show all six of its guns at once.
func _one_gun_test(i: int, L, p) -> void:
    var GUNS := ["AK", "RocketLauncher", "ShortCannon", "Shotgun", "SMG", "Sniper", "Sniper_2", "Pistol", "Knife_1", "Knife_2", "Shovel", "Revolver", "Revolver_Small", "GrenadeLauncher"]
    var bad := []
    for who in [p] + L.enemies:
        var m = who.model
        if m.get("rig") == null:
            continue
        var n := 0
        for mi in m.rig.find_children("*", "MeshInstance3D", true, false):
            if mi.is_visible_in_tree() and GUNS.has(String(mi.name)):
                n += 1
        if n != 1:
            bad.append("%s:%d" % [who.name, n])
    _check(bad.is_empty(), "L%d every soldier holds exactly one gun %s" % [i, str(bad.slice(0, 3)) if not bad.is_empty() else ""])



## The start point is a safe zone: no Tan units start inside it, players
## there can't be hurt or targeted, firing exposes you briefly, and stepping
## out makes you a target again.
## Hits leave melted marks and wear on the plastic; healing to full clears it.
func _plastic_damage_test(L, p) -> void:
    var e = null
    for x in L.enemies:
        if x.alive:
            e = x
            break
    var m0: int = e.model.damage_marks()
    e.take_damage(1.0, p.global_position, e.global_position + Vector3(0.2, 1.2, 0.3), false)
    _check(e.model.damage_marks() == m0 + 1 and e.model._wear > 0.0 and e.model.find_children("*", "MeshInstance3D", true, false)[0].material_overlay != null, "L0 a hit melts a patch of the Tan soldier's plastic (shader, no stuck-on shapes)")
    var keep_inv: bool = p.invulnerable
    var keep_pos: Vector3 = p.global_position
    p.global_position = L.safe_center + Vector3(L.safe_radius + 12.0, 0.5, 0)
    p.invulnerable = false
    p.take_damage(20.0, e.global_position, Vector3.ZERO, true)
    _check(p.model.damage_marks() >= 1 and p.model._wear > 0.0, "L0 the player's plastic shows damage")
    p.health = p.max_health - 5.0
    p.give_pickup("health")
    _check(p.model.damage_marks() == 0 and p.model._wear == 0.0, "L0 healing to full clears the damage")
    p.invulnerable = keep_inv
    p.global_position = keep_pos


## The map edge used to be an invisible wall: now a barrier fades in near it,
## and touching it says so. Also: auto resolution steps down when it's slow.
func _edge_test(L, p) -> void:
    var keep: Vector3 = p.global_position
    var lim: float = L._bounds.y
    p.global_position = Vector3(20, keep.y + 6.0, -lim + 1.2)
    p.velocity = Vector3.ZERO
    await _frames(12)
    _check(L.edge_alpha > 0.4, "L0 the map edge shows a barrier up close (%.2f)" % L.edge_alpha)
    _check("EDGE" in L.hud.msg_label.text, "L0 touching the map edge says turn back")
    p.global_position = keep
    await _frames(6)
    _check(L.edge_alpha < 0.01, "L0 the barrier is hidden away from the edge")
    # Auto resolution: a slow 2 s window drops the 3D scale a step.
    var was: float = Game.res_scale
    Game.auto_res = true
    Game._res_win = 2.5
    Game._res_frames = 40          # = 16 fps
    Game._process(0.0)
    _check(Game.res_scale < was, "auto resolution steps down when the game is slow (%.2f -> %.2f)" % [was, Game.res_scale])
    Game.apply_graphics()


## Street cars and motorbikes can be driven (unarmed), on any operation.
func _street_vehicle_test(L, p) -> void:
    var cars: Array = L.vehicles.filter(func(v): return v.kind == "car")
    var bikes: Array = L.vehicles.filter(func(v): return v.kind == "bike")
    _check(cars.size() >= 8 and bikes.size() >= 4, "L1 drivable street cars (%d) and motorbikes (%d)" % [cars.size(), bikes.size()])
    var c = cars[0]
    var tj = L.enemy_vehicles.filter(func(v): return v.alive)[0]
    c.hp = c.max_hp          # earlier blasts in this test may have scratched it
    await _frames(2)
    _check(not c.hp_bar.visible and tj.hp_bar.visible, "L1 health bars: Tan vehicles always, ours hidden at full health (%s %s)" % [c.hp_bar.visible, tj.hp_bar.visible])
    c.hp = c.max_hp * 0.5
    await _frames(2)
    _check(c.hp_bar.visible and absf(c._bar_fill.mesh.size.x - c.BAR_W * 0.5) < 0.01, "L1 a damaged vehicle shows a half-full health bar")
    c.hp = c.max_hp
    var b = bikes[0]
    var keep: Vector3 = p.global_position
    b.enter(p)
    _check(p.vehicle == b and b.rider.visible, "L1 a soldier rides the motorbike")
    b.drive_input = Vector2(0, -1)
    var start: Vector3 = b.global_position
    await _frames(40)
    _check(b.global_position.distance_to(start) > 3.0, "L1 the motorbike drives")
    var shots: int = b.ai_shots
    b.fire_cd = 0.0
    b.fire_primary()
    _check(b.fire_cd == 0.0, "L1 street vehicles have no gun")
    b.drive_input = null
    b.exit_vehicle()
    _check(p.vehicle == null and not b.rider.visible, "L1 getting off the motorbike")
    p.global_position = keep
    await _frames(5)


## Lag fixes: fires die down and only a few burn at once; effects are
## prepared at level start.
func _fx_budget_test(L) -> void:
    var Fx = load("res://scripts/fx.gd")
    # Bullet holes on walls, scorch on the ground, never on anything that moves.
    var space: PhysicsDirectSpaceState3D = L.get_world_3d().direct_space_state
    var c0: int = L.mark_count()
    var gh: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0, 40, 50), Vector3(0, -10, 50), 1))
    L.bullet_mark(gh)
    _check(L.mark_count() == c0 + 1, "a bullet leaves a hole on fixed scenery")
    L.bullet_mark({"collider": L.enemy_vehicles[0], "position": Vector3.ZERO, "normal": Vector3.UP})
    _check(L.mark_count() == c0 + 1, "no bullet holes on things that move")
    for k in 60:
        L.bullet_mark(gh)
    _check(L._holes.size() <= L.MAX_HOLES, "bullet holes are capped (%d)" % L._holes.size())
    L.boom_local(gh["position"] + Vector3(0, 0.5, 0), 4.0)
    _check(L._scorches.size() >= 1, "an explosion scorches the ground")
    _check(L.fx_prewarmed, "effects are prepared at level start")
    for k in 7:
        Fx.fire(L, Vector3(k * 3.0, 1, 60), 1.0)
    _check(Fx.fires_burning() <= Fx.MAX_FIRES, "at most %d fires burn at once (%d)" % [Fx.MAX_FIRES, Fx.fires_burning()])
    var f = Fx.fire(L, Vector3(0, 1, 64), 1.0, 0.2)
    await get_tree().create_timer(5.5).timeout
    _check(not is_instance_valid(f) or not f.emitting, "a fire dies down after its time")


## Scroll wheel: zooms the camera; all the way in is first person (body hidden).
func _zoom_test(L, p) -> void:
    var keep: float = Game.view_dist
    for k in 8:
        p.zoom(-1)
    _check(p.first_person() and Game.view_dist == 0.0, "wheel all the way in = first person")
    await _frames(40)
    _check(p.camera.global_position.distance_to(p.pivot.global_position) < 0.6 and not p._head_meshes()[0].visible, "first person: camera at the eyes, own head hidden (%.2f m)" % p.camera.global_position.distance_to(p.pivot.global_position))
    for k in 8:
        p.zoom(1)
    _check(Game.view_dist >= 6.0, "wheel out = far third-person view")
    await _frames(60)
    _check(p.model.visible and p._head_meshes()[0].visible and p.camera.global_position.distance_to(p.pivot.global_position) > 2.0, "third person: body visible again")
    Game.view_dist = keep


## Phone controls: the joystick walks, a right-side drag turns, FIRE holds.
func _touch_test(L, p) -> void:
    var tc = null
    for c in L.get_children():
        if c.get_script() == L.TouchControls:
            tc = c
    _check(tc != null, "L0 touch controls are part of the level")
    if tc == null:
        return
    var keep: bool = Game.touch_mode
    Game.touch_mode = false
    await _frames(2)
    _check(not tc.visible, "L0 touch controls stay hidden on desktop")
    Game.touch_mode = true
    await _frames(2)
    _check(tc.visible, "L0 touch controls show in touch mode (playing %s, paused %s)" % [L.is_playing(), get_tree().paused])
    var s: Vector2 = tc._screen()
    var o := Vector2(s.x * 0.2, s.y * 0.7)
    tc._on_touch(0, o, true)
    tc._on_drag(0, o + Vector2(0, -90), Vector2(0, -90))
    await _frames(2)
    _check(Input.is_action_pressed("move_forward") and Input.get_action_strength("move_forward") > 0.5, "L0 pushing the joystick up walks forward")
    tc._on_touch(0, o + Vector2(0, -90), false)
    await _frames(2)
    _check(not Input.is_action_pressed("move_forward"), "L0 letting go of the joystick stops")
    var yaw: float = p.rotation.y
    var r := Vector2(s.x * 0.55, s.y * 0.3)
    if tc._button_at(r) == null:
        tc._on_touch(1, r, true)
        tc._on_drag(1, r + Vector2(120, 0), Vector2(120, 0))
        tc._on_touch(1, r + Vector2(120, 0), false)
    _check(absf(p.rotation.y - yaw) > 0.1, "L0 dragging on the right turns the soldier")
    var fire: Vector2 = tc.buttons[0]["pos"] * s
    tc._on_touch(2, fire, true)
    await _frames(2)
    _check(Input.is_action_pressed("fire") and Game.aiming_input(), "L0 holding FIRE fires without a captured mouse")
    tc._on_touch(2, fire, false)
    await _frames(2)
    _check(not Input.is_action_pressed("fire"), "L0 releasing FIRE stops")
    Game.touch_mode = keep
    await _frames(1)


## Regression (found by CI): a Tan jeep that ended up right on top of the
## player couldn't depress its gun that far and sat there without firing.
func _jeep_point_blank_test(L, p) -> void:
    var j = null
    for v in L.enemy_vehicles:
        if v.alive and v.kind == "jeep":
            j = v
            break
    if j == null:
        return
    var keep: Vector3 = p.global_position
    var spot: Vector3 = L.safe_center + Vector3(L.safe_radius + 30.0, 0.5, 0)
    p.global_position = spot
    p.invulnerable = true
    j.global_position = spot + Vector3(0, 0, -2.5)
    j.rotation.y = 0.0                               # nose toward the player
    j.velocity = Vector3.ZERO
    j.speed = 0.0
    var shots0: int = j.ai_shots
    var t0 := Time.get_ticks_msec()
    while j.ai_shots == shots0 and Time.get_ticks_msec() - t0 < 10000:
        j.ai_alert = 6.0
        j.ai_last_seen = p.global_position + Vector3(0, 1, 0)
        j._ai_charge_t = 4.0                           # it keeps trying to charge in (fails without the fix)
        p.global_position = spot                       # stay put
        await get_tree().physics_frame
    _check(j.ai_shots > shots0, "L0 a Tan jeep on top of you backs off and opens fire (%.1fs)" % ((Time.get_ticks_msec() - t0) / 1000.0))
    p.global_position = keep


## Regression: a Tan jeep chasing someone at the zone's edge used to drive in
## and park inside (found by CI).
func _vehicle_zone_test(L) -> void:
    var j = null
    for v in L.enemy_vehicles:
        if v.alive and v.kind == "jeep":
            j = v
            break
    var out_dir := Vector3(1, 0, 0)
    j.global_position = L.safe_center + out_dir * (L.safe_radius + 45.0) + Vector3(0, 0.5, 0)
    j.rotation.y = atan2(out_dir.x, out_dir.z)       # facing the zone
    j.speed = 22.0                                   # arriving flat out
    var worst := 999.0
    for f in 420:
        j.ai_alert = 6.0
        j.ai_last_seen = L.safe_center + Vector3(0, 1, 0)
        j._ai_charge_t = 4.0                           # charge straight at it
        await get_tree().physics_frame
        var d: float = Vector2(j.global_position.x - L.safe_center.x, j.global_position.z - L.safe_center.z).length()
        worst = minf(worst, d)
    _check(worst > L.safe_radius + 1.0, "L0 a charging Tan jeep stops short of the safe zone (closest %.1fm, zone %.0fm)" % [worst, L.safe_radius])


func _safe_zone_test(i: int, L, p) -> void:
    var inside := []
    for e in L.enemies + L.enemy_vehicles:
        if L.in_safe_zone(e.global_position):
            inside.append(str(e.global_position.snapped(Vector3.ONE)))
    _check(inside.is_empty(), "L%d no Tan units start in the safe zone %s" % [i, str(inside)])
    var was_inv: bool = p.invulnerable
    p.invulnerable = false
    p.global_position = L.safe_center + Vector3(0, 0.3, 0)
    p.last_fire_ms = -100000
    var hp0: float = p.health + p.armor
    p.take_damage(30.0, Vector3.ZERO, p.global_position, false)
    _check(p.health + p.armor == hp0, "L%d no damage inside the safe zone" % i)
    var e = null
    for x in L.enemies:
        if x.alive and x.s["speed"] > 0.0:
            e = x
            break
    _check(e != null and e._player() == null, "L%d Tan troops won't target a player in the safe zone" % i)
    p.last_fire_ms = Time.get_ticks_msec()
    p.take_damage(5.0, Vector3.ZERO, p.global_position, false)
    _check(p.health + p.armor < hp0, "L%d firing from the safe zone exposes you" % i)
    p.global_position = L.safe_center + Vector3(L.safe_radius + 10.0, 0.3, 0)
    p.last_fire_ms = -100000
    _check(e != null and e._player() == p, "L%d outside the zone you're a target again" % i)
    p.health = 100.0
    p.armor = 25.0
    p.global_position = L.safe_center + Vector3(0, 0.3, 0)
    p.invulnerable = was_inv
