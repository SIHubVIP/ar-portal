class_name Kit
extends RefCounted
## Простая геометрия-заглушка с правильными ID: настоящие модели .glb потом
## подменяют эти узлы по одному, не трогая игровую логику.

static var _materials: Dictionary = {}


static func mat(color: Color, emission := 0.0, roughness := 0.85) -> StandardMaterial3D:
	var key := "%s|%s|%s" % [color.to_html(), emission, roughness]
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	_materials[key] = m
	return m


static func box(parent: Node, size: Vector3, pos: Vector3, color: Color, emission := 0.0) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add(parent, mesh, pos, color, emission)


static func cylinder(parent: Node, radius: float, height: float, pos: Vector3, color: Color, emission := 0.0,
		top_radius := -1.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius if top_radius < 0.0 else top_radius
	mesh.height = height
	# по умолчанию 64 грани — для мобильного кадра это тысячи треугольников на каждый столбик
	mesh.radial_segments = 24 if maxf(radius, mesh.top_radius) > 3.0 else 12
	mesh.rings = 1
	return _add(parent, mesh, pos, color, emission)


static func sphere(parent: Node, radius: float, pos: Vector3, color: Color, emission := 0.0) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 24 if radius > 3.0 else 12
	mesh.rings = 12 if radius > 3.0 else 6
	return _add(parent, mesh, pos, color, emission)


static func capsule(parent: Node, radius: float, height: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 2
	return _add(parent, mesh, pos, color, 0.0)


static func label(parent: Node, text: String, pos: Vector3, size := 64, color := Color.WHITE,
		billboard := true) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.01
	l.modulate = color
	l.outline_size = 12
	l.outline_modulate = Color(0, 0, 0, 0.85)
	l.position = pos
	l.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if billboard:
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = false
	parent.add_child(l)
	return l


## Твёрдое препятствие: статическое тело с коробкой коллизии того же размера.
static func solid_box(parent: Node, size: Vector3, pos: Vector3, color: Color, emission := 0.0,
		occluder := false) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	parent.add_child(body)
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	shape.shape = bs
	body.add_child(shape)
	box(body, size, Vector3.ZERO, color, emission)
	if occluder:
		body.add_to_group("occluders")
	return body


static func _add(parent: Node, mesh: Mesh, pos: Vector3, color: Color, emission: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat(color, emission)
	mi.position = pos
	# мелочь и светящееся тень не отбрасывают: на телефоне каждая тень — ещё один проход
	var extent := mesh.get_aabb().size
	if emission > 0.0 or maxf(extent.x, maxf(extent.y, extent.z)) < 1.2:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


## Кольцо-телеграф на земле, которое гаснет само.
static func ring(parent: Node, pos: Vector3, radius: float, color: Color, duration := 0.35) -> void:
	var mi := cylinder(parent, radius, 0.05, pos + Vector3(0, 0.06, 0), color, 2.0)
	mi.material_override = mat(Color(color.r, color.g, color.b, 0.55), 2.0)
	var tw := mi.create_tween()
	tw.tween_property(mi, "scale", Vector3(1.15, 1, 1.15), duration)
	tw.tween_callback(mi.queue_free)


## Луч выстрела между двумя точками.
static func beam(parent: Node, from: Vector3, to: Vector3, color: Color, duration := 0.15) -> void:
	var len := from.distance_to(to)
	if len < 0.01:
		return
	var mi := box(parent, Vector3(0.12, 0.12, len), (from + to) * 0.5, color, 3.0)
	mi.look_at_from_position((from + to) * 0.5, to, Vector3.UP)
	var tw := mi.create_tween()
	tw.tween_interval(duration)
	tw.tween_callback(mi.queue_free)
