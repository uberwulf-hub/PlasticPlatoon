extends RefCounted
## Campaign maps. Each builder places geometry / troops / objectives through
## the Level's helper API and returns the level's settings dictionary.

const Fx = preload("res://scripts/fx.gd")

const META := [
    {
        "name": "Operation Dust Lid",
        "location": "Kharzan Desert - Forward Operating Base JULIET",
        "briefing": "Tan Army electronic-warfare teams have set up radar jammers in a fortified compound north of FOB Juliet, blinding our drones across the whole sector.\n\nPush through the village, knock out all three jammers, then get to the helipad for exfil. Grab the AT4 at the FOB - small arms barely scratch those jammers.",
        "objectives": ["Destroy 3 radar jammers", "Extract at the helipad"],
    },
    {
        "name": "Operation Concrete Jungle",
        "location": "Port Varos - Old City District",
        "briefing": "Colonel Khaki, commander of the Tan Army's 3rd Mechanized, is holding court in a plaza in the north-east of the city. Mobile SAM launchers are keeping our air support grounded.\n\nEliminate the Colonel, destroy both SAM launchers, then extract from the north-west plaza. Watch the rooftops - their snipers love high ground.",
        "objectives": ["Eliminate Colonel Khaki", "Destroy 2 mobile SAM launchers", "Extract"],
    },
    {
        "name": "Operation Tabletop",
        "location": "Somewhere much, much bigger",
        "briefing": "Intel says the Tan Army has taken the kitchen table and wired giant signal boosters into the house Wi-Fi to coordinate a full offensive.\n\nDrop in among the energy drinks and smartphones, destroy all three boosters, then wipe out every last tan soldier on the table. This is the big one, soldier.",
        "objectives": ["Destroy 3 signal boosters", "Eliminate all Tan forces"],
    },
    {
        "name": "Operation Snow Globe",
        "location": "Polar Shelf - Tan Radar Station VANILLA",
        "briefing": "The Tan Army survived the kitchen table and fled north. A defector says a new commander - General Beige - is rebuilding their radar net from Station Vanilla, an ice-bound listening post.\n\nCross the frozen flats, destroy all three radar dishes and get out before the blizzard closes the pass. Dress warm. Plastic gets brittle in the cold.",
        "objectives": ["Destroy 3 radar dishes", "Extract at the east ridge"],
    },
    {
        "name": "Operation Green Hell",
        "location": "Rio Verde Jungle - Temple of the Lost Lid",
        "briefing": "Data from the Vanilla dishes points to a jungle prison camp. Four Green soldiers captured at the table are being held in bamboo cages around an ancient temple.\n\nWade the river, reach the temple, free every POW, and get them to the north-west helipad. Nobody gets left in a cage.",
        "objectives": ["Rescue 4 Green POWs", "Extract at the north-west helipad"],
    },
    {
        "name": "Operation Bath Time",
        "location": "Upstairs Bathroom - The Porcelain Sea",
        "briefing": "The rescued POWs overheard the Tan Navy's plan: Admiral Ecru is fuelling a fleet in the bathtub for a strike on the living room. Their fuel is stored in shampoo-bottle depots along the tub.\n\nBlow all three depots, then sink the Admiral. Watch out for the rubber ducks - they've seen things.",
        "objectives": ["Destroy 3 fuel depots", "Eliminate Admiral Ecru"],
    },
    {
        "name": "Operation Beachhead",
        "location": "Crumb Coast - Landing Zone SAND DOLLAR",
        "briefing": "With the Tan Navy beached, it's time to take the coast. Major Fawn has dug four concrete bunkers into the dunes overlooking the surf.\n\nStorm the beach, knock out every bunker, then push inland to the village and take out the Major. Tanks are already rolling off the landing craft.",
        "objectives": ["Destroy 4 dune bunkers", "Eliminate Major Fawn"],
    },
    {
        "name": "Operation Sandbox",
        "location": "The Backyard - Sandbox Fortress",
        "briefing": "Major Fawn's men retreated to the backyard and built a sand-castle fortress in the sandbox. Inside: the battle plans for something called 'Operation Beige Dawn'.\n\nRecover all three pieces of intel and extract at the doghouse. Mind the garden gnome. Nobody knows whose side he's on.",
        "objectives": ["Recover 3 pieces of intel", "Extract at the doghouse"],
    },
    {
        "name": "Operation Night Shift",
        "location": "Port Ochre - Container Terminal 9",
        "briefing": "The plans show Beige Dawn needs fuel - lots of it - shipped in through Port Ochre tonight.\n\nSlip into the container yard after dark, blow the three fuel depots on the quay, and get out through the south-west gate. Stay out of the floodlights. The crane operators have snipers.",
        "objectives": ["Destroy 3 fuel depots", "Extract at the south-west gate"],
    },
    {
        "name": "Operation Bunk Bed",
        "location": "The Kid's Bedroom - Fort Blanket",
        "briefing": "General Beige is furious. His forces are massing under the bunk bed for a strike on the toy fort - the Green Army's last forward base in the house.\n\nGet to the fort, hold it until bedtime (75 seconds), then clear the room. Grab the LMG at the start - you'll need it.",
        "objectives": ["Reach the toy fort", "Hold the fort for 75 seconds", "Eliminate all Tan forces"],
    },
    {
        "name": "Operation Mountain Pass",
        "location": "Crackerjack Mountains - Biscuit Pass",
        "briefing": "General Beige's supply line runs through Biscuit Pass, guarded by two SAM sites and Brigadier Biscuit, who runs the pass from a ski lodge at the top.\n\nFight up the canyon, destroy both SAM sites, and take out the Brigadier. Snipers are dug in on rock pillars all along the valley.",
        "objectives": ["Destroy 2 SAM sites", "Eliminate Brigadier Biscuit"],
    },
    {
        "name": "Operation Garage Sale",
        "location": "The Garage - Everything Must Go",
        "briefing": "The last convoy from the pass rolled into the garage, where the Tan Army is hiding fuel in gas cans among the garage-sale junk. Somewhere in here is a map to General Beige's headquarters.\n\nDestroy both fuel depots and find all three pieces of the map. Climb the ramps to the workbench and shelves - the Tan love high ground.",
        "objectives": ["Destroy 2 fuel depots", "Recover 3 map pieces"],
    },
    {
        "name": "Operation Beige Dawn",
        "location": "The Living Room - Couch Fortress",
        "briefing": "This is it. General Beige has turned the couch into a fortress and is broadcasting 'Beige Dawn' - a plan to paint the whole house beige - through three TV antennas.\n\nDestroy the antennas, climb the cushions and defeat General Beige himself, then extract on the rug by the window. He's big, he's beige, and he brought an LMG. Good luck, soldier.",
        "objectives": ["Destroy 3 TV antennas", "Defeat General Beige", "Extract by the window"],
    },
]


static func build(i: int, L) -> Dictionary:
    var d: Dictionary
    match i:
        0:
            d = _desert(L)
        1:
            d = _urban(L)
        2:
            d = _tabletop(L)
        3:
            d = _snow(L)
        4:
            d = _jungle(L)
        5:
            d = _bathroom(L)
        6:
            d = _beach(L)
        7:
            d = _sandbox(L)
        8:
            d = _port(L)
        9:
            d = _bedroom(L)
        10:
            d = _mountain(L)
        11:
            d = _garage(L)
        _:
            d = _living_room(L)
    d["name"] = META[clampi(i, 0, META.size() - 1)]["name"]
    return d


static func _rot(v: Vector3, r: float) -> Vector3:
    return v.rotated(Vector3.UP, r)


# ----------------------------------------------------------- props ----

const TOON := "quaternius_toon_shooter/Environment/"
const CARS := ["sedan", "suv", "taxi", "van", "police", "hatchback-sports", "truck", "delivery", "ambulance", "sedan-sports"]


static func container(L, pos: Vector3, rot: float, color: Color) -> void:
    if L.prop(TOON + "Container_Long.gltf", pos, rot + PI / 2, Vector3(6.1, 2.6, 2.5), true, color.lightened(0.25)):
        return
    L.box(pos + Vector3(0, 1.3, 0), Vector3(2.5, 2.6, 6.1), color, rot)
    for i in 5:
        var off := _rot(Vector3(1.27, 1.3, -2.4 + i * 1.2), rot)
        L.box(pos + off, Vector3(0.06, 2.4, 0.15), color.darkened(0.2), rot, false)


static func vehicle(L, pos: Vector3, rot: float, color: Color, burnt := false) -> void:
    if burnt:
        if L.prop(TOON + "Debris_BrokenCar.gltf", pos, rot, Vector3(0, 1.8, 5.0)):
            var f := Fx.fire(L, pos + Vector3(0, 1.4, 0), 0.8)
            f.amount = 14
            return
    else:
        var car: String = CARS[absi(int(pos.x * 7.0 + pos.z * 13.0)) % CARS.size()]
        if L.prop("kenney_car_kit/%s.glb" % car, pos, rot, Vector3(0, 0, 4.8)):
            return
    var c := color.darkened(0.6) if burnt else color
    L.box(pos + Vector3(0, 0.9, 0), Vector3(2.3, 1.0, 4.8), c, rot)
    L.box(pos + _rot(Vector3(0, 1.75, -0.4), rot), Vector3(2.1, 0.8, 2.2), c.darkened(0.1), rot)
    L.box(pos + _rot(Vector3(0, 1.8, -1.52), rot), Vector3(1.9, 0.6, 0.05), Color(0.2, 0.25, 0.3), rot, false)
    for x in [-1.15, 1.15]:
        for z in [-1.5, 1.5]:
            L.cyl(pos + _rot(Vector3(x, 0.45, z), rot), 0.45, 0.35, Color(0.1, 0.1, 0.1), false, Vector3(0, rot, PI / 2))
    if burnt:
        var f := Fx.fire(L, pos + Vector3(0, 1.6, 0), 0.8)
        f.amount = 14


static func hesco(L, a: Vector3, b: Vector3, color: Color) -> void:
    L.wall(a, b, 1.9, 1.4, color)
    L.wall(a + Vector3(0, 1.9, 0), b + Vector3(0, 1.9, 0), 0.15, 1.45, color.darkened(0.15))


static func watchtower(L, pos: Vector3, color: Color) -> void:
    for x in [-1.7, 1.7]:
        for z in [-1.7, 1.7]:
            L.box(pos + Vector3(x, 2.5, z), Vector3(0.3, 5.0, 0.3), color.darkened(0.3))
    L.box(pos + Vector3(0, 5.15, 0), Vector3(4.2, 0.3, 4.2), color)
    for s in [-1, 1]:
        L.box(pos + Vector3(2.0 * s, 5.8, 0), Vector3(0.2, 1.0, 4.2), color)
        L.box(pos + Vector3(0, 5.8, 2.0 * s), Vector3(4.2, 1.0, 0.2), color)
    L.box(pos + Vector3(0, 7.6, 0), Vector3(4.6, 0.2, 4.6), color.darkened(0.2), 0.0, false)


static func sandbags(L, pos: Vector3, rot: float, length := 4.0) -> void:
    if L.prop(TOON + "SackTrench.gltf", pos, rot, Vector3(length, 1.15, 1.0)):
        return
    L.box(pos + Vector3(0, 0.5, 0), Vector3(length, 1.0, 0.9), Color(0.68, 0.6, 0.42), rot)


static func palm(L, pos: Vector3) -> void:
    if L.prop("kenney_nature/tree_palmTall.glb", pos, pos.x, Vector3(0, 7.5, 0)):
        return
    L.cyl(pos + Vector3(0, 3.0, 0), 0.25, 6.0, Color(0.45, 0.35, 0.22), true, Vector3.ZERO, null, 0.18)
    for i in 6:
        var a := i * TAU / 6.0
        L.box_rot(pos + Vector3(cos(a) * 1.4, 6.1, sin(a) * 1.4), Vector3(3.0, 0.08, 0.7), Color(0.3, 0.5, 0.2), Vector3(0, -a, deg_to_rad(-20)), false)


static func tree(L, pos: Vector3) -> void:
    var kind: String = ["tree_default", "tree_oak", "tree_detailed"][absi(int(pos.x + pos.z)) % 3]
    if L.prop("kenney_nature/%s.glb" % kind, pos, pos.z, Vector3(0, 6.0, 0)):
        return
    L.cyl(pos + Vector3(0, 1.5, 0), 0.3, 3.0, Color(0.4, 0.3, 0.2))
    L.sphere(pos + Vector3(0, 4.2, 0), 2.2, Color(0.25, 0.45, 0.2), Vector3(1, 0.85, 1))


static func rocks(L, rng: RandomNumberGenerator, count: int, half: float, avoid: Array, color: Color) -> void:
    var placed := 0
    var guard := 0
    while placed < count and guard < count * 20:
        guard += 1
        var p := Vector3(rng.randf_range(-half, half), 0, rng.randf_range(-half, half))
        var ok := true
        for a in avoid:
            if Vector2(p.x - a[0].x, p.z - a[0].z).length() < a[1]:
                ok = false
                break
        if not ok:
            continue
        var s := rng.randf_range(0.8, 3.0)
        var rock: String = ["rock_largeA", "rock_largeB", "rock_largeC", "rock_tallA", "rock_tallB", "stone_largeA"][rng.randi() % 6]
        if L.prop("kenney_nature/%s.glb" % rock, p, rng.randf() * TAU, Vector3(s * 1.6, 0, s * 1.6), true, color.lightened(0.3)):
            placed += 1
            continue
        L.box_rot(p + Vector3(0, s * 0.35, 0), Vector3(s * 1.4, s, s * 1.1), color, Vector3(rng.randf() * 0.3, rng.randf() * TAU, rng.randf() * 0.3))
        placed += 1


# ======================================================== 1: DESERT ====

static func _desert(L) -> Dictionary:
    var rng := RandomNumberGenerator.new()
    rng.seed = 2026
    var sand := Color(0.66, 0.54, 0.36)
    var hesco_c := Color(0.7, 0.62, 0.44)
    var mud := Color(0.78, 0.66, 0.48)
    var green := Color(0.3, 0.38, 0.24)

    L.box(Vector3(0, -0.5, 0), Vector3(260, 1, 260), sand)
    L.bounds(108, 108)
    for s in [-1, 1]:
        L.box(Vector3(0, 1.5, 112 * s), Vector3(240, 6, 8), sand.darkened(0.06), 0.0, false)
        L.box(Vector3(112 * s, 1.5, 0), Vector3(8, 6, 240), sand.darkened(0.06), 0.0, false)
    # Dunes (visual swells that hug the ground).
    for i in 14:
        var p := Vector3(rng.randf_range(-100, 100), -2.2, rng.randf_range(-100, 100))
        L.sphere(p, 6.0, sand.darkened(0.03), Vector3(rng.randf_range(1.5, 3.0), 0.45, rng.randf_range(1.5, 3.0)))

    # --- FOB Juliet (south) ---
    hesco(L, Vector3(-22, 0, 70), Vector3(-6, 0, 70), hesco_c)
    hesco(L, Vector3(6, 0, 70), Vector3(22, 0, 70), hesco_c)
    hesco(L, Vector3(-22, 0, 70), Vector3(-22, 0, 100), hesco_c)
    hesco(L, Vector3(22, 0, 70), Vector3(22, 0, 100), hesco_c)
    hesco(L, Vector3(-22, 0, 100), Vector3(22, 0, 100), hesco_c)
    L.box(Vector3(-13, 1.3, 91), Vector3(7, 2.6, 9), Color(0.5, 0.47, 0.36))
    L.box(Vector3(13, 1.3, 91), Vector3(7, 2.6, 9), Color(0.5, 0.47, 0.36))
    container(L, Vector3(15, 0, 78), 0.0, green)
    L.add_vehicle("tank", Vector3(-12, 0, 80), 0.0)
    L.add_enemy_vehicle("jeep", Vector3(15, 0, 28), PI)
    L.add_enemy_vehicle("jeep", Vector3(-35, 0, -30), PI)
    L.add_enemy_vehicle("tank", Vector3(14, 0, -60), PI)
    L.add_vehicle("jeep", Vector3(6, 0, 93), 0.0)
    L.add_vehicle("apc", Vector3(-3, 0, 92), 0.0)
    L.add_vehicle("heli", Vector3(0, 0, 76), 0.0)
    L.cyl(Vector3(0, 4, 95), 0.08, 8, Color(0.6, 0.6, 0.6), false)
    L.box(Vector3(0.8, 7.3, 95), Vector3(1.5, 0.9, 0.04), Color(0.3, 0.55, 0.2), 0.0, false)
    L.add_pickup(Vector3(-5, 0, 80), "launcher")
    L.add_pickup(Vector3(5, 0, 80), "ammo")
    L.add_pickup(Vector3(-9, 0, 76), "grenades")
    L.add_pickup(Vector3(9, 0, 76), "armor")

    # --- Village (middle) ---
    var houses := [
        [-40, 10, 10, 4, 8], [-24, 26, 8, 3.5, 9], [-46, -16, 12, 4, 8], [30, 16, 10, 4.5, 9],
        [46, -4, 8, 4, 8], [18, 38, 9, 3.5, 7], [-12, -12, 7, 3, 7], [60, 30, 10, 4, 10],
        [-66, 32, 9, 4, 9], [-6, 46, 6, 3, 6], [70, -30, 8, 4, 8],
    ]
    for h in houses:
        L.box(Vector3(h[0], h[3] * 0.5, h[1]), Vector3(h[2], h[3], h[4]), mud)
        L.box(Vector3(h[0], h[3] + 0.3, h[1]), Vector3(h[2] + 0.3, 0.6, h[4] + 0.3), mud.darkened(0.08))
        L.box(Vector3(h[0], h[3] * 0.35, h[1] + h[4] * 0.5 + 0.02), Vector3(1.2, h[3] * 0.7, 0.05), Color(0.25, 0.18, 0.12), 0.0, false)
    container(L, Vector3(5, 0, 20), 0.3, Color(0.55, 0.2, 0.15))
    container(L, Vector3(-30, 0, 46), 1.2, Color(0.2, 0.35, 0.55))
    container(L, Vector3(40, 0, 50), -0.4, Color(0.6, 0.45, 0.2))
    container(L, Vector3(-62, 0, -4), 0.8, Color(0.3, 0.4, 0.3))
    vehicle(L, Vector3(12, 0, -6), 1.1, Color(0.7, 0.62, 0.44), true)
    vehicle(L, Vector3(-30, 0, -32), 2.4, Color(0.45, 0.4, 0.35), true)
    for p in [Vector3(-18, 0, 12), Vector3(38, 0, 30), Vector3(-52, 0, 20), Vector3(55, 0, 8)]:
        palm(L, p)
    sandbags(L, Vector3(-20, 0, 2), 0.2)
    sandbags(L, Vector3(25, 0, 5), -0.3)
    sandbags(L, Vector3(0, 0, -30), 0.0, 6.0)

    # --- Tan compound (north) ---
    var tan_h := Color(0.76, 0.66, 0.46)
    hesco(L, Vector3(-52, 0, -44), Vector3(-7, 0, -44), tan_h)
    hesco(L, Vector3(7, 0, -44), Vector3(52, 0, -44), tan_h)
    hesco(L, Vector3(-52, 0, -44), Vector3(-52, 0, -96), tan_h)
    hesco(L, Vector3(52, 0, -44), Vector3(52, 0, -60), tan_h)
    hesco(L, Vector3(52, 0, -72), Vector3(52, 0, -96), tan_h)
    hesco(L, Vector3(-52, 0, -96), Vector3(52, 0, -96), tan_h)
    for p in [Vector3(-45, 0, -51), Vector3(45, 0, -51), Vector3(45, 0, -89), Vector3(-45, 0, -89)]:
        watchtower(L, p, tan_h.darkened(0.1))
    container(L, Vector3(-15, 0, -62), 1.57, Color(0.62, 0.52, 0.34))
    container(L, Vector3(20, 0, -75), 0.0, Color(0.62, 0.52, 0.34))
    container(L, Vector3(-38, 0, -76), 0.0, Color(0.5, 0.42, 0.3))
    L.box(Vector3(0, 2, -90), Vector3(14, 4, 7), Color(0.6, 0.52, 0.38))
    sandbags(L, Vector3(-9, 0, -38), 0.0)
    sandbags(L, Vector3(9, 0, -38), 0.0)
    sandbags(L, Vector3(-25, 0, -56), 0.4)
    sandbags(L, Vector3(28, 0, -58), -0.4)
    L.add_target(Vector3(-30, 0, -80), "jammer", "jammers")
    L.add_target(Vector3(5, 0, -82), "jammer", "jammers")
    L.add_target(Vector3(34, 0, -64), "jammer", "jammers", 0.5)
    L.add_pickup(Vector3(-48, 0, -60), "ammo")
    L.add_pickup(Vector3(0, 0, -50), "health")
    L.add_pickup(Vector3(-62, 0, 10), "sniper")
    L.add_pickup(Vector3(62, 0, -15), "health")
    L.add_pickup(Vector3(-35, 0, 22), "ammo")
    L.add_pickup(Vector3(35, 0, -20), "grenades")
    L.add_pickup(Vector3(48, 0, 18), "lmg")

    var troops := [
        [Vector3(-30, 0, 16), "rifleman"], [Vector3(-20, 0, 5), "rifleman"], [Vector3(26, 0, 26), "rifleman"],
        [Vector3(36, 0, 6), "gunner"], [Vector3(8, 0, 2), "rifleman"], [Vector3(-52, 0, -26), "rifleman"],
        [Vector3(52, 0, 22), "rocketeer"], [Vector3(2, 0, 30), "rifleman"], [Vector3(-4, 0, -26), "rifleman"],
        [Vector3(58, 0, -18), "rifleman"], [Vector3(-9, 0, -36), "rifleman"], [Vector3(9, 0, -36), "gunner"],
        [Vector3(-30, 0, -68), "gunner"], [Vector3(-20, 0, -84), "rifleman"], [Vector3(5, 0, -72), "rifleman"],
        [Vector3(15, 0, -86), "rocketeer"], [Vector3(34, 0, -76), "rifleman"], [Vector3(26, 0, -54), "gunner"],
        [Vector3(-38, 0, -58), "rifleman"], [Vector3(40, 0, -86), "rifleman"], [Vector3(66, 0, -22), "rifleman"],
        [Vector3(76, 0, 4), "rifleman"], [Vector3(-8, 0, -55), "rocketeer"],
        [Vector3(-45, 5.4, -51), "sniper"], [Vector3(45, 5.4, -51), "sniper"], [Vector3(45, 5.4, -89), "sniper"],
    ]
    var avoid := [[Vector3(0, 0, 85), 30.0], [Vector3(0, 0, -70), 60.0], [Vector3(72, 0, -5), 12.0]]
    for t in troops:
        L.add_enemy(t[0] + Vector3(0, 0.1, 0), t[1])
        avoid.append([t[0], 4.0])
    for h in houses:
        avoid.append([Vector3(h[0], 0, h[1]), 9.0])
    rocks(L, rng, 30, 100.0, avoid, Color(0.62, 0.5, 0.38))
    for b in [Vector3(-25, 0, -70), Vector3(-23.8, 0, -70.6), Vector3(15, 0, -60), Vector3(29, 0, -82),
            Vector3(12, 0, 10), Vector3(-36, 0, 4), Vector3(42, 0, 12)]:
        L.add_barrel(b)
    L.prop(TOON + "WaterTank_Platform.gltf", Vector3(-20, 0, -92), 0.0, Vector3(0, 7.0, 0))
    L.prop(TOON + "Barrier_Large.gltf", Vector3(-13, 0, -41), 0.0, Vector3(4.5, 0, 0))
    L.prop(TOON + "Barrier_Large.gltf", Vector3(13, 0, -41), 0.0, Vector3(4.5, 0, 0))
    L.prop(TOON + "Structure_2.gltf", Vector3(-58, 0, 50), 0.4, Vector3(0, 4.5, 0))
    for i in 14:
        var cp := Vector3(rng.randf_range(-95, 95), 0, rng.randf_range(-95, 95))
        var clear := true
        for a in avoid:
            if Vector2(cp.x - a[0].x, cp.z - a[0].z).length() < a[1]:
                clear = false
        if clear:
            var tall := i % 2 == 0
            L.prop("kenney_nature/%s.glb" % ("cactus_tall" if tall else "cactus_short"), cp, rng.randf() * TAU,
                Vector3(0, rng.randf_range(2.5, 4.0) if tall else rng.randf_range(1.2, 1.8), 0))

    return {
        "spawn": Vector3(0, 0.5, 86), "spawn_yaw": 0.0, "drones": 1, "safe_radius": 24.0,
        "start_weapons": ["carbine", "shotgun"],
        "sky_top": Color(0.32, 0.55, 0.85), "sky_horizon": Color(0.9, 0.82, 0.68),
        "sun_color": Color(1.0, 0.93, 0.8), "sun_energy": 1.15, "sun_rot": Vector3(-52, 30, 0),
        "fog": 0.0035, "ambient": 0.7, "exposure": 0.85,
        "music": "res://assets/audio/music/battle_theme_a.ogg", "ambience": "res://assets/audio/ambience/desert_wind.ogg", "ambience_db": -10.0, "distant_booms": true,
        "objectives": [
            {"type": "destroy", "tag": "jammers", "text": "Destroy the Tan Army radar jammers"},
            {"type": "extract", "pos": Vector3(74, 0, -6), "text": "Reach the extraction helipad (east)"},
        ],
    }


# ========================================================= 2: URBAN ====

static func _urban(L) -> Dictionary:
    var rng := RandomNumberGenerator.new()
    rng.seed = 7
    var asphalt := Color(0.3, 0.31, 0.33)
    L.box(Vector3(0, -0.5, 0), Vector3(240, 1, 240), asphalt)
    L.bounds(102, 102)
    var streets := [-50.0, 0.0, 50.0]
    var ranges := [[-100.0, -57.0], [-43.0, -7.0], [7.0, 43.0], [57.0, 100.0]]
    for s in streets:
        for k in range(-10, 10):
            var z := k * 10.0 + 5.0
            L.box(Vector3(s, 0.02, z), Vector3(0.3, 0.02, 4.0), Color(0.85, 0.75, 0.2), 0.0, false)
            L.box(Vector3(z, 0.02, s), Vector3(4.0, 0.02, 0.3), Color(0.85, 0.75, 0.2), 0.0, false)
    var palette := [Color(0.62, 0.6, 0.56), Color(0.55, 0.36, 0.3), Color(0.7, 0.66, 0.58), Color(0.45, 0.47, 0.5), Color(0.66, 0.55, 0.42), Color(0.5, 0.52, 0.46)]
    var special := {"2,0": "hvt", "0,2": "samA", "3,1": "samB", "0,0": "exfil", "1,3": "park"}
    var snipers := 0
    for i in 4:
        for j in 4:
            var x0: float = ranges[i][0]
            var x1: float = ranges[i][1]
            var z0: float = ranges[j][0]
            var z1: float = ranges[j][1]
            var cx := (x0 + x1) * 0.5
            var cz := (z0 + z1) * 0.5
            # sidewalk slab (visual)
            L.box(Vector3(cx, 0.03, cz), Vector3(x1 - x0, 0.04, z1 - z0), Color(0.55, 0.55, 0.53), 0.0, false)
            var key := "%d,%d" % [i, j]
            if special.has(key):
                _urban_special(L, special[key], Vector3(cx, 0, cz))
                continue
            var lw := (x1 - x0 - 6.0 - 4.0) * 0.5
            var ld := (z1 - z0 - 6.0 - 4.0) * 0.5
            for a in 2:
                for b in 2:
                    var bx := x0 + 3.0 + lw * 0.5 + a * (lw + 4.0)
                    var bz := z0 + 3.0 + ld * 0.5 + b * (ld + 4.0)
                    var h := rng.randf_range(7.0, 26.0)
                    var col: Color = palette[rng.randi() % palette.size()]
                    var model := ""
                    if h > 20.0:
                        model = "kenney_city_commercial/building-skyscraper-%s.glb" % "abcde"[rng.randi() % 5]
                    elif i == 3 or j == 3:
                        model = "kenney_city_industrial/building-%s.glb" % "abcdefghijklmnopqrst"[rng.randi() % 20]
                    else:
                        model = "kenney_city_commercial/building-%s.glb" % "abcdefghijklmn"[rng.randi() % 14]
                    var face: float = [0.0, PI / 2, PI, -PI / 2][rng.randi() % 4]
                    var fit := Vector3(ld, h, lw) if absf(sin(face)) > 0.5 else Vector3(lw, h, ld)
                    if L.prop(model, Vector3(bx, 0, bz), face, fit) == null:
                        L.box(Vector3(bx, h * 0.5, bz), Vector3(lw, h, ld), col)
                        var band := col.darkened(0.45)
                        var y := 3.0
                        while y < h - 1.5:
                            L.box(Vector3(bx, y, bz), Vector3(lw + 0.12, 1.1, ld + 0.12), band, 0.0, false)
                            y += 4.0
                    if snipers < 5 and h < 18.0 and rng.randf() < 0.28:
                        snipers += 1
                        L.box(Vector3(bx, h, bz), Vector3(lw, 0.2, ld), col)   # walkable roof
                        L.add_enemy(Vector3(bx, h + 0.4, bz), "sniper")

    # Street furniture
    var car_cols := [Color(0.7, 0.1, 0.1), Color(0.15, 0.25, 0.55), Color(0.85, 0.85, 0.82), Color(0.1, 0.1, 0.1), Color(0.75, 0.6, 0.15)]
    var cars := [
        [Vector3(3, 0, 62), 0.0], [Vector3(-3, 0, 28), 3.1], [Vector3(4, 0, -24), 0.1], [Vector3(-4, 0, -72), 3.0],
        [Vector3(25, 0, 3), 1.57], [Vector3(-30, 0, -3), -1.6], [Vector3(72, 0, 3), 1.5], [Vector3(53, 0, 38), 0.0],
        [Vector3(47, 0, -76), 3.1], [Vector3(-47, 0, 20), 0.2], [Vector3(-53, 0, -32), 3.0], [Vector3(20, 0, -47), 1.6],
        [Vector3(-76, 0, -53), -1.5], [Vector3(-22, 0, 53), 1.5], [Vector3(76, 0, 47), -1.6], [Vector3(-80, 0, 3), 1.4],
    ]
    for i in cars.size():
        vehicle(L, cars[i][0], cars[i][1], car_cols[i % car_cols.size()], i % 5 == 2)
    for p in [Vector3(-4.5, 0, 40), Vector3(4.5, 0, 40), Vector3(-4.5, 0, -40), Vector3(4.5, 0, -40),
            Vector3(40, 0, -3), Vector3(40, 0, 3), Vector3(-40, 0, 0), Vector3(50, 0, -40), Vector3(-50, 0, 40)]:
        L.box(p + Vector3(0, 0.55, 0), Vector3(3.2, 1.1, 0.7), Color(0.75, 0.74, 0.7))

    for b in [Vector3(8, 0, 8), Vector3(-8.5, 0, -46), Vector3(46, 0, 8), Vector3(-46, 0, 46), Vector3(9, 0, -52), Vector3(-9, 0, 52)]:
        L.add_barrel(b)
    for s in streets:
        for k in [-80.0, -25.0, 25.0, 80.0]:
            L.prop(TOON + "StreetLight.gltf", Vector3(s + 7.6, 0, k), PI / 2, Vector3(0, 6.5, 0))
            L.prop(TOON + "StreetLight.gltf", Vector3(k, 0, s - 7.6), 0.0, Vector3(0, 6.5, 0))
    for c in [Vector3(-2, 0, 37), Vector3(2, 0, 37), Vector3(-2, 0, -37), Vector3(2.5, 0, -37), Vector3(37, 0, 1.5)]:
        L.prop("kenney_car_kit/cone.glb", c, 0.0, Vector3(0, 0.9, 0), false)
    var troops := [
        [Vector3(0, 0, 20), "rifleman"], [Vector3(6, 0, 0), "gunner"], [Vector3(-8, 0, -6), "rifleman"],
        [Vector3(-2, 0, -38), "rifleman"], [Vector3(2, 0, -55), "rocketeer"], [Vector3(30, 0, -2), "rifleman"],
        [Vector3(50, 0, 10), "rifleman"], [Vector3(48, 0, -20), "gunner"], [Vector3(-50, 0, 30), "rifleman"],
        [Vector3(-48, 0, -10), "rifleman"], [Vector3(-25, 0, -50), "rocketeer"], [Vector3(25, 0, 50), "rifleman"],
        [Vector3(-50, 0, -50), "gunner"], [Vector3(50, 0, 60), "rifleman"], [Vector3(-20, 0, 2), "rifleman"],
        [Vector3(70, 0, -3), "rifleman"], [Vector3(0, 0, 62), "rifleman"],
    ]
    for t in troops:
        L.add_enemy(t[0] + Vector3(0, 0.1, 0), t[1])
    L.add_vehicle("jeep", Vector3(3.5, 0, 80), 0.0)
    L.add_vehicle("tank", Vector3(-3.5, 0, 72), 0.0)
    L.add_vehicle("apc", Vector3(-3.5, 0, 84), 0.0)
    L.add_enemy_vehicle("jeep", Vector3(50, 0, 30), PI)
    L.add_enemy_vehicle("jeep", Vector3(-50, 0, -20), 0.0)
    L.add_enemy_vehicle("tank", Vector3(0, 0, -30), PI)
    L.add_enemy_vehicle("tank", Vector3(25, 0, -50), PI / 2)
    L.add_pickup(Vector3(-3, 0, 85), "ammo")
    L.add_pickup(Vector3(3, 0, 85), "armor")
    L.add_pickup(Vector3(0, 0, 50), "lmg")
    L.add_pickup(Vector3(-50, 0, 60), "health")
    L.add_pickup(Vector3(50, 0, -50), "health")
    L.add_pickup(Vector3(0, 0, -2), "grenades")
    L.add_pickup(Vector3(-50, 0, 0), "ammo")
    L.add_pickup(Vector3(50, 0, 0), "launcher")
    L.add_pickup(Vector3(0, 0, -50), "ammo")

    return {
        "spawn": Vector3(0, 0.5, 92), "spawn_yaw": 0.0, "drones": 2, "safe_radius": 22.0,
        "start_weapons": ["carbine", "shotgun", "launcher"],
        "sky_top": Color(0.4, 0.5, 0.65), "sky_horizon": Color(0.78, 0.74, 0.7),
        "sun_color": Color(1.0, 0.85, 0.7), "sun_energy": 1.15, "sun_rot": Vector3(-35, -40, 0),
        "fog": 0.006, "ambient": 0.8,
        "music": "res://assets/audio/music/war_theme.ogg", "ambience": "res://assets/audio/ambience/city_traffic.ogg", "ambience_db": -14.0, "distant_booms": true,
        "objectives": [
            {"type": "kill_hvt", "text": "Eliminate Colonel Khaki (north-east plaza)"},
            {"type": "destroy", "tag": "sams", "text": "Destroy the mobile SAM launchers"},
            {"type": "extract", "pos": Vector3(-78, 0, -78), "text": "Extract from the north-west plaza"},
        ],
    }


static func _urban_special(L, kind: String, c: Vector3) -> void:
    var paving := Color(0.68, 0.64, 0.58)
    L.box(c + Vector3(0, 0.05, 0), Vector3(34, 0.04, 34), paving, 0.0, false)
    match kind:
        "hvt":
            L.cyl(c + Vector3(0, 0.5, -4), 4.0, 1.0, Color(0.7, 0.7, 0.68))
            L.cyl(c + Vector3(0, 1.05, -4), 3.5, 0.1, Color(0.2, 0.45, 0.6), false)
            L.cyl(c + Vector3(0, 2.0, -4), 0.5, 2.0, Color(0.7, 0.7, 0.68))
            for p in [Vector3(-10, 0, 6), Vector3(10, 0, 6), Vector3(-10, 0, -12), Vector3(10, 0, -12)]:
                L.box(c + p + Vector3(0, 0.6, 0), Vector3(3, 1.2, 3), Color(0.55, 0.5, 0.45))
                tree(L, c + p + Vector3(0, 1.2, 0))
            vehicle(L, c + Vector3(-8, 0, -2), 0.0, Color(0.7, 0.6, 0.38))
            vehicle(L, c + Vector3(9, 0, -1), 0.0, Color(0.7, 0.6, 0.38))
            L.add_enemy(c + Vector3(0, 0.1, 6), "officer", true)
            L.add_enemy(c + Vector3(-6, 0.1, 10), "gunner")
            L.add_enemy(c + Vector3(6, 0.1, 10), "rifleman")
            L.add_enemy(c + Vector3(-5, 0.1, -12), "rifleman")
            L.add_enemy(c + Vector3(7, 0.1, -12), "rocketeer")
        "samA", "samB":
            L.add_target(c, "sam", "sams", 0.6 if kind == "samA" else -0.9)
            sandbags(L, c + Vector3(-7, 0, 6), 0.3, 5.0)
            sandbags(L, c + Vector3(7, 0, -6), 0.3, 5.0)
            L.add_enemy(c + Vector3(-9, 0.1, 9), "gunner")
            L.add_enemy(c + Vector3(9, 0.1, -9), "rifleman")
            L.add_enemy(c + Vector3(10, 0.1, 8), "rocketeer")
        "exfil":
            for p in [Vector3(-12, 0, 12), Vector3(12, 0, 12), Vector3(12, 0, -12)]:
                tree(L, c + p)
            L.add_enemy(c + Vector3(-8, 0.1, 8), "rifleman")
            L.add_enemy(c + Vector3(10, 0.1, 0), "rifleman")
        "park":
            L.box(c + Vector3(0, 0.06, 0), Vector3(32, 0.04, 32), Color(0.3, 0.5, 0.22), 0.0, false)
            for p in [Vector3(-10, 0, -10), Vector3(9, 0, -12), Vector3(-12, 0, 8), Vector3(11, 0, 9), Vector3(0, 0, 0)]:
                tree(L, c + p)
            L.box(c + Vector3(5, 0.45, 2), Vector3(3, 0.9, 1), Color(0.45, 0.3, 0.2))
            L.add_pickup(c + Vector3(-4, 0, 3), "sniper")


# ====================================================== 3: TABLETOP ====

static func _tabletop(L) -> Dictionary:
    var wood := Color(0.56, 0.37, 0.22)
    var hx := 75.0
    var hz := 60.0
    L.box(Vector3(0, -1, 0), Vector3(hx * 2, 2, hz * 2), wood, 0.0, true, L.mat(wood, 0.45))
    for k in range(-5, 6):
        L.box(Vector3(0, 0.005, k * 11.0), Vector3(hx * 2, 0.01, 0.18), wood.darkened(0.3), 0.0, false)
    L.bounds(hx, hz)
    # The room around the table (far, far below / away).
    L.box(Vector3(0, -62, 0), Vector3(900, 2, 900), Color(0.75, 0.72, 0.66), 0.0, false)
    for p in [Vector3(-70, -31, -55), Vector3(70, -31, -55), Vector3(-70, -31, 55), Vector3(70, -31, 55)]:
        L.box(p, Vector3(6, 60, 6), wood.darkened(0.15), 0.0, false)
    L.box(Vector3(0, 60, -320), Vector3(900, 300, 4), Color(0.62, 0.66, 0.6), 0.0, false)
    L.box(Vector3(80, 90, -317), Vector3(140, 110, 1), Color(0.8, 0.9, 1.0), 0.0, false, L.glow_mat(Color(0.8, 0.9, 1.0), 1.4))
    L.box(Vector3(-320, 60, 0), Vector3(4, 300, 900), Color(0.58, 0.62, 0.56), 0.0, false)
    L.box(Vector3(-200, -20, -250), Vector3(160, 80, 60), Color(0.95, 0.95, 0.95), 0.0, false)   # fridge-ish counter
    L.box(Vector3(0, -30, 160), Vector3(70, 60, 8), wood.darkened(0.2), 0.0, false)          # chair back

    # Laptop
    var alu := Color(0.72, 0.73, 0.75)
    L.box(Vector3(-35, 0.6, -25), Vector3(32, 1.2, 22), alu, 0.0, true, L.mat(alu, 0.3, 0.7))
    L.box(Vector3(-35, 1.22, -28), Vector3(28, 0.05, 10), Color(0.12, 0.12, 0.13), 0.0, false)
    L.box(Vector3(-35, 1.22, -18), Vector3(9, 0.05, 6), Color(0.6, 0.61, 0.63), 0.0, false)
    L.box_rot(Vector3(-35, 10.5, -37.2), Vector3(32, 20, 0.8), alu, Vector3(deg_to_rad(-12), 0, 0), true, L.mat(alu, 0.3, 0.7))
    L.box_rot(Vector3(-35, 10.7, -36.7), Vector3(29, 17.5, 0.1), Color(0.3, 0.55, 0.9), Vector3(deg_to_rad(-12), 0, 0), false, L.glow_mat(Color(0.25, 0.5, 0.9), 1.2))
    L.box(Vector3(-9, 0.8, -30), Vector3(3.5, 1.6, 6), Color(0.15, 0.15, 0.17))   # mouse

    # Smartphone (climbable)
    L.box(Vector3(30, 0.25, 20), Vector3(9, 0.5, 18), Color(0.08, 0.08, 0.09))
    L.box(Vector3(30, 0.51, 20), Vector3(8.2, 0.02, 16.8), Color(0.2, 0.4, 0.8), 0.0, false, L.glow_mat(Color(0.2, 0.45, 0.85), 1.0))

    # Energy drinks
    var can_m = L.mat(Color(0.2, 0.85, 0.3), 0.25, 0.8)
    L.cyl(Vector3(10, 5, -20), 2.2, 10, Color.WHITE, true, Vector3.ZERO, can_m)
    L.cyl(Vector3(10, 7, -20), 2.25, 1.2, Color(0.05, 0.05, 0.05), false)
    L.cyl(Vector3(15, 5, -13), 2.2, 10, Color.WHITE, true, Vector3.ZERO, can_m)
    L.cyl(Vector3(-12, 2.2, 32), 2.2, 10, Color.WHITE, true, Vector3(0, 0.5, PI / 2), L.mat(Color(0.15, 0.3, 0.85), 0.25, 0.8))

    # Cereal box, coffee mug, controller, pencils, books, dice
    L.box(Vector3(-60, 9, 35), Vector3(12, 18, 4.5), Color(0.85, 0.2, 0.15), 0.3)
    L.box(Vector3(-60, 11, 35), Vector3(9, 6, 4.6), Color(0.95, 0.8, 0.2), 0.3, false)
    L.cyl(Vector3(55, 3.5, -35), 3.2, 7, Color(0.95, 0.95, 0.93))
    L.cyl(Vector3(55, 7.01, -35), 2.9, 0.05, Color(0.25, 0.15, 0.08), false)
    L.box(Vector3(59, 3.6, -35), Vector3(1.6, 4.0, 0.7), Color(0.95, 0.95, 0.93))
    L.box(Vector3(45, 1.2, 40), Vector3(10, 2.4, 5), Color(0.18, 0.18, 0.2))
    L.cyl(Vector3(41, 1.2, 42.5), 2.0, 2.4, Color(0.18, 0.18, 0.2))
    L.cyl(Vector3(49, 1.2, 42.5), 2.0, 2.4, Color(0.18, 0.18, 0.2))
    for b in [[Vector3(47.5, 2.5, 39), Color(0.2, 0.8, 0.3)], [Vector3(48.5, 2.5, 40), Color(0.9, 0.2, 0.2)], [Vector3(46.5, 2.5, 40), Color(0.2, 0.4, 0.9)], [Vector3(47.5, 2.5, 41), Color(0.95, 0.8, 0.2)]]:
        L.cyl(b[0], 0.35, 0.3, b[1], false)
    L.cyl(Vector3(-15, 0.4, -5), 0.4, 14, Color(0.95, 0.75, 0.15), true, Vector3(0, 0.4, PI / 2))
    L.cyl(Vector3(5, 0.4, 45), 0.4, 14, Color(0.2, 0.4, 0.8), true, Vector3(0, -0.9, PI / 2))
    L.box(Vector3(62, 1.0, 5), Vector3(14, 2, 10), Color(0.2, 0.3, 0.55), 0.1)
    L.box(Vector3(62, 3.0, 5), Vector3(13, 2, 9.5), Color(0.6, 0.15, 0.15), -0.15)
    L.box(Vector3(62, 5.0, 5), Vector3(12, 2, 9), Color(0.2, 0.45, 0.25), 0.05)
    L.box(Vector3(5, 1.5, 12), Vector3(3, 3, 3), Color(0.95, 0.95, 0.95), 0.6)
    L.box(Vector3(-25, 0.01, 10), Vector3(7, 0.02, 7), Color(0.98, 0.9, 0.3), 0.2, false)
    L.box(Vector3(-50, 0.01, -5), Vector3(7, 0.02, 7), Color(0.98, 0.5, 0.6), -0.3, false)

    # Giant toy vehicles left on the table (plus a drivable jeep)
    L.add_vehicle("jeep", Vector3(10, 0, 52), 0.0)
    L.add_enemy_vehicle("jeep", Vector3(25, 0, -28), PI)
    L.add_enemy_vehicle("tank", Vector3(-12, 0, -52), 0.0)
    L.prop("kenney_car_kit/race-future.glb", Vector3(-30, 0, 40), 0.15, Vector3(0, 0, 14.0))
    L.prop("kenney_car_kit/firetruck.glb", Vector3(-58, 0, -50), 1.2, Vector3(0, 0, 16.0))
    L.add_barrel(Vector3(-40, 0, 0))
    L.add_barrel(Vector3(36, 0, -2))
    L.add_barrel(Vector3(4, 0, -42))

    # Tan fortifications + objectives
    L.add_target(Vector3(-45, 0, 8), "booster", "boosters", 0.2)
    L.add_target(Vector3(40, 0, -8), "booster", "boosters", -0.3)
    L.add_target(Vector3(0, 0, -48), "booster", "boosters", 0.0)
    sandbags(L, Vector3(-10, 0, 8), 0.2, 5.0)
    sandbags(L, Vector3(20, 0, 5), -0.4, 5.0)
    sandbags(L, Vector3(-20, 0, -45), 0.0, 6.0)
    sandbags(L, Vector3(25, 0, -38), 0.6, 5.0)

    var troops := [
        [Vector3(-40, 0, 16), "rifleman"], [Vector3(-52, 0, 4), "gunner"], [Vector3(-38, 0, 0), "rifleman"],
        [Vector3(33, 0.6, 22), "rifleman"], [Vector3(28, 0.6, 15), "gunner"], [Vector3(46, 0, -2), "rifleman"],
        [Vector3(36, 0, -16), "rocketeer"], [Vector3(-6, 0, -52), "gunner"], [Vector3(7, 0, -54), "rifleman"],
        [Vector3(0, 0, -40), "rifleman"], [Vector3(-14, 0, 10), "rifleman"], [Vector3(18, 0, 8), "rifleman"],
        [Vector3(-20, 0, -40), "rocketeer"], [Vector3(26, 0, -42), "rifleman"], [Vector3(-60, 0, 20), "rifleman"],
        [Vector3(60, 0, -20), "gunner"], [Vector3(-8, 0, 25), "rifleman"], [Vector3(50, 0, 25), "rifleman"],
        [Vector3(-62, 0, -40), "rifleman"], [Vector3(-30, 0, -8), "rocketeer"], [Vector3(15, 0, -30), "rifleman"],
        [Vector3(62, 6.2, 5), "sniper"], [Vector3(-35, 1.3, -20), "sniper"], [Vector3(-30, 1.3, -16), "gunner"],
        [Vector3(68, 0, -50), "rifleman"],
    ]
    for t in troops:
        L.add_enemy(t[0] + Vector3(0, 0.1, 0), t[1])
    L.add_pickup(Vector3(-4, 0, 52), "ammo")
    L.add_pickup(Vector3(4, 0, 52), "grenades")
    L.add_pickup(Vector3(0, 0, 44), "armor")
    L.add_pickup(Vector3(30, 0.6, 26), "health")
    L.add_pickup(Vector3(-65, 0, 50), "lmg")
    L.add_pickup(Vector3(65, 0, 50), "drone")
    L.add_pickup(Vector3(-20, 1.25, -15), "health")
    L.add_pickup(Vector3(20, 0, -20), "ammo")
    L.add_pickup(Vector3(-65, 0, -25), "ammo")
    L.add_pickup(Vector3(55, 0, -50), "health")

    return {
        "spawn": Vector3(0, 0.5, 54), "spawn_yaw": 0.0, "drones": 2, "safe_radius": 18.0,
        "start_weapons": ["carbine", "shotgun", "launcher", "sniper"],
        "sky_top": Color(0.62, 0.58, 0.52), "sky_horizon": Color(0.74, 0.7, 0.62),
        "sun_color": Color(1.0, 0.9, 0.75), "sun_energy": 0.95, "sun_rot": Vector3(-60, 20, 0),
        "fog": 0.0, "ambient": 0.6, "exposure": 0.85,
        "music": "res://assets/audio/music/determined_pursuit.ogg", "ambience": "res://assets/audio/ambience/clock_tick.ogg", "ambience_db": -8.0,
        "objectives": [
            {"type": "destroy", "tag": "boosters", "text": "Destroy the Tan Army Wi-Fi signal boosters"},
            {"type": "kill_all", "text": "Clear the table of all Tan forces"},
        ],
    }


# ================================================ shared map helpers ====

static func clear_of(p: Vector3, avoid: Array) -> bool:
    for a in avoid:
        if Vector2(p.x - a[0].x, p.z - a[0].z).length() < a[1]:
            return false
    return true


## Scatters random models from `models` (kenney/toon paths) around the map.
static func scatter(L, rng: RandomNumberGenerator, models: Array, count: int, hx: float, hz: float, avoid: Array,
        h_min: float, h_max: float, collide := true, tint := Color(1, 1, 1, 0)) -> void:
    var placed := 0
    var guard := 0
    while placed < count and guard < count * 25:
        guard += 1
        var p := Vector3(rng.randf_range(-hx, hx), 0, rng.randf_range(-hz, hz))
        if not clear_of(p, avoid):
            continue
        var m: String = models[rng.randi() % models.size()]
        L.prop(m, p, rng.randf() * TAU, Vector3(0, rng.randf_range(h_min, h_max), 0), collide, tint)
        avoid.append([p, 2.5])
        placed += 1


## [pos, type] or [pos, type, true] for a high-value target.
static func troops(L, list: Array) -> void:
    for t in list:
        L.add_enemy(t[0] + Vector3(0, 0.1, 0), t[1], t.size() > 2 and t[2])


static func pine(L, pos: Vector3, h := 8.0) -> void:
    var kind: String = ["tree_pineTallA", "tree_pineTallB", "tree_pineRoundA", "tree_pineDefaultA", "tree_pineTallC"][absi(int(pos.x * 3.0 + pos.z)) % 5]
    if L.prop("kenney_nature/%s.glb" % kind, pos, pos.x, Vector3(0, h, 0)):
        return
    L.cyl(pos + Vector3(0, h * 0.5, 0), 1.6, h, Color(0.2, 0.35, 0.25), true, Vector3.ZERO, null, 0.1)


## Snow-capped ridge segment used as a map edge or canyon wall.
static func ridge(L, pos: Vector3, size: Vector3, rot: float, rock: Color, snow: Color) -> void:
    L.box(pos + Vector3(0, size.y * 0.5, 0), size, rock, rot)
    L.box(pos + Vector3(0, size.y + 0.4, 0), Vector3(size.x + 0.6, 0.8, size.z + 0.6), snow, rot, false)


## Interior room: floor, four tall walls (visual) and the invisible bounds.
static func room(L, hx: float, hz: float, floor_c: Color, wall_c: Color, wall_h := 80.0) -> void:
    L.box(Vector3(0, -1, 0), Vector3(hx * 2 + 40, 2, hz * 2 + 40), floor_c, 0.0, true, L.mat(floor_c, 0.5))
    L.bounds(hx, hz)
    L.box(Vector3(0, wall_h * 0.5, -hz - 12), Vector3(hx * 2 + 60, wall_h, 2), wall_c, 0.0, false)
    L.box(Vector3(0, wall_h * 0.5, hz + 12), Vector3(hx * 2 + 60, wall_h, 2), wall_c, 0.0, false)
    L.box(Vector3(-hx - 12, wall_h * 0.5, 0), Vector3(2, wall_h, hz * 2 + 60), wall_c.darkened(0.06), 0.0, false)
    L.box(Vector3(hx + 12, wall_h * 0.5, 0), Vector3(2, wall_h, hz * 2 + 60), wall_c.darkened(0.06), 0.0, false)
    # skirting boards
    for s in [-1.0, 1.0]:
        L.box(Vector3(0, 1.5, (hz + 11) * s), Vector3(hx * 2 + 60, 3, 0.6), Color(0.95, 0.95, 0.92), 0.0, false)
        L.box(Vector3((hx + 11) * s, 1.5, 0), Vector3(0.6, 3, hz * 2 + 60), Color(0.95, 0.95, 0.92), 0.0, false)


static func toy_block(L, pos: Vector3, size: float, color: Color, rot := 0.0) -> void:
    L.box(pos + Vector3(0, size * 0.5, 0), Vector3(size, size, size), color, rot)


static func lego(L, pos: Vector3, w: int, d: int, color: Color, rot := 0.0) -> void:
    var u := 1.6
    L.box(pos + Vector3(0, 0.95, 0), Vector3(w * u, 1.9, d * u), color, rot, true, L.mat(color, 0.35))
    for i in w:
        for j in d:
            var off := _rot(Vector3((i - (w - 1) * 0.5) * u, 2.05, (j - (d - 1) * 0.5) * u), rot)
            L.cyl(pos + off, 0.48, 0.3, color, false)


# ===================================================== 4: SNOW GLOBE ====

static func _snow(L) -> Dictionary:
    var rng := RandomNumberGenerator.new()
    rng.seed = 404
    var snow := Color(0.9, 0.92, 0.96)
    var rock := Color(0.45, 0.47, 0.52)
    var steel := Color(0.62, 0.64, 0.66)
    var tan_c := Color(0.74, 0.65, 0.48)
    L.box(Vector3(0, -0.5, 0), Vector3(260, 1, 260), snow, 0.0, true, L.mat(snow, 0.6))
    L.bounds(100, 100)
    for s in [-1, 1]:
        ridge(L, Vector3(0, 0, 110 * s), Vector3(240, 10, 10), 0.0, rock, snow)
        ridge(L, Vector3(110 * s, 0, 0), Vector3(10, 12, 240), 0.0, rock, snow)
    # Frozen lake (west) and snow drifts.
    L.water(Vector3(-55, 0.02, 20), Vector2(40, 30), Color(0.7, 0.85, 0.95, 0.85))
    for i in 12:
        var p := Vector3(rng.randf_range(-95, 95), -2.0, rng.randf_range(-95, 95))
        L.sphere(p, 5.0, snow.darkened(0.03), Vector3(rng.randf_range(1.4, 2.6), 0.45, rng.randf_range(1.4, 2.6)))

    # --- Green camp (south) ---
    hesco(L, Vector3(-16, 0, 72), Vector3(-5, 0, 72), Color(0.82, 0.84, 0.86))
    hesco(L, Vector3(5, 0, 72), Vector3(16, 0, 72), Color(0.82, 0.84, 0.86))
    L.prop("kenney_nature/tent_detailedClosed.glb", Vector3(-10, 0, 88), 0.3, Vector3(0, 3.0, 0))
    L.prop("kenney_nature/tent_detailedClosed.glb", Vector3(11, 0, 90), -0.4, Vector3(0, 3.0, 0))
    L.add_vehicle("jeep", Vector3(-8, 0, 78), 0.0)
    L.add_vehicle("tank", Vector3(9, 0, 79), 0.0)
    L.add_vehicle("apc", Vector3(0, 0, 94), 0.0)
    L.add_vehicle("heli", Vector3(-22, 0, 86), 0.0)
    L.add_pickup(Vector3(-4, 0, 82), "launcher")
    L.add_pickup(Vector3(4, 0, 82), "armor")
    L.add_pickup(Vector3(0, 0, 92), "grenades")

    # --- Radar station "Vanilla" (north) ---
    hesco(L, Vector3(-60, 0, -40), Vector3(-8, 0, -40), steel)
    hesco(L, Vector3(8, 0, -40), Vector3(60, 0, -40), steel)
    hesco(L, Vector3(-60, 0, -40), Vector3(-60, 0, -95), steel)
    hesco(L, Vector3(60, 0, -40), Vector3(60, 0, -95), steel)
    for p in [Vector3(-52, 0, -48), Vector3(52, 0, -48)]:
        watchtower(L, p, tan_c)
    for h in [[-30, -58, 12, 4, 8], [30, -60, 14, 5, 9], [0, -88, 18, 5, 8], [-42, -84, 10, 4, 10]]:
        L.box(Vector3(h[0], h[3] * 0.5, h[1]), Vector3(h[2], h[3], h[4]), tan_c)
        L.box(Vector3(h[0], h[3] + 0.35, h[1]), Vector3(h[2] + 0.6, 0.7, h[4] + 0.6), snow, 0.0, false)
    L.prop("kenney_city_industrial/detail-tank-large.glb", Vector3(44, 0, -82), 0.0, Vector3(0, 7.0, 0))
    L.prop("kenney_city_industrial/water-tower.glb", Vector3(-20, 0, -92), 0.0, Vector3(0, 12.0, 0))
    container(L, Vector3(14, 0, -50), 1.57, tan_c)
    container(L, Vector3(-14, 0, -70), 0.2, Color(0.55, 0.2, 0.15))
    sandbags(L, Vector3(-9, 0, -35), 0.0)
    sandbags(L, Vector3(9, 0, -35), 0.0)
    L.add_target(Vector3(-36, 0, -70), "radar", "radars", 0.4)
    L.add_target(Vector3(18, 0, -78), "radar", "radars", -0.3)
    L.add_target(Vector3(46, 0, -62), "radar", "radars", 0.9)
    L.add_enemy_vehicle("jeep", Vector3(-25, 0, -10), PI)
    L.add_enemy_vehicle("jeep", Vector3(40, 0, 0), PI)
    L.add_enemy_vehicle("tank", Vector3(0, 0, -62), PI)

    troops(L, [
        [Vector3(-20, 0, 30), "rifleman"], [Vector3(22, 0, 26), "rifleman"], [Vector3(-40, 0, 5), "gunner"],
        [Vector3(35, 0, 12), "rocketeer"], [Vector3(0, 0, 10), "rifleman"], [Vector3(-10, 0, -20), "rifleman"],
        [Vector3(15, 0, -25), "gunner"], [Vector3(-9, 0, -32), "rifleman"], [Vector3(9, 0, -32), "rifleman"],
        [Vector3(-30, 0, -66), "gunner"], [Vector3(-44, 0, -76), "rifleman"], [Vector3(20, 0, -70), "rifleman"],
        [Vector3(30, 0, -84), "rocketeer"], [Vector3(48, 0, -70), "rifleman"], [Vector3(0, 0, -76), "gunner"],
        [Vector3(-52, 5.4, -48), "sniper"], [Vector3(52, 5.4, -48), "sniper"], [Vector3(70, 0, -20), "rifleman"],
        [Vector3(-70, 0, -10), "rifleman"], [Vector3(60, 0, 40), "rifleman"],
    ])
    var avoid := [[Vector3(0, 0, 82), 26.0], [Vector3(0, 0, -68), 66.0], [Vector3(-55, 0, 20), 24.0], [Vector3(80, 0, -10), 12.0]]
    for i in 34:
        var p := Vector3(rng.randf_range(-95, 95), 0, rng.randf_range(-95, 95))
        if clear_of(p, avoid):
            pine(L, p, rng.randf_range(7.0, 12.0))
            avoid.append([p, 4.0])
    rocks(L, rng, 14, 95.0, avoid, rock)
    for b in [Vector3(-24, 0, -52), Vector3(26, 0, -48), Vector3(4, 0, -60), Vector3(-30, 0, 20)]:
        L.add_barrel(b)
    L.add_pickup(Vector3(-55, 0, 40), "sniper")
    L.add_pickup(Vector3(60, 0, 20), "health")
    L.add_pickup(Vector3(0, 0, -30), "ammo")
    L.add_pickup(Vector3(-50, 0, -60), "health")
    L.add_pickup(Vector3(30, 0, 40), "lmg")

    return {
        "spawn": Vector3(0, 0.5, 84), "spawn_yaw": 0.0, "drones": 1, "safe_radius": 22.0,
        "start_weapons": ["carbine", "shotgun"],
        "sky_top": Color(0.55, 0.66, 0.82), "sky_horizon": Color(0.88, 0.9, 0.95),
        "sun_color": Color(0.95, 0.97, 1.0), "sun_energy": 0.9, "sun_rot": Vector3(-28, 60, 0),
        "fog": 0.011, "ambient": 0.75, "exposure": 0.8, "snow": true,
        "music": "res://assets/audio/music/war_theme.ogg", "ambience": "res://assets/audio/ambience/desert_wind.ogg", "ambience_db": -6.0,
        "objectives": [
            {"type": "destroy", "tag": "radars", "text": "Destroy the Station Vanilla radar dishes"},
            {"type": "extract", "pos": Vector3(80, 0, -10), "text": "Reach the extraction helipad (east ridge)"},
        ],
    }


# ===================================================== 5: GREEN HELL ====

static func _jungle(L) -> Dictionary:
    var rng := RandomNumberGenerator.new()
    rng.seed = 505
    var moss := Color(0.24, 0.36, 0.18)
    var mud := Color(0.4, 0.3, 0.2)
    var stone := Color(0.55, 0.55, 0.48)
    L.box(Vector3(0, -0.5, 0), Vector3(240, 1, 240), moss)
    L.bounds(95, 95)
    for s in [-1, 1]:
        L.box(Vector3(0, 6, 104 * s), Vector3(230, 14, 10), moss.darkened(0.3), 0.0, false)
        L.box(Vector3(104 * s, 6, 0), Vector3(10, 14, 230), moss.darkened(0.3), 0.0, false)
    # The river (shallow - wade across) with two rope bridges.
    L.box(Vector3(0, 0.01, 5), Vector3(200, 0.02, 18), mud, 0.0, false)
    L.water(Vector3(0, 0.06, 5), Vector2(200, 14), Color(0.25, 0.4, 0.3, 0.85))
    L.prop("kenney_nature/bridge_wood.glb", Vector3(-30, 0, 5), PI / 2, Vector3(0, 0, 18.0), false)
    L.prop("kenney_nature/bridge_wood.glb", Vector3(40, 0, 5), PI / 2, Vector3(0, 0, 18.0), false)
    for p in [Vector3(-70, 0, 8), Vector3(10, 0, 2), Vector3(70, 0, 6)]:
        L.prop("kenney_nature/lily_large.glb", p, 0.0, Vector3(3, 0, 3), false)
    L.prop("kenney_nature/canoe.glb", Vector3(-12, 0.05, 9), 0.4, Vector3(0, 0, 6.0), false)

    # --- Landing zone (south) ---
    L.add_vehicle("jeep", Vector3(6, 0, 78), 0.0)
    L.add_vehicle("apc", Vector3(-9, 0, 77), 0.0)
    L.add_vehicle("heli", Vector3(14, 0, 90), 0.0)
    L.add_pickup(Vector3(-4, 0, 80), "shotgun")
    L.add_pickup(Vector3(0, 0, 76), "grenades")
    L.add_pickup(Vector3(4, 0, 82), "armor")
    L.prop("kenney_nature/campfire_stones.glb", Vector3(-6, 0, 88), 0.0, Vector3(0, 0.8, 0), false)

    # --- Ancient temple + POW camp (north) ---
    L.box(Vector3(0, 1.5, -60), Vector3(36, 3, 30), stone)
    L.box(Vector3(0, 4.5, -64), Vector3(24, 3, 20), stone.darkened(0.05))
    L.box(Vector3(0, 7.5, -66), Vector3(12, 3, 12), stone.darkened(0.1))
    L.box_rot(Vector3(0, 1.5, -42.5), Vector3(10, 0.5, 9.5), stone, Vector3(deg_to_rad(18), 0, 0))
    L.box_rot(Vector3(0, 4.4, -51.5), Vector3(8, 0.5, 6.6), stone, Vector3(deg_to_rad(27), 0, 0))
    for p in [Vector3(-16, 0, -44), Vector3(16, 0, -44), Vector3(-16, 0, -76), Vector3(16, 0, -76)]:
        L.prop("kenney_nature/statue_column.glb", p, 0.0, Vector3(0, 7.0, 0))
    L.prop("kenney_nature/statue_head.glb", Vector3(-30, 0, -70), 0.5, Vector3(0, 7.0, 0))
    L.prop("kenney_nature/statue_obelisk.glb", Vector3(30, 0, -50), 0.0, Vector3(0, 10.0, 0))
    # bamboo cages with green POWs
    var cages := [Vector3(-45, 0, -30), Vector3(45, 0, -38), Vector3(-28, 0, -88), Vector3(30, 0, -86)]
    for c in cages:
        for k in 8:
            var a := k * TAU / 8.0
            if k == 2:
                continue                                  # the door's been kicked in
            L.cyl(c + Vector3(cos(a) * 2.6, 1.4, sin(a) * 2.6), 0.12, 2.8, Color(0.6, 0.55, 0.3), true)
        L.box(c + Vector3(0, 2.85, 0), Vector3(5.6, 0.15, 5.6), Color(0.55, 0.45, 0.25), 0.0, false)
        L.add_pickup(c, "pow")
        L.prop("kenney_nature/tent_smallOpen.glb", c + Vector3(6, 0, 2), 0.7, Vector3(0, 2.6, 0))
    L.add_enemy_vehicle("jeep", Vector3(-55, 0, -55), 0.0)
    L.add_enemy_vehicle("jeep", Vector3(50, 0, 30), PI)

    troops(L, [
        [Vector3(-20, 0, 40), "rifleman"], [Vector3(25, 0, 35), "rifleman"], [Vector3(-50, 0, 30), "gunner"],
        [Vector3(55, 0, 45), "rifleman"], [Vector3(0, 0, 20), "rocketeer"], [Vector3(-30, 0, -10), "rifleman"],
        [Vector3(40, 0, -10), "rifleman"], [Vector3(-45, 0, -24), "gunner"], [Vector3(45, 0, -30), "rifleman"],
        [Vector3(-26, 0, -80), "rifleman"], [Vector3(30, 0, -78), "gunner"], [Vector3(0, 9.1, -66), "sniper"],
        [Vector3(-8, 3.1, -48), "rifleman"], [Vector3(8, 3.1, -48), "rifleman"], [Vector3(0, 0, -36), "gunner"],
        [Vector3(-60, 0, -70), "rocketeer"], [Vector3(60, 0, -66), "rifleman"], [Vector3(0, 0, -88), "officer"],
        [Vector3(-70, 0, 0), "rifleman"], [Vector3(75, 0, -15), "rifleman"],
    ])
    var avoid := [[Vector3(0, 0, 82), 22.0], [Vector3(0, 0, -62), 26.0], [Vector3(0, 0, 5), 10.0], [Vector3(-75, 0, -75), 12.0]]
    for c in cages:
        avoid.append([c, 9.0])
    scatter(L, rng, ["kenney_nature/tree_palmTall.glb", "kenney_nature/tree_palmBend.glb", "kenney_nature/tree_fat_darkh.glb",
        "kenney_nature/tree_detailed_dark.glb", "kenney_nature/tree_palmDetailedTall.glb", "kenney_nature/tree_oak_dark.glb"],
        60, 92, 92, avoid, 7.0, 12.0)
    scatter(L, rng, ["kenney_nature/plant_bushLarge.glb", "kenney_nature/plant_bushDetailed.glb", "kenney_nature/plant_flatTall.glb",
        "kenney_nature/mushroom_redGroup.glb", "kenney_nature/log_large.glb", "kenney_nature/stump_oldTall.glb"],
        50, 92, 92, avoid, 1.0, 2.2, false)
    for b in [Vector3(-40, 0, -46), Vector3(36, 0, -60), Vector3(-6, 0, -30)]:
        L.add_barrel(b)
    L.add_pickup(Vector3(-60, 0, 50), "health")
    L.add_pickup(Vector3(60, 0, -5), "ammo")
    L.add_pickup(Vector3(-20, 0, -40), "health")
    L.add_pickup(Vector3(20, 0, -20), "lmg")

    return {
        "spawn": Vector3(0, 0.5, 84), "spawn_yaw": 0.0, "drones": 1, "safe_radius": 20.0,
        "start_weapons": ["carbine", "shotgun"],
        "sky_top": Color(0.4, 0.58, 0.55), "sky_horizon": Color(0.62, 0.72, 0.58),
        "sun_color": Color(1.0, 0.95, 0.75), "sun_energy": 1.0, "sun_rot": Vector3(-62, 15, 0),
        "fog": 0.014, "ambient": 0.65, "exposure": 0.9,
        "music": "res://assets/audio/music/determined_pursuit.ogg", "ambience": "res://assets/audio/ambience/desert_wind.ogg", "ambience_db": -18.0, "distant_booms": true,
        "objectives": [
            {"type": "collect", "kind": "pow", "text": "Rescue the captured Green POWs"},
            {"type": "extract", "pos": Vector3(-75, 0, -75), "text": "Get the POWs to the helipad (north-west)"},
        ],
    }


# ======================================================= 6: BATH TIME ====

static func _bathroom(L) -> Dictionary:
    var tile := Color(0.88, 0.9, 0.92)
    var hx := 72.0
    var hz := 58.0
    room(L, hx, hz, tile, Color(0.62, 0.78, 0.82))
    for k in range(-7, 8):
        L.box(Vector3(k * 10.0, 0.005, 0), Vector3(0.25, 0.01, hz * 2 + 30), tile.darkened(0.25), 0.0, false)
    for k in range(-6, 7):
        L.box(Vector3(0, 0.005, k * 10.0), Vector3(hx * 2 + 30, 0.01, 0.25), tile.darkened(0.25), 0.0, false)
    # The bathtub: a porcelain cliff along the north wall, full of water.
    var porcelain := Color(0.97, 0.97, 0.95)
    L.box(Vector3(0, 11, -52), Vector3(110, 22, 16), porcelain, 0.0, true, L.mat(porcelain, 0.2))
    L.box(Vector3(0, 22.02, -52), Vector3(104, 0.04, 12), Color(0.5, 0.75, 0.9), 0.0, false, L.glow_mat(Color(0.45, 0.7, 0.9), 0.25))
    L.cyl(Vector3(30, 26, -59), 0.8, 10, Color(0.75, 0.76, 0.78), false, Vector3(PI / 2, 0, 0))
    # Toilet (east)
    L.cyl(Vector3(60, 7, -10), 9, 14, porcelain, true, Vector3.ZERO, L.mat(porcelain, 0.2), 7.0)
    L.box(Vector3(60, 15, -24), Vector3(20, 30, 8), porcelain, 0.0, true, L.mat(porcelain, 0.2))
    # Sink cabinet (west)
    L.box(Vector3(-62, 14, -10), Vector3(22, 28, 30), Color(0.55, 0.38, 0.25))
    L.box(Vector3(-50.9, 14, -10), Vector3(0.2, 24, 1.2), Color(0.85, 0.75, 0.3), 0.0, false)
    # Bath mat, puddles, towel
    L.box(Vector3(0, 0.05, -30), Vector3(50, 0.1, 22), Color(0.3, 0.5, 0.85), 0.0, false)
    for p in [[Vector3(-30, 0.03, 20), Vector2(16, 10)], [Vector3(25, 0.03, -15), Vector2(12, 14)], [Vector3(-10, 0.03, 0), Vector2(8, 6)]]:
        L.water(p[0], p[1], Color(0.6, 0.8, 0.95, 0.6))
    L.box_rot(Vector3(-25, 1.2, 35), Vector3(30, 2.4, 14), Color(0.9, 0.45, 0.5), Vector3(0, 0.3, 0.05))
    # Rubber ducks (cover), soap, shampoo, toothpaste
    for d in [[Vector3(-30, 0, -10), 0.4], [Vector3(15, 0, 15), -0.8], [Vector3(40, 0, 35), 2.0]]:
        var p: Vector3 = d[0]
        L.cyl(p + Vector3(0, 2.6, 0), 3.4, 5.2, Color(1.0, 0.85, 0.1), true)
        L.sphere(p + Vector3(0, 3.2, 0), 3.8, Color(1.0, 0.85, 0.1), Vector3(1.2, 0.85, 1.0))
        L.sphere(p + _rot(Vector3(2.2, 7.0, 0), d[1]), 2.4, Color(1.0, 0.85, 0.1))
        L.box(p + _rot(Vector3(4.6, 6.6, 0), d[1]), Vector3(1.6, 0.8, 1.6), Color(1.0, 0.45, 0.1), d[1], false)
    L.box(Vector3(10, 1.6, -20), Vector3(9, 3.2, 6), Color(0.95, 0.6, 0.75), 0.4, true, L.mat(Color(0.95, 0.6, 0.75), 0.15))
    L.cyl(Vector3(-40, 9, 25), 3.5, 18, Color(0.2, 0.55, 0.85), true, Vector3.ZERO, L.mat(Color(0.2, 0.55, 0.85), 0.2))
    L.cyl(Vector3(-40, 19, 25), 1.6, 2.0, Color(0.95, 0.95, 0.95))
    L.cyl(Vector3(30, 1.4, 5), 1.4, 22, Color(0.95, 0.95, 0.97), true, Vector3(0, 0.6, PI / 2))
    L.box(Vector3(37, 1.4, 0.5), Vector3(4, 1.6, 2), Color(0.2, 0.5, 0.9), 0.6, false)

    # Admiral Ecru's fleet: fuel depots and sandbag docks along the tub.
    L.add_target(Vector3(-35, 0, -38), "fuel", "fuel", 0.0)
    L.add_target(Vector3(0, 0, -40), "fuel", "fuel", 0.3)
    L.add_target(Vector3(38, 0, -36), "fuel", "fuel", -0.2)
    sandbags(L, Vector3(-28, 0, -30), 0.0, 6.0)
    sandbags(L, Vector3(8, 0, -30), 0.2, 6.0)
    sandbags(L, Vector3(32, 0, -26), -0.3, 6.0)
    L.add_vehicle("jeep", Vector3(8, 0, 44), 0.0)
    L.add_enemy_vehicle("jeep", Vector3(-45, 0, 0), PI / 2)
    L.add_enemy_vehicle("tank", Vector3(20, 0, -20), PI)
    troops(L, [
        [Vector3(48, 0, -36), "officer", true],
        [Vector3(-36, 0, -30), "rifleman"], [Vector3(-30, 0, -44), "gunner"], [Vector3(-4, 0, -34), "rifleman"],
        [Vector3(6, 0, -44), "rocketeer"], [Vector3(30, 0, -30), "rifleman"], [Vector3(44, 0, -44), "gunner"],
        [Vector3(52, 0, -30), "rifleman"], [Vector3(-20, 0, 0), "rifleman"], [Vector3(20, 0, 0), "rifleman"],
        [Vector3(-50, 0, 20), "rocketeer"], [Vector3(50, 0, 15), "rifleman"], [Vector3(0, 0, -10), "gunner"],
        [Vector3(-40, 20.1, 25), "sniper"], [Vector3(-55, 28.2, -10), "sniper"], [Vector3(-62, 0, 30), "rifleman"],
        [Vector3(62, 0, 40), "rifleman"], [Vector3(35, 0, 18), "rifleman"],
    ])
    L.box(Vector3(-55, 28.05, -10), Vector3(8, 0.1, 8), Color(0.55, 0.38, 0.25))
    for b in [Vector3(-20, 0, -36), Vector3(20, 0, -40), Vector3(-5, 0, 10)]:
        L.add_barrel(b)
    L.add_pickup(Vector3(-4, 0, 46), "launcher")
    L.add_pickup(Vector3(4, 0, 50), "ammo")
    L.add_pickup(Vector3(0, 0, 40), "grenades")
    L.add_pickup(Vector3(-60, 0, 45), "health")
    L.add_pickup(Vector3(60, 0, 10), "armor")
    L.add_pickup(Vector3(-45, 0, -20), "ammo")
    L.add_pickup(Vector3(25, 0, -5), "drone")
    L.lamp(Vector3(0, 70, 0), Color(1.0, 0.97, 0.9), 160.0, 1.2, false)

    return {
        "spawn": Vector3(0, 0.5, 48), "spawn_yaw": 0.0, "drones": 2, "safe_radius": 16.0,
        "start_weapons": ["carbine", "shotgun", "launcher"],
        "sky_top": Color(0.75, 0.82, 0.85), "sky_horizon": Color(0.82, 0.86, 0.88),
        "sun_color": Color(1.0, 0.98, 0.95), "sun_energy": 0.8, "sun_rot": Vector3(-70, 10, 0),
        "fog": 0.0, "ambient": 0.7, "exposure": 0.85,
        "music": "res://assets/audio/music/determined_pursuit.ogg", "ambience": "res://assets/audio/ambience/clock_tick.ogg", "ambience_db": -12.0,
        "objectives": [
            {"type": "destroy", "tag": "fuel", "text": "Destroy the Tan fleet's fuel depots"},
            {"type": "kill_hvt", "text": "Sink Admiral Ecru (east end of the tub)"},
        ],
    }


# ====================================================== 7: BEACHHEAD ====

static func _beach(L) -> Dictionary:
    var rng := RandomNumberGenerator.new()
    rng.seed = 707
    var sand := Color(0.76, 0.64, 0.42)
    var grass := Color(0.38, 0.5, 0.26)
    var concrete := Color(0.62, 0.6, 0.55)
    L.box(Vector3(0, -0.5, 0), Vector3(260, 1, 260), grass)
    L.box(Vector3(0, 0.01, 55), Vector3(220, 0.02, 90), sand, 0.0, false)
    L.bounds(100, 100)
    # Surf + open sea beyond the south edge
    L.water(Vector3(0, 0.04, 95), Vector2(220, 20), Color(0.3, 0.6, 0.7, 0.7))
    L.box(Vector3(0, -0.3, 160), Vector3(600, 0.1, 110), Color(0.15, 0.4, 0.55), 0.0, false, L.mat(Color(0.15, 0.4, 0.55), 0.1, 0.3))
    for s in [-1, 1]:
        L.box(Vector3(110 * s, 4, -20), Vector3(10, 10, 200), grass.darkened(0.2), 0.0, false)
    L.box(Vector3(0, 4, -110), Vector3(230, 10, 10), grass.darkened(0.2), 0.0, false)
    # Steel hedgehogs on the beach (cover)
    for i in 16:
        var p := Vector3(-90 + i * 12 + rng.randf_range(-3, 3), 0, rng.randf_range(40, 70))
        if absf(p.x) < 14 and p.z > 60:
            continue
        for r in [0.0, PI / 2, PI / 4]:
            L.box_rot(p + Vector3(0, 1.0, 0), Vector3(3.2, 0.35, 0.35), Color(0.3, 0.28, 0.26), Vector3(0.6, r, 0.6), true)
    # Dune line with bunkers
    for i in 9:
        L.sphere(Vector3(-96 + i * 24, -3.5, 30), 6.0, sand.darkened(0.05), Vector3(2.2, 0.75, 1.0))
    for b in [[Vector3(-60, 0, 18), 0.1], [Vector3(-20, 0, 14), 0.0], [Vector3(25, 0, 16), -0.1], [Vector3(65, 0, 20), 0.15]]:
        L.add_target(b[0], "bunker", "bunkers", b[1])
    # Inland: Tan HQ village + barbed fences
    var houses := [[-50, -40, 10, 5, 9], [-20, -60, 12, 5, 10], [30, -50, 10, 6, 10], [55, -70, 12, 5, 8], [0, -85, 16, 6, 10], [-60, -80, 10, 5, 10]]
    for h in houses:
        L.box(Vector3(h[0], h[3] * 0.5, h[1]), Vector3(h[2], h[3], h[4]), concrete)
        L.box_rot(Vector3(h[0], h[3] + 1.2, h[1]), Vector3(h[2] + 0.5, 0.4, h[4] * 0.62), Color(0.6, 0.25, 0.2), Vector3(deg_to_rad(28), 0, 0), false)
    for p in [Vector3(-80, 0, 40), Vector3(-45, 0, 35), Vector3(40, 0, 38), Vector3(85, 0, 45), Vector3(-75, 0, -5), Vector3(80, 0, -10)]:
        palm(L, p)
    sandbags(L, Vector3(-40, 0, 5), 0.0, 6.0)
    sandbags(L, Vector3(5, 0, 2), 0.0, 6.0)
    sandbags(L, Vector3(45, 0, 5), 0.0, 6.0)
    for p in [Vector3(-75, 0, 10), Vector3(75, 0, 12)]:
        watchtower(L, p, Color(0.7, 0.6, 0.42))
    L.add_vehicle("tank", Vector3(-8, 0, 80), 0.0)
    L.add_vehicle("jeep", Vector3(10, 0, 82), 0.0)
    L.add_vehicle("apc", Vector3(20, 0, 80), 0.0)
    L.add_vehicle("heli", Vector3(-22, 0, 84), 0.0)
    L.add_enemy_vehicle("tank", Vector3(-30, 0, -20), PI)
    L.add_enemy_vehicle("tank", Vector3(35, 0, -25), PI)
    L.add_enemy_vehicle("jeep", Vector3(0, 0, -40), PI)

    troops(L, [
        [Vector3(0, 0, -78), "officer", true],
        [Vector3(-60, 0, 10), "gunner"], [Vector3(-20, 0, 6), "gunner"], [Vector3(25, 0, 8), "gunner"], [Vector3(65, 0, 12), "gunner"],
        [Vector3(-40, 0, 0), "rifleman"], [Vector3(5, 0, -3), "rocketeer"], [Vector3(45, 0, 0), "rifleman"],
        [Vector3(-75, 5.4, 10), "sniper"], [Vector3(75, 5.4, 12), "sniper"], [Vector3(-50, 0, -30), "rifleman"],
        [Vector3(-20, 0, -50), "rifleman"], [Vector3(30, 0, -40), "rocketeer"], [Vector3(55, 0, -60), "rifleman"],
        [Vector3(-8, 0, -80), "gunner"], [Vector3(10, 0, -82), "rifleman"], [Vector3(-60, 0, -70), "rifleman"],
        [Vector3(70, 0, -40), "rifleman"], [Vector3(-85, 0, 30), "rifleman"], [Vector3(85, 0, 30), "rifleman"],
    ])
    var avoid := [[Vector3(0, 0, 82), 20.0], [Vector3(0, 0, 55), 12.0], [Vector3(0, 0, -55), 60.0]]
    scatter(L, rng, ["kenney_nature/plant_bushLarge.glb", "kenney_nature/grass_large.glb", "kenney_nature/rock_smallFlatA.glb"], 26, 95, 30, avoid, 0.8, 1.6, false)
    for b in [Vector3(-10, 0, -10), Vector3(20, 0, -60), Vector3(-45, 0, -45)]:
        L.add_barrel(b)
    L.add_pickup(Vector3(-4, 0, 86), "launcher")
    L.add_pickup(Vector3(4, 0, 86), "armor")
    L.add_pickup(Vector3(-30, 0, 45), "grenades")
    L.add_pickup(Vector3(40, 0, 50), "health")
    L.add_pickup(Vector3(-70, 0, -30), "ammo")
    L.add_pickup(Vector3(60, 0, -20), "health")
    L.add_pickup(Vector3(0, 0, 30), "ammo")

    return {
        "spawn": Vector3(0, 0.5, 84), "spawn_yaw": 0.0, "drones": 2, "safe_radius": 20.0,
        "start_weapons": ["carbine", "shotgun", "launcher"],
        "sky_top": Color(0.35, 0.58, 0.88), "sky_horizon": Color(0.8, 0.86, 0.9),
        "sun_color": Color(1.0, 0.95, 0.85), "sun_energy": 1.05, "sun_rot": Vector3(-40, 160, 0),
        "fog": 0.004, "ambient": 0.7, "exposure": 0.8,
        "music": "res://assets/audio/music/battle_theme_a.ogg", "ambience": "res://assets/audio/ambience/desert_wind.ogg", "ambience_db": -12.0, "distant_booms": true,
        "objectives": [
            {"type": "destroy", "tag": "bunkers", "text": "Knock out the bunkers on the dune line"},
            {"type": "kill_hvt", "text": "Eliminate Major Fawn in the village HQ"},
        ],
    }


# ======================================================== 8: SANDBOX ====

static func _sandbox(L) -> Dictionary:
    var rng := RandomNumberGenerator.new()
    rng.seed = 808
    var lawn := Color(0.3, 0.52, 0.2)
    var sand := Color(0.9, 0.8, 0.55)
    var plank := Color(0.62, 0.45, 0.28)
    L.box(Vector3(0, -0.5, 0), Vector3(240, 1, 240), lawn)
    L.bounds(85, 85)
    # Backyard fence (giant)
    for s in [-1, 1]:
        L.box(Vector3(0, 20, 94 * s), Vector3(220, 40, 3), Color(0.8, 0.72, 0.6), 0.0, false)
        L.box(Vector3(94 * s, 20, 0), Vector3(3, 40, 220), Color(0.8, 0.72, 0.6), 0.0, false)
    # The sandbox: wooden walls with gaps, sand floor, sand castle fort
    L.box(Vector3(0, 0.02, -20), Vector3(70, 0.04, 60), sand, 0.0, false)
    L.wall(Vector3(-35, 0, -50), Vector3(35, 0, -50), 2.4, 2.0, plank)
    L.wall(Vector3(-35, 0, 10), Vector3(-8, 0, 10), 2.4, 2.0, plank)
    L.wall(Vector3(8, 0, 10), Vector3(35, 0, 10), 2.4, 2.0, plank)
    L.wall(Vector3(-35, 0, -50), Vector3(-35, 0, -28), 2.4, 2.0, plank)
    L.wall(Vector3(-35, 0, -14), Vector3(-35, 0, 10), 2.4, 2.0, plank)
    L.wall(Vector3(35, 0, -50), Vector3(35, 0, -26), 2.4, 2.0, plank)
    L.wall(Vector3(35, 0, -12), Vector3(35, 0, 10), 2.4, 2.0, plank)
    # sand castle
    for t in [Vector3(-8, 0, -34), Vector3(8, 0, -34), Vector3(-8, 0, -22), Vector3(8, 0, -22)]:
        L.cyl(t + Vector3(0, 3.5, 0), 2.6, 7.0, sand.darkened(0.08), true, Vector3.ZERO, null, 2.2)
    L.box(Vector3(0, 2, -34), Vector3(14, 4, 1.4), sand.darkened(0.05))
    L.box(Vector3(-8, 2, -28), Vector3(1.4, 4, 10), sand.darkened(0.05))
    L.box(Vector3(8, 2, -28), Vector3(1.4, 4, 10), sand.darkened(0.05))
    L.cyl(Vector3(-22, 4, -40), 4.5, 8, Color(0.9, 0.2, 0.2), true, Vector3.ZERO, L.mat(Color(0.9, 0.2, 0.2), 0.3), 5.5)   # bucket
    L.box_rot(Vector3(22, 0.4, -10), Vector3(6, 0.5, 18), Color(0.2, 0.45, 0.9), Vector3(0, 0.6, 0))                      # shovel
    # Garden: hose, gnome, flower pots, ball, doghouse
    for i in 8:
        L.cyl(Vector3(-70 + i * 9.0, 0.8, 50 + sin(i * 0.9) * 6.0), 0.8, 9.6, Color(0.1, 0.55, 0.2), true, Vector3(0, 0.3 * sin(i), PI / 2))
    L.cyl(Vector3(55, 5, 30), 4, 10, Color(0.2, 0.3, 0.75))
    L.sphere(Vector3(55, 12, 30), 3.5, Color(0.95, 0.85, 0.75))
    L.cyl(Vector3(55, 19, 30), 0.5, 10, Color(0.85, 0.15, 0.15), false, Vector3.ZERO, null, 3.6)
    for p in [Vector3(-60, 0, -10), Vector3(-65, 0, -30), Vector3(65, 0, -55)]:
        L.cyl(p + Vector3(0, 4, 0), 5, 8, Color(0.75, 0.4, 0.25), true, Vector3.ZERO, null, 6.0)
        L.prop("kenney_nature/flower_redA.glb", p + Vector3(0, 8, 0), 0.0, Vector3(0, 7, 0), false)
    L.cyl(Vector3(40, 6, 55), 4.2, 8.4, Color.WHITE, true)
    L.sphere(Vector3(40, 6, 55), 6.05, Color(0.95, 0.95, 0.95))
    L.box(Vector3(-62, 6, -70), Vector3(18, 12, 14), Color(0.65, 0.3, 0.2))
    L.box(Vector3(-62, 3, -62.9), Vector3(6, 6, 0.2), Color(0.1, 0.08, 0.06), 0.0, false)
    L.box_rot(Vector3(-62, 13.5, -70), Vector3(20, 0.8, 16), Color(0.3, 0.3, 0.32), Vector3(0, 0, 0.3), false)
    L.prop("kenney_nature/tree_oak.glb", Vector3(70, 0, -70), 0.3, Vector3(0, 40, 0))
    L.cyl(Vector3(70, 6, -70), 3.5, 12, Color(0.4, 0.3, 0.2))

    for p in [Vector3(-14, 0, -40), Vector3(24, 0, -44), Vector3(0, 0, -28)]:
        L.add_pickup(p, "intel")
    L.add_vehicle("jeep", Vector3(8, 0, 70), 0.0)
    L.add_enemy_vehicle("jeep", Vector3(-50, 0, 20), PI)
    L.add_enemy_vehicle("tank", Vector3(50, 0, -30), PI)
    troops(L, [
        [Vector3(-10, 0, -38), "rifleman"], [Vector3(10, 0, -40), "gunner"], [Vector3(0, 0, -18), "rifleman"],
        [Vector3(-20, 0, -20), "rifleman"], [Vector3(20, 0, -24), "rocketeer"], [Vector3(-8, 7.1, -34), "sniper"],
        [Vector3(8, 7.1, -22), "sniper"], [Vector3(-30, 0, 0), "rifleman"], [Vector3(30, 0, 2), "gunner"],
        [Vector3(0, 0, 14), "rifleman"], [Vector3(-55, 0, 30), "rifleman"], [Vector3(60, 0, 10), "rocketeer"],
        [Vector3(-50, 0, -45), "rifleman"], [Vector3(55, 0, -60), "rifleman"], [Vector3(-70, 0, -50), "gunner"],
        [Vector3(40, 0, 40), "rifleman"], [Vector3(-30, 0, 45), "rifleman"],
    ])
    var avoid := [[Vector3(0, 0, 72), 18.0], [Vector3(0, 0, -20), 45.0], [Vector3(-62, 0, -70), 16.0], [Vector3(55, 0, 30), 8.0]]
    scatter(L, rng, ["kenney_nature/grass_large.glb", "kenney_nature/grass_leafsLarge.glb", "kenney_nature/flower_yellowA.glb",
        "kenney_nature/flower_purpleA.glb", "kenney_nature/mushroom_tanGroup.glb"], 40, 82, 82, avoid, 2.0, 5.0, false)
    scatter(L, rng, ["kenney_nature/stone_largeA.glb", "kenney_nature/rock_largeB.glb"], 10, 80, 80, avoid, 2.0, 3.5)
    L.add_pickup(Vector3(-4, 0, 74), "launcher")
    L.add_pickup(Vector3(4, 0, 78), "ammo")
    L.add_pickup(Vector3(-40, 0, 20), "health")
    L.add_pickup(Vector3(45, 0, -10), "grenades")
    L.add_pickup(Vector3(-60, 0, -50), "armor")
    L.add_pickup(Vector3(20, 0, 30), "sniper")

    return {
        "spawn": Vector3(0, 0.5, 74), "spawn_yaw": 0.0, "drones": 2, "safe_radius": 18.0,
        "start_weapons": ["carbine", "shotgun"],
        "sky_top": Color(0.3, 0.55, 0.92), "sky_horizon": Color(0.75, 0.85, 0.95),
        "sun_color": Color(1.0, 0.95, 0.82), "sun_energy": 1.2, "sun_rot": Vector3(-55, -30, 0),
        "fog": 0.0, "ambient": 0.75, "exposure": 0.85,
        "music": "res://assets/audio/music/battle_theme_a.ogg", "ambience": "res://assets/audio/ambience/desert_wind.ogg", "ambience_db": -20.0,
        "objectives": [
            {"type": "collect", "kind": "intel", "text": "Recover the Tan battle plans from the sandbox"},
            {"type": "extract", "pos": Vector3(-62, 0, -55), "text": "Extract at the doghouse"},
        ],
    }


# ==================================================== 9: NIGHT SHIFT ====

static func _port(L) -> Dictionary:
    var rng := RandomNumberGenerator.new()
    rng.seed = 909
    var concrete := Color(0.4, 0.4, 0.42)
    L.box(Vector3(0, -0.5, 0), Vector3(240, 1, 240), concrete)
    L.bounds(100, 95)
    L.box(Vector3(0, -0.3, -170), Vector3(600, 0.1, 140), Color(0.03, 0.06, 0.1), 0.0, false, L.mat(Color(0.03, 0.06, 0.1), 0.05, 0.4))
    L.box(Vector3(0, 0.3, -98), Vector3(220, 0.6, 3), Color(0.85, 0.7, 0.15), 0.0, false)
    for s in [-1, 1]:
        L.box(Vector3(108 * s, 4, 0), Vector3(8, 8, 220), concrete.darkened(0.3), 0.0, false)
    L.box(Vector3(0, 4, 104), Vector3(220, 8, 8), concrete.darkened(0.3), 0.0, false)
    for k in range(-9, 10):
        L.box(Vector3(k * 10.0, 0.01, 0), Vector3(0.25, 0.02, 190), Color(0.7, 0.65, 0.3), 0.0, false)
    # Container stacks in rows
    var cols := [Color(0.6, 0.2, 0.15), Color(0.15, 0.35, 0.55), Color(0.2, 0.45, 0.25), Color(0.7, 0.5, 0.15), Color(0.45, 0.45, 0.5)]
    var placed := 0
    for row in 5:
        for k in 8:
            var x := -84.0 + k * 24.0 + (6.0 if row % 2 == 1 else 0.0)
            var z := 40.0 - row * 22.0
            if absf(x) < 10 and z > 30:
                continue
            if rng.randf() < 0.3:
                continue
            var c: Color = cols[(row * 3 + k) % cols.size()]
            container(L, Vector3(x, 0, z), PI / 2, c)
            container(L, Vector3(x, 0, z + 3.0), PI / 2, cols[(row + k) % cols.size()])
            if rng.randf() < 0.5:
                container(L, Vector3(x, 2.6, z), PI / 2, cols[(row + k * 2) % cols.size()])
            placed += 1
    # Gantry cranes on the quay
    for x in [-60.0, 0.0, 60.0]:
        for dz in [-6.0, 6.0]:
            for dx in [-8.0, 8.0]:
                L.box(Vector3(x + dx, 12, -86 + dz), Vector3(1.4, 24, 1.4), Color(0.85, 0.55, 0.1))
        L.box(Vector3(x, 24.5, -86), Vector3(18, 2, 14), Color(0.85, 0.55, 0.1))
        L.box(Vector3(x, 24.5, -100), Vector3(4, 1.6, 30), Color(0.85, 0.55, 0.1), 0.0, false)
        L.lamp(Vector3(x, 22.5, -86), Color(1.0, 0.85, 0.6), 30.0, 3.0)
    # Light poles
    for p in [Vector3(-20, 0, 70), Vector3(20, 0, 70), Vector3(-60, 0, 30), Vector3(60, 0, 30), Vector3(0, 0, 10),
            Vector3(-40, 0, -20), Vector3(40, 0, -20), Vector3(-80, 0, -60), Vector3(80, 0, -60), Vector3(0, 0, -50)]:
        L.cyl(p + Vector3(0, 5, 0), 0.2, 10, Color(0.3, 0.3, 0.32))
        L.lamp(p + Vector3(0, 10.2, 0), Color(1.0, 0.78, 0.45), 26.0, 2.6)
    # Fuel depots + tank farm
    L.add_target(Vector3(-70, 0, -72), "fuel", "fuel", 0.0)
    L.add_target(Vector3(10, 0, -72), "fuel", "fuel", 0.2)
    L.add_target(Vector3(78, 0, -40), "fuel", "fuel", -0.4)
    for p in [Vector3(-82, 0, -78), Vector3(88, 0, -30), Vector3(20, 0, -78)]:
        L.prop("kenney_city_industrial/detail-tank.glb", p, 0.0, Vector3(0, 6.0, 0))
    L.add_vehicle("jeep", Vector3(-8, 0, 80), 0.0)
    L.add_vehicle("tank", Vector3(8, 0, 80), 0.0)
    L.add_vehicle("apc", Vector3(-18, 0, 84), 0.0)
    L.add_vehicle("heli", Vector3(20, 0, 86), 0.0)
    L.add_enemy_vehicle("jeep", Vector3(-30, 0, 20), PI / 2)
    L.add_enemy_vehicle("jeep", Vector3(40, 0, -50), -PI / 2)
    L.add_enemy_vehicle("tank", Vector3(-10, 0, -60), PI)
    troops(L, [
        [Vector3(-12, 0, 52), "rifleman"], [Vector3(14, 0, 50), "rifleman"], [Vector3(-48, 0, 30), "gunner"],
        [Vector3(48, 0, 30), "rifleman"], [Vector3(0, 0, 8), "rocketeer"], [Vector3(-60, 0, 8), "rifleman"],
        [Vector3(60, 0, 8), "rifleman"], [Vector3(-30, 0, -14), "gunner"], [Vector3(30, 0, -14), "rifleman"],
        [Vector3(-70, 0, -60), "rifleman"], [Vector3(-60, 0, -80), "gunner"], [Vector3(12, 0, -60), "rifleman"],
        [Vector3(0, 0, -82), "rocketeer"], [Vector3(70, 0, -50), "gunner"], [Vector3(85, 0, -70), "rifleman"],
        [Vector3(-60, 25.6, -86), "sniper"], [Vector3(60, 25.6, -86), "sniper"], [Vector3(-90, 0, 40), "rifleman"],
        [Vector3(90, 0, 50), "rifleman"],
    ])
    for b in [Vector3(-64, 0, -66), Vector3(16, 0, -66), Vector3(72, 0, -34), Vector3(-20, 0, 40), Vector3(26, 0, 0)]:
        L.add_barrel(b)
    L.add_pickup(Vector3(-4, 0, 86), "launcher")
    L.add_pickup(Vector3(4, 0, 86), "armor")
    L.add_pickup(Vector3(0, 0, 76), "grenades")
    L.add_pickup(Vector3(-90, 0, 0), "health")
    L.add_pickup(Vector3(90, 0, 0), "health")
    L.add_pickup(Vector3(0, 0, -30), "ammo")
    L.add_pickup(Vector3(-40, 0, 60), "sniper")
    L.add_pickup(Vector3(45, 0, 60), "drone")

    return {
        "spawn": Vector3(0, 0.5, 84), "spawn_yaw": 0.0, "drones": 2, "safe_radius": 20.0,
        "start_weapons": ["carbine", "shotgun", "launcher"],
        "sky_top": Color(0.01, 0.02, 0.06), "sky_horizon": Color(0.08, 0.1, 0.18),
        "sun_color": Color(0.55, 0.65, 0.95), "sun_energy": 0.35, "sun_rot": Vector3(-45, 120, 0),
        "fog": 0.008, "ambient": 0.55, "exposure": 1.25,
        "music": "res://assets/audio/music/war_theme.ogg", "ambience": "res://assets/audio/ambience/desert_wind.ogg", "ambience_db": -16.0, "distant_booms": true,
        "objectives": [
            {"type": "destroy", "tag": "fuel", "text": "Blow up the Tan fuel depots on the quay"},
            {"type": "extract", "pos": Vector3(-88, 0, 75), "text": "Extract from the south-west gate"},
        ],
    }


# ======================================================= 10: BUNK BED ====

static func _bedroom(L) -> Dictionary:
    var carpet := Color(0.35, 0.45, 0.7)
    var hx := 75.0
    var hz := 62.0
    room(L, hx, hz, carpet, Color(0.85, 0.82, 0.6))
    L.cyl(Vector3(0, 0.03, 0), 30, 0.06, Color(0.85, 0.35, 0.3), false)
    L.cyl(Vector3(0, 0.05, 0), 24, 0.06, Color(0.95, 0.8, 0.3), false)
    # Bunk bed (west): huge posts + slatted base you can run under
    var wood := Color(0.75, 0.55, 0.35)
    for p in [Vector3(-70, 0, -50), Vector3(-70, 0, 20), Vector3(-30, 0, -50), Vector3(-30, 0, 20)]:
        L.box(p + Vector3(0, 30, 0), Vector3(3, 60, 3), wood)
    L.box(Vector3(-50, 18, -15), Vector3(42, 2, 72), wood, 0.0, false)
    L.box(Vector3(-50, 22, -15), Vector3(40, 6, 70), Color(0.3, 0.55, 0.85), 0.0, false)
    L.box(Vector3(-50, 48, -15), Vector3(42, 2, 72), wood, 0.0, false)
    L.box(Vector3(-50, 52, -15), Vector3(40, 6, 70), Color(0.85, 0.3, 0.3), 0.0, false)
    # Dresser (east) + night light
    L.box(Vector3(62, 22, -40), Vector3(24, 44, 36), Color(0.95, 0.95, 0.95))
    L.lamp(Vector3(62, 48, -40), Color(1.0, 0.8, 0.5), 60.0, 2.0)
    # Toy fort in the middle of the rug (the point to defend)
    var fort := Color(0.55, 0.4, 0.25)
    L.wall(Vector3(-14, 0, -14), Vector3(14, 0, -14), 3.0, 1.0, fort)
    L.wall(Vector3(-14, 0, -14), Vector3(-14, 0, -4), 3.0, 1.0, fort)
    L.wall(Vector3(-14, 0, 4), Vector3(-14, 0, 14), 3.0, 1.0, fort)
    L.wall(Vector3(14, 0, -14), Vector3(14, 0, -4), 3.0, 1.0, fort)
    L.wall(Vector3(14, 0, 4), Vector3(14, 0, 14), 3.0, 1.0, fort)
    L.wall(Vector3(-14, 0, 14), Vector3(-4, 0, 14), 3.0, 1.0, fort)
    L.wall(Vector3(4, 0, 14), Vector3(14, 0, 14), 3.0, 1.0, fort)
    for c in [Vector3(-14, 0, -14), Vector3(14, 0, -14), Vector3(-14, 0, 14), Vector3(14, 0, 14)]:
        L.box(c + Vector3(0, 3, 0), Vector3(3.5, 6, 3.5), fort.darkened(0.15))
    L.cyl(Vector3(0, 6, 0), 0.12, 12, Color(0.9, 0.9, 0.9), false)
    L.box(Vector3(1.2, 11, 0), Vector3(2.4, 1.4, 0.05), Color(0.3, 0.6, 0.25), 0.0, false)
    # Toy chaos: blocks, bricks, a race car, books, a sock
    var block_c := [Color(0.9, 0.2, 0.2), Color(0.2, 0.5, 0.9), Color(0.95, 0.8, 0.15), Color(0.25, 0.7, 0.3)]
    var blocks := [[Vector3(-20, 0, 35), 5.0], [Vector3(-15, 5, 35), 5.0], [Vector3(30, 0, 30), 6.0], [Vector3(36, 0, 22), 4.0],
        [Vector3(-10, 0, -40), 5.0], [Vector3(25, 0, -25), 6.0], [Vector3(-55, 0, 40), 5.0], [Vector3(10, 0, 44), 4.0]]
    for i in blocks.size():
        toy_block(L, blocks[i][0], blocks[i][1], block_c[i % 4], i * 0.4)
    lego(L, Vector3(45, 0, 5), 4, 2, Color(0.9, 0.15, 0.15), 0.3)
    lego(L, Vector3(-25, 0, -25), 3, 2, Color(0.15, 0.4, 0.9), -0.5)
    lego(L, Vector3(40, 0, -10), 2, 2, Color(0.95, 0.8, 0.1), 0.0)
    lego(L, Vector3(-22, 0, 15), 4, 2, Color(0.2, 0.7, 0.3), 1.2)
    L.prop("kenney_car_kit/race.glb", Vector3(30, 0, 48), -0.7, Vector3(0, 0, 18.0))
    L.box(Vector3(20, 1.5, -48), Vector3(16, 3, 22), Color(0.6, 0.15, 0.2), 0.2)
    L.box(Vector3(20, 4.5, -48), Vector3(15, 3, 21), Color(0.15, 0.35, 0.6), 0.35)
    L.box_rot(Vector3(-25, 0.6, 50), Vector3(6, 1.2, 16), Color(0.9, 0.9, 0.95), Vector3(0, 0.8, 0))
    # Reinforcements wait under the bed and behind the dresser.
    for p in [Vector3(-60, 0, -40), Vector3(-45, 0, -30), Vector3(-60, 0, 0), Vector3(-40, 0, 10), Vector3(-50, 0, -10),
            Vector3(55, 0, -15), Vector3(65, 0, -10), Vector3(45, 0, -60), Vector3(60, 0, -60), Vector3(0, 0, -55),
            Vector3(-15, 0, -55), Vector3(15, 0, -58)]:
        L.add_reserve(p + Vector3(0, 0.1, 0), ["rifleman", "rifleman", "gunner", "rocketeer"][absi(int(p.x + p.z)) % 4])
    L.add_enemy_vehicle("jeep", Vector3(-50, 0, -45), 0.0)
    L.add_enemy_vehicle("tank", Vector3(50, 0, -50), 0.0)
    troops(L, [
        [Vector3(-30, 0, 40), "rifleman"], [Vector3(30, 0, -30), "rifleman"], [Vector3(-40, 0, -20), "rifleman"],
        [Vector3(40, 0, 15), "gunner"], [Vector3(-15, 10.1, 35), "sniper"],
    ])
    L.add_vehicle("tank", Vector3(-8, 0, 30), 0.0)
    L.add_pickup(Vector3(-4, 0, 54), "launcher")
    L.add_pickup(Vector3(4, 0, 54), "lmg")
    L.add_pickup(Vector3(0, 0, 8), "ammo")
    L.add_pickup(Vector3(-6, 0, -6), "grenades")
    L.add_pickup(Vector3(6, 0, -6), "armor")
    L.add_pickup(Vector3(8, 0, 6), "health")
    L.add_pickup(Vector3(-60, 0, 50), "health")
    L.add_pickup(Vector3(60, 0, 40), "drone")
    L.lamp(Vector3(0, 75, 0), Color(1.0, 0.95, 0.85), 170.0, 1.1, false)

    return {
        "spawn": Vector3(0, 0.5, 56), "spawn_yaw": 0.0, "drones": 2, "safe_radius": 14.0,
        "start_weapons": ["carbine", "shotgun", "launcher"],
        "sky_top": Color(0.8, 0.78, 0.6), "sky_horizon": Color(0.85, 0.82, 0.65),
        "sun_color": Color(1.0, 0.9, 0.7), "sun_energy": 0.75, "sun_rot": Vector3(-35, -60, 0),
        "fog": 0.0, "ambient": 0.65, "exposure": 0.9,
        "music": "res://assets/audio/music/determined_pursuit.ogg", "ambience": "res://assets/audio/ambience/clock_tick.ogg", "ambience_db": -8.0,
        "objectives": [
            {"type": "reach", "pos": Vector3(0, 0, 0), "radius": 10.0, "text": "Get to the toy fort on the rug"},
            {"type": "defend", "pos": Vector3(0, 0, 0), "radius": 14.0, "time": 75.0, "text": "Hold the toy fort until bedtime"},
            {"type": "kill_all", "text": "Clear the bedroom of Tan forces"},
        ],
    }


# =================================================== 11: MOUNTAIN PASS ====

static func _mountain(L) -> Dictionary:
    var rng := RandomNumberGenerator.new()
    rng.seed = 1111
    var snow := Color(0.88, 0.9, 0.94)
    var rock := Color(0.42, 0.42, 0.46)
    var road := Color(0.35, 0.33, 0.32)
    L.box(Vector3(0, -0.5, 0), Vector3(260, 1, 260), snow, 0.0, true, L.mat(snow, 0.6))
    L.bounds(70, 105)
    # Canyon walls, zig-zagging
    for i in 9:
        var z := 100.0 - i * 25.0
        var off := sin(i * 0.9) * 14.0
        ridge(L, Vector3(-62 + off, 0, z), Vector3(40, 28 + (i % 3) * 6, 26), 0.0, rock, snow)
        ridge(L, Vector3(62 + off, 0, z), Vector3(40, 30 + (i % 2) * 8, 26), 0.0, rock, snow)
    # Sniper ledges
    for p in [Vector3(-22, 0, 22), Vector3(22, 0, -12), Vector3(-24, 0, -72), Vector3(24, 0, -60)]:
        L.box(p + Vector3(0, 4, 0), Vector3(6, 8, 6), rock)
        L.box(p + Vector3(0, 8.2, 0), Vector3(6.4, 0.4, 6.4), snow, 0.0, false)
    # Winding road + frozen river with a bridge
    for i in 10:
        L.box(Vector3(sin(i * 0.7) * 10.0, 0.02, 95 - i * 21.0), Vector3(12, 0.04, 22), road, sin(i * 0.7) * 0.3, false)
    L.water(Vector3(0, 0.05, 0), Vector2(90, 12), Color(0.7, 0.85, 0.95, 0.85))
    L.box(Vector3(0, 1.0, 0), Vector3(14, 0.6, 18), Color(0.45, 0.35, 0.25))
    for s in [-1, 1]:
        L.box(Vector3(6.8 * s, 1.9, 0), Vector3(0.4, 1.2, 18), Color(0.35, 0.28, 0.2))
    L.box_rot(Vector3(0, 0.5, 11.2), Vector3(14, 0.4, 4.6), Color(0.45, 0.35, 0.25), Vector3(deg_to_rad(-12), 0, 0))
    L.box_rot(Vector3(0, 0.5, -11.2), Vector3(14, 0.4, 4.6), Color(0.45, 0.35, 0.25), Vector3(deg_to_rad(12), 0, 0))
    # Checkpoint + SAM sites + Brigadier's lodge
    hesco(L, Vector3(-20, 0, -30), Vector3(-7, 0, -30), Color(0.76, 0.68, 0.5))
    hesco(L, Vector3(7, 0, -30), Vector3(20, 0, -30), Color(0.76, 0.68, 0.5))
    L.add_target(Vector3(-22, 0, -55), "sam", "sams", 0.4)
    L.add_target(Vector3(22, 0, -80), "sam", "sams", -0.5)
    L.box(Vector3(0, 3, -94), Vector3(20, 6, 10), Color(0.5, 0.36, 0.24))
    L.box_rot(Vector3(0, 7.5, -94), Vector3(22, 0.6, 7), snow, Vector3(deg_to_rad(25), 0, 0), false)
    L.add_enemy_vehicle("tank", Vector3(5, 0, -45), PI)
    L.add_enemy_vehicle("jeep", Vector3(-5, 0, 30), PI)
    L.add_enemy_vehicle("tank", Vector3(-10, 0, -85), PI)
    troops(L, [
        [Vector3(0, 0, -86), "officer", true],
        [Vector3(-10, 0, 40), "rifleman"], [Vector3(12, 0, 35), "rifleman"], [Vector3(0, 1.4, 4), "gunner"],
        [Vector3(-15, 0, -10), "rifleman"], [Vector3(15, 0, -12), "rocketeer"], [Vector3(-8, 0, -26), "gunner"],
        [Vector3(8, 0, -26), "rifleman"], [Vector3(-26, 0, -60), "rifleman"], [Vector3(-16, 0, -50), "rocketeer"],
        [Vector3(26, 0, -76), "gunner"], [Vector3(16, 0, -84), "rifleman"], [Vector3(-12, 0, -96), "rifleman"],
        [Vector3(12, 0, -96), "gunner"], [Vector3(-22, 8.1, 22), "sniper"], [Vector3(22, 8.1, -12), "sniper"],
        [Vector3(-24, 8.1, -72), "sniper"], [Vector3(24, 8.1, -60), "sniper"],
    ])
    var avoid := [[Vector3(0, 0, 90), 18.0], [Vector3(0, 0, 0), 14.0], [Vector3(0, 0, -60), 36.0],
        [Vector3(-22, 0, 22), 6.0], [Vector3(22, 0, -12), 6.0]]
    for i in 26:
        var p := Vector3(rng.randf_range(-26, 26), 0, rng.randf_range(-100, 100))
        if clear_of(p, avoid) and absf(p.x - sin((95.0 - p.z) / 21.0 * 0.7) * 10.0) > 9.0:
            pine(L, p, rng.randf_range(6.0, 10.0))
            avoid.append([p, 4.0])
    for b in [Vector3(-14, 0, -36), Vector3(14, 0, -36), Vector3(0, 0, -70)]:
        L.add_barrel(b)
    L.add_vehicle("tank", Vector3(-6, 0, 86), 0.0)
    L.add_vehicle("jeep", Vector3(8, 0, 88), 0.0)
    L.add_vehicle("apc", Vector3(18, 0, 80), 0.0)
    L.add_vehicle("heli", Vector3(-18, 0, 76), 0.0)
    L.add_pickup(Vector3(-4, 0, 94), "launcher")
    L.add_pickup(Vector3(4, 0, 94), "sniper")
    L.add_pickup(Vector3(0, 0, 80), "armor")
    L.add_pickup(Vector3(-14, 0, 24), "health")
    L.add_pickup(Vector3(20, 0, -40), "ammo")
    L.add_pickup(Vector3(-20, 0, -80), "health")
    L.add_pickup(Vector3(18, 0, 10), "grenades")

    return {
        "spawn": Vector3(0, 0.5, 92), "spawn_yaw": 0.0, "drones": 2, "safe_radius": 16.0,
        "start_weapons": ["carbine", "shotgun", "launcher"],
        "sky_top": Color(0.42, 0.55, 0.78), "sky_horizon": Color(0.82, 0.86, 0.92),
        "sun_color": Color(1.0, 0.92, 0.85), "sun_energy": 1.0, "sun_rot": Vector3(-35, -20, 0),
        "fog": 0.009, "ambient": 0.75, "exposure": 0.8, "snow": true,
        "music": "res://assets/audio/music/war_theme.ogg", "ambience": "res://assets/audio/ambience/desert_wind.ogg", "ambience_db": -6.0, "distant_booms": true,
        "objectives": [
            {"type": "destroy", "tag": "sams", "text": "Destroy the SAM sites guarding the pass"},
            {"type": "kill_hvt", "text": "Eliminate Brigadier Biscuit at the ski lodge"},
        ],
    }


# ==================================================== 12: GARAGE SALE ====

static func _garage(L) -> Dictionary:
    var floor_c := Color(0.55, 0.55, 0.55)
    var hx := 75.0
    var hz := 62.0
    room(L, hx, hz, floor_c, Color(0.75, 0.72, 0.66))
    L.box(Vector3(10, 0.01, -5), Vector3(30, 0.02, 20), Color(0.25, 0.25, 0.26), 0.3, false)   # oil stain
    L.box(Vector3(0, 30, 73), Vector3(110, 50, 1), Color(0.9, 0.95, 1.0), 0.0, false, L.glow_mat(Color(0.95, 0.97, 1.0), 1.0))  # open door glare
    # The family car (parked, enormous)
    L.prop("kenney_car_kit/suv.glb", Vector3(-40, 0, -10), 0.0, Vector3(0, 0, 60.0))
    # Workbench + pegboard (north), tool chest, shelves, bike
    L.box(Vector3(20, 14, -55), Vector3(60, 2, 14), Color(0.6, 0.45, 0.3))
    for x in [-8.0, 48.0]:
        L.box(Vector3(x, 6.5, -55), Vector3(2, 13, 12), Color(0.5, 0.38, 0.25))
    L.box(Vector3(20, 35, -62), Vector3(60, 30, 1), Color(0.75, 0.6, 0.45), 0.0, false)
    L.box(Vector3(60, 12, -45), Vector3(14, 24, 10), Color(0.8, 0.12, 0.1), 0.0, true, L.mat(Color(0.8, 0.12, 0.1), 0.3, 0.5))
    for y in [0.0, 14.0, 28.0]:
        L.box(Vector3(65, y + 0.5, 20), Vector3(16, 1, 40), Color(0.55, 0.55, 0.6))
    for z in [2.0, 38.0]:
        L.box(Vector3(65, 15, z), Vector3(16, 30, 1), Color(0.5, 0.5, 0.55), 0.0, false)
    # Garage-sale tables with junk; cardboard boxes as cover
    var cardboard := Color(0.7, 0.55, 0.35)
    for b in [[Vector3(-10, 0, 25), 8.0, 0.2], [Vector3(-2, 0, 32), 6.0, -0.1], [Vector3(20, 0, 20), 9.0, 0.5], [Vector3(30, 0, -20), 7.0, 0.0],
            [Vector3(-15, 0, -40), 8.0, 0.8], [Vector3(5, 0, -30), 6.0, 0.3], [Vector3(40, 0, 45), 7.0, -0.4], [Vector3(-60, 0, 45), 8.0, 0.1]]:
        L.box(b[0] + Vector3(0, b[1] * 0.4, 0), Vector3(b[1], b[1] * 0.8, b[1] * 0.9), cardboard, b[2])
        L.box(b[0] + Vector3(0, b[1] * 0.8 + 0.01, 0), Vector3(b[1] * 0.15, 0.02, b[1] * 0.9), Color(0.75, 0.65, 0.45), b[2], false)
    L.cyl(Vector3(30, 0.6, 5), 6, 1.2, Color(0.15, 0.15, 0.15), true, Vector3(PI / 2, 0.4, 0))   # spare tire
    for p in [Vector3(-5, 0, -10), Vector3(45, 0, 0), Vector3(15, 0, 40)]:
        L.cyl(p + Vector3(0, 3, 0), 2.5, 6, Color(0.3, 0.45, 0.75), true, Vector3.ZERO, L.mat(Color(0.3, 0.45, 0.75), 0.3, 0.6))
    # Gas cans (fuel targets) and the Tan plans (intel)
    L.add_target(Vector3(10, 0, -42), "fuel", "fuel", 0.0)
    L.add_target(Vector3(50, 0, -25), "fuel", "fuel", 0.4)
    L.add_pickup(Vector3(20, 15.2, -55), "intel")
    L.add_pickup(Vector3(65, 15.0, 20), "intel")
    L.add_pickup(Vector3(-40, 0, -48), "intel")
    # Ramps up to the workbench and shelf
    L.box_rot(Vector3(0, 7.6, -38), Vector3(6, 0.6, 32), Color(0.65, 0.5, 0.32), Vector3(deg_to_rad(28), 0, 0))
    L.box_rot(Vector3(46, 7.1, 8), Vector3(34, 0.6, 6), Color(0.65, 0.5, 0.32), Vector3(0, 0, deg_to_rad(28)))
    L.add_vehicle("jeep", Vector3(10, 0, 48), 0.0)
    L.add_enemy_vehicle("jeep", Vector3(-10, 0, -20), PI)
    L.add_enemy_vehicle("tank", Vector3(30, 0, -35), PI)
    troops(L, [
        [Vector3(14, 15.1, -55), "gunner"], [Vector3(30, 15.1, -55), "rifleman"], [Vector3(66, 15.1, 30), "sniper"],
        [Vector3(65, 29.1, 10), "sniper"], [Vector3(8, 0, -36), "rifleman"], [Vector3(55, 0, -20), "rifleman"],
        [Vector3(-12, 0, 18), "rifleman"], [Vector3(22, 0, 12), "gunner"], [Vector3(-40, 0, -45), "rocketeer"],
        [Vector3(-55, 0, 20), "rifleman"], [Vector3(-20, 0, -15), "rifleman"], [Vector3(40, 0, 30), "rocketeer"],
        [Vector3(0, 0, -50), "gunner"], [Vector3(-60, 0, -30), "rifleman"], [Vector3(60, 0, 50), "rifleman"],
        [Vector3(-30, 0, 40), "rifleman"],
    ])
    for b in [Vector3(4, 0, -44), Vector3(44, 0, -28), Vector3(-25, 0, 30)]:
        L.add_barrel(b)
    L.add_pickup(Vector3(-4, 0, 52), "launcher")
    L.add_pickup(Vector3(4, 0, 56), "ammo")
    L.add_pickup(Vector3(0, 0, 44), "armor")
    L.add_pickup(Vector3(-60, 0, 0), "health")
    L.add_pickup(Vector3(55, 0, 55), "health")
    L.add_pickup(Vector3(-20, 0, -55), "grenades")
    L.add_pickup(Vector3(35, 0, 0), "lmg")
    for x in [-40.0, 0.0, 40.0]:
        L.box(Vector3(x, 72, -10), Vector3(30, 1, 3), Color(1, 1, 1), 0.0, false, L.glow_mat(Color(0.95, 1.0, 1.0), 2.0))
    L.lamp(Vector3(0, 65, 0), Color(0.92, 0.97, 1.0), 170.0, 1.2, false)

    return {
        "spawn": Vector3(0, 0.5, 52), "spawn_yaw": 0.0, "drones": 2, "safe_radius": 15.0,
        "start_weapons": ["carbine", "shotgun", "launcher"],
        "sky_top": Color(0.7, 0.7, 0.68), "sky_horizon": Color(0.78, 0.76, 0.72),
        "sun_color": Color(1.0, 0.96, 0.88), "sun_energy": 0.85, "sun_rot": Vector3(-30, 180, 0),
        "fog": 0.0, "ambient": 0.65, "exposure": 0.9,
        "music": "res://assets/audio/music/battle_theme_a.ogg", "ambience": "res://assets/audio/ambience/city_traffic.ogg", "ambience_db": -22.0,
        "objectives": [
            {"type": "destroy", "tag": "fuel", "text": "Destroy the Tan gas-can fuel depots"},
            {"type": "collect", "kind": "intel", "text": "Find the map to General Beige's HQ"},
        ],
    }


# ===================================================== 13: BEIGE DAWN ====

static func _living_room(L) -> Dictionary:
    var floor_c := Color(0.55, 0.38, 0.24)
    var hx := 85.0
    var hz := 70.0
    room(L, hx, hz, floor_c, Color(0.78, 0.74, 0.66))
    for k in range(-9, 10):
        L.box(Vector3(k * 9.0, 0.005, 0), Vector3(0.15, 0.01, hz * 2 + 30), floor_c.darkened(0.3), 0.0, false)
    L.box(Vector3(-10, 0.04, 20), Vector3(90, 0.08, 60), Color(0.65, 0.2, 0.2), 0.0, false)
    L.box(Vector3(-10, 0.06, 20), Vector3(80, 0.08, 50), Color(0.8, 0.7, 0.5), 0.0, false)
    # The beige couch fortress (north)
    var beige := Color(0.8, 0.72, 0.58)
    L.box(Vector3(0, 9, -58), Vector3(120, 18, 30), beige)
    L.box(Vector3(0, 30, -70), Vector3(120, 30, 8), beige.darkened(0.06), 0.0, false)
    for s in [-1, 1]:
        L.box(Vector3(64 * s, 16, -58), Vector3(10, 32, 32), beige.darkened(0.04))
    for i in 3:
        L.box(Vector3(-40 + i * 40, 18.3, -55), Vector3(38, 0.6, 24), beige.lightened(0.05))
    # cushion walls (fallen cushions as Tan ramparts)
    L.box_rot(Vector3(-30, 6, -30), Vector3(30, 12, 6), beige.darkened(0.1), Vector3(0.15, 0.2, 0))
    L.box_rot(Vector3(30, 6, -32), Vector3(30, 12, 6), beige.darkened(0.1), Vector3(0.15, -0.25, 0))
    L.box_rot(Vector3(0, 0.6, -38), Vector3(20, 1.2, 10), beige, Vector3(0, 0, 0))
    # TV + stand (east), glowing
    L.box(Vector3(70, 10, 20), Vector3(14, 20, 50), Color(0.2, 0.15, 0.12))
    L.box(Vector3(70, 40, 20), Vector3(3, 36, 64), Color(0.05, 0.05, 0.06))
    L.box(Vector3(68.4, 40, 20), Vector3(0.2, 33, 60), Color(0.3, 0.5, 0.9), 0.0, false, L.glow_mat(Color(0.35, 0.55, 0.95), 1.6))
    L.lamp(Vector3(55, 30, 20), Color(0.5, 0.65, 1.0), 60.0, 1.5, false)
    # Coffee table (walk under it), remote, popcorn, pizza box
    for p in [Vector3(-35, 0, 0), Vector3(15, 0, 0), Vector3(-35, 0, 30), Vector3(15, 0, 30)]:
        L.box(p + Vector3(0, 7, 0), Vector3(2.5, 14, 2.5), Color(0.4, 0.26, 0.16))
    L.box(Vector3(-10, 14.6, 15), Vector3(56, 1.2, 36), Color(0.45, 0.3, 0.18))
    L.box(Vector3(-20, 15.6, 10), Vector3(5, 0.8, 16), Color(0.1, 0.1, 0.1), 0.4, false)
    L.cyl(Vector3(0, 18, 20), 6, 6, Color(0.85, 0.2, 0.2), false, Vector3.ZERO, null, 4.5)
    L.box(Vector3(-70, 0.8, 15), Vector3(22, 1.6, 22), Color(0.85, 0.8, 0.7), 0.3)
    L.box(Vector3(-62, 6, -20), Vector3(10, 12, 10), Color(0.35, 0.3, 0.28))
    L.lamp(Vector3(-62, 34, -20), Color(1.0, 0.85, 0.6), 50.0, 1.8)
    L.cyl(Vector3(-62, 23, -20), 0.6, 22, Color(0.75, 0.7, 0.6), false)
    # Toy blocks + a giant ball as extra cover
    var block_c := [Color(0.9, 0.2, 0.2), Color(0.2, 0.5, 0.9), Color(0.95, 0.8, 0.15), Color(0.25, 0.7, 0.3)]
    var blocks := [Vector3(40, 0, 45), Vector3(-45, 0, 10), Vector3(45, 0, -15), Vector3(-20, 0, -20), Vector3(25, 0, 40)]
    for i in blocks.size():
        toy_block(L, blocks[i], 5.0, block_c[i % 4], i * 0.5)
    lego(L, Vector3(-30, 0, 50), 4, 2, Color(0.9, 0.15, 0.15), 0.2)
    lego(L, Vector3(35, 0, 10), 3, 2, Color(0.15, 0.4, 0.9), -0.4)
    # TV antennas + General Beige on the couch
    L.add_target(Vector3(-40, 18.6, -55), "antenna", "antennas", 0.0)
    L.add_target(Vector3(40, 18.6, -55), "antenna", "antennas", 0.0)
    L.add_target(Vector3(66, 20, 0), "antenna", "antennas", 0.0)
    L.box_rot(Vector3(-50, 9, -30), Vector3(8, 0.8, 34), beige.darkened(0.15), Vector3(deg_to_rad(33), 0, 0))   # cushion ramp up
    L.box_rot(Vector3(50, 9.5, -30), Vector3(8, 0.8, 34), beige.darkened(0.15), Vector3(deg_to_rad(33), 0, 0))
    L.box_rot(Vector3(49.3, 9.8, 35), Vector3(36, 0.8, 8), Color(0.4, 0.3, 0.2), Vector3(0, 0, deg_to_rad(35)))   # book ramp to TV stand
    L.add_vehicle("jeep", Vector3(-8, 0, 58), 0.0)
    L.add_vehicle("tank", Vector3(10, 0, 56), 0.0)
    L.add_enemy_vehicle("tank", Vector3(-30, 0, -15), 0.0)
    L.add_enemy_vehicle("tank", Vector3(30, 0, -18), 0.0)
    L.add_enemy_vehicle("jeep", Vector3(50, 0, 30), PI)
    troops(L, [
        [Vector3(0, 18.7, -52), "general", true],
        [Vector3(-10, 18.7, -50), "gunner"], [Vector3(10, 18.7, -50), "gunner"], [Vector3(-40, 18.7, -48), "rifleman"],
        [Vector3(40, 18.7, -48), "rifleman"], [Vector3(-25, 18.7, -60), "sniper"], [Vector3(25, 18.7, -60), "sniper"],
        [Vector3(-30, 0, -24), "rifleman"], [Vector3(30, 0, -26), "rocketeer"], [Vector3(0, 0, -30), "gunner"],
        [Vector3(66, 20.1, 10), "rifleman"], [Vector3(66, 20.1, 30), "rocketeer"], [Vector3(-10, 15.3, 15), "sniper"],
        [Vector3(-50, 0, 0), "rifleman"], [Vector3(50, 0, 0), "rifleman"], [Vector3(-60, 0, 30), "gunner"],
        [Vector3(45, 0, 30), "rifleman"], [Vector3(0, 0, 0), "rifleman"], [Vector3(-20, 0, 30), "rocketeer"],
        [Vector3(70, 0, -40), "rifleman"], [Vector3(-75, 0, -45), "rifleman"],
    ])
    for b in [Vector3(-25, 0, -30), Vector3(25, 0, -34), Vector3(60, 0, 0), Vector3(-5, 0, 5)]:
        L.add_barrel(b)
    L.add_pickup(Vector3(-4, 0, 62), "launcher")
    L.add_pickup(Vector3(4, 0, 62), "lmg")
    L.add_pickup(Vector3(0, 0, 52), "armor")
    L.add_pickup(Vector3(-70, 0, 55), "health")
    L.add_pickup(Vector3(70, 0, 60), "health")
    L.add_pickup(Vector3(-50, 0, -10), "ammo")
    L.add_pickup(Vector3(40, 0, -5), "grenades")
    L.add_pickup(Vector3(-10, 15.3, 25), "drone")
    L.add_pickup(Vector3(0, 18.7, -60), "health")
    L.lamp(Vector3(0, 80, 0), Color(1.0, 0.9, 0.75), 190.0, 0.9, false)

    return {
        "spawn": Vector3(0, 0.5, 62), "spawn_yaw": 0.0, "drones": 3, "safe_radius": 16.0,
        "start_weapons": ["carbine", "shotgun", "launcher", "sniper"],
        "sky_top": Color(0.85, 0.6, 0.45), "sky_horizon": Color(0.95, 0.75, 0.55),
        "sun_color": Color(1.0, 0.8, 0.6), "sun_energy": 0.9, "sun_rot": Vector3(-20, 120, 0),
        "fog": 0.0, "ambient": 0.6, "exposure": 0.9,
        "music": "res://assets/audio/music/war_theme.ogg", "ambience": "res://assets/audio/ambience/clock_tick.ogg", "ambience_db": -10.0,
        "objectives": [
            {"type": "destroy", "tag": "antennas", "text": "Destroy the TV antennas broadcasting Beige Dawn"},
            {"type": "kill_hvt", "text": "Defeat General Beige on the couch"},
            {"type": "extract", "pos": Vector3(-65, 0, 52), "text": "Extract on the rug by the window"},
        ],
    }
