extends Area3D
## Floating supply crate. Checks overlap periodically so a player who was
## full when they walked over it can still grab it later.

const INFO := {
    "health": {"label": "+ MEDKIT", "color": Color(0.9, 0.2, 0.2)},
    "armor": {"label": "+ PLATE ARMOR", "color": Color(0.3, 0.5, 0.95)},
    "ammo": {"label": "AMMO", "color": Color(0.9, 0.75, 0.2)},
    "grenades": {"label": "FRAG x2", "color": Color(0.35, 0.55, 0.25)},
    "drone": {"label": "DRONE UPLINK", "color": Color(0.2, 0.85, 0.95)},
    "lmg": {"label": "M249 SAW", "color": Color(0.75, 0.75, 0.75)},
    "sniper": {"label": "MK 22 SNIPER", "color": Color(0.75, 0.75, 0.75)},
    "launcher": {"label": "AT4 LAUNCHER", "color": Color(1.0, 0.55, 0.2)},
    "shotgun": {"label": "M1014 SHOTGUN", "color": Color(0.75, 0.75, 0.75)},
    "intel": {"label": "TAN INTEL", "color": Color(1.0, 0.9, 0.3)},
    "pow": {"label": "RESCUE POW", "color": Color(0.45, 1.0, 0.45)},
}

var level: Node
var kind := "ammo"
var net_id := -1
var visual: Node3D
var t := 0.0
var check_t := 0.0


func setup(lvl: Node, k: String, pos: Vector3) -> void:
    level = lvl
    kind = k
    position = pos


func _ready() -> void:
    collision_layer = 8
    collision_mask = 2
    monitoring = true
    monitorable = false
    var cs := CollisionShape3D.new()
    var sh := SphereShape3D.new()
    sh.radius = 1.1
    cs.shape = sh
    cs.position.y = 0.7
    add_child(cs)
    var info: Dictionary = INFO.get(kind, INFO["ammo"])
    t = randf() * 10.0
    visual = Node3D.new()
    add_child(visual)
    if kind == "pow":
        # A captured green soldier, waving for help.
        var guy = load("res://scripts/plastic_soldier.gd").create()
        visual.add_child(guy)
        guy.build(Color(0.32, 0.55, 0.22), "none")
        _add_label(info, 2.3)
        return
    var crate := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = Vector3(0.8, 0.55, 0.55)
    crate.mesh = bm
    var m := StandardMaterial3D.new()
    m.albedo_color = Color(0.3, 0.36, 0.22)
    m.roughness = 0.7
    crate.material_override = m
    visual.add_child(crate)
    var stripe := MeshInstance3D.new()
    var sb := BoxMesh.new()
    sb.size = Vector3(0.82, 0.14, 0.57)
    stripe.mesh = sb
    var sm := StandardMaterial3D.new()
    sm.albedo_color = info["color"]
    sm.emission_enabled = true
    sm.emission = info["color"]
    sm.emission_energy_multiplier = 1.5
    stripe.material_override = sm
    visual.add_child(stripe)
    if kind == "intel":
        crate.scale = Vector3(0.9, 0.5, 0.6)
        m.albedo_color = Color(0.16, 0.12, 0.1)
    _add_label(info, 1.35)


func _add_label(info: Dictionary, height: float) -> void:
    var label := Label3D.new()
    label.text = info["label"]
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.font_size = 40
    label.pixel_size = 0.008
    label.outline_size = 10
    label.modulate = info["color"].lightened(0.3)
    label.position.y = height
    label.visibility_range_begin = 3.5
    label.visibility_range_end = 45.0
    add_child(label)


func _process(delta: float) -> void:
    t += delta
    if kind == "pow":
        visual.position.y = absf(sin(t * 4.0)) * 0.25     # hopping up and down
        return
    visual.rotation.y = t * 1.6
    visual.position.y = 0.6 + sin(t * 3.0) * 0.1


func _physics_process(delta: float) -> void:
    check_t -= delta
    if check_t > 0.0:
        return
    check_t = 0.25
    for b in get_overlapping_bodies():
        # Only our own soldier collects things on this PC (teammates collect on theirs).
        if b == level.player and b.alive and b.give_pickup(kind):
            match kind:
                "pow":
                    level.notify("POW RESCUED", 2.0)
                "intel":
                    level.notify("INTEL RECOVERED", 2.0)
                _:
                    level.notify("Picked up " + str(INFO.get(kind, INFO["ammo"])["label"]).trim_prefix("+ "), 1.6)
            if level.net:
                level.net.pickup_taken(net_id)
            level.pickups.erase(net_id)
            queue_free()
            return
