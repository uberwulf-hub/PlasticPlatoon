extends Node
## Multiplayer (autoload "Net"): the 4-player co-op lobby, played either on
## the same network (LAN: ENet + discovery over UDP broadcast) or over the
## internet (online: RelayPeer through a relay server, joined by room code).
## In-game sync lives in net_sync.gd and works the same either way. When
## `active` is false the game is plain single-player.

signal players_changed
signal hosts_changed
signal host_left
signal start_requested(op: int)
signal join_failed(reason: String)

const PORT := 7777
const DISCOVERY_PORT := 7778
const MAX_PLAYERS := 4
const GAME_ID := "plasticplatoon-1"
# The internet relay: Race Track Mayhem's (it's game-agnostic - rooms and codes
# only). PLATOON_RELAY_URL overrides it (tests run a local copy).
const DEFAULT_RELAY := "wss://race-track-mayhem-relay.andrewsaulls.workers.dev"
const RELAY_PROTOCOL := 1
const RelayPeer = preload("res://scripts/relay_peer.gd")
const SLOT_COLORS := [Color(0.27, 0.48, 0.17), Color(0.2, 0.55, 0.32), Color(0.4, 0.52, 0.14), Color(0.18, 0.42, 0.24)]

var active := false
var players := {}          # peer_id -> {"name": String, "slot": int}
var hosts := {}            # ip -> {"name", "players", "seen"}  (LAN discovery results)
var op := 0
var in_game := false
var online := false        # playing over the internet (relay) rather than LAN
var room_code := ""        # online: the code friends type to join
var _join_watch := 0.0
var _broadcast: PacketPeerUDP
var _listen: PacketPeerUDP
var _bcast_t := 0.0


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)
    multiplayer.connected_to_server.connect(_on_connected)
    multiplayer.connection_failed.connect(func(): _fail("Couldn't connect to that host."))
    multiplayer.server_disconnected.connect(_on_server_gone)


func is_server() -> bool:
    return not active or multiplayer.is_server()


func my_id() -> int:
    return multiplayer.get_unique_id() if active else 1


func my_slot() -> int:
    return players.get(my_id(), {}).get("slot", 0)


func player_name(id: int) -> String:
    return players.get(id, {}).get("name", "Soldier")


# ------------------------------------------------------------ host / join ----

func host(name: String) -> String:
    leave()
    var peer := ENetMultiplayerPeer.new()
    var err := peer.create_server(PORT, MAX_PLAYERS - 1)
    if err != OK:
        return "Couldn't start hosting on port %d (is another game already hosting?)" % PORT
    multiplayer.multiplayer_peer = peer
    active = true
    players = {1: {"name": _clean(name), "slot": 0}}
    _start_broadcast()
    players_changed.emit()
    return ""


func join(ip: String, name: String) -> void:
    leave()
    var peer := ENetMultiplayerPeer.new()
    var err := peer.create_client(ip.strip_edges(), PORT)
    if err != OK:
        _fail("Couldn't reach %s." % ip)
        return
    multiplayer.multiplayer_peer = peer
    active = true
    set_meta("join_name", _clean(name))


func relay_url() -> String:
    var custom := OS.get_environment("PLATOON_RELAY_URL")
    return custom if custom != "" else DEFAULT_RELAY


## Online: opens a room on the relay. The room code arrives a moment later.
func host_online(name: String) -> void:
    leave()
    var relay := RelayPeer.new()
    relay.room_ready.connect(func(c: String):
        room_code = c
        players_changed.emit())
    relay.relay_error.connect(func(m: String): _fail(m))
    if relay.create_room(relay_url(), RELAY_PROTOCOL) != OK:
        _fail("Couldn't reach the online game server.")
        return
    multiplayer.multiplayer_peer = relay
    active = true
    online = true
    room_code = ""
    players = {1: {"name": _clean(name), "slot": 0}}
    players_changed.emit()


## Online: joins a friend's room by its 4-letter code.
func join_online(code: String, name: String) -> void:
    leave()
    code = code.strip_edges().to_upper()
    if code.length() < 4:
        _fail("Type the 4-letter game code first.")
        return
    var relay := RelayPeer.new()
    relay.relay_error.connect(func(m: String): _fail(m.replace("race", "game")))
    if relay.join_room(relay_url(), code, RELAY_PROTOCOL) != OK:
        _fail("Couldn't reach the online game server.")
        return
    multiplayer.multiplayer_peer = relay
    active = true
    online = true
    room_code = code
    set_meta("join_name", _clean(name))
    _join_watch = 15.0          # no squad list by then: not one of our games


func leave() -> void:
    if multiplayer.multiplayer_peer and not (multiplayer.multiplayer_peer is OfflineMultiplayerPeer):
        multiplayer.multiplayer_peer.close()
    multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
    active = false
    in_game = false
    online = false
    room_code = ""
    _join_watch = 0.0
    players = {}
    _stop_broadcast()


func _clean(name: String) -> String:
    var n := name.strip_edges().substr(0, 16)
    return n if n != "" else "Soldier"


func _fail(reason: String) -> void:
    leave()
    join_failed.emit(reason)


func _on_connected() -> void:
    _register.rpc_id(1, get_meta("join_name", "Soldier"))


func _on_peer_connected(_id: int) -> void:
    pass   # the joining client introduces itself with _register


func _on_peer_disconnected(id: int) -> void:
    if not players.has(id):
        return
    var who := player_name(id)
    players.erase(id)
    if multiplayer.is_server():
        _sync_players.rpc(players)
    players_changed.emit()
    if Game.current_level and Game.current_level.has_method("net_peer_left"):
        Game.current_level.net_peer_left(id, who)


func _on_server_gone() -> void:
    leave()
    host_left.emit()


@rpc("any_peer", "reliable")
func _register(name: String) -> void:
    if not multiplayer.is_server():
        return
    var id := multiplayer.get_remote_sender_id()
    if players.size() >= MAX_PLAYERS or in_game:
        _rejected.rpc_id(id, "That game is full." if players.size() >= MAX_PLAYERS else "That game has already started.")
        return
    var used := []
    for p in players.values():
        used.append(p["slot"])
    var slot := 0
    while used.has(slot):
        slot += 1
    players[id] = {"name": _clean(name), "slot": slot}
    _sync_players.rpc(players)
    players_changed.emit()


@rpc("authority", "reliable")
func _rejected(reason: String) -> void:
    _fail(reason)


@rpc("authority", "reliable")
func _sync_players(p: Dictionary) -> void:
    players = p
    _join_watch = 0.0
    players_changed.emit()


## Host: start (or restart) an operation for everyone.
func start_game(operation: int) -> void:
    if not multiplayer.is_server():
        return
    _start_game.rpc(operation)


@rpc("authority", "call_local", "reliable")
func _start_game(operation: int) -> void:
    op = operation
    in_game = true
    start_requested.emit(operation)


## Host: everyone back to the lobby.
func back_to_lobby() -> void:
    if multiplayer.is_server():
        _to_lobby.rpc()


signal lobby_requested


@rpc("authority", "call_local", "reliable")
func _to_lobby() -> void:
    in_game = false
    lobby_requested.emit()


# --------------------------------------------------------- LAN discovery ----

func _start_broadcast() -> void:
    _broadcast = PacketPeerUDP.new()
    _broadcast.set_broadcast_enabled(true)
    _broadcast.set_dest_address("255.255.255.255", DISCOVERY_PORT)


func _stop_broadcast() -> void:
    if _broadcast:
        _broadcast.close()
    _broadcast = null


func start_discovery() -> void:
    stop_discovery()
    hosts = {}
    _listen = PacketPeerUDP.new()
    if _listen.bind(DISCOVERY_PORT) != OK:
        _listen = null


func stop_discovery() -> void:
    if _listen:
        _listen.close()
    _listen = null


func _process(delta: float) -> void:
    if _join_watch > 0.0:
        _join_watch -= delta
        if _join_watch <= 0.0 and players.is_empty():
            _fail("No Plastic Platoon game with that code. Check the letters!")
    if _broadcast and active and multiplayer.is_server():
        _bcast_t -= delta
        if _bcast_t <= 0.0:
            _bcast_t = 1.0
            var msg := JSON.stringify({"game": GAME_ID, "name": player_name(1), "players": players.size(), "max": MAX_PLAYERS, "started": in_game})
            _broadcast.put_packet(msg.to_utf8_buffer())
    if _listen:
        var changed := false
        while _listen.get_available_packet_count() > 0:
            var data := _listen.get_packet().get_string_from_utf8()
            var ip := _listen.get_packet_ip()
            var d = JSON.parse_string(data)
            if d is Dictionary and d.get("game", "") == GAME_ID:
                hosts[ip] = {"name": str(d.get("name", "?")), "players": int(d.get("players", 1)), "started": bool(d.get("started", false)), "seen": Time.get_ticks_msec()}
                changed = true
        for ip in hosts.keys():
            if Time.get_ticks_msec() - hosts[ip]["seen"] > 4000:
                hosts.erase(ip)
                changed = true
        if changed:
            hosts_changed.emit()
