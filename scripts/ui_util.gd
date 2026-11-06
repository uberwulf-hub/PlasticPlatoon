extends RefCounted
## Small UI toolkit: military-olive theme plus label/button/panel helpers.

const OLIVE := Color(0.17, 0.22, 0.12, 0.94)
const OLIVE_LIGHT := Color(0.32, 0.42, 0.2, 0.98)
const ACCENT := Color(0.62, 0.78, 0.36)
const TEXT := Color(0.93, 0.95, 0.86)


static func make_theme() -> Theme:
    var t := Theme.new()
    t.default_font_size = 20
    var normal := _sb(OLIVE, ACCENT.darkened(0.3))
    var hover := _sb(OLIVE_LIGHT, ACCENT)
    var pressed := _sb(OLIVE.darkened(0.3), ACCENT)
    var disabled := _sb(Color(0.15, 0.15, 0.15, 0.8), Color(0.3, 0.3, 0.3))
    t.set_stylebox("normal", "Button", normal)
    t.set_stylebox("hover", "Button", hover)
    t.set_stylebox("pressed", "Button", pressed)
    t.set_stylebox("focus", "Button", hover)
    t.set_stylebox("disabled", "Button", disabled)
    t.set_color("font_color", "Button", TEXT)
    t.set_color("font_hover_color", "Button", Color.WHITE)
    t.set_color("font_disabled_color", "Button", Color(0.5, 0.5, 0.5))
    t.set_font_size("font_size", "Button", 22)
    var panel := _sb(Color(0.08, 0.1, 0.06, 0.9), ACCENT.darkened(0.4))
    panel.content_margin_left = 32
    panel.content_margin_right = 32
    panel.content_margin_top = 26
    panel.content_margin_bottom = 26
    t.set_stylebox("panel", "PanelContainer", panel)
    t.set_color("font_color", "Label", TEXT)
    t.set_color("font_color", "CheckBox", TEXT)
    return t


static func _sb(bg: Color, border: Color) -> StyleBoxFlat:
    var sb := StyleBoxFlat.new()
    sb.bg_color = bg
    sb.border_color = border
    sb.set_border_width_all(2)
    sb.set_corner_radius_all(3)
    sb.content_margin_left = 18
    sb.content_margin_right = 18
    sb.content_margin_top = 8
    sb.content_margin_bottom = 8
    return sb


static func label(text: String, size := 20, color := TEXT, outline := 0) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    if outline > 0:
        l.add_theme_constant_override("outline_size", outline)
        l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
    return l


static func button(text: String, cb: Callable, width := 340) -> Button:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = Vector2(width, 50)
    b.pressed.connect(func(): Game.play_ui("click", -8.0))
    b.pressed.connect(cb)
    return b


## Full-screen root with a centered panel; returns the panel's VBox.
static func centered_panel(parent: Node, min_width := 520) -> VBoxContainer:
    var center := CenterContainer.new()
    center.set_anchors_preset(Control.PRESET_FULL_RECT)
    parent.add_child(center)
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(min_width, 0)
    center.add_child(panel)
    var vb := VBoxContainer.new()
    vb.add_theme_constant_override("separation", 12)
    panel.add_child(vb)
    return vb


static func place(c: Control, anchor: Vector2, rect: Rect2) -> void:
    c.anchor_left = anchor.x
    c.anchor_right = anchor.x
    c.anchor_top = anchor.y
    c.anchor_bottom = anchor.y
    c.offset_left = rect.position.x
    c.offset_top = rect.position.y
    c.offset_right = rect.end.x
    c.offset_bottom = rect.end.y
