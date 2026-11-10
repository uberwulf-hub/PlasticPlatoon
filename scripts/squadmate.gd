extends CharacterBody3D
## A friendly Green AI soldier who follows the player in formation, shoots
## Tan soldiers it can see, and is a target for the Tan Army like the player.
## Orders (T): FOLLOW the player, or HOLD the spot where the order was given.
## When melted it comes back as a reinforcement near the player.
## When the player drives, squadmates climb into the vehicle's seats, shoot
## from there, and hop off when the player gets out.

const Soldier = preload("res://scripts/plastic_soldier.gd")
const Fx = preload("res://scripts/fx.gd")

const NAMES := ["Pvt. Sprue", "Cpl. Rivets", "Pvt. Pickles"]
const COLORS := [Color(0.3, 0.55, 0.22), Color(0.26, 0.5, 0.26), Color(0.34, 0.58, 0.2)]
## Formation slots relative to the leader (x = right, z = behind).
const SLOTS := [Vector3(-2.6, 0, 3.2), Vector3(2.6, 0, 3.2), Vector3(0, 0, 5.6)]
const GRAVITY := 16.0
const RUN := 6.2
const SPRINT := 9.5
const SIGHT := 48.0
const DAMAGE := 7.0
const MAX_HP := 120.0
const RESPAWN := 20.0
const BOARD_RANGE := 4.5          # close enough to climb aboard
const RUN_TO_RIDE := 40.0         # run over to a vehicle the player is driving within this range

var level: Node
var slot := 0
var model
var name_tag: Label3D
var alive := true
var health := MAX_HP
var crouching := false            # read by Tan aiming code
var vehicle = null                # never drives; read by Tan aiming code
var last_fire_ms := -100000
var hold := false
var hold_pos := Vector3.ZERO
var target = null                 # Tan soldier being shot at
var _scan_t := 0.0
var _fire_cd := 0.0
var _burst := 0
var _stuck_t := 0.0
var _side := 0.0
var _side_t := 0.0
var _hurt_t := 0.0
var _respawn_t := 0.0
var kills := 0
var ride = null                   # vehicle we're sitting in
var walk_mask := 1 | 4            # what we collide with on foot (MELTDOWN adds its window blockers)
var seat := -1


func setup(lvl: Node, i: int, pos: Vector3) -> void:
    level = lvl
    slot = i
    position = pos
    name = "Squad%d" % i


func _ready() -> void:
    add_to_group("squad")
    add_to_group("damageable")
    collision_layer = 2           # the "green side" layer: Tan rays and rockets hit it
    collision_mask = 1 | 4
    floor_snap_length = 0.4
    process_physics_priority = 10     # after vehicles move, so riders don't lag a frame
    var cap := CapsuleShape3D.new()
    cap.radius = 0.35
    cap.height = 1.8
    var cs := CollisionShape3D.new()
    cs.shape = cap
    cs.position.y = 0.9
    add_child(cs)
    _build_model()
    name_tag = Label3D.new()
    name_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    name_tag.no_depth_test = true
    name_tag.fixed_size = true
    name_tag.pixel_size = 0.0011
    name_tag.font_size = 20
    name_tag.outline_size = 8
    name_tag.modulate = Color(0.6, 1.0, 0.5)
    name_tag.position.y = 2.3
    add_child(name_tag)
    _update_tag()


func _build_model() -> void:
    model = Soldier.create()
    add_child(model)
    model.build(COLORS[slot % COLORS.size()], "rifle")


func display_name() -> String:
    return NAMES[slot % NAMES.size()]


func _update_tag() -> void:
    name_tag.text = display_name() + ("" if alive else "  (down)")


func set_hold(on: bool) -> void:
    hold = on
    hold_pos = global_position


## Where this squadmate wants to stand right now.
func _goal() -> Vector3:
    if hold:
        return hold_pos
    var p = level.player
    var car = p.vehicle
    if car != null and car.alive and car.free_seats() > 0 and global_position.distance_to(car.global_position) < RUN_TO_RIDE:
        return car.global_position          # run to the vehicle and climb in
    var leader: Node3D = p.vehicle if p.vehicle != null else p
    var s: Vector3 = SLOTS[slot % SLOTS.size()]
    if p.vehicle != null:
        s *= 2.2                    # give vehicles room
    return leader.global_position + s.rotated(Vector3.UP, leader.global_rotation.y)


func _physics_process(delta: float) -> void:
    if not alive:
        _respawn_t -= delta
        if _respawn_t <= 0.0 and level.player != null and level.player.alive:
            _reinforce()
        return
    var p = level.player
    if p == null or not is_instance_valid(p):
        return
    if global_position.y < -40.0 and ride == null:
        _rescue(p)                # fell out of the world somehow: back next to the player
        return
    if ride != null:
        _ride(delta, p)
        return
    # The player is driving: head for a seat (or board straight away if we're
    # far off and nobody's watching).
    var car = p.vehicle
    if car != null and not hold and car.alive and car.free_seats() > 0:
        var dcar: float = global_position.distance_to(car.global_position)
        if dcar < BOARD_RANGE + car.k["size"].z * 0.5 or (dcar > RUN_TO_RIDE and not _player_can_see(global_position)):
            _board(car)
            return
    if not is_on_floor():
        velocity.y -= GRAVITY * delta
    else:
        velocity.y = -0.5

    # Slowly patch up when out of the fight.
    _hurt_t -= delta
    if _hurt_t <= 0.0 and health < MAX_HP:
        health = minf(MAX_HP, health + 6.0 * delta)
        if health >= MAX_HP:
            model.clear_damage()
        else:
            model.set_wear(1.0 - health / MAX_HP)

    # Look for something to shoot a few times a second.
    _scan_t -= delta
    if _scan_t <= 0.0:
        _scan_t = randf_range(0.25, 0.4)
        target = _find_target()

    var goal := _goal()
    var to_goal := goal - global_position
    to_goal.y = 0.0
    var dist := to_goal.length()

    # Fell far behind (or got lost behind a wall): catch up out of sight.
    if not hold and p.alive and dist > 45.0 and not _player_can_see(global_position):
        var spot := goal + Vector3(0, 0.5, 0)
        if _clear(spot):
            global_position = spot
            velocity = Vector3.ZERO
            return

    var desired := Vector3.ZERO
    var speed := RUN
    if dist > 1.8:
        desired = to_goal / dist
        if dist > 12.0:
            speed = SPRINT
    elif target != null:
        # In position and in a fight: side-step a little so they aren't sitting ducks.
        _side_t -= delta
        if _side_t <= 0.0:
            _side_t = randf_range(1.0, 2.5)
            _side = [-1.0, 0.0, 1.0].pick_random()
        var flat: Vector3 = target.global_position - global_position
        flat.y = 0.0
        desired = flat.normalized().cross(Vector3.UP) * _side * 0.5
        speed = 2.5
    # Simple unstick: if we want to move but can't, slide sideways for a moment.
    if _stuck_t < 0.0:
        _stuck_t += delta
        desired = (desired + desired.cross(Vector3.UP) * _side * 1.5).normalized()
    velocity.x = move_toward(velocity.x, desired.x * speed, 24.0 * delta)
    velocity.z = move_toward(velocity.z, desired.z * speed, 24.0 * delta)
    move_and_slide()
    var hs := Vector2(velocity.x, velocity.z).length()
    if desired.length() > 0.5 and hs < speed * 0.2 and _stuck_t >= 0.0:
        _stuck_t += delta
        if _stuck_t > 0.5:
            _side = [-1.0, 1.0].pick_random()
            _stuck_t = -0.8
    elif _stuck_t > 0.0:
        _stuck_t = 0.0

    # Face the enemy when fighting, else where we're going (or where the player looks).
    var face := Vector3.ZERO
    if target != null:
        face = target.global_position - global_position
    elif hs > 0.5:
        face = velocity
    else:
        face = -p.global_transform.basis.z
    if Vector2(face.x, face.z).length() > 0.01:
        rotation.y = lerp_angle(rotation.y, atan2(-face.x, -face.z), minf(1.0, delta * 8.0))
    if target != null:
        _fight(delta)
    model.animate(delta, hs, false)


func _find_target():
    var best = null
    var best_d := SIGHT
    for e in level.enemies:
        if not is_instance_valid(e) or not e.alive:
            continue
        var d: float = e.global_position.distance_to(global_position)
        if d < best_d and _can_see(e.global_position + Vector3(0, 1.2, 0)):
            best_d = d
            best = e
    return best


func _can_see(point: Vector3) -> bool:
    var ex: Array[RID] = [get_rid()]
    var hit := Fx.ray(self, global_position + Vector3(0, 1.6, 0), point, 1, ex)
    return hit.is_empty()


func _player_can_see(point: Vector3) -> bool:
    var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
    if cam == null:
        return false
    if cam.is_position_behind(point + Vector3(0, 1, 0)):
        return false
    return Fx.ray(self, cam.global_position, point + Vector3(0, 1, 0), 1).is_empty()


func _clear(pos: Vector3) -> bool:
    var cap := CapsuleShape3D.new()
    cap.radius = 0.35
    cap.height = 1.6
    var q := PhysicsShapeQueryParameters3D.new()
    q.shape = cap
    q.transform = Transform3D(Basis(), pos + Vector3(0, 0.9, 0))
    q.collision_mask = 1
    return get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty()


func _fight(delta: float) -> void:
    if not is_instance_valid(target) or not target.alive:
        target = null
        return
    _fire_cd -= delta
    if _fire_cd > 0.0:
        return
    if _burst <= 0:
        _burst = randi_range(3, 5)
    _shoot(target)
    _burst -= 1
    _fire_cd = 0.12 if _burst > 0 else randf_range(0.9, 1.6)


func _shoot(e) -> void:
    var muzzle: Vector3 = model.get_muzzle_position()
    var aim: Vector3 = e.global_position + Vector3(0, 1.15, 0)
    var dir := (aim - muzzle).normalized()
    var bx := dir.cross(Vector3.UP).normalized()
    var by := bx.cross(dir).normalized()
    var r := tan(deg_to_rad(3.0)) * sqrt(randf())
    var a := randf() * TAU
    dir = (dir + bx * r * cos(a) + by * r * sin(a)).normalized()
    var to := muzzle + dir * SIGHT * 1.4
    var ex: Array[RID] = [get_rid()]
    var hit := Fx.ray(self, muzzle, to, 1 | 4, ex)
    var end := to
    if not hit.is_empty():
        end = hit["position"]
        var col = hit["collider"]
        if col != null and col.is_in_group("enemies") and col.has_method("take_damage"):
            if col.take_damage(DAMAGE, global_position, end, false):
                kills += 1
        else:
            Fx.impact(level, end, hit["normal"])
    model.notify_shot()
    last_fire_ms = Time.get_ticks_msec()
    Fx.tracer(level, muzzle, end, Color(0.7, 1.0, 0.5))
    Fx.muzzle_flash(level, muzzle)
    Game.play_sfx("rifle", muzzle, -7.0)
    level.make_noise(global_position, 30.0)


# ---------------------------------------------------------------- riding ----

func _board(car) -> void:
    var i: int = car.board(self)
    if i < 0:
        return
    ride = car
    seat = i
    target = null
    velocity = Vector3.ZERO
    collision_layer = 0           # the vehicle's armour takes the hits now
    collision_mask = 0
    global_transform = car.seat_transform(i)


func _ride(delta: float, p) -> void:
    var car = ride
    if not is_instance_valid(car) or not car.alive or car.driver != p or hold:
        dismount(false)
        return
    var t: Transform3D = car.seat_transform(seat)
    global_position = t.origin
    _scan_t -= delta
    if _scan_t <= 0.0:
        _scan_t = randf_range(0.25, 0.4)
        target = _find_target()
    var face: Vector3 = -t.basis.z
    if target != null:
        face = target.global_position - global_position
    rotation.y = lerp_angle(rotation.y, atan2(-face.x, -face.z), minf(1.0, delta * 8.0))
    if target != null:
        _fight(delta)
    model.animate(delta, 0.0, target == null)    # duck while riding, stand up to shoot


## Climb (or get thrown) off the vehicle.
func dismount(thrown: bool) -> void:
    var car = ride
    if car == null:
        return
    # Somewhere clear beside the vehicle: our side, the other side, behind, in
    # front, and as a last resort on the roof. Never inside it (the physics
    # would push us out through the floor).
    var spots: Array = []
    if is_instance_valid(car):
        spots.append(car.dismount_point(seat))
        var half: Vector3 = car.k["size"] * 0.5
        for local in [Vector3(half.x + 1.2, 0.3, 0), Vector3(-half.x - 1.2, 0.3, 0), Vector3(0, 0.3, half.z + 1.3),
                Vector3(0, 0.3, -half.z - 1.3)]:
            spots.append(car.global_transform * local)
        spots.append(car.global_position + Vector3(0, car.k["size"].y + 0.6, 0))
        car.unboard(self)
    else:
        spots.append(global_position + Vector3(0, 0.5, 0))
    ride = null
    seat = -1
    collision_layer = 2
    collision_mask = walk_mask
    var spot: Vector3 = spots[spots.size() - 1]
    for c in spots:
        if _clear(c):
            spot = c
            break
    global_position = spot
    velocity = Vector3.ZERO
    if thrown and alive:
        take_damage(35.0, spot, global_position, true)


func take_damage(amount: float, _source: Vector3, hit_pos: Vector3, explosive := false) -> bool:
    if not alive or ride != null or level.is_protected(self):
        return false
    if explosive:
        amount *= 0.35            # also keeps your own grenades from flattening them
    health -= amount
    _hurt_t = 6.0
    model.hit_flash()
    model.damage_mark(hit_pos if hit_pos.distance_to(global_position) < 3.0 else global_position + Vector3(0, 1.1, 0), explosive)
    model.set_wear(1.0 - health / MAX_HP)
    Fx.blood_plastic(level, hit_pos, COLORS[slot % COLORS.size()])
    if health <= 0.0:
        _go_down()
        return true
    return false


func _go_down() -> void:
    if ride != null:
        dismount(false)
    alive = false
    target = null
    collision_layer = 0
    remove_from_group("damageable")
    model.melt()
    Game.play_sfx("melt", global_position, -4.0)
    level.notify("%s IS DOWN - reinforcement in %ds" % [display_name().to_upper(), int(RESPAWN)], 2.5)
    _respawn_t = RESPAWN
    _update_tag()


func _rescue(p) -> void:
    var spot: Vector3 = p.global_position + (SLOTS[slot % SLOTS.size()]).rotated(Vector3.UP, p.global_rotation.y) + Vector3(0, 0.5, 0)
    global_position = spot if _clear(spot) else p.global_position + Vector3(0, 1.0, 0)
    velocity = Vector3.ZERO


## Back in the fight: a fresh soldier arrives next to the player.
func _reinforce() -> void:
    var p = level.player
    var spot: Vector3 = p.global_position + (SLOTS[slot % SLOTS.size()] * 1.5).rotated(Vector3.UP, p.global_rotation.y) + Vector3(0, 0.5, 0)
    if not _clear(spot):
        spot = p.global_position + Vector3(0, 0.5, 0)
    model.queue_free()
    _build_model()
    global_position = spot
    velocity = Vector3.ZERO
    health = MAX_HP
    alive = true
    hold = false
    collision_layer = 2
    add_to_group("damageable")
    _update_tag()
    level.notify("%s REJOINED THE SQUAD" % display_name().to_upper(), 2.0)
    Game.play_ui("radio", -8.0)
