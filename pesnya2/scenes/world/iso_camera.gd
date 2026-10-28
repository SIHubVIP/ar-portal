class_name IsoCamera
extends Camera3D
## Изометрическая камера: наклон 55°, ограниченный зум, поворот вокруг героя
## (свайп по свободной части экрана или кнопки ⟲ ⟳). Здания между камерой
## и героем становятся полупрозрачными. Ввод стика всегда относительно камеры.

const PITCH_MIN := deg_to_rad(28.0)
const PITCH_MAX := deg_to_rad(80.0)
const ZOOM_MIN := 10.0
const ZOOM_MAX := 26.0

var target: Node3D
var distance := 14.0
var yaw := deg_to_rad(45.0)
var pitch := deg_to_rad(52.0)
var _pitch_target := deg_to_rad(52.0)
var _yaw_target := deg_to_rad(45.0)
var _faded: Array = []


func _ready() -> void:
	fov = 40.0
	far = 400.0
	if target:
		global_position = _desired()
		look_at(target.global_position + Vector3(0, 1, 0), Vector3.UP)


func zoom_by(amount: float) -> void:
	distance = clampf(distance + amount, ZOOM_MIN, ZOOM_MAX)


## Плавный поворот на угол (радианы); свайп передаёт мелкие шаги.
func rotate_by(radians: float) -> void:
	_yaw_target += radians


## Наклон камеры: свайп вверх-вниз. Ниже — видно фасады и небо, выше — почти карта.
func tilt_by(radians: float) -> void:
	_pitch_target = clampf(_pitch_target + radians, PITCH_MIN, PITCH_MAX)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_by(-1.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_by(1.0)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_Z:
			rotate_by(deg_to_rad(-45.0))
		elif event.physical_keycode == KEY_X:
			rotate_by(deg_to_rad(45.0))
		elif event.physical_keycode == KEY_R:
			tilt_by(deg_to_rad(-8.0))
		elif event.physical_keycode == KEY_F:
			tilt_by(deg_to_rad(8.0))


func _desired() -> Vector3:
	var back := Vector3(sin(yaw), 0, cos(yaw)) * cos(pitch)
	return target.global_position + (back + Vector3(0, sin(pitch), 0)) * distance


func _physics_process(delta: float) -> void:
	if target == null:
		return
	yaw = lerp_angle(yaw, _yaw_target, clampf(12.0 * delta, 0.0, 1.0))
	pitch = lerpf(pitch, _pitch_target, clampf(12.0 * delta, 0.0, 1.0))
	if "camera_yaw" in target:
		target.camera_yaw = yaw
	global_position = global_position.lerp(_desired(), clampf(10.0 * delta, 0.0, 1.0))
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
	for mi in body.find_children("*", "GeometryInstance3D", true, false):
		mi.transparency = 1.0 - alpha
