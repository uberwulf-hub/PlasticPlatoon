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
    _invisible_wall_test(i, L)
    if i == 0:
        await _camera_wall_test(L, p)
    if L.vehicles.size() > 0:
        await _vehicle_test(i, L, p)
    # Teleport near an enemy and let it engage.
    var e = null
    for x in L.enemies:
        if x.alive and x.s["speed"] > 0.0:
            e = x
            break
    if e:
        p.global_position = e.global_position + Vector3(8, 0.5, 0)
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
        _check(moved > 3.0, "L%d %s: drove %.1fm" % [i, v.kind, moved])
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
