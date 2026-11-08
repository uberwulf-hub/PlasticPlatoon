extends Node3D
## MELTDOWN: wave survival. Melties pour in through boarded windows, each wave
## bigger, tougher and faster. Hits, kills and nailing planks back up earn
## coins; coins buy guns off the walls, a mystery crate, armour, a medic, the
## Re-Mold Press (double damage) and the junk piles blocking the next rooms.

const Melty = preload("res://scripts/melty.gd")
const Barricade = preload("res://scripts/barricade.gd")
const Weapons = preload("res://scripts/weapons.gd")

const START_COINS := 500
const PLANK_COINS := 10
const PLANK_COINS_PER_WAVE := 100     # stops farming the windows
const BREAK_TIME := 9.0
const FIRST_WAVE_DELAY := 6.0
const INTERACT_RANGE := 2.4
const NAMES := {"carbine": "M4A1 CARBINE", "lmg": "M249 SAW", "shotgun": "M1014 SHOTGUN", "sniper": "MK 22 SNIPER", "launcher": "AT4 LAUNCHER"}

var level: Node
var layout: Dictionary
var coins := START_COINS
var coins_total := 0
var wave := 0
var to_spawn := 0
var alive := 0
var killed := 0
var best_wave := 0
var break_t := FIRST_WAVE_DELAY
var spawn_t := 0.0
var sections := {}                 # id -> {"name", "open"}
var barricades: Array = []
var doors: Array = []              # {"node", "cost", "opens", "label"}
var stations: Array = []           # {"node", "kind", "cost", "weapon", "label", "pos"}
var nav_region: NavigationRegion3D
var _plank_coins := 0
var _rebuild_t := 0.0
var _crate_busy := false
var _focus = null                  # what E would use right now
var _wave_hp := 50.0
var _wave_speed := 1.8
var _wave_damage := 18.0


func setup(lvl: Node, data: Dictionary) -> void:
    level = lvl
    layout = data
    name = "Meltdown"


func _ready() -> void:
    for id in layout["sections"]:
        sections[id] = {"name": layout["sections"][id], "open": id == layout["start"]}
    for w in layout["windows"]:
        var b = Barricade.new()
        b.setup(level, w[0], w[1], w[2])
        level.add_child(b)
        barricades.append(b)
    for d in layout["doors"]:
        doors.append(_build_door(d))
    for s in layout["stations"]:
        stations.append(_build_station(s))
    # The green side can't climb out through the windows.
    level.player.collision_mask |= Barricade.BLOCK_LAYER
    for m in level.squad:
        m.walk_mask |= Barricade.BLOCK_LAYER
        m.collision_mask |= Barricade.BLOCK_LAYER
    _bake_nav()


# ------------------------------------------------------------ navigation ----

func _bake_nav() -> void:
    var nm := NavigationMesh.new()
    nm.agent_radius = 0.45
    nm.agent_height = 1.7
    nm.agent_max_climb = 0.4
    nm.cell_size = 0.25
    nm.cell_height = 0.25
    nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
    nm.geometry_collision_mask = 1
    var src := NavigationMeshSourceGeometryData3D.new()
    NavigationServer3D.parse_source_geometry_data(nm, src, level)
    NavigationServer3D.bake_from_source_geometry_data(nm, src)
    if nav_region == null:
        nav_region = NavigationRegion3D.new()
        nav_region.name = "MeltdownNav"
        level.add_child(nav_region)
    nav_region.navigation_mesh = nm


# --------------------------------------------------------------- building ----

func _label(text: String, pos: Vector3, color: Color, size := 46) -> Label3D:
    var l := Label3D.new()
    l.text = text
    l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    l.font_size = size
    l.pixel_size = 0.008
    l.outline_size = 10
    l.modulate = color
    l.position = pos
    l.visibility_range_end = 30.0
    level.add_child(l)
    return l


func _solid(parent: Node3D, pos: Vector3, size: Vector3, m: Material) -> void:
    var mi := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = size
    mi.mesh = bm
    mi.material_override = m
    mi.position = pos
    parent.add_child(mi)
    var cs := CollisionShape3D.new()
    var bs := BoxShape3D.new()
    bs.size = size
    cs.shape = bs
    cs.position = pos
    parent.add_child(cs)


func _build_door(d: Dictionary) -> Dictionary:
    var body := StaticBody3D.new()
    body.collision_layer = 1
    body.position = d["pos"]
    level.add_child(body)
    var w: float = d["width"]
    var junk := [level.tex("table_wood", Color(0.75, 0.6, 0.45), 2.0), level.mat(Color(0.75, 0.6, 0.4)), level.mat(Color(0.3, 0.45, 0.75)), level.mat(Color(0.8, 0.25, 0.2))]
    _solid(body, Vector3(0, 1.4, 0), Vector3(w + 0.4, 2.8, 0.9), junk[0])            # boards across the doorway
    _solid(body, Vector3(-w * 0.25, 3.2, 0.1), Vector3(1.4, 0.9, 1.0), junk[1])       # boxes piled on top
    _solid(body, Vector3(w * 0.3, 3.1, -0.1), Vector3(1.1, 0.7, 1.1), junk[2])
    _solid(body, Vector3(0.2, 0.45, 0.8), Vector3(1.0, 0.9, 0.7), junk[3])
    var opens: String = d["opens"]
    var text := "CLEAR THE JUNK\n%s  -  %d COINS" % [sections[opens]["name"], d["cost"]]
    var lbl := _label(text, d["pos"] + Vector3(0, 4.3, 0), Color(1.0, 0.85, 0.35))
    return {"node": body, "cost": d["cost"], "opens": opens, "label": lbl, "pos": d["pos"] + Vector3(0, 1.0, 0)}


func _build_station(s: Dictionary) -> Dictionary:
    var kind: String = s["kind"]
    var facing: Vector3 = s["facing"]
    var root := StaticBody3D.new()
    root.collision_layer = 1
    root.position = s["pos"]
    root.rotation.y = atan2(facing.x, facing.z)
    level.add_child(root)
    var title := ""
    var color := Color(0.6, 1.0, 0.5)
    match kind:
        "weapon":
            title = NAMES.get(s["weapon"], s["weapon"])
            _solid(root, Vector3(0, 1.6, 0.05), Vector3(2.4, 1.3, 0.1), level.mat(Color(0.12, 0.13, 0.12)))
            # Chalk outline of the gun on the board.
            var chalk: Material = level.glow_mat(Color(0.85, 0.95, 0.8), 1.2)
            var gun := MeshInstance3D.new()
            var gm := BoxMesh.new()
            gm.size = Vector3(1.7, 0.16, 0.02)
            gun.mesh = gm
            gun.material_override = chalk
            gun.position = Vector3(0, 1.65, 0.11)
            root.add_child(gun)
            var grip := MeshInstance3D.new()
            var gr := BoxMesh.new()
            gr.size = Vector3(0.16, 0.4, 0.02)
            grip.mesh = gr
            grip.material_override = chalk
            grip.position = Vector3(-0.2, 1.42, 0.11)
            root.add_child(grip)
        "medic":
            title = "FIELD MEDIC"
            color = Color(1.0, 0.5, 0.5)
            _solid(root, Vector3(0, 1.4, 0.2), Vector3(1.2, 1.0, 0.4), level.mat(Color(0.95, 0.95, 0.95)))
            _solid(root, Vector3(0, 1.4, 0.41), Vector3(0.7, 0.2, 0.02), level.glow_mat(Color(0.9, 0.1, 0.1), 1.5))
            _solid(root, Vector3(0, 1.4, 0.41), Vector3(0.2, 0.7, 0.02), level.glow_mat(Color(0.9, 0.1, 0.1), 1.5))
        "armor":
            title = "PLATE ARMOR"
            color = Color(0.55, 0.7, 1.0)
            _solid(root, Vector3(0, 1.3, 0.25), Vector3(1.0, 1.2, 0.5), level.mat(Color(0.25, 0.35, 0.6)))
        "crate":
            title = "MYSTERY CRATE"
            color = Color(1.0, 0.9, 0.3)
            _solid(root, Vector3(0, 0.55, 0), Vector3(2.0, 1.1, 1.1), level.tex("table_wood", Color(0.8, 0.6, 0.4), 2.0))
            _solid(root, Vector3(0, 1.12, 0), Vector3(2.1, 0.06, 1.2), level.glow_mat(Color(1.0, 0.85, 0.3), 1.2))
        "press":
            title = "RE-MOLD PRESS"
            color = Color(1.0, 0.45, 0.3)
            _solid(root, Vector3(0, 0.9, 0), Vector3(2.0, 1.8, 1.6), level.mat(Color(0.35, 0.36, 0.4), 0.5, 0.6))
            _solid(root, Vector3(0, 2.2, 0), Vector3(1.2, 0.8, 1.2), level.mat(Color(0.5, 0.2, 0.15), 0.5, 0.4))
            level.lamp(s["pos"] + Vector3(0, 2.9, 0), Color(1.0, 0.35, 0.2), 6.0, 1.6)
    var front: Vector3 = s["pos"] + facing.normalized() * 0.6
    var lbl := _label("%s\n%d COINS" % [title, s["cost"]], s["pos"] + Vector3(0, 2.75, 0) + facing.normalized() * 0.3, color, 40)
    return {"node": root, "kind": kind, "cost": s["cost"], "weapon": s.get("weapon", ""), "title": title, "label": lbl, "pos": front + Vector3(0, 1.0, 0)}


# ------------------------------------------------------------------ waves ----

func _physics_process(delta: float) -> void:
    if level.ended or not level.player.alive:
        return
    _interact(delta)
    if to_spawn == 0 and alive == 0:
        break_t -= delta
        if break_t <= 0.0:
            _start_wave(wave + 1)
        return
    if to_spawn > 0:
        spawn_t -= delta
        if spawn_t <= 0.0 and alive < _max_alive():
            spawn_t = maxf(0.35, 1.8 - 0.12 * wave)
            _spawn_one()


func _max_alive() -> int:
    return mini(16 + wave, 26)


func _start_wave(n: int) -> void:
    wave = n
    best_wave = maxi(best_wave, n)
    to_spawn = 5 + 3 * n
    var hp_mult: float = [0.8, 1.0, 1.25][clampi(Game.difficulty, 0, 2)]
    _wave_hp = (45.0 + 28.0 * (n - 1) * (1.0 + 0.05 * (n - 1))) * hp_mult
    _wave_speed = minf(1.7 + 0.32 * (n - 1), 5.2)
    _wave_damage = minf(18.0 + 2.0 * (n - 1), 45.0) * Game.enemy_damage_mult()
    _plank_coins = 0
    spawn_t = 0.5
    level.notify("WAVE %d" % n, 3.0)
    Game.play_ui("objective", -2.0)


func start_wave_now() -> void:      # tests
    break_t = 0.0


func _spawn_one() -> void:
    var open: Array = barricades.filter(func(b): return sections[b.section]["open"])
    if open.is_empty():
        return
    # Mostly the windows near the player, sometimes any open one.
    var p: Vector3 = level.player.global_position
    open.sort_custom(func(a, b): return a.global_position.distance_to(p) < b.global_position.distance_to(p))
    var b = open[randi() % mini(4, open.size())] if randf() < 0.8 else open.pick_random()
    var side: Vector3 = b.normal.cross(Vector3.UP) * randf_range(-1.6, 1.6)
    var pos: Vector3 = b.global_position + b.normal * randf_range(3.2, 4.4) + side + Vector3(0, 0.3, 0)
    var spd := _wave_speed * randf_range(0.85, 1.15)
    if wave >= 4 and randf() < 0.3:
        spd *= 1.35               # a runner
    var m = Melty.new()
    m.setup(level, self, b, pos, _wave_hp, spd, _wave_damage)
    level.add_child(m)
    level.enemies.append(m)
    to_spawn -= 1
    alive += 1


func on_melty_died(m) -> void:
    alive = maxi(0, alive - 1)
    killed += 1
    level.enemies.erase(m)
    if to_spawn == 0 and alive == 0:
        break_t = BREAK_TIME
        level.notify("WAVE %d SURVIVED" % wave, 3.0)
        Game.play_ui("radio", -6.0)


## Who a Melty goes for: the closest green soldier on foot.
func nearest_prey(pos: Vector3):
    var best = null
    var bd := INF
    var cands: Array = []
    if level.player.alive:
        cands.append(level.player.vehicle if level.player.vehicle != null else level.player)
    for m in level.squad:
        if m.alive and m.ride == null:
            cands.append(m)
    for c in cands:
        var d: float = c.global_position.distance_to(pos)
        if d < bd:
            bd = d
            best = c
    return best


# ------------------------------------------------------------------ coins ----

## Coins only come from the player's own shots and explosives.
func is_player_damage(source: Vector3, explosive: bool) -> bool:
    if explosive:
        return true
    return source.distance_to(level.player.global_position) < 1.0


func award(amount: int, pos: Vector3, _kill: bool) -> void:
    coins += amount
    coins_total += amount
    var l := Label3D.new()
    l.text = "+%d" % amount
    l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    l.no_depth_test = true
    l.font_size = 52 if amount >= 60 else 36
    l.pixel_size = 0.008
    l.outline_size = 10
    l.modulate = Color(1.0, 0.85, 0.25)
    l.position = pos
    level.add_child(l)
    var tw := l.create_tween()
    tw.set_parallel(true)
    tw.tween_property(l, "position", pos + Vector3(0, 1.4, 0), 0.9)
    tw.tween_property(l, "modulate:a", 0.0, 0.9).set_delay(0.3)
    tw.chain().tween_callback(l.queue_free)


func _spend(cost: int) -> bool:
    if coins < cost:
        level.notify("NOT ENOUGH COINS  (%d / %d)" % [coins, cost], 1.4)
        Game.play_ui("ui_error", -4.0)
        return false
    coins -= cost
    Game.play_ui("ui_confirm", -4.0)
    return true


# ------------------------------------------------------------ interaction ----

func _interact(delta: float) -> void:
    var p = level.player
    _focus = null
    if p.vehicle != null:
        return
    var best_d := INTERACT_RANGE
    for d in doors:
        var dd: float = d["pos"].distance_to(p.global_position + Vector3(0, 1, 0))
        if dd < best_d + 1.0:
            best_d = dd
            _focus = d
    for s in stations:
        var ds: float = s["pos"].distance_to(p.global_position + Vector3(0, 1, 0))
        if ds < best_d:
            best_d = ds
            _focus = s
    for b in barricades:
        var db: float = b.inside_point.distance_to(p.global_position)
        if db < 2.6 and b.planks < Barricade.PLANKS and db < best_d + 0.5:
            best_d = db
            _focus = b
    # Hold E to nail planks back on; tap E for everything else.
    if _focus is Node and _focus.get("planks") != null:
        if Input.is_action_pressed("interact"):
            _rebuild_t -= delta
            if _rebuild_t <= 0.0:
                _rebuild_t = 0.75
                if _focus.rebuild() and _plank_coins < PLANK_COINS_PER_WAVE:
                    _plank_coins += PLANK_COINS
                    award(PLANK_COINS, _focus.global_position + Vector3(0, 2.4, 0), false)
        else:
            _rebuild_t = 0.0
    elif _focus != null and Input.is_action_just_pressed("interact"):
        use(_focus)


## Buys / uses a door or station dictionary (also called by tests).
func use(f) -> bool:
    if f.has("opens"):
        return _open_door(f)
    var p = level.player
    match f["kind"]:
        "weapon":
            var id: String = f["weapon"]
            if p.owned.has(id):
                var cost := int(f["cost"] / 2)
                var cap := int(Weapons.DATA[id]["reserve"] * 1.5)
                if p.reserve[id] >= cap:
                    level.notify("%s AMMO IS FULL" % NAMES[id], 1.2)
                    return false
                if not _spend(cost):
                    return false
                p.reserve[id] = cap
                p.mag[id] = Weapons.DATA[id]["mag"]
                level.notify("%s AMMO REFILLED" % NAMES[id], 1.6)
                return true
            if not _spend(f["cost"]):
                return false
            p.give_pickup(id)
            level.notify("BOUGHT THE %s" % NAMES[id], 1.8)
            return true
        "medic":
            if p.health >= p.max_health:
                level.notify("YOU'RE ALREADY PATCHED UP", 1.2)
                return false
            if not _spend(f["cost"]):
                return false
            p.health = p.max_health
            level.notify("HEALTH RESTORED", 1.4)
            return true
        "armor":
            if p.armor >= p.max_armor:
                level.notify("ARMOR IS FULL", 1.2)
                return false
            if not _spend(f["cost"]):
                return false
            p.armor = p.max_armor
            level.notify("PLATE ARMOR ON", 1.4)
            return true
        "crate":
            if _crate_busy or not _spend(f["cost"]):
                return false
            _open_crate(f)
            return true
        "press":
            var cur: String = p.current
            if p.dmg_mult.get(cur, 1.0) > 1.0:
                level.notify("YOUR %s IS ALREADY RE-MOLDED" % NAMES[cur], 1.6)
                return false
            if not _spend(f["cost"]):
                return false
            p.dmg_mult[cur] = 2.0
            p.mag[cur] = Weapons.DATA[cur]["mag"]
            p.reserve[cur] = int(Weapons.DATA[cur]["reserve"] * 1.5)
            level.notify("%s RE-MOLDED: DOUBLE DAMAGE" % NAMES[cur], 2.5)
            Game.play_sfx("explosion", f["pos"], -10.0)
            return true
    return false


func _open_door(d: Dictionary) -> bool:
    if not is_instance_valid(d["node"]) or not _spend(d["cost"]):
        return false
    sections[d["opens"]]["open"] = true
    d["node"].queue_free()
    d["label"].queue_free()
    doors.erase(d)
    level.notify("THE %s IS OPEN" % sections[d["opens"]]["name"], 2.5)
    Game.play_sfx("explosion", d["pos"], -8.0)
    get_tree().create_timer(0.1).timeout.connect(_bake_nav)    # once the junk is gone
    return true


func _open_crate(f: Dictionary) -> void:
    _crate_busy = true
    var lbl: Label3D = f["label"]
    var keys: Array = NAMES.keys()
    for i in 12:
        lbl.text = "MYSTERY CRATE\n" + NAMES[keys[i % keys.size()]]
        Game.play_ui("blip", -12.0)
        await get_tree().create_timer(0.12).timeout
        if not is_instance_valid(lbl):
            return
    var p = level.player
    var choices: Array = keys.filter(func(k): return k != p.current)
    var got: String = choices.pick_random()
    if p.owned.has(got):
        p.reserve[got] = int(Weapons.DATA[got]["reserve"] * 1.5)
        p.mag[got] = Weapons.DATA[got]["mag"]
        p._equip(got)
    else:
        p.give_pickup(got)
    lbl.text = "MYSTERY CRATE\n%s!" % NAMES[got]
    level.notify("THE CRATE GAVE YOU THE %s" % NAMES[got], 2.0)
    await get_tree().create_timer(1.6).timeout
    if is_instance_valid(lbl):
        lbl.text = "%s\n%d COINS" % [f["title"], f["cost"]]
    _crate_busy = false


# -------------------------------------------------------------------- HUD ----

func info_text() -> String:
    var left := to_spawn + alive
    return "WAVE %d\nMELTIES %d\nCOINS %d" % [wave, left, coins]


func objective_text() -> String:
    if wave == 0:
        return "Get ready - the Melties are coming  (%d s)" % int(ceil(break_t))
    if to_spawn == 0 and alive == 0:
        return "Wave %d survived - next wave in %d s" % [wave, int(ceil(break_t))]
    return "Survive wave %d" % wave


func prompt_text() -> String:
    if _focus == null:
        return ""
    if _focus is Node:
        return "Hold E to nail the boards back up  (+%d coins each)" % PLANK_COINS if _plank_coins < PLANK_COINS_PER_WAVE else "Hold E to nail the boards back up"
    if _focus.has("opens"):
        return "Press E to clear the junk into the %s  -  %d coins" % [sections[_focus["opens"]]["name"], _focus["cost"]]
    var f: Dictionary = _focus
    if f["kind"] == "weapon" and level.player.owned.has(f["weapon"]):
        return "Press E for %s ammo  -  %d coins" % [NAMES[f["weapon"]], int(f["cost"] / 2)]
    if f["kind"] == "press":
        return "Press E to re-mold your %s for double damage  -  %d coins" % [NAMES.get(level.player.current, ""), f["cost"]]
    return "Press E to buy the %s  -  %d coins" % [f["title"], f["cost"]]
