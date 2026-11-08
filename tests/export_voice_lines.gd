extends Node
## Dev tool: writes every PNN line (speaker + text + clip key) to JSON so
## tools/make_voices.py can pre-record them.
##   godot --headless --path . res://tests/export_voice_lines.tscn -- out.json

func _ready() -> void:
    var NS = load("res://scripts/news_scripts.gd")
    var NB = load("res://scripts/news_break.gd")
    var LD = load("res://scripts/level_data.gd")
    # One stats set per after-action variant, so every branch is exported.
    var stat_sets := [
        {"time": 245.0, "kills": 31, "total": 34, "headshots": 9, "accuracy": 41.0},
        {"time": 610.0, "kills": 12, "total": 30, "headshots": 1, "accuracy": 18.0},
        {"time": 400.0, "kills": 25, "total": 30, "headshots": 2, "accuracy": 72.0},
        {"time": 200.0, "kills": 25, "total": 30, "headshots": 2, "accuracy": 45.0},
        {"time": 500.0, "kills": 25, "total": 30, "headshots": 2, "accuracy": 45.0},
    ]
    var seen := {}
    var out: Array = []
    for op in LD.META.size():
        var scripts: Array = [NS.intro(op)]
        for st in stat_sets:
            st["level"] = op
            scripts.append(NS.outro(op, true, st))
        scripts.append(NS.outro(op, false, stat_sets[0]))
        for d in scripts:
            for b in d["beats"]:
                var who: String = b.get("who", "both")
                var line: String = b.get("line", "")
                var key: String = NB.clip_key(who, line)
                if not seen.has(key):
                    seen[key] = true
                    out.append({"who": who, "line": line, "key": key})
    var f := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
    f.store_string(JSON.stringify(out, "  "))
    print("exported %d lines" % out.size())
    get_tree().quit()
