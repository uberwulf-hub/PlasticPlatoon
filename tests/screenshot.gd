extends Node
## Renders screenshots of the menu and each operation (needs a real renderer).
## Run: godot --rendering-method gl_compatibility --path . res://tests/screenshot.tscn -- <outdir>

var main: Node


func _ready() -> void:
    var args := OS.get_cmdline_user_args()
    var out: String = args[0] if args.size() > 0 else "user://shots"
    DirAccess.make_dir_recursive_absolute(out)
    main = load("res://scenes/main.tscn").instantiate()
    add_child(main)
    await _frames(90)
    await _shot(out + "/0_menu.png")
    for i in 3:
        main.start_level(i)
        await _frames(20)
        var L = main.level
        var p = L.player
        p.invulnerable = true
        p.pitch = -0.08
        await _frames(40)
        await _shot(out + "/%d_level_start.png" % (i + 1))
        # Walk toward the action and fire.
        var target = L.get_objective_point()
        if target != null:
            var d: Vector3 = target - p.global_position
            p.rotation.y = atan2(-d.x, -d.z)
            p.global_position += Vector3(d.x, 0, d.z).normalized() * (Vector3(d.x, 0, d.z).length() * 0.55)
            p.global_position.y = 6.0
        await _frames(120)
        p.aiming = true
        for k in 6:
            p.fire_cd = 0.0
            p._fire(p.cur())
            await _frames(4)
        p._throw_grenade()
        await _frames(160)
        p._equip("launcher") if p.owned.has("launcher") else null
        p.fire_cd = 0.0
        p.reload_t = 0.0
        p._fire(p.cur())
        await _frames(22)
        await _shot(out + "/%d_level_combat.png" % (i + 1))
    get_tree().quit()


func _frames(n: int) -> void:
    for i in n:
        await get_tree().process_frame


func _shot(path: String) -> void:
    await RenderingServer.frame_post_draw
    var img := get_viewport().get_texture().get_image()
    img.save_png(path)
    print("saved ", path)
