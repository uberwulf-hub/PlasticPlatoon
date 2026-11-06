extends RefCounted
## Modern weapon definitions for the player arsenal.

const ORDER := ["carbine", "lmg", "shotgun", "sniper", "launcher"]

const DATA := {
    "carbine": {
        "name": "M4A1 Carbine", "auto": true, "interval": 0.085, "damage": 22.0, "pellets": 1,
        "spread": 1.8, "aim_spread": 0.35, "bloom": 0.22, "mag": 30, "reserve": 180, "reload": 1.9,
        "range": 260.0, "falloff_start": 70.0, "kind": "hitscan", "noise": 45.0, "recoil": 1.0,
        "zoom": 50.0, "model": "rifle", "sound": "rifle", "reload_sound": "reload_rifle", "tracer": Color(1.0, 0.85, 0.45),
    },
    "lmg": {
        "name": "M249 SAW", "auto": true, "interval": 0.07, "damage": 19.0, "pellets": 1,
        "spread": 2.8, "aim_spread": 0.9, "bloom": 0.16, "mag": 100, "reserve": 300, "reload": 4.2,
        "range": 260.0, "falloff_start": 70.0, "kind": "hitscan", "noise": 55.0, "recoil": 1.2,
        "zoom": 55.0, "model": "lmg", "sound": "lmg", "reload_sound": "reload_rifle", "tracer": Color(1.0, 0.55, 0.3),
    },
    "shotgun": {
        "name": "M1014 Shotgun", "auto": false, "interval": 0.32, "damage": 11.0, "pellets": 9,
        "spread": 5.5, "aim_spread": 4.0, "bloom": 0.6, "mag": 7, "reserve": 42, "reload": 2.6,
        "range": 70.0, "falloff_start": 12.0, "kind": "hitscan", "noise": 50.0, "recoil": 4.0,
        "zoom": 60.0, "model": "shotgun", "sound": "shotgun", "reload_sound": "reload_shotgun", "tracer": Color(1.0, 0.8, 0.5),
    },
    "sniper": {
        "name": "Mk 22 Sniper Rifle", "auto": false, "interval": 1.1, "damage": 125.0, "pellets": 1,
        "spread": 3.0, "aim_spread": 0.02, "bloom": 1.0, "mag": 5, "reserve": 30, "reload": 3.0,
        "range": 520.0, "falloff_start": 400.0, "kind": "hitscan", "noise": 70.0, "recoil": 5.0,
        "zoom": 16.0, "model": "sniper", "sound": "sniper", "reload_sound": "reload_sniper", "tracer": Color(0.8, 0.95, 1.0),
        "scope": true,
    },
    "launcher": {
        "name": "AT4 Launcher", "auto": false, "interval": 1.2, "damage": 170.0, "pellets": 1,
        "spread": 1.2, "aim_spread": 0.3, "bloom": 1.0, "mag": 1, "reserve": 5, "reload": 2.4,
        "range": 400.0, "falloff_start": 400.0, "kind": "rocket", "noise": 75.0, "recoil": 6.0,
        "zoom": 48.0, "model": "launcher", "sound": "rocket", "reload_sound": "reload_sniper", "tracer": Color(1.0, 0.6, 0.2),
        "splash": 5.5,
    },
}
