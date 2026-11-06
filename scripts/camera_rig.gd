extends RefCounted
## Third-person camera collision that doesn't flicker against walls.
##
## Why: a plain SpringArm3D starts its ray at the shoulder offset. When the player
## hugs a wall, that start point ends up *inside* the wall, the ray misses, and the
## camera pops between "close" and "far" every few frames. This rig:
##   1. sweeps a sphere from the character's centre out to the shoulder point,
##   2. then sweeps backwards from there to the desired distance,
##   3. snaps IN instantly (never shows the inside of a wall), but only eases OUT
##      after the path has been clear for a short moment (hysteresis), so a hit
##      that flickers on and off can't make the view jump back and forth.

const RADIUS := 0.28
const EASE_OUT_SPEED := 4.0      # metres per second when moving back out
const CLEAR_DELAY := 0.25        # path must stay clear this long before easing out
const MIN_DIST := 0.15
const PULL_IN_RATE := 12.0       # smooth pull-in speed when merely grazing a wall
const SKIN := 0.2                # gap kept from walls at the shoulder

var distance := 3.4
var _clear_t := 0.0
var _shape := SphereShape3D.new()


func _init() -> void:
    _shape.radius = RADIUS


## pivot: node whose basis gives the look direction (camera sits along +Z).
## shoulder: local offset from the pivot (e.g. Vector3(0.6, 0.15, 0)).
## exclude: RIDs to ignore (the player / vehicle bodies).
func update(delta: float, pivot: Node3D, camera: Camera3D, desired: float, shoulder: Vector3, exclude: Array[RID], mask := 1) -> void:
    var space := pivot.get_world_3d().direct_space_state
    var b := pivot.global_transform.basis
    var origin := pivot.global_position
    var shoulder_pt := origin + b * shoulder
    # Stop a few centimetres short of anything at the shoulder, so the backward
    # sweep doesn't start already touching a wall (which reads as "blocked").
    var reach := origin.distance_to(shoulder_pt)
    var f := _sweep(space, origin, shoulder_pt, exclude, mask)
    if f < 1.0 and reach > 0.001:
        f = maxf(0.0, f - SKIN / reach)
    var start := origin.lerp(shoulder_pt, f)
    var back := b.z.normalized()
    var target := maxf(MIN_DIST, desired * _sweep(space, start, start + back * desired, exclude, mask))

    if target < distance - 0.01:
        # Something is in the way. If the camera is actually inside geometry, snap
        # in at once; if the view only grazes a wall, pull in fast but smoothly.
        if _overlaps(space, start + back * distance, exclude, mask):
            distance = target
        else:
            distance = maxf(target, lerpf(distance, target, 1.0 - exp(-PULL_IN_RATE * delta)))
        _clear_t = 0.0
    else:
        _clear_t += delta
        if _clear_t >= CLEAR_DELAY:
            distance = move_toward(distance, target, EASE_OUT_SPEED * delta)
    camera.global_position = start + back * distance


func _overlaps(space: PhysicsDirectSpaceState3D, pos: Vector3, exclude: Array[RID], mask: int) -> bool:
    var q := PhysicsShapeQueryParameters3D.new()
    var small := SphereShape3D.new()
    small.radius = 0.12
    q.shape = small
    q.transform = Transform3D(Basis(), pos)
    q.collision_mask = mask
    q.exclude = exclude
    return not space.intersect_shape(q, 1).is_empty()


func _sweep(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3, exclude: Array[RID], mask: int) -> float:
    var motion := to - from
    if motion.length_squared() < 0.0001:
        return 1.0
    var q := PhysicsShapeQueryParameters3D.new()
    q.shape = _shape
    q.transform = Transform3D(Basis(), from)
    q.motion = motion
    q.collision_mask = mask
    q.exclude = exclude
    var r := space.cast_motion(q)
    return r[0] if r.size() > 0 else 1.0
