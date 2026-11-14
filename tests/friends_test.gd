extends Node
## Two-process friends test through a local relay (tools/relay_local):
##   PLATOON_RELAY_URL=ws://127.0.0.1:24690 PLATOON_FRIENDS_TEST=1 godot --headless --path . res://tests/friends_test.tscn -- dad
##   (same) -- kid
## Dad and Kid have each other's friend codes; both show as playing; Dad hosts
## an online game and invites Kid; Kid's game gets the invite and joins.

var role := "dad"
var main: Node
var results := []
var invite := []


func _ready() -> void:
    role = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "dad"
    Game.show_news = false
    var me := "DADCODE1" if role == "dad" else "KIDCODE1"
    var other := "KIDCODE1" if role == "dad" else "DADCODE1"
    Game.friend_code = me
    Game.player_name = "Dad" if role == "dad" else "Kid"
    Game.friends = [{"code": other, "name": "Friend"}]
    main = load("res://scenes/main.tscn").instantiate()
    add_child(main)
    await _frames(5)
    Net.invite_received.connect(func(who, room): invite.append([who, room]))
    _check(await _wait(func():
        Net.check_friends_soon()
        return Net.is_friend_online(other), 30.0), "%s sees their friend playing" % role)
    _check(await _wait(func(): return Game.friends[0]["name"] != "Friend", 10.0), "%s learned the friend's name (%s)" % [role, Game.friends[0]["name"]])
    if role == "dad":
        Net.host_online("Dad")
        _check(await _wait(func(): return Net.room_code != "", 15.0), "dad opened an online game (%s)" % Net.room_code)
        Net.invite_friend(other)
        _check(await _wait(func(): return Net.players.size() == 2, 40.0), "kid joined from the invite")
    else:
        _check(await _wait(func():
            Net.check_friends_soon()
            return not invite.is_empty(), 40.0), "kid got dad's invite %s" % str(invite))
        if not invite.is_empty():
            Net.join_online(invite[0][1], "Kid")
            _check(await _wait(func(): return Net.players.size() == 2, 20.0), "kid is in dad's lobby")
    await _frames(60)
    print("\n==== FRIENDS TEST (%s): %d checks, %d failed ====" % [role, results.size(), results.filter(func(r): return not r[1]).size()])
    for r in results:
        print("%s %s %s" % ["PASS" if r[1] else "FAIL", role, r[0]])
    Net.leave()
    get_tree().quit(1 if results.any(func(r): return not r[1]) else 0)


func _check(ok: bool, label: String) -> void:
    results.append([label, ok])


func _frames(n: int) -> void:
    for i in n:
        await get_tree().physics_frame


func _wait(cond: Callable, s: float) -> bool:
    var t0 := Time.get_ticks_msec()
    while not cond.call():
        if Time.get_ticks_msec() - t0 > s * 1000.0:
            return false
        await _frames(15)
    return true
