extends Node3D
## Renders store/icon.png: a green plastic soldier on an olive background.
## Run: godot --rendering-method gl_compatibility --path . res://tests/render_icon.tscn -- <out.png>

func _ready() -> void:
    var out: String = OS.get_cmdline_user_args()[0]
    var vp := SubViewport.new()
    vp.size = Vector2i(512, 512)
    vp.transparent_bg = false
    vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    add_child(vp)
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.2, 0.27, 0.13)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.85, 0.9, 0.8)
    env.ambient_light_energy = 0.55
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    var we := WorldEnvironment.new()
    we.environment = env
    vp.add_child(we)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-35, 35, 0)
    sun.light_energy = 1.5
    vp.add_child(sun)
    var rim := DirectionalLight3D.new()
    rim.rotation_degrees = Vector3(-20, 200, 0)
    rim.light_energy = 0.8
    rim.light_color = Color(1.0, 0.9, 0.6)
    vp.add_child(rim)
    var s = load("res://scripts/plastic_soldier.gd").create()
    vp.add_child(s)
    s.build(Color(0.27, 0.48, 0.17), "rifle")
    s.rotation.y = deg_to_rad(180 - 28)
    s.notify_shot()
    for i in 30:
        s.animate(1.0 / 30.0, 0.0, false)
        await get_tree().process_frame
    var cam := Camera3D.new()
    cam.fov = 32
    vp.add_child(cam)
    cam.position = Vector3(0.0, 1.25, 4.3)
    cam.look_at(Vector3(0.05, 0.95, 0))
    cam.current = true
    for i in 10:
        await get_tree().process_frame
    await RenderingServer.frame_post_draw
    vp.get_texture().get_image().save_png(out)
    print("saved ", out)
    get_tree().quit()
