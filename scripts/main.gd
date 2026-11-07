extends Node
## Front-end flow: animated title diorama, campaign select, briefing,
## settings, controls, level loading and the after-action debrief.

const Level = preload("res://scripts/level.gd")
const LevelData = preload("res://scripts/level_data.gd")
const UI = preload("res://scripts/ui_util.gd")
const NewsBreak = preload("res://scripts/news_break.gd")
const NewsScripts = preload("res://scripts/news_scripts.gd")
const Soldier = preload("res://scripts/plastic_soldier.gd")
const Fx = preload("res://scripts/fx.gd")

var ui: CanvasLayer
var level: Node3D
var diorama: Node3D
var diorama_cam: Camera3D
var t := 0.0
var _boom_t := 3.0


func _ready() -> void:
    show_main_menu()


func _process(delta: float) -> void:
    if diorama and is_instance_valid(diorama_cam):
        t += delta * 0.15
        diorama_cam.position = Vector3(sin(t) * 10.0, 3.0, cos(t) * 10.0)
        diorama_cam.look_at(Vector3(0, 1.2, 0))
        _boom_t -= delta
        if _boom_t <= 0.0:
            _boom_t = randf_range(2.5, 5.0)
            var p := Vector3(randf_range(-25, 25), 0, randf_range(-30, -12))
            Fx.explosion(diorama, p, 3.0)


# ------------------------------------------------------------ plumbing ----

func _new_ui(dim := 0.0) -> Control:
    if ui:
        ui.queue_free()
    ui = CanvasLayer.new()
    ui.layer = 10
    ui.process_mode = Node.PROCESS_MODE_ALWAYS
    add_child(ui)
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.theme = UI.make_theme()
    ui.add_child(root)
    if dim > 0.0:
        var bg := ColorRect.new()
        bg.set_anchors_preset(Control.PRESET_FULL_RECT)
        bg.color = Color(0.03, 0.04, 0.02, dim)
        root.add_child(bg)
    return root


func _clear_level() -> void:
    if level and is_instance_valid(level):
        level.queue_free()
    level = null


func _clear_diorama() -> void:
    if diorama:
        diorama.queue_free()
    diorama = null
    diorama_cam = null


# ---------------------------------------------------------------- menus ----

func show_main_menu() -> void:
    _cancel_news()
    _clear_level()
    get_tree().paused = false
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    Game.stop_ambience()
    Game.play_music("res://assets/audio/music/menu_militaristic_tune.ogg", -8.0)
    if diorama == null:
        _build_diorama()
    var root := _new_ui()
    var shade := ColorRect.new()
    UI.place(shade, Vector2(0, 0), Rect2(0, 0, 640, 4000))
    shade.color = Color(0.03, 0.05, 0.02, 0.72)
    root.add_child(shade)
    var vb := VBoxContainer.new()
    vb.add_theme_constant_override("separation", 14)
    UI.place(vb, Vector2(0, 0), Rect2(70, 90, 560, 760))
    root.add_child(vb)
    vb.add_child(UI.label("PLASTIC PLATOON", 56, UI.ACCENT, 10))
    vb.add_child(UI.label("REVENGE 2026", 56, Color(0.95, 0.95, 0.88), 10))
    vb.add_child(UI.label("Plastic soldiers. Modern warfare.", 22, Color(0.8, 0.85, 0.7), 4))
    var spacer := Control.new()
    spacer.custom_minimum_size = Vector2(0, 30)
    vb.add_child(spacer)
    vb.add_child(UI.button("Campaign", show_campaign))
    vb.add_child(UI.button("Settings", show_settings))
    vb.add_child(UI.button("Controls", show_controls))
    vb.add_child(UI.button("Quit", func(): get_tree().quit()))
    var foot := UI.label("Difficulty: %s" % Game.DIFFICULTY_NAMES[Game.difficulty], 16, Color(0.7, 0.75, 0.6))
    vb.add_child(foot)


func show_campaign() -> void:
    var root := _new_ui(0.4)
    var vb := UI.centered_panel(root, 640)
    vb.add_child(UI.label("CAMPAIGN", 40, UI.ACCENT))
    vb.add_child(UI.label("Select an operation", 18))
    for i in LevelData.META.size():
        var m: Dictionary = LevelData.META[i]
        var locked: bool = i > Game.unlocked_level
        var b := UI.button(("%d.  %s" % [i + 1, m["name"]]) + ("   [LOCKED]" if locked else ""), func(): _news(NewsScripts.intro(i), func(): show_briefing(i)), 560)
        b.disabled = locked
        vb.add_child(b)
    vb.add_child(UI.button("Back", show_main_menu, 560))


func show_briefing(i: int) -> void:
    var m: Dictionary = LevelData.META[i]
    var root := _new_ui(0.55)
    var vb := UI.centered_panel(root, 760)
    vb.add_child(UI.label("OPERATION %d - BRIEFING" % (i + 1), 16, UI.ACCENT))
    vb.add_child(UI.label(m["name"].to_upper(), 38, Color.WHITE))
    vb.add_child(UI.label(m["location"], 18, Color(0.8, 0.82, 0.7)))
    var body := UI.label(m["briefing"], 19)
    body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.custom_minimum_size = Vector2(690, 0)
    vb.add_child(body)
    vb.add_child(UI.label("OBJECTIVES", 16, UI.ACCENT))
    for o in m["objectives"]:
        vb.add_child(UI.label("  ■  " + o, 19))
    var hb := HBoxContainer.new()
    hb.add_theme_constant_override("separation", 16)
    hb.add_child(UI.button("DEPLOY", func(): start_level(i), 300))
    hb.add_child(UI.button("Back", show_campaign, 200))
    vb.add_child(hb)


func show_settings() -> void:
    var root := _new_ui(0.4)
    var vb := UI.centered_panel(root, 560)
    vb.add_child(UI.label("SETTINGS", 40, UI.ACCENT))
    vb.add_child(UI.label("Difficulty", 18))
    var diff := HBoxContainer.new()
    for d in 3:
        var b := UI.button(Game.DIFFICULTY_NAMES[d], func():
            Game.difficulty = d
            Game.save()
            show_settings(), 160)
        if d == Game.difficulty:
            b.add_theme_color_override("font_color", UI.ACCENT)
            b.text = "> " + b.text
        diff.add_child(b)
    vb.add_child(diff)
    vb.add_child(UI.label("Mouse sensitivity", 18))
    var slider := HSlider.new()
    slider.min_value = 0.0005
    slider.max_value = 0.008
    slider.step = 0.0001
    slider.value = Game.mouse_sensitivity
    slider.custom_minimum_size = Vector2(480, 24)
    slider.value_changed.connect(func(v): Game.mouse_sensitivity = v)
    vb.add_child(slider)
    for row in [["Music volume", "music_volume"], ["Effects volume", "sfx_volume"]]:
        vb.add_child(UI.label(row[0], 18))
        var vs := HSlider.new()
        vs.min_value = 0.0
        vs.max_value = 1.0
        vs.step = 0.05
        vs.value = Game.get(row[1])
        vs.custom_minimum_size = Vector2(480, 24)
        var prop: String = row[1]
        vs.value_changed.connect(func(v):
            Game.set(prop, v)
            Game.apply_volumes())
        vb.add_child(vs)
    var nb := CheckBox.new()
    nb.text = "PNN news breaks between operations"
    nb.button_pressed = Game.show_news
    nb.toggled.connect(func(on): Game.show_news = on)
    vb.add_child(nb)
    var inv := CheckBox.new()
    inv.text = "Invert mouse Y"
    inv.button_pressed = Game.invert_y
    inv.toggled.connect(func(on): Game.invert_y = on)
    vb.add_child(inv)
    vb.add_child(UI.button("Back", func():
        Game.save()
        show_main_menu(), 480))


func show_controls() -> void:
    var root := _new_ui(0.4)
    var vb := UI.centered_panel(root, 620)
    vb.add_child(UI.label("CONTROLS", 40, UI.ACCENT))
    var rows := [
        ["W A S D", "Move"], ["Mouse", "Look / aim"], ["Left click", "Fire"],
        ["Right click", "Aim down sights / scope"], ["Shift", "Sprint"], ["C / Ctrl", "Crouch (harder to spot)"],
        ["Space", "Jump"], ["R", "Reload"], ["1 - 5 / Wheel", "Switch weapon"],
        ["G", "Throw frag grenade"], ["E", "Get in / out of a jeep or tank"], ["F", "Call Reaper drone strike at crosshair"], ["Esc / P", "Pause"], ["In vehicles", "WASD drive, mouse aims the gun, LMB fire, RMB tank coax MG"],
    ]
    var grid := GridContainer.new()
    grid.columns = 2
    grid.add_theme_constant_override("h_separation", 40)
    for r in rows:
        grid.add_child(UI.label(r[0], 19, UI.ACCENT))
        grid.add_child(UI.label(r[1], 19))
    vb.add_child(grid)
    vb.add_child(UI.label("Tip: radar jammers, SAMs and boosters shrug off bullets.\nUse the AT4, grenades or a drone strike.", 16, Color(0.8, 0.82, 0.7)))
    vb.add_child(UI.button("Back", show_main_menu, 540))


# ------------------------------------------------------------ gameplay ----

func start_level(i: int) -> void:
    _cancel_news()
    _clear_diorama()
    _clear_level()
    if ui:
        ui.queue_free()
        ui = null
    get_tree().paused = false
    level = Level.new()
    level.level_index = i
    level.finished.connect(_on_level_finished)
    level.request_menu.connect(show_main_menu)
    level.request_restart.connect(func(): start_level(i))
    add_child(level)


## Plays a PNN news break (unless turned off in Settings), then calls `then`.
var news: CanvasLayer = null


func _cancel_news() -> void:
    if news != null and is_instance_valid(news):
        news.done = true          # silently stop; don't run its follow-up
        news.queue_free()
    news = null


func _news(d: Dictionary, then: Callable) -> void:
    _cancel_news()
    if not Game.show_news:
        then.call()
        return
    news = NewsBreak.new()
    news.play(d)
    news.finished.connect(func():
        news = null
        then.call())
    add_child(news)


func _on_level_finished(success: bool, stats: Dictionary) -> void:
    var i: int = stats["level"]
    if success:
        Game.unlock(i + 1)
        Game.play_ui("ui_confirm", -2.0)
    get_tree().paused = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if ui:
        ui.queue_free()
        ui = null
    _news(NewsScripts.outro(i, success, stats), func(): _show_debrief(success, stats))


func _show_debrief(success: bool, stats: Dictionary) -> void:
    var i: int = stats["level"]
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    var root := _new_ui(0.6)
    var vb := UI.centered_panel(root, 600)
    var last: bool = i >= LevelData.META.size() - 1
    if success:
        vb.add_child(UI.label("MISSION ACCOMPLISHED", 40, UI.ACCENT))
        if last:
            vb.add_child(UI.label("The table is ours. The Tan Army is a puddle.\nCampaign complete - thanks for playing!", 19))
    else:
        vb.add_child(UI.label("MISSION FAILED", 40, Color(0.95, 0.35, 0.25)))
        vb.add_child(UI.label("You were melted down. Regroup and try again.", 19))
    vb.add_child(UI.label(LevelData.META[i]["name"], 22))
    var secs := int(stats["time"])
    var grid := GridContainer.new()
    grid.columns = 2
    grid.add_theme_constant_override("h_separation", 50)
    for r in [
        ["Time", "%02d:%02d" % [secs / 60, secs % 60]],
        ["Tan soldiers melted", "%d / %d" % [stats["kills"], stats["total"]]],
        ["Headshots", str(stats["headshots"])],
        ["Accuracy", "%d%%" % int(stats["accuracy"])],
    ]:
        grid.add_child(UI.label(r[0], 19, Color(0.8, 0.82, 0.7)))
        grid.add_child(UI.label(r[1], 19, Color.WHITE))
    vb.add_child(grid)
    if success and not last:
        vb.add_child(UI.button("Next Operation", func(): show_briefing_from_game(i + 1), 520))
    vb.add_child(UI.button("Retry Operation", func(): start_level(i), 520))
    vb.add_child(UI.button("Main Menu", show_main_menu, 520))


func show_briefing_from_game(i: int) -> void:
    _clear_level()
    get_tree().paused = false
    _build_diorama()
    _news(NewsScripts.intro(i), func(): show_briefing(i))


# -------------------------------------------------------------- diorama ----

func _build_diorama() -> void:
    _clear_diorama()
    diorama = Node3D.new()
    add_child(diorama)
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sm := ProceduralSkyMaterial.new()
    sm.sky_top_color = Color(0.25, 0.35, 0.55)
    sm.sky_horizon_color = Color(0.95, 0.7, 0.45)
    sm.ground_horizon_color = Color(0.95, 0.7, 0.45)
    sky.sky_material = sm
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.glow_enabled = true
    env.fog_enabled = true
    env.fog_density = 0.012
    env.fog_light_color = Color(0.9, 0.7, 0.5)
    var we := WorldEnvironment.new()
    we.environment = env
    diorama.add_child(we)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-18, -60, 0)
    sun.light_color = Color(1.0, 0.75, 0.5)
    sun.light_energy = 1.4
    sun.shadow_enabled = true
    diorama.add_child(sun)
    var ground := MeshInstance3D.new()
    var pm := PlaneMesh.new()
    pm.size = Vector2(200, 200)
    ground.mesh = pm
    var gm := StandardMaterial3D.new()
    gm.albedo_color = Color(0.7, 0.58, 0.4)
    ground.material_override = gm
    diorama.add_child(ground)
    var bag := StandardMaterial3D.new()
    bag.albedo_color = Color(0.66, 0.58, 0.4)
    for i in 5:
        var b := MeshInstance3D.new()
        var bm := BoxMesh.new()
        bm.size = Vector3(1.6, 0.9, 0.8)
        b.mesh = bm
        b.material_override = bag
        b.position = Vector3(-3.2 + i * 1.6, 0.45, -1.8)
        diorama.add_child(b)
    var poses := [
        [Vector3(-1.6, 0, 0), 0.1, "rifle"], [Vector3(0.6, 0, 0.6), -0.2, "lmg"],
        [Vector3(2.4, 0, -0.4), 0.3, "launcher"], [Vector3(-3.4, 0, 1.2), -0.4, "sniper"],
    ]
    for p in poses:
        var s = Soldier.create()
        diorama.add_child(s)
        s.build(Color(0.27, 0.48, 0.17), p[2])
        s.position = p[0]
        s.rotation.y = p[1]
        s.animate(0.016, 0.0, p[2] == "sniper")
    var dead = Soldier.create()
    diorama.add_child(dead)
    dead.build(Color(0.8, 0.68, 0.44), "rifle")
    dead.position = Vector3(1.5, 0, -6)
    dead.scale = Vector3(1.9, 0.07, 1.9)
    diorama_cam = Camera3D.new()
    diorama_cam.fov = 55
    diorama.add_child(diorama_cam)
    diorama_cam.current = true
