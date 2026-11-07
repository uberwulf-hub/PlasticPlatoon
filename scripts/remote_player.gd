extends CharacterBody3D
## A teammate in a LAN game, as seen on this PC: a green plastic soldier with
## a name tag, moved by the state its owner sends ~20 times a second.
## On the host it is also a real target for the Tan Army; damage it takes is
## forwarded to the owning player's PC, which is the authority on its health.

const Soldier = preload("res://scripts/plastic_soldier.gd")
const Weapons = preload("res://scripts/weapons.gd")

var level: Node
var peer_id := 0
var model
var name_tag: Label3D
var alive := true
var crouching := false
var health := 100.0
var armor := 0.0
var vehicle: Node = null          # the vehicle node they're driving, if any
var weapon := "carbine"
var _target_pos := Vector3.ZERO
var _target_yaw := 0.0
var _hspeed := 0.0
var _pitch := 0.0
var _have_state := false
var _cs: CollisionShape3D


func setup(lvl: Node, id: int, pos: Vector3) -> void:
    level = lvl
    peer_id = id
    position = pos
    _target_pos = pos
    name = "Remote%d" % id


func _ready() -> void:
    add_to_group("player")
    add_to_group("damageable")
    collision_layer = 2           # same layer as the local player, so AI rays hit it
    collision_mask = 0
    var cap := CapsuleShape3D.new()
    cap.radius = 0.35
    cap.height = 1.8
    _cs = CollisionShape3D.new()
    _cs.shape = cap
    _cs.position.y = 0.9
    add_child(_cs)
    var slot: int = Net.players.get(peer_id, {}).get("slot", 1)
    model = Soldier.create()
    add_child(model)
    model.build(Net.SLOT_COLORS[slot % Net.SLOT_COLORS.size()], "rifle")
    name_tag = Label3D.new()
    name_tag.text = Net.player_name(peer_id)
    name_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    name_tag.no_depth_test = true
    name_tag.fixed_size = true
    name_tag.pixel_size = 0.0012
    name_tag.font_size = 22
    name_tag.outline_size = 8
    name_tag.modulate = Color(0.75, 1.0, 0.6)
    name_tag.position.y = 2.35
    add_child(name_tag)


## data: [x,y,z, yaw, pitch, hspeed, crouch, alive, weapon_idx, health, vehicle_idx, armor, shooting]
func apply_state(d: PackedFloat32Array) -> void:
    _target_pos = Vector3(d[0], d[1], d[2])
    _target_yaw = d[3]
    _pitch = d[4]
    _hspeed = d[5]
    crouching = d[6] > 0.5
    var now_alive := d[7] > 0.5
    var w: String = Weapons.ORDER[clampi(int(d[8]), 0, Weapons.ORDER.size() - 1)]
    health = d[9]
    var vi := int(d[10])
    armor = d[11]
    if d[12] > 0.5:
        model.notify_shot()
    if not _have_state:
        position = _target_pos
        rotation.y = _target_yaw
        _have_state = true
    if w != weapon:
        weapon = w
        model.set_weapon(Weapons.DATA[w]["model"])
    vehicle = level.vehicles[vi] if vi >= 0 and vi < level.vehicles.size() else null
    var hidden := vehicle != null
    model.visible = not hidden
    name_tag.visible = true
    if hidden:
        name_tag.position.y = 3.6
    else:
        name_tag.position.y = 2.35
    collision_layer = 0 if hidden or not now_alive else 2
    if now_alive and not alive:
        _respawned()
    elif alive and not now_alive:
        alive = false
        model.melt()
        Game.play_sfx("melt", global_position, -4.0)
    name_tag.text = Net.player_name(peer_id) + ("" if alive else "  (down)")


func _respawned() -> void:
    alive = true
    model.queue_free()
    var slot: int = Net.players.get(peer_id, {}).get("slot", 1)
    model = Soldier.create()
    add_child(model)
    model.build(Net.SLOT_COLORS[slot % Net.SLOT_COLORS.size()], Weapons.DATA[weapon]["model"])
    position = _target_pos


func _physics_process(delta: float) -> void:
    if not _have_state:
        return
    var k := minf(1.0, delta * 15.0)
    if position.distance_to(_target_pos) > 6.0:
        position = _target_pos       # teleported (respawn / vehicle exit)
    else:
        position = position.lerp(_target_pos, k)
    rotation.y = lerp_angle(rotation.y, _target_yaw, k)
    velocity = (_target_pos - position) * 10.0
    if alive and model.visible:
        model.aim_pitch = _pitch
        model.animate(delta, _hspeed, crouching)


## Server only: something hit this teammate. Their own PC applies it.
func take_damage(amount: float, source: Vector3, _hit_pos: Vector3, explosive := false) -> bool:
    if not alive or vehicle != null:
        return false
    if level.net:
        level.net.send_damage(peer_id, amount, source, explosive)
    return false
