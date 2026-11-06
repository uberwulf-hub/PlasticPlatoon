extends Node
## Global game state (autoload "Game"): input map, settings, save data,
## difficulty helpers and procedurally synthesized sound effects.

const SAVE_PATH := "user://plastic_platoon.cfg"
const LEVEL_COUNT := 3
const DIFFICULTY_NAMES := ["Recruit", "Regular", "Veteran"]
const RATE := 22050

var mouse_sensitivity := 0.0025
var invert_y := false
var difficulty := 1
var unlocked_level := 0
var current_level: Node = null

var sfx := {}
var music_volume := 0.7
var sfx_volume := 1.0
var _music: AudioStreamPlayer
var _music_path := ""
var _ambience: AudioStreamPlayer

## Recorded CC0 sounds (see CREDITS.md). Each name may have several variants;
## anything missing falls back to the synthesized placeholder.
const SFX_FILES := {
    "rifle": ["rifle", "rifle_2"], "enemy_rifle": ["enemy_rifle"], "lmg": ["lmg"],
    "shotgun": ["shotgun"], "sniper": ["sniper"], "rocket": ["rocket"],
    "explosion": ["explosion", "explosion_2"], "empty": ["empty"], "click": ["ui_click"],
    "reload_rifle": ["reload_rifle"], "reload_shotgun": ["reload_shotgun"], "reload_sniper": ["reload_sniper"],
    "throw": ["throw"], "pickup": ["pickup"], "radio": ["radio_1", "radio_2", "radio_3", "radio_4"],
    "ui_confirm": ["ui_confirm"], "ui_error": ["ui_error"], "distant_boom": ["ambience/distant_explosion"],
}


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    randomize()
    _setup_inputs()
    _load()
    _setup_buses()
    _build_sfx()
    _load_sfx_files()
    _music = AudioStreamPlayer.new()
    _music.bus = "Music"
    add_child(_music)
    _ambience = AudioStreamPlayer.new()
    _ambience.bus = "SFX"
    add_child(_ambience)


# ---------------------------------------------------------------- input ----

func _setup_inputs() -> void:
    _keys("move_forward", [KEY_W, KEY_UP])
    _keys("move_back", [KEY_S, KEY_DOWN])
    _keys("move_left", [KEY_A, KEY_LEFT])
    _keys("move_right", [KEY_D, KEY_RIGHT])
    _keys("jump", [KEY_SPACE])
    _keys("sprint", [KEY_SHIFT])
    _keys("crouch", [KEY_C, KEY_CTRL])
    _keys("reload", [KEY_R])
    _keys("grenade", [KEY_G])
    _keys("drone", [KEY_F])
    _keys("interact", [KEY_E])
    _keys("pause", [KEY_ESCAPE, KEY_P])
    for i in 5:
        _keys("weapon_%d" % (i + 1), [KEY_1 + i])
    _mouse("fire", MOUSE_BUTTON_LEFT)
    _mouse("aim", MOUSE_BUTTON_RIGHT)
    _mouse("next_weapon", MOUSE_BUTTON_WHEEL_DOWN)
    _mouse("prev_weapon", MOUSE_BUTTON_WHEEL_UP)


func _keys(action: String, keys: Array) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action)
    for k in keys:
        var ev := InputEventKey.new()
        ev.physical_keycode = k
        InputMap.action_add_event(action, ev)


func _mouse(action: String, button: MouseButton) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action)
    var ev := InputEventMouseButton.new()
    ev.button_index = button
    InputMap.action_add_event(action, ev)


func _unhandled_input(event: InputEvent) -> void:
    if current_level == null or not is_instance_valid(current_level):
        return
    if event.is_action_pressed("pause"):
        current_level.toggle_pause()
        get_viewport().set_input_as_handled()
    elif event is InputEventMouseButton and event.pressed and not get_tree().paused:
        if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and current_level.is_playing():
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# ------------------------------------------------------------- settings ----

func enemy_damage_mult() -> float:
    return [0.55, 1.0, 1.45][difficulty]


func enemy_spread_mult() -> float:
    return [1.6, 1.0, 0.7][difficulty]


func enemy_reaction_mult() -> float:
    return [1.6, 1.0, 0.65][difficulty]


func unlock(level_index: int) -> void:
    if level_index > unlocked_level:
        unlocked_level = min(level_index, LEVEL_COUNT - 1)
        save()


func save() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("settings", "mouse_sensitivity", mouse_sensitivity)
    cfg.set_value("settings", "invert_y", invert_y)
    cfg.set_value("settings", "difficulty", difficulty)
    cfg.set_value("settings", "music_volume", music_volume)
    cfg.set_value("settings", "sfx_volume", sfx_volume)
    cfg.set_value("progress", "unlocked_level", unlocked_level)
    cfg.save(SAVE_PATH)


func _load() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) != OK:
        return
    mouse_sensitivity = cfg.get_value("settings", "mouse_sensitivity", mouse_sensitivity)
    invert_y = cfg.get_value("settings", "invert_y", invert_y)
    difficulty = clampi(cfg.get_value("settings", "difficulty", difficulty), 0, 2)
    music_volume = cfg.get_value("settings", "music_volume", music_volume)
    sfx_volume = cfg.get_value("settings", "sfx_volume", sfx_volume)
    unlocked_level = clampi(cfg.get_value("progress", "unlocked_level", 0), 0, LEVEL_COUNT - 1)


# ----------------------------------------------------------------- audio ----

func play_sfx(sound: String, pos: Vector3, volume_db := 0.0) -> void:
    if not sfx.has(sound) or get_child_count() > 64:
        return
    var p := AudioStreamPlayer3D.new()
    p.stream = _pick(sound)
    p.bus = "SFX"
    p.volume_db = volume_db
    p.unit_size = 14.0
    p.max_distance = 260.0
    p.pitch_scale = randf_range(0.9, 1.1)
    add_child(p)
    p.global_position = pos
    p.finished.connect(p.queue_free)
    p.play()


func play_ui(sound: String, volume_db := -4.0) -> void:
    if not sfx.has(sound):
        return
    var p := AudioStreamPlayer.new()
    p.stream = _pick(sound)
    p.bus = "SFX"
    p.volume_db = volume_db
    add_child(p)
    p.finished.connect(p.queue_free)
    p.play()


func _pick(sound: String) -> AudioStream:
    var v = sfx[sound]
    if v is Array:
        return v.pick_random()
    return v


func _load_sfx_files() -> void:
    for sound in SFX_FILES:
        var variants: Array = []
        for f in SFX_FILES[sound]:
            var path := ("res://assets/audio/%s.ogg" if "/" in f else "res://assets/audio/sfx/%s.ogg") % f
            if ResourceLoader.exists(path):
                variants.append(load(path))
        if not variants.is_empty():
            sfx[sound] = variants
    for alias in ["reload_rifle", "reload_shotgun", "reload_sniper"]:
        if not sfx.has(alias):
            sfx[alias] = sfx["reload"]
    if not sfx.has("enemy_rifle"):
        sfx["enemy_rifle"] = sfx["rifle"]
    for alias in ["empty", "throw", "ui_confirm", "ui_error"]:
        if not sfx.has(alias):
            sfx[alias] = sfx["click"]


func _setup_buses() -> void:
    for b in ["Music", "SFX"]:
        if AudioServer.get_bus_index(b) == -1:
            AudioServer.add_bus()
            AudioServer.set_bus_name(AudioServer.bus_count - 1, b)
            AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
    apply_volumes()


func apply_volumes() -> void:
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(maxf(music_volume, 0.0001)))
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(maxf(sfx_volume, 0.0001)))


## Crossfades to a looping music track (no-op if it's already playing).
func play_music(path: String, volume_db := -6.0) -> void:
    if path == _music_path or not ResourceLoader.exists(path):
        return
    _music_path = path
    var stream: AudioStream = load(path)
    if stream is AudioStreamOggVorbis:
        stream.loop = true
    var tw := create_tween()
    if _music.playing:
        tw.tween_property(_music, "volume_db", -40.0, 0.8)
    tw.tween_callback(func():
        _music.stream = stream
        _music.volume_db = -40.0
        _music.play())
    tw.tween_property(_music, "volume_db", volume_db, 1.2)


func play_ambience(path: String, volume_db := -10.0) -> void:
    if path == "" or not ResourceLoader.exists(path):
        _ambience.stop()
        return
    var stream: AudioStream = load(path)
    if stream is AudioStreamOggVorbis:
        stream.loop = true
    _ambience.stream = stream
    _ambience.volume_db = volume_db
    _ambience.play()


func stop_ambience() -> void:
    _ambience.stop()


func _build_sfx() -> void:
    sfx["rifle"] = _burst(0.24, 30.0, 0.55, 110.0, 0.5)
    sfx["lmg"] = _burst(0.24, 26.0, 0.45, 90.0, 0.6)
    sfx["shotgun"] = _burst(0.5, 12.0, 0.3, 70.0, 0.9)
    sfx["sniper"] = _burst(0.8, 9.0, 0.45, 55.0, 1.0)
    sfx["rocket"] = _burst(0.9, 3.5, 0.18, 40.0, 0.4)
    sfx["explosion"] = _burst(1.7, 2.6, 0.06, 42.0, 0.9)
    sfx["melt"] = _burst(1.1, 2.2, 0.95, 0.0, 0.0, 0.35)
    sfx["click"] = _burst(0.03, 120.0, 0.9, 0.0, 0.0, 0.5)
    sfx["reload"] = _clicks([0.0, 0.28, 0.5])
    sfx["pickup"] = _tones([660.0, 990.0], 0.07)
    sfx["hit"] = _tones([1900.0], 0.035)
    sfx["objective"] = _tones([523.0, 659.0, 784.0, 1046.0], 0.11)
    sfx["beep"] = _tones([1200.0, 0.0, 1200.0, 0.0, 1200.0], 0.09)
    sfx["fail"] = _tones([392.0, 330.0, 262.0], 0.2)
    sfx["engine"] = _engine_loop()


func _to_wav(samples: PackedFloat32Array, gain: float) -> AudioStreamWAV:
    var peak := 0.0001
    for v in samples:
        peak = max(peak, absf(v))
    var data := PackedByteArray()
    data.resize(samples.size() * 2)
    for i in samples.size():
        data.encode_s16(i * 2, int(clampf(samples[i] / peak * gain, -1.0, 1.0) * 32767.0))
    var s := AudioStreamWAV.new()
    s.format = AudioStreamWAV.FORMAT_16_BITS
    s.mix_rate = RATE
    s.stereo = false
    s.data = data
    return s


## Filtered noise burst with an optional low "thump" sine - good for guns/booms.
func _burst(dur: float, decay: float, smooth: float, thump_f: float, thump_amt: float, gain := 0.9) -> AudioStreamWAV:
    var n := int(dur * RATE)
    var out := PackedFloat32Array()
    out.resize(n)
    var lp := 0.0
    for i in n:
        var t := float(i) / RATE
        lp += (randf_range(-1.0, 1.0) - lp) * smooth
        var v := lp * exp(-t * decay)
        if thump_f > 0.0:
            v += sin(TAU * thump_f * t * (1.0 - t * 0.5)) * exp(-t * decay * 0.8) * thump_amt * 0.35
        out[i] = v
    return _to_wav(out, gain)


## One-second seamless engine loop (whole numbers of cycles so it loops cleanly).
func _engine_loop() -> AudioStreamWAV:
    var n := RATE
    var out := PackedFloat32Array()
    out.resize(n)
    var lp := 0.0
    for i in n:
        var t := float(i) / RATE
        var v := 0.0
        for h in [[48.0, 1.0], [96.0, 0.5], [144.0, 0.3], [24.0, 0.6]]:
            v += sin(TAU * h[0] * t) * h[1]
        v += sin(TAU * 8.0 * t) * 0.25 * sin(TAU * 48.0 * t)      # firing pulses
        lp += (randf_range(-1.0, 1.0) - lp) * 0.2
        out[i] = v * 0.6 + lp * 0.4
    var s := _to_wav(out, 0.5)
    s.loop_mode = AudioStreamWAV.LOOP_FORWARD
    s.loop_begin = 0
    s.loop_end = n
    return s


func _clicks(times: Array) -> AudioStreamWAV:
    var n := int((times[-1] + 0.06) * RATE)
    var out := PackedFloat32Array()
    out.resize(n)
    for t0 in times:
        var start := int(t0 * RATE)
        for j in int(0.04 * RATE):
            if start + j < n:
                out[start + j] += randf_range(-1.0, 1.0) * exp(-float(j) / RATE * 90.0)
    return _to_wav(out, 0.5)


func _tones(freqs: Array, each: float) -> AudioStreamWAV:
    var per := int(each * RATE)
    var out := PackedFloat32Array()
    out.resize(per * freqs.size())
    for k in freqs.size():
        var f: float = freqs[k]
        for j in per:
            var t := float(j) / RATE
            var env := minf(1.0, t * 200.0) * exp(-t * 18.0)
            out[k * per + j] = sin(TAU * f * t) * env if f > 0.0 else 0.0
    return _to_wav(out, 0.45)
