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
    {
        "name": "Model Railway",
        "location": "The loft - Grandpa's train set",
        "briefing": "The Melties have taken over Grandpa's model railway. Hold the station platform, fight through the train yard around the parked locomotive and dig in at the engine shed.",
        "blurb": "A station platform, the train yard with a parked train, and the engine shed.",
    },
    {
        "name": "Birthday Party",
        "location": "The dining room - the party nobody cleaned up",
        "briefing": "Cake, balloons and presents everywhere - and the Melties want all of it. Hold the party table, fight through the games room and make your last stand around the bouncy castle.",
        "blurb": "The party table and cake, a games room full of presents, and the bouncy castle.",
    },
    {
        "name": "Snow Day",
        "location": "The back yard - school's cancelled",
        "briefing": "It snowed overnight, and the Melties are slipping in over the drifts. Hold the snow fort, cross the snowman yard and fall back to the sled shed.",
        "blurb": "A snow fort, a yard full of snowmen, and the sled shed.",
    },
    {
        "name": "The Big Flush",
        "location": "The bathroom - and you're the size of a bottle cap",
        "briefing": "You woke up at the bottom of the toilet. The Melties are crawling through the hollow porcelain and cracking the bowl to get at you.\n\nPlaster the cracks, earn coins, and buy the toilet paper: it unrolls into a ramp up and over the rim. Then take the bathroom floor, clear the towels out of the corner, and climb into the tub for the Re-Mold Press.",
        "blurb": "Start inside a giant toilet bowl, escape up the toilet paper, take the floor, the corner and the tub.",
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
        10:
            d = _railway(L)
        11:
            d = _party(L)
        12:
            d = _snow_day(L)
        13:
            d = _big_flush(L)
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
    # Round the crawlspace: two giant pine 2x4s stacked on edge (decoration only,
    # no collision; the play edge is still L.bounds above). They replace the old
    # 12 m stone wall, which hid the giant basement beyond.
    _basement_giant(L)

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
        "fog": 0.006, "ambient": 1.0, "exposure": 1.3,
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


# ---- The Basement: giant scale (Creative Collaboration: Plastic Platoon art pass 1) ----
# Art direction: ChatGPT (creative director); spec approved by Andrew, 2026-11-20.
# The soldier (1.8 m) is a ~7 cm toy, so the human basement is drawn at 25x:
# a 0.85 m washing machine is 22 m tall, the 2.4 m ceiling is 60 m up. Every
# giant prop stands outside the play area (|x| > 24, |z| > 48) or overhead and
# has no collision, so layout, doors, cracks, enemies and collisions are as before.
# Built only from boxes, cylinders and spheres with the game's existing tiling
# textures. Shadows of a colour are that colour darkened 35-45%; nothing is random.
const BM_ENAMEL := Color("e9e7e1")      # washer / heater white enamel
const BM_CHROME := Color("c9ccd1")
const BM_GLASS := Color("2b3440")
const BM_BASKET := Color("2f7fd1")      # blue plastic laundry basket
const BM_CARD := Color("b08a5a")        # cardboard
const BM_TAPE := Color("d2b27a")        # packing tape (lighter, glossier)
const BM_TOOL := Color("c7322a")        # red toolbox
const BM_SOFA := Color("b5532e")        # burnt-orange sofa
const BM_COPPER := Color("b8733a")
const BM_PINE := Color("d9b98a")        # 2x4 lumber
const BM_BULB := Color("ffd9a0")
const BM_MOON := Color("6f8fd8")        # cool light through the high window


static func _basement_giant(L) -> void:
    # The rest of the basement floor, far out, with expansion joints every 40 m.
    var conc = L.tex("concrete", Color(0.62, 0.61, 0.6), 40.0)
    L.box(Vector3(0, -0.6, 0), Vector3(420, 1.0, 420), Color.GRAY, 0.0, false, conc)
    for k in range(-5, 6):
        L.box(Vector3(k * 40.0, -0.08, 0), Vector3(0.5, 0.06, 420), Color(0.25, 0.24, 0.23), 0.0, false)
        L.box(Vector3(0, -0.08, k * 40.0), Vector3(420, 0.06, 0.5), Color(0.25, 0.24, 0.23), 0.0, false)
    # The border: two pine 2x4s on edge (3.8 x 8.9 cm x 25 = 0.95 x 2.2 m each).
    var pine = L.tex("table_wood", BM_PINE, 6.0)
    for s in [-1.0, 1.0]:
        for y in [1.1, 3.3]:
            L.box(Vector3(23 * s, y, 0), Vector3(0.95, 2.18, 95.9), Color.GRAY, 0.0, false, pine)
            L.box(Vector3(0, y, 47 * s), Vector3(46.9, 2.18, 0.95), Color.GRAY, 0.0, false, pine)
    _bm_washer(L, Vector3(38, 0, 16))
    _bm_basket(L, Vector3(38, 22, 15))
    _bm_heater(L, Vector3(6, 0, -63))
    _bm_sofa(L, Vector3(0, 0, 66))
    _bm_box(L, Vector3(-39, 0, 24), Vector3(16, 16, 18), 0.0, "TOYS")
    _bm_box(L, Vector3(-38, 16, 25), Vector3(13, 11, 14), 0.12, "")
    _bm_box(L, Vector3(-40, 0, 0), Vector3(18, 19, 20), -0.05, "OLD CLOTHES")
    _bm_box(L, Vector3(-36, 0, -20), Vector3(11, 11, 12), 0.2, "BOOKS")
    _bm_toolbox(L, Vector3(-41, 0, -41))
    _bm_ceiling(L)
    # Fill light on the giant things (no shadows; too far out to light the rooms):
    # warm on the sofa and boxes, neutral on the washer, cool moonlight on the heater.
    for f in [[Vector3(30, 26, 16), Color("fff1dc"), 34.0, 1.6], [Vector3(0, 26, 48), Color("ffd2a6"), 44.0, 2.0],
            [Vector3(-30, 20, 8), Color("ffdcae"), 42.0, 1.5], [Vector3(-32, 14, -34), Color("ffe6c8"), 26.0, 1.3],
            [Vector3(6, 26, -46), Color("a9c1ff"), 36.0, 1.5]]:
        L.lamp(f[0], f[1], f[2], f[3], false)


## Front-loading washing machine, door facing -x (into the room). base = floor centre.
static func _bm_washer(L, base: Vector3) -> void:
    var enamel = L.mat(BM_ENAMEL, 0.3)
    var W := 16.0
    var H := 22.0
    var D := 16.0
    var fx: float = base.x - D * 0.5          # the front face
    L.box(base + Vector3(0, H * 0.5 + 0.8, 0), Vector3(D, H - 1.6, W), Color.WHITE, 0.0, false, enamel)
    L.box(base + Vector3(0, 0.4, 0), Vector3(D - 0.6, 0.8, W - 0.6), Color("3a3a3a"), 0.0, false)    # kick plate
    L.box(base + Vector3(0, H - 0.4, 0), Vector3(D, 0.8, W), Color.WHITE, 0.0, false, L.mat(BM_ENAMEL.darkened(0.06), 0.25))
    # Control panel along the top, a dial and a little glowing display.
    L.box(Vector3(fx - 0.1, H - 3.0, base.z), Vector3(0.3, 3.2, W - 0.6), Color.WHITE, 0.0, false, L.mat(Color("d4d4d2"), 0.35))
    L.cyl(Vector3(fx - 0.5, H - 3.0, base.z + 4.5), 1.25, 0.7, BM_CHROME, false, Vector3(0, 0, PI / 2), L.mat(BM_CHROME, 0.2, 0.8))
    L.box(Vector3(fx - 0.3, H - 3.0, base.z - 1.0), Vector3(0.2, 1.0, 3.2), Color.WHITE, 0.0, false, L.glow_mat(Color("5fd3c8"), 1.2))
    L.box(Vector3(fx - 0.3, H - 3.0, base.z - 5.2), Vector3(0.3, 1.6, 3.4), Color.WHITE, 0.0, false, L.mat(BM_ENAMEL.darkened(0.12), 0.35))  # drawer
    # The round door: chrome ring, dark glass, laundry tumbling behind it.
    var c := Vector3(fx - 0.2, 9.5, base.z)
    L.cyl(c, 6.0, 0.8, BM_CHROME, false, Vector3(0, 0, PI / 2), L.mat(BM_CHROME, 0.18, 0.85))
    L.cyl(c + Vector3(-0.3, 0, 0), 4.7, 0.6, BM_GLASS, false, Vector3(0, 0, PI / 2), L.mat(BM_GLASS, 0.05, 0.3))
    var cloth := [Color("d94a4a"), Color("f2c230"), Color("f4f1ea"), Color("3f7fd6")]
    for i in 4:
        var a := i * TAU / 4.0 + 0.4
        L.sphere(c + Vector3(0.6, sin(a) * 2.2 - 0.6, cos(a) * 2.2), 1.6, cloth[i], Vector3(0.5, 0.8, 1.2), L.mat(cloth[i], 0.95))
    L.box(c + Vector3(-0.7, 0, 5.4), Vector3(0.6, 2.4, 0.9), BM_CHROME, 0.0, false, L.mat(BM_CHROME, 0.2, 0.8))   # handle


## Open-top plastic laundry basket with slots, clothes spilling over. base = bottom centre.
static func _bm_basket(L, base: Vector3) -> void:
    var m = L.mat(BM_BASKET, 0.45)
    var dark = L.mat(BM_BASKET.darkened(0.45), 0.6)
    var X := 11.0
    var Y := 9.0
    var Z := 13.0
    var t := 0.6
    L.box(base + Vector3(0, t * 0.5, 0), Vector3(X, t, Z), BM_BASKET, 0.0, false, m)
    for s in [-1.0, 1.0]:
        L.box(base + Vector3(s * (X - t) * 0.5, Y * 0.5, 0), Vector3(t, Y, Z), BM_BASKET, 0.0, false, m)
        L.box(base + Vector3(0, Y * 0.5, s * (Z - t) * 0.5), Vector3(X, Y, t), BM_BASKET, 0.0, false, m)
        L.box(base + Vector3(0, Y - 0.3, s * (Z * 0.5 + 0.1)), Vector3(X + 0.8, 0.8, 0.5), BM_BASKET, 0.0, false, m)  # rim
        # Slots: dark bars on the outside of the front (-x) and sides.
        for k in 5:
            var zz := -4.8 + k * 2.4
            L.box(base + Vector3(-X * 0.5 - 0.05, Y * 0.45, zz), Vector3(0.1, Y * 0.5, 1.1), BM_BASKET, 0.0, false, dark)
    # Clothes: a pile, a shirt hanging over the front edge, a sock.
    L.sphere(base + Vector3(0, Y - 0.5, 0), 5.0, Color("f4f1ea"), Vector3(1.0, 0.45, 1.15), L.mat(Color("f4f1ea"), 0.95))
    L.sphere(base + Vector3(1.5, Y + 0.6, -2.5), 3.0, Color("d94a4a"), Vector3(1.0, 0.5, 1.0), L.mat(Color("d94a4a"), 0.95))
    L.sphere(base + Vector3(-1.0, Y + 0.5, 3.0), 2.8, Color("f2c230"), Vector3(1.0, 0.5, 1.2), L.mat(Color("f2c230"), 0.95))
    L.box_rot(base + Vector3(-X * 0.5 - 0.6, Y - 3.0, 1.0), Vector3(0.4, 7.0, 5.0), Color("3f7fd6"), Vector3(0, 0, -0.12), false, L.mat(Color("3f7fd6"), 0.95))


## Tall gas water heater with copper pipes to the ceiling. base = floor centre.
static func _bm_heater(L, base: Vector3) -> void:
    var R := 9.0
    var H := 38.0
    var shell = L.mat(Color("e7e2d4"), 0.35, 0.15)
    L.cyl(base + Vector3(0, H * 0.5, 0), R, H, Color.WHITE, false, Vector3.ZERO, shell)
    L.sphere(base + Vector3(0, H, 0), R, Color.WHITE, Vector3(1, 0.22, 1), shell)
    L.cyl(base + Vector3(0, 1.0, 0), R + 0.3, 2.0, Color("6b6660"), false, Vector3.ZERO, L.mat(Color("6b6660"), 0.5, 0.4))   # base ring
    var front: float = base.z + R           # the side facing the play area (+z)
    # Burner door with a warm flame window, and the yellow rating plate (no words).
    L.box(Vector3(base.x, 4.5, front - 0.2), Vector3(5.0, 3.6, 0.6), Color.WHITE, 0.0, false, L.mat(Color("8d8780"), 0.4, 0.5))
    L.box(Vector3(base.x, 4.5, front + 0.15), Vector3(2.0, 1.0, 0.2), Color.WHITE, 0.0, false, L.glow_mat(Color("ff8a2a"), 2.5))
    L.lamp(Vector3(base.x, 5.0, front + 3.0), Color("ff8a2a"), 18.0, 1.6, false)
    L.box(Vector3(base.x - 3.0, 16.0, front - 0.35), Vector3(4.0, 5.0, 0.4), Color.WHITE, 0.0, false, L.mat(Color("f2c230"), 0.5))
    L.box(Vector3(base.x + 2.5, 9.0, front - 0.3), Vector3(2.4, 1.6, 1.4), Color.WHITE, 0.0, false, L.mat(Color("3a3a3a"), 0.5, 0.4))  # gas valve
    var cu = L.mat(BM_COPPER, 0.3, 0.8)
    for dx in [-4.0, 4.0]:
        L.cyl(base + Vector3(dx, (H + 60.0) * 0.5, 0), 0.9, 60.0 - H, BM_COPPER, false, Vector3.ZERO, cu)
    L.cyl(base + Vector3(0, (H + 60.0) * 0.5 + 2.0, 0), 2.2, 60.0 - H - 4.0, BM_CHROME, false, Vector3.ZERO, L.mat(Color("9fa3a8"), 0.4, 0.7))  # flue
    # Relief valve pipe down the side.
    L.cyl(Vector3(base.x + R + 0.6, 16.0, base.z + 2.0), 0.6, 30.0, BM_COPPER, false, Vector3.ZERO, cu)


## A big sofa, its front facing -z (the play area). base = floor centre.
static func _bm_sofa(L, base: Vector3) -> void:
    var fab = L.tex("carpet", BM_SOFA, 8.0)
    var fab_dark = L.tex("carpet", BM_SOFA.darkened(0.35), 8.0)
    var W := 68.0
    var fz: float = base.z - 10.0          # front of the seat
    L.box(Vector3(base.x, 6.5, base.z), Vector3(W, 11.0, 20.0), Color.WHITE, 0.0, false, fab_dark)     # body / skirt
    for i in 3:                                                                                     # seat cushions
        var x: float = base.x + (i - 1) * (W / 3.0)
        L.box(Vector3(x, 13.5, base.z - 1.0), Vector3(W / 3.0 - 0.6, 4.0, 20.5), Color.WHITE, 0.0, false, fab)
        L.box_rot(Vector3(x, 23.0, base.z + 8.0), Vector3(W / 3.0 - 0.8, 15.0, 5.0), Color.WHITE, Vector3(-0.18, 0, 0), false, fab)  # back cushions
    L.box(Vector3(base.x, 21.0, base.z + 12.0), Vector3(W + 0.2, 28.0, 6.0), Color.WHITE, 0.0, false, fab_dark)   # back
    for s in [-1.0, 1.0]:
        var ax: float = base.x + s * (W * 0.5 + 4.0)
        L.box(Vector3(ax, 9.0, base.z + 1.0), Vector3(8.0, 18.0, 22.0), Color.WHITE, 0.0, false, fab)
        L.cyl(Vector3(ax, 18.0, base.z + 1.0), 4.4, 22.0, BM_SOFA, false, Vector3(PI / 2, 0, 0), fab)   # rolled arm
    var foot = L.tex("table_wood", Color("5a3a22"), 2.0)
    for s in [-1.0, 1.0]:
        for z in [fz + 2.0, base.z + 12.0]:
            L.cyl(Vector3(base.x + s * (W * 0.5 + 2.0), 0.5, z), 1.4, 1.0, Color.BROWN, false, Vector3.ZERO, foot)


## A taped cardboard storage box with a marker label on the side facing the play area (+x).
static func _bm_box(L, base: Vector3, size: Vector3, rot_y: float, word: String) -> void:
    var card = L.tex("plaster", BM_CARD, 4.0, 0.95)
    var tape = L.mat(BM_TAPE, 0.35)
    var seam = L.mat(BM_CARD.darkened(0.45), 0.95)
    var c := base + Vector3(0, size.y * 0.5, 0)
    L.box_rot(c, size, Color.WHITE, Vector3(0, rot_y, 0), false, card)
    var b := Basis(Vector3.UP, rot_y)
    # Flap seam and tape across the top, tape down the front.
    L.box_rot(c + b * Vector3(0, size.y * 0.5 + 0.02, 0), Vector3(0.25, 0.06, size.z), Color.WHITE, Vector3(0, rot_y, 0), false, seam)
    L.box_rot(c + b * Vector3(0, size.y * 0.5 + 0.05, 0), Vector3(2.6, 0.08, size.z + 0.1), Color.WHITE, Vector3(0, rot_y, 0), false, tape)
    L.box_rot(c + b * Vector3(size.x * 0.5 + 0.05, size.y * 0.5 - 2.0, 0), Vector3(0.08, 4.0, 2.6), Color.WHITE, Vector3(0, rot_y, 0), false, tape)
    if word != "":
        # Marker writing as thin solid 3D text (a TextMesh, so walls hide it properly).
        var tm := TextMesh.new()
        tm.text = word
        tm.font_size = 220
        tm.pixel_size = 0.02
        tm.depth = 0.05
        var mi := MeshInstance3D.new()
        mi.mesh = tm
        mi.material_override = L.mat(Color("222222"), 0.9)
        mi.position = c + b * Vector3(size.x * 0.5 + 0.05, -size.y * 0.12, 0)
        mi.rotation.y = rot_y + PI / 2
        mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        L.add_child(mi)


## A red metal toolbox with a black handle. base = floor centre; long side along z.
static func _bm_toolbox(L, base: Vector3) -> void:
    var red = L.mat(BM_TOOL, 0.35, 0.3)
    var red_dark = L.mat(BM_TOOL.darkened(0.4), 0.4, 0.3)
    var blk = L.mat(Color("1e1e1e"), 0.5)
    var chrome = L.mat(BM_CHROME, 0.2, 0.85)
    var X := 12.0
    var Z := 24.0
    L.box(base + Vector3(0, 4.5, 0), Vector3(X, 9.0, Z), Color.WHITE, 0.0, false, red)              # bottom
    L.box(base + Vector3(0, 9.1, 0), Vector3(X + 0.2, 0.3, Z + 0.2), Color.WHITE, 0.0, false, red_dark)  # lid line
    L.box(base + Vector3(0, 11.0, 0), Vector3(X - 0.4, 3.6, Z - 0.4), Color.WHITE, 0.0, false, red)  # lid
    for dz in [-6.0, 6.0]:                                                                            # latches
        L.box(base + Vector3(X * 0.5 + 0.15, 9.0, dz), Vector3(0.3, 2.2, 1.6), Color.WHITE, 0.0, false, chrome)
    for dz in [-7.0, 7.0]:                                                                            # handle posts
        L.box(base + Vector3(0, 14.0, dz), Vector3(1.2, 3.0, 1.2), Color.WHITE, 0.0, false, blk)
    L.box(base + Vector3(0, 15.8, 0), Vector3(1.6, 1.4, 15.2), Color.WHITE, 0.0, false, blk)


## The ceiling 60 m up: subfloor, joists, pipes, a duct and a bare bulb on a cord.
static func _bm_ceiling(L) -> void:
    var Y := 60.0
    L.box(Vector3(0, Y + 0.6, 0), Vector3(420, 1.2, 420), Color.WHITE, 0.0, false, L.tex("table_wood", Color("6e5a44"), 30.0))
    var joist = L.tex("table_wood", BM_PINE.darkened(0.25), 10.0)
    for k in range(-10, 11):
        L.box(Vector3(k * 10.0, Y - 3.0, 0), Vector3(1.6, 6.0, 420), Color.WHITE, 0.0, false, joist)
    var cu = L.mat(BM_COPPER, 0.3, 0.8)
    L.cyl(Vector3(-8, Y - 9.0, 0), 0.8, 420.0, BM_COPPER, false, Vector3(PI / 2, 0, 0), cu)
    L.cyl(Vector3(-5, Y - 9.0, 0), 0.8, 420.0, BM_COPPER, false, Vector3(PI / 2, 0, 0), cu)
    L.cyl(Vector3(13, Y - 11.0, 0), 1.6, 420.0, Color.WHITE, false, Vector3(PI / 2, 0, 0), L.mat(Color("eeeeea"), 0.5))   # white drain pipe
    L.box(Vector3(-22, Y - 9.0, 0), Vector3(9.0, 4.5, 420), Color.WHITE, 0.0, false, L.mat(Color("a7abb0"), 0.35, 0.75)) # silver duct
    for z in range(-180, 181, 30):                                                                    # pipe hangers
        L.box(Vector3(-6.5, Y - 7.0, z), Vector3(5.0, 0.4, 0.4), Color.WHITE, 0.0, false, L.mat(Color("555555"), 0.6, 0.5))
    # Two bare bulbs on long cords, warm pools of light far above the rooms.
    for p in [Vector3(2, 0, 4), Vector3(-4, 0, -30)]:
        L.cyl(Vector3(p.x, Y - 9.0, p.z), 0.15, 18.0, Color("222222"), false)
        L.cyl(Vector3(p.x, Y - 18.8, p.z), 1.0, 1.8, Color("3a3a3a"), false, Vector3.ZERO, L.mat(Color("3a3a3a"), 0.5, 0.5))
        L.sphere(Vector3(p.x, Y - 21.6, p.z), 2.2, BM_BULB, Vector3(1, 1.2, 1), L.glow_mat(BM_BULB, 3.0))
        L.lamp(Vector3(p.x, Y - 24.0, p.z), BM_BULB, 110.0, 1.8, false)
    # A high basement window: cool light from outside.
    var wc := Vector3(-30, Y - 14.0, -117.6)
    L.box(wc, Vector3(34, 10, 0.6), Color.WHITE, 0.0, false, L.glow_mat(BM_MOON, 1.4))
    var frame = L.tex("table_wood", Color("4a3a2a"), 3.0)
    for dy in [-5.4, 5.4]:
        L.box(wc + Vector3(0, dy, 0.4), Vector3(36, 1.0, 1.2), Color.WHITE, 0.0, false, frame)
    for dx in [-17.4, 0.0, 17.4]:
        L.box(wc + Vector3(dx, 0, 0.4), Vector3(1.0, 11.8, 1.2), Color.WHITE, 0.0, false, frame)
    L.box(wc + Vector3(0, -6.2, 2.0), Vector3(38, 0.6, 4.0), Color.WHITE, 0.0, false, L.mat(Color("8d8a84"), 0.9))   # sill
    L.lamp(Vector3(-30, Y - 16.0, -100), BM_MOON, 90.0, 0.7, false)
    # The basement's far walls (painted concrete block).
    var block = L.tex("wall", Color("8d8a84"), 14.0)
    for s in [-1.0, 1.0]:
        L.box(Vector3(105 * s, Y * 0.5, 0), Vector3(2, Y, 240), Color.WHITE, 0.0, false, block)
        L.box(Vector3(0, Y * 0.5, 119 * s), Vector3(212, Y, 2), Color.WHITE, 0.0, false, block)


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


# ===================================================== MODEL RAILWAY ====
#   A  Station Platform  z  18..40
#   B  Train Yard        z -14..18   (a parked train on the tracks; 1000)
#   C  Engine Shed       z -40..-14  (1250)

static func _railway(L) -> Dictionary:
    var rooms := [
        {"id": "A", "x0": -18, "x1": 18, "z0": 18, "z1": 40, "win_s": [-10, 10], "win_w": [29], "win_e": [29], "door_x": 0, "door_cost": 1000},
        {"id": "B", "x0": -18, "x1": 18, "z0": -14, "z1": 18, "win_w": [2], "win_e": [-6], "door_x": 10, "door_cost": 1250},
        {"id": "C", "x0": -14, "x1": 14, "z0": -40, "z1": -14, "win_w": [-26], "win_e": [-34], "win_n": [0]},
    ]
    _floors(L, rooms, L.tex("grass", Color(0.55, 0.75, 0.45), 5.0), 24, 46,
        {"A": L.tex("concrete", Color(0.9, 0.88, 0.85), 5.0), "B": L.tex("rock", Color(0.65, 0.6, 0.55), 5.0), "C": L.tex("concrete", Color(0.7, 0.7, 0.72), 5.0)})
    L.bounds(24, 46)
    var lay := _rooms(L, rooms, 5.0, L.tex("wall", Color(0.95, 0.85, 0.7), 5.0),
        {"B": L.tex("wall", Color(0.75, 0.85, 0.7), 5.0), "C": L.tex("table_wood", Color(0.7, 0.5, 0.35), 3.0)})
    # Platform: yellow edge line, benches, the station clock and the ticket booth.
    L.box(Vector3(0, 0.05, 19.5), Vector3(36, 0.04, 0.4), Color(0.95, 0.8, 0.1), 0.0, false)
    for x in [-8.0, 8.0]:
        L.box(Vector3(x, 0.45, 24), Vector3(3.0, 0.15, 0.8), Color.BROWN, 0.0, true, L.tex("table_wood", Color(0.8, 0.6, 0.4), 1.5))
        L.box(Vector3(x, 0.8, 24.35), Vector3(3.0, 0.6, 0.1), Color(0.5, 0.35, 0.2), 0.0, false)
    L.cyl(Vector3(12, 1.6, 30), 0.1, 3.2, Color(0.15, 0.25, 0.15))
    L.cyl(Vector3(12, 3.4, 30), 0.55, 0.15, Color.WHITE, false, Vector3(PI / 2, 0, 0))
    L.box(Vector3(-10, 1.2, 21), Vector3(3.0, 2.4, 2.0), Color(0.6, 0.2, 0.2), 0.0, true, L.mat(Color(0.65, 0.2, 0.18), 0.6))
    # Train yard: two tracks with sleepers, a locomotive and two wagons.
    var rail: Material = L.mat(Color(0.45, 0.45, 0.48), 0.3, 0.8)
    var tie: Material = L.mat(Color(0.35, 0.25, 0.18), 0.9)
    for tx in [-7.0, 5.0]:
        for off in [-0.7, 0.7]:
            L.box(Vector3(tx + off, 0.08, 2), Vector3(0.12, 0.12, 31.0), Color.GRAY, 0.0, false, rail)
        for k in 15:
            L.box(Vector3(tx, 0.04, -12.5 + k * 2.1), Vector3(2.2, 0.08, 0.4), Color.BROWN, 0.0, false, tie)
    var loco: Material = L.mat(Color(0.1, 0.35, 0.2), 0.35, 0.4)
    L.box(Vector3(-7, 1.3, 8), Vector3(2.4, 2.2, 5.0), Color.GREEN, 0.0, true, loco)
    L.cyl(Vector3(-7, 2.8, 9.5), 0.3, 1.0, Color(0.1, 0.1, 0.1))
    L.box(Vector3(-7, 2.9, 6.4), Vector3(2.4, 1.0, 1.8), Color.GREEN, 0.0, true, loco)
    for wz in [1.5, -4.5]:
        L.box(Vector3(-7, 1.1, wz), Vector3(2.4, 1.8, 4.5), Color(0.6, 0.3, 0.15), 0.0, true, L.mat([Color(0.6, 0.3, 0.15), Color(0.2, 0.3, 0.6)][int(wz < 0)], 0.5))
    # Engine shed: oil drums, a workbench, a spare wheel set.
    for p in [Vector3(8, 0, -36), Vector3(9.2, 0, -36.6), Vector3(-8, 0, -37)]:
        L.cyl(p + Vector3(0, 0.6, 0), 0.5, 1.2, Color(0.2, 0.35, 0.6))
    L.box(Vector3(-6, 0.9, -15.2), Vector3(5.0, 0.15, 1.6), Color.BROWN, 0.0, true, L.tex("table_wood", Color(0.75, 0.55, 0.4), 2.0))
    for x in [-1.0, 1.0]:
        L.cyl(Vector3(x, 0.6, -36), 0.6, 0.2, Color(0.3, 0.3, 0.32), true, Vector3(0, 0, PI / 2))
    for p in [Vector3(-8, 4.6, 32), Vector3(8, 4.6, 26), Vector3(-10, 4.6, 4), Vector3(8, 4.6, -6), Vector3(-6, 4.6, -24), Vector3(6, 4.6, -34)]:
        L.lamp(p, Color(1.0, 0.9, 0.75), 18.0, 2.5)
    return {
        "spawn": Vector3(0, 0.5, 32), "spawn_yaw": 0.0, "drones": 0, "safe_radius": 0.0,
        "start_weapons": ["carbine"],
        "sky_top": Color(0.05, 0.05, 0.1), "sky_horizon": Color(0.18, 0.15, 0.2),
        "sun_color": Color(0.7, 0.75, 1.0), "sun_energy": 0.35, "sun_rot": Vector3(-55, 70, 0),
        "fog": 0.008, "ambient": 1.0, "exposure": 1.15,
        "music": "res://assets/audio/music/determined_pursuit.ogg", "ambience": "res://assets/audio/ambience/clock_tick.ogg", "ambience_db": -14.0,
        "objectives": [],
        "meltdown": {
            "start": "A",
            "sections": {"A": "STATION PLATFORM", "B": "TRAIN YARD", "C": "ENGINE SHED"},
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


# ==================================================== BIRTHDAY PARTY ====
#   A  Party Table     z  14..36
#   B  Games Room      z -12..14   (presents and a pinata; 750)
#   C  Bouncy Castle   z -36..-12  (1500)

static func _party(L) -> Dictionary:
    var rooms := [
        {"id": "A", "x0": -14, "x1": 14, "z0": 14, "z1": 36, "win_s": [-7, 7], "win_w": [25], "win_e": [20], "door_x": 0, "door_cost": 750},
        {"id": "B", "x0": -20, "x1": 20, "z0": -12, "z1": 14, "win_w": [6, -6], "win_e": [0], "door_x": -8, "door_cost": 1500},
        {"id": "C", "x0": -12, "x1": 12, "z0": -36, "z1": -12, "win_w": [-24], "win_e": [-30], "win_n": [0]},
    ]
    _floors(L, rooms, L.tex("grass", Color(0.6, 0.8, 0.5), 6.0), 26, 42,
        {"A": L.tex("wood_floor", Color(1.0, 0.85, 0.7), 8.0), "B": L.tex("carpet", Color(0.8, 1.0, 1.2), 3.0), "C": L.tex("carpet", Color(1.2, 1.1, 0.6), 3.0)})
    L.bounds(26, 42)
    var lay := _rooms(L, rooms, 4.6, L.tex("wall", Color(1.0, 0.85, 0.9), 5.0),
        {"B": L.tex("wall", Color(0.85, 0.95, 1.0), 5.0), "C": L.tex("wall", Color(1.0, 1.0, 0.8), 5.0)})
    var party := [Color(0.95, 0.3, 0.35), Color(0.3, 0.6, 0.95), Color(0.98, 0.8, 0.2), Color(0.4, 0.85, 0.4), Color(0.8, 0.45, 0.9)]
    # Party table with the cake (candles lit), cups and hats; balloons above.
    L.box(Vector3(0, 0.9, 22), Vector3(6.0, 0.15, 2.4), Color.WHITE, 0.0, true, L.mat(Color(0.97, 0.97, 0.97), 0.7))
    for x in [-2.7, 2.7]:
        for z in [21.0, 23.0]:
            L.box(Vector3(x, 0.45, z), Vector3(0.15, 0.9, 0.15), Color(0.6, 0.45, 0.3), 0.0, false)
    L.cyl(Vector3(0, 1.4, 22), 0.8, 0.85, Color(0.98, 0.7, 0.8), false)
    L.cyl(Vector3(0, 1.84, 22), 0.82, 0.06, Color(0.98, 0.95, 0.95), false)
    var flame: Material = L.glow_mat(Color(1.0, 0.7, 0.2), 4.0)
    for k in 5:
        var a := k * TAU / 5.0
        var c := Vector3(cos(a) * 0.45, 0, sin(a) * 0.45) + Vector3(0, 0, 22)
        L.cyl(c + Vector3(0, 2.05, 0), 0.04, 0.35, party[k], false)
        L.sphere(c + Vector3(0, 2.27, 0), 0.06, Color.ORANGE, Vector3(1, 1.6, 1), flame)
    L.lamp(Vector3(0, 2.6, 22), Color(1.0, 0.75, 0.4), 8.0, 1.4, false)
    for k in 6:
        L.cyl(Vector3(-2.2 + k * 0.9, 1.25, 23.0 if k % 2 == 0 else 21.0), 0.12, 0.5, party[k % 5], false, Vector3.ZERO, null, 0.0)
    for k in 9:
        var bp := Vector3(-10 + (k % 5) * 5.0, 3.5 + (k % 3) * 0.3, 18 + int(k / 5) * 12.0 + (k % 2) * 2.0)
        L.sphere(bp, 0.45, party[k % 5], Vector3(1, 1.2, 1), L.mat(party[k % 5], 0.25))
        L.cyl(bp - Vector3(0, 1.1, 0), 0.01, 1.7, Color.WHITE, false)
    # Games room: stacks of presents, a pinata hanging from the ceiling.
    for p in [Vector3(12, 0, 8), Vector3(13.4, 0, 9.4), Vector3(-12, 0, -8), Vector3(10, 0, -8)]:
        var sz := 1.2 + absf(p.x) * 0.03
        L.box(p + Vector3(0, sz * 0.5, 0), Vector3(sz, sz, sz), party[int(absf(p.x + p.z)) % 5], 0.3, true, L.mat(party[int(absf(p.x + p.z)) % 5], 0.4))
        L.box(p + Vector3(0, sz * 0.5, 0), Vector3(sz + 0.02, sz + 0.02, 0.15), Color.WHITE, 0.3, false)
    L.sphere(Vector3(-4, 3.3, 4), 0.7, Color(0.95, 0.5, 0.2), Vector3(1.4, 1.0, 1.0), L.mat(Color(0.95, 0.5, 0.2), 0.8))
    L.cyl(Vector3(-4, 4.1, 4), 0.02, 0.9, Color.WHITE, false)
    # Bouncy castle: an inflatable block with turrets in the middle of the room.
    var vinyl: Material = L.mat(Color(0.95, 0.35, 0.3), 0.3)
    L.box(Vector3(0, 1.25, -24), Vector3(6.0, 2.5, 6.0), Color.RED, 0.0, true, vinyl)
    L.box(Vector3(0, 2.6, -24), Vector3(6.2, 0.3, 6.2), Color.BLUE, 0.0, false, L.mat(Color(0.3, 0.5, 0.95), 0.3))
    for tx in [-3.0, 3.0]:
        for tz in [-21.0, -27.0]:
            L.cyl(Vector3(tx, 1.8, tz), 0.8, 3.6, Color.YELLOW, true, Vector3.ZERO, L.mat(Color(0.98, 0.85, 0.2), 0.3))
            L.sphere(Vector3(tx, 3.7, tz), 0.8, Color.BLUE, Vector3(1, 0.7, 1), L.mat(Color(0.3, 0.5, 0.95), 0.3))
    for p in [Vector3(-6, 4.2, 30), Vector3(6, 4.2, 18), Vector3(-12, 4.2, 4), Vector3(12, 4.2, -4), Vector3(-6, 4.2, -18), Vector3(6, 4.2, -32)]:
        L.lamp(p, Color(1.0, 0.92, 0.85), 18.0, 2.5)
    return {
        "spawn": Vector3(0, 0.5, 30), "spawn_yaw": 0.0, "drones": 0, "safe_radius": 0.0,
        "start_weapons": ["carbine"],
        "sky_top": Color(0.2, 0.35, 0.65), "sky_horizon": Color(0.85, 0.65, 0.55),
        "sun_color": Color(1.0, 0.75, 0.55), "sun_energy": 0.7, "sun_rot": Vector3(-20, 150, 0),
        "fog": 0.006, "ambient": 0.9, "exposure": 1.05,
        "music": "res://assets/audio/music/battle_theme_a.ogg", "ambience": "res://assets/audio/ambience/clock_tick.ogg", "ambience_db": -18.0,
        "objectives": [],
        "meltdown": {
            "start": "A",
            "sections": {"A": "PARTY TABLE", "B": "GAMES ROOM", "C": "BOUNCY CASTLE"},
            "windows": lay["windows"], "doors": lay["doors"],
            "stations": [
                {"kind": "weapon", "weapon": "shotgun", "cost": 500, "pos": Vector3(-13.55, 0, 31), "facing": Vector3(1, 0, 0)},
                {"kind": "medic", "cost": 300, "pos": Vector3(13.55, 0, 30), "facing": Vector3(-1, 0, 0)},
                {"kind": "weapon", "weapon": "lmg", "cost": 1250, "pos": Vector3(19.55, 0, 8), "facing": Vector3(-1, 0, 0)},
                {"kind": "weapon", "weapon": "sniper", "cost": 1000, "pos": Vector3(19.55, 0, -7), "facing": Vector3(-1, 0, 0)},
                {"kind": "armor", "cost": 400, "pos": Vector3(-19.55, 0, 0), "facing": Vector3(1, 0, 0)},
                {"kind": "crate", "cost": 950, "pos": Vector3(6, 0, -3), "facing": Vector3(0, 0, 1)},
                {"kind": "weapon", "weapon": "launcher", "cost": 2000, "pos": Vector3(-11.55, 0, -19), "facing": Vector3(1, 0, 0)},
                {"kind": "press", "cost": 3000, "pos": Vector3(6, 0, -31), "facing": Vector3(0, 0, 1)},
            ],
        },
    }


# ========================================================== SNOW DAY ====
#   A  Snow Fort      z  16..38   (packed-snow walls)
#   B  Snowman Yard   z -10..16   (750)
#   C  Sled Shed      z -38..-10  (1250)

static func _snow_day(L) -> Dictionary:
    var rooms := [
        {"id": "A", "x0": -12, "x1": 12, "z0": 16, "z1": 38, "win_s": [0], "win_w": [27], "win_e": [22, 33], "door_x": 4, "door_cost": 750},
        {"id": "B", "x0": -18, "x1": 18, "z0": -10, "z1": 16, "win_w": [8, -4], "win_e": [2], "door_x": -6, "door_cost": 1250},
        {"id": "C", "x0": -16, "x1": 16, "z0": -38, "z1": -10, "win_w": [-24], "win_e": [-30], "win_n": [-6, 8]},
    ]
    var snow = L.tex("snow", Color(1.0, 1.0, 1.05), 6.0)
    _floors(L, rooms, snow, 24, 44, {"C": L.tex("wood_floor", Color(0.75, 0.6, 0.45), 8.0)})
    L.bounds(24, 44)
    var lay := _rooms(L, rooms, 4.0, L.tex("snow", Color(0.95, 0.97, 1.05), 3.0),
        {"C": L.tex("table_wood", Color(0.75, 0.5, 0.35), 3.0)})
    var white: Material = L.mat(Color(0.97, 0.98, 1.0), 0.6)
    # Snow fort: a pile of snowballs, a little flag.
    for k in 7:
        L.sphere(Vector3(-6 + (k % 4) * 0.55, 0.3 + int(k / 4) * 0.45, 20 + (k % 2) * 0.3), 0.3, Color.WHITE, Vector3.ONE, white)
    L.cyl(Vector3(8, 2.0, 35), 0.05, 4.0, Color(0.4, 0.3, 0.2), false)
    L.box(Vector3(8.6, 3.6, 35), Vector3(1.2, 0.7, 0.04), Color(0.2, 0.6, 0.25), 0.0, false)
    # Snowmen: a solid base, two snowballs, coal eyes, a carrot nose, a scarf.
    for p in [Vector3(8, 0, -4), Vector3(-8, 0, 6), Vector3(4, 0, 9)]:
        L.cyl(p + Vector3(0, 0.6, 0), 0.9, 1.2, Color.WHITE, true, Vector3.ZERO, white)
        L.sphere(p + Vector3(0, 1.3, 0), 1.0, Color.WHITE, Vector3.ONE, white)
        L.sphere(p + Vector3(0, 2.6, 0), 0.7, Color.WHITE, Vector3.ONE, white)
        L.sphere(p + Vector3(0, 3.5, 0), 0.5, Color.WHITE, Vector3.ONE, white)
        for ex in [-0.18, 0.18]:
            L.sphere(p + Vector3(ex, 3.62, 0.45), 0.06, Color(0.05, 0.05, 0.05))
        L.cyl(p + Vector3(0, 3.48, 0.6), 0.07, 0.4, Color(1.0, 0.5, 0.1), false, Vector3(PI / 2, 0, 0), null, 0.0)
        L.cyl(p + Vector3(0, 3.05, 0), 0.62, 0.22, Color(0.85, 0.15, 0.15), false)
    # Sled shed: sleds, skis on the wall, a firewood stack.
    for x in [-10.0, -7.0]:
        L.box(Vector3(x, 0.15, -34), Vector3(1.0, 0.15, 2.4), Color(0.8, 0.2, 0.15), 0.0, false)
    for k in 3:
        L.box(Vector3(-15.5, 1.6, -14 - k * 0.6), Vector3(0.05, 3.0, 0.15), [Color(0.2, 0.4, 0.9), Color(0.95, 0.8, 0.2), Color(0.3, 0.8, 0.4)][k], 0.0, false)
    L.box(Vector3(10, 0.6, -14), Vector3(2.0, 1.2, 1.5), Color(0.5, 0.35, 0.2), 0.0, true, L.tex("forest", Color(0.8, 0.6, 0.45), 1.5))
    for p in [Vector3(0, 3.6, 30), Vector3(-10, 3.6, 4), Vector3(10, 3.6, 2), Vector3(-6, 3.6, -22), Vector3(8, 3.6, -30)]:
        L.lamp(p, Color(1.0, 0.95, 0.85), 18.0, 1.8)
    return {
        "spawn": Vector3(0, 0.5, 30), "spawn_yaw": 0.0, "drones": 0, "safe_radius": 0.0,
        "start_weapons": ["carbine"],
        "sky_top": Color(0.55, 0.65, 0.8), "sky_horizon": Color(0.88, 0.9, 0.95),
        "sun_color": Color(0.95, 0.97, 1.0), "sun_energy": 0.9, "sun_rot": Vector3(-35, 60, 0),
        "fog": 0.012, "ambient": 1.0, "exposure": 0.95, "snow": true,
        "music": "res://assets/audio/music/determined_pursuit.ogg", "ambience": "res://assets/audio/ambience/desert_wind.ogg", "ambience_db": -14.0,
        "objectives": [],
        "meltdown": {
            "start": "A",
            "sections": {"A": "SNOW FORT", "B": "SNOWMAN YARD", "C": "SLED SHED"},
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


# ===================================================== THE BIG FLUSH ====
# A whole bathroom at toy scale (1 m = 32 units; the toilet is a bit bigger
# than life). Four areas, opened in order:
#   A  The Bowl     inside the toilet; the floor is the water, 12 up.
#                   Melties crawl through the hollow porcelain and crack the
#                   bowl in three places (porcelain "windows").
#   B  The Floor    the front of the room: rug, slippers, duck, the vanity.
#                   Reached by buying the toilet paper (a ramp over the rim).
#   C  The Corner   behind a heap of towels on the right: bin, plunger, bleach.
#   D  The Tub      a towel ramp up and over the side; the Re-Mold Press is in it.
const FLUSH_T := 60.0             # toilet scale: profile metres -> units
const FLUSH_C := Vector3(4, 0, -19)   # toilet centre
const FLUSH_OVAL := 1.25          # the bowl is longer front to back
## The toilet's shape, [radius m, height m]: inside from the middle of the
## water up to the rim (a short wall all round the water, then slopes too
## steep to climb), the rim, then the outside down to the floor.
const FLUSH_IN := [[0.0, 0.2], [0.105, 0.2], [0.11, 0.245], [0.15, 0.275], [0.18, 0.32], [0.195, 0.37], [0.2, 0.41]]
const FLUSH_OUT := [[0.205, 0.415], [0.25, 0.415], [0.262, 0.39], [0.245, 0.3], [0.19, 0.2], [0.135, 0.12], [0.12, 0.05], [0.15, 0.0]]
const FLUSH_CRACKS := [0.0, 45.0, 120.0]      # degrees round the bowl (90 = front, where the paper goes)


static func _flush_pt(r: float, y: float, deg: float) -> Vector3:
    var a := deg_to_rad(deg)
    return FLUSH_C + Vector3(cos(a) * r, y, sin(a) * r * FLUSH_OVAL) * FLUSH_T


## Outward normal of the oval bowl at an angle.
static func _flush_normal(deg: float) -> Vector3:
    var a := deg_to_rad(deg)
    return Vector3(cos(a), 0, sin(a) / FLUSH_OVAL).normalized()


static func _big_flush(L) -> Dictionary:
    var porcelain: StandardMaterial3D = L.mat(Color(0.93, 0.95, 0.98), 0.18)
    porcelain.cull_mode = BaseMaterial3D.CULL_DISABLED
    # ---- floor, walls, ceiling ----
    L.box(Vector3(0, -0.5, 0), Vector3(104, 1, 128), Color.GRAY, 0.0, true, L.tex("concrete", Color(0.45, 0.43, 0.42), 9.0))
    L.box(Vector3(0, 0.02, 0), Vector3(72, 0.04, 96), Color.GRAY, 0.0, false, L.tex("tiles", Color(0.82, 0.9, 1.0), 9.6, 0.3))
    L.bounds(50, 62)
    var wall = L.tex("tiles", Color(0.92, 0.97, 1.0), 4.8, 0.3)
    var H := 78.0
    # Holes at floor level: [centre, width, floor height]. Melties come in
    # under the door, through a mouse hole, a heating vent, behind the bin and
    # up the tub's overflow pipe.
    _flush_wall(L, true, 48, -36, 36, [[10, 2.8, 0.0]], H, wall)                  # front: under the door
    _flush_wall(L, true, -48, -36, 36, [[28, 2.8, 0.0], [-25, 2.8, 2.0]], H, wall) # back: corner, tub pipe
    _flush_wall(L, false, -36, -48, 48, [[30, 2.8, 0.0]], H, wall)                # left: mouse hole
    _flush_wall(L, false, 36, -48, 48, [[40, 2.8, 0.0], [-30, 2.8, 0.0]], H, wall) # right: vent, corner
    L.box(Vector3(0, H + 0.5, 0), Vector3(74, 1, 98), Color(0.95, 0.95, 0.93), 0.0, false)
    L.box(Vector3(10, 41.7, 47.45), Vector3(26, 76.6, 0.3), Color(0.85, 0.82, 0.76), 0.0, false)   # the door (a gap under it)
    L.box(Vector3(-25, 1.0, -52), Vector3(8, 2.0, 8), Color(0.5, 0.5, 0.52), 0.0, true)        # the overflow pipe outside
    # ---- the toilet ----
    _flush_toilet(L, porcelain)
    # ---- the tub (D): built so you can stand in it ----
    var tub_m: StandardMaterial3D = L.mat(Color(0.95, 0.96, 0.98), 0.2)
    L.box(Vector3(-24.8, 1.0, -20.8), Vector3(22.4, 2.0, 54.4), Color.WHITE, 0.0, true, tub_m)      # floor of the tub
    L.box(Vector3(-35.2, 9.6, -20.8), Vector3(1.6, 15.2, 54.4), Color.WHITE, 0.0, true, tub_m)      # against the wall
    L.box(Vector3(-14.4, 8.8, -20.8), Vector3(1.6, 17.6, 54.4), Color.WHITE, 0.0, true, tub_m)      # room side
    L.box(Vector3(-24.8, 8.8, 5.6), Vector3(22.4, 17.6, 1.6), Color.WHITE, 0.0, true, tub_m)        # front end
    # back end, with the overflow hole the Melties climb out of
    L.box(Vector3(-31.4, 8.8, -47.2), Vector3(9.2, 17.6, 1.6), Color.WHITE, 0.0, true, tub_m)
    L.box(Vector3(-18.2, 8.8, -47.2), Vector3(9.2, 17.6, 1.6), Color.WHITE, 0.0, true, tub_m)
    L.box(Vector3(-24.8, 11.4, -47.2), Vector3(4.0, 12.4, 1.6), Color.WHITE, 0.0, true, tub_m)
    for z in [-20.8]:
        L.cyl(Vector3(-14.4, 17.6, z), 0.95, 54.4, Color.WHITE, false, Vector3(PI / 2, 0, 0), tub_m)  # rounded rim
    L.cyl(Vector3(-24.8, 17.6, 5.6), 0.95, 22.4, Color.WHITE, false, Vector3(0, 0, PI / 2), tub_m)
    var chrome: StandardMaterial3D = L.mat(Color(0.82, 0.84, 0.88), 0.15, 0.9)
    L.cyl(Vector3(-24.8, 14.0, -44.5), 0.8, 5.0, Color.GRAY, false, Vector3(PI / 2, 0, 0), chrome)   # tap
    L.cyl(Vector3(-24.8, 2.05, -38), 1.6, 0.1, Color(0.2, 0.2, 0.22), false)                          # plughole
    L.water(Vector3(-27, 2.1, -34), Vector2(9, 12), Color(0.6, 0.8, 0.95, 0.55))
    # ---- props ----
    var P := "bathroom/"
    _prop_at(L, P + "polyhaven/rubber_duck_toy.glb", Vector3(-4, 0, 18), 2.4, Vector3(0, 5.2, 0))
    _prop_at(L, P + "polyhaven/rubber_duck_toy.glb", Vector3(-22, 2, -28), -0.7, Vector3(0, 4.0, 0))     # in the tub
    _prop_at(L, P + "kenney/rugRounded.glb", Vector3(-2, 0.05, 26), 0.0, Vector3(30, 0, 0), false)
    _prop_at(L, P + "tiny_treats/slippers.glb", Vector3(20, 0, 30), -0.4, Vector3(10, 0, 0))
    _prop_at(L, P + "tiny_treats/towel_stacked.glb", Vector3(-30, 0, 24), 0.2, Vector3(0, 5.8, 0))
    _prop_at(L, P + "tiny_treats/towel_blue.glb", Vector3(14, 0, 42), 0.6, Vector3(13, 0, 0))
    _prop_at(L, P + "tiny_treats/towel_pink.glb", Vector3(-8, 0, 41), -0.9, Vector3(12, 0, 0))
    _prop_at(L, P + "kenney/bathroomSink.glb", Vector3(29.5, 0, 14), -PI / 2, Vector3(0, 27, 0))
    _prop_at(L, P + "kenney/bathroomMirror.glb", Vector3(33.4, 32, 14), -PI / 2, Vector3(0, 16, 0), false)
    _prop_at(L, P + "kenney/bathroomCabinetDrawer.glb", Vector3(-28, 0, 44), PI, Vector3(0, 14, 0))
    _prop_at(L, P + "tiny_treats/toothbrush_cup.glb", Vector3(-30, 14, 44), 0.0, Vector3(0, 3.5, 0), false)
    _prop_at(L, P + "tiny_treats/toothbrush_blue.glb", Vector3(-26, 14.4, 44), 0.4, Vector3(0, 0, 5.5), false)
    _prop_at(L, P + "kenney/trashcan.glb", Vector3(30, 0, -38), 0.3, Vector3(0, 9.6, 0))
    _prop_at(L, P + "polyhaven/plunger.glb", Vector3(24, 0, -43), 0.5, Vector3(0, 15, 0))
    _prop_at(L, P + "polyhaven/bleach_bottle.glb", Vector3(24, 0, -27), 0.8, Vector3(0, 8.6, 0))
    _prop_at(L, P + "tiny_treats/container_bathroom_A_blue.glb", Vector3(-35.2, 18.6, -10), 0.0, Vector3(0, 6.4, 0), false)
    _prop_at(L, P + "tiny_treats/container_bathroom_C_pink.glb", Vector3(-35.2, 18.6, -4), 0.0, Vector3(0, 5.8, 0), false)
    _prop_at(L, P + "tiny_treats/container_bathroom_B_yellow.glb", Vector3(-35.2, 18.6, 2), 0.0, Vector3(0, 6.4, 0), false)
    # A crumpled towel on the floor (cover).
    for i in 6:
        var a := i * 1.1
        L.sphere(Vector3(-14 + cos(a) * 2.4, 1.2, 34 + sin(a) * 1.8), 2.4, Color(0.98, 0.85, 0.35), Vector3(1.0, 0.55, 1.0))
    # The heap of towels across the corner (C), with its doorway.
    var towel_m = L.tex("carpet", Color(1.3, 1.3, 1.25), 3.0)
    L.box(Vector3(15.75, 3.0, -14), Vector3(23.5, 6.0, 3.0), Color.WHITE, 0.0, true, towel_m)
    L.box(Vector3(33.85, 3.0, -14), Vector3(4.3, 6.0, 3.0), Color.WHITE, 0.0, true, towel_m)
    var towel_cols := [Color(0.55, 0.78, 1.0), Color(1.0, 0.75, 0.82), Color(1.0, 0.9, 0.45), Color(0.95, 0.95, 0.95)]
    for k in 9:
        var x := 6.0 + k * 3.0 if k < 8 else 33.8
        L.sphere(Vector3(x, 5.6 + (k % 2) * 0.6, -14 + ((k % 3) - 1) * 0.6), 2.2, towel_cols[k % 4], Vector3(1.0, 0.6, 0.9), L.tex("carpet", towel_cols[k % 4] * 1.3, 2.0))
    # The waste pipe behind the toilet keeps the corner shut off underneath it.
    L.box(Vector3(4, 4.0, -39), Vector3(4.0, 8.0, 18.0), Color.WHITE, 0.0, true, porcelain)
    # ---- lights: two ceiling lamps, plus fill ----
    var lights: Array = []
    var glow: Array = []
    for x in [-12.0, 14.0]:
        L.prop(P + "polyhaven/modern_ceiling_lamp_01.glb", Vector3(x, H - 9.0, 2), 0.0, Vector3(10, 0, 0), false)
        var gm: StandardMaterial3D = L.glow_mat(Color(1.0, 0.93, 0.78), 3.0)
        L.sphere(Vector3(x, H - 8.0, 2), 2.0, Color.WHITE, Vector3.ONE, gm)
        glow.append(gm)
        lights.append(L.lamp(Vector3(x, H - 12.0, 2), Color(1.0, 0.92, 0.78), 110.0, 2.4, false))
    for p in [Vector3(4, 34, -19), Vector3(0, 24, 26), Vector3(28, 20, -30), Vector3(-25, 24, -20)]:
        lights.append(L.lamp(p, Color(1.0, 0.94, 0.85), 40.0, 1.0, false))

    # ---- MELTDOWN layout ----
    var windows: Array = []
    for deg in FLUSH_CRACKS:
        var n := _flush_normal(deg)
        var at := _flush_pt(0.1075, 0.2, deg)
        # The Melties climb up the outside of the toilet and appear on the
        # landing at the top of their melted-plastic ramp.
        var landing := _flush_pt(0.205, 0.2, deg) + n * 1.5
        var depth := (landing - at).dot(n)
        windows.append([at, n, "A", "porcelain", Vector2(depth - 0.8, depth + 0.8)])
    windows += [
        [Vector3(10, 0, 48), Vector3(0, 0, 1), "B"], [Vector3(-36, 0, 30), Vector3(-1, 0, 0), "B"], [Vector3(36, 0, 40), Vector3(1, 0, 0), "B"],
        [Vector3(36, 0, -30), Vector3(1, 0, 0), "C"], [Vector3(28, 0, -48), Vector3(0, 0, -1), "C"],
        [Vector3(-25, 2, -46.4), Vector3(0, 0, -1), "D"],
    ]
    # The toilet paper: from the water, up and over the front rim, down to the floor.
    var paper: Array = []
    for p in [[0.2, -0.02], [0.43, 0.27], [0.43, 0.335], [0.0, 0.885]]:
        paper.append(FLUSH_C + Vector3(0, p[0], p[1]) * FLUSH_T)
    var towel := [Vector3(-24.8, 0, 30), Vector3(-24.8, 18.8, 7.6), Vector3(-24.8, 18.8, 3.8), Vector3(-24.8, 2.0, -16)]
    var lip := func(deg: float) -> Vector3: return _flush_pt(0.1075, 0.2, deg)
    return {
        "spawn": FLUSH_C + Vector3(0, 12.5, -3), "spawn_yaw": PI, "drones": 0, "safe_radius": 0.0,
        "start_weapons": ["carbine"],
        "sky_top": Color(0.1, 0.1, 0.12), "sky_horizon": Color(0.2, 0.2, 0.22),
        "sun_color": Color(1.0, 0.95, 0.88), "sun_energy": 0.25, "sun_rot": Vector3(-70, 30, 0),
        "fog": 0.002, "ambient": 1.1, "exposure": 1.1,
        "music": "res://assets/audio/music/determined_pursuit.ogg", "ambience": "res://assets/audio/ambience/clock_tick.ogg", "ambience_db": -16.0,
        "objectives": [],
        "meltdown": {
            "start": "A",
            "sections": {"A": "BOWL", "B": "BATHROOM FLOOR", "C": "CORNER", "D": "BATHTUB"},
            "windows": windows,
            "doors": [
                {"pos": FLUSH_C + Vector3(0, 12, 6), "width": 6.6, "cost": 750, "opens": "B", "verb": "UNROLL THE TOILET PAPER",
                    "ramp": paper, "ramp_width": 6.6, "ramp_look": "paper", "roll": FLUSH_C + Vector3(0, 25.8 + 3.2, 19)},
                {"pos": Vector3(29.6, 0, -14), "width": 4.2, "cost": 1000, "opens": "C", "verb": "MOVE THE TOWELS"},
                {"pos": Vector3(-24.8, 0, 32), "width": 6.0, "cost": 1250, "opens": "D", "verb": "LAY THE TOWEL",
                    "ramp": towel, "ramp_width": 6.0, "ramp_look": "towel", "roll": Vector3(-24.8, 2.8, 33)},
            ],
            "stations": [
                {"kind": "weapon", "weapon": "shotgun", "cost": 500, "pos": lip.call(210.0), "facing": -_flush_normal(210.0)},
                {"kind": "medic", "cost": 300, "pos": lip.call(300.0), "facing": -_flush_normal(300.0)},
                {"kind": "weapon", "weapon": "lmg", "cost": 1250, "pos": Vector3(-35.55, 0, 16), "facing": Vector3(1, 0, 0)},
                {"kind": "armor", "cost": 400, "pos": Vector3(-20, 0, 47.55), "facing": Vector3(0, 0, -1)},
                {"kind": "crate", "cost": 950, "pos": Vector3(12, 0, 22), "facing": Vector3(0, 0, 1)},
                {"kind": "weapon", "weapon": "sniper", "cost": 1000, "pos": Vector3(35.55, 0, 30), "facing": Vector3(-1, 0, 0)},
                {"kind": "weapon", "weapon": "launcher", "cost": 2000, "pos": Vector3(35.55, 0, -42), "facing": Vector3(-1, 0, 0)},
                {"kind": "press", "cost": 3000, "pos": Vector3(-24.8, 2, -22), "facing": Vector3(0, 0, 1)},
            ],
        },
    }


## L.prop puts a model's origin at pos; these models' origins are at a corner,
## so move each one so its middle is at pos.
static func _prop_at(L, path: String, pos: Vector3, rot_y := 0.0, fit := Vector3.ZERO, collide := true) -> Node3D:
    var n: Node3D = L.prop(path, pos, rot_y, fit, collide)
    if n == null:
        return null
    var box := AABB()
    var first := true
    for m in n.find_children("*", "MeshInstance3D", true, false):
        var b: AABB = m.global_transform * m.get_aabb()
        box = b if first else box.merge(b)
        first = false
    if not first:
        n.position += Vector3(pos.x - box.get_center().x, 0, pos.z - box.get_center().z)
    return n


## The broken rim of a crack: a jagged band of chipped porcelain round an
## oval hole (see-through), with hairline cracks running out from it.
static func _flush_crack_tex() -> ImageTexture:
    var W := 256
    var Hh := 224
    var img := Image.create(W, Hh, false, Image.FORMAT_RGBA8)
    img.fill(Color(0, 0, 0, 0))
    var rng := RandomNumberGenerator.new()
    rng.seed = 42
    var c := Vector2(W * 0.5, Hh * 0.52)
    var rx := W * 0.24
    var ry := Hh * 0.27
    var edge := PackedFloat32Array()            # jagged radius per angle
    for k in 72:
        edge.append(1.0 + rng.randf_range(-0.06, 0.12) + (0.12 if k % 7 == 0 else 0.0))
    for y in Hh:
        for x in W:
            var d := Vector2(x, y) - c
            var a := fposmod(atan2(d.y / ry, d.x / rx), TAU)
            var r := Vector2(d.x / rx, d.y / ry).length()
            var e: float = edge[int(a / TAU * 72.0) % 72]
            if r > e and r < e + 0.16:
                # chipped edge: rough grey porcelain, darker toward the hole
                var t := (r - e) / 0.16
                img.set_pixel(x, y, Color(0.55, 0.53, 0.5).lerp(Color(0.82, 0.83, 0.85), t))
    # hairline cracks running out from the edge
    for k in 9:
        var a := rng.randf() * TAU
        var p := c + Vector2(cos(a) * rx, sin(a) * ry) * 1.15
        var dir := Vector2(cos(a), sin(a))
        for s in 40:
            dir = dir.rotated(rng.randf_range(-0.35, 0.35))
            p += dir * 2.0
            if p.x < 1 or p.y < 1 or p.x > W - 2 or p.y > Hh - 2:
                break
            img.set_pixel(int(p.x), int(p.y), Color(0.45, 0.43, 0.42))
            img.set_pixel(int(p.x) + 1, int(p.y), Color(0.62, 0.62, 0.62))
    img.generate_mipmaps()
    return ImageTexture.create_from_image(img)


static func _flush_goo(body: StaticBody3D, m: Material, pos: Vector3, size: Vector3, rot: Vector3) -> void:
    var mi := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = size
    mi.mesh = bm
    mi.material_override = m
    var cs := CollisionShape3D.new()
    var bs := BoxShape3D.new()
    bs.size = size
    cs.shape = bs
    for n in [mi, cs]:
        n.position = pos
        n.rotation = rot
        body.add_child(n)


## A tall wall along X (along=true, constant z) or Z with small holes at the
## bottom: [centre, width, floor height]. Each hole is 3.2 tall.
static func _flush_wall(L, along_x: bool, at: float, a0: float, a1: float, holes: Array, h: float, m: Material) -> void:
    var cuts: Array = [[a0, a0]]
    for g in holes:
        cuts.append([g[0] - g[1] * 0.5, g[0] + g[1] * 0.5])
    cuts.append([a1, a1])
    cuts.sort_custom(func(x, y): return x[0] < y[0])
    for k in cuts.size() - 1:
        var lo: float = cuts[k][1]
        var hi: float = cuts[k + 1][0]
        if hi - lo > 0.05:
            var c := (lo + hi) * 0.5
            L.box(Vector3(c, h * 0.5, at) if along_x else Vector3(at, h * 0.5, c), Vector3(hi - lo, h, 0.8) if along_x else Vector3(0.8, h, hi - lo), Color.GRAY, 0.0, true, m)
    for g in holes:
        var y0: float = g[2]
        var top := y0 + 3.2
        var c: float = g[0]
        var w: float = g[1]
        L.box(Vector3(c, (top + h) * 0.5, at) if along_x else Vector3(at, (top + h) * 0.5, c), Vector3(w, h - top, 0.8) if along_x else Vector3(0.8, h - top, w), Color.GRAY, 0.0, true, m)
        if y0 > 0.0:
            L.box(Vector3(c, y0 * 0.5, at) if along_x else Vector3(at, y0 * 0.5, c), Vector3(w, y0, 0.8) if along_x else Vector3(0.8, y0, w), Color.GRAY, 0.0, true, m)


## The toilet: a lathe of the profile, with holes cut in the short wall round
## the water where the cracks are, a hidden floor inside the porcelain for the
## Melties to crawl along, and the cistern behind.
static func _flush_toilet(L, porcelain: Material) -> void:
    var prof: Array = FLUSH_IN.duplicate()
    prof += FLUSH_OUT
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var seg := 72
    var hole_pts: Array = FLUSH_CRACKS.map(func(d): return _flush_pt(0.1075, 0.2, d))
    for i in prof.size() - 1:
        for j in seg:
            var d0 := 360.0 * j / seg
            var d1 := 360.0 * (j + 1) / seg
            if i == 1 or i == 10:          # the short wall round the water, and the outside: cut the cracks through
                var outer := i == 10
                var mid := _flush_pt(0.2175 if outer else 0.1075, 0.25 if outer else 0.2, (d0 + d1) * 0.5)
                var cut := false
                for k in hole_pts.size():
                    var hp: Vector3 = _flush_pt(0.2175, 0.25, FLUSH_CRACKS[k]) if outer else hole_pts[k]
                    if mid.distance_to(hp) < (1.9 if outer else 1.6):
                        cut = true
                if cut:
                    continue
            var p00 := _flush_pt(prof[i][0], prof[i][1], d0)
            var p01 := _flush_pt(prof[i][0], prof[i][1], d1)
            var p10 := _flush_pt(prof[i + 1][0], prof[i + 1][1], d0)
            var p11 := _flush_pt(prof[i + 1][0], prof[i + 1][1], d1)
            for v in [p00, p10, p11, p00, p11, p01]:
                st.add_vertex(v)
    st.generate_normals()
    var mesh := st.commit()
    var mi := MeshInstance3D.new()
    mi.mesh = mesh
    mi.material_override = porcelain
    L.add_child(mi)
    var body := StaticBody3D.new()
    body.collision_layer = 1
    var cs := CollisionShape3D.new()
    var shape := ConcavePolygonShape3D.new()
    shape.set_faces(mesh.get_faces())
    shape.backface_collision = true
    cs.shape = shape
    body.add_child(cs)
    L.add_child(body)
    # The hollow inside the porcelain: a ring of floor at water height.
    var ring := StaticBody3D.new()
    ring.collision_layer = 1
    L.add_child(ring)
    for j in 36:
        var deg := j * 10.0
        var c := _flush_pt(0.15, 0.2, deg) - Vector3(0, 0.25, 0)
        var rcs := CollisionShape3D.new()
        var bs := BoxShape3D.new()
        bs.size = Vector3(2.8, 0.5, 6.0)
        rcs.shape = bs
        rcs.position = c
        rcs.rotation.y = atan2(_flush_normal(deg).x, _flush_normal(deg).z)
        ring.add_child(rcs)
    # Through each crack: the broken porcelain floor of the passage, and the
    # Melties' ramp of melted tan plastic up the outside of the toilet.
    var goo: StandardMaterial3D = L.mat(Color(0.72, 0.52, 0.33), 0.18)
    var ramps := StaticBody3D.new()
    ramps.collision_layer = 4        # Melties walk it; not part of the navigation mesh
    ramps.collision_mask = 0
    L.add_child(ramps)
    for deg in FLUSH_CRACKS:
        var n := _flush_normal(deg)
        var yaw := atan2(n.x, n.z)
        var floor_pt := _flush_pt(0.155, 0.2, deg) - Vector3(0, 0.15, 0)
        var fl := MeshInstance3D.new()
        var fbm := BoxMesh.new()
        fbm.size = Vector3(3.4, 0.3, 7.0)
        fl.mesh = fbm
        fl.material_override = porcelain
        L.add_child(fl)
        fl.position = floor_pt
        fl.rotation.y = yaw
        # Broken edges and cracks spreading out round the hole (inside the bowl).
        var dec := MeshInstance3D.new()
        var qm := QuadMesh.new()
        qm.size = Vector2(6.4, 5.6)
        dec.mesh = qm
        var dm := StandardMaterial3D.new()
        dm.albedo_texture = _flush_crack_tex()
        dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
        dm.alpha_scissor_threshold = 0.4
        dm.cull_mode = BaseMaterial3D.CULL_DISABLED
        dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        dm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
        dec.material_override = dm
        L.add_child(dec)
        dec.position = _flush_pt(0.1075, 0.2, deg) - n * 0.18 + Vector3(0, 1.4, 0)
        dec.rotation.y = yaw
        var top := _flush_pt(0.205, 0.2, deg)
        var land_c := top + n * 1.5 - Vector3(0, 0.3, 0)
        _flush_goo(ramps, goo, land_c, Vector3(4.0, 0.6, 3.6), Vector3(0, yaw, 0))
        L.lamp(land_c + Vector3(0, 3.0, 0) - n * 2.0, Color(1.0, 0.9, 0.75), 12.0, 1.4, false)   # light through the crack
        var drop := 12.0
        var run := drop / tan(deg_to_rad(38.0))
        var slope_len := sqrt(drop * drop + run * run)
        var mid := top + n * (3.3 + run * 0.5) + Vector3(0, -drop * 0.5 - 0.3, 0)
        _flush_goo(ramps, goo, mid, Vector3(4.0, 0.6, slope_len + 0.6), Vector3(atan2(drop, run), yaw, 0))
        # drips down the sides
        for k in 4:
            var d := MeshInstance3D.new()
            var sm := SphereMesh.new()
            sm.radius = randf_range(0.4, 0.7)
            sm.height = sm.radius * 3.0
            d.mesh = sm
            d.material_override = goo
            L.add_child(d)
            d.position = top + n * (3.6 + k * run * 0.25) + Vector3(0, -k * drop * 0.25 - 0.8, 0) + n.cross(Vector3.UP) * (2.0 if k % 2 == 0 else -2.0)
    # Cistern and flush handle, against the back wall.
    L.box(FLUSH_C + Vector3(0, 37.2, -24.0), Vector3(26.4, 25.2, 10.2), Color.WHITE, 0.0, true, porcelain)
    L.box(FLUSH_C + Vector3(0, 50.7, -24.0), Vector3(27.6, 1.8, 11.4), Color.WHITE, 0.0, true, porcelain)
    L.box(FLUSH_C + Vector3(-8.4, 46.8, -18.6), Vector3(3.6, 1.2, 1.8), Color.GRAY, 0.0, false, L.mat(Color(0.82, 0.84, 0.88), 0.15, 0.9))
