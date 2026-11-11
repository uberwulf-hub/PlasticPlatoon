extends Node
## Close-ups of Gary and his boom mic: at rest, at the moment it lands on his
## helmet (front and side views), and mid-stagger. Needs a real renderer:
## godot --rendering-method gl_compatibility --path . res://tests/_anchor_shot.tscn -- <outdir>
func _ready() -> void:
    var out: String = OS.get_cmdline_user_args()[0]
    var NS = load("res://scripts/news_scripts.gd")
    var NB = load("res://scripts/news_break.gd")
    var nb = NB.new()
    nb.auto_advance = false
    nb.play(NS.intro(0))
    add_child(nb)
    for i in 10: await get_tree().process_frame
    nb._cut_to("gary")
    nb.shot_t = 0.0
    for i in 20: await get_tree().process_frame
    print("helmet top %.3f  mic rest %.3f" % [nb.helmet_top(), nb.boom.position.y - nb.MIC_R])
    print("gary ", nb.gary.global_position, " head ", nb.gary.torso.global_position, " boom ", nb.boom.global_position, " cam ", nb.cam.global_position)
    for mi in nb.gary.find_children("*", "MeshInstance3D", true, false):
        if mi.is_visible_in_tree():
            print("  mesh ", mi.name, " ", mi.global_transform * mi.get_aabb())
    await _save(nb, out + "/gary_rest.png")
    nb._bump_t = 0.0
    while nb.bonks == 0:
        await get_tree().process_frame
    var front: Transform3D = nb.cam.global_transform
    await _save(nb, out + "/gary_contact.png")
    var g: Vector3 = nb.gary.global_position
    nb.cam.global_position = g + Vector3(2.6, 1.9, 0.0)
    nb.cam.look_at(g + Vector3(0, 1.8, 0))
    nb.set_process(false)
    await _save(nb, out + "/gary_contact_side.png")
    nb.set_process(true)
    nb.cam.global_transform = front
    nb._knock = 0.15                     # mid-stagger (frames are slow on CI renderers)
    nb.set_process(false)
    nb._update_knock(0.0)
    await _save(nb, out + "/gary_knocked.png")
    print("bonks %d  closest gap %.3f  gary %s rot %s knock %.2f" % [nb.bonks, nb.boom_gap, nb.gary.position, nb.gary.rotation, nb._knock])
    get_tree().quit()


func _save(nb, path: String) -> void:
    await RenderingServer.frame_post_draw
    nb.vp.get_texture().get_image().save_png(path)
