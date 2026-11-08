extends RefCounted
## MELTDOWN mode maps. A builder places the geometry through the Level API and
## returns the settings dictionary plus a "meltdown" layout (sections, doors,
## boarded windows and buy stations) that the Meltdown controller brings to life.

const META := [
    {
        "name": "The Basement",
        "location": "Under the house - where the broken toys go",
        "briefing": "Something went wrong with General Beige's paint. The Tan soldiers it touched came back... melted. And hungry for green plastic.\n\nHold the toy shelf. Board up the windows, earn coins for every hit and every Melty, buy guns off the walls, and save up to clear the junk into the workshop and the boiler room. Every wave is worse than the last.",
    },
]


static func build(i: int, L) -> Dictionary:
    var d: Dictionary = _basement(L)
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
