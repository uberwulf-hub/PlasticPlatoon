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
    Net.start_requested.connect(func(op): start_level(op))
    Net.lobby_requested.connect(show_lobby)
    Net.host_left.connect(func(): _mp_message("The host left the game."))
    Net.join_failed.connect(func(reason): _mp_message(reason))
    Net.players_changed.connect(func():
        if get_meta("in_lobby", false):
            show_lobby())
    Net.friends_changed.connect(func():
        if get_meta("in_friends", false):
            show_multiplayer()
        elif get_meta("in_lobby", false):
            show_lobby())
    Net.invite_received.connect(_on_invite)
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
    set_meta("in_friends", false)     # screens that list friends set it again
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
        # Remove right away so a new level can take the name "Level" (LAN
        # games address each other's levels by node path).
        if level.get_parent() == self:
            remove_child(level)
        level.queue_free()
    level = null


func _clear_diorama() -> void:
    if diorama:
        diorama.queue_free()
    diorama = null
    diorama_cam = null


# ---------------------------------------------------------------- menus ----

func show_main_menu() -> void:
    set_meta("in_lobby", false)
    Net.stop_discovery()
    if Net.active and not Net.in_game:
        pass
    if Net.active and level == null:
        Net.leave()
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
    vb.add_child(UI.button("Meltdown (wave survival)", show_meltdown))
    vb.add_child(UI.button("Multiplayer (LAN)", show_multiplayer))
    vb.add_child(UI.button("Settings", show_settings))
    vb.add_child(UI.button("Controls", show_controls))
    vb.add_child(UI.button("Quit", func(): get_tree().quit()))
    var foot := UI.label("Difficulty: %s" % Game.DIFFICULTY_NAMES[Game.difficulty], 16, Color(0.7, 0.75, 0.6))
    vb.add_child(foot)


func show_campaign() -> void:
    var root := _new_ui(0.4)
    var vb := UI.centered_panel(root, 900)
    vb.add_child(UI.label("CAMPAIGN", 40, UI.ACCENT))
    vb.add_child(UI.label("Select an operation  -  %d / %d unlocked" % [mini(Game.unlocked_level + 1, LevelData.META.size()), LevelData.META.size()], 18))
    var grid := GridContainer.new()
    grid.columns = 2
    grid.add_theme_constant_override("h_separation", 12)
    grid.add_theme_constant_override("v_separation", 6)
    for i in LevelData.META.size():
        var m: Dictionary = LevelData.META[i]
        var locked: bool = i > Game.unlocked_level
        var title: String = m["name"].trim_prefix("Operation ")
        var b := UI.button(("%d.  %s" % [i + 1, title]) + ("   [LOCKED]" if locked else ""), func(): _news(NewsScripts.intro(i), func(): show_briefing(i)), 420)
        b.disabled = locked
        b.tooltip_text = m["location"]
        grid.add_child(b)
    vb.add_child(grid)
    vb.add_child(UI.button("Back", show_main_menu, 420))


func show_meltdown() -> void:
    var MM = load("res://scripts/meltdown_maps.gd")
    var root := _new_ui(0.55)
    var vb := UI.centered_panel(root, 1080)
    vb.add_child(UI.label("MELTDOWN", 44, Color(1.0, 0.6, 0.25)))
    vb.add_child(UI.label("Wave survival  -  how long can you hold out?", 19))
    vb.add_child(UI.label("Coins: hits +10, kills +60, headshot kills +100, boards +10.  Hold E to rebuild, tap E to buy.", 16, Color(0.85, 0.85, 0.75)))
    var grid := GridContainer.new()
    grid.columns = 3
    grid.add_theme_constant_override("h_separation", 22)
    grid.add_theme_constant_override("v_separation", 12)
    # More maps than fit on one screen: the list scrolls (wheel, drag or touch).
    var scroll := ScrollContainer.new()
    scroll.custom_minimum_size = Vector2(1040, 560)
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.add_child(grid)
    vb.add_child(scroll)
    for i in MM.META.size():
        var m: Dictionary = MM.META[i]
        var card := VBoxContainer.new()
        card.custom_minimum_size = Vector2(330, 0)
        card.add_theme_constant_override("separation", 2)
        card.tooltip_text = m["location"]
        card.add_child(UI.label(m["name"].to_upper(), 20, Color.WHITE))
        var blurb := UI.label(m.get("blurb", ""), 14)
        blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        blurb.custom_minimum_size = Vector2(330, 0)
        card.add_child(blurb)
        var best: int = Game.meltdown_best.get(i, 0)
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 16)
        row.add_child(UI.button("START", func(): start_level(LevelData.MELTDOWN_BASE + i), 150))
        row.add_child(UI.label("Best: wave %d" % best if best > 0 else "Best: -", 16, UI.ACCENT))
        card.add_child(row)
        grid.add_child(card)
    vb.add_child(UI.button("Back", show_main_menu, 300))


func _show_meltdown_end(stats: Dictionary) -> void:
    var MM = load("res://scripts/meltdown_maps.gd")
    var i: int = stats["level"] - LevelData.MELTDOWN_BASE
    var wave: int = stats.get("wave", 0)
    var prev: int = Game.meltdown_best.get(i, 0)
    if wave > prev:
        Game.meltdown_best[i] = wave
        Game.save()
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    var root := _new_ui(0.6)
    var vb := UI.centered_panel(root, 600)
    vb.add_child(UI.label("MELTED DOWN", 42, Color(1.0, 0.5, 0.25)))
    vb.add_child(UI.label("You survived to wave %d%s" % [wave, "  -  NEW BEST!" if wave > prev else ""], 24, Color.WHITE))
    vb.add_child(UI.label(MM.META[clampi(i, 0, MM.META.size() - 1)]["name"], 20))
    var secs := int(stats["time"])
    var grid := GridContainer.new()
    grid.columns = 2
    grid.add_theme_constant_override("h_separation", 50)
    for r in [["Time", "%02d:%02d" % [secs / 60, secs % 60]], ["Melties melted", str(stats["kills"])],
            ["Headshots", str(stats["headshots"])], ["Coins earned", str(stats.get("coins", 0))], ["Best wave", str(maxi(wave, prev))]]:
        grid.add_child(UI.label(r[0], 19, Color(0.8, 0.82, 0.7)))
        grid.add_child(UI.label(r[1], 19, Color.WHITE))
    vb.add_child(grid)
    vb.add_child(UI.button("Try Again", func(): start_level(stats["level"]), 520))
    vb.add_child(UI.button("Main Menu", show_main_menu, 520))


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
    var fresh: Array = LevelData.new_on(i)
    if not fresh.is_empty():
        vb.add_child(UI.label("NEW THIS OPERATION:  " + ", ".join(fresh), 18, Color(1.0, 0.85, 0.35)))
    var hb := HBoxContainer.new()
    hb.add_theme_constant_override("separation", 16)
    hb.add_child(UI.button("DEPLOY", func(): start_level(i), 300))
    hb.add_child(UI.button("Back", show_campaign, 200))
    vb.add_child(hb)


func show_settings() -> void:
    var root := _new_ui(0.4)
    var vb := UI.centered_panel(root, 1080)
    vb.add_child(UI.label("SETTINGS", 40, UI.ACCENT))
    var cols := HBoxContainer.new()
    cols.add_theme_constant_override("separation", 48)
    vb.add_child(cols)
    var left := VBoxContainer.new()
    var right := VBoxContainer.new()
    for c in [left, right]:
        c.add_theme_constant_override("separation", 10)
        c.custom_minimum_size = Vector2(500, 0)
        cols.add_child(c)
    var choice_row := func(parent: Control, title: String, opts: Array, current, pick: Callable, width := 160) -> void:
        parent.add_child(UI.label(title, 18))
        var row := HBoxContainer.new()
        for o in opts:
            var val = o[0]
            var b := UI.button(("> " if val == current else "") + str(o[1]), func(): pick.call(val), width)
            if val == current:
                b.add_theme_color_override("font_color", UI.ACCENT)
            row.add_child(b)
        parent.add_child(row)
    var check := func(parent: Control, text: String, on: bool, set_to: Callable) -> void:
        var cb := CheckBox.new()
        cb.text = text
        cb.button_pressed = on
        cb.toggled.connect(set_to)
        parent.add_child(cb)
    var slider_row := func(parent: Control, title: String, lo: float, hi: float, step: float, value: float, changed: Callable) -> void:
        parent.add_child(UI.label(title, 18))
        var sl := HSlider.new()
        sl.min_value = lo
        sl.max_value = hi
        sl.step = step
        sl.value = value
        sl.custom_minimum_size = Vector2(480, 24)
        sl.value_changed.connect(changed)
        parent.add_child(sl)

    # ---- left: gameplay ----
    choice_row.call(left, "Difficulty", [[0, "Recruit"], [1, "Regular"], [2, "Veteran"]], Game.difficulty, func(v):
        Game.difficulty = v
        Game.save()
        show_settings())
    slider_row.call(left, "Mouse sensitivity", 0.0005, 0.008, 0.0001, Game.mouse_sensitivity, func(v): Game.mouse_sensitivity = v)
    check.call(left, "Invert mouse Y", Game.invert_y, func(on): Game.invert_y = on)
    choice_row.call(left, "AI squadmates (single-player)", [[0, 0], [1, 1], [2, 2], [3, 3]], Game.squad_size, func(v):
        Game.squad_size = v
        Game.save()
        show_settings(), 110)
    check.call(left, "PNN news breaks between operations", Game.show_news, func(on): Game.show_news = on)
    check.call(left, "Narrator voices (reads the news aloud)", Game.narration, func(on): Game.narration = on)

    # ---- right: sound + graphics ----
    slider_row.call(right, "Music volume", 0.0, 1.0, 0.05, Game.music_volume, func(v):
        Game.music_volume = v
        Game.apply_volumes())
    slider_row.call(right, "Effects volume", 0.0, 1.0, 0.05, Game.sfx_volume, func(v):
        Game.sfx_volume = v
        Game.apply_volumes())
    choice_row.call(right, "Graphics quality  (Low if the game lags)", [[0, "Low"], [1, "Medium"], [2, "High"]], Game.graphics, func(v):
        Game.graphics = v
        Game.apply_graphics()
        Game.save()
        show_settings())
    choice_row.call(right, "Frame rate", [[0, "Match screen"], [60, "60 cap"], [120, "120 cap"]], Game.fps_cap, func(v):
        Game.fps_cap = v
        Game.apply_graphics()
        Game.save()
        show_settings())
    check.call(right, "Show FPS counter (in game)", Game.show_fps, func(on): Game.show_fps = on)
    check.call(right, "Auto resolution (smooth when busy)", Game.auto_res, func(on):
        Game.auto_res = on
        Game.apply_graphics())
    check.call(right, "On-screen touch controls", Game.touch_controls, func(on):
        Game.touch_controls = on
        Game.touch_mode = on)

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
        ["G", "Throw frag grenade"], ["E", "Get in / out of a jeep or tank"], ["T", "Squad: hold position / follow me"], ["F", "Call Reaper drone strike at crosshair"], ["Esc / P", "Pause"], ["In vehicles", "WASD drive, mouse aims the gun, LMB fire, RMB tank coax MG"],
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
    level.name = "Level"
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
    if stats.get("mode", "") == "meltdown":
        get_tree().paused = true
        if ui:
            ui.queue_free()
            ui = null
        _show_meltdown_end(stats)
        return
    if success:
        Game.unlock(i + 1)
        Game.play_ui("ui_confirm", -2.0)
    get_tree().paused = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if ui:
        ui.queue_free()
        ui = null
    if Net.active:
        _show_debrief(success, stats)       # LAN: straight to the debrief so the squad stays in step
    else:
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
            vb.add_child(UI.label("General Beige is a puddle. The house keeps its colours.\nCampaign complete - thanks for playing!", 19))
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
    if Net.active:
        if multiplayer.is_server():
            if success and not last:
                vb.add_child(UI.button("Next Operation (everyone)", func(): Net.start_game(i + 1), 520))
            vb.add_child(UI.button("Retry Operation (everyone)", func(): Net.start_game(i), 520))
            vb.add_child(UI.button("Back to Lobby", func(): Net.back_to_lobby(), 520))
        else:
            vb.add_child(UI.label("Waiting for the host to pick the next operation...", 17, Color(0.8, 0.85, 0.7)))
        vb.add_child(UI.button("Leave Game", func():
            Net.leave()
            show_main_menu(), 520))
        return
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


# ------------------------------------------------------------ multiplayer ----

func show_multiplayer() -> void:
    set_meta("in_lobby", false)
    Net.check_friends_soon()
    if Net.active:
        Net.leave()
    Net.start_discovery()
    var root := _new_ui(0.4)
    var vb := UI.centered_panel(root, 640)
    vb.add_child(UI.label("MULTIPLAYER", 40, UI.ACCENT))
    vb.add_child(UI.label("Co-op for up to 4 players - over the internet or on the same Wi-Fi.", 17))
    var row := HBoxContainer.new()
    row.add_child(UI.label("Your name  ", 19))
    var name_edit := LineEdit.new()
    name_edit.text = Game.player_name
    name_edit.max_length = 16
    name_edit.custom_minimum_size = Vector2(300, 40)
    name_edit.text_changed.connect(func(t):
        Game.player_name = t
        Game.save())
    row.add_child(name_edit)
    vb.add_child(row)
    vb.add_child(UI.label("Over the internet", 19, UI.ACCENT))
    vb.add_child(UI.button("Host an online game (get a code)", func():
        Net.stop_discovery()
        Net.host_online(Game.player_name)
        show_lobby(), 560))
    var code_row := HBoxContainer.new()
    var code_edit := LineEdit.new()
    code_edit.placeholder_text = "friend's game code, e.g. ZOOM"
    code_edit.max_length = 6
    code_edit.custom_minimum_size = Vector2(380, 40)
    code_row.add_child(code_edit)
    code_row.add_child(UI.button("Join online", func():
        Net.stop_discovery()
        Net.join_online(code_edit.text, Game.player_name)
        if Net.active:
            show_lobby(), 160))
    vb.add_child(code_row)
    _friends_section(vb)
    vb.add_child(UI.label("On the same Wi-Fi (LAN)", 19, UI.ACCENT))
    vb.add_child(UI.button("Host a LAN game", func():
        var err := Net.host(Game.player_name)
        if err != "":
            _mp_message(err)
        else:
            Net.stop_discovery()
            show_lobby(), 560))
    vb.add_child(UI.label("Games on your network", 17))
    var list := VBoxContainer.new()
    list.name = "HostList"
    vb.add_child(list)
    _fill_host_list(list)
    if not Net.hosts_changed.is_connected(_on_hosts_changed):
        Net.hosts_changed.connect(_on_hosts_changed)
    set_meta("host_list", list)
    var ip_row := HBoxContainer.new()
    var ip_edit := LineEdit.new()
    ip_edit.placeholder_text = "or type the host's IP, e.g. 192.168.1.20"
    ip_edit.custom_minimum_size = Vector2(380, 40)
    ip_row.add_child(ip_edit)
    ip_row.add_child(UI.button("Join", func(): _join(ip_edit.text), 160))
    vb.add_child(ip_row)
    vb.add_child(UI.label("Allow Plastic Platoon through Windows Firewall when asked (UDP ports 7777-7778).", 14, Color(0.75, 0.78, 0.68)))
    vb.add_child(UI.button("Back", show_main_menu, 560))


## Friends: your code to share, add a friend by code, who's playing now.
func _friends_section(vb: VBoxContainer) -> void:
    set_meta("in_friends", true)
    var head := HBoxContainer.new()
    head.add_child(UI.label("Friends   -   your friend code: ", 17))
    head.add_child(UI.label(Game.my_friend_code(), 20, Color(1.0, 0.85, 0.3)))
    vb.add_child(head)
    var add_row := HBoxContainer.new()
    var add_edit := LineEdit.new()
    add_edit.placeholder_text = "add a friend by their code"
    add_edit.max_length = 10
    add_edit.custom_minimum_size = Vector2(380, 36)
    add_row.add_child(add_edit)
    add_row.add_child(UI.button("Add", func():
        var err := Game.add_friend(add_edit.text)
        if err != "":
            add_edit.text = ""
            add_edit.placeholder_text = err
        else:
            Net.check_friends_soon()
            show_multiplayer(), 160))
    vb.add_child(add_row)
    # The list scrolls once there are more than a few friends.
    var list := VBoxContainer.new()
    if Game.friends.size() > 2:
        var sc := ScrollContainer.new()
        sc.custom_minimum_size = Vector2(560, 96)
        sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
        sc.add_child(list)
        vb.add_child(sc)
    else:
        vb.add_child(list)
    # Friends playing now first.
    var sorted: Array = Game.friends.duplicate()
    sorted.sort_custom(func(a, b): return Net.is_friend_online(a["code"]) and not Net.is_friend_online(b["code"]))
    for f in sorted:
        var row := HBoxContainer.new()
        var on: bool = Net.is_friend_online(f["code"])
        row.add_child(UI.label(("  ● " if on else "  ○ ") + "%s  (%s)%s" % [f["name"], f["code"], "  - playing now" if on else ""], 16,
            Color(0.55, 0.95, 0.45) if on else Color(0.7, 0.72, 0.65)))
        var code: String = f["code"]
        row.add_child(UI.button("Remove", func():
            Game.remove_friend(code)
            show_multiplayer(), 110))
        list.add_child(row)


## A friend invited us to their online game.
func _on_invite(who: String, room: String) -> void:
    if Net.active or level != null:
        return                       # busy: invites only pop up on the menus
    var root := _new_ui(0.55)
    var vb := UI.centered_panel(root, 560)
    vb.add_child(UI.label("INVITE!", 40, UI.ACCENT))
    vb.add_child(UI.label("%s wants you in their squad." % who, 22))
    vb.add_child(UI.button("Join %s's game" % who, func():
        Net.join_online(room, Game.player_name)
        if Net.active:
            show_lobby(), 480))
    vb.add_child(UI.button("Not now", show_main_menu, 480))


func _on_hosts_changed() -> void:
    var list = get_meta("host_list", null)
    if list != null and is_instance_valid(list):
        _fill_host_list(list)


func _fill_host_list(list: VBoxContainer) -> void:
    for c in list.get_children():
        c.queue_free()
    if Net.hosts.is_empty():
        list.add_child(UI.label("  Looking for games...", 17, Color(0.75, 0.78, 0.68)))
        return
    for ip in Net.hosts:
        var h: Dictionary = Net.hosts[ip]
        var full: bool = h["players"] >= Net.MAX_PLAYERS or h["started"]
        var b := UI.button("%s's game   (%d/%d)%s" % [h["name"], h["players"], Net.MAX_PLAYERS, "  - in progress" if h["started"] else ""], func(): _join(ip), 560)
        b.disabled = full
        list.add_child(b)


func _join(ip: String) -> void:
    if ip.strip_edges() == "":
        return
    Net.stop_discovery()
    Net.join(ip, Game.player_name)
    show_lobby()


func show_lobby() -> void:
    _clear_level()
    get_tree().paused = false
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if diorama == null:
        _build_diorama()
    set_meta("in_lobby", true)
    var root := _new_ui(0.4)
    var vb := UI.centered_panel(root, 600)
    var host: bool = Net.active and multiplayer.is_server()
    vb.add_child(UI.label("ONLINE LOBBY" if Net.online else "LOBBY", 40, UI.ACCENT))
    if Net.online:
        if Net.room_code == "":
            vb.add_child(UI.label("Getting a game code...", 20))
        else:
            vb.add_child(UI.label("Game code:  " + Net.room_code, 34, Color(1.0, 0.85, 0.3)))
            if host:
                vb.add_child(UI.label("Friends: Multiplayer > Join online > type this code.", 16, Color(0.8, 0.85, 0.7)))
    if not Net.active:
        vb.add_child(UI.label("Not connected.", 18))
    elif Net.players.is_empty():
        vb.add_child(UI.label("Connecting...", 18))
    else:
        vb.add_child(UI.label("Squad (%d/%d)" % [Net.players.size(), Net.MAX_PLAYERS], 19))
        var ids := Net.players.keys()
        ids.sort_custom(func(a, b): return Net.players[a]["slot"] < Net.players[b]["slot"])
        for id in ids:
            var tag := "  (host)" if id == 1 else ""
            tag += "  (you)" if id == Net.my_id() else ""
            vb.add_child(UI.label("  ■  " + Net.player_name(id) + tag, 20, Net.SLOT_COLORS[Net.players[id]["slot"] % 4].lightened(0.35)))
    if host and Net.online and Net.room_code != "":
        var on_now: Array = Game.friends.filter(func(f): return Net.is_friend_online(f["code"]))
        if not on_now.is_empty():
            vb.add_child(UI.label("Friends playing now", 17, UI.ACCENT))
            for f in on_now:
                var code: String = f["code"]
                var b := UI.button("Invite %s" % f["name"], func(): Net.invite_friend(code), 520)
                b.pressed.connect(func():
                    b.text = "Invited %s!" % f["name"]
                    b.disabled = true)
                vb.add_child(b)
    if host:
        vb.add_child(UI.label("Operation", 19, UI.ACCENT))
        var pick := OptionButton.new()
        for i in LevelData.META.size():
            pick.add_item("%d. %s" % [i + 1, LevelData.META[i]["name"]], i)
        # MELTDOWN maps too: hold off the waves together.
        var MM = load("res://scripts/meltdown_maps.gd")
        pick.add_separator("MELTDOWN")
        for i in MM.META.size():
            pick.add_item("MELTDOWN: %s" % MM.META[i]["name"], LevelData.MELTDOWN_BASE + i)
        var want: int = get_meta("mp_op", 0)
        pick.selected = maxi(0, pick.get_item_index(want))
        pick.item_selected.connect(func(idx): set_meta("mp_op", pick.get_item_id(idx)))
        pick.custom_minimum_size = Vector2(520, 44)
        vb.add_child(pick)
        vb.add_child(UI.button("START", func(): Net.start_game(get_meta("mp_op", 0)), 520))
    elif Net.active:
        vb.add_child(UI.label("Waiting for the host to start...", 17, Color(0.8, 0.85, 0.7)))
    vb.add_child(UI.button("Leave", func():
        Net.leave()
        show_multiplayer(), 520))


func _mp_message(text: String) -> void:
    set_meta("in_lobby", false)
    _clear_level()
    get_tree().paused = false
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if diorama == null:
        _build_diorama()
    var root := _new_ui(0.5)
    var vb := UI.centered_panel(root, 520)
    vb.add_child(UI.label("MULTIPLAYER", 34, UI.ACCENT))
    var l := UI.label(text, 19)
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.custom_minimum_size = Vector2(460, 0)
    vb.add_child(l)
    vb.add_child(UI.button("OK", show_multiplayer, 460))
