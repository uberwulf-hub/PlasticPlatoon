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
    {
        "name": "Midnight Kitchen",
        "location": "The kitchen - after everyone's gone to bed",
        "briefing": "Something tan is crawling out from behind the fridge. Hold the kitchen floor, squeeze through the pantry and make your stand by the washing machine.",
        "blurb": "A big kitchen with an open fridge, a narrow pantry, and the laundry room.",
    },
    {
        "name": "Recess Is Cancelled",
        "location": "Room 4B - the school at night",
        "briefing": "The Melties got into the school. Barricade the classroom, fight down the long locker hallway and take the gym.",
        "blurb": "Rows of desks, a long hallway of lockers, and a wide-open gym.",
    },
    {
        "name": "Sandcastle Beach at Dusk",
        "location": "The beach - as the sun goes down",
        "briefing": "The tide brought the Melties in. Hold the lifeguard hut, take the sandcastle courtyard and fall back down the pier with nowhere left to run.",
        "blurb": "Lifeguard hut, a sandcastle courtyard, and a narrow pier over the sea.",
    },
    {
        "name": "Bath Time",
        "location": "The upstairs bathroom - long after bedtime",
        "briefing": "The Melties came up the drain. Hold the bathroom, push out across the landing and make your last stand in the kids' bedroom, between the bed and the toy box.",
        "blurb": "A tiled bathroom with a full tub, the upstairs landing, and the kids' bedroom.",
    },
    {
        "name": "The Garage",
        "location": "The garage - where Dad keeps the good tools",
        "briefing": "Something tan is oozing under the garage door. Hold the workbench, fight round the family car and fall back into the paint store.",
        "blurb": "Dad's workbench, a car bay with the family car in it, and the paint store.",
    },
    {
        "name": "Pillow Fort",
        "location": "The living room - sleepover night",
        "briefing": "The sleepover is over: the Melties want in. Hold the pillow fort, take back the living room around the sofa and the TV, and dig in by the fireplace.",
        "blurb": "A blanket-and-cushion fort, the living room, and the fireplace den.",
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
        4:
            d = _kitchen(L)
        5:
            d = _school(L)
        6:
            d = _beach_md(L)
        7:
            d = _bathroom(L)
        8:
            d = _garage(L)
        9:
            d = _pillow_fort(L)
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


# ================================================= MIDNIGHT KITCHEN ====
#   A  Kitchen Floor   z  14..40
#   B  Pantry          z -14..14   (narrow; 750)
#   C  Laundry Room    z -40..-14  (1250)

static func _kitchen(L) -> Dictionary:
    var rooms := [
        {"id": "A", "x0": -18, "x1": 18, "z0": 14, "z1": 40, "win_s": [-9, 9], "win_w": [27], "win_e": [22], "door_x": -6, "door_cost": 750},
        {"id": "B", "x0": -12, "x1": 12, "z0": -14, "z1": 14, "win_w": [0], "win_e": [-6], "door_x": 6, "door_cost": 1250},
        {"id": "C", "x0": -16, "x1": 16, "z0": -40, "z1": -14, "win_w": [-27], "win_e": [-33], "win_n": [0]},
    ]
    _floors(L, rooms, L.tex("wood_floor", Color(0.55, 0.45, 0.38), 10.0), 24, 46,
        {"A": L.tex("tiles", Color(1.0, 0.97, 0.9), 3.0), "B": L.tex("wood_floor", Color(0.8, 0.7, 0.6), 8.0), "C": L.tex("concrete", Color(0.85, 0.85, 0.88), 6.0)})
    L.bounds(24, 46)
    var lay := _rooms(L, rooms, 4.8, L.tex("wall", Color(1.05, 0.98, 0.75), 6.0),
        {"B": L.tex("table_wood", Color(0.7, 0.58, 0.45), 4.0), "C": L.tex("wall", Color(0.8, 0.9, 1.0), 6.0)})
    var white: Material = L.mat(Color(0.95, 0.95, 0.93), 0.3)
    var wood = L.tex("table_wood", Color(0.75, 0.6, 0.45), 3.0)
    # Kitchen: island, fridge (door ajar, glowing), table and chairs, spilled cereal.
    L.box(Vector3(4, 0.9, 27), Vector3(8, 1.8, 3), Color.WHITE, 0.0, true, wood)
    L.box(Vector3(4, 1.85, 27), Vector3(8.4, 0.12, 3.4), Color(0.2, 0.2, 0.22))
    L.box(Vector3(-16.4, 3.4, 19.5), Vector3(3.0, 6.8, 3.0), Color.WHITE, 0.0, true, white)
    L.box_rot(Vector3(-14.2, 3.4, 18.2), Vector3(0.2, 6.6, 2.8), Color.WHITE, Vector3(0, 0.6, 0), false, white)
    L.lamp(Vector3(-14.5, 3.0, 19.5), Color(0.75, 0.9, 1.0), 12.0, 3.0, false)
    L.box(Vector3(9, 1.3, 35), Vector3(4, 0.2, 2.6), Color.WHITE, 0.0, true, wood)
    for p in [Vector3(7.4, 0, 33.8), Vector3(10.6, 0, 33.8), Vector3(7.4, 0, 36.2), Vector3(10.6, 0, 36.2)]:
        L.box(p + Vector3(0, 0.6, 0), Vector3(0.2, 1.2, 0.2), Color(0.4, 0.3, 0.2))
    L.box_rot(Vector3(-4, 1.2, 33), Vector3(1.6, 2.4, 0.6), Color(0.9, 0.75, 0.2), Vector3(0, 0.4, deg_to_rad(80)))   # cereal box on its side
    for i in 10:
        L.sphere(Vector3(-2.0 + randf() * 2.5, 0.12, 31.5 + randf() * 2.5), 0.15, Color(0.95, 0.8, 0.35))
    # Pantry: a shelving island down the middle.
    L.box(Vector3(0, 1.4, 0), Vector3(1.4, 2.8, 10), Color.BROWN, 0.0, true, wood)
    for k in 6:
        L.box(Vector3(0, 0.6 + (k % 3) * 0.9, -4 + k * 1.6), Vector3(1.5, 0.6, 1.0), [Color(0.85, 0.2, 0.2), Color(0.9, 0.8, 0.3), Color(0.3, 0.6, 0.3)][k % 3], 0.0, false)
    # Laundry: washer + dryer, a basket.
    for z in [-20.0, -23.4]:
        L.box(Vector3(-12, 1.5, z), Vector3(3, 3, 3), Color.WHITE, 0.0, true, white)
        L.cyl(Vector3(-10.48, 1.6, z), 0.9, 0.05, Color(0.3, 0.4, 0.5), false, Vector3(0, 0, PI / 2))
    L.cyl(Vector3(8, 0.7, -36), 1.2, 1.4, Color(0.4, 0.55, 0.85), true, Vector3.ZERO, null, 1.4)
    for p in [Vector3(-6, 4.4, 33), Vector3(8, 4.4, 20), Vector3(0, 4.4, 6), Vector3(0, 4.4, -8), Vector3(-6, 4.4, -26), Vector3(8, 4.4, -32)]:
        L.lamp(p, Color(1.0, 0.85, 0.6), 18.0, 2.8)
    return {
        "spawn": Vector3(0, 0.5, 33), "spawn_yaw": 0.0, "drones": 0, "safe_radius": 0.0,
        "start_weapons": ["carbine"],
        "sky_top": Color(0.04, 0.04, 0.08), "sky_horizon": Color(0.12, 0.12, 0.18),
        "sun_color": Color(0.65, 0.7, 0.9), "sun_energy": 0.3, "sun_rot": Vector3(-55, 60, 0),
        "fog": 0.01, "ambient": 1.0, "exposure": 1.25,
        "music": "res://assets/audio/music/determined_pursuit.ogg", "ambience": "res://assets/audio/ambience/clock_tick.ogg", "ambience_db": -12.0,
        "objectives": [],
        "meltdown": {
            "start": "A",
            "sections": {"A": "KITCHEN FLOOR", "B": "PANTRY", "C": "LAUNDRY ROOM"},
            "windows": lay["windows"], "doors": lay["doors"],
            "stations": [
                {"kind": "weapon", "weapon": "shotgun", "cost": 500, "pos": Vector3(-17.55, 0, 34), "facing": Vector3(1, 0, 0)},
                {"kind": "medic", "cost": 300, "pos": Vector3(17.55, 0, 33), "facing": Vector3(-1, 0, 0)},
                {"kind": "weapon", "weapon": "lmg", "cost": 1250, "pos": Vector3(-11.55, 0, 8), "facing": Vector3(1, 0, 0)},
                {"kind": "weapon", "weapon": "sniper", "cost": 1000, "pos": Vector3(11.55, 0, 6), "facing": Vector3(-1, 0, 0)},
                {"kind": "armor", "cost": 400, "pos": Vector3(-11.55, 0, -8), "facing": Vector3(1, 0, 0)},
                {"kind": "crate", "cost": 950, "pos": Vector3(-4, 0, -9), "facing": Vector3(0, 0, 1)},
                {"kind": "weapon", "weapon": "launcher", "cost": 2000, "pos": Vector3(15.55, 0, -22), "facing": Vector3(-1, 0, 0)},
                {"kind": "press", "cost": 3000, "pos": Vector3(0, 0, -30), "facing": Vector3(0, 0, 1)},
            ],
        },
    }


# =========================================== RECESS IS CANCELLED ====
#   A  Classroom   z  16..42
#   B  Hallway     z   4..16   (long and thin; 750)
#   C  Gym         z -42..4    (1000)

static func _school(L) -> Dictionary:
    var rooms := [
        {"id": "A", "x0": -16, "x1": 16, "z0": 16, "z1": 42, "win_s": [-8, 8], "win_w": [30], "win_e": [24], "door_x": 10, "door_cost": 750},
        {"id": "B", "x0": -24, "x1": 24, "z0": 4, "z1": 16, "win_w": [10], "win_e": [10], "door_x": -14, "door_cost": 1000},
        {"id": "C", "x0": -20, "x1": 20, "z0": -42, "z1": 4, "win_w": [-10, -30], "win_e": [-20], "win_n": [-8, 8]},
    ]
    _floors(L, rooms, L.tex("asphalt", Color(0.6, 0.6, 0.62), 8.0), 30, 48,
        {"A": L.tex("wood_floor", Color(0.9, 0.8, 0.65), 8.0), "B": L.tex("tiles", Color(0.85, 0.9, 0.85), 3.0), "C": L.tex("wood_floor", Color(1.05, 0.9, 0.65), 12.0)})
    L.bounds(30, 48)
    var lay := _rooms(L, rooms, 5.0, L.tex("wall", Color(0.85, 0.95, 0.85), 6.0),
        {"C": L.tex("concrete", Color(0.9, 0.85, 0.75), 5.0)})
    # Classroom: rows of desks, the teacher's desk and a chalkboard.
    var desk = L.tex("table_wood", Color(0.85, 0.7, 0.5), 2.0)
    for row in 3:
        for col in 4:
            var p := Vector3(-9 + col * 6.0, 0, 34 - row * 5.0)
            L.box(p + Vector3(0, 0.75, 0), Vector3(2.0, 0.1, 1.2), Color.BROWN, 0.0, true, desk)
            L.box(p + Vector3(0, 0.35, 0), Vector3(1.8, 0.7, 0.2), Color(0.35, 0.35, 0.4))
    L.box(Vector3(-6, 0.8, 19.5), Vector3(4, 1.6, 1.8), Color.BROWN, 0.0, true, desk)
    L.box(Vector3(-4, 2.8, 16.45), Vector3(10, 2.6, 0.1), Color(0.15, 0.3, 0.2), 0.0, false)
    L.box(Vector3(-4, 3.0, 16.5), Vector3(5, 0.04, 0.04), Color(0.95, 0.95, 0.9), 0.0, false, L.glow_mat(Color(0.95, 0.95, 0.9), 0.8))
    # Hallway: lockers on the walls between the doors.
    var locker: Material = L.mat(Color(0.3, 0.45, 0.75), 0.35, 0.5)
    for x in [-20.0, -8.0, 0.0, 18.0]:
        L.box(Vector3(x, 1.4, 4.45), Vector3(3.8, 2.8, 0.5), Color.BLUE, 0.0, true, locker)
    # Gym: a hoop at each end, mats, a ball bin.
    for z in [-40.5, 2.5]:
        L.box(Vector3(0, 3.6, z), Vector3(2.2, 1.4, 0.1), Color.WHITE, 0.0, false)
        L.cyl(Vector3(0, 3.0, z + (0.6 if z < 0 else -0.6)), 0.5, 0.05, Color(0.95, 0.4, 0.1), false)
    for p in [Vector3(-12, 0, -16), Vector3(12, 0, -8)]:
        L.box(p + Vector3(0, 0.15, 0), Vector3(4, 0.3, 6), Color(0.2, 0.4, 0.8))
    L.box(Vector3(-15, 0.6, -38), Vector3(2, 1.2, 2), Color(0.3, 0.3, 0.32))
    for i in 6:
        L.sphere(Vector3(-15.5 + (i % 3) * 0.5, 1.35, -38.4 + (i / 3) * 0.6), 0.25, Color(0.9, 0.45, 0.15))
    var tube: Material = L.glow_mat(Color(0.95, 1.0, 1.0), 2.0)
    for p in [Vector3(-6, 4.7, 32), Vector3(6, 4.7, 22), Vector3(-14, 4.7, 10), Vector3(12, 4.7, 10), Vector3(-8, 4.7, -14), Vector3(8, 4.7, -30)]:
        L.box(p, Vector3(3.0, 0.12, 0.3), Color.WHITE, 0.0, false, tube)
        L.lamp(p - Vector3(0, 0.3, 0), Color(0.92, 0.97, 1.0), 18.0, 2.6, false)
    return {
        "spawn": Vector3(0, 0.5, 38), "spawn_yaw": 0.0, "drones": 0, "safe_radius": 0.0,
        "start_weapons": ["carbine"],
        "sky_top": Color(0.03, 0.04, 0.08), "sky_horizon": Color(0.1, 0.12, 0.2),
        "sun_color": Color(0.6, 0.7, 0.95), "sun_energy": 0.3, "sun_rot": Vector3(-60, 30, 0),
        "fog": 0.01, "ambient": 1.0, "exposure": 1.2,
        "music": "res://assets/audio/music/war_theme.ogg", "ambience": "res://assets/audio/ambience/clock_tick.ogg", "ambience_db": -14.0,
        "objectives": [],
        "meltdown": {
            "start": "A",
            "sections": {"A": "CLASSROOM", "B": "HALLWAY", "C": "GYM"},
            "windows": lay["windows"], "doors": lay["doors"],
            "stations": [
                {"kind": "weapon", "weapon": "shotgun", "cost": 500, "pos": Vector3(-15.55, 0, 37), "facing": Vector3(1, 0, 0)},
                {"kind": "medic", "cost": 300, "pos": Vector3(15.55, 0, 34), "facing": Vector3(-1, 0, 0)},
                {"kind": "weapon", "weapon": "lmg", "cost": 1250, "pos": Vector3(-23.55, 0, 14.5), "facing": Vector3(1, 0, 0)},
                {"kind": "weapon", "weapon": "sniper", "cost": 1000, "pos": Vector3(23.55, 0, 14.5), "facing": Vector3(-1, 0, 0)},
                {"kind": "crate", "cost": 950, "pos": Vector3(4, 0, 10), "facing": Vector3(0, 0, 1)},
                {"kind": "armor", "cost": 400, "pos": Vector3(-19.55, 0, -20), "facing": Vector3(1, 0, 0)},
                {"kind": "weapon", "weapon": "launcher", "cost": 2000, "pos": Vector3(19.55, 0, -32), "facing": Vector3(-1, 0, 0)},
                {"kind": "press", "cost": 3000, "pos": Vector3(6, 0, -26), "facing": Vector3(0, 0, 1)},
            ],
        },
    }


# ============================================ SANDCASTLE BEACH AT DUSK ====
#   A  Lifeguard Hut          z  18..40
#   B  Sandcastle Courtyard   z -12..18   (sand walls; 750)
#   C  The Pier               z -40..-12  (narrow boardwalk; 1250)

static func _beach_md(L) -> Dictionary:
    var rooms := [
        {"id": "A", "x0": -12, "x1": 12, "z0": 18, "z1": 40, "win_s": [0], "win_w": [29], "win_e": [24, 35], "door_x": -4, "door_cost": 750},
        {"id": "B", "x0": -20, "x1": 20, "z0": -12, "z1": 18, "win_w": [10, -4], "win_e": [3], "door_x": 4, "door_cost": 1250},
        {"id": "C", "x0": -10, "x1": 10, "z0": -40, "z1": -12, "win_w": [-22, -34], "win_e": [-28], "win_n": [0]},
    ]
    var sand = L.tex("beach_sand", Color(1.2, 1.1, 0.95), 7.0)
    _floors(L, rooms, sand, 26, 46,
        {"A": L.tex("table_wood", Color(0.75, 0.6, 0.45), 4.0), "C": L.tex("table_wood", Color(0.65, 0.55, 0.45), 3.0)})
    L.bounds(26, 46)
    var lay := _rooms(L, rooms, 4.2, L.tex("table_wood", Color(0.95, 0.85, 0.7), 4.0),
        {"B": L.tex("beach_sand", Color(1.25, 1.12, 0.9), 4.0)})
    # The sea beyond the pier, and the surf line.
    var sea: Material = L.mat(Color(0.15, 0.35, 0.5), 0.05, 0.3)
    L.box(Vector3(0, -0.2, -120), Vector3(400, 0.1, 140), Color.BLUE, 0.0, false, sea)
    L.water(Vector3(0, 0.03, -44), Vector2(60, 6), Color(0.4, 0.65, 0.75, 0.6))
    # Lifeguard tower in the hut, beach umbrellas, sandcastle turrets.
    for p in [Vector3(4, 0, 30), Vector3(7, 0, 30), Vector3(4, 0, 33), Vector3(7, 0, 33)]:
        L.box(p + Vector3(0, 1.5, 0), Vector3(0.25, 3.0, 0.25), Color.WHITE)
    L.box(Vector3(5.5, 3.1, 31.5), Vector3(3.6, 0.2, 3.6), Color(0.9, 0.2, 0.2))
    for p in [Vector3(-10, 0, 6), Vector3(12, 0, -4), Vector3(-6, 0, -8)]:
        L.cyl(p + Vector3(0, 1.6, 0), 0.08, 3.2, Color(0.9, 0.9, 0.9), false)
        L.cyl(p + Vector3(0, 3.2, 0), 0.05, 0.6, [Color(0.95, 0.3, 0.3), Color(0.2, 0.6, 0.9), Color(0.95, 0.8, 0.2)][int(absf(p.x)) % 3], false, Vector3.ZERO, null, 2.2)
    for p in [Vector3(-20, 0, -12), Vector3(20, 0, -12), Vector3(-20, 0, 18), Vector3(20, 0, 18)]:
        L.cyl(p + Vector3(0, 2.6, 0), 1.8, 5.2, Color(0.9, 0.8, 0.55), true, Vector3.ZERO, sand, 1.5)
    # Pier: posts, crates, lamp posts.
    for z in [-16.0, -24.0, -32.0]:
        for x in [-10.6, 10.6]:
            L.cyl(Vector3(x, 1.5, z), 0.3, 3.0, Color(0.4, 0.3, 0.22))
    L.box(Vector3(-6.5, 0.6, -36), Vector3(1.2, 1.2, 1.2), Color(0.6, 0.45, 0.3))
    for p in [Vector3(-5, 3.6, 30), Vector3(0, 3.6, 4), Vector3(-10, 3.6, -6), Vector3(0, 3.6, -20), Vector3(0, 3.6, -34)]:
        L.lamp(p, Color(1.0, 0.75, 0.45), 18.0, 2.6)
    return {
        "spawn": Vector3(0, 0.5, 33), "spawn_yaw": 0.0, "drones": 0, "safe_radius": 0.0,
        "start_weapons": ["carbine"],
        "sky_top": Color(0.25, 0.2, 0.45), "sky_horizon": Color(0.95, 0.5, 0.35),
        "sun_color": Color(1.0, 0.6, 0.4), "sun_energy": 0.7, "sun_rot": Vector3(-12, 200, 0),
        "fog": 0.008, "ambient": 0.8, "exposure": 1.0,
        "music": "res://assets/audio/music/battle_theme_a.ogg", "ambience": "res://assets/audio/ambience/desert_wind.ogg", "ambience_db": -14.0,
        "objectives": [],
        "meltdown": {
            "start": "A",
            "sections": {"A": "LIFEGUARD HUT", "B": "SANDCASTLE COURTYARD", "C": "THE PIER"},
            "windows": lay["windows"], "doors": lay["doors"],
            "stations": [
                {"kind": "weapon", "weapon": "shotgun", "cost": 500, "pos": Vector3(-11.55, 0, 35), "facing": Vector3(1, 0, 0)},
                {"kind": "medic", "cost": 300, "pos": Vector3(11.55, 0, 30), "facing": Vector3(-1, 0, 0)},
                {"kind": "weapon", "weapon": "lmg", "cost": 1250, "pos": Vector3(-19.55, 0, 3), "facing": Vector3(1, 0, 0)},
                {"kind": "weapon", "weapon": "sniper", "cost": 1000, "pos": Vector3(19.55, 0, 12), "facing": Vector3(-1, 0, 0)},
                {"kind": "armor", "cost": 400, "pos": Vector3(19.55, 0, -6), "facing": Vector3(-1, 0, 0)},
                {"kind": "crate", "cost": 950, "pos": Vector3(-2, 0, 6), "facing": Vector3(0, 0, 1)},
                {"kind": "weapon", "weapon": "launcher", "cost": 2000, "pos": Vector3(-9.55, 0, -28), "facing": Vector3(1, 0, 0)},
                {"kind": "press", "cost": 3000, "pos": Vector3(3, 0, -22), "facing": Vector3(0, 0, 1)},
            ],
        },
    }


# ========================================================= BATH TIME ====
#   A  Bathroom       z  16..38
#   B  Landing        z   2..16   (wide and shallow; 750)
#   C  Kids' Bedroom  z -38..2    (1000)

static func _bathroom(L) -> Dictionary:
    var rooms := [
        {"id": "A", "x0": -14, "x1": 14, "z0": 16, "z1": 38, "win_s": [-6, 6], "win_w": [30], "win_e": [22], "door_x": -6, "door_cost": 750},
        {"id": "B", "x0": -20, "x1": 20, "z0": 2, "z1": 16, "win_w": [9], "win_e": [9], "door_x": 10, "door_cost": 1000},
        {"id": "C", "x0": -18, "x1": 18, "z0": -38, "z1": 2, "win_w": [-12, -28], "win_e": [-20], "win_n": [-6, 8]},
    ]
    var tiles = L.tex("tiles", Color(0.85, 0.95, 1.0), 2.5, 0.3)
    var carpet = L.tex("carpet", Color(0.55, 0.65, 1.0), 4.0)
    _floors(L, rooms, L.tex("grass", Color(0.45, 0.55, 0.5), 6.0), 30, 48,
        {"A": tiles, "B": L.tex("carpet", Color(1.0, 0.85, 0.6), 4.0), "C": carpet})
    L.bounds(30, 48)
    var lay := _rooms(L, rooms, 4.6, L.tex("wall", Color(1.0, 0.95, 0.85), 5.0),
        {"A": L.tex("tiles", Color(0.8, 0.92, 1.0), 2.0, 0.3), "C": L.tex("wall", Color(0.8, 0.88, 1.0), 5.0)})
    # Bathroom: the tub (still full) with a rubber duck, the loo, the sink, a bath mat.
    var white: Material = L.mat(Color(0.96, 0.96, 0.98), 0.15)
    L.box(Vector3(10.5, 0.6, 27), Vector3(5.0, 1.2, 2.6), Color.WHITE, 0.0, true, white)
    L.water(Vector3(10.5, 1.15, 27), Vector2(4.4, 2.0), Color(0.55, 0.8, 0.95, 0.75))
    L.sphere(Vector3(9.5, 1.35, 26.6), 0.28, Color(1.0, 0.85, 0.1))
    L.sphere(Vector3(9.25, 1.6, 26.6), 0.17, Color(1.0, 0.85, 0.1))
    L.box(Vector3(-11.6, 0.45, 35.5), Vector3(1.2, 0.9, 1.6), Color.WHITE, 0.0, true, white)
    L.box(Vector3(-11.6, 1.3, 36.6), Vector3(1.4, 1.0, 0.5), Color.WHITE, 0.0, true, white)
    L.box(Vector3(6, 0.9, 17.2), Vector3(3.0, 1.8, 1.6), Color(0.5, 0.35, 0.25), 0.0, true, L.tex("table_wood", Color(0.8, 0.65, 0.5), 2.0))
    L.box(Vector3(6, 3.0, 16.45), Vector3(2.4, 1.8, 0.08), Color(0.8, 0.9, 1.0), 0.0, false, L.mat(Color(0.85, 0.92, 1.0), 0.02, 0.9))
    L.box(Vector3(2, 0.03, 27), Vector3(3.0, 0.06, 2.0), Color(0.4, 0.75, 0.6), 0.0, false)
    # Landing: a laundry basket and the banister rail.
    L.cyl(Vector3(-13, 0.7, 12.5), 0.9, 1.4, Color(0.75, 0.6, 0.4))
    L.box(Vector3(2, 1.0, 3.4), Vector3(10, 0.12, 0.12), Color(0.5, 0.35, 0.25), 0.0, false)
    # Bedroom: the bed, a toy box, a round rug and a night-light.
    L.box(Vector3(12, 0.6, -10), Vector3(6.0, 1.2, 8.0), Color(0.4, 0.55, 0.9), 0.0, true, L.tex("carpet", Color(0.6, 0.75, 1.2), 2.0))
    L.box(Vector3(12, 1.4, -13.5), Vector3(5.0, 0.5, 1.4), Color.WHITE, 0.0, false)
    L.box(Vector3(12, 1.6, -14.3), Vector3(6.2, 2.0, 0.3), Color(0.5, 0.35, 0.25))
    L.box(Vector3(-8, 0.6, -6), Vector3(3.0, 1.2, 2.0), Color(0.9, 0.3, 0.3))
    L.cyl(Vector3(-2, 0.03, -20), 5.0, 0.06, Color(0.95, 0.75, 0.3), false)
    L.sphere(Vector3(17.2, 1.0, -2.0), 0.25, Color(1.0, 0.85, 0.5), Vector3.ONE, L.glow_mat(Color(1.0, 0.8, 0.45), 3.0))
    for p in [Vector3(0, 4.2, 27), Vector3(-10, 4.2, 9), Vector3(10, 4.2, 9), Vector3(0, 4.2, -8), Vector3(-6, 4.2, -26), Vector3(10, 4.2, -28)]:
        L.lamp(p, Color(1.0, 0.92, 0.8), 18.0, 2.4)
    return {
        "spawn": Vector3(-2, 0.5, 33), "spawn_yaw": 0.0, "drones": 0, "safe_radius": 0.0,
        "start_weapons": ["carbine"],
        "sky_top": Color(0.03, 0.04, 0.1), "sky_horizon": Color(0.12, 0.14, 0.25),
        "sun_color": Color(0.6, 0.7, 1.0), "sun_energy": 0.3, "sun_rot": Vector3(-55, 40, 0),
        "fog": 0.008, "ambient": 1.0, "exposure": 1.15,
        "music": "res://assets/audio/music/determined_pursuit.ogg", "ambience": "res://assets/audio/ambience/clock_tick.ogg", "ambience_db": -14.0,
        "objectives": [],
        "meltdown": {
            "start": "A",
            "sections": {"A": "BATHROOM", "B": "LANDING", "C": "KIDS' BEDROOM"},
            "windows": lay["windows"], "doors": lay["doors"],
            "stations": [
                {"kind": "weapon", "weapon": "shotgun", "cost": 500, "pos": Vector3(-13.55, 0, 22), "facing": Vector3(1, 0, 0)},
                {"kind": "medic", "cost": 300, "pos": Vector3(13.55, 0, 33), "facing": Vector3(-1, 0, 0)},
                {"kind": "weapon", "weapon": "lmg", "cost": 1250, "pos": Vector3(-19.55, 0, 4), "facing": Vector3(1, 0, 0)},
                {"kind": "weapon", "weapon": "sniper", "cost": 1000, "pos": Vector3(19.55, 0, 14), "facing": Vector3(-1, 0, 0)},
                {"kind": "crate", "cost": 950, "pos": Vector3(-4, 0, 6), "facing": Vector3(0, 0, 1)},
                {"kind": "armor", "cost": 400, "pos": Vector3(-17.55, 0, -20), "facing": Vector3(1, 0, 0)},
                {"kind": "weapon", "weapon": "launcher", "cost": 2000, "pos": Vector3(17.55, 0, -32), "facing": Vector3(-1, 0, 0)},
                {"kind": "press", "cost": 3000, "pos": Vector3(4, 0, -26), "facing": Vector3(0, 0, 1)},
            ],
        },
    }


# ======================================================== THE GARAGE ====
#   A  Workbench    z  16..40
#   B  Car Bay      z -14..16   (the family car parked in the middle; 750)
#   C  Paint Store  z -40..-14  (shelving rows; 1250)

static func _garage(L) -> Dictionary:
    var rooms := [
        {"id": "A", "x0": -14, "x1": 14, "z0": 16, "z1": 40, "win_s": [-7, 7], "win_w": [28], "win_e": [24], "door_x": 6, "door_cost": 750},
        {"id": "B", "x0": -22, "x1": 22, "z0": -14, "z1": 16, "win_w": [8, -6], "win_e": [0], "door_x": -10, "door_cost": 1250},
        {"id": "C", "x0": -16, "x1": 16, "z0": -40, "z1": -14, "win_w": [-26], "win_e": [-34], "win_n": [-6, 6]},
    ]
    var concrete = L.tex("concrete", Color(0.8, 0.8, 0.78), 7.0)
    _floors(L, rooms, L.tex("asphalt", Color(0.55, 0.55, 0.58), 8.0), 32, 46, {"A": concrete, "B": concrete, "C": concrete})
    L.bounds(32, 46)
    var lay := _rooms(L, rooms, 5.0, L.tex("concrete", Color(0.75, 0.78, 0.82), 5.0),
        {"A": L.tex("wall", Color(0.85, 0.8, 0.7), 5.0)})
    var wood = L.tex("table_wood", Color(0.85, 0.7, 0.5), 2.0)
    # Workbench, pegboard with tools, the red tool chest.
    L.box(Vector3(-7, 1.0, 17.4), Vector3(8.0, 0.15, 1.8), Color.BROWN, 0.0, true, wood)
    for x in [-10.6, -3.4]:
        L.box(Vector3(x, 0.5, 17.4), Vector3(0.2, 1.0, 1.6), Color.BROWN, 0.0, true, wood)
    L.box(Vector3(-7, 2.6, 16.45), Vector3(7.0, 2.2, 0.08), Color(0.75, 0.6, 0.4), 0.0, false)
    for i in 5:
        L.box(Vector3(-9.6 + i * 1.3, 2.6, 16.55), Vector3(0.15, 1.2, 0.1), [Color(0.8, 0.2, 0.15), Color(0.2, 0.3, 0.8), Color(0.3, 0.3, 0.3)][i % 3], 0.0, false)
    L.box(Vector3(12, 1.0, 19), Vector3(2.0, 2.0, 2.0), Color(0.8, 0.12, 0.1), 0.0, true, L.mat(Color(0.8, 0.12, 0.1), 0.3, 0.5))
    # The family car (you can hide behind it), an oil stain, the lawn mower.
    var paint: Material = L.mat(Color(0.2, 0.35, 0.7), 0.25, 0.6)
    L.box(Vector3(5, 1.0, 1), Vector3(4.4, 1.2, 9.0), Color.BLUE, 0.0, true, paint)
    L.box(Vector3(5, 2.1, 0.5), Vector3(3.8, 1.0, 4.6), Color.BLUE, 0.0, true, paint)
    L.box(Vector3(5, 2.1, 0.5), Vector3(3.9, 0.7, 4.0), Color(0.15, 0.2, 0.25), 0.0, false, L.mat(Color(0.2, 0.28, 0.35), 0.05, 0.6))
    for wx in [2.75, 7.25]:
        for wz in [-2.0, 4.0]:
            L.cyl(Vector3(wx, 0.55, wz), 0.55, 0.5, Color(0.08, 0.08, 0.08), false, Vector3(0, 0, PI / 2))
    for hz in [5.55, -3.55]:
        for hx in [3.6, 6.4]:
            L.box(Vector3(hx, 1.2, hz), Vector3(0.6, 0.25, 0.05), Color(1, 1, 0.8), 0.0, false, L.glow_mat(Color(1.0, 0.95, 0.75), 1.5) if hz > 0 else L.glow_mat(Color(1.0, 0.15, 0.1), 1.5))
    L.cyl(Vector3(-4, 0.02, 4), 1.4, 0.03, Color(0.05, 0.05, 0.06), false)
    L.box(Vector3(-14, 0.5, -9), Vector3(1.6, 1.0, 2.2), Color(0.2, 0.55, 0.2))
    # Paint store: shelving rows with paint tins.
    for x in [-6.0, 0.0]:
        L.box(Vector3(x, 1.6, -26), Vector3(1.2, 3.2, 8.0), Color.GRAY, 0.0, true, L.mat(Color(0.5, 0.5, 0.52), 0.4, 0.6))
        for k in 6:
            for lvl in 2:
                L.cyl(Vector3(x, 1.0 + lvl * 1.2, -29 + k * 1.2), 0.3, 0.5, [Color(0.9, 0.2, 0.2), Color(0.2, 0.6, 0.9), Color(0.95, 0.85, 0.2), Color(0.3, 0.75, 0.3)][(k + lvl) % 4], false)
    var tube: Material = L.glow_mat(Color(0.95, 1.0, 1.0), 2.0)
    for p in [Vector3(0, 4.7, 30), Vector3(0, 4.7, 21), Vector3(-12, 4.7, 4), Vector3(12, 4.7, 4), Vector3(-6, 4.7, -20), Vector3(6, 4.7, -32)]:
        L.box(p, Vector3(3.0, 0.12, 0.3), Color.WHITE, 0.0, false, tube)
        L.lamp(p - Vector3(0, 0.3, 0), Color(0.92, 0.97, 1.0), 18.0, 2.4, false)
    return {
        "spawn": Vector3(0, 0.5, 34), "spawn_yaw": 0.0, "drones": 0, "safe_radius": 0.0,
        "start_weapons": ["carbine"],
        "sky_top": Color(0.04, 0.04, 0.08), "sky_horizon": Color(0.15, 0.13, 0.18),
        "sun_color": Color(0.7, 0.75, 1.0), "sun_energy": 0.3, "sun_rot": Vector3(-50, 120, 0),
        "fog": 0.01, "ambient": 1.0, "exposure": 1.15,
        "music": "res://assets/audio/music/battle_theme_a.ogg", "ambience": "res://assets/audio/ambience/city_traffic.ogg", "ambience_db": -26.0,
        "objectives": [],
        "meltdown": {
            "start": "A",
            "sections": {"A": "WORKBENCH", "B": "CAR BAY", "C": "PAINT STORE"},
            "windows": lay["windows"], "doors": lay["doors"],
            "stations": [
                {"kind": "weapon", "weapon": "shotgun", "cost": 500, "pos": Vector3(-13.55, 0, 34), "facing": Vector3(1, 0, 0)},
                {"kind": "medic", "cost": 300, "pos": Vector3(13.55, 0, 32), "facing": Vector3(-1, 0, 0)},
                {"kind": "weapon", "weapon": "lmg", "cost": 1250, "pos": Vector3(-21.55, 0, 1), "facing": Vector3(1, 0, 0)},
                {"kind": "weapon", "weapon": "sniper", "cost": 1000, "pos": Vector3(21.55, 0, 10), "facing": Vector3(-1, 0, 0)},
                {"kind": "armor", "cost": 400, "pos": Vector3(21.55, 0, -9), "facing": Vector3(-1, 0, 0)},
                {"kind": "crate", "cost": 950, "pos": Vector3(-10, 0, 9), "facing": Vector3(0, 0, 1)},
                {"kind": "weapon", "weapon": "launcher", "cost": 2000, "pos": Vector3(-15.55, 0, -19), "facing": Vector3(1, 0, 0)},
                {"kind": "press", "cost": 3000, "pos": Vector3(8, 0, -27), "facing": Vector3(0, 0, 1)},
            ],
        },
    }


# ======================================================= PILLOW FORT ====
#   A  Pillow Fort     z  18..40   (blanket walls)
#   B  Living Room     z -14..18   (sofa, coffee table, TV; 750)
#   C  Fireplace Den   z -40..-14  (1250)

static func _pillow_fort(L) -> Dictionary:
    var rooms := [
        {"id": "A", "x0": -12, "x1": 12, "z0": 18, "z1": 40, "win_s": [-5, 5], "win_w": [30], "win_e": [26], "door_x": 0, "door_cost": 750},
        {"id": "B", "x0": -22, "x1": 22, "z0": -14, "z1": 18, "win_w": [10, -6], "win_e": [2], "door_x": 8, "door_cost": 1250},
        {"id": "C", "x0": -14, "x1": 14, "z0": -40, "z1": -14, "win_w": [-24], "win_e": [-32], "win_n": [-6, 6]},
    ]
    var rug = L.tex("carpet", Color(1.1, 0.75, 0.6), 4.0)
    _floors(L, rooms, L.tex("wood_floor", Color(0.6, 0.48, 0.38), 10.0), 32, 48,
        {"A": L.tex("carpet", Color(1.0, 0.95, 1.2), 3.0), "B": rug, "C": L.tex("wood_floor", Color(0.9, 0.7, 0.55), 8.0)})
    L.bounds(32, 48)
    var lay := _rooms(L, rooms, 4.4, L.tex("wall", Color(0.95, 0.88, 0.75), 5.0),
        {"A": L.tex("carpet", Color(1.25, 0.6, 0.7), 2.0), "C": L.tex("rock", Color(0.85, 0.75, 0.7), 4.0)})
    # The fort: a sagging blanket roof, cushions to duck behind, fairy lights.
    L.box(Vector3(0, 4.3, 29), Vector3(24, 0.1, 22), Color(0.9, 0.5, 0.6), 0.0, false, L.tex("carpet", Color(1.2, 0.65, 0.75), 3.0))
    for p in [Vector3(-4, 0, 30), Vector3(5, 0, 24), Vector3(-6, 0, 21)]:
        L.box(p + Vector3(0, 0.45, 0), Vector3(2.4, 0.9, 1.2), Color(0.6, 0.7, 0.95), 0.0, true, L.mat(Color(0.6, 0.7, 0.95), 0.9))
    var bulb: Material = L.glow_mat(Color(1.0, 0.85, 0.45), 3.0)
    for i in 11:
        L.sphere(Vector3(-10 + i * 2.0, 3.8 - absf(sin(i * 0.9)) * 0.3, 39.4), 0.1, Color.YELLOW, Vector3.ONE, bulb)
    for p in [Vector3(-5, 3.4, 32), Vector3(5, 3.4, 32), Vector3(0, 3.4, 23)]:
        L.lamp(p, Color(1.0, 0.8, 0.55), 16.0, 2.6)
    # Living room: the sofa, the coffee table, the TV (still on) and a floor lamp.
    var sofa: Material = L.mat(Color(0.3, 0.45, 0.35), 0.9)
    L.box(Vector3(6, 0.5, 8), Vector3(8.0, 1.0, 2.4), Color.GREEN, 0.0, true, sofa)
    L.box(Vector3(6, 1.3, 9.0), Vector3(8.0, 1.2, 0.6), Color.GREEN, 0.0, true, sofa)
    L.box(Vector3(6, 0.45, 2), Vector3(3.0, 0.12, 1.8), Color.BROWN, 0.0, true, L.tex("table_wood", Color(0.8, 0.6, 0.45), 2.0))
    L.box(Vector3(6, 0.4, -10), Vector3(6.0, 0.8, 1.4), Color(0.25, 0.2, 0.18))
    L.box(Vector3(6, 2.3, -10), Vector3(5.0, 2.8, 0.2), Color(0.05, 0.05, 0.06), 0.0, true)
    L.box(Vector3(6, 2.3, -9.88), Vector3(4.6, 2.4, 0.05), Color.WHITE, 0.0, false, L.glow_mat(Color(0.35, 0.55, 0.95), 1.4))
    L.cyl(Vector3(-16, 1.4, 14), 0.08, 2.8, Color(0.3, 0.3, 0.3), false)
    L.sphere(Vector3(-16, 2.9, 14), 0.45, Color.WHITE, Vector3.ONE, L.glow_mat(Color(1.0, 0.85, 0.6), 1.5))
    L.lamp(Vector3(-16, 2.6, 14), Color(1.0, 0.8, 0.55), 12.0, 1.6, false)
    # Den: the fireplace (lit), an armchair, a bookcase.
    L.box(Vector3(0, 1.4, -39.0), Vector3(4.6, 2.8, 1.4), Color(0.5, 0.3, 0.25), 0.0, true, L.tex("rock", Color(0.8, 0.55, 0.45), 2.0))
    L.box(Vector3(0, 0.7, -38.25), Vector3(2.4, 1.2, 0.1), Color(1, 0.5, 0.1), 0.0, false, L.glow_mat(Color(1.0, 0.45, 0.1), 3.0))
    L.lamp(Vector3(0, 1.0, -37), Color(1.0, 0.55, 0.2), 14.0, 2.5, false)
    L.box(Vector3(-8, 0.6, -24), Vector3(2.2, 1.2, 2.2), Color(0.55, 0.2, 0.2))
    L.box(Vector3(-8, 1.5, -25), Vector3(2.2, 1.4, 0.4), Color(0.55, 0.2, 0.2))
    L.box(Vector3(-9, 1.6, -15.0), Vector3(5.0, 3.2, 1.0), Color.BROWN, 0.0, true, L.tex("table_wood", Color(0.7, 0.5, 0.35), 2.0))
    for p in [Vector3(-6, 3.8, 6), Vector3(14, 3.8, 0), Vector3(-12, 3.8, -8), Vector3(-6, 3.8, -30), Vector3(8, 3.8, -28)]:
        L.lamp(p, Color(1.0, 0.85, 0.65), 18.0, 2.2)
    return {
        "spawn": Vector3(0, 0.5, 35), "spawn_yaw": 0.0, "drones": 0, "safe_radius": 0.0,
        "start_weapons": ["carbine"],
        "sky_top": Color(0.03, 0.03, 0.08), "sky_horizon": Color(0.12, 0.1, 0.2),
        "sun_color": Color(0.65, 0.7, 1.0), "sun_energy": 0.3, "sun_rot": Vector3(-60, 210, 0),
        "fog": 0.008, "ambient": 0.9, "exposure": 1.15,
        "music": "res://assets/audio/music/war_theme.ogg", "ambience": "res://assets/audio/ambience/clock_tick.ogg", "ambience_db": -16.0,
        "objectives": [],
        "meltdown": {
            "start": "A",
            "sections": {"A": "PILLOW FORT", "B": "LIVING ROOM", "C": "FIREPLACE DEN"},
            "windows": lay["windows"], "doors": lay["doors"],
            "stations": [
                {"kind": "weapon", "weapon": "shotgun", "cost": 500, "pos": Vector3(-11.55, 0, 23), "facing": Vector3(1, 0, 0)},
                {"kind": "medic", "cost": 300, "pos": Vector3(11.55, 0, 34), "facing": Vector3(-1, 0, 0)},
                {"kind": "weapon", "weapon": "lmg", "cost": 1250, "pos": Vector3(-21.55, 0, 2), "facing": Vector3(1, 0, 0)},
                {"kind": "weapon", "weapon": "sniper", "cost": 1000, "pos": Vector3(21.55, 0, 12), "facing": Vector3(-1, 0, 0)},
                {"kind": "armor", "cost": 400, "pos": Vector3(21.55, 0, -8), "facing": Vector3(-1, 0, 0)},
                {"kind": "crate", "cost": 950, "pos": Vector3(-8, 0, 0), "facing": Vector3(0, 0, 1)},
                {"kind": "weapon", "weapon": "launcher", "cost": 2000, "pos": Vector3(13.55, 0, -24), "facing": Vector3(-1, 0, 0)},
                {"kind": "press", "cost": 3000, "pos": Vector3(-4, 0, -32), "facing": Vector3(0, 0, 1)},
            ],
        },
    }
