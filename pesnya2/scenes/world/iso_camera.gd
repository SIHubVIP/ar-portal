class_name IsoCamera
extends Camera3D
## Изометрическая камера по ТЗ «Погуляй» п. 7: ортографическая проекция, 45° по сторонам,
## наклон 55°. Кадр 12 м (ТЗ — 24 м; владелец дважды просил ближе, D-033, D-043). Зум меняет размер кадра. По дополнению владельца к ТЗ
## камеру можно крутить вокруг героя и наклонять вверх-вниз (свайп по свободной части экрана
## или кнопки ⟲ ⟳); ТЗ запрещало вращение, решение D-029. Здания между камерой и героем
## становятся полупрозрачными. Ввод стика всегда относительно камеры.

const PITCH_MIN := deg_to_rad(28.0)
const PITCH_MAX := deg_to_rad(80.0)
const ZOOM_MIN := 8.0
const ZOOM_MAX := 26.0
## Кадр по умолчанию: 12 м (D-043, владелец: «камера слишком далеко», было 18).
const DEFAULT_SIZE := 11.0
## Камера стоит на этом расстоянии от героя: в ортографике оно не меняет масштаб,
## только то, что попадает между камерой и героем.
const ARM := 60.0

var target: Node3D
var yaw := deg_to_rad(45.0)
var pitch := deg_to_rad(55.0)
var _pitch_target := deg_to_rad(55.0)
var _yaw_target := deg_to_rad(45.0)
var _faded: Array = []
var _shake := 0.0
var _tube := BoxShape3D.new()
# кинокамера разговора: 0 — изометрия, 1 — почти от лица героя
var _cine := 0.0
var _cine_dir := 0
var _cine_eye := Vector3.ZERO
var _cine_look := Vector3.ZERO
var _iso_size := DEFAULT_SIZE

## Ширина и высота «прозрачного коридора» от камеры к герою, метры: всё, что в нём, тает.
const SEE_THROUGH := Vector2(9.0, 7.0)
const CINE_TIME := 0.9
const CINE_FOV := 50.0
const CINE_MIN_DIST := 3.4
const CINE_RISE := 0.35
const CINE_TILT := 8.0
## Свет «как в кино»: тёплая лампа у камеры подсвечивает лицо собеседника ночью.
var _key_light: OmniLight3D


func _ready() -> void:
	add_to_group("iso_camera")
	# разговор ставит дерево на паузу, а кинокамера должна доехать
	process_mode = Node.PROCESS_MODE_ALWAYS
	_key_light = OmniLight3D.new()
	_key_light.light_color = Color(1.0, 0.86, 0.7)
	_key_light.light_energy = 0.0
	_key_light.omni_range = 9.0
	_key_light.visible = false
	add_child(_key_light)
	projection = PROJECTION_ORTHOGONAL
	size = DEFAULT_SIZE
	near = 1.0
	far = 400.0
	if target:
		global_position = _desired()
		look_at(target.global_position + Vector3(0, 1, 0), Vector3.UP)


## Тряска при ударе: смещение кадра гаснет за ~0,3 с.
func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


## Кинокамера разговора (D-044): из изометрии камера переезжает к голове героя и смотрит
## на собеседника почти от первого лица. Если он на балконе — смотрим вверх.
func cinematic(npc_head: Vector3) -> void:
	if target == null:
		return
	var head := target.global_position + Vector3(0, 1.65, 0)
	var flat := (npc_head - head) * Vector3(1, 0, 1)
	var d := flat.normalized() if flat.length() > 0.1 else Vector3.FORWARD
	var right := d.cross(Vector3.UP).normalized()
	# глаза героя (модель скрыта), чуть выше роста и на шаг дальше: собеседник виден по пояс,
	# а не одна макушка (владелец, 0.9). Выше собеседник (балкон) — шаг назад, чтобы не мешали перила.
	var back := maxf(maxf(flat.length() + 0.15, CINE_MIN_DIST), (npc_head.y - head.y) * 1.5)
	var stand := npc_head * Vector3(1, 0, 1) - d * back
	_cine_eye = Vector3(stand.x, head.y + CINE_RISE, stand.z) + right * 0.12
	# низ экрана занимает реплика: смотрим ниже груди собеседника на CINE_TILT, и он встаёт
	# в верхнюю половину кадра целиком — голова, плечи, руки
	var chest := npc_head - Vector3(0, 0.5, 0)
	var to_chest := (chest - _cine_eye).normalized()
	# собеседник наверху: перила и так внизу кадра, наклон вниз упрёт взгляд в балкон
	var tilt := CINE_TILT * clampf(1.0 - (npc_head.y - head.y) / 3.0, 0.2, 1.0)
	var aim := to_chest.rotated(right, -deg_to_rad(tilt)) if absf(to_chest.dot(Vector3.UP)) < 0.95 else to_chest
	_cine_look = _cine_eye + aim * 3.0
	if _cine_dir == 0 and _cine <= 0.0:
		_iso_size = size
	_cine_dir = 1


func end_cinematic() -> void:
	if _cine > 0.0 or _cine_dir > 0:
		_cine_dir = -1


func in_cinematic() -> bool:
	return _cine > 0.0 or _cine_dir != 0


func _update_cinematic(delta: float) -> void:
	_cine = clampf(_cine + _cine_dir * delta / CINE_TIME, 0.0, 1.0)
	var iso_pos := _desired()
	var iso_look := target.global_position + Vector3(0, 1, 0)
	if _cine <= 0.0 and _cine_dir < 0:
		_cine_dir = 0
		projection = PROJECTION_ORTHOGONAL
		size = _iso_size
		near = 1.0
		_key_light.visible = false
		global_position = iso_pos
		look_at(iso_look, Vector3.UP)
		return
	if _cine >= 1.0 and _cine_dir > 0:
		_cine_dir = 0
	var e := smoothstep(0.0, 1.0, _cine)
	# из ортографики в перспективу без скачка: начальный угол обзора даёт тот же кадр
	var fov0 := rad_to_deg(2.0 * atan(_iso_size / 2.0 / ARM))
	projection = PROJECTION_PERSPECTIVE
	near = 0.05
	fov = lerpf(fov0, CINE_FOV, e)
	_key_light.visible = e > 0.3
	_key_light.light_energy = 2.2 * e
	global_position = iso_pos.lerp(_cine_eye, 1.0 - pow(1.0 - e, 2.0))
	look_at(iso_look.lerp(_cine_look, e), Vector3.UP)
	h_offset = 0.0
	v_offset = 0.0


func zoom_by(amount: float) -> void:
	size = clampf(size + amount, ZOOM_MIN, ZOOM_MAX)


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
	return target.global_position + (back + Vector3(0, sin(pitch), 0)) * ARM


func _physics_process(delta: float) -> void:
	if target == null:
		return
	if in_cinematic():
		_update_cinematic(delta)
		return
	if get_tree().paused:
		return
	yaw = lerp_angle(yaw, _yaw_target, clampf(12.0 * delta, 0.0, 1.0))
	pitch = lerpf(pitch, _pitch_target, clampf(12.0 * delta, 0.0, 1.0))
	if "camera_yaw" in target:
		target.camera_yaw = yaw
	global_position = global_position.lerp(_desired(), clampf(10.0 * delta, 0.0, 1.0))
	look_at(target.global_position + Vector3(0, 1, 0), Vector3.UP)
	if _shake > 0.01:
		h_offset = randf_range(-_shake, _shake)
		v_offset = randf_range(-_shake, _shake)
		_shake = lerpf(_shake, 0.0, clampf(14.0 * delta, 0.0, 1.0))
	elif h_offset != 0.0 or v_offset != 0.0:
		h_offset = 0.0
		v_offset = 0.0
		_shake = 0.0
	var vp := get_viewport().get_visible_rect().size
	if vp.x > 0.0:
		RenderingServer.global_shader_parameter_set("hero_screen",
				unproject_position(target.global_position + Vector3(0, 1.0, 0)) / vp)
		# глубина героя от камеры: мелкие дома в MultiMesh вырезают всё, что ближе (depth_cut)
		RenderingServer.global_shader_parameter_set("hero_depth",
				-(global_transform.affine_inverse() * (target.global_position + Vector3(0, 1.0, 0))).z)
	_update_occluders()


func _update_occluders() -> void:
	var space := get_world_3d().direct_space_state
	var hits: Array = []
	var from := global_position
	var to := target.global_position + Vector3(0, 1, 0)
	# не один луч, а коридор SEE_THROUGH: тает всё, что закрывает героя и то, что рядом с ним
	var dir := to - from
	var length := dir.length() - 2.0
	if length > 1.0:
		_tube.size = Vector3(SEE_THROUGH.x, SEE_THROUGH.y, length)
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = _tube
		q.collision_mask = 1
		q.transform = Transform3D(Basis.looking_at(dir, Vector3.UP), from + dir.normalized() * length / 2.0)
		for r in space.intersect_shape(q, 48):
			var c: Object = r.collider
			if c is Node and c.is_in_group("occluders") and not hits.has(c):
				hits.append(c)
	for c in _faded:
		if is_instance_valid(c) and not hits.has(c):
			_set_alpha(c, 1.0)
	for c in hits:
		_set_alpha(c, 0.0)
	_faded = hits


## Здание в коридоре: стены в круге вокруг героя вырезаются (D-046). Материалы подменяются
## копиями с шейдером see_through (непрозрачный проход, без сортировки и наложения слоёв),
## дома района — вариантом своего шейдера с cut = true. Всё кэшируется: шейдер один.
func _set_alpha(body: Node, alpha: float) -> void:
	for gi in body.find_children("*", "GeometryInstance3D", true, false):
		if not gi is MeshInstance3D:
			gi.transparency = 1.0 - alpha
			continue
		var mi := gi as MeshInstance3D
		if alpha >= 1.0:
			if mi.has_meta("fade_orig"):
				var orig: Array = mi.get_meta("fade_orig")
				mi.material_override = orig[0]
				for k in mi.get_surface_override_material_count():
					mi.set_surface_override_material(k, orig[1][k] if k < orig[1].size() else null)
				mi.remove_meta("fade_orig")
			continue
		if mi.has_meta("fade_orig") or mi.mesh == null:
			continue
		var surf: Array = []
		for k in mi.get_surface_override_material_count():
			surf.append(mi.get_surface_override_material(k))
		mi.set_meta("fade_orig", [mi.material_override, surf])
		if mi.material_override:
			mi.material_override = cut_material(mi.material_override)
		else:
			for k in mi.get_surface_override_material_count():
				mi.set_surface_override_material(k, cut_material(mi.get_active_material(k)))


const SEE_THROUGH_SHADER := preload("res://assets/shaders/see_through.gdshader")
static var _cut_cache: Dictionary = {}


## Вариант материала с вырезом вокруг героя.
static func cut_material(m: Material) -> Material:
	if m == null:
		return null
	if _cut_cache.has(m):
		return _cut_cache[m]
	var out: Material = m
	if m is ShaderMaterial and (m as ShaderMaterial).shader and "cut" in str((m as ShaderMaterial).shader.code):
		out = m.duplicate()
		(out as ShaderMaterial).set_shader_parameter("cut", true)
	elif m is BaseMaterial3D:
		var b := m as BaseMaterial3D
		var sm := ShaderMaterial.new()
		sm.shader = SEE_THROUGH_SHADER
		sm.set_shader_parameter("albedo", b.albedo_color)
		sm.set_shader_parameter("use_tex", b.albedo_texture != null)
		if b.albedo_texture:
			sm.set_shader_parameter("albedo_tex", b.albedo_texture)
		sm.set_shader_parameter("triplanar", b.uv1_triplanar)
		sm.set_shader_parameter("uv_scale", b.uv1_scale)
		sm.set_shader_parameter("roughness", b.roughness)
		if b.emission_enabled:
			sm.set_shader_parameter("emission", b.emission)
			sm.set_shader_parameter("emission_energy", b.emission_energy_multiplier)
		out = sm
	_cut_cache[m] = out
	return out
