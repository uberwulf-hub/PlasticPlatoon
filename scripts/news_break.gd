extends CanvasLayer
## A PNN (Plastic News Network) news-break cutscene: a little 3D toy TV studio
## with two anchors, a field reporter, lower-third headline, scrolling ticker,
## typewriter subtitles and gibberish "voice" blips. Runs in its own World3D so
## it can play over a paused level. Space / click = next line, Esc = skip.

signal finished

const Soldier = preload("res://scripts/plastic_soldier.gd")
const UI = preload("res://scripts/ui_util.gd")

const CHARS_PER_SEC := 40.0
const FIELD_X := 60.0
const NAVY := Color(0.07, 0.1, 0.22)
const PNN_ORANGE := Color(0.95, 0.45, 0.1)
const NAMES := {
    "chip": ["CHIP PLASTERSON", "Anchor. Molded since 1962."],
    "brenda": ["BRENDA MOLD", "Co-Anchor. Unimpressed."],
    "both": ["PNN EVENING NEWS", "All the news that's fit to mold."],
}
const GARY_TITLES := {
    "desert": "Field Reporter. Has sand in everything.",
    "city": "Field Reporter. Lost on Khaki Street.",
    "table": "Field Reporter. Heart rate: concerning.",
}
const VOICE := {"chip": 0.75, "brenda": 1.3, "gary": 1.05, "both": 1.0}
const SCREEN_TEXT := {"desert": "JAMMED?!", "city": "KHAKI ST.", "table": "WI-FI?!"}

var data: Dictionary
var beats: Array = []
var idx := -1
var typed := 0.0
var hold := 0.0
var done := false
var auto_advance := true          # tests turn this off to hold on a shot
var theme := "desert"

var vp: SubViewport
var cam: Camera3D
var cam_from := Vector3.ZERO
var cam_look := Vector3.ZERO
var shot_t := 0.0
var chip
var brenda
var gary

var subtitle: Label
var name_label: Label
var title_label: Label
var headline_label: Label
var ticker_label: Label
var ticker_w := 0.0
var voice: AudioStreamPlayer
var _blip_t := 0.0


func play(d: Dictionary) -> void:
    data = d
    beats = d.get("beats", [])
    theme = d.get("theme", "desert")


func _ready() -> void:
    layer = 30
    process_mode = Node.PROCESS_MODE_ALWAYS
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    _build_world()
    _build_ui()
    voice = AudioStreamPlayer.new()
    voice.stream = Game.sfx.get("blip")
    voice.bus = "SFX"
    voice.volume_db = -10.0
    add_child(voice)
    Game.play_ui("news_sting", -4.0)
    _next()


# ------------------------------------------------------------------ world ----

func _build_world() -> void:
    var container := SubViewportContainer.new()
    container.set_anchors_preset(Control.PRESET_FULL_RECT)
    container.stretch = true
    container.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(container)
    vp = SubViewport.new()
    vp.own_world_3d = true
    vp.msaa_3d = Viewport.MSAA_2X
    container.add_child(vp)

    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.03, 0.04, 0.09)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.75, 0.78, 0.9)
    env.ambient_light_energy = 0.5
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.glow_enabled = true
    var we := WorldEnvironment.new()
    we.environment = env
    vp.add_child(we)
    var key := DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-35, 25, 0)
    key.light_energy = 1.3
    key.shadow_enabled = true
    vp.add_child(key)
    var rim := DirectionalLight3D.new()
    rim.rotation_degrees = Vector3(-25, 200, 0)
    rim.light_energy = 0.7
    rim.light_color = Color(0.7, 0.8, 1.0)
    vp.add_child(rim)

    # --- the studio ---
    _box(Vector3(0, -0.1, 0), Vector3(30, 0.2, 20), Color(0.08, 0.1, 0.18), 0.15)
    _box(Vector3(0, 4.5, -6), Vector3(26, 9, 0.4), NAVY.lightened(0.05))
    for y in [1.2, 6.8]:
        _glow(Vector3(0, y, -5.75), Vector3(26, 0.12, 0.05), Color(0.2, 0.6, 1.0))
    _glow(Vector3(3.4, 3.4, -5.7), Vector3(7.4, 4.2, 0.1), Color(0.05, 0.12, 0.3), 1.0)
    var screen := Label3D.new()
    screen.text = SCREEN_TEXT.get(theme, "NEWS!")
    screen.font_size = 220
    screen.pixel_size = 0.006
    screen.outline_size = 24
    screen.modulate = Color(1.0, 0.85, 0.3)
    screen.position = Vector3(3.4, 3.4, -5.6)
    vp.add_child(screen)
    var logo := Label3D.new()
    logo.text = "PNN"
    logo.font_size = 300
    logo.pixel_size = 0.008
    logo.outline_size = 30
    logo.modulate = PNN_ORANGE
    logo.position = Vector3(-4.6, 3.6, -5.6)
    vp.add_child(logo)
    # desk
    _box(Vector3(0, 0.55, 0), Vector3(6.2, 1.1, 1.6), Color(0.92, 0.93, 0.96), 0.2)
    _glow(Vector3(0, 0.55, 0.81), Vector3(6.2, 0.25, 0.02), PNN_ORANGE, 1.5)
    var desk_logo := Label3D.new()
    desk_logo.text = "PNN"
    desk_logo.font_size = 120
    desk_logo.pixel_size = 0.004
    desk_logo.modulate = NAVY
    desk_logo.position = Vector3(0, 0.88, 0.82)
    vp.add_child(desk_logo)
    _box(Vector3(0, 0.2, -1.0), Vector3(5.6, 0.4, 1.4), NAVY)                     # riser behind the desk
    chip = _person(Vector3(-1.35, 0.4, -0.8), Color(0.22, 0.32, 0.6))
    brenda = _person(Vector3(1.35, 0.4, -0.8), Color(0.6, 0.22, 0.3))
    _box(Vector3(-1.35, 1.12, 0.3), Vector3(0.7, 0.04, 0.5), Color(1, 1, 1))     # papers
    _box(Vector3(1.35, 1.16, 0.3), Vector3(0.18, 0.12, 0.18), Color(0.9, 0.3, 0.2))  # mug

    # --- the field set, themed to the operation ---
    var o := Vector3(FIELD_X, 0, 0)
    match theme:
        "city":
            _box(o + Vector3(0, -0.1, 0), Vector3(30, 0.2, 30), Color(0.3, 0.31, 0.33))
            _box(o + Vector3(-5, 5, -7), Vector3(6, 10, 4), Color(0.7, 0.66, 0.6))
            _box(o + Vector3(3, 7, -9), Vector3(7, 14, 4), Color(0.55, 0.38, 0.32))
            _box(o + Vector3(-2.5, 0.7, -3.5), Vector3(4.2, 1.2, 2.0), Color(0.75, 0.62, 0.4))   # parked tan jeep-ish
            _box(o + Vector3(0, 0.02, -1.5), Vector3(0.3, 0.02, 3.0), Color(0.85, 0.75, 0.2))
        "table":
            _box(o + Vector3(0, -0.1, 0), Vector3(30, 0.2, 30), Color(0.56, 0.37, 0.22), 0.45)
            _cyl(o + Vector3(-3.0, 5.0, -5.0), 2.2, 10.0, Color(0.2, 0.85, 0.3))
            _cyl(o + Vector3(-3.0, 7.0, -5.0), 2.25, 1.2, Color(0.05, 0.05, 0.05))
            _box(o + Vector3(3.5, 0.3, -3.0), Vector3(9.0, 0.5, 4.5), Color(0.08, 0.08, 0.1))  # phone
        _:
            _box(o + Vector3(0, -0.1, 0), Vector3(30, 0.2, 30), Color(0.74, 0.62, 0.42))
            _box(o + Vector3(-3.0, 0.5, -3.0), Vector3(4.0, 1.0, 0.9), Color(0.66, 0.58, 0.4))   # sandbags
            _box(o + Vector3(3.5, 1.3, -6.0), Vector3(6.1, 2.6, 2.5), Color(0.3, 0.38, 0.25))  # container
            _cyl(o + Vector3(-6.0, 3.0, -7.0), 0.25, 6.0, Color(0.45, 0.35, 0.22))           # palm trunk
            _box(o + Vector3(-6.0, 6.1, -7.0), Vector3(3.5, 0.1, 0.8), Color(0.3, 0.5, 0.2))
    gary = _person(o, Color(0.85, 0.68, 0.2))
    var mic := Node3D.new()
    mic.position = Vector3(-0.3, 1.3, -0.45)      # in front of him (he's turned to face the camera)
    gary.add_child(mic)
    var stick := MeshInstance3D.new()
    var sm := CylinderMesh.new()
    sm.top_radius = 0.03
    sm.bottom_radius = 0.03
    sm.height = 0.3
    stick.mesh = sm
    stick.rotation.x = deg_to_rad(-30)
    mic.add_child(stick)
    var head := MeshInstance3D.new()
    var hm := SphereMesh.new()
    hm.radius = 0.07
    hm.height = 0.14
    head.mesh = hm
    head.position = Vector3(0, 0.15, -0.08)
    var hmat := StandardMaterial3D.new()
    hmat.albedo_color = Color(0.1, 0.1, 0.1)
    head.material_override = hmat
    mic.add_child(head)
    var live := Label3D.new()
    live.text = "PNN LIVE"
    live.font_size = 90
    live.pixel_size = 0.005
    live.outline_size = 14
    live.modulate = PNN_ORANGE
    live.position = o + Vector3(1.4, 2.3, -1.0)
    vp.add_child(live)

    cam = Camera3D.new()
    cam.fov = 45
    vp.add_child(cam)
    cam.current = true


func _person(pos: Vector3, color: Color) -> Node3D:
    var p = Soldier.create()
    vp.add_child(p)
    p.build(color, "none")
    p.position = pos
    p.rotation.y = PI        # face the camera (+Z)
    return p


func _mat(c: Color, rough := 0.5) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.roughness = rough
    return m


func _box(pos: Vector3, size: Vector3, c: Color, rough := 0.6) -> void:
    var mi := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = size
    mi.mesh = bm
    mi.material_override = _mat(c, rough)
    mi.position = pos
    vp.add_child(mi)


func _cyl(pos: Vector3, r: float, h: float, c: Color) -> void:
    var mi := MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.top_radius = r
    cm.bottom_radius = r
    cm.height = h
    mi.mesh = cm
    mi.material_override = _mat(c, 0.3)
    mi.position = pos
    vp.add_child(mi)


func _glow(pos: Vector3, size: Vector3, c: Color, energy := 2.0) -> void:
    var mi := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = size
    mi.mesh = bm
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.emission_enabled = true
    m.emission = c
    m.emission_energy_multiplier = energy
    mi.material_override = m
    mi.position = pos
    vp.add_child(mi)


# --------------------------------------------------------------------- UI ----

func _panel(color: Color) -> PanelContainer:
    var p := PanelContainer.new()
    var sb := StyleBoxFlat.new()
    sb.bg_color = color
    sb.content_margin_left = 16
    sb.content_margin_right = 16
    sb.content_margin_top = 6
    sb.content_margin_bottom = 6
    p.add_theme_stylebox_override("panel", sb)
    p.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return p


func _build_ui() -> void:
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)

    # Network bug, top-left, and LIVE tag, top-right.
    var bug := _panel(PNN_ORANGE)
    UI.place(bug, Vector2(0, 0), Rect2(30, 26, 300, 70))
    var bvb := VBoxContainer.new()
    bvb.add_theme_constant_override("separation", -6)
    bug.add_child(bvb)
    bvb.add_child(UI.label("PNN", 34, Color.WHITE, 4))
    bvb.add_child(UI.label("PLASTIC NEWS NETWORK", 13, Color(1, 0.95, 0.85)))
    root.add_child(bug)
    var live := _panel(Color(0.85, 0.08, 0.08))
    UI.place(live, Vector2(1, 0), Rect2(-130, 30, 100, 40))
    live.add_child(UI.label("LIVE", 20, Color.WHITE))
    root.add_child(live)
    var hint := UI.label("Space / click: next      Esc: skip", 15, Color(1, 1, 1, 0.6), 4)
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    UI.place(hint, Vector2(0.5, 0), Rect2(-300, 36, 600, 24))
    root.add_child(hint)

    # Subtitles.
    subtitle = UI.label("", 26, Color.WHITE, 8)
    subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
    UI.place(subtitle, Vector2(0.5, 1), Rect2(-620, -350, 1240, 120))
    root.add_child(subtitle)

    # Lower third: BREAKING + headline, then name strip.
    var lower := VBoxContainer.new()
    lower.add_theme_constant_override("separation", 0)
    UI.place(lower, Vector2(0, 1), Rect2(40, -210, 1300, 140))
    root.add_child(lower)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 0)
    lower.add_child(row)
    var brk := _panel(Color(1.0, 0.82, 0.1))
    brk.add_child(UI.label("BREAKING", 24, Color(0.1, 0.05, 0.0)))
    row.add_child(brk)
    var hl := _panel(Color(0.78, 0.08, 0.1))
    headline_label = UI.label("", 26, Color.WHITE)
    hl.add_child(headline_label)
    row.add_child(hl)
    var strip := _panel(Color(NAVY.r, NAVY.g, NAVY.b, 0.92))
    var shb := HBoxContainer.new()
    shb.add_theme_constant_override("separation", 16)
    strip.add_child(shb)
    name_label = UI.label("", 22, Color.WHITE)
    shb.add_child(name_label)
    title_label = UI.label("", 17, Color(0.75, 0.82, 1.0))
    shb.add_child(title_label)
    var strip_row := HBoxContainer.new()
    strip_row.add_child(strip)
    lower.add_child(strip_row)

    # Ticker.
    var tick_bg := ColorRect.new()
    tick_bg.color = Color(0.03, 0.05, 0.12, 0.95)
    tick_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    UI.place(tick_bg, Vector2(0, 1), Rect2(0, -54, 4000, 54))
    root.add_child(tick_bg)
    var clip := Control.new()
    clip.clip_contents = true
    clip.set_anchors_preset(Control.PRESET_FULL_RECT)
    clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
    tick_bg.add_child(clip)
    var items: Array = data.get("ticker", [])
    var one := "   •   ".join(items) + "   •   "
    ticker_label = UI.label(one + one, 21, Color(1.0, 0.9, 0.6))
    ticker_label.position = Vector2(0, 12)
    clip.add_child(ticker_label)
    ticker_w = ticker_label.get_theme_font("font").get_string_size(one, HORIZONTAL_ALIGNMENT_LEFT, -1, 21).x


# --------------------------------------------------------------- playback ----

func _next() -> void:
    idx += 1
    if idx >= beats.size():
        _finish()
        return
    var b: Dictionary = beats[idx]
    var who: String = b.get("who", "both")
    subtitle.text = b.get("line", "")
    subtitle.visible_characters = 0
    typed = 0.0
    hold = 0.0
    if b.has("headline"):
        headline_label.text = b["headline"]
    var nm: Array = NAMES.get(who, NAMES["both"])
    if who == "gary":
        nm = ["GARY", GARY_TITLES.get(theme, "Field Reporter.")]
    name_label.text = nm[0]
    title_label.text = nm[1]
    _cut_to(who)
    var speaker = {"chip": chip, "brenda": brenda, "gary": gary}.get(who)
    if speaker != null:
        var g: String = b.get("gesture", "")
        if g == "" and randf() < 0.35:
            g = ["Yes", "No"].pick_random()
        if g != "":
            speaker.gesture(g)
    elif who == "both":
        chip.gesture("Wave")
        brenda.gesture("Yes")


func _cut_to(who: String) -> void:
    shot_t = 0.0
    match who:
        "chip":
            cam_from = Vector3(-0.55, 2.2, 3.0)
            cam_look = Vector3(-1.35, 1.85, -0.8)
        "brenda":
            cam_from = Vector3(0.55, 2.2, 3.0)
            cam_look = Vector3(1.35, 1.85, -0.8)
        "gary":
            cam_from = Vector3(FIELD_X + 1.3, 1.9, 4.6)
            cam_look = Vector3(FIELD_X + 0.4, 1.25, 0)
        _:
            cam_from = Vector3(0.0, 2.8, 8.0)
            cam_look = Vector3(0.0, 2.0, -1.5)
    _place_camera()


func _place_camera() -> void:
    # Slow push-in on every shot.
    var dir := (cam_look - cam_from).normalized()
    cam.position = cam_from + dir * minf(shot_t * 0.12, 0.8)
    cam.look_at(cam_look)


func _process(delta: float) -> void:
    if done:
        return
    shot_t += delta
    _place_camera()
    ticker_label.position.x -= 110.0 * delta
    if ticker_w > 0.0 and ticker_label.position.x < -ticker_w:
        ticker_label.position.x += ticker_w
    var total := subtitle.text.length()
    if typed < total:
        typed += CHARS_PER_SEC * delta
        subtitle.visible_characters = int(typed)
        _blip_t -= delta
        if _blip_t <= 0.0 and voice.stream != null:
            _blip_t = 0.075
            var who: String = beats[idx].get("who", "both")
            voice.pitch_scale = VOICE.get(who, 1.0) * randf_range(0.85, 1.2)
            voice.play()
    else:
        subtitle.visible_characters = -1
        hold += delta
        if auto_advance and hold > 1.4 + total * 0.025:
            _next()


func _input(event: InputEvent) -> void:
    if done:
        return
    var skip_all: bool = event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")
    var advance: bool = event.is_action_pressed("ui_accept") or event.is_action_pressed("jump") \
        or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
    if skip_all:
        get_viewport().set_input_as_handled()
        _finish()
    elif advance:
        get_viewport().set_input_as_handled()
        if typed < subtitle.text.length():
            typed = subtitle.text.length()     # finish the line first
        else:
            _next()


## Advances one beat (used by tests).
func skip_line() -> void:
    typed = subtitle.text.length()
    _next()


func _finish() -> void:
    if done:
        return
    done = true
    finished.emit()
    queue_free()
