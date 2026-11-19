extends Node3D
## 3D mockups (not used by the game):
##   held_A/B/C.png   the Crayon Box weapon in a soldier's hands, 3 styles
##   army_A/B/C.png   3 looks for the zombie army
##   boss_A/B/C.png   3 looks for the final boss
## xvfb-run godot --path . res://tests/_army_mockup.tscn -- <outdir>

const Soldier = preload("res://scripts/plastic_soldier.gd")
const Draw = preload("res://tests/_crayon_ui_mockup.gd")
const DAMAGE := preload("res://assets/shaders/plastic_damage.gdshader")
const GREEN := Color(0.27, 0.48, 0.17)

var out := ""
var cam: Camera3D
var env: Environment
var sun: DirectionalLight3D
var stage: Node3D                 # everything for one shot; freed between shots
var caption: Label
var drawer                        # the 2D mockup script, used only for its crayon drawing code


class Paint extends Control:
    var fn: Callable
    func _draw() -> void:
        fn.call(self)


func _ready() -> void:
    out = OS.get_cmdline_user_args()[0]
    drawer = Draw.new()
    var we := WorldEnvironment.new()
    env = Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    we.environment = env
    add_child(we)
    sun = DirectionalLight3D.new()
    sun.shadow_enabled = true
    add_child(sun)
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
    for v in ["A", "B", "C"]:
        await _shot("held_" + v, Callable(self, "_held").bind(v))
    for v in ["A", "B", "C"]:
        await _shot("army_" + v, Callable(self, "_army").bind(v))
    for v in ["A", "B", "C"]:
        await _shot("boss_" + v, Callable(self, "_boss").bind(v))
    drawer.free()
    get_tree().quit()


func _shot(file: String, build: Callable) -> void:
    if stage:
        stage.queue_free()
    await get_tree().process_frame
    seed(11)
    stage = Node3D.new()
    add_child(stage)
    await build.call()
    for i in 6:
        await get_tree().process_frame
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, file])


# ------------------------------------------------------------- helpers ----

func _mat(c: Color, rough := 0.35, emit := 0.0, metal := 0.0) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.roughness = rough
    m.metallic = metal
    m.metallic_specular = 0.6
    if emit > 0.0:
        m.emission_enabled = true
        m.emission = c
        m.emission_energy_multiplier = emit
    return m


func _mesh(mesh: Mesh, m: Material, parent: Node, gpos: Vector3) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    mi.mesh = mesh
    mi.material_override = m
    parent.add_child(mi)
    if parent is BoneAttachment3D:
        mi.top_level = true            # don't inherit the soldier's scale twice
    mi.global_position = gpos
    return mi


func _sphere(r: float, h := -1.0) -> SphereMesh:
    var s := SphereMesh.new()
    s.radius = r
    s.height = r * 2.0 if h < 0.0 else h
    return s


func _box(sz: Vector3) -> BoxMesh:
    var b := BoxMesh.new()
    b.size = sz
    return b


func _cyl(top: float, bottom: float, h: float) -> CylinderMesh:
    var c := CylinderMesh.new()
    c.top_radius = top
    c.bottom_radius = bottom
    c.height = h
    return c


## A soldier frozen in a pose. anim_t is how far into the animation.
func _soldier(col: Color, kind: String, anim_name: String, anim_t: float, pos: Vector3, yaw_deg: float, sc := 1.0):
    var s = Soldier.create()
    stage.add_child(s)
    s.build(col, kind)
    s.position = pos
    s.rotation.y = deg_to_rad(yaw_deg)
    s.scale = Vector3.ONE * sc
    s.set_process(false)
    s.set_physics_process(false)
    s._play(anim_name)
    s.anim.seek(anim_t, true)
    s.anim.pause()
    return s


func _bone(s, bname: String) -> Transform3D:
    var sk: Skeleton3D = s.skeleton
    return sk.global_transform * sk.get_bone_global_pose(sk.find_bone(bname))


func _attach(s, bname: String) -> BoneAttachment3D:
    var ba := BoneAttachment3D.new()
    s.skeleton.add_child(ba)
    ba.bone_name = bname
    return ba


func _fwd(s) -> Vector3:
    return -s.global_basis.z.normalized()


func _right(s) -> Vector3:
    return s.global_basis.x.normalized()


## Paint a 2D picture into a texture.
func _texture(size_px: Vector2i, fn: Callable) -> Texture2D:
    var vp := SubViewport.new()
    vp.size = size_px
    vp.transparent_bg = true
    vp.render_target_update_mode = SubViewport.UPDATE_ONCE
    stage.add_child(vp)
    var p := Paint.new()
    p.fn = fn
    p.size = Vector2(size_px)
    vp.add_child(p)
    return vp.get_texture()


func _floor(col: Color, size := 40.0) -> void:
    var pm := PlaneMesh.new()
    pm.size = Vector2(size, size)
    _mesh(pm, _mat(col, 0.85), stage, Vector3.ZERO)


func _wall(col: Color, z: float, w := 40.0, h := 12.0) -> void:
    _mesh(_box(Vector3(w, h, 0.4)), _mat(col, 0.9), stage, Vector3(0, h * 0.5, z))


func _lighting(bg: Color, amb: Color, amb_e: float, sun_rot: Vector3, sun_e: float, sun_col := Color.WHITE) -> void:
    env.background_color = bg
    env.ambient_light_color = amb
    env.ambient_light_energy = amb_e
    env.fog_enabled = false
    sun.rotation_degrees = sun_rot
    sun.light_energy = sun_e
    sun.light_color = sun_col


func _omni(pos: Vector3, col: Color, energy: float, rng: float) -> void:
    var l := OmniLight3D.new()
    l.light_color = col
    l.light_energy = energy
    l.omni_range = rng
    stage.add_child(l)
    l.global_position = pos


# --------------------------------------------------- the crayon weapon ----

const PX := 0.009            # drawing pixel -> gun-mesh units
const X0 := -1.25
const Y0 := 1.05


func _lp(p: Vector2) -> Vector2:
    return Vector2(X0 + p.x * PX, Y0 - p.y * PX)


func _held(v: String) -> void:
    _lighting(Color(0.2, 0.18, 0.16), Color(0.62, 0.6, 0.58), 0.75, Vector3(-35, 60, 0), 1.25, Color(1, 0.96, 0.9))
    _floor(Color(0.4, 0.36, 0.3))
    _wall(Color(0.5, 0.46, 0.4), -6.0)
    var s = _soldier(GREEN, "rifle", "Idle_Shoot", 0.6, Vector3.ZERO, 0)
    await get_tree().process_frame
    var gun: MeshInstance3D = s._current_gun
    gun.visible = false
    var holder := Node3D.new()
    gun.get_parent().add_child(holder)
    holder.transform = gun.transform
    # Point the drawing's muzzle the same way as the real gun's.
    var muzzle: Vector3 = holder.to_local(s.get_muzzle_position())
    if muzzle.x < 0.0:
        holder.rotate_object_local(Vector3.UP, PI)
    # Level the gun out (this pose holds it pointing at the floor).
    for i in 2:
        var dir := (holder.to_global(Vector3.RIGHT) - holder.global_position).normalized()
        var pitch := asin(dir.y) - deg_to_rad(4.0)
        holder.rotate_object_local(Vector3.BACK, -pitch)
        var nd := (holder.to_global(Vector3.RIGHT) - holder.global_position).normalized()
        if absf(nd.y) > absf(dir.y):
            holder.rotate_object_local(Vector3.BACK, 2.0 * pitch)
    var lines_only: bool = v != "A"
    var tex := _texture(Vector2i(880, 460), func(c):
        c.draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))
        if not lines_only:
            var paper := Color(0.98, 0.97, 0.92)
            c.draw_colored_polygon(PackedVector2Array(Draw.GUN.map(func(p): return p + Vector2(0, 0))), paper)
            c.draw_colored_polygon(PackedVector2Array(Draw.SCOPE), paper)
            c.draw_circle(Vector2(190, 100), 34, paper)
        seed(5)
        drawer._gun_drawing(c, Vector2.ZERO, 1.0))
    var dm := StandardMaterial3D.new()
    dm.albedo_texture = tex
    dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
    dm.alpha_scissor_threshold = 0.3
    dm.cull_mode = BaseMaterial3D.CULL_DISABLED
    dm.roughness = 0.9
    var qm := QuadMesh.new()
    qm.size = Vector2(440 * PX, 230 * PX)
    var qctr := Vector3(_lp(Vector2(220, 115)).x, _lp(Vector2(220, 115)).y, 0)
    var thick := 0.03 if v == "A" else 0.36
    match v:
        "A":
            caption.text = "A  -  PAPER CUTOUT: your drawing, cut out and held like a cardboard toy"
            var q := MeshInstance3D.new()
            q.mesh = qm
            q.material_override = dm
            holder.add_child(q)
            q.position = qctr
        "B":
            caption.text = "B  -  CRAYON WAX: your drawing pressed into a thick block of crayon"
            _extrude(holder, Draw.GUN, thick, _mat(Color(0.86, 0.22, 0.17), 0.8))
            _extrude(holder, Draw.SCOPE, thick * 0.7, _mat(Color(0.22, 0.42, 0.88), 0.8))
            _drum(holder, thick * 1.2, _mat(Color(0.98, 0.72, 0.2), 0.8))
            for side in [-1.0, 1.0]:
                var q := MeshInstance3D.new()
                q.mesh = qm
                q.material_override = dm
                holder.add_child(q)
                q.position = qctr + Vector3(0, 0, side * (thick * 0.5 + 0.01))
            # chunky wax ridges
            for i in 7:
                _mesh(_box(Vector3(0.05, 0.5, thick + 0.04)), _mat(Color(0.75, 0.16, 0.12), 0.8), holder, Vector3.ZERO).position = Vector3(_lp(Vector2(60 + i * 26, 100)).x, _lp(Vector2(0, 100)).y, 0)
        "C":
            caption.text = "C  -  TOY PLASTIC: your drawing rebuilt as a shiny plastic toy gun"
            _extrude(holder, Draw.GUN, thick, _mat(Color(0.86, 0.18, 0.14), 0.25))
            _extrude(holder, Draw.SCOPE, thick * 0.7, _mat(Color(0.2, 0.4, 0.9), 0.25))
            _drum(holder, thick * 1.3, _mat(Color(1.0, 0.8, 0.15), 0.25))
            var barrel := _mesh(_cyl(0.2, 0.2, 0.9), _mat(Color(0.4, 0.42, 0.45), 0.3, 0.0, 0.3), holder, Vector3.ZERO)
            barrel.rotation = Vector3(0, 0, PI / 2)
            barrel.position = Vector3(_lp(Vector2(345, 92)).x, _lp(Vector2(0, 92)).y, 0)
            for side in [-1.0, 1.0]:
                var fl := MeshInstance3D.new()
                fl.mesh = qm
                var fm := StandardMaterial3D.new()
                fm.albedo_texture = _texture(Vector2i(880, 460), func(c):
                    c.draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))
                    var pts := [Vector2(48, 116), Vector2(70, 92), Vector2(78, 110), Vector2(96, 86), Vector2(104, 112), Vector2(120, 94), Vector2(124, 124)]
                    c.draw_colored_polygon(PackedVector2Array(pts), Color(1.0, 0.55, 0.1)))
                fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
                fm.cull_mode = BaseMaterial3D.CULL_DISABLED
                fl.material_override = fm
                holder.add_child(fl)
                fl.position = qctr + Vector3(0, 0, side * (thick * 0.5 + 0.01))
    var gp: Vector3 = gun.global_position
    cam.fov = 40
    cam.position = gp + _right(s) * 2.9 + Vector3(0, 0.45, 0) + _fwd(s) * 0.5
    cam.look_at(gp + Vector3(0, 0.3, 0) + _fwd(s) * 0.25)


func _extrude(holder: Node3D, pts: Array, depth: float, m: Material) -> void:
    var poly := CSGPolygon3D.new()
    poly.polygon = PackedVector2Array(pts.map(func(p): return _lp(p)))
    poly.depth = depth
    poly.material = m
    holder.add_child(poly)
    poly.position = Vector3(0, 0, depth * 0.5)


func _drum(holder: Node3D, depth: float, m: Material) -> void:
    var d := MeshInstance3D.new()
    d.mesh = _cyl(30 * PX, 30 * PX, depth)
    d.material_override = m
    holder.add_child(d)
    var c := _lp(Vector2(190, 100))
    d.position = Vector3(c.x, c.y, 0)
    d.rotation = Vector3(PI / 2, 0, 0)


# ------------------------------------------------------- emblems (2D) ----

## Made-up army symbols. A: melted gear. B: claw marks. C: cracked crown.
func _emblem(v: String, col: Color) -> Texture2D:
    return _texture(Vector2i(256, 256), Callable(self, "_emblem_paint").bind(v, col))


func _emblem_paint(c: CanvasItem, v: String, col: Color) -> void:
    var ctr := Vector2(128, 128)
    match v:
        "A":
            var pts := PackedVector2Array()
            for i in 48:
                var a := i * TAU / 48.0
                var r := 92.0 if (i / 3) % 2 == 0 else 74.0
                pts.append(ctr + Vector2(cos(a), sin(a)) * r)
            c.draw_colored_polygon(pts, col)
            c.draw_circle(ctr, 40, Color(0, 0, 0, 0))
            c.draw_circle(ctr, 40, Color(0.08, 0.08, 0.08))
            # drips running off the bottom
            for d in [[-40, 70], [8, 100], [44, 60]]:
                c.draw_rect(Rect2(ctr.x + d[0] - 9, ctr.y + 60, 18, d[1] * 0.6), col)
                c.draw_circle(Vector2(ctr.x + d[0], ctr.y + 60 + d[1] * 0.6), 11, col)
        "B":
            c.draw_arc(ctr, 100, 0, TAU, 64, col, 16.0)
            for k in 3:
                var o := Vector2(-48 + k * 48, 0)
                c.draw_colored_polygon(PackedVector2Array([ctr + o + Vector2(-30, -78), ctr + o + Vector2(-12, -80), ctr + o + Vector2(30, 78), ctr + o + Vector2(18, 80)]), col)
        "C":
            var crown := PackedVector2Array([Vector2(36, 190), Vector2(36, 80), Vector2(80, 130), Vector2(128, 50), Vector2(176, 130), Vector2(220, 80), Vector2(220, 190)])
            c.draw_colored_polygon(crown, col)
            c.draw_polyline(PackedVector2Array([Vector2(128, 60), Vector2(112, 110), Vector2(140, 135), Vector2(116, 190)]), Color(0.06, 0.06, 0.06), 9.0)
            for x in [70, 128, 186]:
                c.draw_circle(Vector2(x, 168), 10, Color(0.06, 0.06, 0.06))

func _banner(v: String, cloth: Color, sym: Color, pos: Vector3) -> void:
    var b := _mesh(_box(Vector3(1.7, 3.4, 0.04)), _mat(cloth, 0.95), stage, pos)
    var q := MeshInstance3D.new()
    var qm := QuadMesh.new()
    qm.size = Vector2(1.3, 1.3)
    q.mesh = qm
    var m := StandardMaterial3D.new()
    m.albedo_texture = _emblem(v, sym)
    m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
    m.roughness = 0.9
    q.material_override = m
    b.add_child(q)
    q.position = Vector3(0, 0.45, 0.03)
    # tattered bottom edge
    for i in 5:
        var t := _mesh(_box(Vector3(0.3, randf_range(0.2, 0.5), 0.04)), _mat(cloth, 0.95), b, Vector3.ZERO)
        t.position = Vector3(-0.68 + i * 0.34, -1.75 - randf_range(0.0, 0.15), 0)
    _mesh(_cyl(0.04, 0.04, 2.0), _mat(Color(0.3, 0.22, 0.14), 0.8), b, Vector3.ZERO).position = Vector3(0, 1.72, 0)
    b.get_child(b.get_child_count() - 1).rotation = Vector3(0, 0, PI / 2)


# ----------------------------------------------------- zombie soldiers ----

func _eyes(s, col: Color, r := 0.032, energy := 4.0) -> void:
    var h := _bone(s, "Head").origin
    var at := _attach(s, "Head")
    for side in [-1.0, 1.0]:
        _mesh(_sphere(r * 1.3 * s.scale.x), _mat(col, 0.2, energy), at, h + _fwd(s) * 0.33 * s.scale.x + Vector3(0, 0.13, 0) * s.scale.x + _right(s) * side * 0.1 * s.scale.x)


func _gas_mask(s) -> void:
    var k: float = s.scale.x
    var h := _bone(s, "Head").origin
    var at := _attach(s, "Head")
    var f := _fwd(s)
    var dark := _mat(Color(0.1, 0.1, 0.1), 0.5)
    var face := _mesh(_sphere(0.27 * k, 0.32 * k), _mat(Color(0.22, 0.23, 0.2), 0.6), at, h + f * 0.17 * k + Vector3(0, 0.06, 0) * k)
    face.scale = Vector3(1.0, 1.0, 0.8)
    var snout := _mesh(_cyl(0.06 * k, 0.09 * k, 0.14 * k), dark, at, h + f * 0.42 * k - Vector3(0, 0.03, 0) * k)
    snout.look_at(snout.global_position + f, Vector3.UP)
    snout.rotate_object_local(Vector3.RIGHT, PI / 2)
    var can := _mesh(_cyl(0.08 * k, 0.08 * k, 0.15 * k), _mat(Color(0.32, 0.34, 0.26), 0.5), at, h + f * 0.44 * k - Vector3(0, 0.16, 0) * k)
    can.rotation.x = 0.4
    for side in [-1.0, 1.0]:
        var lens := _mesh(_cyl(0.065 * k, 0.065 * k, 0.03 * k), _mat(Color(1.0, 0.1, 0.05), 0.2, 1.6), at, h + f * 0.38 * k + Vector3(0, 0.13, 0) * k + _right(s) * side * 0.11 * k)
        lens.look_at(lens.global_position + f, Vector3.UP)
        lens.rotate_object_local(Vector3.RIGHT, PI / 2)


func _spike(s, col: Color) -> void:
    var k: float = s.scale.x
    var at := _attach(s, "Head")
    var h := _bone(s, "Head").origin
    _mesh(_cyl(0.0, 0.05 * k, 0.22 * k), _mat(col, 0.3, 0.0, 0.6), at, h + Vector3(0, 0.68, 0) * k)


func _drips(s, col: Color, n: int) -> void:
    var k: float = s.scale.x
    var at := _attach(s, "Torso")
    var t := _bone(s, "Torso").origin
    for i in n:
        var d := _mesh(_sphere(randf_range(0.04, 0.07) * k), _mat(col, 0.15), at, t + Vector3(randf_range(-0.2, 0.2), randf_range(-0.1, 0.35), 0) * k + _fwd(s) * 0.15 * k)
        d.scale = Vector3(1, randf_range(1.6, 2.6), 1)


func _armband(s, col: Color) -> void:
    var k: float = s.scale.x
    var tr := _bone(s, "UpperArm.L")
    var at := _attach(s, "UpperArm.L")
    var ring := _mesh(_cyl(0.085 * k, 0.085 * k, 0.07 * k), _mat(col, 0.6), at, tr.origin + tr.basis.y.normalized() * 0.12 * k)
    ring.global_basis = Basis(tr.basis.x.normalized(), tr.basis.y.normalized(), tr.basis.z.normalized())


func _overlay(s, style: int, wear: float, n: int) -> void:
    var m := ShaderMaterial.new()
    m.shader = DAMAGE
    m.set_shader_parameter("style", style)
    m.set_shader_parameter("base_color", s.body_color)
    var arr: Array = []
    for b in ["Torso", "Head", "UpperLeg.L", "ShoulderPad.R", "LowerArm.L", "UpperLeg.R", "Abdomen", "UpperArm.R"]:
        var p: Vector3 = _bone(s, b).origin + _fwd(s) * 0.15 * s.scale.x
        arr.append(Vector4(p.x, p.y, p.z, randf_range(0.18, 0.3) * s.scale.x))
    m.set_shader_parameter("hits", arr)
    m.set_shader_parameter("hit_count", n)
    m.set_shader_parameter("wear", wear)
    for mi in s.find_children("*", "MeshInstance3D", true, false):
        if mi.is_visible_in_tree() and mi.get_parent() is not BoneAttachment3D or mi.get_parent().get_parent() != s.skeleton:
            pass
    for mi in s.rig.find_children("*", "MeshInstance3D", true, false):
        if mi.is_visible_in_tree():
            mi.material_overlay = m


func _army(v: String) -> void:
    var looks := {
        "A": {"name": "A  -  GAS MASK GHOULS: charcoal plastic, gas masks, red glowing eyes",
            "col": Color(0.2, 0.21, 0.22), "cloth": Color(0.16, 0.2, 0.1), "sym": Color(0.82, 0.86, 0.2), "band": Color(0.82, 0.86, 0.2)},
        "B": {"name": "B  -  GRAVE GREY: rotten grey-green plastic, spiked helmets, green eyes",
            "col": Color(0.5, 0.55, 0.47), "cloth": Color(0.24, 0.16, 0.3), "sym": Color(0.6, 0.95, 0.4), "band": Color(0.36, 0.22, 0.44)},
        "C": {"name": "C  -  BURNT BLACK: charred plastic with glowing ember cracks",
            "col": Color(0.1, 0.09, 0.09), "cloth": Color(0.08, 0.07, 0.07), "sym": Color(1.0, 0.45, 0.08), "band": Color(1.0, 0.45, 0.08)},
    }
    var L: Dictionary = looks[v]
    caption.text = L["name"]
    _lighting(Color(0.07, 0.07, 0.09), Color(0.62, 0.64, 0.72), 0.8, Vector3(-30, 160, 0), 1.2, Color(0.9, 0.92, 1.0))
    _floor(Color(0.28, 0.26, 0.24))
    _wall(Color(0.3, 0.29, 0.28), -4.5)
    _banner(v, L["cloth"], L["sym"], Vector3(0, 2.3, -4.2))
    var poses := [["Walk", 0.35, Vector3(-1.3, 0, -0.6), -150.0], ["Idle", 0.2, Vector3(0, 0, 0.2), 180.0], ["Run", 0.25, Vector3(1.35, 0, -0.4), 160.0]]
    var guys := []
    for i in 3:
        var p: Array = poses[i]
        var s = _soldier(L["col"], "none", p[0], p[1], p[2], p[3])
        s.rig.rotation.x = deg_to_rad(10.0 if i != 1 else 4.0)
        guys.append(s)
    await get_tree().process_frame
    await get_tree().process_frame
    for s in guys:
        match v:
            "A":
                _gas_mask(s)
                _armband(s, L["band"])
            "B":
                _eyes(s, Color(0.4, 1.0, 0.2), 0.032, 1.6)
                _spike(s, Color(0.35, 0.37, 0.36))
                _drips(s, Color(0.42, 0.47, 0.38), 5)
                _overlay(s, 2, 0.75, 6)
                _armband(s, L["band"])
            "C":
                _eyes(s, Color(1.0, 0.45, 0.05), 0.03, 1.8)
                _overlay(s, 1, 0.9, 8)
                # embers glowing through cracks
                var at := _attach(s, "Torso")
                for k in 7:
                    var e := _mesh(_box(Vector3(randf_range(0.03, 0.06), randf_range(0.1, 0.2), 0.02)), _mat(Color(1.0, 0.38, 0.05), 0.3, 2.2), at, _bone(s, ["Torso", "Abdomen", "UpperLeg.L", "UpperLeg.R", "UpperArm.L", "Torso", "Abdomen"][k]).origin + _fwd(s) * 0.17 + Vector3(randf_range(-0.12, 0.12), randf_range(-0.08, 0.1), 0))
                    e.rotation.z = randf_range(-0.8, 0.8)
                _armband(s, L["band"])
    match v:
        "A": _omni(Vector3(0, 1.5, 1.5), Color(1.0, 0.3, 0.2), 0.35, 6.0)
        "B": _omni(Vector3(0, 1.5, 1.5), Color(0.5, 1.0, 0.4), 0.3, 6.0)
        "C": _omni(Vector3(0, 0.6, 1.0), Color(1.0, 0.5, 0.15), 0.6, 6.0)
    cam.fov = 45
    cam.position = Vector3(0.3, 1.5, 4.6)
    cam.look_at(Vector3(0, 1.2, -1.0))


# ---------------------------------------------------------------- boss ----

func _boss(v: String) -> void:
    _lighting(Color(0.1, 0.09, 0.11), Color(0.7, 0.68, 0.74), 1.0, Vector3(-30, 165, 0), 1.6, Color(0.95, 0.92, 1.0))
    _floor(Color(0.26, 0.24, 0.22))
    _wall(Color(0.28, 0.26, 0.25), -6.0)
    var K := 2.4
    var s
    match v:
        "A":
            caption.text = "A  -  THE MELTED MARSHAL: giant officer, long coat, medals, half his face melting"
            s = _soldier(Color(0.24, 0.26, 0.3), "none", "Idle", 0.3, Vector3(0, 0, -1.2), 180.0, K)
        "B":
            caption.text = "B  -  THE IRON OVERLORD: plastic in toy armour, spiked helmet, molten core"
            s = _soldier(Color(0.18, 0.18, 0.2), "none", "Idle", 0.3, Vector3(0, 0, -1.2), 180.0, K)
        "C":
            caption.text = "C  -  THE MOLTEN EMPEROR: a crowned giant half-sunk in a pool of melted soldiers"
            s = _soldier(Color(0.45, 0.24, 0.14), "none", "Idle", 0.3, Vector3(0, -1.1, -1.2), 180.0, K)
    await get_tree().process_frame
    await get_tree().process_frame
    var f := _fwd(s)
    var r := _right(s)
    var h := _bone(s, "Head").origin
    var t := _bone(s, "Torso").origin
    match v:
        "A":
            var at := _attach(s, "Head")
            # peaked officer cap: tall crown, flat top, black brim
            _mesh(_cyl(0.27 * K, 0.23 * K, 0.15 * K), _mat(Color(0.2, 0.22, 0.26), 0.5), at, h + Vector3(0, 0.55, 0) * K)
            var brim := _mesh(_cyl(0.22 * K, 0.22 * K, 0.025 * K), _mat(Color(0.05, 0.05, 0.05), 0.2), at, h + Vector3(0, 0.45, 0) * K + f * 0.14 * K)
            brim.scale = Vector3(1.0, 1.0, 0.6)
            _mesh(_cyl(0.24 * K, 0.24 * K, 0.04 * K), _mat(Color(0.75, 0.12, 0.1), 0.5), at, h + Vector3(0, 0.49, 0) * K)
            # coat: a long dark slab behind and below the shoulders
            var coat := _mesh(_box(Vector3(0.55, 1.1, 0.06) * K), _mat(Color(0.1, 0.11, 0.13), 0.7), _attach(s, "Torso"), t - f * 0.18 * K - Vector3(0, 0.42, 0) * K)
            coat.look_at(coat.global_position + f, Vector3.UP)
            coat.rotate_object_local(Vector3.RIGHT, -0.12)
            # medals
            var tat := _attach(s, "Torso")
            for i in 4:
                var med := _mesh(_cyl(0.03 * K, 0.03 * K, 0.012 * K), _mat([Color(0.95, 0.75, 0.2), Color(0.8, 0.8, 0.85), Color(0.8, 0.2, 0.2), Color(0.95, 0.75, 0.2)][i], 0.2, 0.0, 0.8), tat, t + f * 0.26 * K + r * (0.06 + i * 0.07) * K + Vector3(0, 0.08, 0) * K)
                med.look_at(med.global_position + f, Vector3.UP)
                med.rotate_object_local(Vector3.RIGHT, PI / 2)
            # melting face: one side drips, eyes uneven
            for i in 6:
                var d := _mesh(_sphere(randf_range(0.025, 0.04) * K), _mat(Color(0.3, 0.32, 0.36), 0.12), at, h + f * 0.36 * K - r * (0.08 + randf() * 0.12) * K - Vector3(0, i * 0.045 - 0.05, 0) * K)
                d.scale = Vector3(1, 2.2, 1)
            _mesh(_sphere(0.06 * K), _mat(Color(1.0, 0.12, 0.05), 0.2, 2.0), at, h + f * 0.36 * K + r * 0.11 * K + Vector3(0, 0.14, 0) * K)
            _mesh(_sphere(0.035 * K), _mat(Color(1.0, 0.12, 0.05), 0.2, 2.0), at, h + f * 0.37 * K - r * 0.11 * K + Vector3(0, 0.1, 0) * K)
            _overlay(s, 2, 0.4, 3)
            _omni(t + f * 2.0 + Vector3(0, 1, 0), Color(1.0, 0.3, 0.2), 0.5, 8.0)
        "B":
            var tat := _attach(s, "Torso")
            var steel := _mat(Color(0.32, 0.33, 0.36), 0.35, 0.0, 0.75)
            var plate := _mesh(_box(Vector3(0.3, 0.26, 0.08) * K), steel, tat, t + f * 0.14 * K + Vector3(0, 0.02, 0) * K)
            plate.look_at(plate.global_position + f, Vector3.UP)
            for side in [-1.0, 1.0]:
                var sp := _mesh(_box(Vector3(0.15, 0.07, 0.18) * K), steel, tat, t + r * side * 0.2 * K + Vector3(0, 0.14, 0) * K)
                sp.look_at(sp.global_position + f, Vector3.UP)
                sp.rotate_object_local(Vector3.FORWARD, side * 0.35)
                _mesh(_cyl(0.0, 0.025 * K, 0.1 * K), steel, tat, t + r * side * 0.24 * K + Vector3(0, 0.22, 0) * K)
            var core := _mesh(_sphere(0.06 * K), _mat(Color(1.0, 0.45, 0.05), 0.2, 2.2), tat, t + f * 0.19 * K + Vector3(0, 0.03, 0) * K)
            core.scale = Vector3(1, 1, 0.5)
            var hat := _attach(s, "Head")
            var helm := _mesh(_sphere(0.3 * K, 0.36 * K), steel, hat, h + Vector3(0, 0.4, 0) * K)
            helm.scale = Vector3(1.0, 0.8, 1.05)
            _mesh(_cyl(0.0, 0.05 * K, 0.3 * K), steel, hat, h + Vector3(0, 0.72, 0) * K)
            var visor := _mesh(_box(Vector3(0.2, 0.035, 0.04) * K), _mat(Color(1.0, 0.45, 0.05), 0.2, 2.2), hat, h + f * 0.2 * K + Vector3(0, 0.1, 0) * K)
            visor.look_at(visor.global_position + f, Vector3.UP)
            _omni(t + f * 1.2, Color(1.0, 0.5, 0.15), 0.9, 7.0)
        "C":
            # the pool, with melted soldiers sticking out of it
            var pool := _mesh(_cyl(3.0, 3.2, 0.12), _mat(Color(0.5, 0.27, 0.15), 0.1), stage, Vector3(0, 0.06, -1.2))
            pool.scale = Vector3(1, 1, 0.8)
            for i in 18:
                var a := randf() * TAU
                var rr := randf_range(0.9, 2.2)
                var b := _mesh(_sphere(randf_range(0.25, 0.55)), _mat(Color(0.5, 0.27, 0.15).lerp(Color(0.6, 0.35, 0.2), randf()), 0.12), stage, Vector3(cos(a) * rr, 0.1, -1.2 + sin(a) * rr * 0.7))
                b.scale = Vector3(1, 0.55, 1)
            for p in [[Vector3(-2.0, -0.55, -0.2), 160.0, 25.0], [Vector3(1.9, -0.7, -0.4), -150.0, -30.0], [Vector3(0.9, -0.85, 0.5), 200.0, 15.0]]:
                var m = _soldier(Color(0.74, 0.55, 0.36).darkened(randf() * 0.3), "none", "Idle", 0.5, p[0], p[1])
                m.rotation.z = deg_to_rad(p[2])
            var hat := _attach(s, "Head")
            var gold := _mat(Color(1.0, 0.78, 0.2), 0.25, 0.3, 0.8)
            _mesh(_cyl(0.22 * K, 0.23 * K, 0.08 * K), gold, hat, h + Vector3(0, 0.55, 0) * K)
            for i in 6:
                var a := i * TAU / 6.0
                _mesh(_cyl(0.0, 0.04 * K, 0.12 * K), gold, hat, h + Vector3(cos(a) * 0.2, 0.64, sin(a) * 0.2) * K)
            _eyes(s, Color(1.0, 0.8, 0.1), 0.035, 2.0)
            _drips(s, Color(0.4, 0.2, 0.1), 10)
            var cape := _mesh(_box(Vector3(0.75, 0.9, 0.06) * K), _mat(Color(0.45, 0.06, 0.1), 0.7), _attach(s, "Torso"), t - f * 0.2 * K - Vector3(0, 0.3, 0) * K)
            cape.look_at(cape.global_position + f, Vector3.UP)
            _overlay(s, 2, 0.8, 6)
            _omni(Vector3(0, 0.8, 1.5), Color(1.0, 0.6, 0.25), 0.7, 8.0)
    # the player, for scale
    _soldier(GREEN, "rifle", "Idle_Shoot", 0.1, Vector3(-2.3, 0, 0.4), 30.0)
    cam.fov = 44
    cam.position = Vector3(1.4, 1.3, 7.4)
    cam.look_at(Vector3(0, 2.2, -1.0))
