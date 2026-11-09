extends RefCounted
## MELTDOWN mode maps. A builder places the geometry through the Level API and
## returns the settings dictionary plus a "meltdown" layout (sections, doors,
## boarded windows and buy stations) that the Meltdown controller brings to life.

const META := [
    {
        "name": "The Basement",
        "location": "Under the house - where the broken toys go",
        "briefing": "Something went wrong with General Beige's paint. The Tan soldiers it touched came back... melted. And hungry for green plastic.\n\nHold the toy shelf. Board up the windows, earn coins for every hit and every Melty, buy guns off the walls, and save up to clear the junk into the workshop and the boiler room. Every wave is worse than the last.",
        "blurb": "Hold the toy shelf, then fight through the workshop to the boiler room.",
    },
    {
        "name": "The Attic",
        "location": "Up the pull-down ladder - nobody has been up here in years",
        "briefing": "The Melties have found the attic. Dust, rafters, a chimney and a toy chest that hasn't been opened since the nineties.",
        "blurb": "Dusty storage corner, a wide room under the rafters, and the toy chest loft.",
    },
    {
        "name": "The Garden Shed",
        "location": "The back garden - after dark",
        "briefing": "Melties are crawling out of the flower beds. Barricade the potting shed, push through the glass greenhouse and make a last stand by the compost bins.",
        "blurb": "Moonlit potting shed, a glass greenhouse, and the compost corner.",
    },
    {
        "name": "Toy Store After Hours",
        "location": "The mall toy store - closing time",
        "briefing": "The shop's shut, the lights are humming, and something tan is scratching at the front windows. Hold the checkout, fight down the action-figure aisle, and hole up in the stockroom.",
        "blurb": "Checkout counters, shelving aisles to hide behind, and the stockroom out back.",
    },
]


static func build(i: int, L) -> Dictionary:
    var d: Dictionary
    match i:
        1:
            d = _attic(L)
        2:
            d = _garden(L)
        3:
            d = _toystore(L)
        _:
            d = _basement(L)
    d["name"] = META[clampi(i, 0, META.size() - 1)]["name"]
    d["mode"] = "meltdown"
    return d


## A wall along X (constant z) from x0 to x1 with window/door gaps [centre, width].
static func _wall_x(L, z: float, x0: float, x1: float, gaps: Array, h: float, m: Material) -> void:
    var cuts: Array = [[x0, x0]]
    for g in gaps:
        cuts.append([g[0] - g[1] * 0.5, g[0] + g[1] * 0.5])
    cuts.append([x1, x1])
    cuts.sort_custom(func(a, b): return a[0] < b[0])
    for k in cuts.size() - 1:
        var a: float = cuts[k][1]
        var b: float = cuts[k + 1][0]
        if b - a > 0.05:
            L.box(Vector3((a + b) * 0.5, h * 0.5, z), Vector3(b - a, h, 0.8), Color.GRAY, 0.0, true, m)


static func _wall_z(L, x: float, z0: float, z1: float, gaps: Array, h: float, m: Material) -> void:
    var cuts: Array = [[z0, z0]]
    for g in gaps:
        cuts.append([g[0] - g[1] * 0.5, g[0] + g[1] * 0.5])
    cuts.append([z1, z1])
    cuts.sort_custom(func(a, b): return a[0] < b[0])
    for k in cuts.size() - 1:
        var a: float = cuts[k][1]
        var b: float = cuts[k + 1][0]
        if b - a > 0.05:
            L.box(Vector3(x, h * 0.5, (a + b) * 0.5), Vector3(0.8, h, b - a), Color.GRAY, 0.0, true, m)


# ===================================================== THE BASEMENT ====
# Three rooms in a row, north (-z) from the start:
#   A  Toy Shelf    z  16..40   (start)
#   B  Workshop     z -14..16   (junk pile at z=16, 750 coins)
#   C  Boiler Room  z -40..-14  (junk pile at z=-14, 1250 coins)
# A 6 m crawlspace runs all the way round outside, where the Melties gather.

static func _basement(L) -> Dictionary:
    var floor_m = L.tex("concrete", Color(0.75, 0.74, 0.72), 9.0)
    L.box(Vector3(0, -0.5, 0), Vector3(60, 1, 110), Color(0.4, 0.4, 0.4), 0.0, true, floor_m)
    # Dirt in the crawlspace outside the rooms.
    for s in [-1.0, 1.0]:
        L.box(Vector3(19 * s, 0.02, 0), Vector3(5.6, 0.04, 92), Color(0.3, 0.25, 0.2), 0.0, false, L.tex("forest", Color(0.55, 0.5, 0.45), 6.0))
        L.box(Vector3(0, 0.02, 43 * s), Vector3(44, 0.04, 5.6), Color(0.3, 0.25, 0.2), 0.0, false, L.tex("forest", Color(0.55, 0.5, 0.45), 6.0))
    L.bounds(22, 46)
    # The house's foundation walls round the crawlspace (tall, so it feels underground).
    var stone = L.tex("rock", Color(0.8, 0.78, 0.75), 8.0)
    for s in [-1.0, 1.0]:
        L.box(Vector3(23 * s, 6, 0), Vector3(2, 12, 96), Color.GRAY, 0.0, false, stone)
        L.box(Vector3(0, 6, 47 * s), Vector3(48, 12, 2), Color.GRAY, 0.0, false, stone)

    var H := 5.0
    var wall = L.tex("plaster", Color(0.95, 0.95, 0.9), 5.0)
    var GAP := 2.4
    _wall_x(L, 40, -16, 16, [[-8, GAP], [8, GAP]], H, wall)                         # south (A)
    _wall_x(L, -40, -16, 16, [[0, GAP]], H, wall)                                    # north (C)
    _wall_z(L, -16, -40, 40, [[26, GAP], [2, GAP], [-28, GAP]], H, wall)             # west
    _wall_z(L, 16, -40, 40, [[32, GAP], [-6, GAP], [-24, GAP]], H, wall)             # east
    _wall_x(L, 16, -16, 16, [[0, 4.2]], H, wall)                                     # A | B
    _wall_x(L, -14, -16, 16, [[8, 4.2]], H, wall)                                    # B | C
    # Bare bulbs and a dim, dusty gloom.
    for p in [Vector3(-7, 4.4, 33), Vector3(7, 4.4, 23), Vector3(-8, 4.4, 8), Vector3(8, 4.4, -6),
            Vector3(-7, 4.4, -22), Vector3(7, 4.4, -34)]:
        L.lamp(p, Color(1.0, 0.82, 0.6), 20.0, 3.2)
    for p in [Vector3(-19, 3.5, 26), Vector3(19, 3.5, -6), Vector3(0, 3.5, -43)]:
        L.lamp(p, Color(0.5, 0.7, 1.0), 9.0, 0.8, false)

    # --- A: the toy shelf ---
    var shelf_m = L.tex("table_wood", Color(0.8, 0.7, 0.6), 4.0)
    for z in [22.0, 30.0]:
        L.box(Vector3(-9, 0.9, z), Vector3(5, 1.8, 1.2), Color.BROWN, 0.0, true, shelf_m)
        L.box(Vector3(-9, 2.1, z), Vector3(4.6, 0.6, 1.0), Color(0.85, 0.25, 0.2))
    L.box(Vector3(9, 0.6, 26), Vector3(2.5, 1.2, 2.5), Color(0.2, 0.45, 0.85), 0.4)
    L.box(Vector3(10, 0.5, 21), Vector3(1.8, 1.0, 1.8), Color(0.95, 0.8, 0.2), -0.3)
    # --- B: the workshop ---
    L.box(Vector3(-8, 0.9, -6), Vector3(6, 0.2, 2.4), Color.BROWN, 0.0, true, shelf_m)
    for x in [-10.6, -5.4]:
        L.box(Vector3(x, 0.4, -6), Vector3(0.3, 0.8, 2.2), Color(0.3, 0.25, 0.2))
    L.box(Vector3(9, 0.75, 9), Vector3(2.0, 1.5, 3.0), Color(0.7, 0.55, 0.35))
    L.box(Vector3(-11, 0.6, 10), Vector3(1.6, 1.2, 1.6), Color(0.7, 0.55, 0.35), 0.5)
    # --- C: the boiler room ---
    L.cyl(Vector3(-8, 2.0, -34), 2.4, 4.0, Color(0.45, 0.4, 0.38), true, Vector3.ZERO, L.mat(Color(0.45, 0.4, 0.38), 0.4, 0.6))
    L.lamp(Vector3(-8, 0.8, -31.4), Color(1.0, 0.4, 0.1), 7.0, 2.5)                  # furnace glow
    L.cyl(Vector3(-8, 4.6, -27), 0.3, 14.0, Color(0.5, 0.45, 0.4), false, Vector3(PI / 2, 0, 0))
    L.box(Vector3(10, 0.8, -32), Vector3(3, 1.6, 2), Color(0.35, 0.35, 0.38))

    return {
        "spawn": Vector3(0, 0.5, 32), "spawn_yaw": PI, "drones": 0, "safe_radius": 0.0,
        "start_weapons": ["carbine"],
        "sky_top": Color(0.08, 0.08, 0.1), "sky_horizon": Color(0.16, 0.14, 0.13),
        "sun_color": Color(0.6, 0.6, 0.75), "sun_energy": 0.3, "sun_rot": Vector3(-70, 30, 0),
        "fog": 0.015, "ambient": 1.0, "exposure": 1.3,
        "music": "res://assets/audio/music/determined_pursuit.ogg", "ambience": "res://assets/audio/ambience/clock_tick.ogg", "ambience_db": -14.0,
        "objectives": [],
        "meltdown": {
            "start": "A",
            "sections": {"A": "TOY SHELF", "B": "WORKSHOP", "C": "BOILER ROOM"},
            "windows": [
                [Vector3(-8, 0, 40), Vector3(0, 0, 1), "A"], [Vector3(8, 0, 40), Vector3(0, 0, 1), "A"],
                [Vector3(-16, 0, 26), Vector3(-1, 0, 0), "A"], [Vector3(16, 0, 32), Vector3(1, 0, 0), "A"],
                [Vector3(-16, 0, 2), Vector3(-1, 0, 0), "B"], [Vector3(16, 0, -6), Vector3(1, 0, 0), "B"],
                [Vector3(-16, 0, -28), Vector3(-1, 0, 0), "C"], [Vector3(16, 0, -24), Vector3(1, 0, 0), "C"],
                [Vector3(0, 0, -40), Vector3(0, 0, -1), "C"],
            ],
            "doors": [
                {"pos": Vector3(0, 0, 16), "width": 4.2, "cost": 750, "opens": "B"},
                {"pos": Vector3(8, 0, -14), "width": 4.2, "cost": 1250, "opens": "C"},
            ],
            # pos = on the wall face (or free-standing); facing = into the room.
            "stations": [
                {"kind": "weapon", "weapon": "shotgun", "cost": 500, "pos": Vector3(-15.55, 0, 34), "facing": Vector3(1, 0, 0)},
                {"kind": "medic", "cost": 300, "pos": Vector3(15.55, 0, 22), "facing": Vector3(-1, 0, 0)},
                {"kind": "weapon", "weapon": "lmg", "cost": 1250, "pos": Vector3(15.55, 0, 6), "facing": Vector3(-1, 0, 0)},
                {"kind": "weapon", "weapon": "sniper", "cost": 1000, "pos": Vector3(-15.55, 0, -8), "facing": Vector3(1, 0, 0)},
                {"kind": "armor", "cost": 400, "pos": Vector3(-15.55, 0, 10), "facing": Vector3(1, 0, 0)},
                {"kind": "crate", "cost": 950, "pos": Vector3(2, 0, -8), "facing": Vector3(0, 0, 1)},
                {"kind": "weapon", "weapon": "launcher", "cost": 2000, "pos": Vector3(-15.55, 0, -20), "facing": Vector3(1, 0, 0)},
                {"kind": "press", "cost": 3000, "pos": Vector3(4, 0, -34), "facing": Vector3(0, 0, 1)},
            ],
        },
    }


# ================================================== shared map helpers ====

## A row of rooms from south (+z) to north (-z). Each room is a dictionary:
##   id, x0, x1, z0 (north edge), z1 (south edge),
##   win_s / win_n: window x positions on the south / north wall (outer walls only),
##   win_w / win_e: window z positions on the west / east wall,
##   door_x, door_cost: the junk pile in the north wall that opens the next room.
## Rooms may differ in width; neighbours share the wall between them.
## Returns {"windows": [...], "doors": [...]} for the layout dictionary.
static func _rooms(L, rooms: Array, H: float, wall_m: Material, room_walls := {}) -> Dictionary:
    var GAP := 2.4
    var windows: Array = []
    var doors: Array = []
    var first: Dictionary = rooms[0]
    _wall_x(L, first["z1"], first["x0"], first["x1"], first.get("win_s", []).map(func(x): return [x, GAP]), H, room_walls.get(first["id"], wall_m))
    for x in first.get("win_s", []):
        windows.append([Vector3(x, 0, first["z1"]), Vector3(0, 0, 1), first["id"]])
    for k in rooms.size():
        var r: Dictionary = rooms[k]
        var m: Material = room_walls.get(r["id"], wall_m)
        _wall_z(L, r["x0"], r["z0"], r["z1"], r.get("win_w", []).map(func(z): return [z, GAP]), H, m)
        _wall_z(L, r["x1"], r["z0"], r["z1"], r.get("win_e", []).map(func(z): return [z, GAP]), H, m)
        for z in r.get("win_w", []):
            windows.append([Vector3(r["x0"], 0, z), Vector3(-1, 0, 0), r["id"]])
        for z in r.get("win_e", []):
            windows.append([Vector3(r["x1"], 0, z), Vector3(1, 0, 0), r["id"]])
        if k + 1 < rooms.size():
            var nxt: Dictionary = rooms[k + 1]
            var x0: float = minf(r["x0"], nxt["x0"])
            var x1: float = maxf(r["x1"], nxt["x1"])
            _wall_x(L, r["z0"], x0, x1, [[r["door_x"], 4.2]], H, m)
            doors.append({"pos": Vector3(r["door_x"], 0, r["z0"]), "width": 4.2, "cost": r["door_cost"], "opens": nxt["id"]})
        else:
            _wall_x(L, r["z0"], r["x0"], r["x1"], r.get("win_n", []).map(func(x): return [x, GAP]), H, m)
            for x in r.get("win_n", []):
                windows.append([Vector3(x, 0, r["z0"]), Vector3(0, 0, -1), r["id"]])
    return {"windows": windows, "doors": doors}


## Floor for the whole map (outside material) plus a floor per room.
static func _floors(L, rooms: Array, outside: Material, half_x: float, half_z: float, room_floors: Dictionary) -> void:
    L.box(Vector3(0, -0.5, 0), Vector3(half_x * 2 + 20, 1, half_z * 2 + 20), Color.GRAY, 0.0, true, outside)
    for r in rooms:
        if room_floors.has(r["id"]):
            var w: float = r["x1"] - r["x0"]
            var d: float = r["z1"] - r["z0"]
            L.box(Vector3((r["x0"] + r["x1"]) * 0.5, 0.02, (r["z0"] + r["z1"]) * 0.5), Vector3(w, 0.04, d), Color.GRAY, 0.0, false, room_floors[r["id"]])


static func _glass(L) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = Color(0.7, 0.9, 0.85, 0.28)
    m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    m.roughness = 0.05
    m.metallic = 0.2
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    return m


# ======================================================== THE ATTIC ====
#   A  Storage Corner   z  14..36
#   B  Rafters          z -12..14   (wide; 750)
#   C  Toy Chest Loft   z -36..-12  (1500)

static func _attic(L) -> Dictionary:
    var rooms := [
        {"id": "A", "x0": -14, "x1": 14, "z0": 14, "z1": 36, "win_s": [-7, 7], "win_w": [25], "win_e": [20], "door_x": 0, "door_cost": 750},
        {"id": "B", "x0": -20, "x1": 20, "z0": -12, "z1": 14, "win_w": [6, -6], "win_e": [0], "door_x": -8, "door_cost": 1500},
        {"id": "C", "x0": -12, "x1": 12, "z0": -36, "z1": -12, "win_w": [-24], "win_e": [-30], "win_n": [0]},
    ]
    var floor_m = L.tex("wood_floor", Color(0.85, 0.75, 0.62), 10.0)
    _floors(L, rooms, L.tex("carpet", Color(1.25, 0.7, 0.75), 3.0), 26, 42, {"A": floor_m, "B": floor_m, "C": floor_m})
    L.bounds(26, 42)
    var lay := _rooms(L, rooms, 4.6, L.tex("table_wood", Color(0.8, 0.68, 0.55), 4.0))
    # Roof: sloping rafters and the ridge beam (overhead, decorative).
    var beam = L.tex("table_wood", Color(0.55, 0.42, 0.32), 3.0)
    for z in range(-40, 44, 6):
        for s in [-1.0, 1.0]:
            L.box_rot(Vector3(13.0 * s, 8.5, z), Vector3(30.0, 0.5, 0.5), Color.BROWN, Vector3(0, 0, deg_to_rad(28) * -s), false, beam)
    L.box(Vector3(0, 15.5, 0), Vector3(0.7, 0.7, 86), Color.BROWN, 0.0, false, beam)
    L.box(Vector3(0, 11, -40), Vector3(60, 22, 1), Color.BROWN, 0.0, false, beam)
    L.box(Vector3(0, 11, 40), Vector3(60, 22, 1), Color.BROWN, 0.0, false, beam)
    # Dusty light from the gable vents, plus bare bulbs.
    for p in [Vector3(-6, 4.2, 30), Vector3(6, 4.2, 20), Vector3(-10, 4.2, 4), Vector3(10, 4.2, -6), Vector3(0, 4.2, -26)]:
        L.lamp(p, Color(1.0, 0.85, 0.6), 18.0, 3.0)
    L.lamp(Vector3(0, 12, 39), Color(0.75, 0.8, 1.0), 30.0, 1.4, false)
    # Junk the family put up here.
    var card := Color(0.7, 0.55, 0.35)
    for b in [[Vector3(-10, 0, 32), 2.4], [Vector3(-10, 2.4, 32), 1.6], [Vector3(9, 0, 30.5), 2.0], [Vector3(-3, 0, 18.5), 1.8]]:
        L.box(b[0] + Vector3(0, b[1] * 0.5, 0), Vector3(b[1], b[1], b[1]), card)
    L.box(Vector3(14, 0.8, 4), Vector3(2.4, 1.6, 4.0), Color(0.45, 0.3, 0.2), 0.0, true, beam)          # old trunk
    L.cyl(Vector3(-12, 2.3, -8), 1.1, 4.6, Color(0.6, 0.3, 0.25))                                       # brick chimney
    L.box(Vector3(-6, 1.0, -30), Vector3(5.0, 2.0, 2.6), Color(0.75, 0.3, 0.25), 0.0, true, L.tex("table_wood", Color(1.1, 0.6, 0.5), 3.0))  # toy chest
    L.box(Vector3(-6, 2.1, -31.1), Vector3(5.0, 0.3, 0.6), Color(0.6, 0.2, 0.15))
    L.box(Vector3(6, 0.9, -18), Vector3(1.0, 1.8, 3.0), Color(0.85, 0.85, 0.8), 0.4)                   # rocking horse-ish
    return {
        "spawn": Vector3(0, 0.5, 27), "spawn_yaw": 0.0, "drones": 0, "safe_radius": 0.0,
        "start_weapons": ["carbine"],
        "sky_top": Color(0.1, 0.09, 0.08), "sky_horizon": Color(0.2, 0.17, 0.14),
        "sun_color": Color(0.9, 0.8, 0.65), "sun_energy": 0.25, "sun_rot": Vector3(-60, 20, 0),
        "fog": 0.018, "ambient": 1.0, "exposure": 1.25,
        "music": "res://assets/audio/music/determined_pursuit.ogg", "ambience": "res://assets/audio/ambience/clock_tick.ogg", "ambience_db": -16.0,
        "objectives": [],
        "meltdown": {
            "start": "A",
            "sections": {"A": "STORAGE CORNER", "B": "RAFTERS", "C": "TOY CHEST LOFT"},
            "windows": lay["windows"], "doors": lay["doors"],
            "stations": [
                {"kind": "weapon", "weapon": "shotgun", "cost": 500, "pos": Vector3(-13.55, 0, 31), "facing": Vector3(1, 0, 0)},
                {"kind": "medic", "cost": 300, "pos": Vector3(13.55, 0, 30), "facing": Vector3(-1, 0, 0)},
                {"kind": "weapon", "weapon": "lmg", "cost": 1250, "pos": Vector3(19.55, 0, 8), "facing": Vector3(-1, 0, 0)},
                {"kind": "weapon", "weapon": "sniper", "cost": 1000, "pos": Vector3(19.55, 0, -7), "facing": Vector3(-1, 0, 0)},
                {"kind": "armor", "cost": 400, "pos": Vector3(-19.55, 0, 0), "facing": Vector3(1, 0, 0)},
                {"kind": "crate", "cost": 950, "pos": Vector3(6, 0, -3), "facing": Vector3(0, 0, 1)},
                {"kind": "weapon", "weapon": "launcher", "cost": 2000, "pos": Vector3(-11.55, 0, -19), "facing": Vector3(1, 0, 0)},
                {"kind": "press", "cost": 3000, "pos": Vector3(5, 0, -29), "facing": Vector3(0, 0, 1)},
            ],
        },
    }


# =================================================== THE GARDEN SHED ====
#   A  Potting Shed     z  16..38
#   B  Greenhouse       z -10..16   (glass walls; 750)
#   C  Compost Corner   z -38..-10  (1250)

static func _garden(L) -> Dictionary:
    var rooms := [
        {"id": "A", "x0": -12, "x1": 12, "z0": 16, "z1": 38, "win_s": [0], "win_w": [27], "win_e": [22, 33], "door_x": 4, "door_cost": 750},
        {"id": "B", "x0": -18, "x1": 18, "z0": -10, "z1": 16, "win_w": [8, -4], "win_e": [2], "door_x": -6, "door_cost": 1250},
        {"id": "C", "x0": -16, "x1": 16, "z0": -38, "z1": -10, "win_w": [-24], "win_e": [-30], "win_n": [-6, 8]},
    ]
    _floors(L, rooms, L.tex("grass", Color(0.75, 0.85, 0.7), 6.0), 24, 44,
        {"A": L.tex("table_wood", Color(0.7, 0.6, 0.5), 5.0), "B": L.tex("tiles", Color(0.75, 0.8, 0.75), 6.0), "C": L.tex("forest", Color(0.7, 0.62, 0.55), 5.0)})
    L.bounds(24, 44)
    var lay := _rooms(L, rooms, 4.4, L.tex("table_wood", Color(0.62, 0.72, 0.55), 4.0),
        {"B": _glass(L), "C": L.tex("rock", Color(1.3, 1.25, 1.2), 5.0)})
    # Greenhouse frame + benches of seedlings.
    var frame: Material = L.mat(Color(0.85, 0.88, 0.85), 0.4, 0.5)
    for z in [-10.0, -3.5, 3.0, 9.5, 16.0]:
        for x in [-18.0, 18.0]:
            L.box(Vector3(x, 2.2, z), Vector3(0.25, 4.4, 0.25), Color.WHITE, 0.0, false, frame)
    for p in [Vector3(-9, 0, 6), Vector3(9, 0, -4)]:
        L.box(p + Vector3(0, 0.9, 0), Vector3(6, 0.2, 2.2), Color.BROWN, 0.0, true, L.tex("table_wood", Color(0.8, 0.7, 0.55), 3.0))
        for k in 4:
            var pp: Vector3 = p + Vector3(-2.2 + k * 1.5, 1.0, 0)
            L.cyl(pp + Vector3(0, 0.35, 0), 0.4, 0.7, Color(0.75, 0.4, 0.25), false, Vector3.ZERO, null, 0.5)
            L.prop("kenney_nature/plant_bushSmall.glb", pp + Vector3(0, 0.7, 0), k * 1.3, Vector3(0, 0.9, 0), false)
    # Potting shed: workbench, pots, a lantern.
    L.box(Vector3(-8, 0.95, 20), Vector3(5, 0.2, 2), Color.BROWN, 0.0, true, L.tex("table_wood", Color(0.75, 0.6, 0.45), 3.0))
    for x in [-10.2, -5.8]:
        L.box(Vector3(x, 0.45, 20), Vector3(0.3, 0.9, 1.8), Color(0.35, 0.25, 0.2))
    for p in [Vector3(7, 0, 36), Vector3(8.4, 0, 35.2), Vector3(-4, 0, 36.5)]:
        L.cyl(p + Vector3(0, 0.45, 0), 0.6, 0.9, Color(0.75, 0.4, 0.25), true, Vector3.ZERO, null, 0.7)
    # Compost bins + a wheelbarrow.
    for z in [-33.0, -28.6]:            # along the west wall, clear of the windows
        L.box(Vector3(-13, 0.9, z), Vector3(4.2, 1.8, 3.6), Color(0.35, 0.25, 0.18), 0.0, true, L.tex("table_wood", Color(0.55, 0.45, 0.35), 2.5))
    L.box_rot(Vector3(10, 0.6, -16), Vector3(1.6, 0.8, 2.6), Color(0.2, 0.45, 0.25), Vector3(0.1, 0.5, 0))
    for p in [Vector3(-5, 3.9, 30), Vector3(6, 3.9, 22), Vector3(-10, 3.9, 0), Vector3(10, 3.9, 8), Vector3(0, 3.9, -24)]:
        L.lamp(p, Color(1.0, 0.8, 0.5), 18.0, 2.8)
    L.lamp(Vector3(0, 30, 0), Color(0.6, 0.7, 1.0), 120.0, 0.6, false)     # moonlight wash
    # The garden fence round the yard.
    var fence = L.tex("table_wood", Color(0.65, 0.55, 0.45), 4.0)
    for s in [-1.0, 1.0]:
        L.box(Vector3(26 * s, 2.5, 0), Vector3(1.0, 5, 92), Color.BROWN, 0.0, false, fence)
        L.box(Vector3(0, 2.5, 46 * s), Vector3(54, 5, 1.0), Color.BROWN, 0.0, false, fence)
    return {
        "spawn": Vector3(0, 0.5, 30), "spawn_yaw": 0.0, "drones": 0, "safe_radius": 0.0,
        "start_weapons": ["carbine"],
        "sky_top": Color(0.03, 0.05, 0.12), "sky_horizon": Color(0.12, 0.15, 0.25),
        "sun_color": Color(0.6, 0.7, 1.0), "sun_energy": 0.4, "sun_rot": Vector3(-50, 140, 0),
        "fog": 0.012, "ambient": 0.9, "exposure": 1.3, "snow": false,
        "music": "res://assets/audio/music/determined_pursuit.ogg", "ambience": "res://assets/audio/ambience/desert_wind.ogg", "ambience_db": -18.0,
        "objectives": [],
        "meltdown": {
            "start": "A",
            "sections": {"A": "POTTING SHED", "B": "GREENHOUSE", "C": "COMPOST CORNER"},
            "windows": lay["windows"], "doors": lay["doors"],
            "stations": [
                {"kind": "weapon", "weapon": "shotgun", "cost": 500, "pos": Vector3(-11.55, 0, 33), "facing": Vector3(1, 0, 0)},
                {"kind": "medic", "cost": 300, "pos": Vector3(11.55, 0, 28), "facing": Vector3(-1, 0, 0)},
                {"kind": "weapon", "weapon": "sniper", "cost": 1000, "pos": Vector3(-17.55, 0, 2), "facing": Vector3(1, 0, 0)},
                {"kind": "weapon", "weapon": "lmg", "cost": 1250, "pos": Vector3(17.55, 0, 10), "facing": Vector3(-1, 0, 0)},
                {"kind": "armor", "cost": 400, "pos": Vector3(17.55, 0, -5), "facing": Vector3(-1, 0, 0)},
                {"kind": "crate", "cost": 950, "pos": Vector3(-2, 0, 1), "facing": Vector3(0, 0, 1)},
                {"kind": "weapon", "weapon": "launcher", "cost": 2000, "pos": Vector3(15.55, 0, -20), "facing": Vector3(-1, 0, 0)},
                {"kind": "press", "cost": 3000, "pos": Vector3(4, 0, -30), "facing": Vector3(0, 0, 1)},
            ],
        },
    }


# ============================================== TOY STORE AFTER HOURS ====
#   A  Checkout              z  18..40
#   B  Action Figure Aisle   z -14..18   (shelving rows; 1000)
#   C  Stockroom             z -40..-14  (1250)

static func _toystore(L) -> Dictionary:
    var rooms := [
        {"id": "A", "x0": -18, "x1": 18, "z0": 18, "z1": 40, "win_s": [-10, 10], "win_w": [29], "win_e": [29], "door_x": 0, "door_cost": 1000},
        {"id": "B", "x0": -18, "x1": 18, "z0": -14, "z1": 18, "win_w": [2], "win_e": [-6], "door_x": 10, "door_cost": 1250},
        {"id": "C", "x0": -14, "x1": 14, "z0": -40, "z1": -14, "win_w": [-26], "win_e": [-34], "win_n": [0]},
    ]
    var tiles = L.tex("tiles", Color(0.95, 0.95, 1.0), 4.0)
    _floors(L, rooms, L.tex("asphalt", Color(0.7, 0.7, 0.72), 8.0), 24, 46, {"A": tiles, "B": tiles, "C": L.tex("concrete", Color(0.85, 0.85, 0.85), 6.0)})
    L.bounds(24, 46)
    var lay := _rooms(L, rooms, 5.0, L.tex("wall", Color(0.85, 0.9, 1.0), 6.0),
        {"A": L.tex("wall", Color(1.05, 0.85, 0.95), 6.0), "C": L.tex("concrete", Color(0.75, 0.75, 0.75), 5.0)})
    # Checkout counters + a gumball machine.
    for x in [-9.0, 0.0, 9.0]:
        L.box(Vector3(x, 0.55, 24), Vector3(5.0, 1.1, 1.4), Color(0.85, 0.2, 0.25), 0.0, true, L.mat(Color(0.85, 0.2, 0.25), 0.35))
        L.box(Vector3(x - 1.5, 1.35, 24), Vector3(0.9, 0.5, 0.6), Color(0.15, 0.15, 0.17))
    L.sphere(Vector3(13, 1.9, 36), 0.8, Color(0.9, 0.9, 1.0), Vector3.ONE, L.mat(Color(0.85, 0.9, 1.0), 0.05, 0.2))
    L.cyl(Vector3(13, 0.7, 36), 0.5, 1.4, Color(0.85, 0.15, 0.15))
    # Aisle shelving with toy boxes.
    var shelf: Material = L.mat(Color(0.75, 0.78, 0.82), 0.4, 0.6)
    var box_cols := [Color(0.9, 0.3, 0.2), Color(0.2, 0.45, 0.9), Color(0.95, 0.8, 0.2), Color(0.3, 0.7, 0.35), Color(0.75, 0.35, 0.8)]
    for x in [-8.0, 4.0]:
        L.box(Vector3(x, 1.3, 1), Vector3(1.6, 2.6, 18), Color.GRAY, 0.0, true, shelf)
        for k in 8:
            for y in [0.5, 1.4, 2.3]:
                L.box(Vector3(x + (0.82 if k % 2 == 0 else -0.82), y, -7 + k * 2.2), Vector3(0.05, 0.6, 1.5), box_cols[(k + int(y)) % 5], 0.0, false)
    # Stockroom: pallets and cardboard.
    var card := Color(0.7, 0.55, 0.35)
    for b in [[Vector3(-9, 0, -32), 2.6], [Vector3(-9, 2.6, -32), 1.8], [Vector3(-9, 0, -20), 2.2], [Vector3(10, 0, -20), 2.4], [Vector3(-2, 0, -37), 2.0]]:
        L.box(b[0] + Vector3(0, b[1] * 0.5, 0), Vector3(b[1], b[1], b[1]), card)
    L.prop("kenney_retro_urban/pallet.glb", Vector3(10, 0, -27), 0.3, Vector3(2.4, 0, 0), true)
    # Fluorescent tubes.
    var tube: Material = L.glow_mat(Color(0.95, 1.0, 1.0), 2.0)
    for p in [Vector3(-8, 4.7, 32), Vector3(8, 4.7, 32), Vector3(-12, 4.7, 8), Vector3(10, 4.7, 8), Vector3(-2, 4.7, -6), Vector3(0, 4.7, -27)]:
        L.box(p, Vector3(3.0, 0.12, 0.3), Color.WHITE, 0.0, false, tube)
        L.lamp(p - Vector3(0, 0.3, 0), Color(0.92, 0.97, 1.0), 16.0, 2.6, false)
    L.lamp(Vector3(-17, 3.2, 1), Color(1.0, 0.25, 0.2), 6.0, 1.0)                    # EXIT sign glow
    return {
        "spawn": Vector3(0, 0.5, 33), "spawn_yaw": 0.0, "drones": 0, "safe_radius": 0.0,
        "start_weapons": ["carbine"],
        "sky_top": Color(0.04, 0.04, 0.07), "sky_horizon": Color(0.14, 0.12, 0.16),
        "sun_color": Color(0.7, 0.7, 0.85), "sun_energy": 0.3, "sun_rot": Vector3(-65, 30, 0),
        "fog": 0.01, "ambient": 1.0, "exposure": 1.2,
        "music": "res://assets/audio/music/war_theme.ogg", "ambience": "res://assets/audio/ambience/city_traffic.ogg", "ambience_db": -24.0,
        "objectives": [],
        "meltdown": {
            "start": "A",
            "sections": {"A": "CHECKOUT", "B": "ACTION FIGURE AISLE", "C": "STOCKROOM"},
            "windows": lay["windows"], "doors": lay["doors"],
            "stations": [
                {"kind": "weapon", "weapon": "shotgun", "cost": 500, "pos": Vector3(-17.55, 0, 35), "facing": Vector3(1, 0, 0)},
                {"kind": "medic", "cost": 300, "pos": Vector3(17.55, 0, 22), "facing": Vector3(-1, 0, 0)},
                {"kind": "weapon", "weapon": "sniper", "cost": 1000, "pos": Vector3(17.55, 0, 35), "facing": Vector3(-1, 0, 0)},
                {"kind": "weapon", "weapon": "lmg", "cost": 1250, "pos": Vector3(-17.55, 0, 10), "facing": Vector3(1, 0, 0)},
                {"kind": "armor", "cost": 400, "pos": Vector3(17.55, 0, 8), "facing": Vector3(-1, 0, 0)},
                {"kind": "crate", "cost": 950, "pos": Vector3(-13, 0, -6), "facing": Vector3(1, 0, 0)},
                {"kind": "weapon", "weapon": "launcher", "cost": 2000, "pos": Vector3(-13.55, 0, -22), "facing": Vector3(1, 0, 0)},
                {"kind": "press", "cost": 3000, "pos": Vector3(4, 0, -30), "facing": Vector3(0, 0, 1)},
            ],
        },
    }
