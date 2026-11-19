extends Node3D
## Mockups for the giant-bathroom MELTDOWN map (not used by the game).
## Loads the CC0 models straight from the download folder (they're not in the
## project yet). xvfb-run godot --path . res://tests/_bathroom_mockup.tscn -- <assets dir> <outdir>
##   bath_1.png  inside the toilet bowl: Melties cracking the porcelain, the locked paper
##   bath_2.png  the toilet-paper ramp after it's bought, up and over the rim
##   bath_3.png  the bathroom floor from the rim: tub, sink, duck, towels, mat, slippers
##   bath_4.png  looking up: the ceiling lights, one flickering

const Soldier = preload("res://scripts/plastic_soldier.gd")
const S := 40.0                   # 1 real metre = 40 game units (a soldier is ~4 cm tall)
const GREEN := Color(0.27, 0.48, 0.17)
const MELT := Color(0.74, 0.55, 0.36)

var A := ""                       # assets dir
var out := ""
var cam: Camera3D
var env: Environment
var caption: Label
var toilet_pos := Vector3.ZERO     # world position of the toilet's origin
var lights: Array = []
var shot1_guys: Array = []


func _ready() -> void:
    var args := OS.get_cmdline_user_args()
    A = args[0]
    out = args[1]
    _world()
    _room()
    _toilet()
    _props()
    _ceiling_lights()
    cam = Camera3D.new()
    add_child(cam)
    cam.current = true
    var cl := CanvasLayer.new()
    add_child(cl)
    caption = Label.new()
    caption.position = Vector2(24, 16)
    caption.add_theme_font_size_override("font_size", 30)
    caption.add_theme_constant_override("outline_size", 8)
    caption.add_theme_color_override("font_outline_color", Color.BLACK)
    cl.add_child(caption)
    for i in 3:
        await get_tree().process_frame
    for n in get_children():
        if n is Node3D and n.get_child_count() > 0:
            var b := _aabb(n)
            if b.size.length() > 0.01:
                print("AABB ", n.name, " ", n.get_child(0).name, " pos=", b.position.snapped(Vector3.ONE * 0.1), " size=", b.size.snapped(Vector3.ONE * 0.1))
    print("TOILETPOS ", toilet_pos)
    await _shot_bowl()
    await _shot_ramp()
    await _shot_floor()
    await _shot_ceiling()
    get_tree().quit()


func _snap(file: String) -> void:
    for i in 6:
        await get_tree().process_frame
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, file])


# ------------------------------------------------------------- helpers ----

func _r(x: float, y: float, z: float) -> Vector3:
    return Vector3(x, y, z) * S


func _load(path: String) -> Node3D:
    var doc := GLTFDocument.new()
    var st := GLTFState.new()
    if doc.append_from_file(A + "/" + path, st) != OK:
        push_error("could not load " + path)
        return Node3D.new()
    return doc.generate_scene(st)


func _aabb(n: Node) -> AABB:
    var box := AABB()
    var first := true
    for mi in n.find_children("*", "MeshInstance3D", true, false):
        var b: AABB = mi.global_transform * mi.get_aabb()
        box = b if first else box.merge(b)
        first = false
    return box


## Put a model in the world. fit = ["h", metres] (height) or ["w", metres]
## (longest side across the floor). pos is where the middle of its base goes.
func _place(path: String, fit: Array, pos: Vector3, yaw_deg := 0.0, parent: Node = null) -> Node3D:
    var holder := Node3D.new()
    (parent if parent else self).add_child(holder)
    var m := _load(path)
    holder.add_child(m)
    var b := _aabb(m)
    var size_now: float = b.size.y if fit[0] == "h" else maxf(b.size.x, b.size.z)
    var k: float = fit[1] * S / maxf(size_now, 0.0001)
    m.scale = Vector3.ONE * k
    b = _aabb(m)
    m.position -= Vector3(b.get_center().x, b.position.y, b.get_center().z)
    holder.position = pos
    holder.rotation.y = deg_to_rad(yaw_deg)
    return holder


func _mat(c: Color, rough := 0.5, emit := 0.0) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.roughness = rough
    if emit > 0.0:
        m.emission_enabled = true
        m.emission = c
        m.emission_energy_multiplier = emit
    return m


func _box(size: Vector3, pos: Vector3, m: Material) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = size
    mi.mesh = bm
    mi.material_override = m
    add_child(mi)
    mi.position = pos
    return mi


func _tex(file: String) -> ImageTexture:
    var img := Image.load_from_file(A + "/" + file)
    img.generate_mipmaps()
    return ImageTexture.create_from_image(img)


func _soldier(col: Color, anim: String, t: float, pos: Vector3, yaw: float, kind := "rifle"):
    var s = Soldier.create()
    add_child(s)
    s.build(col, kind)
    s.position = pos
    s.rotation.y = deg_to_rad(yaw)
    s.set_process(false)
    s.set_physics_process(false)
    s._play(anim)
    s.anim.seek(t, true)
    s.anim.pause()
    return s


# ---------------------------------------------------------------- room ----

func _world() -> void:
    var we := WorldEnvironment.new()
    env = Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.1, 0.1, 0.12)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.85, 0.86, 0.9)
    env.ambient_light_energy = 0.32
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.ssao_enabled = false
    we.environment = env
    add_child(we)
    # Soft daylight from a window high on the left wall.
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55, -60, 0)
    sun.light_energy = 0.55
    sun.light_color = Color(1.0, 0.97, 0.9)
    sun.shadow_enabled = true
    add_child(sun)


## A 2.2 m x 2.8 m bathroom, 2.4 m high: tiled walls, tiled floor.
func _room() -> void:
    var tiles := _tex("polyhaven/tex_interior_tiles/interior_tiles_diff_1k.jpg")
    var floor_m := StandardMaterial3D.new()
    floor_m.albedo_texture = tiles
    floor_m.albedo_color = Color(0.75, 0.82, 0.9)
    floor_m.uv1_triplanar = true
    floor_m.uv1_scale = Vector3.ONE / (0.3 * S)       # 30 cm tiles
    floor_m.roughness = 0.35
    var wall_m: StandardMaterial3D = floor_m.duplicate()
    wall_m.albedo_color = Color(1.0, 1.08, 1.15)
    wall_m.uv1_scale = Vector3.ONE / (0.15 * S)       # 15 cm wall tiles
    _box(_r(2.2, 0.02, 2.8), _r(0, -0.01, 1.4), floor_m)
    _box(_r(2.2, 2.4, 0.02), _r(0, 1.2, -0.01), wall_m)            # back
    _box(_r(0.02, 2.4, 2.8), _r(-1.11, 1.2, 1.4), wall_m)          # left
    _box(_r(0.02, 2.4, 2.8), _r(1.11, 1.2, 1.4), wall_m)           # right
    _box(_r(2.2, 2.4, 0.02), _r(0, 1.2, 2.81), wall_m)             # front (door wall)
    _box(_r(2.2, 0.02, 2.8), _r(0, 2.41, 1.4), _mat(Color(0.95, 0.95, 0.93), 0.9))   # ceiling
    # A painted wall stripe above the tiles, a skirting line, a window.
    _box(_r(2.18, 1.2, 0.005), _r(0, 1.8, 0.0), _mat(Color(0.62, 0.78, 0.86), 0.9))
    _box(_r(0.005, 0.6, 0.9), _r(-1.1, 1.75, 1.0), _mat(Color(0.95, 0.97, 1.0), 0.2, 1.6))
    # The door, with light under it.
    _box(_r(0.8, 2.0, 0.04), _r(0.55, 1.0, 2.79), _mat(Color(0.86, 0.84, 0.8), 0.6))


# -------------------------------------------------------------- toilet ----

## The toilet, built in code: a smooth porcelain bowl you can stand in (flat
## water floor, slopes you can walk up, steep near the rim), a pedestal and a
## cistern. Profile in metres: [radius, height]; the bowl is oval (deeper front
## to back).
const BOWL_IN := [[0.0, 0.2], [0.1, 0.2], [0.14, 0.235], [0.17, 0.29], [0.19, 0.35], [0.2, 0.4]]
const BOWL_OUT := [[0.25, 0.41], [0.262, 0.385], [0.245, 0.3], [0.19, 0.2], [0.135, 0.12], [0.12, 0.05], [0.15, 0.0]]
const OVAL := 1.25


func _toilet() -> void:
    toilet_pos = _r(0.1, 0, 0.52)
    var porc := _mat(Color(0.93, 0.95, 0.98), 0.18)
    var prof: Array = BOWL_IN.duplicate()
    prof.append([0.2, 0.41])
    prof += BOWL_OUT
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var seg := 64
    for i in prof.size() - 1:
        for j in seg:
            var a0 := TAU * j / seg
            var a1 := TAU * (j + 1) / seg
            var p00 := _lathe(prof[i], a0)
            var p01 := _lathe(prof[i], a1)
            var p10 := _lathe(prof[i + 1], a0)
            var p11 := _lathe(prof[i + 1], a1)
            for v in [p00, p10, p11, p00, p11, p01]:
                st.add_vertex(toilet_pos + v * S)
    st.generate_normals()
    var bowl := MeshInstance3D.new()
    bowl.mesh = st.commit()
    porc.cull_mode = BaseMaterial3D.CULL_DISABLED
    bowl.material_override = porc
    add_child(bowl)
    # Cistern behind it, with a flush handle.
    _box(_r(0.44, 0.42, 0.17), toilet_pos + _r(0, 0.62, -0.42), porc)
    _box(_r(0.46, 0.03, 0.19), toilet_pos + _r(0, 0.845, -0.42), porc)
    _box(_r(0.06, 0.02, 0.03), toilet_pos + _r(-0.14, 0.78, -0.33), _mat(Color(0.8, 0.8, 0.82), 0.2))
    # Water on the bowl floor (shallow; the soldiers stand in it).
    var water := MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.top_radius = 0.11 * S
    cm.bottom_radius = 0.11 * S
    cm.height = 0.004 * S
    water.mesh = cm
    var wm := _mat(Color(0.55, 0.78, 0.9, 0.6), 0.05)
    wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    water.material_override = wm
    add_child(water)
    water.position = toilet_pos + _r(0, 0.202, 0)
    water.scale = Vector3(1, 1, OVAL)
    # The paper roll on its holder, on the wall to the right.
    _paper_holder(toilet_pos + _r(0.36, 0.62, -0.5))


func _lathe(pr: Array, a: float) -> Vector3:
    return Vector3(cos(a) * pr[0], pr[1], sin(a) * pr[0] * OVAL)


func _paper_holder(p: Vector3) -> void:
    var chrome := _mat(Color(0.82, 0.83, 0.86), 0.15)
    chrome.metallic = 0.9
    var arm := _box(_r(0.16, 0.012, 0.012), p + _r(0, 0, 0.06), chrome)
    var roll := MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.top_radius = 0.055 * S
    cm.bottom_radius = 0.055 * S
    cm.height = 0.11 * S
    roll.mesh = cm
    roll.material_override = _mat(Color(0.98, 0.98, 0.96), 0.95)
    add_child(roll)
    roll.position = p + _r(0, 0, 0.06)
    roll.rotation.z = PI / 2
    roll.name = "Roll"
    var tail := _box(_r(0.11, 0.18, 0.004), p + _r(0, -0.09, 0.115), _mat(Color(0.98, 0.98, 0.96), 0.95))
    tail.name = "RollTail"


## The ramp you buy: the roll tips off, bounces into the bowl and leaves a strip
## of paper from the water, up the inside, over the front rim and down to the
## floor. Real toilet paper is 11 cm wide, so it's a 4.4-unit walkway.
func _ramp() -> void:
    var path := [[0.2, 0.04], [0.235, 0.17], [0.29, 0.212], [0.35, 0.237], [0.4, 0.25], [0.414, 0.28], [0.414, 0.32], [0.38, 0.35], [0.25, 0.42], [0.12, 0.5], [0.02, 0.62], [0.002, 0.78]]
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var w := 0.11 * S * 0.5
    var along := 0.0
    for i in path.size() - 1:
        var a := toilet_pos + _r(0, path[i][0] + 0.004, path[i][1])
        var b := toilet_pos + _r(0, path[i + 1][0] + 0.004, path[i + 1][1])
        var seg := a.distance_to(b)
        var n := (b - a).cross(Vector3.RIGHT).normalized()
        if n.y < 0.0:
            n = -n
        for v in [[a, -w, along], [a, w, along], [b, w, along + seg], [a, -w, along], [b, w, along + seg], [b, -w, along + seg]]:
            st.set_normal(n)
            st.set_uv(Vector2((v[1] + w) / (2.0 * w), v[2] / (0.12 * S)))
            st.add_vertex(v[0] + Vector3(v[1], 0, 0))
        along += seg
    var mi := MeshInstance3D.new()
    mi.mesh = st.commit()
    var pm := _mat(Color(1.0, 0.9, 0.68), 1.0)
    pm.albedo_texture = _perforation()
    pm.cull_mode = BaseMaterial3D.CULL_DISABLED
    mi.material_override = pm
    add_child(mi)
    # The roll, ended up on the floor at the bottom of the ramp.
    var roll := find_child("Roll", true, false)
    if roll:
        roll.position = toilet_pos + _r(0, 0.03, 0.82)
        roll.scale = Vector3(1, 1, 1) * 0.55
    var tail := find_child("RollTail", true, false)
    if tail:
        tail.visible = false


func _perforation() -> ImageTexture:
    var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
    img.fill(Color(0.98, 0.98, 0.96))
    for x in range(0, 64, 4):
        img.set_pixel(x, 0, Color(0.78, 0.78, 0.76))
        img.set_pixel(x + 1, 0, Color(0.78, 0.78, 0.76))
    for y in 64:                      # quilted dimples
        for x in 64:
            if (x + y) % 16 == 0 or (x - y + 64) % 16 == 0:
                img.set_pixel(x, y, Color(0.93, 0.93, 0.91))
    return ImageTexture.create_from_image(img)


## A crack in the porcelain: a dark jagged star on the bowl's inside wall, with
## a Melty pushing through. patched = already repaired with white plaster.
## A crack on the bowl's inside wall, at an angle around the bowl (0 = right,
## 90 = front) and a height in metres.
func _crack_at(deg: float, y: float, patched: bool) -> void:
    var a := deg_to_rad(deg)
    var r := 0.1
    for i in BOWL_IN.size() - 1:
        if y >= BOWL_IN[i][1] and y <= BOWL_IN[i + 1][1]:
            r = lerpf(BOWL_IN[i][0], BOWL_IN[i + 1][0], (y - BOWL_IN[i][1]) / (BOWL_IN[i + 1][1] - BOWL_IN[i][1]))
    var local := Vector3(cos(a) * r, y, sin(a) * r * OVAL)
    var facing := -Vector3(cos(a), -0.35, sin(a)).normalized()
    _crack(local, facing, patched)


func _crack(local: Vector3, facing: Vector3, patched: bool) -> void:
    var p := toilet_pos + local * S
    var q := MeshInstance3D.new()
    var qm := QuadMesh.new()
    qm.size = Vector2(0.1, 0.085) * S
    q.mesh = qm
    var m := StandardMaterial3D.new()
    m.albedo_texture = _crack_tex(patched)
    m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
    m.roughness = 0.5
    q.material_override = m
    add_child(q)
    q.global_position = p + facing * 0.004 * S
    q.look_at(q.global_position + facing, Vector3.UP)
    q.rotate_object_local(Vector3.UP, PI)
    if not patched:
        # A Melty shoving through the hole: half a tan soldier, arms out.
        var mel = _soldier(MELT.darkened(0.1), "Walk", 0.3, p + facing * 0.6 + Vector3(0, -0.9, 0), 0.0, "none")
        var flat := Vector3(facing.x, 0, facing.z).normalized()
        mel.look_at(mel.global_position - flat, Vector3.UP)
        mel.rotation.x = -0.5
        mel.scale = Vector3.ONE * 1.1
        # porcelain chunks breaking off
        for i in 5:
            var ch := _box(Vector3(0.35, 0.25, 0.3), p + facing * (0.4 + i * 0.25) + Vector3(randf_range(-1.6, 1.6), randf_range(-1.2, 0.6), randf_range(-1.6, 1.6)), _mat(Color(0.97, 0.97, 0.98), 0.15))
            ch.rotation = Vector3(randf(), randf(), randf()) * 2.0


func _crack_tex(patched: bool) -> ImageTexture:
    var img := Image.create(128, 104, false, Image.FORMAT_RGBA8)
    img.fill(Color(0, 0, 0, 0))
    var c := Vector2(64, 52)
    if patched:
        # rough white plaster blob with a trowel edge
        for y in 104:
            for x in 128:
                var d := Vector2(x, y).distance_to(c) / 44.0 + sin(x * 0.3) * 0.05 + cos(y * 0.4) * 0.05
                if d < 1.0:
                    var shade := 0.93 + 0.05 * sin(x * 0.7 + y * 0.2)
                    img.set_pixel(x, y, Color(shade, shade, shade * 0.98))
        return ImageTexture.create_from_image(img)
    seed(3)
    # dark hole in the middle, jagged cracks running out of it
    for y in 104:
        for x in 128:
            var d := Vector2(x, y).distance_to(c)
            if d < 26 + 7 * sin(atan2(y - 52, x - 64) * 5.0):
                img.set_pixel(x, y, Color(0.08, 0.06, 0.05))
    for k in 9:
        var a := k * TAU / 9.0 + randf() * 0.3
        var p := c
        for s in 14:
            a += randf_range(-0.5, 0.5)
            var n := p + Vector2(cos(a), sin(a)) * 4.0
            for t in 5:
                var q := p.lerp(n, t / 5.0)
                if q.x >= 1 and q.y >= 1 and q.x < 127 and q.y < 103:
                    img.set_pixel(int(q.x), int(q.y), Color(0.2, 0.2, 0.22))
                    img.set_pixel(int(q.x) + 1, int(q.y), Color(0.35, 0.35, 0.37))
            p = n
    return ImageTexture.create_from_image(img)


# --------------------------------------------------------------- props ----

func _props() -> void:
    var K := "kenney/furniture_kit/x/Models/GLTF format/"
    var T := "opengameart/isa_lousberg_tiny_treats_bathroom/x/Tiny_Treats_Bubbly_Bathroom_1.0/Assets/gltf/"
    var P := "polyhaven/"
    _place(K + "bathtub.glb", ["w", 1.7], _r(-0.74, 0, 0.88), 90.0)
    _place(K + "bathroomCabinetDrawer.glb", ["h", 0.82], _r(0.84, 0, 0.75), -90.0)
    _place(K + "bathroomSink.glb", ["w", 0.5], _r(0.84, 0.82, 0.75), -90.0)
    _place(K + "bathroomMirror.glb", ["w", 0.6], _r(1.09, 1.45, 0.75), -90.0)
    _place(K + "trashcan.glb", ["h", 0.3], _r(0.55, 0, 0.16))
    _place(P + "rubber_duck_toy/rubber_duck_toy_1k.glb", ["h", 0.11], _r(-0.25, 0, 1.05), 140.0)
    _place(P + "rubber_duck_toy/rubber_duck_toy_1k.glb", ["h", 0.09], _r(-0.62, 0.56, 1.3), 60.0)      # on the tub rim
    _place(P + "plunger/plunger_1k.glb", ["h", 0.48], _r(0.4, 0, 0.1), 20.0)
    _place(K + "rugRounded.glb", ["w", 0.75], _r(-0.18, 0, 1.45), 90.0)
    _place(T + "slippers.glb", ["w", 0.3], _r(0.38, 0, 1.15), -25.0)
    _place(T + "towel_stacked.glb", ["h", 0.18], _r(0.72, 0, 1.45), 10.0)
    _place(T + "towel_blue.glb", ["w", 0.45], _r(0.05, 0, 1.95), 35.0)
    _place(T + "towel_pink.glb", ["w", 0.4], _r(0.18, 0.04, 2.02), -50.0)
    _place(T + "toothbrush_cup.glb", ["h", 0.11], _r(0.9, 0.84, 0.48))
    _place(T + "toothbrush_blue.glb", ["w", 0.17], _r(0.9, 0.88, 0.48), 15.0)
    _place(T + "container_bathroom_A_blue.glb", ["h", 0.2], _r(0.92, 0.84, 1.0))
    _place(T + "container_bathroom_C_pink.glb", ["h", 0.18], _r(-0.4, 0.56, 1.62))
    _place(T + "container_bathroom_B_yellow.glb", ["h", 0.2], _r(-0.4, 0.56, 1.5))
    _place(P + "bleach_bottle/bleach_bottle_1k.glb", ["h", 0.27], _r(0.62, 0, 2.3), 30.0)
    _place(P + "wicker_basket_01/wicker_basket_01_1k.glb", ["w", 0.45], _r(-0.85, 0, 2.35))
    # A crumpled towel (built in code: a lumpy heap).
    var tm := _mat(Color(0.95, 0.85, 0.35), 0.95)
    for i in 7:
        var sm := SphereMesh.new()
        sm.radius = randf_range(0.06, 0.1) * S
        sm.height = sm.radius * randf_range(0.6, 1.0)
        var b := MeshInstance3D.new()
        b.mesh = sm
        b.material_override = tm
        add_child(b)
        b.position = _r(-0.45 + randf_range(-0.12, 0.12), 0.02, 2.05 + randf_range(-0.1, 0.1))


func _ceiling_lights() -> void:
    for i in 2:
        var p := _r(-0.35 + i * 0.75, 2.4, 1.15)
        var lamp := _place("polyhaven/modern_ceiling_lamp_01/modern_ceiling_lamp_01_1k.glb", ["w", 0.32], p - _r(0, 0.3, 0))
        var bulb := MeshInstance3D.new()
        var sm := SphereMesh.new()
        sm.radius = 0.07 * S
        sm.height = 0.14 * S
        bulb.mesh = sm
        var on := i == 0
        bulb.material_override = _mat(Color(1.0, 0.95, 0.8), 0.2, 4.0 if on else 0.4)
        add_child(bulb)
        bulb.position = p - _r(0, 0.33, 0)
        var l := OmniLight3D.new()
        l.light_color = Color(1.0, 0.93, 0.8)
        l.light_energy = 2.2 if on else 0.25    # the right one is mid-flicker
        l.omni_range = 3.0 * S
        l.omni_attenuation = 0.8
        l.shadow_enabled = on
        add_child(l)
        l.position = p - _r(0, 0.3, 0)
        lights.append(l)


# --------------------------------------------------------------- shots ----

func _shot_bowl() -> void:
    caption.text = "1  -  INSIDE THE BOWL: Melties crack through the porcelain; plaster the cracks to hold them off"
    _crack_at(55.0, 0.29, false)
    _crack_at(125.0, 0.3, false)
    _crack_at(90.0, 0.33, true)
    var sign := Label3D.new()
    sign.text = "TOILET PAPER RAMP\n1500 COINS"
    sign.font_size = 160
    sign.outline_size = 30
    sign.modulate = Color(1, 0.92, 0.5)
    sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    add_child(sign)
    sign.position = toilet_pos + _r(0.36, 0.74, -0.44)
    sign.name = "Sign"
    shot1_guys = [
        _soldier(GREEN, "Idle_Shoot", 0.3, toilet_pos + _r(0.04, 0.202, 0.03), 210.0),
        _soldier(GREEN, "Idle_Shoot", 0.5, toilet_pos + _r(-0.05, 0.202, 0.05), 150.0),
        _soldier(GREEN, "Idle", 0.2, toilet_pos + _r(0.0, 0.202, -0.04), 180.0)]
    cam.fov = 84
    cam.fov = 72
    cam.position = toilet_pos + _r(0.0, 0.33, -0.2)
    cam.look_at(toilet_pos + _r(0.0, 0.24, 0.12))
    await _snap("bath_1")


func _shot_ramp() -> void:
    caption.text = "2  -  BUY THE PAPER: the roll tips off, rolls into the bowl and unrolls a ramp up and over the rim"
    var sign := find_child("Sign", true, false)
    if sign:
        sign.queue_free()
    for g in shot1_guys:
        g.queue_free()
    _ramp()
    _soldier(GREEN, "Run", 0.2, toilet_pos + _r(0, 0.3, 0.222), 180.0)
    _soldier(GREEN, "Run", 0.5, toilet_pos + _r(0.012, 0.236, 0.172), 180.0)
    _soldier(GREEN, "Run", 0.7, toilet_pos + _r(-0.01, 0.204, 0.08), 180.0)
    cam.fov = 84
    cam.position = toilet_pos + _r(0.025, 0.218, -0.05)
    cam.look_at(toilet_pos + _r(0.0, 0.4, 0.3))
    await _snap("bath_2")


func _shot_floor() -> void:
    caption.text = "3  -  OVER THE RIM: the giant bathroom - tub, sink, rubber duck, towels, bath mat, slippers"
    _soldier(GREEN, "Run", 0.3, toilet_pos + _r(0.0, 0.414, 0.3), 0.0)
    _soldier(GREEN, "Run", 0.6, toilet_pos + _r(0.005, 0.253, 0.418), 0.0)
    var mel = _soldier(MELT, "Walk", 0.4, _r(-0.15, 0, 1.3), 160.0, "none")
    var mel2 = _soldier(MELT.darkened(0.15), "Walk", 0.1, _r(0.3, 0, 1.6), 200.0, "none")
    cam.fov = 64
    cam.fov = 70
    cam.position = toilet_pos + _r(0.12, 0.6, 0.1)
    cam.look_at(_r(-0.15, 0.0, 1.55))
    await _snap("bath_3")


func _shot_ceiling() -> void:
    caption.text = "4  -  LOOK UP: giant ceiling lights - they flicker, and go dark for a moment during big waves"
    cam.fov = 75
    cam.position = _r(0.3, 0.12, 0.85)
    cam.look_at(_r(0.05, 2.2, 1.2))
    await _snap("bath_4")
