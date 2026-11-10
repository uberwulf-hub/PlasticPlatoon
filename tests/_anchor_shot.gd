extends Node
## Close-ups of the PNN anchors (mouths) and Gary's boom mic.
func _ready() -> void:
    var out: String = OS.get_cmdline_user_args()[0]
    var NS = load("res://scripts/news_scripts.gd")
    var NB = load("res://scripts/news_break.gd")
    var nb = NB.new()
    nb.auto_advance = false
    nb.play(NS.intro(0))
    add_child(nb)
    for i in 10: await get_tree().process_frame
    # Chip close-up with his mouth forced open.
    nb.idx = 1
    nb._cut_to("chip")
    for i in 30: await get_tree().process_frame
    nb.chip.set_mouth(1.0); nb.chip.mouth.scale.y = 0.9
    nb.cam.position = Vector3(-1.35, 1.75, -0.2)
    nb.cam.look_at(Vector3(-1.35, 1.7, -1.35))
    await RenderingServer.frame_post_draw
    nb.vp.get_texture().get_image().save_png(out + "/chip.png")
    # Gary + boom: rest, then mid-bonk.
    nb._cut_to("gary")
    nb.shot_t = 0.0
    for i in 20: await get_tree().process_frame
    await RenderingServer.frame_post_draw
    nb.vp.get_texture().get_image().save_png(out + "/gary_rest.png")
    nb._bumping = 0.0
    for i in 14: await get_tree().process_frame
    await RenderingServer.frame_post_draw
    nb.vp.get_texture().get_image().save_png(out + "/gary_bonk.png")
    get_tree().quit()
