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
]


static func build(i: int, L) -> Dictionary:
    var d: Dictionary
    match i:
        0:
            d = _desert(L)
        1:
            d = _urban(L)
        _:
            d = _tabletop(L)
    d["name"] = META[clampi(i, 0, META.size() - 1)]["name"]
    return d


static func _rot(v: Vector3, r: float) -> Vector3:
    return v.rotated(Vector3.UP, r)


# ----------------------------------------------------------- props ----

static func container(L, pos: Vector3, rot: float, color: Color) -> void:
    L.box(pos + Vector3(0, 1.3, 0), Vector3(2.5, 2.6, 6.1), color, rot)
    for i in 5:
        var off := _rot(Vector3(1.27, 1.3, -2.4 + i * 1.2), rot)
        L.box(pos + off, Vector3(0.06, 2.4, 0.15), color.darkened(0.2), rot, false)


static func vehicle(L, pos: Vector3, rot: float, color: Color, burnt := false) -> void:
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
    L.box(pos + Vector3(0, 0.5, 0), Vector3(length, 1.0, 0.9), Color(0.68, 0.6, 0.42), rot)


static func palm(L, pos: Vector3) -> void:
    L.cyl(pos + Vector3(0, 3.0, 0), 0.25, 6.0, Color(0.45, 0.35, 0.22), true, Vector3.ZERO, null, 0.18)
    for i in 6:
        var a := i * TAU / 6.0
        L.box_rot(pos + Vector3(cos(a) * 1.4, 6.1, sin(a) * 1.4), Vector3(3.0, 0.08, 0.7), Color(0.3, 0.5, 0.2), Vector3(0, -a, deg_to_rad(-20)), false)


static func tree(L, pos: Vector3) -> void:
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
        L.box_rot(p + Vector3(0, s * 0.35, 0), Vector3(s * 1.4, s, s * 1.1), color, Vector3(rng.randf() * 0.3, rng.randf() * TAU, rng.randf() * 0.3))
        placed += 1


# ======================================================== 1: DESERT ====

static func _desert(L) -> Dictionary:
    var rng := RandomNumberGenerator.new()
    rng.seed = 2026
    var sand := Color(0.74, 0.62, 0.42)
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
    vehicle(L, Vector3(-14, 0, 78), 0.2, green)
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

    return {
        "spawn": Vector3(0, 0.5, 86), "spawn_yaw": 0.0, "drones": 1,
        "start_weapons": ["carbine", "shotgun"],
        "sky_top": Color(0.32, 0.55, 0.85), "sky_horizon": Color(0.9, 0.82, 0.68),
        "sun_color": Color(1.0, 0.93, 0.8), "sun_energy": 1.15, "sun_rot": Vector3(-52, 30, 0),
        "fog": 0.0035, "ambient": 0.7,
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
                    L.box(Vector3(bx, h * 0.5, bz), Vector3(lw, h, ld), col)
                    var band := col.darkened(0.45)
                    var y := 3.0
                    while y < h - 1.5:
                        L.box(Vector3(bx, y, bz), Vector3(lw + 0.12, 1.1, ld + 0.12), band, 0.0, false)
                        y += 4.0
                    L.box(Vector3(bx, h + 0.4, bz), Vector3(lw, 0.8, ld), col.darkened(0.15), 0.0, false)
                    L.box(Vector3(bx + lw * 0.2, h + 1.0, bz - ld * 0.2), Vector3(2.0, 1.2, 1.6), Color(0.6, 0.6, 0.6), 0.0, false)
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
    for p in [Vector3(-4.5, 0, 40), Vector3(0, 0, 40), Vector3(4.5, 0, 40), Vector3(-4.5, 0, -40), Vector3(4.5, 0, -40),
            Vector3(40, 0, -3), Vector3(40, 0, 3), Vector3(-40, 0, 0), Vector3(50, 0, -40), Vector3(-50, 0, 40)]:
        L.box(p + Vector3(0, 0.55, 0), Vector3(3.2, 1.1, 0.7), Color(0.75, 0.74, 0.7))

    var troops := [
        [Vector3(0, 0, 20), "rifleman"], [Vector3(6, 0, 0), "gunner"], [Vector3(-8, 0, -6), "rifleman"],
        [Vector3(-2, 0, -38), "rifleman"], [Vector3(2, 0, -55), "rocketeer"], [Vector3(30, 0, -2), "rifleman"],
        [Vector3(50, 0, 10), "rifleman"], [Vector3(48, 0, -20), "gunner"], [Vector3(-50, 0, 30), "rifleman"],
        [Vector3(-48, 0, -10), "rifleman"], [Vector3(-25, 0, -50), "rocketeer"], [Vector3(25, 0, 50), "rifleman"],
        [Vector3(-50, 0, -50), "gunner"], [Vector3(50, 0, 60), "rifleman"], [Vector3(-20, 0, 2), "rifleman"],
        [Vector3(70, 0, -3), "rifleman"], [Vector3(0, 0, 70), "rifleman"],
    ]
    for t in troops:
        L.add_enemy(t[0] + Vector3(0, 0.1, 0), t[1])
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
        "spawn": Vector3(0, 0.5, 92), "spawn_yaw": 0.0, "drones": 2,
        "start_weapons": ["carbine", "shotgun", "launcher"],
        "sky_top": Color(0.4, 0.5, 0.65), "sky_horizon": Color(0.78, 0.74, 0.7),
        "sun_color": Color(1.0, 0.85, 0.7), "sun_energy": 1.15, "sun_rot": Vector3(-35, -40, 0),
        "fog": 0.006, "ambient": 0.8,
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
    L.add_pickup(Vector3(-20, 0, -15), "health")
    L.add_pickup(Vector3(20, 0, -20), "ammo")
    L.add_pickup(Vector3(-65, 0, -25), "ammo")
    L.add_pickup(Vector3(55, 0, -50), "health")

    return {
        "spawn": Vector3(0, 0.5, 54), "spawn_yaw": 0.0, "drones": 2,
        "start_weapons": ["carbine", "shotgun", "launcher", "sniper"],
        "sky_top": Color(0.62, 0.58, 0.52), "sky_horizon": Color(0.74, 0.7, 0.62),
        "sun_color": Color(1.0, 0.9, 0.75), "sun_energy": 0.95, "sun_rot": Vector3(-60, 20, 0),
        "fog": 0.0, "ambient": 0.6, "exposure": 0.85,
        "objectives": [
            {"type": "destroy", "tag": "boosters", "text": "Destroy the Tan Army Wi-Fi signal boosters"},
            {"type": "kill_all", "text": "Clear the table of all Tan forces"},
        ],
    }
