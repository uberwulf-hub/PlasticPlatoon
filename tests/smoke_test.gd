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
        if x.alive and x.s["speed"] > 0.0:
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
    for v in L.vehicles.duplicate():
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
        await _frames(540)
        _check(v.ai_alert > 0.0, "L%d tan %s spotted the player" % [i, v.kind])
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
