class_name NpcModel
extends Node3D
## Человечек из tools/blender/build_npc_body.py (0.9): тело, голова с лицом, руки, причёска.
## Облик — словарь цветов и стиля; материал кэшируется по облику. Анимация кодом: дыхание,
## руки при ходьбе (walk 0..1), кивки и жесты в разговоре (talking).

const SCENE := preload("res://assets/characters/npc/npc_body.glb")
const SHADER := preload("res://assets/shaders/npc_palette.gdshader")
const HAIRS := ["short", "bun", "curlers", "bald"]
const SKINS := [Color(0.92, 0.76, 0.64), Color(0.84, 0.66, 0.52), Color(0.7, 0.52, 0.4), Color(0.55, 0.4, 0.3)]
const HAIR_COLORS := [Color(0.12, 0.09, 0.07), Color(0.35, 0.22, 0.12), Color(0.7, 0.55, 0.3), Color(0.55, 0.55, 0.55),
		Color(0.6, 0.2, 0.15)]
const CLOTHES := [Color(0.7, 0.2, 0.25), Color(0.2, 0.35, 0.6), Color(0.85, 0.75, 0.3), Color(0.25, 0.25, 0.28),
		Color(0.4, 0.55, 0.35), Color(0.6, 0.4, 0.65), Color(0.9, 0.9, 0.88), Color(0.55, 0.35, 0.2)]

var look: Dictionary = {}
var walk := 0.0
var talking := false
var _t := 0.0
var _head: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _body: Node3D
static var _mats: Dictionary = {}


static func make(look_: Dictionary) -> NpcModel:
	var m := NpcModel.new()
	m.look = look_
	return m


## Точка на модели в её осях с учётом роста: для очков, кепок и того, что в руках.
static func at(l: Dictionary, p: Vector3) -> Vector3:
	var h := float(l.get("height", 1.0))
	var w := float(l.get("width", 1.0))
	return Vector3(p.x * h * w, p.y * h, p.z * h * w)


## Случайный облик для прохожих и очереди.
static func random_look(rng: RandomNumberGenerator, top := Color(0, 0, 0, 0)) -> Dictionary:
	var female := rng.randf() < 0.5
	return {"skin": SKINS[rng.randi_range(0, SKINS.size() - 1)], "top": top if top.a > 0.0 else CLOTHES[rng.randi_range(0, CLOTHES.size() - 1)],
			"bottom": CLOTHES[rng.randi_range(0, CLOTHES.size() - 1)].darkened(0.4), "hair": HAIR_COLORS[rng.randi_range(0, HAIR_COLORS.size() - 1)],
			"style": ("bun" if rng.randf() < 0.6 else "short") if female else ("short" if rng.randf() < 0.75 else "bald"),
			"skirt": female and rng.randf() < 0.6, "height": rng.randf_range(0.92, 1.06)}


func _ready() -> void:
	_t = randf() * 10.0
	var inst := SCENE.instantiate()
	add_child(inst)
	var mat := _material(look)
	var style: String = look.get("style", "short")
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		var n := String(mi.name)
		mi.material_override = mat
		if n.begins_with("Hair"):
			mi.visible = (n == "HairShort" and style == "short") or (n == "HairBun" and style == "bun") \
					or (n == "HairCurlers" and style == "curlers")
		elif n == "Skirt":
			mi.visible = look.get("skirt", false)
		match n:
			"Head": _head = mi
			"ArmL": _arm_l = mi
			"ArmR": _arm_r = mi
			"Body": _body = mi
	# причёски крутятся вместе с головой
	for mi in inst.find_children("Hair*", "MeshInstance3D", true, false):
		mi.reparent(_head)
	var h := float(look.get("height", 1.0))
	var w := float(look.get("width", 1.0))
	scale = Vector3(h * w, h, h * w)


## Разговор идёт на паузе игры: на это время модель живёт и при паузе.
func set_talking(on: bool) -> void:
	talking = on
	process_mode = Node.PROCESS_MODE_ALWAYS if on else Node.PROCESS_MODE_INHERIT
	if on:
		add_to_group("npc_talking")
	elif is_in_group("npc_talking"):
		remove_from_group("npc_talking")


static func _material(l: Dictionary) -> ShaderMaterial:
	var key := str(l.get("skin"), l.get("top"), l.get("bottom"), l.get("hair"), l.get("emission", 0.0))
	if _mats.has(key):
		return _mats[key]
	var m := ShaderMaterial.new()
	m.shader = SHADER
	for k in ["skin", "top", "bottom", "hair", "shoes", "mouth"]:
		if l.has(k):
			m.set_shader_parameter(k, l[k])
	m.set_shader_parameter("emission", float(l.get("emission", 0.0)))
	_mats[key] = m
	return m


func _process(delta: float) -> void:
	if not is_visible_in_tree() or _head == null:
		return
	_t += delta
	var swing := sin(_t * 7.0) * 0.55 * walk
	_arm_l.rotation.x = swing
	_arm_r.rotation.x = -swing
	if talking:
		# кивает и жестикулирует правой рукой
		_head.rotation.x = sin(_t * 3.1) * 0.08
		_head.rotation.y = sin(_t * 1.3) * 0.12
		_arm_r.rotation.x = -0.6 + sin(_t * 2.4) * 0.35
		_arm_r.rotation.z = -0.2
	else:
		_head.rotation.x = 0.0
		_head.rotation.y = sin(_t * 0.4) * 0.25 * (1.0 - walk)
		_arm_r.rotation.z = 0.0
	# дыхание
	_body.scale.y = 1.0 + sin(_t * 2.0) * 0.008
