extends Control
## Mockups for the Crayon Box weapon screens (not used by the game).
## xvfb-run godot --path . res://tests/_crayon_ui_mockup.tscn -- <outdir>
## Saves draw_A/B/C.png (the drawing screen) and power_A/B/C.png (power menu).

const UI = preload("res://scripts/ui_util.gd")
const W := 1280
const H := 720
const RED := Color(0.86, 0.16, 0.14)
const ORANGE := Color(0.98, 0.55, 0.12)
const YELLOW := Color(0.98, 0.84, 0.2)
const GREEN := Color(0.3, 0.68, 0.24)
const BLUE := Color(0.2, 0.42, 0.88)
const PURPLE := Color(0.52, 0.27, 0.72)
const BLACK := Color(0.12, 0.12, 0.14)
const CRAYONS := [RED, ORANGE, YELLOW, GREEN, BLUE, PURPLE, BLACK, Color(0.55, 0.36, 0.2)]

# A kid's drawing of a blaster, in a 400 x 220 box: the outline, a drum, a
# scope and some flames on the side.
const GUN := [Vector2(40, 70), Vector2(250, 62), Vector2(262, 78), Vector2(372, 76), Vector2(380, 104),
    Vector2(262, 110), Vector2(255, 128), Vector2(176, 132), Vector2(160, 206), Vector2(118, 204),
    Vector2(128, 134), Vector2(80, 136), Vector2(36, 170), Vector2(8, 160), Vector2(16, 96)]
const SCOPE := [Vector2(110, 62), Vector2(116, 34), Vector2(212, 30), Vector2(220, 58)]

var out := ""
var seed_i := 0


class Paint extends Control:
    var fn: Callable
    func _draw() -> void:
        fn.call(self)


func _ready() -> void:
    out = OS.get_cmdline_user_args()[0]
    theme = UI.make_theme()
    size = Vector2(W, H)
    for v in ["A", "B", "C"]:
        await _shot("draw_" + v, Callable(self, "_draw_" + v))
    for v in ["A", "B", "C"]:
        await _shot("power_" + v, Callable(self, "_power_" + v))
    get_tree().quit()


func _shot(file: String, build: Callable) -> void:
    for c in get_children():
        c.queue_free()
    await get_tree().process_frame
    seed(7)
    build.call()
    for i in 4:
        await get_tree().process_frame
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, file])


# ------------------------------------------------------------- helpers ----

func _paint(rect: Rect2, fn: Callable) -> Paint:
    var p := Paint.new()
    p.fn = fn
    p.position = rect.position
    p.size = rect.size
    p.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(p)
    return p


func _label(text: String, pos: Vector2, size_px := 20, col := UI.TEXT, outline := 0, width := 0.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
    var l: Label = UI.label(text, size_px, col, outline)
    l.position = pos
    if width > 0.0:
        l.size.x = width
        l.horizontal_alignment = align
        l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    add_child(l)
    return l


func _button(text: String, rect: Rect2, hot := false) -> Button:
    var b := Button.new()
    b.text = text
    b.position = rect.position
    b.size = rect.size
    if hot:
        b.add_theme_stylebox_override("normal", UI._sb(UI.OLIVE_LIGHT, UI.ACCENT))
        b.add_theme_color_override("font_color", Color.WHITE)
    add_child(b)
    return b


## Game in the background, dimmed: the basement, blurred out.
func _backdrop(c: CanvasItem) -> void:
    c.draw_rect(Rect2(0, 0, W, H), Color(0.16, 0.14, 0.12))
    for i in 9:
        c.draw_rect(Rect2(i * 150 - 20, 380 + (i % 3) * 10, 130, 340), Color(0.24, 0.2, 0.16))
    c.draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.45))


## A wobbly crayon line: several thin passes with a little jitter, so it
## looks waxy instead of vector-perfect.
func _crayon(c: CanvasItem, pts: Array, col: Color, w: float, closed := true, jit := 1.6) -> void:
    var p2: Array = pts.duplicate()
    if closed:
        p2.append(pts[0])
    for pass_i in 4:
        var line := PackedVector2Array()
        for p in p2:
            line.append(p + Vector2(randf_range(-jit, jit), randf_range(-jit, jit)))
        var cc := col
        cc.a = 0.55
        c.draw_polyline(line, cc, w * randf_range(0.5, 0.9), true)


## Crayon scribble fill: zig-zag strokes clipped roughly inside a box.
func _scribble(c: CanvasItem, rect: Rect2, col: Color, step := 7.0) -> void:
    var x := rect.position.x
    var line := PackedVector2Array()
    var up := true
    while x < rect.end.x:
        line.append(Vector2(x, (rect.position.y if up else rect.end.y) + randf_range(-2, 2)))
        x += step + randf_range(-2, 2)
        up = not up
    var cc := col
    cc.a = 0.5
    c.draw_polyline(line, cc, 4.0, true)


func _xf(pts: Array, origin: Vector2, s: float) -> Array:
    return pts.map(func(p): return origin + p * s)


## The kid's drawing: red blaster, black outline, blue scope, orange flames,
## a yellow drum, and "PEW" written on it.
func _gun_drawing(c: CanvasItem, origin: Vector2, s: float, ink := BLACK, chalk := false) -> void:
    var body := _xf(GUN, origin, s)
    if not chalk:
        c.draw_colored_polygon(PackedVector2Array(body), Color(RED, 0.18))
        _scribble(c, Rect2(origin + Vector2(30, 70) * s, Vector2(220, 60) * s), RED, 8.0 * s)
        _scribble(c, Rect2(origin + Vector2(124, 136) * s, Vector2(40, 66) * s), RED, 7.0 * s)
        _scribble(c, Rect2(origin + Vector2(262, 80) * s, Vector2(112, 26) * s), Color(0.5, 0.5, 0.55), 6.0 * s)
    _crayon(c, body, ink, 6.0 * s)
    var sc := _xf(SCOPE, origin, s)
    if not chalk:
        _scribble(c, Rect2(sc[1], Vector2(96, 24) * s), BLUE, 6.0 * s)
    _crayon(c, sc, BLUE if not chalk else ink, 5.0 * s, false)
    var drum := []
    for i in 20:
        var a := i * TAU / 20.0
        drum.append(origin + (Vector2(190, 100) + Vector2(cos(a), sin(a)) * 30) * s)
    if not chalk:
        c.draw_colored_polygon(PackedVector2Array(drum), Color(YELLOW, 0.55))
    _crayon(c, drum, ink if chalk else ORANGE, 5.0 * s)
    # flames painted on the side
    var fl := [Vector2(48, 116), Vector2(70, 92), Vector2(78, 110), Vector2(96, 86), Vector2(104, 112), Vector2(120, 94), Vector2(124, 124)]
    _crayon(c, _xf(fl, origin, s), ORANGE if not chalk else ink, 4.0 * s, false)
    # muzzle zap
    for z in [[Vector2(392, 82), Vector2(420, 70)], [Vector2(394, 92), Vector2(428, 92)], [Vector2(392, 102), Vector2(420, 114)]]:
        _crayon(c, _xf(z, origin, s), YELLOW if not chalk else ink, 4.0 * s, false)


func _crayon_stick(c: CanvasItem, pos: Vector2, col: Color, selected: bool) -> void:
    var r := Rect2(pos + Vector2(0, 16), Vector2(26, 70))
    if selected:
        c.draw_rect(Rect2(pos - Vector2(6, 8), Vector2(38, 102)), Color(1, 1, 1, 0.25))
    c.draw_colored_polygon(PackedVector2Array([pos + Vector2(4, 16), pos + Vector2(13, 0), pos + Vector2(22, 16)]), col)
    c.draw_rect(r, col)
    c.draw_rect(Rect2(r.position + Vector2(0, 18), Vector2(26, 30)), col.darkened(0.35))
    c.draw_rect(Rect2(r.position + Vector2(4, 26), Vector2(18, 4)), Color(1, 1, 1, 0.35))


func _title(text: String, sub: String) -> void:
    _label(text, Vector2(0, 18), 34, UI.ACCENT, 6, W, HORIZONTAL_ALIGNMENT_CENTER)
    _label(sub, Vector2(0, 62), 18, UI.TEXT, 4, W, HORIZONTAL_ALIGNMENT_CENTER)


func _timer_badge(pos: Vector2) -> void:
    _paint(Rect2(pos, Vector2(150, 44)), func(c):
        c.draw_rect(Rect2(0, 0, 150, 44), Color(0.08, 0.1, 0.06, 0.9))
        c.draw_rect(Rect2(0, 0, 150, 44), UI.ACCENT.darkened(0.3), false, 2.0)
        c.draw_arc(Vector2(24, 22), 13, 0, TAU, 24, UI.TEXT, 2.0)
        c.draw_line(Vector2(24, 22), Vector2(24, 13), UI.TEXT, 2.0)
        c.draw_line(Vector2(24, 22), Vector2(31, 22), UI.TEXT, 2.0))
    _label("0:24", pos + Vector2(48, 8), 22)


# ------------------------------------------------------ drawing screens ----

## A: crayons on notebook paper, freehand only.
func _draw_A() -> void:
    _paint(Rect2(0, 0, W, H), _backdrop)
    _title("YOU FOUND THE CRAYON BOX!", "Draw any weapon you want. The game turns your drawing into a real gun.")
    var paper := Rect2(150, 110, 820, 500)
    _paint(paper, func(c):
        c.draw_rect(Rect2(6, 8, paper.size.x, paper.size.y), Color(0, 0, 0, 0.35))
        c.draw_rect(Rect2(Vector2.ZERO, paper.size), Color(0.98, 0.97, 0.92))
        var y := 60.0
        while y < paper.size.y:
            c.draw_line(Vector2(0, y), Vector2(paper.size.x, y), Color(0.55, 0.7, 0.9, 0.6), 1.5)
            y += 34
        c.draw_line(Vector2(70, 0), Vector2(70, paper.size.y), Color(0.9, 0.4, 0.4, 0.7), 2.0)
        for hy in [90, 250, 410]:
            c.draw_circle(Vector2(30, hy), 12, Color(0.16, 0.14, 0.12))
        _gun_drawing(c, Vector2(150, 120), 1.45))
    # crayon box on the right
    _paint(Rect2(1000, 110, 240, 500), func(c):
        c.draw_rect(Rect2(0, 0, 240, 360), Color(0.95, 0.78, 0.15))
        c.draw_rect(Rect2(0, 0, 240, 360), Color(0.3, 0.6, 0.2), false, 6.0)
        c.draw_rect(Rect2(0, 240, 240, 120), Color(0.3, 0.6, 0.2))
        for i in 8:
            _crayon_stick(c, Vector2(20 + (i % 4) * 55, 20 + (i / 4) * 110), CRAYONS[i], i == 0)
        for i in 3:
            var r := 6 + i * 6
            c.draw_circle(Vector2(50 + i * 70, 290), r, Color.WHITE if i == 1 else Color(1, 1, 1, 0.5)))
    _label("CRAYON SIZE", Vector2(1000, 436), 16, UI.TEXT, 0, 240, HORIZONTAL_ALIGNMENT_CENTER)
    _button("ERASER", Rect2(1000, 480, 115, 48))
    _button("UNDO", Rect2(1125, 480, 115, 48))
    _button("START OVER", Rect2(150, 636, 220, 52))
    _button("DONE  -  POWER IT UP  >", Rect2(670, 636, 300, 52), true)
    _timer_badge(Vector2(1000, 640))


## B: blueprint paper, chalk lines, a ruler that snaps lines straight.
func _draw_B() -> void:
    _paint(Rect2(0, 0, W, H), _backdrop)
    _title("SECRET WEAPON BLUEPRINT", "Draw your weapon. Hold SHIFT for straight lines. Tap a part to stamp it on.")
    var bp := Rect2(150, 110, 820, 500)
    _paint(bp, func(c):
        c.draw_rect(Rect2(Vector2.ZERO, bp.size), Color(0.1, 0.27, 0.55))
        var x := 0.0
        while x < bp.size.x:
            c.draw_line(Vector2(x, 0), Vector2(x, bp.size.y), Color(1, 1, 1, 0.12 if int(x) % 100 else 0.25), 1.0)
            x += 20
        var y := 0.0
        while y < bp.size.y:
            c.draw_line(Vector2(0, y), Vector2(bp.size.x, y), Color(1, 1, 1, 0.12 if int(y) % 100 else 0.25), 1.0)
            y += 20
        c.draw_rect(Rect2(12, 12, bp.size.x - 24, bp.size.y - 24), Color(1, 1, 1, 0.6), false, 2.0)
        _gun_drawing(c, Vector2(150, 120), 1.45, Color(0.95, 0.97, 1.0), true)
        # measurement marks
        c.draw_line(Vector2(160, 440), Vector2(560, 440), Color(1, 1, 1, 0.6), 2.0)
        c.draw_line(Vector2(160, 430), Vector2(160, 450), Color(1, 1, 1, 0.6), 2.0)
        c.draw_line(Vector2(560, 430), Vector2(560, 450), Color(1, 1, 1, 0.6), 2.0)
        c.draw_rect(Rect2(bp.size.x - 230, bp.size.y - 82, 210, 62), Color(1, 1, 1, 0.6), false, 2.0))
    _label("LENGTH: 1.2 m", Vector2(380, 560), 16, Color(1, 1, 1, 0.8))
    _label("TOP SECRET\nMODEL: ???", Vector2(752, 538), 16, Color(1, 1, 1, 0.85))
    # parts stamps
    _label("PARTS", Vector2(1000, 112), 20, UI.ACCENT)
    var parts := ["BARREL", "SCOPE", "DRUM", "STOCK", "GRIP", "BLADE"]
    for i in parts.size():
        var r := Rect2(1000 + (i % 2) * 120, 144 + (i / 2) * 104, 110, 94)
        _paint(r, Callable(self, "_part_icon").bind(i, r))
        _label(parts[i], r.position + Vector2(0, 66), 15, UI.TEXT, 0, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
    _button("CHALK", Rect2(1000, 470, 115, 46), true)
    _button("RULER", Rect2(1125, 470, 115, 46))
    _button("ERASE", Rect2(1000, 524, 115, 46))
    _button("UNDO", Rect2(1125, 524, 115, 46))
    _button("START OVER", Rect2(150, 636, 220, 52))
    _button("DONE  -  POWER IT UP  >", Rect2(670, 636, 300, 52), true)
    _timer_badge(Vector2(1000, 640))


## C: arts and crafts: paper taped to cardboard, markers and stickers.
func _draw_C() -> void:
    _paint(Rect2(0, 0, W, H), func(c):
        _backdrop(c)
        c.draw_rect(Rect2(110, 96, 1150, 610), Color(0.66, 0.5, 0.32))
        for i in 40:
            var y := 100.0 + i * 15.0
            c.draw_line(Vector2(110, y), Vector2(1260, y + randf_range(-3, 3)), Color(0.58, 0.43, 0.27, 0.6), 1.0))
    _title("ARTS & CRAFTS ARMORY", "Draw it with markers, then stick on stickers. Your weapon is born!")
    var paper := Rect2(150, 120, 800, 480)
    _paint(paper, func(c):
        c.draw_set_transform(Vector2(400, 240), deg_to_rad(-1.5), Vector2.ONE)
        c.draw_rect(Rect2(-400 + 6, -240 + 8, 800, 480), Color(0, 0, 0, 0.3))
        c.draw_rect(Rect2(-400, -240, 800, 480), Color(1, 1, 1))
        c.draw_set_transform(Vector2(0, 0), 0.0, Vector2.ONE)
        # tape on the corners
        for t in [[Vector2(-20, -10), 0.6], [Vector2(740, -14), -0.6], [Vector2(-18, 440), -0.6], [Vector2(742, 444), 0.6]]:
            c.draw_set_transform(t[0] + Vector2(40, 15), t[1], Vector2.ONE)
            c.draw_rect(Rect2(-45, -15, 90, 30), Color(0.95, 0.92, 0.7, 0.75))
        c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        _gun_drawing(c, Vector2(140, 110), 1.45)
        # stickers already placed: a star and a lightning bolt
        _star(c, Vector2(520, 170), 34, YELLOW)
        c.draw_colored_polygon(PackedVector2Array([Vector2(300, 140), Vector2(330, 140), Vector2(316, 168), Vector2(338, 168), Vector2(296, 216), Vector2(308, 180), Vector2(288, 180)]), Color(0.3, 0.75, 1.0)))
    # markers
    _paint(Rect2(980, 120, 260, 220), func(c):
        for i in 8:
            var p := Vector2(12 + (i % 4) * 62, 10 + (i / 4) * 104)
            c.draw_rect(Rect2(p, Vector2(36, 80)), Color(0.95, 0.95, 0.95))
            c.draw_rect(Rect2(p, Vector2(36, 26)), CRAYONS[i])
            c.draw_rect(Rect2(p + Vector2(4, 40), Vector2(28, 26)), CRAYONS[i].lightened(0.2))
            if i == 0:
                c.draw_rect(Rect2(p - Vector2(5, 5), Vector2(46, 90)), Color.WHITE, false, 3.0))
    _label("STICKERS", Vector2(980, 352), 20, Color(0.1, 0.08, 0.05))
    _paint(Rect2(980, 384, 260, 120), func(c):
        c.draw_rect(Rect2(0, 0, 260, 120), Color(0.92, 0.92, 0.95))
        _star(c, Vector2(40, 40), 24, YELLOW)
        c.draw_circle(Vector2(110, 40), 22, RED)
        c.draw_circle(Vector2(110, 40), 12, Color.WHITE)
        c.draw_circle(Vector2(110, 40), 5, RED)
        c.draw_colored_polygon(PackedVector2Array([Vector2(170, 18), Vector2(190, 18), Vector2(182, 36), Vector2(198, 36), Vector2(168, 66), Vector2(176, 44), Vector2(162, 44)]), Color(0.3, 0.75, 1.0))
        c.draw_circle(Vector2(230, 40), 20, Color(0.25, 0.7, 0.3))
        c.draw_circle(Vector2(223, 34), 4, Color.BLACK)
        c.draw_circle(Vector2(237, 34), 4, Color.BLACK)
        c.draw_arc(Vector2(230, 42), 10, 0.2, PI - 0.2, 10, Color.BLACK, 3.0)
        for i in 4:
            c.draw_rect(Rect2(12 + i * 62, 80, 50, 26), [ORANGE, PURPLE, GREEN, BLUE][i])
        c.draw_rect(Rect2(0, 0, 260, 120), Color(0.4, 0.4, 0.45), false, 2.0))
    _button("ERASER", Rect2(980, 520, 125, 46))
    _button("UNDO", Rect2(1115, 520, 125, 46))
    _button("START OVER", Rect2(150, 636, 220, 52))
    _button("DONE  -  POWER IT UP  >", Rect2(650, 636, 300, 52), true)
    _timer_badge(Vector2(1090, 640))


func _part_icon(c: CanvasItem, i: int, r: Rect2) -> void:
    c.draw_rect(Rect2(Vector2.ZERO, r.size), Color(0.1, 0.27, 0.55))
    c.draw_rect(Rect2(Vector2.ZERO, r.size), Color(1, 1, 1, 0.5), false, 2.0)
    var wcol := Color(1, 1, 1, 0.9)
    match i:
        0: c.draw_rect(Rect2(14, 30, 82, 14), wcol, false, 2.0)
        1:
            c.draw_rect(Rect2(24, 22, 62, 20), wcol, false, 2.0)
            c.draw_circle(Vector2(86, 32), 8, Color(0.1, 0.27, 0.55))
            c.draw_arc(Vector2(86, 32), 8, 0, TAU, 16, wcol, 2.0)
        2: c.draw_arc(Vector2(55, 36), 22, 0, TAU, 24, wcol, 2.0)
        3: c.draw_colored_polygon(PackedVector2Array([Vector2(20, 24), Vector2(90, 24), Vector2(90, 40), Vector2(30, 56), Vector2(16, 50)]), Color(1, 1, 1, 0.25))
        4: c.draw_rect(Rect2(44, 16, 22, 44), wcol, false, 2.0)
        5: c.draw_colored_polygon(PackedVector2Array([Vector2(14, 40), Vector2(80, 26), Vector2(98, 36), Vector2(80, 46)]), Color(1, 1, 1, 0.3))


func _star(c: CanvasItem, ctr: Vector2, r: float, col: Color) -> void:
    var pts := PackedVector2Array()
    for i in 10:
        var a := -PI / 2 + i * PI / 5
        pts.append(ctr + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
    c.draw_colored_polygon(pts, col)
    var outline := pts.duplicate()
    outline.append(pts[0])
    c.draw_polyline(outline, col.darkened(0.4), 2.0, true)


# --------------------------------------------------------- power menus ----

func _power_frame(title: String, sub: String) -> void:
    _paint(Rect2(0, 0, W, H), _backdrop)
    _title(title, sub)
    # their drawing, small, on a scrap of paper, with the name field under it
    _paint(Rect2(60, 120, 360, 250), func(c):
        c.draw_set_transform(Vector2(180, 125), deg_to_rad(-3), Vector2.ONE)
        c.draw_rect(Rect2(-176, -116, 352, 232), Color(0.98, 0.97, 0.92))
        c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        _gun_drawing(c, Vector2(30, 40), 0.72))
    _label("NAME YOUR WEAPON", Vector2(60, 392), 16, UI.ACCENT)
    var le := LineEdit.new()
    le.text = "THE BLASTINATOR 3000"
    le.position = Vector2(60, 418)
    le.size = Vector2(360, 46)
    le.add_theme_font_size_override("font_size", 22)
    add_child(le)
    _button("< REDRAW", Rect2(60, 636, 180, 52))


func _bar(c: CanvasItem, r: Rect2, f: float, col: Color) -> void:
    c.draw_rect(r, Color(0, 0, 0, 0.5))
    c.draw_rect(Rect2(r.position, Vector2(r.size.x * f, r.size.y)), col)
    c.draw_rect(r, UI.ACCENT.darkened(0.3), false, 2.0)


## A: sliders that share a pool of points, plus one special.
func _power_A() -> void:
    _power_frame("POWER IT UP", "Spend 15 power points. Every point makes one thing stronger.")
    var stats := [["DAMAGE", 5], ["FIRE RATE", 3], ["AMMO", 2], ["ACCURACY", 1], ["RANGE", 1]]
    var panel := Rect2(470, 120, 760, 480)
    _paint(panel, func(c):
        c.draw_rect(Rect2(Vector2.ZERO, panel.size), Color(0.08, 0.1, 0.06, 0.92))
        c.draw_rect(Rect2(Vector2.ZERO, panel.size), UI.ACCENT.darkened(0.4), false, 2.0)
        for i in stats.size():
            var y := 40 + i * 64
            var f: float = stats[i][1] / 6.0
            c.draw_rect(Rect2(230, y + 12, 380, 10), Color(0, 0, 0, 0.6))
            c.draw_rect(Rect2(230, y + 12, 380 * f, 10), UI.ACCENT)
            c.draw_circle(Vector2(230 + 380 * f, y + 17), 14, Color.WHITE)
            c.draw_circle(Vector2(230 + 380 * f, y + 17), 10, UI.ACCENT.darkened(0.2))
        c.draw_line(Vector2(30, 360), Vector2(730, 360), UI.ACCENT.darkened(0.5), 1.0))
    for i in stats.size():
        _label(stats[i][0], panel.position + Vector2(30, 40 + i * 64), 22)
        _label(str(stats[i][1]), panel.position + Vector2(640, 38 + i * 64), 24, UI.ACCENT)
    _label("SPECIAL (costs 3)", panel.position + Vector2(30, 376), 18, UI.ACCENT)
    var sp := ["NONE", "BOUNCY", "FIRE", "BOOM", "FREEZE"]
    for i in sp.size():
        _button(sp[i], Rect2(panel.position + Vector2(30 + i * 142, 410), Vector2(132, 46)), i == 3)
    _label("POINTS LEFT", Vector2(470, 618), 18)
    _label("0 / 15", Vector2(470, 640), 30, UI.ACCENT, 4)
    _button("FIRE AWAY!  >", Rect2(1000, 636, 230, 52), true)


## B: stack plastic bricks on each stat; the brick pile is the budget.
func _power_B() -> void:
    _power_frame("BUILD ITS POWER", "Stack up to 5 bricks on each stat. You have 14 bricks.")
    var stats := [["DAMAGE", 4, RED], ["FIRE RATE", 3, ORANGE], ["AMMO", 2, YELLOW], ["ACCURACY", 2, GREEN], ["RANGE", 1, BLUE], ["SPECIAL: BOUNCY", 2, PURPLE]]
    var panel := Rect2(470, 120, 760, 480)
    _paint(panel, func(c):
        c.draw_rect(Rect2(Vector2.ZERO, panel.size), Color(0.08, 0.1, 0.06, 0.92))
        c.draw_rect(Rect2(Vector2.ZERO, panel.size), UI.ACCENT.darkened(0.4), false, 2.0)
        for i in stats.size():
            var y := 26 + i * 74
            for b in 5:
                var r := Rect2(300 + b * 66, y, 58, 44)
                if b < stats[i][1]:
                    var col: Color = stats[i][2]
                    c.draw_rect(r, col)
                    c.draw_rect(Rect2(r.position, Vector2(58, 8)), col.lightened(0.25))
                    for s in 2:
                        c.draw_circle(r.position + Vector2(16 + s * 26, -2), 7, col.lightened(0.1))
                    c.draw_rect(r, col.darkened(0.4), false, 2.0)
                else:
                    c.draw_rect(r, Color(1, 1, 1, 0.12), false, 2.0))
    for i in stats.size():
        _label(stats[i][0], panel.position + Vector2(24, 34 + i * 74), 20)
        _button("-", Rect2(panel.position + Vector2(640, 26 + i * 74), Vector2(46, 44)))
        _button("+", Rect2(panel.position + Vector2(694, 26 + i * 74), Vector2(46, 44)))
    _label("BRICKS LEFT", Vector2(470, 618), 18)
    _label("0 / 14", Vector2(470, 640), 30, UI.ACCENT, 4)
    _button("FIRE AWAY!  >", Rect2(1000, 636, 230, 52), true)


## C: no numbers - pick 3 power cards.
func _power_C() -> void:
    _power_frame("PICK 3 POWERS", "Choose any three cards. Mix them up!")
    var cards := ["BIG HITS", "SUPER FAST", "HUGE MAG", "BOUNCY", "ON FIRE", "KA-BOOM", "LASER AIM", "TRIPLE SHOT"]
    var chosen := [0, 3, 7]
    for i in cards.size():
        var r := Rect2(470 + (i % 4) * 192, 120 + (i / 4) * 244, 178, 230)
        var on: bool = chosen.has(i)
        var col: Color = CRAYONS[i]
        _paint(r, Callable(self, "_card").bind(i, r, on, col))
        _label(cards[i], r.position + Vector2(0, 166), 20, Color(0.12, 0.12, 0.1) if on else Color(0.2, 0.2, 0.2), 0, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
    _label("3 / 3 PICKED", Vector2(470, 630), 26, UI.ACCENT, 4)
    _button("FIRE AWAY!  >", Rect2(1000, 636, 230, 52), true)


func _card(c: CanvasItem, i: int, r: Rect2, on: bool, col: Color) -> void:
    c.draw_rect(Rect2(Vector2.ZERO, r.size), Color(0.97, 0.95, 0.88) if on else Color(0.5, 0.5, 0.48))
    c.draw_rect(Rect2(10, 10, 158, 140), col if on else col.darkened(0.5))
    var ctr := Vector2(89, 80)
    match i:
        0: c.draw_circle(ctr, 44, Color.WHITE); c.draw_circle(ctr, 30, col)
        1:
            for k in 3: c.draw_line(Vector2(30, 50 + k * 28), Vector2(150, 50 + k * 28), Color.WHITE, 8.0)
        2:
            for k in 5: c.draw_rect(Rect2(36 + k * 22, 40, 14, 80), Color.WHITE)
        3: c.draw_polyline(PackedVector2Array([Vector2(26, 50), Vector2(70, 120), Vector2(110, 50), Vector2(150, 110)]), Color.WHITE, 8.0)
        4: c.draw_colored_polygon(PackedVector2Array([Vector2(89, 22), Vector2(104, 58), Vector2(118, 44), Vector2(130, 92), Vector2(116, 128), Vector2(62, 128), Vector2(48, 92), Vector2(62, 60), Vector2(74, 74)]), Color.WHITE)
        5: _star(c, ctr, 52, Color.WHITE)
        6: c.draw_line(Vector2(20, 80), Vector2(158, 80), Color.WHITE, 6.0); c.draw_circle(ctr, 20, Color.WHITE)
        7:
            for k in 3: c.draw_line(Vector2(30, 80), Vector2(150, 40 + k * 40), Color.WHITE, 7.0)
    if on:
        c.draw_rect(Rect2(Vector2.ZERO, r.size), UI.ACCENT, false, 6.0)
        c.draw_circle(Vector2(160, 18), 18, UI.ACCENT)
        c.draw_polyline(PackedVector2Array([Vector2(151, 18), Vector2(158, 26), Vector2(170, 10)]), Color.WHITE, 4.0)
    else:
        c.draw_rect(Rect2(Vector2.ZERO, r.size), Color(0, 0, 0, 0.35))
