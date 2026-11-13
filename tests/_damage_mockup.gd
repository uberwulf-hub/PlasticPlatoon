extends Node3D
## Damage-look mockups: the same soldier, same pose and light, one image per
## style and damage level.  godot --path . res://tests/_damage_mockup.tscn -- <outdir>
const SHADER := preload("res://assets/shaders/plastic_damage.gdshader")
const GREEN := Color(0.27, 0.48, 0.17)

func _ready() -> void:
    var out: String = OS.get_cmdline_user_args()[0]
    var env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Color(0.78, 0.8, 0.82)
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color(0.6, 0.62, 0.65)
    e.ambient_light_energy = 0.7
    e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.environment = e
    add_child(env)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-40, 35, 0)
    sun.light_energy = 1.3
    sun.shadow_enabled = true
    add_child(sun)
    var floor_mi := MeshInstance3D.new()
    var pm := PlaneMesh.new()
    pm.size = Vector2(20, 20)
    floor_mi.mesh = pm
    var fm := StandardMaterial3D.new()
    fm.albedo_color = Color(0.72, 0.66, 0.55)
    floor_mi.material_override = fm
    add_child(floor_mi)
    var S = load("res://scripts/plastic_soldier.gd")
    var sol = S.create()
    add_child(sol)
    sol.build(GREEN, "rifle")
    sol.rotation.y = PI
    var cam := Camera3D.new()
    cam.fov = 32
    add_child(cam)
    cam.position = Vector3(1.5, 1.55, 3.6)
    cam.look_at(Vector3(0, 1.0, 0))
    cam.current = true
    for i in 30: await get_tree().process_frame
    sol.set_physics_process(false)
    sol.set_process(false)
    var ap = sol.find_children("*", "AnimationPlayer", true, false)
    for a in ap: a.pause()
    var sk: Skeleton3D = sol.skeleton
    var fwd := Vector3(0, 0, 1)
    var spots := []
    for b in [["Torso", 0.22, 0.34], ["ShoulderPad.R", 0.12, 0.26], ["UpperLeg.L", 0.14, 0.3], ["Head", 0.25, 0.3], ["LowerArm.R", 0.06, 0.24]]:
        var bi := sk.find_bone(b[0])
        var p: Vector3 = (sk.global_transform * sk.get_bone_global_pose(bi)).origin + fwd * b[1]
        spots.append(Vector4(p.x, p.y, p.z, b[2]))
    var meshes = sol.find_children("*", "MeshInstance3D", true, false).filter(func(m): return m.is_visible_in_tree())
    var styles := [["none", -1], ["whitening", 0], ["scorch", 1], ["melt", 2]]
    for st in styles:
        for lvl in [["light", 2, 0.3], ["heavy", 5, 0.8]]:
            var mat: ShaderMaterial = null
            if st[1] >= 0:
                mat = ShaderMaterial.new()
                mat.shader = SHADER
                mat.set_shader_parameter("style", st[1])
                mat.set_shader_parameter("base_color", GREEN)
                var arr: Array = []
                for k in 8:
                    arr.append(spots[k] if k < spots.size() else Vector4.ZERO)
                mat.set_shader_parameter("hits", arr)
                mat.set_shader_parameter("hit_count", lvl[1])
                mat.set_shader_parameter("wear", lvl[2])
            for m in meshes:
                m.material_overlay = mat
            for i in 3: await get_tree().process_frame
            await RenderingServer.frame_post_draw
            get_viewport().get_texture().get_image().save_png("%s/%s_%s.png" % [out, st[0], lvl[0]])
    get_tree().quit()
