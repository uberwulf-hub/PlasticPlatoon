extends CanvasLayer
## On-screen controls for phones and tablets (Game.touch_mode).
##  - Left half: a floating joystick wherever your thumb lands (moves / drives).
##  - Right half: drag to look and aim (on foot or in a vehicle).
##  - Buttons on the right: FIRE (hold), AIM (hold), JUMP, CROUCH, RELOAD,
##    GRENADE, DRONE, USE (E), SQUAD (T), SWAP (next weapon) and pause.
## Buttons send the same InputEventActions as the keyboard, so the player,
## vehicles and menus need no touch-specific code.

const STICK_RADIUS := 110.0
const LOOK_SENS := 0.0045

var level: Node
var root: Control
var buttons: Array = []          # [{"action", "label", "pos" (fraction of screen), "r", "hold"}]
var _touch_role := {}            # touch index -> "stick" | "look" | button dict
var _stick_origin := Vector2.ZERO
var _stick_pos := Vector2.ZERO
var _stick_active := false
var _move := Vector2.ZERO        # last sent joystick vector


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
    # Positions are fractions of the screen so they suit any phone.
    for b in [
        ["fire", "FIRE", Vector2(0.88, 0.70), 78.0],
        ["aim", "AIM", Vector2(0.75, 0.80), 52.0],
        ["jump", "JUMP", Vector2(0.92, 0.45), 46.0],
        ["crouch", "DUCK", Vector2(0.80, 0.55), 42.0],
        ["reload", "RELOAD", Vector2(0.68, 0.62), 40.0],
        ["grenade", "NADE", Vector2(0.80, 0.33), 38.0],
        ["drone", "DRONE", Vector2(0.62, 0.84), 36.0],
        ["interact", "USE", Vector2(0.66, 0.42), 44.0],
        ["squad_order", "SQUAD", Vector2(0.56, 0.20), 34.0],
        ["next_weapon", "SWAP", Vector2(0.92, 0.22), 38.0],
        ["pause", "II", Vector2(0.5, 0.07), 30.0],
    ]:
        buttons.append({"action": b[0], "label": b[1], "pos": b[2], "r": b[3]})


func _screen() -> Vector2:
    return root.get_viewport_rect().size


func _button_at(p: Vector2) -> Variant:
    var s := _screen()
    var k := s.y / 900.0
    for b in buttons:
        if p.distance_to(b["pos"] * s) < b["r"] * k * 1.15:
            return b
    return null


func _input(event: InputEvent) -> void:
    if not visible:
        return
    if event is InputEventScreenTouch:
        _on_touch(event.index, event.position, event.pressed)
    elif event is InputEventScreenDrag:
        _on_drag(event.index, event.position, event.relative)


func _on_touch(i: int, p: Vector2, pressed: bool) -> void:
    if pressed:
        var b = _button_at(p)
        if b != null:
            _touch_role[i] = b
            _send(b["action"], true)
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
            _send(role["action"], false)
        elif role == "stick":
            _stick_active = false
            _set_move(Vector2.ZERO)
    root.queue_redraw()


func _on_drag(i: int, p: Vector2, rel: Vector2) -> void:
    var role = _touch_role.get(i)
    if role == "stick":
        _stick_pos = p
        var v := (p - _stick_origin) / STICK_RADIUS
        if v.length() > 1.0:
            v = v.normalized()
        _set_move(v)
        root.queue_redraw()
    elif role == "look":
        look(rel)


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


func _send(action: String, pressed: bool, strength := 1.0) -> void:
    var ev := InputEventAction.new()
    ev.action = action
    ev.pressed = pressed
    ev.strength = strength if pressed else 0.0
    Input.parse_input_event(ev)


func _process(_delta: float) -> void:
    var show: bool = Game.touch_mode and level != null and level.is_playing() and not get_tree().paused
    if visible != show:
        visible = show
        # In play, touches are ours (a tap mustn't also be a left-click = FIRE);
        # menus and the pause screen need the emulated mouse for their buttons.
        Input.emulate_mouse_from_touch = not show
        if not show:
            _release_all()
        root.queue_redraw()


func _exit_tree() -> void:
    Input.emulate_mouse_from_touch = true
    _release_all()


func _release_all() -> void:
    for i in _touch_role.keys():
        var role = _touch_role[i]
        if role is Dictionary:
            _send(role["action"], false)
    _touch_role.clear()
    _stick_active = false
    _set_move(Vector2.ZERO)


func _draw_controls() -> void:
    var s := _screen()
    var k := s.y / 900.0
    var font := ThemeDB.fallback_font
    # Joystick (where the thumb is, or a hint where it can go).
    var base := _stick_origin if _stick_active else Vector2(s.x * 0.16, s.y * 0.72)
    root.draw_circle(base, STICK_RADIUS * k, Color(1, 1, 1, 0.08))
    root.draw_arc(base, STICK_RADIUS * k, 0.0, TAU, 48, Color(1, 1, 1, 0.35), 3.0)
    var knob := base + _move * STICK_RADIUS * k
    root.draw_circle(knob, 42.0 * k, Color(0.55, 0.85, 0.4, 0.55))
    var held := []
    for r in _touch_role.values():
        if r is Dictionary:
            held.append(r["action"])
    for b in buttons:
        var c: Vector2 = b["pos"] * s
        var rr: float = b["r"] * k
        var on := held.has(b["action"])
        root.draw_circle(c, rr, Color(0.55, 0.85, 0.4, 0.55) if on else Color(0.1, 0.12, 0.08, 0.45))
        root.draw_arc(c, rr, 0.0, TAU, 40, Color(0.75, 0.95, 0.6, 0.8), 2.5)
        var fs := int(maxf(12.0, rr * 0.42))
        var w := font.get_string_size(b["label"], HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
        root.draw_string(font, c + Vector2(-w * 0.5, fs * 0.35), b["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.92))
