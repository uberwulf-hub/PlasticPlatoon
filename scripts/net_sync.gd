extends Node
## In-game LAN sync for one Level (node path .../Level/NetSync on every PC).
##
## Authority model (co-op):
##  * The host simulates the Tan Army (soldiers + vehicles), targets, barrels,
##    objectives, empty vehicles and all damage. It sends snapshots ~20x/sec.
##  * Each player simulates their own soldier (and the vehicle they drive) and
##    sends its state ~20x/sec. Their shots/projectiles are resolved on the host.
##  * Events (explosions, pickups, objectives, mission end...) are reliable RPCs.

const Weapons = preload("res://scripts/weapons.gd")
const Fx = preload("res://scripts/fx.gd")
const Rocket = preload("res://scripts/rocket.gd")
const Grenade = preload("res://scripts/grenade.gd")
const DroneStrike = preload("res://scripts/drone_strike.gd")

const SEND_INTERVAL := 0.05
const ENEMY_STRIDE := 6       # x y z yaw hspeed flags
const VEH_STRIDE := 10        # x y z yaw turret barrel hp alive speed occupant
const ST_SIZE := 13

var level: Node
var started := false          # host: all players have loaded; AI is running
var _send_t := 0.0
var _ready_peers := {}
var _go_timeout := 8.0
var _all_down_t := 0.0


func _init(lvl: Node) -> void:
    level = lvl
    name = "NetSync"


func _ready() -> void:
    if multiplayer.is_server():
        _ready_peers[1] = true
    else:
        srv_ready.rpc_id(1)


func is_server() -> bool:
    return multiplayer.is_server()


# ------------------------------------------------------------ main loop ----

func _physics_process(delta: float) -> void:
    if is_server() and not started:
        _go_timeout -= delta
        if _ready_peers.size() >= Net.players.size() or _go_timeout <= 0.0:
            _go.rpc()
    _send_t -= delta
    if _send_t > 0.0:
        return
    _send_t = SEND_INTERVAL
    _send_my_state()
    if is_server() and started:
        _send_snapshot()
        _check_squad_down(SEND_INTERVAL)


@rpc("any_peer", "reliable")
func srv_ready() -> void:
    _ready_peers[multiplayer.get_remote_sender_id()] = true


@rpc("authority", "call_local", "reliable")
func _go() -> void:
    started = true
    level.net_go()


# --------------------------------------------------------- player state ----

func _send_my_state() -> void:
    var p = level.player
    if p == null or not is_instance_valid(p):
        return
    var vi := -1
    var v = p.vehicle
    if v != null:
        vi = level.vehicles.find(v)
    var shooting := 1.0 if p.get("_net_shot") else 0.0
    p.set("_net_shot", false)
    var d := PackedFloat32Array([
        p.global_position.x, p.global_position.y, p.global_position.z, p.rotation.y, p.pitch,
        Vector2(p.velocity.x, p.velocity.z).length(), 1.0 if p.crouching else 0.0, 1.0 if p.alive else 0.0,
        float(Weapons.ORDER.find(p.current)), p.health, float(vi), p.armor, shooting,
    ])
    var vd := PackedFloat32Array()
    if v != null:
        vd = PackedFloat32Array([v.global_position.x, v.global_position.y, v.global_position.z, v.rotation.y,
            v.turret.rotation.y if v.turret else 0.0, v.barrel.rotation.x if v.barrel else 0.0, v.speed])
    _st.rpc(d, vd)


@rpc("any_peer", "unreliable_ordered")
func _st(d: PackedFloat32Array, vd: PackedFloat32Array) -> void:
    if d.size() < ST_SIZE:
        return
    level.remote_state(multiplayer.get_remote_sender_id(), d, vd)


# --------------------------------------------------- host -> all snapshot ----

func _send_snapshot() -> void:
    var en := PackedFloat32Array()
    if level.mode != null:
        # MELTDOWN: Melties come and go, so they travel by id on their own channel.
        _md_pos.rpc(level.mode.pack_melties())
    for e in ([] if level.mode != null else level.enemies):
        var alive: bool = is_instance_valid(e) and e.alive
        var pos: Vector3 = e.global_position if is_instance_valid(e) else Vector3.ZERO
        var flags := (1.0 if alive else 0.0) + (2.0 if is_instance_valid(e) and e.get("_net_shot") else 0.0)
        if is_instance_valid(e):
            e.set("_net_shot", false)
        en.append_array([pos.x, pos.y, pos.z, e.rotation.y if is_instance_valid(e) else 0.0,
            Vector2(e.velocity.x, e.velocity.z).length() if is_instance_valid(e) else 0.0, flags])
    _snap.rpc(PackedFloat32Array([level.kills, level.headshots, level.elapsed]), en,
        _pack_vehicles(level.enemy_vehicles), _pack_vehicles(level.vehicles))


func _pack_vehicles(list: Array) -> PackedFloat32Array:
    var out := PackedFloat32Array()
    for v in list:
        var p: Vector3 = v.global_position
        out.append_array([p.x, p.y, p.z, v.rotation.y, v.turret.rotation.y if v.turret else 0.0,
            v.barrel.rotation.x if v.barrel else 0.0, v.hp, 1.0 if v.alive else 0.0, v.speed, float(v.occupant_peer)])
    return out


@rpc("authority", "unreliable_ordered")
func _snap(header: PackedFloat32Array, en: PackedFloat32Array, ev: PackedFloat32Array, pv: PackedFloat32Array) -> void:
    level.kills = int(header[0])
    level.headshots = int(header[1])
    level.elapsed = header[2]
    for i in mini(level.enemies.size(), en.size() / ENEMY_STRIDE):
        var o := i * ENEMY_STRIDE
        var e = level.enemies[i]
        if is_instance_valid(e):
            e.net_apply(Vector3(en[o], en[o + 1], en[o + 2]), en[o + 3], en[o + 4], int(en[o + 5]))
    _apply_vehicles(level.enemy_vehicles, ev)
    _apply_vehicles(level.vehicles, pv)


func _apply_vehicles(list: Array, data: PackedFloat32Array) -> void:
    for i in mini(list.size(), data.size() / VEH_STRIDE):
        var o := i * VEH_STRIDE
        list[i].net_apply(Vector3(data[o], data[o + 1], data[o + 2]), data[o + 3], data[o + 4], data[o + 5],
            data[o + 6], data[o + 7] > 0.5, data[o + 8], int(data[o + 9]))


# ------------------------------------------------------- shots & effects ----

## A player on this PC fired hitscan rounds. segs = [from0, end0, from1, end1...]
## where each end is where the round stopped *on the shooter's screen*, and
## refs[i] names what it hit there (level.ref_of) or [] for a miss.
## Co-op uses "what you see is what you hit": the shooter's PC decides hits,
## because a client sees moving enemies ~0.1 s behind the host.
func send_shot(segs: PackedVector3Array, dmgs: PackedFloat32Array, refs: Array, color: Color, sound: String, noise: float) -> void:
    srv_shot.rpc_id(1, segs, dmgs, refs, color, sound, noise)


@rpc("any_peer", "reliable")
func srv_shot(segs: PackedVector3Array, dmgs: PackedFloat32Array, refs: Array, color: Color, sound: String, noise: float) -> void:
    var from_peer := multiplayer.get_remote_sender_id()
    var any_hit := false
    var killed := false
    for i in range(0, segs.size() - 1, 2):
        var a := segs[i]
        var end := segs[i + 1]
        var ref: Array = refs[i / 2] if i / 2 < refs.size() else []
        var recv = level.node_of(ref)
        if recv != null and recv.get("alive") != false:
            if recv.take_damage(dmgs[i / 2], a, end, false):
                killed = true
            any_hit = true
        if i == 0 or randf() < 0.3:
            _fx_shot_except(from_peer, a, end, color, sound if i == 0 else "")
    if segs.size() >= 2:
        level.make_noise(segs[0], noise)
    if any_hit:
        _cl_hit.rpc_id(from_peer, killed)


@rpc("authority", "reliable")
func _cl_hit(killed: bool) -> void:
    var p = level.player
    p.shots_hit += 1
    p.hit_confirmed.emit(killed)
    Game.play_ui("hit", -10.0)


## Tracer + flash + sound for everyone (host side). except = a peer that
## already drew it locally (0 = nobody).
func fx_shot(from: Vector3, to: Vector3, color: Color, sound: String, db := -3.0) -> void:
    _fx_shot_except(0, from, to, color, sound, db)


func _fx_shot_except(except: int, from: Vector3, to: Vector3, color: Color, sound: String, db := -3.0) -> void:
    if except != 1:
        _fx_shot_local(from, to, color, sound, db)
    for id in multiplayer.get_peers():
        if id != except:
            _cl_fx_shot.rpc_id(id, from, to, color, sound, db)


@rpc("authority", "unreliable")
func _cl_fx_shot(from: Vector3, to: Vector3, color: Color, sound: String, db: float) -> void:
    _fx_shot_local(from, to, color, sound, db)


func _fx_shot_local(from: Vector3, to: Vector3, color: Color, sound: String, db: float) -> void:
    Fx.tracer(level, from, to, color)
    Fx.muzzle_flash(level, from)
    if sound != "":
        Game.play_sfx(sound, from, db)


## Host: explosion effect + sound on every PC.
func boom(pos: Vector3, radius: float, db: float) -> void:
    _cl_boom.rpc(pos, radius, db)


@rpc("authority", "call_local", "reliable")
func _cl_boom(pos: Vector3, radius: float, db: float) -> void:
    level.boom_local(pos, radius, db)


# ----------------------------------------------------------- projectiles ----

## kind: "rocket" (a = damage, b = radius, c = speed), "grenade" (dir = velocity),
## "drone" (pos = target). The firing PC already shows its own visual copy.
func send_projectile(kind: String, pos: Vector3, dir: Vector3, a := 0.0, b := 0.0, c := 0.0) -> void:
    if is_server():
        _spawn_projectile(kind, pos, dir, a, b, c, 1)
    else:
        srv_projectile.rpc_id(1, kind, pos, dir, a, b, c)


@rpc("any_peer", "reliable")
func srv_projectile(kind: String, pos: Vector3, dir: Vector3, a: float, b: float, c: float) -> void:
    _spawn_projectile(kind, pos, dir, a, b, c, multiplayer.get_remote_sender_id())


func _spawn_projectile(kind: String, pos: Vector3, dir: Vector3, a: float, b: float, c: float, origin: int) -> void:
    # The real (damaging) copy lives on the host...
    var shooter = level.player if origin == 1 else level.remotes.get(origin)
    if shooter != null and shooter.get("vehicle") != null:
        shooter = shooter.vehicle
    if origin != 1:
        level.spawn_projectile(kind, pos, dir, a, b, c, false, shooter)
    # ...and every other PC gets a harmless visual copy.
    for id in multiplayer.get_peers():
        if id != origin:
            _cl_projectile.rpc_id(id, kind, pos, dir, a, b, c)


@rpc("authority", "reliable")
func _cl_projectile(kind: String, pos: Vector3, dir: Vector3, a: float, b: float, c: float) -> void:
    level.spawn_projectile(kind, pos, dir, a, b, c, true, null)


# ---------------------------------------------------------------- damage ----

func send_damage(peer: int, amount: float, source: Vector3, explosive: bool) -> void:
    _cl_damage.rpc_id(peer, amount, source, explosive)


@rpc("authority", "reliable")
func _cl_damage(amount: float, source: Vector3, explosive: bool) -> void:
    var p = level.player
    if p and p.alive:
        p.take_damage(amount, source, p.global_position + Vector3(0, 1, 0), explosive)


# ------------------------------------------------------- world events ----

func target_destroyed(i: int) -> void:
    _cl_target.rpc(i)


@rpc("authority", "reliable")
func _cl_target(i: int) -> void:
    if i >= 0 and i < level.targets.size():
        level.targets[i].destroy_visual()


func barrel_gone(i: int) -> void:
    _cl_barrel.rpc(i)


@rpc("authority", "reliable")
func _cl_barrel(i: int) -> void:
    if i >= 0 and i < level.barrels.size() and is_instance_valid(level.barrels[i]):
        level.barrels[i].queue_free()


func pickup_spawned(id: int, kind: String, pos: Vector3) -> void:
    _cl_pickup_spawn.rpc(id, kind, pos)


@rpc("authority", "reliable")
func _cl_pickup_spawn(id: int, kind: String, pos: Vector3) -> void:
    level.add_pickup(pos, kind, id)


## This PC's player took pickup `id`.
func pickup_taken(id: int) -> void:
    if is_server():
        _cl_pickup_gone.rpc(id)
    else:
        srv_pickup.rpc_id(1, id)


@rpc("any_peer", "reliable")
func srv_pickup(id: int) -> void:
    level.remove_pickup(id)
    _cl_pickup_gone.rpc(id)


@rpc("authority", "reliable")
func _cl_pickup_gone(id: int) -> void:
    level.remove_pickup(id)


func objective(i: int) -> void:
    _cl_objective.rpc(i)


@rpc("authority", "reliable")
func _cl_objective(i: int) -> void:
    level.net_objective(i)


func notify_all(text: String, dur: float) -> void:
    _cl_notify.rpc(text, dur)


@rpc("authority", "call_local", "reliable")
func _cl_notify(text: String, dur: float) -> void:
    level.notify(text, dur)


func mission_end(success: bool, stats: Dictionary) -> void:
    _cl_mission_end.rpc(success, stats)


@rpc("authority", "call_local", "reliable")
func _cl_mission_end(success: bool, stats: Dictionary) -> void:
    level.net_mission_end(success, stats)


# --------------------------------------------------------------- vehicles ----

func request_enter(vi: int) -> void:
    if is_server():
        _grant_enter(1, vi)
    else:
        srv_enter.rpc_id(1, vi)


@rpc("any_peer", "reliable")
func srv_enter(vi: int) -> void:
    _grant_enter(multiplayer.get_remote_sender_id(), vi)


func _grant_enter(peer: int, vi: int) -> void:
    if vi < 0 or vi >= level.vehicles.size():
        return
    var v = level.vehicles[vi]
    if not v.alive or v.occupant_peer != 0:
        return
    _cl_occupant.rpc(vi, peer)


func release_vehicle(vi: int) -> void:
    if is_server():
        _cl_occupant.rpc(vi, 0)
    else:
        srv_exit.rpc_id(1, vi)


@rpc("any_peer", "reliable")
func srv_exit(vi: int) -> void:
    var v = level.vehicles[vi] if vi >= 0 and vi < level.vehicles.size() else null
    if v and v.occupant_peer == multiplayer.get_remote_sender_id():
        _cl_occupant.rpc(vi, 0)


@rpc("authority", "call_local", "reliable")
func _cl_occupant(vi: int, peer: int) -> void:
    level.net_set_occupant(vi, peer)


# ---------------------------------------------------------- squad wipe ----

## Host: the mission fails only if every player is down at the same time.
func _check_squad_down(delta: float) -> void:
    if level.ended:
        return
    var any_alive: bool = level.player != null and level.player.alive
    for r in level.remotes.values():
        if r.alive:
            any_alive = true
    _all_down_t = 0.0 if any_alive else _all_down_t + delta
    if _all_down_t > 1.0:
        level.net_squad_wiped()


# ------------------------------------------------------------- MELTDOWN ----
# The host runs the waves; these keep the other PCs' Melties, numbers,
# windows and doors in step, and carry their purchases and repairs.

func md_spawn(id: int, kind: String, pos: Vector3, max_hp: float, spd: float, bi: int, is_boss: bool) -> void:
    _md_spawn.rpc(id, kind, pos, max_hp, spd, bi, is_boss)


@rpc("authority", "reliable")
func _md_spawn(id: int, kind: String, pos: Vector3, max_hp: float, spd: float, bi: int, is_boss: bool) -> void:
    if level.mode:
        level.mode.puppet_spawn(id, kind, pos, max_hp, spd, bi, is_boss)


func md_dead(id: int) -> void:
    _md_dead.rpc(id)


@rpc("authority", "reliable")
func _md_dead(id: int) -> void:
    if level.mode:
        level.mode.puppet_dead(id)


@rpc("authority", "unreliable_ordered")
func _md_pos(d: PackedFloat32Array) -> void:
    if level.mode:
        level.mode.apply_melties(d)


func md_state(st: Dictionary) -> void:
    _md_state.rpc(st)


@rpc("authority", "unreliable_ordered")
func _md_state(st: Dictionary) -> void:
    if level.mode:
        level.mode.apply_state(st)


## A teammate buys something: "door" (index) or plain "coins" for a station item.
func md_buy(what: String, i: int, cost: int) -> void:
    srv_md_buy.rpc_id(1, what, i, cost)


@rpc("any_peer", "reliable")
func srv_md_buy(what: String, i: int, cost: int) -> void:
    if not is_server() or level.mode == null:
        return
    if not level.mode.host_spend(cost):
        return
    if what == "door":
        md_door(i)


## Open door i on every PC (the host already took the coins).
func md_door(i: int) -> void:
    _md_door.rpc(i)


@rpc("authority", "call_local", "reliable")
func _md_door(i: int) -> void:
    if level.mode:
        level.mode.open_door_index(i)


func md_rebuild(bi: int) -> void:
    srv_md_rebuild.rpc_id(1, bi)


@rpc("any_peer", "reliable")
func srv_md_rebuild(bi: int) -> void:
    if is_server() and level.mode and bi >= 0 and bi < level.mode.barricades.size():
        level.mode.teammate_planks += 1
        level.mode.rebuild_board(level.mode.barricades[bi])


## A Spitter spat: the other PCs show the glob flying (the host's does the damage).
func md_spit(id: int, from: Vector3, at: Vector3) -> void:
    _md_spit.rpc(id, from, at)


@rpc("authority", "unreliable")
func _md_spit(id: int, from: Vector3, at: Vector3) -> void:
    if level.mode:
        var m = level.mode.melties.get(id)
        if m != null and is_instance_valid(m):
            m.model.gesture("Punch")
        load("res://scripts/melty.gd").spawn_spit(level, level.mode, from, at, 0.0, true)


func md_coins(amount: int, pos: Vector3) -> void:
    _md_coins.rpc(amount, pos)


@rpc("authority", "unreliable")
func _md_coins(amount: int, pos: Vector3) -> void:
    if level.mode:
        level.mode.coin_popup(amount, pos)

