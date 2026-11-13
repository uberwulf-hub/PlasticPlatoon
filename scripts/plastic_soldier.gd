extends Node3D
## Animated soldier from the Quaternius "Toon Shooter Game Kit" (CC0), recolored
## into a single-color plastic toy (green or tan). Exposes the same interface as
## toy_soldier.gd, which stays as the fallback if the model can't be loaded.

const MODEL_PATH := "res://assets/models/soldier.gltf"
const MODEL_SCALE := 0.84

## Our weapon ids -> gun meshes already parented to the model's right hand.
const GUN_FOR := {
    "rifle": "AK", "lmg": "ShortCannon", "shotgun": "Shotgun",
    "sniper": "Sniper", "launcher": "RocketLauncher", "smg": "SMG",
}
const HIDDEN_PROPS := ["Knife_1", "Knife_2", "Pistol", "Revolver", "Revolver_Small", "Shovel", "GrenadeLauncher", "Sniper_2"]
const LOOPING := ["Idle", "Idle_Shoot", "Run", "Run_Gun", "Run_Shoot", "Walk", "Walk_Shoot", "Duck", "Jump_Idle"]

static var _scene: PackedScene

var body_color := Color(0.27, 0.48, 0.17)
var weapon_kind := "rifle"
var aim_pitch := 0.0
var torso: Node3D            # attachment point for hats etc. (head bone)
var hat_offset := Vector3(0, 0.62, 0)
var rig: Node3D
var skeleton: Skeleton3D
var anim: AnimationPlayer
var mats: Array[StandardMaterial3D] = []
var base_colors: Array[Color] = []
var guns := {}
var _current_gun: MeshInstance3D
var _shoot_t := 0.0
var _flash_t := 0.0
var _dead := false
var _anim_name := ""


## Returns the CC0 plastic soldier if the model is present, else the
## procedural fallback. Both share the same interface.
static func create() -> Node3D:
    if available():
        return new()
    return preload("res://scripts/toy_soldier.gd").new()


static func available() -> bool:
    if _scene == null and ResourceLoader.exists(MODEL_PATH):
        _scene = load(MODEL_PATH)
    return _scene != null


func build(c: Color, kind := "rifle") -> void:
    body_color = c
    available()
    rig = _scene.instantiate()
    rig.scale = Vector3.ONE * MODEL_SCALE
    rig.rotation.y = PI          # model faces +Z, the game uses -Z as forward
    add_child(rig)
    skeleton = rig.find_children("*", "Skeleton3D", true, false)[0]
    anim = rig.find_children("*", "AnimationPlayer", true, false)[0]
    for a in LOOPING:
        if anim.has_animation(a):
            anim.get_animation(a).loop_mode = Animation.LOOP_LINEAR
    _recolor()
    # Each gun is a MeshInstance3D inside a same-named BoneAttachment3D, so look
    # the meshes up by type; find_child(name) would return the attachment.
    var gun_names: Array = GUN_FOR.values()
    for mi in rig.find_children("*", "MeshInstance3D", true, false):
        if gun_names.has(String(mi.name)):
            guns[String(mi.name)] = mi
    # Hide hand-held props we don't use (knives, shovel, pistols...).
    for pname in HIDDEN_PROPS:
        var p := rig.find_child(pname, true, false)
        if p is Node3D:
            p.visible = false
    torso = BoneAttachment3D.new()
    skeleton.add_child(torso)
    torso.bone_name = "Head"
    hat_offset = Vector3(0, 0.62, 0)
    set_weapon(kind)
    _play("Idle")


func _recolor() -> void:
    var cache := {}
    for m in rig.find_children("*", "MeshInstance3D", true, false):
        var mi := m as MeshInstance3D
        for i in mi.mesh.get_surface_count():
            var src := mi.get_active_material(i)
            var key := src.get_instance_id() if src else 0
            if not cache.has(key):
                # Keep a hint of the original shading so details stay readable.
                var lum := 0.6
                if src is BaseMaterial3D:
                    lum = (src as BaseMaterial3D).albedo_color.get_luminance()
                var shade := body_color.darkened(clampf(0.45 - lum * 0.5, 0.0, 0.4))
                var pm := StandardMaterial3D.new()
                pm.albedo_color = shade
                pm.roughness = 0.38
                pm.metallic_specular = 0.65
                pm.rim_enabled = true
                pm.rim = 0.2
                cache[key] = pm
                mats.append(pm)
                base_colors.append(shade)
            mi.set_surface_override_material(i, cache[key])


func set_weapon(kind: String) -> void:
    weapon_kind = kind
    var want: String = "" if kind == "none" else GUN_FOR.get(kind, "AK")
    for gname in guns:
        guns[gname].visible = gname == want
    _current_gun = guns.get(want)


func get_muzzle_position() -> Vector3:
    if _current_gun == null or not _current_gun.is_inside_tree():
        return global_position + Vector3(0, 1.3, 0)
    # The muzzle is whichever end of the gun's long axis points most forward.
    var ab := _current_gun.get_aabb()
    var axis := 0
    for k in 3:
        if ab.size[k] > ab.size[axis]:
            axis = k
    var c := ab.get_center()
    var a := c
    var b := c
    a[axis] = ab.position[axis]
    b[axis] = ab.end[axis]
    var xf := _current_gun.global_transform
    var fwd := -global_transform.basis.z
    var pa := xf * a
    var pb := xf * b
    return pa if (pa - global_position).dot(fwd) > (pb - global_position).dot(fwd) else pb


func notify_shot() -> void:
    _shoot_t = 0.6


func animate(delta: float, speed: float, crouch: bool) -> void:
    if _dead:
        return
    _shoot_t = maxf(0.0, _shoot_t - delta)
    var shooting := _shoot_t > 0.0
    var a := "Idle_Shoot" if shooting else "Idle"
    if crouch:
        a = "Duck"
    elif speed > 6.5:
        a = "Run_Shoot" if shooting else "Run_Gun"
    elif speed > 0.4:
        a = "Walk_Shoot" if shooting else "Walk"
    _play(a)
    if a.begins_with("Walk") or a.begins_with("Run"):
        anim.speed_scale = clampf(speed / (6.0 if a.begins_with("Run") else 3.0), 0.6, 1.6)
    else:
        anim.speed_scale = 1.0
    if _flash_t > 0.0:
        _flash_t -= delta
        if _flash_t <= 0.0:
            for m in mats:
                m.emission_enabled = false


## One-off gesture (Wave / Yes / No / ...) that returns to Idle when done.
## Used by the PNN news cutscenes.
func gesture(a: String) -> void:
    if _dead or not anim.has_animation(a):
        return
    _anim_name = a
    anim.play(a, 0.2)
    if not anim.animation_finished.is_connected(_on_gesture_done):
        anim.animation_finished.connect(_on_gesture_done)


func _on_gesture_done(_name: StringName) -> void:
    if not _dead and not LOOPING.has(String(_name)):
        _anim_name = ""
        _play("Idle")


func _play(a: String) -> void:
    if a != _anim_name and anim.has_animation(a):
        _anim_name = a
        anim.play(a, 0.15)


func hit_flash() -> void:
    _flash_t = 0.07
    for m in mats:
        m.emission_enabled = true
        m.emission = Color(1, 1, 1)
        m.emission_energy_multiplier = 0.5
    if not _dead and anim.has_animation("HitReact") and _anim_name.begins_with("Idle"):
        _anim_name = "HitReact"
        anim.play("HitReact", 0.05)


func melt() -> void:
    _dead = true
    anim.speed_scale = 1.0
    if anim.has_animation("Death"):
        anim.play("Death", 0.1)
    for m in mats:
        m.emission_enabled = false
    var tw := create_tween()
    tw.tween_interval(0.9)
    tw.set_parallel(true)
    tw.tween_property(self, "scale", Vector3(1.8, 0.06, 1.8), 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
    for i in mats.size():
        tw.tween_property(mats[i], "albedo_color", base_colors[i].darkened(0.35), 1.5)
        tw.tween_property(mats[i], "roughness", 0.1, 1.5)


# --------------------------------------------------------- plastic damage ----
# The "melt" look (picked from the damage mockups): each hit melts a patch of
# the soldier's own plastic - darker, wet-glossy, running downward - drawn by a
# shader pass over the same mesh, so it always follows the body. Each hit is
# pinned to the nearest bone and its position re-sent every frame, so a melted
# arm stays melted where it was hit while it moves. Healing clears it.

const DamageShader = preload("res://assets/shaders/plastic_damage.gdshader")
const MAX_MARKS := 8              # the shader takes 8 hit spots
const MARKS_ENABLED := true
var _hits: Array = []             # [bone index, offset in bone space, size]
var _dmg_mat: ShaderMaterial
var _wear := 0.0


func damage_mark(world_pos: Vector3, explosive := false) -> void:
    if not MARKS_ENABLED or skeleton == null or _dead or not is_inside_tree():
        return
    var best := -1
    var best_d := INF
    for i in skeleton.get_bone_count():
        var bp: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(i).origin
        var d := bp.distance_to(world_pos)
        if d < best_d:
            best_d = d
            best = i
    if best < 0:
        return
    var bone_xf: Transform3D = skeleton.global_transform * skeleton.get_bone_global_pose(best)
    # Hits are reported on the collision capsule, a little outside the plastic:
    # pull the spot part of the way in towards the bone.
    var p: Vector3 = world_pos.lerp(bone_xf.origin, 0.35)
    var size := (0.4 if explosive else 0.26) * randf_range(0.9, 1.15)
    var offset: Vector3 = bone_xf.affine_inverse() * p
    # Another hit right next to an old one makes that patch bigger instead.
    for h in _hits:
        if h[0] == best and h[1].distance_to(offset) < 0.15:
            h[2] = minf(h[2] + size * 0.35, 0.6)
            _push_hits()
            return
    _hits.append([best, offset, size])
    if _hits.size() > MAX_MARKS:
        _hits.pop_front()
    if _dmg_mat == null:
        _dmg_mat = ShaderMaterial.new()
        _dmg_mat.shader = DamageShader
        _dmg_mat.set_shader_parameter("style", 2)
        _dmg_mat.set_shader_parameter("base_color", body_color)
        for m in find_children("*", "MeshInstance3D", true, false):
            m.material_overlay = _dmg_mat
    _dmg_mat.set_shader_parameter("wear", _wear)
    _push_hits()


## Re-sends the hit spots (bone pose -> world) so they move with the body.
func _push_hits() -> void:
    if _dmg_mat == null or skeleton == null:
        return
    var arr: Array = []
    for k in MAX_MARKS:
        if k < _hits.size():
            var h: Array = _hits[k]
            var w: Vector3 = skeleton.global_transform * (skeleton.get_bone_global_pose(h[0]) * h[1])
            arr.append(Vector4(w.x, w.y, w.z, h[2]))
        else:
            arr.append(Vector4.ZERO)
    _dmg_mat.set_shader_parameter("hits", arr)
    _dmg_mat.set_shader_parameter("hit_count", _hits.size())


func _process(_delta: float) -> void:
    if not _hits.is_empty() and is_visible_in_tree():
        _push_hits()


## 0 = fresh plastic, 1 = nearly melted.
func set_wear(w: float) -> void:
    _wear = clampf(w, 0.0, 1.0)
    if _dead:
        return
    for i in mats.size():
        mats[i].albedo_color = base_colors[i].darkened(_wear * 0.25)
        mats[i].roughness = lerpf(0.38, 0.12, _wear)
    if _dmg_mat != null:
        _dmg_mat.set_shader_parameter("wear", _wear)


func clear_damage() -> void:
    _hits.clear()
    if _dmg_mat != null:
        _dmg_mat.set_shader_parameter("hit_count", 0)
        _dmg_mat.set_shader_parameter("wear", 0.0)
    set_wear(0.0)


func damage_marks() -> int:
    return _hits.size()
