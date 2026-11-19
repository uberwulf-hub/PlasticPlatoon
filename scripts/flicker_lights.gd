extends Node
## Lights that flicker now and then, like an old bathroom fitting. While a
## MELTDOWN boss is on its way in, they sometimes cut out for a moment.

var level: Node
var lights: Array = []            # [OmniLight3D, base energy]
var bulbs: Array = []             # glowing materials that dim with them
var blackouts := 0                # tests read it
var _next := 0.0
var _flick := 0.0                 # seconds of flicker left
var _dark := 0.0                  # seconds of blackout left


func setup(lvl: Node, ls: Array, glow: Array = []) -> void:
    level = lvl
    for l in ls:
        lights.append([l, l.light_energy])
    bulbs = glow
    name = "FlickerLights"
    _next = randf_range(4.0, 9.0)


func _process(delta: float) -> void:
    if get_tree().paused:
        return
    _next -= delta
    if _next <= 0.0:
        var boss_wave: bool = level != null and level.get("mode") != null and level.mode.get("boss") != null and is_instance_valid(level.mode.boss)
        if boss_wave and randf() < 0.5:
            blackout(1.6)
        else:
            _flick = randf_range(0.5, 1.1)
        _next = randf_range(7.0, 16.0) if not boss_wave else randf_range(5.0, 9.0)
    var f := 1.0
    if _dark > 0.0:
        _dark -= delta
        f = 0.05 if _dark > 0.15 else 0.6
    elif _flick > 0.0:
        _flick -= delta
        f = 0.15 if fmod(_flick * 13.0, 1.0) < 0.45 else 1.0
    for e in lights:
        if is_instance_valid(e[0]):
            e[0].light_energy = e[1] * f
    for m in bulbs:
        m.emission_energy_multiplier = 3.0 * f


func blackout(t: float) -> void:
    blackouts += 1
    _dark = t
