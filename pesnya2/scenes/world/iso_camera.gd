class_name IsoCamera
extends Camera3D
## Изометрическая камера: фиксированный азимут 45°, наклон 55°, ограниченный зум.
## Здания между камерой и героем становятся полупрозрачными.

const YAW := deg_to_rad(45.0)
const PITCH := deg_to_rad(55.0)
const ZOOM_MIN := 12.0
const ZOOM_MAX := 26.0

var target: Node3D
var distance := 18.0
var _faded: Array = []


func _ready() -> void:
	fov = 40.0
	far = 400.0
	if target:
		global_position = _desired()
		look_at(target.global_position + Vector3(0, 1, 0), Vector3.UP)


func zoom_by(amount: float) -> void:
	distance = clampf(distance + amount, ZOOM_MIN, ZOOM_MAX)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_by(-1.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_by(1.0)


func _desired() -> Vector3:
	var back := Vector3(sin(YAW), 0, cos(YAW)) * cos(PITCH)
	return target.global_position + (back + Vector3(0, sin(PITCH), 0)) * distance


func _physics_process(delta: float) -> void:
	if target == null:
		return
	global_position = global_position.lerp(_desired(), clampf(8.0 * delta, 0.0, 1.0))
	look_at(target.global_position + Vector3(0, 1, 0), Vector3.UP)
	_update_occluders()


func _update_occluders() -> void:
	var space := get_world_3d().direct_space_state
	var hits: Array = []
	var from := global_position
	var to := target.global_position + Vector3(0, 1, 0)
	var exclude: Array[RID] = []
	for i in 4:
		var q := PhysicsRayQueryParameters3D.create(from, to, 1, exclude)
		var r := space.intersect_ray(q)
		if r.is_empty():
			break
		var c: Object = r.collider
		if c is Node and c.is_in_group("occluders"):
			hits.append(c)
		exclude.append(r.rid)
	for c in _faded:
		if is_instance_valid(c) and not hits.has(c):
			_set_alpha(c, 1.0)
	for c in hits:
		_set_alpha(c, 0.25)
	_faded = hits


func _set_alpha(body: Node, alpha: float) -> void:
	for mi in body.find_children("*", "MeshInstance3D", true, false):
		mi.transparency = 1.0 - alpha
