extends Node3D
## Weather for a level: drifting clouds painted into the sky, rain that falls
## around the player, and thunderstorms (lightning flashes, the odd bolt in the
## distance, thunder rolling in a moment later). Set per map in
## LevelData.WEATHER; Settings > Weather turns it off.
##
## w = {"clouds": 0..1, "rain": 0..1, "storm": bool}

const SKY_SHADER := preload("res://assets/shaders/weather_sky.gdshader")

var level: Node
var w: Dictionary = {}
var sky_mat: ShaderMaterial
var rain: CPUParticles3D
var rain_sound: AudioStreamPlayer
var _thunder_t := 0.0
var _flash := 0.0
var _base_sun := 1.0
var _base_ambient := 1.0
var flashes := 0                  # lightning strikes so far (tests read it)


func setup(lvl: Node, preset: Dictionary) -> void:
    level = lvl
    w = preset.duplicate()          # the map's table is read-only
    name = "Weather"


func _ready() -> void:
    var clouds: float = w.get("clouds", 0.0)
    var rain_amt: float = w.get("rain", 0.0)
    var storm: bool = w.get("storm", false)
    _build_sky(clouds, storm)
    var sun: DirectionalLight3D = level._sun
    if rain_amt > 0.0 or storm:
        # Grey skies dim the sun.
        sun.light_energy *= lerpf(1.0, 0.45, maxf(rain_amt, 0.6 if storm else 0.0))
        if level._env.fog_enabled:
            level._env.fog_density *= 1.0 + rain_amt * 0.8
        else:
            level._env.fog_enabled = true
            level._env.fog_density = 0.004 + rain_amt * 0.006
            level._env.fog_light_color = level.info["sky_horizon"].darkened(0.3)
    _base_sun = sun.light_energy
    _base_ambient = level._env.ambient_light_energy
    if rain_amt > 0.0:
        _build_rain(rain_amt)
        _build_rain_sound(rain_amt)
    _thunder_t = randf_range(6.0, 12.0)


# ------------------------------------------------------------------ sky ----

func _build_sky(clouds: float, storm: bool) -> void:
    sky_mat = ShaderMaterial.new()
    sky_mat.shader = SKY_SHADER
    var top: Color = level.info["sky_top"]
    var hor: Color = level.info["sky_horizon"]
    var grey := Color(0.42, 0.44, 0.48) if storm else Color(0.62, 0.64, 0.68)
    var overcast: float = clamp((clouds - 0.5) * 1.6, 0.0, 1.0) * (1.0 if w.get("rain", 0.0) > 0.0 or storm else 0.5)
    sky_mat.set_shader_parameter("top_color", top.lerp(grey.darkened(0.15), overcast))
    sky_mat.set_shader_parameter("horizon_color", hor.lerp(grey, overcast))
    sky_mat.set_shader_parameter("ground_color", hor.darkened(0.5))
    sky_mat.set_shader_parameter("coverage", clouds)
    var cloud_col: Color = Color(0.97, 0.97, 0.99).lerp(Color(0.38, 0.4, 0.44), overcast if storm or w.get("rain", 0.0) > 0.0 else 0.0)
    # Clouds take on a little of the sky's colour (warm at dusk, dark at night).
    sky_mat.set_shader_parameter("cloud_color", cloud_col * clampf(hor.get_luminance() * 1.6 + 0.25, 0.35, 1.0))
    sky_mat.set_shader_parameter("sun_dir", -level._sun.global_transform.basis.z)
    level._env.sky.sky_material = sky_mat


# ----------------------------------------------------------------- rain ----

func _build_rain(amt: float) -> void:
    rain = CPUParticles3D.new()
    rain.amount = int([220, 450, 750][clampi(Game.graphics, 0, 2)] * amt) + 60
    rain.lifetime = 0.9
    rain.preprocess = 1.0
    rain.local_coords = false
    rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
    rain.emission_box_extents = Vector3(22, 1, 22)
    rain.position = Vector3(0, 14, 0)
    rain.direction = Vector3(0.12, -1, 0.05)
    rain.spread = 3.0
    rain.gravity = Vector3(0, -12, 0)
    rain.initial_velocity_min = 18.0
    rain.initial_velocity_max = 22.0
    var qm := QuadMesh.new()
    qm.size = Vector2(0.03, 0.8)
    var m := StandardMaterial3D.new()
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
    m.albedo_color = Color(0.78, 0.82, 0.92, 0.5)
    m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    qm.material = m
    rain.mesh = qm
    rain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    level.player.add_child(rain)


## Rain you can hear: a loop of soft, low noise made right here (no sound file).
func _build_rain_sound(amt: float) -> void:
    var rate := 22050
    var n := rate * 2
    var data := PackedByteArray()
    data.resize(n * 2)
    var b0 := 0.0
    var b1 := 0.0
    for i in n:
        var white := randf() * 2.0 - 1.0
        b0 = 0.99 * b0 + white * 0.09          # pinkish hiss
        b1 = 0.6 * b1 + white * 0.4            # patter
        var v := clampf((b0 * 1.6 + b1 * 0.35) * 0.45, -1.0, 1.0)
        # Fade the loop's ends together so it doesn't click.
        var edge := minf(1.0, minf(float(i), float(n - i)) / 600.0)
        data.encode_s16(i * 2, int(v * edge * 26000.0))
    var wav := AudioStreamWAV.new()
    wav.format = AudioStreamWAV.FORMAT_16_BITS
    wav.mix_rate = rate
    wav.data = data
    wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
    wav.loop_end = n
    rain_sound = AudioStreamPlayer.new()
    rain_sound.stream = wav
    rain_sound.bus = "SFX"
    rain_sound.volume_db = lerpf(-24.0, -13.0, amt)
    add_child(rain_sound)
    rain_sound.play()


# -------------------------------------------------------------- thunder ----

func _process(delta: float) -> void:
    if sky_mat != null:
        sky_mat.set_shader_parameter("drift", Time.get_ticks_msec() * 0.001)
    if not w.get("storm", false):
        return
    _thunder_t -= delta
    if _thunder_t <= 0.0:
        _thunder_t = randf_range(9.0, 22.0)
        strike()
    if _flash > 0.0:
        _flash = maxf(0.0, _flash - delta * 5.0)
        # A double flicker as it fades.
        var f := _flash * (0.6 + 0.4 * absf(sin(_flash * 40.0)))
        level._sun.light_energy = _base_sun + f * 2.6
        level._env.ambient_light_energy = _base_ambient + f * 1.4
        sky_mat.set_shader_parameter("flash", f)


## Lightning: a flash over the whole map, sometimes a bolt you can see in the
## distance, and thunder after a delay that depends on how far away it was.
func strike() -> void:
    flashes += 1
    _flash = 1.0
    var cam := get_viewport().get_camera_3d()
    var eye: Vector3 = cam.global_position if cam else level.player.global_position
    var dist := randf_range(60.0, 160.0)
    var dir := Vector3.FORWARD.rotated(Vector3.UP, randf() * TAU)
    if randf() < 0.6:
        _bolt(eye + dir * dist)
    get_tree().create_timer(clampf(dist / 120.0, 0.25, 1.6)).timeout.connect(func():
        if is_inside_tree():
            Game.play_ui("distant_boom", randf_range(-6.0, -1.0)))


func _bolt(ground: Vector3) -> void:
    var bolt := Node3D.new()
    add_child(bolt)
    var m := StandardMaterial3D.new()
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.albedo_color = Color(0.92, 0.95, 1.0)
    var p := ground + Vector3(0, 70, 0)
    while p.y > ground.y + 1.0:
        var nxt := p + Vector3(randf_range(-4, 4), -randf_range(6, 11), randf_range(-4, 4))
        nxt.y = maxf(nxt.y, ground.y)
        var seg := MeshInstance3D.new()
        var bm := BoxMesh.new()
        bm.size = Vector3(0.35, 0.35, p.distance_to(nxt))
        seg.mesh = bm
        seg.material_override = m
        seg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        bolt.add_child(seg)
        seg.global_position = (p + nxt) * 0.5
        seg.look_at(nxt, Vector3.RIGHT)
        p = nxt
    get_tree().create_timer(0.18).timeout.connect(bolt.queue_free)
