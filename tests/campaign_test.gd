extends Node
## Headless campaign test: builds every operation, checks nothing spawned
## inside the scenery, and plays each objective chain (destroy, kill_hvt,
## kill_all, extract, collect, reach, defend) through to MISSION ACCOMPLISHED.
## Also plays every operation's PNN intro and outro to the end.
## Run:  godot --headless --path . res://tests/campaign_test.tscn [-- first last]

var main: Node
var results := []
var finished_result = null


func _ready() -> void:
    var news_was: bool = Game.show_news
    var squad_was: int = Game.squad_size
    Game.show_news = false
    Game.squad_size = 2
    main = load("res://scenes/main.tscn").instantiate()
    add_child(main)
    await _frames(10)
    var LD = load("res://scripts/level_data.gd")
    var n: int = LD.META.size()
    _check(n == Game.LEVEL_COUNT, "Game.LEVEL_COUNT (%d) matches the campaign (%d ops)" % [Game.LEVEL_COUNT, n])
    var args := OS.get_cmdline_user_args()
    var first := int(args[0]) if args.size() > 0 else 0
    var last := int(args[1]) if args.size() > 1 else n - 1
    await _news(first, last)
    main.show_campaign()
    await _frames(3)
    var buttons: Array = main.ui.find_children("*", "Button", true, false).filter(func(b): return b.text.contains("."))
    _check(buttons.size() == n, "campaign menu lists all %d operations (%d)" % [n, buttons.size()])
    for i in range(first, last + 1):
        await _play(i)
    main.show_main_menu()
    await _frames(5)
    Game.show_news = news_was
    Game.squad_size = squad_was
    Game.save()
    var fails := results.filter(func(r): return not r[1])
    print("\n==== CAMPAIGN TEST: %d checks, %d failed ====" % [results.size(), fails.size()])
    for r in results:
        print(("PASS " if r[1] else "FAIL ") + r[0])
    get_tree().quit(1 if fails.size() > 0 else 0)


func _frames(k: int) -> void:
    for i in k:
        await get_tree().physics_frame


func _check(cond: bool, label: String) -> void:
    results.append([label, cond])


func _news(first: int, last: int) -> void:
    var NS = load("res://scripts/news_scripts.gd")
    var NB = load("res://scripts/news_break.gd")
    var st := {"time": 321.0, "kills": 22, "total": 30, "headshots": 3, "accuracy": 44.0, "level": 0}
    var played := 0
    var total := 0
    var voiced := 0
    var total_beats := 0
    var clip_played := false
    var narr_was: bool = Game.narration
    Game.narration = true
    var unfilled := 0
    var themes := {}
    for op in range(first, last + 1):
        for d in [NS.intro(op), NS.outro(op, true, st), NS.outro(op, false, st)]:
            total += 1
            themes[d["theme"]] = true
            for b in d["beats"]:
                if "{" in b.get("line", "") or "{" in b.get("headline", ""):
                    unfilled += 1
            for b in d["beats"]:
                total_beats += 1
                if ResourceLoader.exists("res://assets/audio/voice/%s.ogg" % NB.clip_key(b.get("who", "both"), b.get("line", ""))):
                    voiced += 1
            var nb = NB.new()
            nb.play(d)
            var got := [false]
            nb.finished.connect(func(): got[0] = true)
            add_child(nb)
            await _frames(2)
            clip_played = clip_played or nb._clip_mode
            var guard := 0
            while not got[0] and guard < 40:
                nb.skip_line()
                await _frames(1)
                guard += 1
            if got[0]:
                played += 1
    _check(unfilled == 0, "PNN: all placeholders filled (%d unfilled)" % unfilled)
    _check(played == total, "PNN: %d/%d news breaks play to the end" % [played, total])
    Game.narration = narr_was
    _check(voiced == total_beats, "PNN: every line has a recorded voice (%d/%d)" % [voiced, total_beats])
    _check(clip_played, "PNN: the cutscene plays the recordings")
    if first == 0 and last >= 12:
        _check(themes.size() >= 13, "PNN: %d different field sets" % themes.size())
    var LD = load("res://scripts/level_data.gd")
    var ramp_up := true
    for k in range(1, LD.PROGRESSION.size()):
        ramp_up = ramp_up and LD.PROGRESSION[k]["ramp"] > LD.PROGRESSION[k - 1]["ramp"]
    _check(ramp_up, "Tan toughness rises every operation")
    # Each op's intro is its own story beat (no op falls back to another's script).
    var seen := {}
    for op in range(first, last + 1):
        var line: String = NS.intro(op)["beats"][0]["line"]
        seen[line] = true
    _check(seen.size() == last - first + 1, "PNN: every operation has its own intro")


## Static scenery overlapping a capsule at `pos` (feet), ignoring `except`.
func _blocked(L, pos: Vector3, except: Array, r := 0.3, h := 1.4) -> Array:
    var cap := CapsuleShape3D.new()
    cap.radius = r
    cap.height = h
    var q := PhysicsShapeQueryParameters3D.new()
    q.shape = cap
    q.transform = Transform3D(Basis(), pos + Vector3(0, h * 0.5 + 0.25, 0))
    q.collision_mask = 1
    q.exclude = except
    var out: Array = []
    for hit in L.get_world_3d().direct_space_state.intersect_shape(q, 4):
        var c = hit["collider"]
        if c is StaticBody3D and c.get_script() == null:
            out.append(c)
    return out


func _play(i: int) -> void:
    main.start_level(i)
    await _frames(3)
    var L = main.level
    var p = L.player
    var tag := "L%d %s:" % [i + 1, L.info["name"].trim_prefix("Operation ")]
    _check(L.enemies.size() >= 15, "%s %d Tan soldiers" % [tag, L.enemies.size()])
    _check(L.objectives.size() >= 2, "%s %d objectives" % [tag, L.objectives.size()])
    # Progression: only this op's vehicles, weapons and drone strikes, and its toughness.
    var pr: Dictionary = load("res://scripts/level_data.gd").progression(i)
    var bad: Array = []
    for v in L.vehicles:
        if not pr["vehicles"].has(v.kind) and not ["car", "bike"].has(v.kind):   # street rides are always allowed
            bad.append(v.kind)
    for v in L.enemy_vehicles:
        if not pr["tan"].has(v.kind):
            bad.append("tan " + v.kind)
    for id in L.pickups:
        var k: String = L.pickups[id].kind
        if (["carbine", "lmg", "shotgun", "sniper", "launcher"].has(k) and not pr["weapons"].has(k)) or (k == "drone" and not pr["drones"]):
            bad.append(k + " pickup")
    for w in p.owned:
        if not pr["weapons"].has(w):
            bad.append("starts with " + w)
    if not pr["drones"] and p.drones > 0:
        bad.append("drone strikes")
    _check(bad.is_empty(), "%s only unlocked gear %s" % [tag, str(bad)])
    _check(is_equal_approx(Game.campaign_ramp, pr["ramp"]), "%s Tan toughness x%.2f" % [tag, Game.campaign_ramp])
    var kinds := {}
    for v in L.vehicles:
        kinds[v.kind] = true
    if i == 0:
        _check(L.vehicles.is_empty(), "%s no vehicles yet on the first op" % tag)
    if i == 6:
        _check(kinds.has("heli"), "%s the helicopter arrives" % tag)
    # Nothing should start inside the scenery.
    var stuck: Array = []
    for e in L.enemies:
        if not _blocked(L, e.global_position, [e.get_rid()]).is_empty():
            stuck.append("%s@%s" % [e.type, e.global_position.snapped(Vector3.ONE)])
    _check(stuck.is_empty(), "%s no soldiers spawned inside scenery %s" % [tag, str(stuck.slice(0, 4))])
    _check(_blocked(L, p.global_position, [p.get_rid()]).is_empty(), "%s player spawn is clear" % tag)
    var bad_pk: Array = []
    for id in L.pickups:
        var pk = L.pickups[id]
        if not _blocked(L, pk.global_position, [], 0.25, 0.8).is_empty():
            bad_pk.append("%s@%s" % [pk.kind, pk.global_position.snapped(Vector3.ONE)])
    _check(bad_pk.is_empty(), "%s pickups reachable %s" % [tag, str(bad_pk.slice(0, 4))])
    var in_zone := 0
    for e in L.enemies:
        if e.global_position.distance_to(L.safe_center) < L.safe_radius + 2.0:
            in_zone += 1
    _check(in_zone == 0, "%s no Tan soldiers start in the safe zone (%d)" % [tag, in_zone])
    p.invulnerable = true
    await _frames(60)
    _check(p.is_on_floor(), "%s player on the floor at %s" % [tag, p.global_position.snapped(Vector3(0.1, 0.1, 0.1))])
    var fallen := 0
    for e in L.enemies:
        if e.global_position.y < -3.0:
            fallen += 1
    _check(fallen == 0, "%s no soldiers fell through the floor (%d)" % [tag, fallen])
    for m in L.squad:
        _check(m.global_position.distance_to(p.global_position) < 12.0 and m.global_position.y > -1.0, "%s %s deployed beside the player" % [tag, m.display_name()])
    for v in L.vehicles + L.enemy_vehicles:
        var bs := BoxShape3D.new()
        bs.size = v.k["size"] - Vector3(0.3, 0.6, 0.3)
        var q := PhysicsShapeQueryParameters3D.new()
        q.shape = bs
        q.transform = Transform3D(v.global_transform.basis, v.global_position + Vector3(0, v.k["size"].y * 0.5 + 0.3, 0))
        q.collision_mask = 1
        q.exclude = [v.get_rid()]
        var hits := []
        for h in L.get_world_3d().direct_space_state.intersect_shape(q, 4):
            if h["collider"] is StaticBody3D and h["collider"].get_script() == null:
                hits.append(h["collider"])
        if not hits.is_empty():
            _check(false, "%s %s %s starts clear of scenery at %s" % [tag, v.team, v.kind, v.global_position.snapped(Vector3.ONE)])
        if v.global_position.y < -2.0 or v.global_position.y > 4.0:
            _check(false, "%s vehicle %s sits at a sane height (%s)" % [tag, v.kind, v.global_position])

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
            "extract", "reach":
                p.global_position = o["pos"] + Vector3(0, 1.0, 0)
            "collect":
                _check(L.get_objective_text().contains("(0/"), "%s collect counter starts at 0 ('%s')" % [tag, L.get_objective_text()])
                for id in L.pickups.keys():
                    var pk = L.pickups.get(id)
                    if is_instance_valid(pk) and pk.kind == o["kind"]:
                        p.global_position = pk.global_position + Vector3(0, 0.2, 0)
                        p.velocity = Vector3.ZERO
                        await _frames(25)
                        _check(not L.pickups.has(id), "%s picked up %s #%d" % [tag, o["kind"], id])
            "defend":
                var d0 := _reserve_dist(L, o["pos"])
                _check(L.get_objective_text().contains(" s)"), "%s defend shows a countdown ('%s')" % [tag, L.get_objective_text()])
                await _frames(300)
                var d1 := _reserve_dist(L, o["pos"])
                _check(d1 < d0 - 3.0, "%s reserves attack the fort (avg %.0fm -> %.0fm)" % [tag, d0, d1])
                _check(L.obj_index == before, "%s defend doesn't finish early" % tag)
                L._obj_start = L.elapsed - o["time"]        # fast-forward the clock
        await _frames(20)
        _check(L.obj_index > before, "%s objective '%s' completed" % [tag, o["type"]])
    finished_result = null
    L.finished.connect(func(s, _st): finished_result = s, CONNECT_ONE_SHOT)
    for k in 300:
        await get_tree().physics_frame
        if finished_result != null:
            break
    _check(finished_result == true, "%s MISSION ACCOMPLISHED" % tag)
    await _frames(5)


func _reserve_dist(L, pos: Vector3) -> float:
    var sum := 0.0
    var n := 0
    for e in L.reserves:
        if is_instance_valid(e) and e.alive:
            sum += Vector2(e.global_position.x - pos.x, e.global_position.z - pos.z).length()
            n += 1
    return sum / maxf(1.0, n)
