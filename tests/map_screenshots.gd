extends Node
## One establishing shot per map (needs a real renderer).
var main: Node
const VIEWS := [
    [0, Vector3(-6, 0.5, -20), 0.0, -0.05],     # desert: compound gate
    [1, Vector3(0, 0.5, 30), 0.0, 0.05],        # city: main street north
    [2, Vector3(-12, 0.5, 52), 0.35, -0.02],    # tabletop
    [3, Vector3(0, 0.5, -12), 0.0, 0.0],        # snow globe: radar station
    [4, Vector3(10, 0.5, -28), 0.3, 0.05],      # green hell: temple
    [5, Vector3(0, 0.5, 20), 0.0, 0.08],        # bath time
    [6, Vector3(10, 0.5, 60), 0.0, 0.0],        # beachhead
    [7, Vector3(0, 0.5, 40), 0.0, 0.05],        # sandbox
    [8, Vector3(0, 0.5, 60), 0.0, 0.05],        # night shift
    [9, Vector3(0, 0.5, 30), 0.0, 0.05],        # bunk bed
    [10, Vector3(0, 0.5, 40), 0.0, 0.08],       # mountain pass
    [11, Vector3(0, 0.5, 30), 0.0, 0.1],        # garage sale
    [12, Vector3(0, 0.5, 40), 0.0, 0.12],       # beige dawn
]

func _ready() -> void:
    var out: String = OS.get_cmdline_user_args()[0]
    main = load("res://scenes/main.tscn").instantiate()
    add_child(main)
    await _frames(10)
    var only: Array = []
    for a in OS.get_cmdline_user_args().slice(1):
        only.append(int(a))
    for v in VIEWS:
        if not only.is_empty() and not only.has(v[0]):
            continue
        main.start_level(v[0])
        await _frames(10)
        var p = main.level.player
        p.invulnerable = true
        for e in main.level.enemies + main.level.enemy_vehicles:
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
