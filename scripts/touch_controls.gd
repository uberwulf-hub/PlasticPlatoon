extends CanvasLayer
## On-screen controls for phones and tablets (Game.touch_mode).
##  - Left half: a floating joystick wherever your thumb lands (moves / drives).
##    Pushing it all the way forward sprints.
##  - Right half: drag to look and aim (on foot or in a vehicle).
##  - Buttons on the right. They change with what you're doing: on foot you get
##    FIRE, AIM, JUMP, DUCK, RELOAD, NADE, DRONE, USE, SQUAD, SWAP and VIEW
##    (first person on/off); in a tank or jeep FIRE / FIRE 2 / EXIT; in a
##    helicopter UP / DOWN as well; on a street car or bike just EXIT. A button
##    with nothing to do is hidden (no drones left, no squad), and USE glows
##    when there's something to use.
##  - Players can drag the buttons where they like and pick a size
##    (Settings > Arrange touch buttons); that's this node with editing = true.
## Buttons send the same InputEventActions as the keyboard, so the player,
## vehicles and menus need no touch-specific code.

const STICK_RADIUS := 110.0
const LOOK_SENS := 0.0045
const SPRINT_PUSH := 0.9          # stick pushed this far forward = sprint

## id -> [default position (fraction of the screen), radius, label]. The id is
## the input action it sends, except "view", which is handled here.
const DEFAULTS := {
    "fire": [Vector2(0.88, 0.70), 78.0, "FIRE"],
    "aim": [Vector2(0.75, 0.80), 52.0, "AIM"],
    "jump": [Vector2(0.92, 0.45), 46.0, "JUMP"],
    "crouch": [Vector2(0.80, 0.55), 42.0, "DUCK"],
    "reload": [Vector2(0.68, 0.62), 40.0, "RELOAD"],
    "grenade": [Vector2(0.80, 0.33), 38.0, "NADE"],
    "drone": [Vector2(0.64, 0.25), 36.0, "DRONE"],
    "interact": [Vector2(0.66, 0.42), 44.0, "USE"],
    "squad_order": [Vector2(0.56, 0.20), 34.0, "SQUAD"],
    "next_weapon": [Vector2(0.93, 0.31), 38.0, "SWAP"],
    "view": [Vector2(0.72, 0.17), 32.0, "VIEW"],
    "pause": [Vector2(0.5, 0.07), 30.0, "II"],
}

var level: Node
var editing := false              # layout editor: drag buttons, nothing is sent
var root: Control
var buttons: Array = []           # [{"action", "label", "pos", "r", "shown", "glow"}]
var context := "foot"             # foot | vehicle | air | ride (see _context)
var _touch_role := {}             # touch index -> "stick" | "look" | button dict
var _stick_origin := Vector2.ZERO
var _stick_pos := Vector2.ZERO
var _stick_active := false
var _move := Vector2.ZERO         # last sent joystick vector
var _sprinting := false
var _drag_off := Vector2.ZERO     # editing: finger offset from the button centre


func setup(lvl: Node) -> void:
    level = lvl


func _ready() -> void:
    layer = 20
    process_mode = Node.PROCESS_MODE_ALWAYS
    root = Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.draw.connect(_draw_controls)
    add_child(root)
    for id in DEFAULTS:
        var d: Array = DEFAULTS[id]
        buttons.append({"action": id, "label": d[2], "pos": d[0], "r": d[1], "shown": true, "glow": false})
    apply_layout()
    if editing:
        visible = true


## Positions and size from Settings > Arrange touch buttons.
func apply_layout() -> void:
    for b in buttons:
        var p = Game.touch_layout.get(b["action"])
        b["pos"] = p if p is Vector2 else DEFAULTS[b["action"]][0]
        b["r"] = DEFAULTS[b["action"]][1] * Game.touch_size
    if root:
        root.queue_redraw()


func reset_layout() -> void:
    Game.touch_layout = {}
    Game.touch_size = 1.0
    Game.save()
    apply_layout()


func _screen() -> Vector2:
    return root.get_viewport_rect().size


func _k() -> float:
    return _screen().y / 900.0


func _button_at(p: Vector2) -> Variant:
    var s := _screen()
    var k := _k()
    var best = null
    var best_d := INF
    for b in buttons:
        if not b["shown"]:
            continue
        var d: float = p.distance_to(b["pos"] * s)
        if d < b["r"] * k * 1.15 and d < best_d:
            best = b
            best_d = d
    return best


func _input(event: InputEvent) -> void:
    if not visible:
        return
    if event is InputEventScreenTouch:
        _on_touch(event.index, event.position, event.pressed)
    elif event is InputEventScreenDrag:
        _on_drag(event.index, event.position, event.relative)
    elif editing and not DisplayServer.is_touchscreen_available():
        # The layout editor also works with a mouse (on a PC, or in tests).
        if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
            _on_touch(0, event.position, event.pressed)
        elif event is InputEventMouseMotion and _touch_role.has(0):
            _on_drag(0, event.position, event.relative)


func _on_touch(i: int, p: Vector2, pressed: bool) -> void:
    if editing:
        _edit_touch(i, p, pressed)
        return
    if pressed:
        var b = _button_at(p)
        if b != null:
            _touch_role[i] = b
            _press(b, true)
        elif p.x < _screen().x * 0.45 and not get_tree().paused:
            _touch_role[i] = "stick"
            _stick_origin = p
            _stick_pos = p
            _stick_active = true
        elif not get_tree().paused:
            _touch_role[i] = "look"
    else:
        var role = _touch_role.get(i)
        _touch_role.erase(i)
        if role is Dictionary:
            _press(role, false)
        elif role == "stick":
            _stick_active = false
            _set_move(Vector2.ZERO)
    root.queue_redraw()


func _on_drag(i: int, p: Vector2, rel: Vector2) -> void:
    var role = _touch_role.get(i)
    if editing:
        if role is Dictionary:
            var s := _screen()
            var np := (p + _drag_off) / s
            role["pos"] = Vector2(clampf(np.x, 0.04, 0.96), clampf(np.y, 0.05, 0.95))
            root.queue_redraw()
        return
    if role == "stick":
        _stick_pos = p
        var v := (p - _stick_origin) / (STICK_RADIUS * _k())
        if v.length() > 1.0:
            v = v.normalized()
        _set_move(v)
        root.queue_redraw()
    elif role == "look":
        look(rel)


func _press(b: Dictionary, pressed: bool) -> void:
    if b["action"] == "view":
        if pressed:
            toggle_view()
        return
    _send(b["action"], pressed)


## VIEW: first person on/off (on foot), or the next chase-camera distance in a
## vehicle. Phones have no mouse wheel.
func toggle_view() -> void:
    if level == null or level.player == null:
        return
    var p = level.player
    if p.vehicle != null:
        var steps := [0.7, 1.0, 1.5]
        var i := steps.find(snappedf(Game.vehicle_zoom, 0.1))
        Game.vehicle_zoom = steps[(i + 1) % steps.size()]
    else:
        Game.view_dist = 3.4 if p.first_person() else 0.0
    Game.save()


## Drag-to-look: turns the soldier (or the vehicle's camera).
func look(rel: Vector2) -> void:
    if level == null or level.player == null or get_tree().paused:
        return
    var target = level.player.vehicle if level.player.vehicle != null else level.player
    if target.has_method("look"):
        target.look(rel * LOOK_SENS / maxf(0.0001, Game.mouse_sensitivity))


func _set_move(v: Vector2) -> void:
    _move = v
    for pair in [["move_left", -v.x], ["move_right", v.x], ["move_forward", -v.y], ["move_back", v.y]]:
        var strength: float = maxf(0.0, pair[1])
        if strength > 0.08:
            Input.action_press(pair[0], strength)
        else:
            Input.action_release(pair[0])
    # All the way forward = sprint.
    var sprint := -v.y > SPRINT_PUSH * 0.95 and absf(v.x) < 0.45 and context == "foot"
    if sprint != _sprinting:
        _sprinting = sprint
        if sprint:
            Input.action_press("sprint")
        else:
            Input.action_release("sprint")


func _send(action: String, pressed: bool, strength := 1.0) -> void:
    var ev := InputEventAction.new()
    ev.action = action
    ev.pressed = pressed
    ev.strength = strength if pressed else 0.0
    Input.parse_input_event(ev)


func _process(_delta: float) -> void:
    if editing:
        _apply_context("foot")
        return
    var show: bool = Game.touch_mode and level != null and level.is_playing() and not get_tree().paused
    if visible != show:
        visible = show
        # In play, touches are ours (a tap mustn't also be a left-click = FIRE);
        # menus and the pause screen need the emulated mouse for their buttons.
        Input.emulate_mouse_from_touch = not show
        if not show:
            _release_all()
        root.queue_redraw()
    if visible:
        _apply_context(_context())
        root.queue_redraw()


## What the player is doing right now, which decides the buttons.
func _context() -> String:
    if level == null or level.player == null:
        return "foot"
    var v = level.player.vehicle
    if v == null:
        return "foot"
    if v.k.get("flies", false):
        return "air"
    if v.k.get("primary", "") == "none":
        return "ride"
    return "vehicle"


func _apply_context(ctx: String) -> void:
    var changed := ctx != context
    context = ctx
    var p = level.player if level != null else null
    var prompt := ""
    if level != null and level.get("hud") != null and level.hud.prompt_label != null:
        prompt = level.hud.prompt_label.text
    for b in buttons:
        var id: String = b["action"]
        var label: String = DEFAULTS[id][2]
        var shown := true
        match ctx:
            "foot":
                if id == "grenade" and p != null:
                    label = "NADE %d" % p.grenades
                if id == "drone" and p != null:
                    shown = editing or p.drones > 0
                if id == "squad_order":
                    shown = editing or (level != null and not level.squad.is_empty())
            "vehicle", "air", "ride":
                shown = id in ["interact", "squad_order", "view", "pause"]
                if id == "squad_order":
                    shown = level != null and not level.squad.is_empty()
                if ctx != "ride" and id in ["fire", "aim"]:
                    shown = true
                    label = "FIRE" if id == "fire" else "FIRE 2"
                if ctx == "air" and id in ["jump", "crouch"]:
                    shown = true
                    label = "UP" if id == "jump" else "DOWN"
                if id == "interact":
                    label = "EXIT"
        b["label"] = label
        b["glow"] = id == "interact" and prompt != "" and not editing
        if b["shown"] != shown:
            b["shown"] = shown
            if not shown:
                _drop_button(b)
    if changed:
        root.queue_redraw()


## A button that disappears under a finger lets go of its action.
func _drop_button(b: Dictionary) -> void:
    for i in _touch_role.keys():
        if _touch_role[i] == b:
            _touch_role.erase(i)
            _press(b, false)


func _exit_tree() -> void:
    if not editing:
        Input.emulate_mouse_from_touch = true
        _release_all()


func _release_all() -> void:
    for i in _touch_role.keys():
        var role = _touch_role[i]
        if role is Dictionary:
            _press(role, false)
    _touch_role.clear()
    _stick_active = false
    _set_move(Vector2.ZERO)


# ----------------------------------------------------- layout editor ----

func _edit_touch(i: int, p: Vector2, pressed: bool) -> void:
    if pressed:
        var b = _button_at(p)
        if b != null:
            _touch_role[i] = b
            _drag_off = b["pos"] * _screen() - p
    else:
        var role = _touch_role.get(i)
        _touch_role.erase(i)
        if role is Dictionary:
            Game.touch_layout[role["action"]] = role["pos"]
            Game.save()
    root.queue_redraw()


func set_size(f: float) -> void:
    Game.touch_size = clampf(f, 0.7, 1.4)
    apply_layout()


# --------------------------------------------------------------- draw ----

func _draw_controls() -> void:
    var s := _screen()
    var k := _k()
    var font := ThemeDB.fallback_font
    # Joystick (where the thumb is, or a hint where it can go).
    var base := _stick_origin if _stick_active else Vector2(s.x * 0.16, s.y * 0.72)
    root.draw_circle(base, STICK_RADIUS * k, Color(1, 1, 1, 0.08))
    root.draw_arc(base, STICK_RADIUS * k, 0.0, TAU, 48, Color(1, 1, 1, 0.35), 3.0)
    var knob := base + _move * STICK_RADIUS * k
    root.draw_circle(knob, 42.0 * k, Color(0.95, 0.75, 0.3, 0.6) if _sprinting else Color(0.55, 0.85, 0.4, 0.55))
    var held := []
    for r in _touch_role.values():
        if r is Dictionary:
            held.append(r)
    var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.008)
    for b in buttons:
        if not b["shown"]:
            continue
        var c: Vector2 = b["pos"] * s
        var rr: float = b["r"] * k
        var on := held.has(b)
        if b["glow"]:
            root.draw_circle(c, rr * (1.12 + 0.08 * pulse), Color(0.95, 0.85, 0.3, 0.25 + 0.25 * pulse))
        root.draw_circle(c, rr, Color(0.55, 0.85, 0.4, 0.55) if on else Color(0.1, 0.12, 0.08, 0.45))
        root.draw_arc(c, rr, 0.0, TAU, 40, Color(0.95, 0.85, 0.3, 0.95) if b["glow"] else Color(0.75, 0.95, 0.6, 0.8), 2.5)
        var fs := int(maxf(12.0, rr * 0.42))
        var w := font.get_string_size(b["label"], HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
        root.draw_string(font, c + Vector2(-w * 0.5, fs * 0.35), b["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.92))
