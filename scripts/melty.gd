extends CharacterBody3D
## MELTDOWN mode enemy: a half-melted Tan soldier. It spawns outside the
## basement, shambles to its assigned barricade, tears the planks off, climbs
## through, then hunts the nearest green soldier with the navigation mesh and
## swipes at them. Later waves make them tougher, faster and harder-hitting.

const Soldier = preload("res://scripts/plastic_soldier.gd")
const Fx = preload("res://scripts/fx.gd")

const MELT_TAN := Color(0.74, 0.55, 0.36)
const GRAVITY := 16.0
const REACH := 1.7

enum { OUTSIDE, BREAKING, CLIMBING, HUNTING }

var level: Node
var mode: Node                    # the Meltdown controller
var barricade: Node
var hp := 60.0
var max_hp := 60.0
var speed := 2.0
var damage := 20.0
var alive := true
var model
var state := OUTSIDE
var agent: NavigationAgent3D
var _attack_cd := 0.0
var _tear_cd := 0.0
var _repath_t := 0.0
var _stuck_t := 0.0
var _groan_t := 0.0
var _target = null
var type := "melty"               # read by shared code that expects enemies to have a type


func setup(lvl: Node, md: Node, b: Node, pos: Vector3, wave_hp: float, wave_speed: float, wave_damage: float) -> void:
    level = lvl
    mode = md
    barricade = b
    position = pos
    hp = wave_hp
    max_hp = wave_hp
    speed = wave_speed
    damage = wave_damage


func _ready() -> void:
    add_to_group("enemies")
    add_to_group("damageable")
    collision_layer = 4
    collision_mask = 1 | 4
    floor_snap_length = 0.4
    var cap := CapsuleShape3D.new()
    cap.radius = 0.35
    cap.height = 1.7
    var cs := CollisionShape3D.new()
    cs.shape = cap
    cs.position.y = 0.85
    add_child(cs)
    model = Soldier.create()
    add_child(model)
    var c := MELT_TAN.lerp(Color(0.6, 0.42, 0.3), randf() * 0.5)
    model.build(c, "none")
    # Melted: shorter, lumpier, leaning forward, with drips of plastic on it.
    model.scale = Vector3(1.08, randf_range(0.8, 0.9), 1.08)
    model.rotation.x = deg_to_rad(randf_range(8.0, 16.0))
    var drip := StandardMaterial3D.new()
    drip.albedo_color = c.darkened(0.15)
    drip.roughness = 0.15
    for i in 4:
        var d := MeshInstance3D.new()
        var sm := SphereMesh.new()
        sm.radius = randf_range(0.07, 0.13)
        sm.height = sm.radius * randf_range(2.2, 3.2)
        d.mesh = sm
        d.material_override = drip
        d.position = Vector3(randf_range(-0.25, 0.25), randf_range(0.9, 1.6), randf_range(-0.2, 0.2))
        add_child(d)
    agent = NavigationAgent3D.new()
    agent.path_desired_distance = 0.8
    agent.target_desired_distance = 1.2
    agent.radius = 0.4
    agent.height = 1.7
    add_child(agent)
    _groan_t = randf_range(1.0, 5.0)


func _physics_process(delta: float) -> void:
    if not alive:
        return
    if not is_on_floor():
        velocity.y -= GRAVITY * delta
    else:
        velocity.y = -0.5
    _attack_cd = maxf(0.0, _attack_cd - delta)
    _groan_t -= delta
    if _groan_t <= 0.0:
        _groan_t = randf_range(4.0, 9.0)
        Game.play_sfx("melt", global_position, -16.0)
    var dir := Vector3.ZERO
    var spd := speed
    match state:
        OUTSIDE:
            var to: Vector3 = barricade.outside_point - global_position
            to.y = 0.0
            if to.length() < 0.9:
                state = BREAKING
            else:
                dir = to.normalized()
        BREAKING:
            _face(barricade.inside_point - global_position)
            if barricade.planks <= 0:
                state = CLIMBING
            else:
                _tear_cd -= delta
                if _tear_cd <= 0.0:
                    _tear_cd = 1.4
                    model.gesture("Punch")
                    barricade.tear()
        CLIMBING:
            var to2: Vector3 = barricade.inside_point - global_position
            to2.y = 0.0
            if barricade.planks > 0:
                state = BREAKING     # boarded up again before we got through
            elif to2.length() < 0.8:
                state = HUNTING
            else:
                dir = to2.normalized()
                spd = minf(speed, 2.5)
        HUNTING:
            dir = _hunt(delta)
    velocity.x = move_toward(velocity.x, dir.x * spd, 20.0 * delta)
    velocity.z = move_toward(velocity.z, dir.z * spd, 20.0 * delta)
    move_and_slide()
    var hs := Vector2(velocity.x, velocity.z).length()
    if dir != Vector3.ZERO:
        _face(dir)
        _stuck_t = _stuck_t + delta if hs < spd * 0.15 else 0.0
        if _stuck_t > 2.5:
            _stuck_t = 0.0
            velocity += dir.cross(Vector3.UP) * [-3.0, 3.0].pick_random()   # shoulder past whatever's in the way
    model.animate(delta, hs, false)


func _hunt(_delta: float) -> Vector3:
    _repath_t -= _delta
    if _repath_t <= 0.0 or _target == null or not is_instance_valid(_target) or not _target.alive:
        _repath_t = 0.35
        _target = mode.nearest_prey(global_position)
        if _target != null:
            agent.target_position = _target.global_position
    if _target == null:
        return Vector3.ZERO
    var to_t: Vector3 = _target.global_position - global_position
    to_t.y = 0.0
    if to_t.length() < REACH:
        _face(to_t)
        if _attack_cd <= 0.0:
            _attack_cd = 1.1
            model.gesture("Punch")
            _target.take_damage(damage, global_position, _target.global_position + Vector3(0, 1.0, 0), false)
            Game.play_sfx("hit", global_position, -6.0)
        return Vector3.ZERO
    var next := agent.get_next_path_position()
    var d := next - global_position
    d.y = 0.0
    if d.length() < 0.05 or agent.is_navigation_finished():
        d = to_t                  # no path (yet): head straight for them
    return d.normalized()


func _face(d: Vector3) -> void:
    if Vector2(d.x, d.z).length() > 0.01:
        rotation.y = lerp_angle(rotation.y, atan2(-d.x, -d.z), 0.25)


func hear(_pos: Vector3) -> void:
    pass                          # they're already coming for you


func take_damage(amount: float, source: Vector3, hit_pos: Vector3, explosive := false) -> bool:
    if not alive:
        return false
    var headshot: bool = not explosive and (hit_pos.y - global_position.y) > 1.25
    if headshot:
        amount *= 2.0
    hp -= amount
    model.hit_flash()
    Fx.blood_plastic(level, hit_pos, MELT_TAN)
    var by_player: bool = mode.is_player_damage(source, explosive)
    if hp <= 0.0:
        _die(headshot, by_player)
        return true
    if by_player:
        mode.award(10, hit_pos, false)
    return false


func _die(headshot: bool, by_player: bool) -> void:
    alive = false
    remove_from_group("enemies")
    remove_from_group("damageable")
    collision_layer = 0
    collision_mask = 0
    set_physics_process(false)
    model.melt()
    Game.play_sfx("melt", global_position, -2.0)
    level.on_enemy_killed(self, headshot)
    if by_player:
        mode.award(100 if headshot else 60, global_position + Vector3(0, 1.4, 0), true)
    mode.on_melty_died(self)
    var t := Timer.new()
    t.wait_time = 8.0
    t.one_shot = true
    t.autostart = true
    t.timeout.connect(queue_free)
    add_child(t)
