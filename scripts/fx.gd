extends RefCounted
## Stateless visual-effect and physics helpers built entirely from primitives.


static func ray(node: Node3D, from: Vector3, to: Vector3, mask: int, exclude: Array[RID] = []) -> Dictionary:
    var q := PhysicsRayQueryParameters3D.create(from, to, mask, exclude)
    return node.get_world_3d().direct_space_state.intersect_ray(q)


static func unlit(color: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    m.albedo_color = color
    return m


static func safe_look_at(n: Node3D, target: Vector3) -> void:
    var d := target - n.global_position
    if d.length_squared() < 0.0001:
        return
    var up := Vector3.UP
    if absf(d.normalized().dot(up)) > 0.98:
        up = Vector3.RIGHT
    n.look_at(target, up)


static func tracer(root: Node, from: Vector3, to: Vector3, color: Color) -> void:
    var length := from.distance_to(to)
    if length < 0.3:
        return
    var mi := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = Vector3(0.035, 0.035, 1.0)
    mi.mesh = bm
    var m := unlit(color)
    mi.material_override = m
    mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    root.add_child(mi)
    mi.global_position = (from + to) * 0.5
    safe_look_at(mi, to)
    mi.scale = Vector3(1, 1, length)
    var tw := mi.create_tween()
    tw.tween_property(m, "albedo_color:a", 0.0, 0.08)
    tw.tween_callback(mi.queue_free)


## Every shot used to make a real light. Now only flashes near the camera get
## one, and at most MAX_FLASH_LIGHTS at a time; the rest are just the glow ball.
const MAX_FLASH_LIGHTS := 4
static var _flash_lights := 0


static func muzzle_flash(root: Node, pos: Vector3) -> void:
    var cam: Camera3D = root.get_viewport().get_camera_3d() if root.is_inside_tree() else null
    var near: bool = cam != null and cam.global_position.distance_to(pos) < 25.0
    if not near or _flash_lights >= MAX_FLASH_LIGHTS:
        var ball := MeshInstance3D.new()
        var bs := SphereMesh.new()
        bs.radius = 0.12
        bs.height = 0.24
        ball.mesh = bs
        ball.material_override = unlit(Color(1.0, 0.85, 0.4, 0.9))
        ball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        root.add_child(ball)
        ball.global_position = pos
        ball.create_tween().tween_callback(ball.queue_free).set_delay(0.05)
        return
    _flash_lights += 1
    var l := OmniLight3D.new()
    l.light_color = Color(1.0, 0.75, 0.35)
    l.light_energy = 3.0
    l.omni_range = 5.0
    root.add_child(l)
    l.global_position = pos
    var mi := MeshInstance3D.new()
    var sm := SphereMesh.new()
    sm.radius = 0.12
    sm.height = 0.24
    mi.mesh = sm
    mi.material_override = unlit(Color(1.0, 0.85, 0.4, 0.9))
    l.add_child(mi)
    l.tree_exiting.connect(func(): _flash_lights = maxi(0, _flash_lights - 1))
    l.create_tween().tween_callback(l.queue_free).set_delay(0.05)


static func puff(root: Node, pos: Vector3, color: Color, size: float, life: float, rise := 0.6) -> void:
    var mi := MeshInstance3D.new()
    var sm := SphereMesh.new()
    sm.radius = 0.5
    sm.height = 1.0
    sm.radial_segments = 8
    sm.rings = 4
    mi.mesh = sm
    var m := unlit(color)
    mi.material_override = m
    mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    root.add_child(mi)
    mi.global_position = pos
    mi.scale = Vector3.ONE * size * 0.4
    var tw := mi.create_tween().set_parallel(true)
    tw.tween_property(mi, "scale", Vector3.ONE * size, life).set_ease(Tween.EASE_OUT)
    tw.tween_property(mi, "position:y", mi.position.y + rise, life)
    tw.tween_property(m, "albedo_color:a", 0.0, life)
    tw.chain().tween_callback(mi.queue_free)


static func impact(root: Node, pos: Vector3, normal: Vector3) -> void:
    puff(root, pos + normal * 0.1, Color(0.75, 0.68, 0.55, 0.7), 0.5, 0.35, 0.2)


static func blood_plastic(root: Node, pos: Vector3, color: Color) -> void:
    var c := color
    c.a = 0.9
    puff(root, pos, c, 0.35, 0.25, 0.1)


static func smoke_puff(root: Node, pos: Vector3) -> void:
    puff(root, pos, Color(0.85, 0.85, 0.85, 0.5), 0.9, 0.9, 0.5)


static func explosion(root: Node, pos: Vector3, radius: float) -> void:
    var n := Node3D.new()
    root.add_child(n)
    n.global_position = pos

    var fire := MeshInstance3D.new()
    var sm := SphereMesh.new()
    sm.radius = 0.5
    sm.height = 1.0
    fire.mesh = sm
    var fm := unlit(Color(1.0, 0.72, 0.25, 1.0))
    fire.material_override = fm
    fire.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    n.add_child(fire)
    fire.scale = Vector3.ONE * 0.3

    var smoke := MeshInstance3D.new()
    smoke.mesh = sm
    var smm := unlit(Color(0.35, 0.32, 0.28, 0.0))
    smoke.material_override = smm
    smoke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    n.add_child(smoke)
    smoke.scale = Vector3.ONE * minf(radius * 0.5, 2.0)

    var light := OmniLight3D.new()
    light.light_color = Color(1.0, 0.6, 0.25)
    light.light_energy = 10.0
    light.omni_range = minf(radius * 3.5, 14.0)
    n.add_child(light)

    var debris := CPUParticles3D.new()
    var dm := BoxMesh.new()
    dm.size = Vector3(0.18, 0.18, 0.18)
    debris.mesh = dm
    var dmat := StandardMaterial3D.new()
    dmat.albedo_color = Color(0.25, 0.22, 0.18)
    dm.material = dmat
    debris.amount = 16
    debris.lifetime = 1.4
    debris.one_shot = true
    debris.explosiveness = 1.0
    debris.direction = Vector3.UP
    debris.spread = 75.0
    debris.initial_velocity_min = radius * 1.2
    debris.initial_velocity_max = radius * 2.6
    debris.gravity = Vector3(0, -22, 0)
    debris.angular_velocity_min = -400.0
    debris.angular_velocity_max = 400.0
    n.add_child(debris)
    debris.emitting = true

    var tw := n.create_tween().set_parallel(true)
    tw.tween_property(fire, "scale", Vector3.ONE * radius * 1.4, 0.3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
    tw.tween_property(fm, "albedo_color", Color(1.0, 0.35, 0.1, 0.0), 0.55)
    tw.tween_property(smm, "albedo_color:a", 0.4, 0.3).set_delay(0.15)
    tw.tween_property(smoke, "scale", Vector3.ONE * minf(radius * 1.2, 4.5), 2.0).set_delay(0.15)
    tw.tween_property(smoke, "position:y", radius * 1.2, 2.0).set_delay(0.15)
    tw.tween_property(smm, "albedo_color:a", 0.0, 1.1).set_delay(0.5)
    tw.tween_property(light, "light_energy", 0.0, 0.6)
    tw.tween_callback(n.queue_free).set_delay(2.2)


## Burning wrecks used to burn forever, and every one is a cloud of see-through
## particles (costly to draw). Now each fire dies down after `life` seconds
## (0 = keep burning, e.g. a camp fire), and only MAX_FIRES burn at once: the
## oldest dies down early when a new one starts.
const MAX_FIRES := 4
static var _fires: Array = []


static func fire(root: Node, pos: Vector3, size := 1.0, life := 25.0) -> CPUParticles3D:
    var p := CPUParticles3D.new()
    var sm := SphereMesh.new()
    sm.radius = 0.35 * size
    sm.height = 0.7 * size
    sm.radial_segments = 8
    sm.rings = 4
    var m := StandardMaterial3D.new()
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    m.vertex_color_use_as_albedo = true
    sm.material = m
    p.mesh = sm
    p.amount = 16
    p.lifetime = 1.2
    p.direction = Vector3.UP
    p.spread = 15.0
    p.gravity = Vector3(0, 3.0, 0)
    p.initial_velocity_min = 1.0
    p.initial_velocity_max = 2.5
    p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
    p.emission_sphere_radius = 0.8 * size
    var g := Gradient.new()
    g.set_color(0, Color(1.0, 0.85, 0.3, 0.9))
    g.set_color(1, Color(0.15, 0.13, 0.12, 0.0))
    g.add_point(0.35, Color(1.0, 0.4, 0.1, 0.8))
    p.color_ramp = g
    root.add_child(p)
    p.global_position = pos
    p.emitting = true
    if life > 0.0:
        _fires = _fires.filter(func(f): return is_instance_valid(f) and not f.has_meta("dying"))
        _fires.append(p)
        if _fires.size() > MAX_FIRES:
            die_down(_fires.pop_front(), 0.0)
        die_down(p, life)
    return p


## The fire shrinks to nothing over 4 s (after `delay`), then is removed.
static func die_down(p: CPUParticles3D, delay: float) -> void:
    if not is_instance_valid(p) or p.has_meta("dying"):
        return
    p.set_meta("dying", delay <= 0.0)
    var tw := p.create_tween()
    tw.tween_interval(delay)
    tw.tween_callback(func(): p.set_meta("dying", true))
    tw.tween_property(p, "scale_amount_max", 0.0, 4.0)
    tw.parallel().tween_property(p, "scale_amount_min", 0.0, 4.0)
    tw.tween_callback(func(): p.emitting = false)
    tw.tween_interval(p.lifetime + 0.2)
    tw.tween_callback(p.queue_free)


## Fires still burning (tests read it).
static func fires_burning() -> int:
    return _fires.filter(func(f): return is_instance_valid(f) and not f.has_meta("dying")).size()
