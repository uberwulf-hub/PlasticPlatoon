extends CanvasLayer
## In-game HUD: vitals, ammo, ordnance, objective + waypoint, crosshair,
## hit markers, damage flash, sniper scope and center-screen messages.

const UI = preload("res://scripts/ui_util.gd")
const Weapons = preload("res://scripts/weapons.gd")

var player
var level
var root: Control
var overlay: Control
var vignette: ColorRect
var hp_bar: ProgressBar
var armor_bar: ProgressBar
var hp_label: Label
var weapon_label: Label
var ammo_label: Label
var slots_label: Label
var ord_label: Label
var obj_label: Label
var info_label: Label
var msg_label: Label
var prompt_label: Label
var team_label: Label
var zone_label: Label
var show_team := false
var msg_t := 0.0
var hit_t := 0.0
var hit_kill := false
var dmg_t := 0.0


func _ready() -> void:
    layer = 5
    root = Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.theme = UI.make_theme()
    add_child(root)

    vignette = ColorRect.new()
    vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
    vignette.color = Color(0.8, 0.0, 0.0, 0.0)
    vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(vignette)

    overlay = Control.new()
    overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    overlay.draw.connect(_draw_overlay)
    root.add_child(overlay)

    # Vitals (bottom-left)
    var vit := VBoxContainer.new()
    UI.place(vit, Vector2(0, 1), Rect2(28, -150, 360, 122))
    root.add_child(vit)
    hp_label = UI.label("HEALTH 100   ARMOR 25", 18, UI.TEXT, 6)
    vit.add_child(hp_label)
    hp_bar = _bar(Color(0.45, 0.8, 0.3))
    vit.add_child(hp_bar)
    armor_bar = _bar(Color(0.35, 0.55, 0.95))
    vit.add_child(armor_bar)
    ord_label = UI.label("", 18, Color(0.85, 0.9, 0.75), 6)
    vit.add_child(ord_label)

    # Weapon (bottom-right)
    var wp := VBoxContainer.new()
    wp.alignment = BoxContainer.ALIGNMENT_END
    UI.place(wp, Vector2(1, 1), Rect2(-480, -170, 452, 142))
    root.add_child(wp)
    weapon_label = UI.label("", 24, Color(1, 1, 1), 6)
    weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    wp.add_child(weapon_label)
    ammo_label = UI.label("", 44, Color(1, 0.92, 0.6), 8)
    ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    wp.add_child(ammo_label)
    slots_label = UI.label("", 15, Color(0.8, 0.85, 0.75), 5)
    slots_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    wp.add_child(slots_label)

    # Objective (top-left)
    var ob := VBoxContainer.new()
    UI.place(ob, Vector2(0, 0), Rect2(28, 22, 760, 90))
    root.add_child(ob)
    var ob_title := UI.label("OBJECTIVE", 15, UI.ACCENT, 5)
    ob.add_child(ob_title)
    obj_label = UI.label("", 22, Color(1, 1, 1), 6)
    ob.add_child(obj_label)

    info_label = UI.label("", 18, Color(0.9, 0.9, 0.85), 6)
    info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    UI.place(info_label, Vector2(1, 0), Rect2(-420, 22, 392, 60))
    root.add_child(info_label)

    team_label = UI.label("", 17, Color(0.8, 1.0, 0.7), 6)
    team_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    UI.place(team_label, Vector2(1, 0), Rect2(-420, 90, 392, 140))
    root.add_child(team_label)

    zone_label = UI.label("", 20, Color(0.55, 1.0, 0.55), 6)
    zone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    UI.place(zone_label, Vector2(0.5, 0), Rect2(-400, 96, 800, 30))
    root.add_child(zone_label)

    prompt_label = UI.label("", 22, Color(1, 1, 1), 6)
    prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    UI.place(prompt_label, Vector2(0.5, 0.5), Rect2(-400, 60, 800, 34))
    root.add_child(prompt_label)

    msg_label = UI.label("", 30, Color(1, 0.95, 0.7), 8)
    msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    UI.place(msg_label, Vector2(0.5, 0.0), Rect2(-700, 140, 1400, 50))
    root.add_child(msg_label)


func _bar(color: Color) -> ProgressBar:
    var b := ProgressBar.new()
    b.custom_minimum_size = Vector2(340, 16)
    b.show_percentage = false
    b.max_value = 100
    var bg := StyleBoxFlat.new()
    bg.bg_color = Color(0, 0, 0, 0.55)
    var fg := StyleBoxFlat.new()
    fg.bg_color = color
    b.add_theme_stylebox_override("background", bg)
    b.add_theme_stylebox_override("fill", fg)
    return b


func bind(p, lvl) -> void:
    player = p
    level = lvl
    p.stats_changed.connect(_refresh)
    p.hit_confirmed.connect(_on_hit)
    p.took_damage.connect(_on_damage)
    _refresh()


func show_message(text: String, dur := 2.5) -> void:
    msg_label.text = text
    msg_t = dur


func _on_hit(killed: bool) -> void:
    hit_t = 0.18
    hit_kill = killed


func _on_damage(amount: float) -> void:
    dmg_t = clampf(dmg_t + amount / 40.0, 0.0, 1.0)


func _refresh() -> void:
    if player == null:
        return
    if player.vehicle != null:
        _refresh_vehicle()
        return
    armor_bar.max_value = 100
    hp_bar.value = player.health
    armor_bar.value = player.armor
    hp_label.text = "HEALTH %d    ARMOR %d" % [int(ceil(player.health)), int(ceil(player.armor))]
    var w: Dictionary = player.cur()
    weapon_label.text = w["name"]
    if player.reload_t > 0.0:
        ammo_label.text = "RELOADING"
    else:
        ammo_label.text = "%d / %d" % [player.mag[player.current], player.reserve[player.current]]
    var parts: Array = []
    for i in Weapons.ORDER.size():
        var id: String = Weapons.ORDER[i]
        if player.owned.has(id):
            var nm: String = Weapons.DATA[id]["name"].split(" ")[0]
            parts.append(("[%d %s]" if id == player.current else "%d %s") % [i + 1, nm])
    slots_label.text = "   ".join(parts)
    ord_label.text = "FRAGS [G] x%d     DRONE [F] x%d" % [player.grenades, player.drones]


func _refresh_vehicle() -> void:
    var v = player.vehicle
    hp_bar.value = player.health
    armor_bar.max_value = v.k["hp"]
    armor_bar.value = v.hp
    hp_label.text = "HEALTH %d    VEHICLE %d / %d" % [int(ceil(player.health)), int(ceil(v.hp)), int(v.k["hp"])]
    weapon_label.text = v.k["name"]
    if v.kind == "tank":
        ammo_label.text = "CANNON READY" if v.fire_cd <= 0.0 else "LOADING %.1fs" % v.fire_cd
    else:
        ammo_label.text = "%d km/h" % int(absf(v.speed) * 3.6)
    slots_label.text = "LMB fire   %sE exit" % ("RMB coax MG   " if v.kind == "tank" else "")
    ord_label.text = "%d km/h" % int(absf(v.speed) * 3.6) if v.kind == "tank" else "Ram Tan soldiers to flatten them"
    if v.kind == "heli":
        var alt: float = v.altitude()
        slots_label.text = "LMB gun   RMB rockets   SPACE up   C down   E exit"
        ord_label.text = "ALT %d m" % int(alt) if alt < 900.0 else "ALT ---"
    if not level.squad.is_empty() and not v.passengers.is_empty():
        ord_label.text += "     SQUAD ABOARD %d/%d" % [v.passengers.size() - v.free_seats(), mini(level.squad.size(), v.passengers.size())]


func _process(delta: float) -> void:
    if player == null or level == null:
        return
    if msg_t > 0.0:
        msg_t -= delta
        msg_label.modulate.a = clampf(msg_t * 2.0, 0.0, 1.0)
    hit_t = maxf(0.0, hit_t - delta)
    dmg_t = maxf(0.0, dmg_t - delta * 0.9)
    vignette.color.a = dmg_t * 0.35 + (0.25 if not player.alive else 0.0)
    obj_label.text = level.get_objective_text()
    var watched = player.vehicle if player.vehicle != null else player
    if player.alive and level.in_safe_zone(watched.global_position):
        zone_label.text = "SAFE ZONE  -  Tan forces won't fire here" if level.is_protected(watched) else "SAFE ZONE  -  you fired, so you're exposed for a moment"
        zone_label.modulate = Color(1, 1, 1) if level.is_protected(watched) else Color(1.0, 0.8, 0.4)
    else:
        zone_label.text = ""
    if show_team:
        var lines := ["SQUAD"]
        lines.append("%s (you)  %s" % [Net.player_name(Net.my_id()), "%d HP" % int(ceil(player.health)) if player.alive else "DOWN"])
        for id in level.remotes:
            var r = level.remotes[id]
            lines.append("%s  %s" % [Net.player_name(id), ("%d HP" % int(ceil(r.health))) if r.alive else "DOWN"])
        team_label.text = "\n".join(lines)
    elif not level.squad.is_empty():
        var lines := ["SQUAD  -  %s  [T]" % ("HOLDING" if level.squad_hold else "FOLLOWING")]
        for m in level.squad:
            lines.append("%s  %s" % [m.display_name(), ("%d HP" % int(ceil(m.health))) if m.alive else "DOWN"])
        team_label.text = "\n".join(lines)
    var secs := int(level.elapsed)
    info_label.text = "TAN FORCES: %d\nTIME %02d:%02d" % [level.enemies_alive(), secs / 60, secs % 60]
    if player.vehicle != null:
        _refresh_vehicle()
        prompt_label.text = ""
    else:
        if player.reload_t > 0.0:
            ammo_label.text = "RELOADING"
        var near = level.nearest_vehicle(player.global_position, 4.5) if player.alive else null
        prompt_label.text = ("Press E to drive the %s" % near.kind.to_upper()) if near != null else ""
    overlay.queue_redraw()


func _draw_overlay() -> void:
    if player == null or not player.alive:
        return
    var size := overlay.size
    var c := size * 0.5
    var font := ThemeDB.fallback_font
    # Waypoint
    var pt = level.get_objective_point()
    if pt != null:
        var cam: Camera3D = overlay.get_viewport().get_camera_3d()
        var behind := cam.is_position_behind(pt)
        var sp := cam.unproject_position(pt)
        if behind:
            sp = size - sp
            sp.y = size.y - 60.0
        sp.x = clampf(sp.x, 40.0, size.x - 40.0)
        sp.y = clampf(sp.y, 90.0, size.y - 60.0)
        var col := Color(1.0, 0.85, 0.2, 0.95)
        var pts := PackedVector2Array([sp + Vector2(0, -12), sp + Vector2(10, 0), sp + Vector2(0, 12), sp + Vector2(-10, 0)])
        overlay.draw_colored_polygon(pts, col)
        var dist := int(player.global_position.distance_to(pt))
        overlay.draw_string(font, sp + Vector2(-40, 32), "%dm" % dist, HORIZONTAL_ALIGNMENT_CENTER, 80, 16, col)
    # Scope or crosshair
    if player.vehicle == null and player.is_scoped():
        var r := minf(size.x, size.y) * 0.42
        var w := size.length()
        overlay.draw_arc(c, r + w * 0.5, 0.0, TAU, 96, Color(0, 0, 0, 1), w)
        overlay.draw_arc(c, r, 0.0, TAU, 96, Color(0, 0, 0, 1), 4.0)
        overlay.draw_line(c - Vector2(r, 0), c + Vector2(r, 0), Color(0, 0, 0, 0.9), 1.5)
        overlay.draw_line(c - Vector2(0, r), c + Vector2(0, r), Color(0, 0, 0, 0.9), 1.5)
        overlay.draw_circle(c, 2.0, Color(1, 0.2, 0.1))
    else:
        var gap: float = 9.0 if player.vehicle != null else 5.0 + player.get_spread() * 7.0
        var col2 := Color(1, 1, 1, 0.9)
        for d in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
            overlay.draw_line(c + d * gap, c + d * (gap + 10.0), Color(0, 0, 0, 0.6), 4.0)
            overlay.draw_line(c + d * gap, c + d * (gap + 10.0), col2, 2.0)
        overlay.draw_circle(c, 1.6, col2)
    if hit_t > 0.0:
        var hc := Color(1.0, 0.25, 0.2) if hit_kill else Color(1, 1, 1)
        for d in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
            overlay.draw_line(c + d * 7.0, c + d * 15.0, hc, 2.5)
