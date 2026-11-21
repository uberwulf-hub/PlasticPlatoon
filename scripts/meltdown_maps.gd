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
    # Revision 1 (ChatGPT review): room walls toward neutral concrete grey (#85827A).
    var wall: StandardMaterial3D = L.tex("plaster", BM_WALL, 5.0).duplicate()
    wall.emission_enabled = true              # shadows no darker than #555957
    wall.emission = Color("555957")
    wall.emission_energy_multiplier = BM_WALL_FLOOR
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
        L.lamp(p, BM_ROOM_BULB, 20.0, 3.2)
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
const BM_CARD := Color("b08a5a")        # cardboard (seams are this darkened)
const BM_BOX_FLOOR := 1.0               # strength of the #806D53 minimum on dark box faces
const BM_TAPE := Color("d2b27a")        # packing tape (lighter, glossier)
const BM_TOOL := Color("c7322a")        # red toolbox
const BM_SOFA := Color("b5532e")        # burnt-orange sofa (first build; revision 1 uses the colours in _bm_sofa)
const BM_SOFA_FLOOR := 0.45             # strength of the #553A32 minimum on the sofa
const BM_COPPER := Color("b8733a")
const BM_PINE := Color("d9b98a")        # 2x4 lumber
const BM_BULB := Color("ffd9a0")
const BM_WALL := Color("85827a")        # room walls (revision 1)
const BM_WALL_FLOOR := 0.75             # strength of the #555957 minimum on the walls
const BM_ROOM_BULB := Color(1.0, 0.9, 0.78)   # the rooms' bulbs, a softer warm (was 1.0, 0.82, 0.6)
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
    # Revision 1: moved out and shortened so warm light stays on the furniture,
    # not the outer rooms.
    for f in [[Vector3(26, 24, 16), Color("fff1dc"), 22.0, 2.0], [Vector3(0, 30, 50), Color("ffd2a6"), 29.0, 4.5],
            [Vector3(-27, 26, 10), Color("ffdcae"), 24.0, 3.0], [Vector3(-30, 18, -40), Color("ffe6c8"), 18.0, 2.0],
            [Vector3(6, 26, -46), Color("a9c1ff"), 20.0, 2.0]]:
        L.lamp(f[0], f[1], f[2], f[3], false)


## Front-loading washing machine, door facing -x (into the room). base = floor centre.
static func _bm_washer(L, base: Vector3, body := BM_ENAMEL, glass := BM_GLASS, clothes := true) -> void:
    var enamel = L.mat(body, 0.3)
    var W := 16.0
    var H := 22.0
    var D := 16.0
    var fx: float = base.x - D * 0.5          # the front face
    L.box(base + Vector3(0, H * 0.5 + 0.8, 0), Vector3(D, H - 1.6, W), Color.WHITE, 0.0, false, enamel)
    L.box(base + Vector3(0, 0.4, 0), Vector3(D - 0.6, 0.8, W - 0.6), Color("3a3a3a"), 0.0, false)    # kick plate
    L.box(base + Vector3(0, H - 0.4, 0), Vector3(D, 0.8, W), Color.WHITE, 0.0, false, L.mat(body.darkened(0.06), 0.25))
    # Control panel along the top, a dial and a little glowing display.
    L.box(Vector3(fx - 0.1, H - 3.0, base.z), Vector3(0.3, 3.2, W - 0.6), Color.WHITE, 0.0, false, L.mat(Color("d4d4d2"), 0.35))
    L.cyl(Vector3(fx - 0.5, H - 3.0, base.z + 4.5), 1.25, 0.7, BM_CHROME, false, Vector3(0, 0, PI / 2), L.mat(BM_CHROME, 0.2, 0.8))
    L.box(Vector3(fx - 0.3, H - 3.0, base.z - 1.0), Vector3(0.2, 1.0, 3.2), Color.WHITE, 0.0, false, L.glow_mat(Color("5fd3c8"), 1.2))
    L.box(Vector3(fx - 0.3, H - 3.0, base.z - 5.2), Vector3(0.3, 1.6, 3.4), Color.WHITE, 0.0, false, L.mat(body.darkened(0.12), 0.35))  # drawer
    # The round door: chrome ring, dark glass, laundry tumbling behind it.
    var c := Vector3(fx - 0.2, 9.5, base.z)
    L.cyl(c, 6.0, 0.8, BM_CHROME, false, Vector3(0, 0, PI / 2), L.mat(BM_CHROME, 0.18, 0.85))
    L.cyl(c + Vector3(-0.3, 0, 0), 4.7, 0.6, glass, false, Vector3(0, 0, PI / 2), L.mat(glass, 0.05, 0.3))
    var cloth := [Color("d94a4a"), Color("f2c230"), Color("f4f1ea"), Color("3f7fd6")]
    for i in (4 if clothes else 0):
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
    # Revision 1 (ChatGPT review): flat upholstery colours, 8 m raised cushions,
    # #553A32 in the creases and under the skirt, #D9A17E piping on the edges.
    var main := _bm_floored(Color("986047"), Color("553a32"), 0.95)
    var seat := _bm_floored(Color("c58b69"), Color("553a32"), 0.95)
    var back_c := _bm_floored(Color("b9795b"), Color("553a32"), 0.95)
    var shade := _bm_floored(Color("553a32"), Color("553a32"), 1.0)
    var hi := _bm_floored(Color("d9a17e"), Color("553a32"), 0.8)
    var W := 68.0
    var fz: float = base.z - 10.0          # front of the seat
    L.box(Vector3(base.x, 6.5, base.z), Vector3(W, 11.0, 20.0), Color.WHITE, 0.0, false, main)         # body / skirt
    L.box(Vector3(base.x, 1.2, base.z - 0.2), Vector3(W - 0.4, 1.6, 20.0), Color.WHITE, 0.0, false, shade)   # shadow under the skirt
    L.box(Vector3(base.x, 21.0, base.z + 12.0), Vector3(W + 0.2, 30.0, 6.0), Color.WHITE, 0.0, false, main)  # back (6..36)
    var cw := W / 3.0
    for i in 3:
        var x: float = base.x + (i - 1) * cw
        L.box(Vector3(x, 16.0, base.z - 1.0), Vector3(cw - 1.2, 8.0, 20.5), Color.WHITE, 0.0, false, seat)        # seat cushion 12..20
        L.box(Vector3(x, 19.85, fz - 0.05), Vector3(cw - 1.4, 0.5, 0.5), Color.WHITE, 0.0, false, hi)             # piping, front top edge
        L.box_rot(Vector3(x, 28.0, base.z + 7.5), Vector3(cw - 1.4, 16.0, 6.0), Color.WHITE, Vector3(-0.16, 0, 0), false, back_c)  # back cushion
    for i in 2:                                                                                                   # creases between cushions
        var cx: float = base.x + (i - 0.5) * cw
        L.box(Vector3(cx, 16.0, base.z - 1.0), Vector3(1.1, 7.8, 20.4), Color.WHITE, 0.0, false, shade)
        L.box(Vector3(cx, 28.0, base.z + 8.0), Vector3(1.3, 15.5, 5.0), Color.WHITE, 0.0, false, shade)
    L.box(Vector3(base.x, 12.3, fz + 0.4), Vector3(W, 0.6, 1.0), Color.WHITE, 0.0, false, shade)                    # seat meets the skirt
    for s in [-1.0, 1.0]:
        var ax: float = base.x + s * (W * 0.5 + 4.0)
        L.box(Vector3(ax, 11.0, base.z + 1.0), Vector3(8.0, 22.0, 22.0), Color.WHITE, 0.0, false, main)
        L.cyl(Vector3(ax, 22.0, base.z + 1.0), 4.4, 22.0, Color.WHITE, false, Vector3(PI / 2, 0, 0), main)          # rolled arm
        L.box(Vector3(ax, 26.3, base.z + 1.0), Vector3(1.4, 0.4, 22.2), Color.WHITE, 0.0, false, hi)                # highlight on the roll
        L.box(Vector3(ax - s * 4.05, 11.0, base.z + 1.0), Vector3(0.3, 21.0, 22.0), Color.WHITE, 0.0, false, shade) # crease beside the seat
    var foot = L.tex("table_wood", Color("5a3a22"), 2.0)
    for s in [-1.0, 1.0]:
        for z in [fz + 2.0, base.z + 12.0]:
            L.cyl(Vector3(base.x + s * (W * 0.5 + 2.0), 0.5, z), 1.4, 1.0, Color.BROWN, false, Vector3.ZERO, foot)


## A plain colour that never renders darker than `floor_c` (a faint glow of that
## colour), so faces turned away from the light keep the spec's shadow tone.
static func _bm_floored(c: Color, floor_c: Color, rough: float, energy := BM_SOFA_FLOOR) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.roughness = rough
    m.emission_enabled = true
    m.emission = floor_c
    m.emission_energy_multiplier = energy
    return m


## A taped cardboard storage box with a marker label on the side facing the play area (+x).
static func _bm_box(L, base: Vector3, size: Vector3, rot_y: float, word: String) -> void:
    # Revision 1 (ChatGPT review): lit faces #C5A477; a faint #806D53 glow keeps
    # faces turned away from the light from going darker than that.
    var card := StandardMaterial3D.new()
    card.albedo_color = Color("c5a477")
    card.roughness = 0.95
    card.emission_enabled = true
    card.emission = Color("806d53")
    card.emission_energy_multiplier = BM_BOX_FLOOR
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
        L.lamp(Vector3(p.x, Y - 24.0, p.z), BM_BULB, 100.0, 1.2, false)
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


# ---- Midnight Kitchen: giant scale (Creative Collaboration: Plastic Platoon art pass, round 2) ----
# Art direction: ChatGPT (creative director); spec approved by Andrew, 2026-11-21.
# Same rules as The Basement: 25x human scale, every giant prop outside the play
# edge (|x| > 24, |z| > 46) or overhead with no collision; colours are the spec's
# hex values, and _bm_floored keeps a face from rendering darker than the spec's
# shadow colour. Nothing random except the cereal, which uses a fixed seed.

## Checkerboard lino for the floor outside the rooms: a 32 x 32 picture made
## here in code (two muted squares and grout lines), tiled every 15 m (7.5 m squares).
static func _gk_lino() -> StandardMaterial3D:
    var img := Image.create(32, 32, false, Image.FORMAT_RGB8)
    var a := Color("66717a")
    var b := Color("46525d")
    var g := Color("303b45")
    for y in 32:
        for x in 32:
            var c: Color = a if ((x < 16) == (y < 16)) else b
            if x % 16 == 0 or y % 16 == 0:
                c = g
            img.set_pixel(x, y, c)
    var m := StandardMaterial3D.new()
    m.albedo_texture = ImageTexture.create_from_image(img)
    m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
    m.uv1_triplanar = true
    m.uv1_world_triplanar = true
    m.uv1_scale = Vector3.ONE / 15.0
    m.roughness = 0.6
    return m


## Builds `build` around the origin, then turns it by `yaw` and moves it to `pos`
## (so the Basement helpers can be reused facing another way, unchanged).
static func _gk_place(L, build: Callable, pos: Vector3, yaw: float) -> void:
    var before: int = L.get_child_count()
    build.call()
    var kids: Array = []
    for i in range(before, L.get_child_count()):
        kids.append(L.get_child(i))
    var pivot := Node3D.new()
    L.add_child(pivot)
    for k in kids:
        L.remove_child(k)
        pivot.add_child(k)
    pivot.transform = Transform3D(Basis(Vector3.UP, yaw), pos)


## Black block letters (solid 3D text, so walls hide it), facing +z unless turned.
static func _gk_word(L, text: String, pos: Vector3, yaw: float, height: float, col := Color("222222")) -> void:
    var tm := TextMesh.new()
    tm.text = text
    tm.font_size = 64
    tm.pixel_size = height / 64.0
    tm.depth = 0.05
    var mi := MeshInstance3D.new()
    mi.mesh = tm
    mi.material_override = L.mat(col, 0.9)
    mi.position = pos
    mi.rotation.y = yaw
    mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    L.add_child(mi)


const GK_FLOOR := 1.1     # minimum-shadow glow strength for the kitchen props (the night scene is dark)


static func _giant_kitchen(L) -> void:
    # The rest of the kitchen floor, far out, and the dark ceiling 75 m up.
    L.box(Vector3(0, -0.6, 0), Vector3(600, 1.0, 600), Color.WHITE, 0.0, false, _gk_lino())
    var plaster := _bm_floored(Color("35404c"), Color("202a35"), 0.9, 0.5)
    L.box(Vector3(0, 75.6, 0), Vector3(600, 1.2, 600), Color.WHITE, 0.0, false, plaster)
    for z in [-40.0, 20.0]:                                                       # two broad beams
        L.box(Vector3(0, 72.5, z), Vector3(600, 5.0, 6.0), Color.WHITE, 0.0, false, _bm_floored(Color("566473"), Color("202a35"), 0.9, 0.5))
    var wall := _bm_floored(Color("35404c"), Color("202a35"), 0.9, 0.5)
    for s in [-1.0, 1.0]:
        L.box(Vector3(110 * s, 37.5, 0), Vector3(2, 75, 252), Color.WHITE, 0.0, false, wall)
        L.box(Vector3(0, 37.5, 125 * s), Vector3(222, 75, 2), Color.WHITE, 0.0, false, wall)
    _gk_table(L)
    _gk_fridge(L)
    _gk_counter(L)
    _gk_spill(L)
    _gk_pantry(L)
    _gk_laundry(L)
    _gk_window_pendant(L)
    # Gate 1 review: a little local fill on the fridge, the table legs and the
    # counter faces so they read against the bright start room. Cool-neutral to
    # keep the midnight palette; every light stops well above the play floor.
    var fill := Color("c9d6ea")
    for f in [[Vector3(-20, 30, 23), 18.0, 1.3], [Vector3(-34, 30, 40), 18.0, 1.1], [Vector3(34, 30, 40), 18.0, 1.1],
            [Vector3(22, 24, -15), 16.0, 1.2], [Vector3(22, 24, 15), 16.0, 1.2]]:
        L.lamp(f[0], fill, f[1], f[2], false)


## 1. The dining table, straddling the south play edge: legs as columns, the
## underside as a ceiling over the south of the Kitchen Floor; three chairs.
static func _gk_table(L) -> void:
    var wood := _bm_floored(Color("a87545"), Color("513a2b"), 0.8, 0.95)   # underside reads as wood, not black
    var hi = L.mat(Color("d5ad78"), 0.6)
    var top := Vector3(0, 50.5, 62.5)
    L.box(top, Vector3(90, 5, 55), Color.WHITE, 0.0, false, wood)
    L.box(top + Vector3(0, 2.6, -27.6), Vector3(90.4, 0.4, 0.4), Color.WHITE, 0.0, false, hi)       # lit front edge
    for s in [-1.0, 1.0]:                                                                           # aprons under the top
        L.box(Vector3(39 * s, 45.5, 62.5), Vector3(2, 5, 46), Color.WHITE, 0.0, false, wood)
        L.box(Vector3(0, 45.5, 62.5 + 23 * s), Vector3(78, 5, 2), Color.WHITE, 0.0, false, wood)
        for z in [37.5, 87.5]:
            L.box(Vector3(42 * s, 24, z), Vector3(5, 48, 5), Color.WHITE, 0.0, false, wood)
    for ch in [[Vector3(56, 0, 58), -PI / 2], [Vector3(-56, 0, 70), PI / 2], [Vector3(0, 0, 100), PI]]:
        _gk_place(L, func():
            for lx in [-9.0, 9.0]:
                for lz in [-9.0, 9.0]:
                    L.box(Vector3(lx, 12, lz), Vector3(2, 24, 2), Color.WHITE, 0.0, false, wood)
            L.box(Vector3(0, 25, 0), Vector3(22, 2, 22), Color.WHITE, 0.0, false, wood)
            L.box(Vector3(0, 39, 10), Vector3(22, 26, 2), Color.WHITE, 0.0, false, wood)
            L.box(Vector3(0, 26.1, -11.1), Vector3(22.2, 0.3, 0.3), Color.WHITE, 0.0, false, hi), ch[0], ch[1])


## 2. The full-height refrigerator west of the Kitchen Floor, door ajar.
static func _gk_fridge(L) -> void:
    var enamel := _bm_floored(Color("d8e0e5"), Color("71818e"), 0.3, 0.45)
    var hi = L.mat(Color("f5f8f7"), 0.2)
    var seam = L.mat(Color("71818e"), 0.6)
    var c := Vector3(-34, 0, 23)          # body x -42..-26 (front at -26), z 14..32
    L.box(c + Vector3(0, 22.5, 0), Vector3(16, 45, 18), Color.WHITE, 0.0, false, enamel)
    L.box(Vector3(-25.9, 31.0, 23), Vector3(0.3, 0.5, 18), Color.WHITE, 0.0, false, seam)             # freezer seam
    L.box(Vector3(-25.6, 38.0, 16.0), Vector3(0.8, 8.0, 0.9), Color.WHITE, 0.0, false, hi)           # freezer handle
    L.box(Vector3(-26.0, 44.9, 23), Vector3(0.4, 0.3, 18.2), Color.WHITE, 0.0, false, hi)
    # The fridge door, hinged on the south edge and standing a little open:
    # the warm interior shows in the gap.
    L.box(Vector3(-26.4, 15.0, 22.0), Vector3(0.4, 29.0, 15.0), Color.WHITE, 0.0, false, L.glow_mat(Color("ddeeff"), 0.8))
    var door := Node3D.new()
    L.add_child(door)
    door.position = Vector3(-26, 0.5, 32)
    door.rotation.y = 0.32
    var dm := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = Vector3(1.2, 29.5, 18)
    dm.mesh = bm
    dm.material_override = enamel
    dm.position = Vector3(0.6, 14.75, -9)
    door.add_child(dm)
    var hm := MeshInstance3D.new()
    var hb := BoxMesh.new()
    hb.size = Vector3(0.8, 10, 0.9)
    hm.mesh = hb
    hm.material_override = hi
    hm.position = Vector3(1.6, 16, -16.5)
    door.add_child(hm)
    # Magnets on the door: a star, an apple, a smiley, a letter A and a note.
    var mags := [["star", Color("e7b84f"), Vector3(1.4, 22, -5)], ["apple", Color("c95b52"), Vector3(1.4, 18, -12)],
        ["smile", Color("e5bf42"), Vector3(1.4, 12, -4)], ["A", Color("4c83b6"), Vector3(1.4, 25, -13)]]
    for mg in mags:
        var n := MeshInstance3D.new()
        if mg[0] == "A" or mg[0] == "star":
            var t := TextMesh.new()
            t.text = "A" if mg[0] == "A" else "*"
            t.font_size = 64
            t.pixel_size = (2.6 if mg[0] == "A" else 4.0) / 64.0
            t.depth = 0.3
            n.mesh = t
            n.rotation.y = PI / 2
        else:
            var sm := SphereMesh.new()
            sm.radius = 1.1
            sm.height = 2.2
            n.mesh = sm
            n.scale = Vector3(0.4, 1, 1)
        n.material_override = L.mat(mg[1], 0.5)
        n.position = mg[2]
        door.add_child(n)
    var note := MeshInstance3D.new()
    var nb := BoxMesh.new()
    nb.size = Vector3(0.2, 3.6, 6.0)
    note.mesh = nb
    note.material_override = L.mat(Color("f2eee5"), 0.9)
    note.position = Vector3(1.3, 7, -9)
    door.add_child(note)
    var nt := TextMesh.new()
    nt.text = "LEFTOVERS"
    nt.font_size = 64
    nt.pixel_size = 0.9 / 64.0
    nt.depth = 0.05
    var ntm := MeshInstance3D.new()
    ntm.mesh = nt
    ntm.material_override = L.mat(Color("222222"), 0.9)
    ntm.position = Vector3(1.45, 7, -9)
    ntm.rotation.y = PI / 2
    door.add_child(ntm)
    _gk_word(L, "KEEP COLD", Vector3(-25.7, 34.5, 23), PI / 2, 1.4, Color("71818e"))
    # The fridge light: warm, the brightest local light, short reach (stops above the floor).
    L.lamp(Vector3(-21, 18, 24), Color("ffdda0"), 14.0, 2.2, false)


## 3 + 4. The counter run east of the play area: cabinets, worktop, oven with a
## glowing clock, sink and faucet with a drip, toaster, cookie jar, trash can.
static func _gk_counter(L) -> void:
    var cab := _bm_floored(Color("b78a5b"), Color("614a37"), 0.8, GK_FLOOR)
    var cab_hi = L.mat(Color("d8b58a"), 0.6)
    var cab_line = L.mat(Color("614a37"), 0.8)
    var top := _bm_floored(Color("d9d3c7"), Color("77746d"), 0.4, GK_FLOOR)
    var top_hi = L.mat(Color("f2eee5"), 0.3)
    var steel := _bm_floored(Color("aebbc2"), Color("53616a"), 0.25, GK_FLOOR)
    var steel_hi = L.mat(Color("e8f0f3"), 0.15)
    steel.metallic = 0.6
    var z0 := -35.0
    var z1 := 30.0
    var zc := (z0 + z1) * 0.5
    L.box(Vector3(33.5, 9, zc), Vector3(13, 18, z1 - z0), Color.WHITE, 0.0, false, cab)              # cabinets x 27..40
    L.box(Vector3(33.0, 19, zc), Vector3(14, 2, z1 - z0 + 1), Color.WHITE, 0.0, false, top)           # worktop, front edge x 26
    L.box(Vector3(25.95, 19.9, zc), Vector3(0.3, 0.3, z1 - z0 + 1), Color.WHITE, 0.0, false, top_hi)
    L.box(Vector3(26.9, 1.0, zc), Vector3(0.4, 2.0, z1 - z0), Color.WHITE, 0.0, false, L.mat(Color("614a37"), 0.9))  # toe kick
    var z := z0 + 6.5
    while z < z1:                                                                                     # door seams and knobs
        if absf(z - 20.0) > 9.0:
            L.box(Vector3(26.9, 9, z - 6.5), Vector3(0.2, 16, 0.4), Color.WHITE, 0.0, false, cab_line)
            L.sphere(Vector3(26.6, 14.0, z - 4.5), 0.5, Color.WHITE, Vector3.ONE, cab_hi)
        z += 6.5
    # Oven (15 wide, 15 tall) set into the cabinets, opposite the fridge.
    var oven := _bm_floored(Color("343b43"), Color("1c2228"), 0.4, GK_FLOOR)
    L.box(Vector3(26.8, 8.5, 20), Vector3(0.6, 15, 15), Color.WHITE, 0.0, false, oven)
    L.box(Vector3(26.45, 7.5, 20), Vector3(0.2, 7, 10), Color.WHITE, 0.0, false, L.mat(Color("1a1f24"), 0.1, 0.3))  # oven window
    L.box(Vector3(26.2, 12.4, 20), Vector3(0.5, 0.6, 11), Color.WHITE, 0.0, false, steel_hi)                  # handle
    for i in 4:
        L.cyl(Vector3(26.3, 15.3, 14.5 + i * 2.2 + (1.0 if i > 1 else 0.0)), 0.6, 0.6, Color.WHITE, false, Vector3(0, 0, PI / 2), steel)
    L.box(Vector3(26.4, 15.3, 19.75), Vector3(0.2, 0.9, 2.2), Color.WHITE, 0.0, false, L.glow_mat(Color("e7a85b"), 2.2))  # clock
    L.lamp(Vector3(25.0, 15.3, 19.75), Color("e7a85b"), 6.0, 0.8, false)
    # Sink (12 x 9 opening) and a tall curved faucet with one big drip.
    L.box(Vector3(33, 20.05, -5), Vector3(9.4, 0.2, 12.4), Color.WHITE, 0.0, false, steel)                    # rim
    L.box(Vector3(33, 19.0, -5), Vector3(8.0, 2.1, 11.0), Color.WHITE, 0.0, false, L.mat(Color("53616a"), 0.3, 0.6))  # basin seen from the side
    L.cyl(Vector3(38, 26, -5), 0.9, 12, Color.WHITE, false, Vector3.ZERO, steel)                             # faucet column
    L.cyl(Vector3(35.5, 32.2, -5), 0.8, 5.2, Color.WHITE, false, Vector3(0, 0, PI / 2), steel)               # spout
    L.cyl(Vector3(33.0, 31.2, -5), 0.8, 2.0, Color.WHITE, false, Vector3.ZERO, steel)
    L.box(Vector3(38.0, 32.2, -5), Vector3(0.3, 0.3, 1.9), Color.WHITE, 0.0, false, steel_hi)
    var water := StandardMaterial3D.new()
    water.albedo_color = Color("8fcde8")
    water.roughness = 0.05
    water.emission_enabled = true
    water.emission = Color("8fcde8")
    water.emission_energy_multiplier = 0.25
    L.sphere(Vector3(33.0, 28.6, -5), 0.75, Color.WHITE, Vector3(1, 1.3, 1), water)
    # Toaster and cookie jar on the worktop, trash can beside the south end.
    L.box(Vector3(34, 23.0, 4), Vector3(6, 6, 9), Color.WHITE, 0.0, false, steel)
    for dz in [-2.0, 2.0]:
        L.box(Vector3(34, 26.05, 4 + dz), Vector3(3.4, 0.1, 0.8), Color.WHITE, 0.0, false, L.mat(Color("222222"), 0.9))
    L.box(Vector3(30.95, 23.0, 4), Vector3(0.1, 1.2, 9.0), Color.WHITE, 0.0, false, steel_hi)
    L.cyl(Vector3(34, 23.5, -25), 3.0, 7.0, Color.WHITE, false, Vector3.ZERO, _bm_floored(Color("e6e0d4"), Color("77736c"), 0.4, GK_FLOOR))
    L.cyl(Vector3(34, 27.4, -25), 2.4, 0.8, Color.WHITE, false, Vector3.ZERO, L.mat(Color("c0453a"), 0.5))
    L.sphere(Vector3(34, 28.2, -25), 0.8, Color("c0453a"), Vector3.ONE, L.mat(Color("c0453a"), 0.5))
    var bin := _bm_floored(Color("667078"), Color("333c43"), 0.4, GK_FLOOR)
    bin.metallic = 0.4
    L.cyl(Vector3(31, 9, 37), 4.0, 18.0, Color.WHITE, false, Vector3.ZERO, bin)
    L.cyl(Vector3(31, 18.3, 37), 4.2, 0.6, Color.WHITE, false, Vector3.ZERO, L.mat(Color("9ba7ad"), 0.3, 0.5))
    L.box(Vector3(26.9, 12, 37), Vector3(0.4, 3.0, 2.2), Color.WHITE, 0.0, false, L.mat(Color("333c43"), 0.5))  # pedal


## 5. The breakfast spill: a tipped generic cereal box, a bowl, a spoon and cereal.
static func _gk_spill(L) -> void:
    var box := _bm_floored(Color("d4a64d"), Color("76552e"), 0.8, 0.45)
    L.box_rot(Vector3(-32, 2.0, 48), Vector3(11, 4, 16), Color.WHITE, Vector3(0, 0.5, 0), false, box)
    L.box_rot(Vector3(-32, 4.05, 48), Vector3(10.2, 0.1, 15.2), Color.WHITE, Vector3(0, 0.5, 0), false, L.mat(Color("f2d58d"), 0.7))
    _gk_word(L, "CEREAL", Vector3(-32, 4.2, 48), 0.5, 2.6)
    var w = L.get_child(L.get_child_count() - 1)
    w.rotation = Vector3(-PI / 2, 0.5, 0)
    var bowl := _bm_floored(Color("e6e0d4"), Color("77736c"), 0.3, 0.4)
    L.cyl(Vector3(-40, 2, 57), 2.4, 4.0, Color.WHITE, false, Vector3.ZERO, bowl, 4.0)      # wide top, narrow foot
    L.cyl(Vector3(-40, 4.02, 57), 3.6, 0.05, Color.WHITE, false, Vector3.ZERO, L.mat(Color("f2eee5"), 0.4))   # milk
    var spoon = L.mat(Color("aebbc2"), 0.2, 0.7)
    L.box_rot(Vector3(-30, 0.5, 58), Vector3(9, 0.6, 1.2), Color.WHITE, Vector3(0, 0.3, 0), false, spoon)
    L.sphere(Vector3(-35.2, 0.6, 59.6), 1.6, Color.WHITE, Vector3(1.3, 0.35, 0.9), spoon)
    var rng := RandomNumberGenerator.new()
    rng.seed = 7
    for i in 16:
        var c := Color("c58b4b") if i % 2 == 0 else Color("e7bd75")
        var r := rng.randf_range(0.4, 0.75)
        L.sphere(Vector3(rng.randf_range(-36, -26), r * 0.8, rng.randf_range(51, 58)), r, c, Vector3(1, 0.8, 1), L.mat(c, 0.9))


## 6. Pantry shelving west of the Pantry: timber shelves of cans, jars and boxes.
static func _gk_pantry(L) -> void:
    var timber := _bm_floored(Color("956b43"), Color("49382b"), 0.85, GK_FLOOR)
    var t_hi = L.mat(Color("c49a68"), 0.7)
    var fx := -28.0                       # front of the unit; it runs z -36..14, back at x -40
    L.box(Vector3(-39.5, 19, -11), Vector3(1, 38, 50), Color.WHITE, 0.0, false, timber)
    for z in [-36.0, 14.0]:
        L.box(Vector3(-34, 19, z), Vector3(12, 38, 1.2), Color.WHITE, 0.0, false, timber)
    var levels := [1.0, 10.5, 20.0, 29.5]
    for y in levels + [38.0]:
        L.box(Vector3(-34, y - 0.5, -11), Vector3(12, 1, 50), Color.WHITE, 0.0, false, timber)
        L.box(Vector3(fx + 0.05, y - 0.5, -11), Vector3(0.2, 1.0, 50), Color.WHITE, 0.0, false, t_hi)
    var can := _bm_floored(Color("789a9b"), Color("3f5b60"), 0.35, GK_FLOOR)
    can.metallic = 0.4
    var can_hi = L.mat(Color("b5d0c8"), 0.3)
    var jars := [Color("c99a4a"), Color("b05a4a"), Color("6f8a55")]
    var words := [["SOUP", -30.0], ["PEACHES", -14.0], ["JAM", 2.0]]
    for li in levels.size():
        var y: float = levels[li]
        var z := -33.0
        var k := li
        while z < 11.5:
            var kind := k % 4
            if kind == 0 or kind == 1:                                                    # cans
                L.cyl(Vector3(-31, y + 3, z), 1.5, 6.0, Color.WHITE, false, Vector3.ZERO, can)
                L.cyl(Vector3(-31, y + 6.02, z), 1.4, 0.05, Color.WHITE, false, Vector3.ZERO, can_hi)
                z += 3.6
            elif kind == 2:                                                               # jar with a lid
                var jc: Color = jars[(k / 4) % 3]
                L.cyl(Vector3(-31, y + 2.5, z), 1.5, 5.0, Color.WHITE, false, Vector3.ZERO, _bm_floored(jc, jc.darkened(0.5), 0.2, 0.4))
                L.cyl(Vector3(-31, y + 5.3, z), 1.55, 0.6, Color.WHITE, false, Vector3.ZERO, L.mat(Color("8a8f94"), 0.3, 0.6))
                z += 3.8
            else:                                                                         # small cereal box
                L.box(Vector3(-32, y + 3.5, z + 0.5), Vector3(3, 7, 4), Color.WHITE, 0.0, false, _bm_floored(Color("d4a64d"), Color("76552e"), 0.8, 0.4))
                z += 5.0
            k += 1
    # Shelf-edge labels on the bottom shelf, block letters on cream strips.
    for wd in words:
        L.box(Vector3(fx + 0.15, 0.2, wd[1]), Vector3(0.1, 0.9, 6.5), Color.WHITE, 0.0, false, L.mat(Color("e5d7b5"), 0.9))
        _gk_word(L, wd[0], Vector3(fx + 0.25, 0.2, wd[1]), PI / 2, 0.7)
    _gk_word(L, "OATS", Vector3(-30.45, 13.5, -14.5), PI / 2, 0.9)
    _gk_word(L, "RICE", Vector3(-30.45, 23.0, -4.5), PI / 2, 0.9)
    # Dim neutral-warm fill on the shelf faces (short; stops above the floor).
    L.lamp(Vector3(-24, 26, -11), Color("ffe6c8"), 22.0, 1.2, false)


## 7a. The laundry beyond the north edge: the Basement washer (with its basket)
## and a matching dryer, facing the play area, a detergent jug, an ironing board.
static func _gk_laundry(L) -> void:
    _gk_place(L, func():
        _bm_washer(L, Vector3.ZERO)
        _bm_basket(L, Vector3(0, 22, -1)), Vector3(-14, 0, -62), PI / 2)
    _gk_place(L, func():
        _bm_washer(L, Vector3.ZERO, Color("d7e0e5"), Color("29343d"), false), Vector3(6, 0, -62), PI / 2)
    L.box(Vector3(6, 26, -62), Vector3(5, 8, 3.5), Color.WHITE, 0.0, false, _bm_floored(Color("5f86a8"), Color("2f4a63"), 0.4, 0.4))
    L.cyl(Vector3(7.4, 30.8, -62), 0.8, 1.6, Color.WHITE, false, Vector3.ZERO, L.mat(Color("e5d7b5"), 0.5))
    _gk_word(L, "DETERGENT", Vector3(6, 26, -60.2), 0.0, 0.8, Color("f2eee5"))
    var fab := _bm_floored(Color("91aebb"), Color("4d6875"), 0.9, 0.4)
    L.box(Vector3(28, 14, -56), Vector3(20, 2, 6), Color.WHITE, 0.0, false, fab)
    L.box(Vector3(28, 15.05, -56), Vector3(19.6, 0.1, 5.6), Color.WHITE, 0.0, false, L.mat(Color("c4d8df"), 0.9))
    var leg = L.mat(Color("87969b"), 0.3, 0.6)
    for s in [-1.0, 1.0]:
        L.box_rot(Vector3(28, 6.6, -56), Vector3(0.6, 15.5, 0.6), Color.WHITE, Vector3(0, 0, 0.6 * s), false, leg)
    # Cool laundry fill (#A8C3D5, gate 1 review); neither light reaches the play floor.
    L.lamp(Vector3(0, 30, -52), Color("a8c3d5"), 26.0, 2.2, false)
    L.lamp(Vector3(-4, 18, -50), Color("a8c3d5"), 17.0, 1.4, false)
    _gk_word(L, "TOWELS", Vector3(-14, 31.5, -56.2), 0.0, 0.9)


## 7b. The moonlit window high on the west wall, and a pendant lamp over the Kitchen Floor.
static func _gk_window_pendant(L) -> void:
    var wc := Vector3(-108.6, 42, 10)
    L.box(wc, Vector3(0.6, 20, 28), Color.WHITE, 0.0, false, L.glow_mat(Color("263d67"), 1.6))
    L.box(wc + Vector3(0.3, 4, -4), Vector3(0.2, 8, 8), Color.WHITE, 0.0, false, L.glow_mat(Color("7896c5"), 1.2))   # moon reflection
    var frame = L.mat(Color("18263e"), 0.8)
    for dz in [-14.4, 0.0, 14.4]:
        L.box(wc + Vector3(0.4, 0, dz), Vector3(1.0, 21, 1.0), Color.WHITE, 0.0, false, frame)
    for dy in [-10.4, 10.4]:
        L.box(wc + Vector3(0.4, dy, 0), Vector3(1.0, 1.0, 29.8), Color.WHITE, 0.0, false, frame)
    L.lamp(Vector3(-86, 42, 10), Color("9bbceb"), 70.0, 1.3, false)       # moonlight onto the fridge and pantry side
    # Pendant: cord from the ceiling, a dark shade, a small amber glow.
    var pc := Vector3(6, 0, 8)
    L.cyl(Vector3(pc.x, 66, pc.z), 0.15, 19.0, Color("222222"), false)
    L.cyl(Vector3(pc.x, 51, pc.z), 2.5, 12.0, Color.WHITE, false, Vector3.ZERO, _bm_floored(Color("424b58"), Color("202833"), 0.5, 0.4), 1.0)
    L.box(Vector3(pc.x + 2.0, 51, pc.z), Vector3(0.2, 9, 0.4), Color.WHITE, 0.0, false, L.mat(Color("7e8b9a"), 0.4))
    L.sphere(Vector3(pc.x, 44.6, pc.z), 1.0, Color("e7a85b"), Vector3.ONE, L.glow_mat(Color("e7a85b"), 2.5))
    L.lamp(Vector3(pc.x, 43.5, pc.z), Color("e7a85b"), 16.0, 1.0, false)


# ---- Round 2, gate 2: the other 11 MELTDOWN maps at giant scale ----
# Art direction: ChatGPT (creative director), spec approved by Andrew, 2026-11-21.
# Same rules as The Basement and Midnight Kitchen: 25x human scale, decoration only
# (no collision), outside the play edge or overhead; spec hex colours with a faint
# glow so faces never render darker than the spec's shadow colour; local fill
# lights that are cut short so they never reach the play floor. Nothing random.

## A spec colour that never renders darker than its spec shadow.
static func _gm(base: String, shadow: String, rough := 0.8, e := 0.6) -> StandardMaterial3D:
    return _bm_floored(Color(base), Color(shadow), rough, e)


## A fill light whose reach is cut so it stops 1 m short of the play floor
## (the floor inside the play edge, |x| <= bx, |z| <= bz).
static func _gfill(L, pos: Vector3, col: Color, rng: float, energy: float, bx: float, bz: float) -> void:
    var near := Vector3(clampf(pos.x, -bx, bx), 0.0, clampf(pos.z, -bz, bz))
    L.lamp(pos, col, minf(rng, pos.distance_to(near) - 1.0), energy, false)


static func _gbox(L, pos: Vector3, size: Vector3, m: Material, rot := Vector3.ZERO) -> void:
    L.box_rot(pos, size, Color.WHITE, rot, false, m)


static func _gcone(L, pos: Vector3, r_bottom: float, r_top: float, h: float, m: Material, rot := Vector3.ZERO) -> void:
    L.cyl(pos, r_bottom, h, Color.WHITE, false, rot, m, r_top)


static func _gball(L, pos: Vector3, r: float, m: Material, sc := Vector3.ONE) -> void:
    L.sphere(pos, r, Color.WHITE, sc, m)


## A ring (TorusMesh); lies flat unless turned.
static func _gring(L, pos: Vector3, r: float, thick: float, m: Material, rot := Vector3.ZERO) -> void:
    var mi := MeshInstance3D.new()
    var t := TorusMesh.new()
    t.inner_radius = r - thick * 0.5
    t.outer_radius = r + thick * 0.5
    mi.mesh = t
    mi.material_override = m
    mi.position = pos
    mi.rotation = rot
    L.add_child(mi)


## A triangular prism standing upright (a 3-sided cylinder).
static func _gprism(L, pos: Vector3, r: float, h: float, m: Material, yaw := 0.0) -> void:
    var mi := MeshInstance3D.new()
    var c := CylinderMesh.new()
    c.top_radius = r
    c.bottom_radius = r
    c.height = h
    c.radial_segments = 3
    c.rings = 1
    mi.mesh = c
    mi.material_override = m
    mi.position = pos
    mi.rotation.y = yaw
    L.add_child(mi)


## The rest of the room's floor, far out, just below the play floor.
static func _gground(L, m: Material, y := -0.6) -> void:
    L.box(Vector3(0, y, 0), Vector3(600, 1.0, 600), Color.WHITE, 0.0, false, m)


## A rod between two points (a thin box).
static func _grod(L, a: Vector3, b: Vector3, w: float, m: Material) -> void:
    var mi := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = Vector3(w, w, a.distance_to(b))
    mi.mesh = bm
    mi.material_override = m
    L.add_child(mi)
    mi.look_at_from_position((a + b) * 0.5, b, Vector3.UP if absf((b - a).normalized().y) < 0.95 else Vector3.RIGHT)


# ---------------------------------------------------------------- The Attic
static func _giant_attic(L) -> void:
    _gground(L, L.tex("wood_floor", Color("826a50"), 18.0))
    # West, seen between the rafters: steamer trunk, picture frames, light coil.
    var lea := _gm("72513d", "382b25", 0.6)
    var brass := _gm("b28a4b", "5f4a2a", 0.35, 0.5)
    brass.metallic = 0.6
    _gbox(L, Vector3(-46, 10, 8), Vector3(18, 20, 35), lea)
    L.cyl(Vector3(-46, 20, 8), 9.0, 35.0, Color.WHITE, false, Vector3(PI / 2, 0, 0), lea)        # domed lid
    for dz in [-9.0, 9.0]:
        _gbox(L, Vector3(-46, 10, 8 + dz), Vector3(18.4, 20.2, 1.4), brass)
        L.cyl(Vector3(-46, 20, 8 + dz), 9.25, 1.4, Color.WHITE, false, Vector3(PI / 2, 0, 0), brass)
    _gbox(L, Vector3(-36.8, 19.5, 8), Vector3(0.6, 2.4, 6), brass)                              # latch
    _gbox(L, Vector3(-36.9, 21.8, 8), Vector3(0.4, 0.4, 8), L.mat(Color("a98465"), 0.5))          # highlight
    var fw := _gm("8c6748", "493729", 0.7)
    var sky := _gm("8fb3c9", "4d6a7c", 0.9, 0.5)
    var hill := _gm("6f9467", "3b553a", 0.9, 0.5)
    for k in 3:
        var c := Vector3(-40 - k * 1.6, 15, -20 + k * 3.0)
        var lean := Vector3(0, 0, 0.12 + k * 0.03)
        _gbox(L, c, Vector3(3, 30, 20), fw, lean)
        _gbox(L, c + Vector3(1.6, 0, 0), Vector3(0.3, 25, 15), sky, lean)
        _gbox(L, c + Vector3(1.75, -7, 0), Vector3(0.3, 10, 15), hill, lean)
    var cable := _gm("39443b", "1d241e", 0.6, 0.4)
    var bulbs := [Color("b94a45"), Color("5f9a5f"), Color("d9a441"), Color("4f7fbf")]
    for ring in 3:
        var y := 0.6 + ring * 1.3
        _gring(L, Vector3(-44, y, 36), 6.5 - ring * 0.6, 0.6, cable)
        for i in 10:
            var a := i * TAU / 10.0 + ring * 0.3
            var rr := 6.5 - ring * 0.6
            L.sphere(Vector3(-44 + cos(a) * rr, y + 0.5, 36 + sin(a) * rr), 0.55, Color.WHITE, Vector3(1, 1.4, 1), L.glow_mat(bulbs[(i + ring) % 4], 1.6))
    # East: the old lamp (with its warm pool), the dress form, the rocking chair.
    var dark_wood := _gm("4a3a2c", "2a211a", 0.6)
    L.cyl(Vector3(40, 0.8, 18), 4.0, 1.6, Color.WHITE, false, Vector3.ZERO, dark_wood)
    L.cyl(Vector3(40, 8, 18), 0.5, 13.0, Color.WHITE, false, Vector3.ZERO, brass)
    _gcone(L, Vector3(40, 16.5, 18), 4.0, 2.4, 6.0, _gm("b99b6c", "66523b", 0.9))
    L.sphere(Vector3(40, 14.6, 18), 1.0, Color.WHITE, Vector3.ONE, L.glow_mat(Color("ffd59a"), 3.0))
    _gfill(L, Vector3(40, 14, 18), Color("ffd59a"), 24.0, 2.2, 26, 42)
    var linen := _gm("b9aa91", "645b4e", 0.9)
    for a in [0.0, 2.1, 4.2]:
        _grod(L, Vector3(44, 9, -10), Vector3(44 + cos(a) * 5, 0, -10 + sin(a) * 5), 0.8, dark_wood)
    L.cyl(Vector3(44, 11, -10), 0.6, 6.0, Color.WHITE, false, Vector3.ZERO, dark_wood)
    _gball(L, Vector3(44, 21, -10), 6.0, linen, Vector3(0.8, 1.35, 1.0))
    L.cyl(Vector3(44, 29.5, -10), 1.4, 3.0, Color.WHITE, false, Vector3.ZERO, linen)
    _gball(L, Vector3(44, 31.5, -10), 1.6, dark_wood)
    var rw := _gm("8b5c3d", "483326", 0.7)
    var rc := Vector3(46, 0, -34)
    for dz in [-6.5, 6.5]:
        for i in 5:                                                                   # curved rocker
            var x0 := -10.0 + i * 4.0
            var y0 := 1.0 + pow((x0 + 2.0) / 10.0, 2) * 2.0
            var y1 := 1.0 + pow((x0 + 6.0) / 10.0, 2) * 2.0
            _grod(L, rc + Vector3(x0, y0, dz), rc + Vector3(x0 + 4.0, y1, dz), 1.0, rw)
        for dx in [-6.0, 6.0]:
            _gbox(L, rc + Vector3(dx, 6.5, dz), Vector3(1.2, 11, 1.2), rw)
        _gbox(L, rc + Vector3(7.5, 20, dz), Vector3(1.2, 17, 1.2), rw, Vector3(0, 0, 0.12))   # back posts
    _gbox(L, rc + Vector3(0, 12, 0), Vector3(15, 1.6, 15), rw)
    for k in 4:
        _gbox(L, rc + Vector3(8.3, 20, -4.5 + k * 3.0), Vector3(0.8, 14, 1.4), rw, Vector3(0, 0, 0.12))
    _gbox(L, rc + Vector3(9.2, 28.3, 0), Vector3(1.4, 1.4, 15), rw, Vector3(0, 0, 0.12))
    # A tiny attic window far to the west: cool blue-grey light.
    _gbox(L, Vector3(-90, 22, 0), Vector3(0.6, 9, 12), L.glow_mat(Color("8fa5b8"), 1.2))
    _gfill(L, Vector3(-60, 22, 4), Color("a9b8c8"), 40.0, 1.0, 26, 42)


# ---------------------------------------------------------- The Garden Shed
static func _giant_garden(L) -> void:
    _gground(L, _gm("4b5145", "282f2b", 0.35, 0.35))
    var terra := _gm("b96845", "633a30", 0.8)
    var stem := _gm("4f7a45", "2b4527", 0.8)
    var blooms := [Color("e0b84a"), Color("c95b6a"), Color("9a7ac0")]
    var pots := [[Vector3(36, 0, 20), 7.0, 18.0], [Vector3(38, 0, 0), 5.0, 12.0], [Vector3(34, 0, -26), 4.0, 8.0]]
    for k in pots.size():
        var pp: Vector3 = pots[k][0]
        var r: float = pots[k][1]
        var h: float = pots[k][2]
        _gcone(L, pp + Vector3(0, h * 0.5, 0), r * 0.75, r, h, terra)
        L.cyl(pp + Vector3(0, h - 0.8, 0), r * 1.08, 1.6, Color.WHITE, false, Vector3.ZERO, terra)
        L.cyl(pp + Vector3(0, h - 0.5, 0), r * 0.95, 0.2, Color.WHITE, false, Vector3.ZERO, _gm("3a2c22", "20180f", 0.9, 0.4))
        L.cyl(pp + Vector3(0, h + h * 0.45, 0), 0.5, h * 0.9, Color.WHITE, false, Vector3.ZERO, stem)
        var top := pp + Vector3(0, h + h * 0.9, 0)
        var bm := _gm(blooms[k].to_html(false), blooms[k].darkened(0.45).to_html(false), 0.8)
        for i in 5:
            var a := i * TAU / 5.0
            _gball(L, top + Vector3(cos(a), 0, sin(a)) * r * 0.45, r * 0.35, bm)
        _gball(L, top, r * 0.25, _gm("e7bd75", "7a5d34", 0.8))
        for s in [-1.0, 1.0]:
            _gball(L, pp + Vector3(0, h + h * 0.4, s * r * 0.5), r * 0.4, stem, Vector3(0.5, 0.25, 1.0))
    var can := _gm("66866a", "344d40", 0.45)
    L.cyl(Vector3(-38, 7, 14), 6.0, 14.0, Color.WHITE, false, Vector3.ZERO, can)
    _grod(L, Vector3(-38, 4, 18), Vector3(-36, 15, 30), 1.6, can)                          # spout
    _gcone(L, Vector3(-35.8, 15.6, 31.0), 1.0, 2.4, 2.0, can, Vector3(-0.6, 0, 0))            # rose
    _grod(L, Vector3(-38, 14, 9), Vector3(-38, 18, 14), 1.2, can)                            # handle
    _grod(L, Vector3(-38, 18, 14), Vector3(-38, 14, 19), 1.2, can)
    L.cyl(Vector3(-38, 14.05, 14), 5.6, 0.1, Color.WHITE, false, Vector3.ZERO, L.mat(Color("a4c09a"), 0.4))
    var handle := _gm("a47a4f", "55402e", 0.7)
    var metal := _gm("78848a", "3c4448", 0.35)
    metal.metallic = 0.5
    _gbox(L, Vector3(-28.5, 17, -30), Vector3(1.2, 35, 1.2), handle, Vector3(0, 0, -0.12))   # rake against the fence
    _gbox(L, Vector3(-30.6, 33, -30), Vector3(1.2, 1.2, 10), metal)
    for i in 7:
        _gbox(L, Vector3(-30.6, 31, -34.5 + i * 1.5), Vector3(0.4, 3, 0.4), metal)
    _gbox(L, Vector3(28.6, 14, -34), Vector3(1.2, 28, 1.2), handle, Vector3(0, 0, 0.1))      # shovel
    _gbox(L, Vector3(27.2, 2.5, -34), Vector3(0.6, 8, 6), metal, Vector3(0, 0, 0.1))
    _gbox(L, Vector3(30.0, 28.5, -34), Vector3(1.2, 1.2, 4), handle)
    var paper := _gm("d8c99c", "766b4e", 0.9)
    for sp in [[Vector3(-12, 0, 52), "FLOWERS", Color("c95b6a")], [Vector3(2, 0, 54), "HERBS", Color("5f9a5f")], [Vector3(16, 0, 52), "BEANS", Color("8a6a3e")]]:
        var p0: Vector3 = sp[0]
        _gbox(L, p0 + Vector3(0, 7.5, 0), Vector3(10, 15, 1), paper, Vector3(-0.08, 0, 0))
        _gball(L, p0 + Vector3(0, 7.5, -0.7), 2.6, L.mat(sp[2], 0.8), Vector3(1, 1, 0.2))
        _gk_word(L, sp[1], p0 + Vector3(0, 12.2, -1.35), PI, 1.6)   # in front of the leaning card
    var coat := _gm("527da3", "2b4560", 0.8)
    var skin := _gm("d9c6a5", "7d6f5a", 0.8)
    var gp := Vector3(-14, 0, -54)
    _gcone(L, gp + Vector3(0, 6, 0), 6.0, 3.0, 12.0, coat)
    _gbox(L, gp + Vector3(0, 7, 0), Vector3(9.5, 1.0, 9.5), _gm("3a2c22", "20180f", 0.6))
    _gball(L, gp + Vector3(0, 15, 0), 3.6, skin)
    _gcone(L, gp + Vector3(0, 12.6, 1.4), 0.4, 3.0, 5.5, _gm("e8e2d5", "8a857a", 0.9))          # beard
    _gball(L, gp + Vector3(0, 15.2, 3.4), 0.9, _gm("d98a7a", "7a4a40", 0.8))
    for ex in [-1.3, 1.3]:
        _gball(L, gp + Vector3(ex, 16.4, 3.1), 0.35, L.mat(Color("222222"), 0.5))
    _gcone(L, gp + Vector3(0, 22.5, 0), 3.9, 0.3, 9.0, _gm("b94c3d", "632822", 0.8))
    var tub := _gm("788a70", "39483a", 0.5)
    var wb := Vector3(18, 0, -58)
    _gcone(L, wb + Vector3(0, 10, 0), 4.5, 7.0, 7.0, tub)
    _gbox(L, wb + Vector3(0, 10, 0), Vector3(22, 7, 12), tub)
    L.cyl(wb + Vector3(-12, 4, 0), 4.0, 2.0, Color.WHITE, false, Vector3(PI / 2, 0, 0), _gm("2a2e31", "15181a", 0.7))
    for s in [-1.0, 1.0]:
        _grod(L, wb + Vector3(-8, 7, s * 4.5), wb + Vector3(16, 9, s * 5.5), 1.0, handle)
        _gbox(L, wb + Vector3(8, 3, s * 4.5), Vector3(1, 6, 1), metal)
    for f in [[Vector3(32, 20, 4), 30.0], [Vector3(-32, 16, 16), 26.0], [Vector3(0, 18, -50), 24.0], [Vector3(2, 14, 50), 20.0]]:
        _gfill(L, f[0], Color("9fb3d6"), f[1], 1.4, 24, 44)


# ---------------------------------------------------------- Toy Store After Hours
static func _giant_toystore(L) -> void:
    _gground(L, L.tex("tiles", Color("777a7c"), 22.0, 0.4))
    var blue := _gm("477b9e", "294657", 0.6)
    var toy_cols := ["c95a4d", "4c80b5", "d8b64d", "6d9b6b", "9b7ab8"]
    _gbox(L, Vector3(-41.5, 20, 0), Vector3(1, 40, 60), blue)
    for z in [-30.0, 30.0]:
        _gbox(L, Vector3(-36, 20, z), Vector3(12, 40, 1.4), blue)
    var k := 0
    for y in [1.0, 11.0, 21.0, 31.0]:
        _gbox(L, Vector3(-36, y - 0.5, 0), Vector3(12, 1, 60), blue)
        _gbox(L, Vector3(-29.95, y - 0.5, 0), Vector3(0.2, 1.0, 60), L.mat(Color("83b3cc"), 0.5))
        var z := -27.0
        while z < 26.0:
            var w := 4.0 + float(k % 3) * 1.5
            var h := 5.0 + float((k * 7) % 4)
            var c: String = toy_cols[k % 5]
            _gbox(L, Vector3(-34, y + h * 0.5, z + w * 0.5), Vector3(7, h, w), _gm(c, Color(c).darkened(0.45).to_html(false), 0.7))
            _gbox(L, Vector3(-30.45, y + h * 0.5, z + w * 0.5), Vector3(0.1, h * 0.6, w * 0.6), L.mat(Color(c).lightened(0.35), 0.3))   # box window
            z += w + 1.0
            k += 1
    _gbox(L, Vector3(-29.8, 11.0 - 2.2, 12), Vector3(0.2, 2.6, 3.4), _gm("e5d7b5", "8c7d61", 0.9))
    _gk_word(L, "$4", Vector3(-29.65, 11.0 - 2.9, 12), PI / 2, 1.6)
    _gbox(L, Vector3(-29.8, 21.0 - 2.2, -14), Vector3(0.2, 2.6, 3.4), _gm("e5d7b5", "8c7d61", 0.9))
    _gk_word(L, "$9", Vector3(-29.65, 21.0 - 2.9, -14), PI / 2, 1.6)
    var fur := _gm("b9875b", "654a38", 0.95)
    var muzzle := _gm("d9b48c", "7a6550", 0.95)
    var bp := Vector3(38, 0, 14)
    _gball(L, bp + Vector3(0, 10, 0), 9.0, fur, Vector3(0.9, 1.1, 1.0))
    _gball(L, bp + Vector3(-1, 24, 0), 7.0, fur)
    for s in [-1.0, 1.0]:
        _gball(L, bp + Vector3(0, 30, s * 5.2), 2.6, fur)
        _gball(L, bp + Vector3(-0.8, 30, s * 5.2), 1.4, muzzle)
        _gball(L, bp + Vector3(-5, 12, s * 8.5), 3.4, fur, Vector3(1.6, 1, 1))        # arms
        _gball(L, bp + Vector3(-7, 3.2, s * 5.0), 3.6, fur, Vector3(1.5, 0.9, 1))       # feet
        _gball(L, bp + Vector3(-7.2, 26, s * 2.4), 0.8, L.mat(Color("1e1a18"), 0.3))     # eyes
    _gball(L, bp + Vector3(-6.8, 22.5, 0), 2.8, muzzle, Vector3(0.8, 0.8, 1))
    _gball(L, bp + Vector3(-9.1, 23.4, 0), 0.9, L.mat(Color("2a211c"), 0.3))
    var bcols := ["c95a4d", "4c80b5", "d8b64d", "6d9b6b"]
    var blocks := [[Vector3(-10, 0, 54), 10.0], [Vector3(1, 0, 53), 8.0], [Vector3(-6, 10, 54), 7.0], [Vector3(12, 0, 56), 6.0], [Vector3(20, 0, 52), 5.0], [Vector3(4, 8, 54), 5.0]]
    var letters := ["A", "B", "C", "D", "E", "F"]
    for i in blocks.size():
        var p0: Vector3 = blocks[i][0]
        var sz: float = blocks[i][1]
        _gbox(L, p0 + Vector3(0, sz * 0.5, 0), Vector3(sz, sz, sz), _gm(bcols[i % 4], Color(bcols[i % 4]).darkened(0.4).to_html(false), 0.6), Vector3(0, 0.15 * i, 0))
        _gk_word(L, letters[i], p0 + Vector3(0, sz * 0.25, -sz * 0.5 - 0.05), PI + 0.15 * i, sz * 0.55, Color("f2eee5"))
    var red := _gm("c64d45", "71302c", 0.4)
    var tp := Vector3(-12, 0, -56)
    _gcone(L, tp + Vector3(0, 3.5, 0), 0.4, 6.0, 7.0, red)
    L.cyl(tp + Vector3(0, 7.8, 0), 6.0, 1.6, Color.WHITE, false, Vector3.ZERO, red)
    L.cyl(tp + Vector3(0, 8.7, 0), 5.2, 0.2, Color.WHITE, false, Vector3.ZERO, L.mat(Color("f18b69"), 0.4))
    _gcone(L, tp + Vector3(0, 10.5, 0), 5.0, 1.4, 3.0, red)
    L.cyl(tp + Vector3(0, 14, 0), 0.7, 4.0, Color.WHITE, false, Vector3.ZERO, _gm("e5d7b5", "8c7d61", 0.6))
    _gfill(L, Vector3(-26, 26, 0), Color("ffe0b0"), 26.0, 1.6, 24, 46)        # warm display light on the shelves
    _gfill(L, Vector3(30, 26, 14), Color("dfe8ff"), 24.0, 1.4, 24, 46)
    _gfill(L, Vector3(4, 22, 50), Color("dfe8ff"), 22.0, 1.2, 24, 46)
    _gfill(L, Vector3(-12, 22, -50), Color("ffe0b0"), 22.0, 1.2, 24, 46)


# ---------------------------------------------------------- Recess Is Cancelled
static func _giant_school(L) -> void:
    _gground(L, L.tex("tiles", Color("85847b"), 22.0, 0.5))
    var wood := _gm("98714f", "4e3c2d", 0.7)
    var dp := Vector3(0, 0, 66)
    _gbox(L, dp + Vector3(0, 24, 0), Vector3(45, 2, 25), wood)
    _gbox(L, dp + Vector3(0, 25.05, -12.5), Vector3(45, 0.3, 0.3), L.mat(Color("c59c70"), 0.5))
    for s in [-1.0, 1.0]:
        _gbox(L, dp + Vector3(s * 21, 11.5, 11), Vector3(2, 23, 2), wood)
    _gbox(L, dp + Vector3(14, 11.5, 0), Vector3(15, 23, 24), wood)                          # drawer pedestal
    for i in 3:
        _gbox(L, dp + Vector3(14, 4 + i * 7, -12.05), Vector3(13, 0.3, 0.2), L.mat(Color("4e3c2d"), 0.8))
        _gbox(L, dp + Vector3(14, 7.3 + i * 7, -12.2), Vector3(4, 0.8, 0.5), L.mat(Color("c59c70"), 0.4))
    _gbox(L, dp + Vector3(-1, 11.5, 11.5), Vector3(40, 18, 1), wood)                         # modesty panel
    var gp := dp + Vector3(-10, 25, -2)
    L.cyl(gp + Vector3(0, 0.6, 0), 3.0, 1.2, Color.WHITE, false, Vector3.ZERO, wood)
    L.cyl(gp + Vector3(0, 3, 0), 0.5, 4.0, Color.WHITE, false, Vector3.ZERO, wood)
    var ocean := _gm("477d9d", "25475d", 0.4)
    _gball(L, gp + Vector3(0, 12, 0), 7.0, ocean)
    var land := _gm("7fa65a", "40552d", 0.8)
    for c in [[Vector3(-3, 14, -5.2), 3.2], [Vector3(3, 9, -5.5), 2.6], [Vector3(-5, 8, -3), 2.0], [Vector3(2, 16, -4.0), 2.0]]:
        _gball(L, gp + c[0], c[1], land, Vector3(1.2, 1.0, 0.5))
    _gring(L, gp + Vector3(0, 12, 0), 7.8, 0.6, wood, Vector3(PI / 2, 0, 0.3))
    var cols := [["e1b84f", "7a6124"], ["c95b52", "6a2e2a"], ["4c83b6", "264561"], ["6c9b69", "374f35"], ["e1b84f", "7a6124"]]
    for i in cols.size():
        var bp := Vector3(40 + i * 1.5, 0, 16 + i * 4.5)
        var rot := Vector3(0, 0, 0.18 - i * 0.07)
        var m := _gm(cols[i][0], cols[i][1], 0.6)
        _gbox(L, bp + Vector3(0, 18, 0), Vector3(4, 36, 4), m, rot)
        var tip := bp + Vector3(-sin(rot.z) * 38, cos(rot.z) * 38, 0)
        _gcone(L, tip, 2.0, 0.3, 4.0, _gm("d9b98a", "6d5c45", 0.8) if i % 2 == 0 else m, rot)
    var purple := _gm("80679c", "433852", 0.85)
    var bk := Vector3(-44, 0, 20)
    _gbox(L, bk + Vector3(0, 11, 0), Vector3(12, 22, 20), purple)
    L.cyl(bk + Vector3(0, 22, 0), 6.0, 20.0, Color.WHITE, false, Vector3(PI / 2, 0, 0), purple)
    _gbox(L, bk + Vector3(6.5, 8, 0), Vector3(3, 10, 14), _gm("b49cc9", "5d4f6a", 0.85))      # front pocket
    _gbox(L, bk + Vector3(8.05, 13.2, 0), Vector3(0.3, 0.5, 12), L.mat(Color("2a2430"), 0.5)) # zip
    for dz in [-5.0, 5.0]:
        _gbox(L, bk + Vector3(-6.4, 12, dz), Vector3(1, 18, 2.4), _gm("433852", "2a2333", 0.8))
    var lk := _gm("617c91", "354a5c", 0.45)
    lk.metallic = 0.3
    for i in 6:
        var z := -44.0 + i * 8.4
        _gbox(L, Vector3(-38, 19, z), Vector3(8, 38, 8.0), lk)
        for v in 4:
            _gbox(L, Vector3(-33.95, 32 - v * 1.4, z), Vector3(0.1, 0.4, 4.5), L.mat(Color("354a5c"), 0.6))
        _gbox(L, Vector3(-33.8, 19, z + 2.8), Vector3(0.4, 3.0, 0.8), L.mat(Color("a0b7c6"), 0.3, 0.5))
    var hp := Vector3(0, 0, -66)
    L.cyl(hp + Vector3(0, 20, -4), 1.5, 40.0, Color.WHITE, false, Vector3.ZERO, _gm("8a9399", "444b50", 0.4))
    _gbox(L, hp + Vector3(0, 38, -2), Vector3(26, 16, 1), _gm("e8e6df", "7c7a74", 0.4))
    for b in [[Vector3(0, 34.5, -1.4), Vector3(9, 0.6, 0.2)], [Vector3(0, 40.5, -1.4), Vector3(9, 0.6, 0.2)], [Vector3(-4.2, 37.5, -1.4), Vector3(0.6, 6.6, 0.2)], [Vector3(4.2, 37.5, -1.4), Vector3(0.6, 6.6, 0.2)]]:
        _gbox(L, hp + b[0], b[1], L.mat(Color("b84c3d"), 0.5))
    _gring(L, hp + Vector3(0, 33, 3.6), 4.6, 0.6, _gm("b84c3d", "5e2620", 0.4))
    var orange := _gm("c87b43", "75452e", 0.8)
    _gball(L, Vector3(20, 6, -58), 6.0, orange)
    _gring(L, Vector3(20, 6, -58), 6.0, 0.25, L.mat(Color("3a2418"), 0.8), Vector3(PI / 2, 0, 0))
    _gring(L, Vector3(20, 6, -58), 6.0, 0.25, L.mat(Color("3a2418"), 0.8), Vector3(0, 0, PI / 2))
    for f in [[Vector3(-28, 28, -22), Color("dfe8ff"), 26.0, 1.4], [Vector3(30, 24, 26), Color("dfe8ff"), 24.0, 1.3], [Vector3(-30, 22, 20), Color("dfe8ff"), 24.0, 1.2],
            [Vector3(0, 30, 52), Color("dfe8ff"), 22.0, 1.3], [Vector3(6, 30, -54), Color("ffe6c8"), 24.0, 1.5]]:
        _gfill(L, f[0], f[1], f[2], f[3], 30, 48)


## A beach-umbrella canopy: 8 panels alternating two colours, a cone of
## triangles (drawn from both sides), with a faint glow of the shadow colour.
static func _gumbrella(L, base: Vector3, r: float, h: float, a: Color, b: Color, shadow: Color) -> void:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var top := Vector3(0, h, 0)
    for i in 16:
        var a0 := i * TAU / 16.0
        var a1 := (i + 1) * TAU / 16.0
        st.set_color(a if (i / 2) % 2 == 0 else b)
        st.add_vertex(top)
        st.add_vertex(Vector3(cos(a1) * r, 0, sin(a1) * r))
        st.add_vertex(Vector3(cos(a0) * r, 0, sin(a0) * r))
    st.generate_normals()
    var mi := MeshInstance3D.new()
    mi.mesh = st.commit()
    var m := StandardMaterial3D.new()
    m.vertex_color_use_as_albedo = true
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    m.roughness = 0.8
    m.emission_enabled = true
    m.emission = shadow
    m.emission_energy_multiplier = 0.6
    mi.material_override = m
    mi.position = base
    L.add_child(mi)


# ---------------------------------------------------------- Sandcastle Beach at Dusk
static func _giant_beach(L) -> void:
    _gground(L, L.tex("beach_sand", Color("c7a36f"), 24.0))
    var coral := _gm("d96f59", "784b48", 0.8)
    var cream := _gm("e7d7b8", "7f7563", 0.8)
    var up := Vector3(40, 0, 10)
    L.cyl(up + Vector3(0, 16, 0), 0.8, 32.0, Color.WHITE, false, Vector3.ZERO, cream)
    _gumbrella(L, up + Vector3(0, 27, 0), 17.5, 6.5, Color("d96f59"), Color("e7d7b8"), Color("784b48"))
    _gball(L, up + Vector3(0, 33.6, 0), 1.0, cream)
    var teal := _gm("4d9b9c", "285e64", 0.95)
    _gbox(L, Vector3(-42, 0.5, 0), Vector3(18, 1, 35), teal)
    for dz in [-11.0, 0.0, 11.0]:
        _gbox(L, Vector3(-42, 1.02, dz), Vector3(18, 0.06, 3), _gm("8cc6b8", "4a6a62", 0.95))
    var frame := _gm("313943", "171f28", 0.4)
    for dz in [-4.2, 4.2]:
        L.cyl(Vector3(-40, 1.3, -8 + dz), 3.6, 0.5, Color.WHITE, false, Vector3.ZERO, frame)
        L.cyl(Vector3(-40, 1.6, -8 + dz), 3.1, 0.2, Color.WHITE, false, Vector3.ZERO, L.mat(Color("4e6a8a"), 0.05, 0.4))
    _gbox(L, Vector3(-40, 1.4, -8), Vector3(1.0, 0.6, 2.0), frame)
    for dz in [-7.6, 7.6]:
        _gbox(L, Vector3(-46, 1.4, -8 + dz), Vector3(12, 0.6, 0.6), frame)
    var yellow := _gm("d9b54c", "80652d", 0.5)
    var bk := Vector3(12, 0, 56)
    _gcone(L, bk + Vector3(0, 9, 0), 5.6, 7.0, 18.0, yellow)
    L.cyl(bk + Vector3(0, 17.6, 0), 7.3, 0.8, Color.WHITE, false, Vector3.ZERO, yellow)
    L.cyl(bk + Vector3(0, 17.0, 0), 6.6, 0.2, Color.WHITE, false, Vector3.ZERO, L.tex("beach_sand", Color("c7a36f"), 4.0))
    _gring(L, bk + Vector3(0, 18, 0), 7.0, 0.5, yellow, Vector3(PI / 2, 0, 0))
    var spade := _gm("4e86b5", "28455d", 0.5)
    _gbox(L, Vector3(22, 6, 58), Vector3(1.2, 14, 1.2), spade, Vector3(0, 0, -0.25))
    _gbox(L, Vector3(23.6, 0.5, 58), Vector3(0.5, 6, 5), spade, Vector3(0, 0, -0.25))
    var red := _gm("c65b50", "70372f", 0.8)
    for ff in [[Vector3(-14, 0.5, 56), 0.3], [Vector3(-4, 0.5, 60), -0.2]]:
        _gball(L, ff[0], 1.0, red, Vector3(3.5, 0.5, 7.5))
        var p0: Vector3 = ff[0]
        _grod(L, p0 + Vector3(0, 0.6, -3), p0 + Vector3(-2.6, 1.6, 1.5), 0.6, L.mat(Color("e78b70"), 0.6))
        _grod(L, p0 + Vector3(0, 0.6, -3), p0 + Vector3(2.6, 1.6, 1.5), 0.6, L.mat(Color("e78b70"), 0.6))
    var crab := _gm("c85b4c", "73352e", 0.6)
    var cp := Vector3(36, 0, -30)
    _gball(L, cp + Vector3(0, 5, 0), 6.5, crab, Vector3(1.0, 0.55, 1.35))
    for s in [-1.0, 1.0]:
        _grod(L, cp + Vector3(-4, 7, s * 2), cp + Vector3(-5, 11, s * 2.4), 0.6, crab)
        _gball(L, cp + Vector3(-5, 11.4, s * 2.4), 1.0, L.mat(Color("1e1a18"), 0.3))
        _grod(L, cp + Vector3(-5, 5, s * 5), cp + Vector3(-10, 6, s * 8), 1.4, crab)
        _gball(L, cp + Vector3(-12, 6.5, s * 8.5), 3.0, crab, Vector3(1.5, 0.9, 1.0))
        for j in 3:
            _grod(L, cp + Vector3(-1 + j * 3, 4, s * 7), cp + Vector3(1 + j * 3, 0.2, s * 12), 0.8, crab)
    _gball(L, cp + Vector3(-4.5, 6.5, 0), 1.0, L.mat(Color("ed9274"), 0.5), Vector3(1, 0.3, 3))   # friendly smile line
    for f in [[Vector3(36, 26, 10), Color("ffb98a")], [Vector3(-36, 18, 0), Color("b7a6e6")], [Vector3(8, 18, 50), Color("ffc89a")], [Vector3(32, 16, -28), Color("b7a6e6")]]:
        _gfill(L, f[0], f[1], 26.0, 1.5, 26, 46)


# ---------------------------------------------------------- Bath Time
static func _giant_bathtime(L) -> void:
    _gground(L, L.tex("tiles", Color("a0aaa9"), 18.0, 0.3))
    _gbox(L, Vector3(0, -0.12, -230), Vector3(600, 0.1, 420), L.tex("carpet", Color("81768d"), 10.0))   # bedroom carpet to the north
    var porc := _gm("e4e7e4", "87969a", 0.25)
    var tp := Vector3(46, 0, 24)
    _gbox(L, tp + Vector3(0, 8, 0), Vector3(22, 16, 45), porc)
    _gbox(L, tp + Vector3(0, 16.6, 0), Vector3(23, 1.2, 46), _gm("ffffff", "9aa6a8", 0.2))
    var bub := _gm("d5eaf1", "86a2ac", 0.3)
    for i in 14:
        var a := float(i) * 1.7
        _gball(L, tp + Vector3(sin(a) * 6.5, 17.5 + float(i % 3) * 0.8, -18 + i * 2.8), 2.6 + float(i % 3) * 0.7, bub)
    L.cyl(tp + Vector3(0, 21, -22), 1.0, 6.0, Color.WHITE, false, Vector3.ZERO, _gm("c9ccd1", "5b6066", 0.2))
    _gbox(L, tp + Vector3(0, 23.5, -20), Vector3(1.6, 1.6, 6), _gm("c9ccd1", "5b6066", 0.2))
    var duck := _gm("e5bf42", "896b2b", 0.4)
    var dk := tp + Vector3(0, 20.5, 6)
    _gball(L, dk, 6.0, duck, Vector3(1.0, 0.75, 1.25))
    _gball(L, dk + Vector3(-1, 6, -3), 4.0, duck)
    _gbox(L, dk + Vector3(-5.2, 5.4, -3), Vector3(3.0, 1.4, 2.4), _gm("e0893a", "7a4a20", 0.5))
    for s in [-1.0, 1.0]:
        _gball(L, dk + Vector3(-3.6, 7.4, -3 + s * 1.8), 0.6, L.mat(Color("1e1a18"), 0.3))
    _gball(L, dk + Vector3(0, 2, 5.5), 3.0, duck, Vector3(1, 0.8, 1.2))          # tail
    var cup := _gm("72a9a7", "3d666a", 0.4)
    L.cyl(Vector3(-40, 6, 30), 4.0, 12.0, Color.WHITE, false, Vector3.ZERO, cup)
    for b in [[Color("c95b52"), 0.25], [Color("4c83b6"), -0.2], [Color("d8b64d"), 0.05]]:
        var rot := Vector3(b[1], 0, b[1] * 0.6)
        _gbox(L, Vector3(-40 + b[1] * 6, 16, 30 + b[1] * 4), Vector3(1.2, 18, 1.2), _gm(b[0].to_html(false), b[0].darkened(0.45).to_html(false), 0.5), rot)
        _gbox(L, Vector3(-40 + b[1] * 10, 24.5, 30 + b[1] * 8), Vector3(1.6, 3.0, 1.8), L.mat(Color("f2f4f5"), 0.8), rot)
    var lav := _gm("9b8ab2", "51445f", 0.95)
    for sp in [Vector3(-12, 0, 58), Vector3(2, 0, 60)]:
        _gball(L, sp + Vector3(0, 1.2, 0), 1.0, lav, Vector3(4.0, 1.2, 8.0))
        _gball(L, sp + Vector3(0, 2.6, -3.0), 1.0, lav, Vector3(3.6, 2.2, 4.2))
        _gball(L, sp + Vector3(0, 4.6, -4.0), 1.4, _gm("cbbce0", "6a6178", 0.95))
    var tim := _gm("98714f", "4f3c2f", 0.7)
    var blanket := _gm("6485a8", "354b69", 0.95)
    var bd := Vector3(0, 0, -70)
    _gbox(L, bd + Vector3(0, 8, 0), Vector3(55, 8, 35), tim)
    for c in [Vector3(-26, 2, -16), Vector3(26, 2, -16), Vector3(-26, 2, 16), Vector3(26, 2, 16)]:
        _gbox(L, bd + c, Vector3(3, 4, 3), tim)
    _gbox(L, bd + Vector3(0, 15, -18), Vector3(57, 30, 2), tim)
    _gbox(L, bd + Vector3(0, 13.5, 4), Vector3(56, 3, 28), blanket)
    _gbox(L, bd + Vector3(0, 15.05, 4), Vector3(56, 0.2, 2), _gm("a4bdd7", "556a82", 0.9))
    _gball(L, bd + Vector3(0, 15, -12), 1.0, _gm("e8e4dc", "8a857a", 0.9), Vector3(18, 3, 5))
    var lp := Vector3(-36, 0, -58)
    _gbox(L, lp + Vector3(0, 6, 0), Vector3(12, 12, 12), tim)
    L.cyl(lp + Vector3(0, 15, 0), 0.6, 6.0, Color.WHITE, false, Vector3.ZERO, tim)
    _gcone(L, lp + Vector3(0, 20, 0), 4.0, 2.4, 6.0, _gm("d4b78a", "766044", 0.9))
    L.sphere(lp + Vector3(0, 18.5, 0), 1.0, Color.WHITE, Vector3.ONE, L.glow_mat(Color("ffd9a0"), 3.0))
    _gfill(L, lp + Vector3(2, 18, 2), Color("ffd9a0"), 28.0, 2.2, 30, 48)
    _gfill(L, Vector3(40, 30, 24), Color("e6f0ff"), 28.0, 1.6, 30, 48)
    _gfill(L, Vector3(-36, 20, 30), Color("e6f0ff"), 24.0, 1.3, 30, 48)
    _gfill(L, Vector3(-4, 16, 54), Color("e6f0ff"), 20.0, 1.2, 30, 48)


# ---------------------------------------------------------- The Garage
static func _giant_garage(L) -> void:
    _gground(L, L.tex("concrete", Color("777b78"), 30.0))
    var body := _gm("6d8490", "344650", 0.35)
    var tyre := _gm("252b30", "121518", 0.8)
    var cp := Vector3(-72, 0, 0)                        # the car's nose points east, at x -38
    _gbox(L, cp + Vector3(0, 19, 0), Vector3(64, 22, 58), body)
    _gbox(L, cp + Vector3(-6, 36, 0), Vector3(36, 14, 52), body)
    _gbox(L, cp + Vector3(12.3, 36, 0), Vector3(0.4, 11, 46), L.mat(Color("23303a"), 0.1, 0.3))    # windscreen
    _gbox(L, Vector3(-39, 12, 0), Vector3(10, 12, 60), _gm("a9c0c8", "4c5a60", 0.3))                # bumper
    for s in [-1.0, 1.0]:
        L.sphere(Vector3(-40.1, 22, s * 20), 3.0, Color.WHITE, Vector3(0.3, 0.8, 1.4), L.glow_mat(Color("e8e2cf"), 0.6))
        for wx in [-16.0, 20.0]:
            L.cyl(cp + Vector3(wx, 10, s * 29.5), 10.0, 6.0, Color.WHITE, false, Vector3(PI / 2, 0, 0), tyre)
            L.cyl(cp + Vector3(wx, 10, s * 32.6), 5.0, 0.4, Color.WHITE, false, Vector3(PI / 2, 0, 0), _gm("596067", "2a2e31", 0.4))
    var shelf := _gm("8b755a", "4b3f32", 0.8)
    _gbox(L, Vector3(47.5, 19, 0), Vector3(1, 38, 45), shelf)
    var can_cols := ["b85a4e", "4c7fae", "d0ae4a", "6a956a", "e2ddd1"]
    var k := 0
    for y in [1.0, 11.0, 21.0, 31.0]:
        _gbox(L, Vector3(42, y - 0.5, 0), Vector3(12, 1, 45), shelf)
        var z := -20.0
        while z < 20.0:
            var c: String = can_cols[k % 5]
            L.cyl(Vector3(40, y + 3, z), 2.6, 6.0, Color.WHITE, false, Vector3.ZERO, _gm(c, Color(c).darkened(0.45).to_html(false), 0.4))
            L.cyl(Vector3(40, y + 6.05, z), 2.4, 0.1, Color.WHITE, false, Vector3.ZERO, L.mat(Color("8e969a"), 0.3, 0.6))
            z += 6.0
            k += 1
    var frame := _gm("477d8c", "294650", 0.4)
    var bp := Vector3(0, 0, 60)
    for wx in [-12.0, 12.0]:
        _gring(L, bp + Vector3(wx, 9, 0), 8.5, 1.4, tyre, Vector3(PI / 2, 0, 0))
        _gring(L, bp + Vector3(wx, 9, 0), 7.4, 0.3, _gm("c5d0d2", "5e6668", 0.3), Vector3(PI / 2, 0, 0))
    _grod(L, bp + Vector3(-12, 9, 0), bp + Vector3(-2, 9, 0), 1.0, frame)
    _grod(L, bp + Vector3(-2, 9, 0), bp + Vector3(-5, 21, 0), 1.0, frame)
    _grod(L, bp + Vector3(-5, 21, 0), bp + Vector3(8, 21, 0), 1.0, frame)
    _grod(L, bp + Vector3(8, 21, 0), bp + Vector3(-2, 9, 0), 1.0, frame)
    _grod(L, bp + Vector3(8, 21, 0), bp + Vector3(12, 9, 0), 1.0, frame)
    _grod(L, bp + Vector3(-12, 9, 0), bp + Vector3(-5, 21, 0), 1.0, frame)
    _grod(L, bp + Vector3(9, 21, 0), bp + Vector3(9, 26, 0), 1.0, frame)
    _gbox(L, bp + Vector3(9, 26, 0), Vector3(1, 1, 10), _gm("2b2f33", "15181a", 0.6))           # handlebar
    _gbox(L, bp + Vector3(-5, 22.5, 0), Vector3(6, 1.2, 3), _gm("2b2f33", "15181a", 0.6))       # saddle
    var green := _gm("66865a", "34442f", 0.5)
    var mp := Vector3(-16, 0, -58)
    _gbox(L, mp + Vector3(0, 6, 0), Vector3(30, 8, 25), green)
    L.cyl(mp + Vector3(0, 13, 2), 5.0, 6.0, Color.WHITE, false, Vector3.ZERO, _gm("3a3f44", "1d2023", 0.4))
    for wx in [-12.0, 12.0]:
        for wz in [-11.0, 11.0]:
            L.cyl(mp + Vector3(wx, 3.5, wz), 3.5, 2.0, Color.WHITE, false, Vector3(PI / 2, 0, 0), tyre)
    for s in [-1.0, 1.0]:
        _grod(L, mp + Vector3(s * 8, 9, -11), mp + Vector3(s * 8, 26, -26), 1.0, _gm("2b2f33", "15181a", 0.5))
    _gbox(L, mp + Vector3(0, 26, -26), Vector3(17, 1, 1), _gm("2b2f33", "15181a", 0.5))
    _gk_place(L, func(): _bm_toolbox(L, Vector3.ZERO), Vector3(24, 0, -58), -PI / 2)
    _gfill(L, Vector3(24, 12, -45), Color("ffe6c8"), 14.0, 5.5, 32, 46)        # keeps the reused red toolbox readable
    var peg := _gm("6f5d47", "3a3027", 0.9)
    _gbox(L, Vector3(44, 20, 36), Vector3(1, 24, 22), peg)
    var steel := _gm("85949a", "414c52", 0.3)
    steel.metallic = 0.5
    _gbox(L, Vector3(43, 24, 30), Vector3(0.6, 12, 1.4), steel)                        # spanner
    _gring(L, Vector3(43, 31, 30), 2.0, 0.8, steel, Vector3(0, 0, PI / 2))
    _gbox(L, Vector3(43, 20, 37), Vector3(0.8, 14, 1.4), _gm("a4774c", "55402e", 0.7))  # hammer
    _gbox(L, Vector3(43, 27.5, 37), Vector3(1.6, 2.4, 6), steel)
    _gring(L, Vector3(43, 21, 44), 3.2, 1.2, _gm("5f8a55", "2f4529", 0.6), Vector3(0, 0, PI / 2))   # hose
    _gfill(L, Vector3(36, 24, 34), Color("ffd59a"), 22.0, 2.0, 32, 46)        # warm workbench light
    for f in [[Vector3(-38, 30, 0), 28.0], [Vector3(36, 24, 0), 22.0], [Vector3(0, 26, 52), 24.0], [Vector3(2, 22, -52), 24.0]]:
        _gfill(L, f[0], Color("e6ecf2"), f[1], 1.4, 32, 46)


# ---------------------------------------------------------- Pillow Fort
static func _giant_pillowfort(L) -> void:
    _gground(L, L.tex("carpet", Color("776b62"), 14.0))
    _bm_sofa(L, Vector3(0, 0, 62))
    var fab := _gm("6b7c8d", "35404e", 0.95)
    var ap := Vector3(-50, 0, 16)
    _gbox(L, ap + Vector3(0, 6, 0), Vector3(28, 12, 30), fab)
    _gbox(L, ap + Vector3(2, 14, 0), Vector3(22, 4, 22), _gm("a4b4c1", "4e5a64", 0.95))
    _gbox(L, ap + Vector3(-11, 20, 0), Vector3(6, 28, 30), fab)
    for s in [-1.0, 1.0]:
        _gbox(L, ap + Vector3(0, 11, s * 13), Vector3(28, 18, 5), fab)
    var wood := _gm("79583f", "3f3028", 0.7)
    var tv := Vector3(0, 0, -62)
    _gbox(L, tv + Vector3(0, 9, 0), Vector3(40, 18, 12), wood)
    for dx in [-10.0, 10.0]:
        _gbox(L, tv + Vector3(dx, 9, 6.05), Vector3(0.2, 15, 0.2), L.mat(Color("3f3028"), 0.8))
    _gbox(L, tv + Vector3(0, 30, 0), Vector3(36, 22, 2), _gm("23272c", "121417", 0.4))
    _gbox(L, tv + Vector3(0, 30, 1.05), Vector3(33, 19, 0.1), L.glow_mat(Color("1c2934"), 0.6))
    _gbox(L, tv + Vector3(6, 34, 1.15), Vector3(12, 4, 0.05), L.glow_mat(Color("2c4a66"), 0.5), Vector3(0, 0, 0.4))   # faint reflection
    _gbox(L, tv + Vector3(0, 19.5, 0), Vector3(8, 1, 6), _gm("23272c", "121417", 0.4))
    var brick := _gm("895b49", "49372f", 0.9)
    var fp := Vector3(46, 0, -20)
    _gbox(L, fp + Vector3(0, 22.5, 0), Vector3(15, 45, 35), brick)
    _gbox(L, fp + Vector3(-7.4, 8, 0), Vector3(1, 14, 18), _gm("1c1512", "0e0a08", 0.9))       # firebox
    _gbox(L, fp + Vector3(-8.5, 17, 0), Vector3(3, 1.6, 38), _gm("b78567", "5d4334", 0.7))     # mantel
    for i in 6:
        _gbox(L, fp + Vector3(-7.6, 28 + (i % 3) * 5, -12 + i * 4.5), Vector3(0.2, 0.3, 4.0), L.mat(Color("49372f"), 0.9))
    _gbox(L, fp + Vector3(-6, 2, 0), Vector3(3, 2, 12), _gm("5a3a22", "2d1d11", 0.8), Vector3(0, 0.2, 0))   # logs
    for i in 3:
        L.sphere(fp + Vector3(-6.5, 5 + i * 1.6, -3 + i * 3), 1.8 - i * 0.3, Color.WHITE, Vector3(1, 1.6, 1), L.glow_mat(Color("f2a65a"), 3.0))
    _gfill(L, fp + Vector3(-9, 8, 0), Color("f2a65a"), 26.0, 2.6, 32, 48)
    var rug := _gm("81515a", "49313e", 0.95)
    var rp := Vector3(-48, 0.4, -26)
    _gbox(L, rp, Vector3(30, 0.8, 45), rug)
    for d in [Vector3(0, 0.42, -18), Vector3(0, 0.42, 18), Vector3(0, 0.42, 0)]:
        _gbox(L, rp + d, Vector3(26, 0.05, 2), _gm("b67c7d", "5b3e3e", 0.95))
    _gbox(L, rp + Vector3(0, 0.42, 0), Vector3(2, 0.05, 41), _gm("b67c7d", "5b3e3e", 0.95))
    var rem := _gm("343a40", "1b2026", 0.5)
    _gbox(L, Vector3(-44, 2.3, -14), Vector3(6, 3, 18), rem, Vector3(0, 0.4, 0))
    for i in 4:
        L.sphere(Vector3(-44 - sin(0.4) * (i * 3 - 5), 3.8, -14 - cos(0.4) * (i * 3 - 5)), 0.7, Color.WHITE, Vector3(1, 0.4, 1), L.mat(Color("707b83") if i else Color("c95b52"), 0.5))
    for f in [[Vector3(0, 30, 52), Color("ffd2a6"), 30.0, 2.4], [Vector3(-40, 22, 16), Color("ffe0bf"), 22.0, 1.4], [Vector3(0, 30, -50), Color("ffe0bf"), 24.0, 1.4], [Vector3(-40, 16, -26), Color("ffe0bf"), 20.0, 1.2]]:
        _gfill(L, f[0], f[1], f[2], f[3], 32, 48)


# ---------------------------------------------------------- Model Railway
static func _giant_railway(L) -> void:
    # The layout is on a big table: its timber edge, and the hobby room's floor 20 m below.
    _gground(L, L.tex("wood_floor", Color("80664c"), 20.0), -20.6)
    var tim := _gm("8e6847", "4a3528", 0.75)
    _gbox(L, Vector3(0, -4.02, 10), Vector3(120, 8, 150), tim)
    _gbox(L, Vector3(0, 0.0, 85.1), Vector3(120.2, 0.3, 0.3), L.mat(Color("c09263"), 0.5))
    for x in [-56.0, 56.0]:
        for z in [-60.0, 80.0]:
            _gbox(L, Vector3(x, -14, z), Vector3(6, 12, 6), tim)
    var shade := _gm("66818a", "34454c", 0.5)
    var lp := Vector3(46, 0, 10)
    _gbox(L, lp + Vector3(0, 1, 0), Vector3(6, 2, 6), shade)
    _grod(L, lp + Vector3(0, 2, 0), lp + Vector3(-2, 16, -4), 1.0, _gm("87969b", "414c52", 0.3))
    _grod(L, lp + Vector3(-2, 16, -4), lp + Vector3(-8, 24, -2), 1.0, _gm("87969b", "414c52", 0.3))
    _gcone(L, lp + Vector3(-9, 22, -2), 5.0, 2.0, 6.0, shade)
    L.sphere(lp + Vector3(-9, 19.5, -2), 1.2, Color.WHITE, Vector3.ONE, L.glow_mat(Color("ffd59a"), 3.0))
    _gfill(L, lp + Vector3(-9, 19, -2), Color("ffd59a"), 30.0, 2.6, 24, 46)
    var mug := _gm("b66b50", "613c34", 0.4)
    L.cyl(Vector3(-44, 6, 20), 5.0, 12.0, Color.WHITE, false, Vector3.ZERO, mug)
    L.cyl(Vector3(-44, 11.6, 20), 4.4, 0.4, Color.WHITE, false, Vector3.ZERO, L.mat(Color("3a2418"), 0.2))
    _gring(L, Vector3(-44, 6.5, 26), 3.2, 1.2, mug, Vector3(PI / 2, 0, 0))
    var steel := _gm("87969b", "414c52", 0.3)
    steel.metallic = 0.5
    var pots := [["b85a4e", Vector3(38, 0, -24)], ["4c7fae", Vector3(42, 0, -18)], ["6a956a", Vector3(36, 0, -14)], ["d0ae4a", Vector3(44, 0, -28)]]
    for pt in pots:
        L.cyl(pt[1] + Vector3(0, 2, 0), 2.5, 4.0, Color.WHITE, false, Vector3.ZERO, _gm(pt[0], Color(pt[0]).darkened(0.45).to_html(false), 0.5))
        L.cyl(pt[1] + Vector3(0, 4.1, 0), 2.6, 0.3, Color.WHITE, false, Vector3.ZERO, steel)
    _gbox(L, Vector3(34, 0.5, -34), Vector3(1.0, 1.0, 8.0), steel, Vector3(0, 0.3, 0))      # tweezers
    _gbox(L, Vector3(35, 0.5, -34), Vector3(1.0, 1.0, 8.0), steel, Vector3(0, 0.45, 0))
    _gbox(L, Vector3(40, 0.6, -38), Vector3(1.2, 1.2, 8), _gm("a4774c", "55402e", 0.6), Vector3(0, -0.5, 0))   # brush
    _gbox(L, Vector3(37.6, 0.6, -41.6), Vector3(1.4, 1.4, 2.0), _gm("2b2f33", "15181a", 0.7), Vector3(0, -0.5, 0))
    var leaf := _gm("527453", "2c4637", 0.85)
    var trunk := _gm("79553b", "3e2c1f", 0.8)
    for t in [[Vector3(-16, 0, 52), 26.0], [Vector3(-2, 0, 54), 18.0], [Vector3(14, 0, 52), 32.0], [Vector3(-12, 0, -52), 22.0], [Vector3(10, 0, -54), 15.0], [Vector3(-30, 0, -40), 28.0], [Vector3(30, 0, 40), 20.0]]:
        var h: float = t[1]
        L.cyl(t[0] + Vector3(0, h * 0.12, 0), h * 0.04, h * 0.24, Color.WHITE, false, Vector3.ZERO, trunk)
        _gcone(L, t[0] + Vector3(0, h * 0.5, 0), h * 0.3, 0.2, h * 0.6, leaf)
        _gcone(L, t[0] + Vector3(0, h * 0.75, 0), h * 0.22, 0.2, h * 0.45, leaf)
    _gfill(L, Vector3(-36, 18, 20), Color("c9d6ea"), 22.0, 1.2, 24, 46)
    _gfill(L, Vector3(0, 20, 50), Color("c9d6ea"), 22.0, 1.2, 24, 46)
    _gfill(L, Vector3(0, 20, -50), Color("c9d6ea"), 22.0, 1.2, 24, 46)


# ---------------------------------------------------------- Birthday Party
static func _giant_party(L) -> void:
    _gground(L, L.tex("wood_floor", Color("8b7964"), 18.0))
    var sponge := _gm("d9b779", "84643d", 0.8)
    var icing := _gm("d986a0", "78475d", 0.6)
    var ck := Vector3(0, 0, 62)
    _gprism(L, ck + Vector3(0, 11, 0), 20.0, 22.0, sponge, PI / 6.0)
    _gprism(L, ck + Vector3(0, 11, 0), 20.3, 2.0, icing, PI / 6.0)
    _gprism(L, ck + Vector3(0, 23.5, 0), 20.4, 3.0, icing, PI / 6.0)
    _gball(L, ck + Vector3(0, 26.5, 2), 2.4, _gm("c0453a", "5e211c", 0.4))
    L.cyl(ck + Vector3(-6, 30, 4), 0.7, 8.0, Color.WHITE, false, Vector3.ZERO, _gm("75a9c0", "3d657c", 0.6))
    L.sphere(ck + Vector3(-6, 35, 4), 0.9, Color.WHITE, Vector3(1, 1.8, 1), L.glow_mat(Color("ffd59a"), 3.0))
    var plate := _gm("e5ddc9", "7f786a", 0.4)
    var cupm := _gm("75a9c0", "3d657c", 0.4)
    for i in 3:
        L.cyl(Vector3(42, 0.6 + i * 1.2, 8), 9.0, 1.0, Color.WHITE, false, Vector3.ZERO, plate)
    for c in [Vector3(40, 0, -6), Vector3(48, 0, 22)]:
        _gcone(L, c + Vector3(0, 5, 0), 3.5, 5.0, 10.0, cupm)
        L.cyl(c + Vector3(0, 10.05, 0), 4.6, 0.1, Color.WHITE, false, Vector3.ZERO, L.mat(Color("b7dce5"), 0.3))
    var gifts := [[Vector3(-44, 0, 0), 30.0, "4f7fae", "bd5b50"], [Vector3(-42, 30, -1), 20.0, "648d69", "d8b64d"], [Vector3(-40, 0, -28), 22.0, "bd5b50", "d8b64d"]]
    for g in gifts:
        var p0: Vector3 = g[0]
        var sz: float = g[1]
        _gbox(L, p0 + Vector3(0, sz * 0.5, 0), Vector3(sz, sz, sz), _gm(g[2], Color(g[2]).darkened(0.45).to_html(false), 0.7))
        var rib := _gm(g[3], Color(g[3]).darkened(0.45).to_html(false), 0.5)
        _gbox(L, p0 + Vector3(0, sz * 0.5, 0), Vector3(sz + 0.2, sz + 0.2, 3), rib)
        _gbox(L, p0 + Vector3(0, sz * 0.5, 0), Vector3(3, sz + 0.2, sz + 0.2), rib)
        for s in [-1.0, 1.0]:
            _gball(L, p0 + Vector3(s * 2.5, sz + 1.5, 0), 2.2, rib, Vector3(1.3, 0.8, 0.6))
    var hats := [[Vector3(-10, 0, -52), "d8b64d", "c0453a"], [Vector3(8, 0, -54), "c0453a", "d8b64d"], [Vector3(22, 0, -50), "4f7fae", "e5ddc9"]]
    for h in hats:
        _gcone(L, h[0] + Vector3(0, 10, 0), 7.5, 0.4, 20.0, _gm(h[1], Color(h[1]).darkened(0.45).to_html(false), 0.7))
        _gcone(L, h[0] + Vector3(0, 6, 0), 5.85, 5.2, 1.6, _gm(h[2], Color(h[2]).darkened(0.45).to_html(false), 0.7))
        _gball(L, h[0] + Vector3(0, 20.5, 0), 1.8, _gm(h[2], Color(h[2]).darkened(0.45).to_html(false), 0.9))
    var swags := [[Vector3(-42, 50, -2), Vector3(-6, 34, 60), "4c9b99"], [Vector3(-42, 48, -2), Vector3(42, 12, 8), "d46f5c"], [Vector3(-40, 22, -28), Vector3(22, 20, -50), "d9b64c"]]
    for sw in swags:
        var a: Vector3 = sw[0]
        var b: Vector3 = sw[1]
        var sm := _gm(sw[2], Color(sw[2]).darkened(0.45).to_html(false), 0.8)
        var prev := a
        for i in range(1, 15):
            var t := i / 14.0
            var p := a.lerp(b, t) + Vector3(0, -sin(t * PI) * 8.0, 0)
            _grod(L, prev, p, 2.0, sm)
            prev = p
    var bal := [[Vector3(-34, 48, -50), 8.0, "b9554c"], [Vector3(34, 54, -44), 7.0, "4f7fae"], [Vector3(44, 50, 40), 9.0, "d8b64d"], [Vector3(-40, 56, 42), 7.5, "648d69"]]
    for bl in bal:
        _gball(L, bl[0], bl[1], _gm(bl[2], Color(bl[2]).darkened(0.45).to_html(false), 0.3), Vector3(1, 1.15, 1))
        _gball(L, bl[0] + Vector3(-bl[1] * 0.4, bl[1] * 0.5, -bl[1] * 0.4), bl[1] * 0.2, L.mat(Color("f2eee5"), 0.2))
        L.cyl(bl[0] + Vector3(0, -bl[1] * 1.15 - bl[0].y * 0.5 + bl[1] * 0.6, 0), 0.12, bl[0].y - bl[1], Color("e5ddc9"), false)
    for f in [[Vector3(0, 34, 50), Color("ffd9b0"), 30.0, 2.0], [Vector3(-34, 34, 0), Color("ffd9b0"), 26.0, 1.6], [Vector3(36, 22, 8), Color("ffe6c8"), 22.0, 1.4], [Vector3(8, 28, -46), Color("ffd9b0"), 24.0, 1.5]]:
        _gfill(L, f[0], f[1], f[2], f[3], 26, 42)
    _gfill(L, Vector3(-30, 40, 30), Color("d986a0"), 30.0, 0.8, 26, 42)        # small coloured accents
    _gfill(L, Vector3(30, 40, -30), Color("75a9c0"), 30.0, 0.8, 26, 42)


# ---------------------------------------------------------- Snow Day
static func _giant_snowday(L) -> void:
    _gground(L, L.tex("snow", Color("a8b8c6"), 20.0))   # renders close to the spec #C5D5E3
    var snowman := _gm("d2dde5", "849bae", 0.6, 0.5)
    var sp := Vector3(0, 0, 64)
    _gball(L, sp + Vector3(0, 13, 0), 14.0, snowman)
    _gball(L, sp + Vector3(0, 33, 0), 10.0, snowman)
    _gball(L, sp + Vector3(0, 48, 0), 7.0, snowman)
    var coal = L.mat(Color("23262a"), 0.7)
    for ex in [-2.6, 2.6]:
        _gball(L, sp + Vector3(ex, 50, -6.2), 0.9, coal)
    for by in [28.0, 33.0, 38.0]:
        _gball(L, sp + Vector3(0, by, -9.6), 1.0, coal)
    _gcone(L, sp + Vector3(0, 47.5, -9.5), 1.2, 0.2, 5.0, _gm("d9822b", "6d4115", 0.6), Vector3(-PI / 2, 0, 0))
    var scarf := _gm("418c91", "24565e", 0.9)
    _gring(L, sp + Vector3(0, 42, 0), 7.2, 2.6, scarf)
    _gbox(L, sp + Vector3(4, 35, -6.5), Vector3(3.6, 12, 1.4), scarf, Vector3(0.15, 0, 0.1))
    _gbox(L, sp + Vector3(4.2, 29.5, -7.2), Vector3(3.6, 1.0, 1.5), _gm("82c0b9", "41605c", 0.9), Vector3(0.15, 0, 0.1))
    var navy := _gm("344b66", "1b2b40", 0.6)
    var sole := _gm("343a40", "1b2026", 0.7)
    for bz in [4.0, 18.0]:
        var b0 := Vector3(38, 0, bz)
        _gbox(L, b0 + Vector3(2, 16, 0), Vector3(12, 22, 12), navy)
        _gbox(L, b0 + Vector3(-6, 5, 0), Vector3(16, 8, 12), navy)
        _gbox(L, b0 + Vector3(-2, 1, 0), Vector3(24, 2, 13), sole)
        _gbox(L, b0 + Vector3(2, 26, 0), Vector3(12.6, 3, 12.6), _gm("6f8ba6", "3a4a5a", 0.8))
    var mit := _gm("a94e54", "5e303a", 0.95)
    var mp := Vector3(-38, 0, 16)
    _gball(L, mp + Vector3(0, 13, 0), 1.0, mit, Vector3(6, 10, 9))
    _gball(L, mp + Vector3(0, 10, -9), 1.0, mit, Vector3(3.5, 6, 3.5))
    L.cyl(mp + Vector3(0, 3, 0), 7.5, 6.0, Color.WHITE, false, Vector3.ZERO, _gm("d88984", "6e4542", 0.95))
    var red := _gm("b94c43", "632d2b", 0.5)
    var steel := _gm("84949c", "414a4e", 0.3)
    steel.metallic = 0.5
    var sl := Vector3(0, 0, -56)
    _gbox(L, sl + Vector3(0, 6, 0), Vector3(40, 2, 20), red)
    for i in 4:
        _gbox(L, sl + Vector3(-15 + i * 10, 7.05, 0), Vector3(0.4, 0.1, 19), _gm("e37c67", "71403a", 0.6))
    for s in [-1.0, 1.0]:
        _gbox(L, sl + Vector3(0, 1, s * 8), Vector3(40, 1, 1.2), steel)
        for dx in [-12.0, 0.0, 12.0]:
            _gbox(L, sl + Vector3(dx, 3.5, s * 8), Vector3(1, 4, 1), steel)
        _gring(L, sl + Vector3(-21, 4.5, s * 8), 3.6, 1.0, steel, Vector3(PI / 2, 0, 0))
    var wood := _gm("9a704b", "503a2a", 0.7)
    _gbox(L, Vector3(-34, 16, -30), Vector3(1.6, 30, 1.6), wood, Vector3(0, 0, 0.14))
    _gbox(L, Vector3(-36.3, 31.5, -30), Vector3(1.4, 1.4, 5), wood)
    _gbox(L, Vector3(-31.8, 1.5, -30), Vector3(0.8, 9, 8), _gm("748b9c", "394f62", 0.4), Vector3(0, 0, 0.14))
    for f in [[Vector3(30, 26, 12), 26.0], [Vector3(-30, 20, 16), 22.0], [Vector3(0, 40, 52), 30.0], [Vector3(0, 18, -50), 22.0], [Vector3(-30, 22, -28), 20.0]]:
        _gfill(L, f[0], Color("ffe8cf"), f[1], 0.9, 24, 44)      # faint warm reflected fill


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
    _floors(L, rooms, L.tex("wood_floor", Color("826a50"), 10.0), 26, 42, {"A": floor_m, "B": floor_m, "C": floor_m})
    L.bounds(26, 42)
    _giant_attic(L)
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
    _floors(L, rooms, _gm("4b5145", "282f2b", 0.35, 0.35), 24, 44,
        {"A": L.tex("table_wood", Color(0.7, 0.6, 0.5), 5.0), "B": L.tex("tiles", Color(0.75, 0.8, 0.75), 6.0), "C": L.tex("forest", Color(0.7, 0.62, 0.55), 5.0)})
    L.bounds(24, 44)
    _giant_garden(L)
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
    _floors(L, rooms, L.tex("tiles", Color("777a7c"), 6.0, 0.4), 24, 46, {"A": tiles, "B": tiles, "C": L.tex("concrete", Color(0.85, 0.85, 0.85), 6.0)})
    L.bounds(24, 46)
    _giant_toystore(L)
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
    _floors(L, rooms, _gk_lino(), 24, 46,
        {"A": L.tex("tiles", Color(1.0, 0.97, 0.9), 3.0), "B": L.tex("wood_floor", Color(0.8, 0.7, 0.6), 8.0), "C": L.tex("concrete", Color(0.85, 0.85, 0.88), 6.0)})
    L.bounds(24, 46)
    _giant_kitchen(L)
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
    _floors(L, rooms, L.tex("tiles", Color("85847b"), 6.0, 0.5), 30, 48,
        {"A": L.tex("wood_floor", Color(0.9, 0.8, 0.65), 8.0), "B": L.tex("tiles", Color(0.85, 0.9, 0.85), 3.0), "C": L.tex("wood_floor", Color(1.05, 0.9, 0.65), 12.0)})
    L.bounds(30, 48)
    _giant_school(L)
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
    _floors(L, rooms, L.tex("beach_sand", Color("c7a36f"), 8.0), 26, 46,
        {"A": L.tex("table_wood", Color(0.75, 0.6, 0.45), 4.0), "C": L.tex("table_wood", Color(0.65, 0.55, 0.45), 3.0)})
    L.bounds(26, 46)
    _giant_beach(L)
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
        "fog": 0.004, "ambient": 0.8, "exposure": 1.0,     # lighter sunset haze (art pass round 2)
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
    _floors(L, rooms, L.tex("tiles", Color("a0aaa9"), 5.0, 0.3), 30, 48,
        {"A": tiles, "B": L.tex("carpet", Color(1.0, 0.85, 0.6), 4.0), "C": carpet})
    L.bounds(30, 48)
    _giant_bathtime(L)
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
    _floors(L, rooms, L.tex("concrete", Color("777b78"), 8.0), 32, 46, {"A": concrete, "B": concrete, "C": concrete})
    L.bounds(32, 46)
    _giant_garage(L)
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
    _floors(L, rooms, L.tex("carpet", Color("776b62"), 6.0), 32, 48,
        {"A": L.tex("carpet", Color(1.0, 0.95, 1.2), 3.0), "B": rug, "C": L.tex("wood_floor", Color(0.9, 0.7, 0.55), 8.0)})
    L.bounds(32, 48)
    _giant_pillowfort(L)
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
    _giant_railway(L)
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
    _floors(L, rooms, L.tex("wood_floor", Color("8b7964"), 8.0), 26, 42,
        {"A": L.tex("wood_floor", Color(1.0, 0.85, 0.7), 8.0), "B": L.tex("carpet", Color(0.8, 1.0, 1.2), 3.0), "C": L.tex("carpet", Color(1.2, 1.1, 0.6), 3.0)})
    L.bounds(26, 42)
    _giant_party(L)
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
        "fog": 0.003, "ambient": 0.9, "exposure": 1.05,     # lighter haze (art pass round 2)
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
    _floors(L, rooms, L.tex("snow", Color("a8b8c6"), 6.0), 24, 44, {"C": L.tex("wood_floor", Color(0.75, 0.6, 0.45), 8.0)})
    L.bounds(24, 44)
    _giant_snowday(L)
    var lay := _rooms(L, rooms, 4.0, L.tex("snow", Color("95a8b8"), 3.0),
        {"C": L.tex("table_wood", Color(0.75, 0.5, 0.35), 3.0)})
    var white: Material = _gm("d2dde5", "849bae", 0.6, 0.5)      # snowmen: warm off-white, never white-on-white
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
        "sky_top": Color("7897b8"), "sky_horizon": Color("afc5d8"),
        "sun_color": Color(0.95, 0.97, 1.0), "sun_energy": 0.6, "sun_rot": Vector3(-35, 60, 0),
        "fog": 0.006, "ambient": 0.8, "exposure": 0.95, "snow": true,     # less whiteout from high up (lighter fog)
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
