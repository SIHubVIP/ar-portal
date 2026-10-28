class_name Props
extends RefCounted
## Модели города из assets/city (собираются tools/blender/build_city_assets.py).
## Столкновения остаются простыми коробками: модель — только картинка.

const DIR := "res://assets/city/%s.glb"

static var _cache: Dictionary = {}


static func exists(name: String) -> bool:
	return ResourceLoader.exists(DIR % name)


## Ставит модель; yaw_deg поворачивает «лицо» модели (+Z) куда нужно. Без модели вернёт null.
static func place(parent: Node, name: String, pos: Vector3, yaw_deg := 0.0, scale := Vector3.ONE) -> Node3D:
	if not exists(name):
		return null
	if not _cache.has(name):
		_cache[name] = load(DIR % name)
	var n: Node3D = _cache[name].instantiate()
	n.position = pos
	n.rotation_degrees.y = yaw_deg
	n.scale = scale
	parent.add_child(n)
	return n


## Невидимая коробка столкновения (occluder — здание, которое камера делает прозрачным).
static func collider(parent: Node, size: Vector3, pos: Vector3, occluder := false) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	parent.add_child(body)
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	shape.shape = bs
	body.add_child(shape)
	if occluder:
		body.add_to_group("occluders")
	return body
