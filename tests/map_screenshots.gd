extends Node
## One establishing shot per map (needs a real renderer).
var main: Node
const VIEWS := [
    [0, Vector3(-6, 0.5, -20), 0.0, -0.05],     # desert: compound gate
    [1, Vector3(0, 0.5, 30), 0.0, 0.05],        # city: main street north
    [2, Vector3(-12, 0.5, 52), 0.35, -0.02],    # tabletop
]

func _ready() -> void:
    var out: String = OS.get_cmdline_user_args()[0]
    main = load("res://scenes/main.tscn").instantiate()
    add_child(main)
    await _frames(10)
    for v in VIEWS:
        main.start_level(v[0])
        await _frames(10)
        var p = main.level.player
        p.invulnerable = true
        for e in main.level.enemies:
            e.set_physics_process(false)
        p.global_position = v[1]
        p.rotation.y = v[2]
        p.pitch = v[3]
        await _frames(45)
        await RenderingServer.frame_post_draw
        get_viewport().get_texture().get_image().save_png(out + "/v3_map%d.png" % v[0])
        print("saved map ", v[0])
    get_tree().quit()

func _frames(n: int) -> void:
    for i in n:
        await get_tree().process_frame
