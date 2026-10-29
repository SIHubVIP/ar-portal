class_name ParkingReference
extends RefCounted
## Этап 2 ТЗ «Погуляй»: эталон парковки «Похмельная» по утверждённому ориентиру.
## Обязательные объекты п. 5: шлагбаум с будкой «Парковка платная. Сон тоже», кирпичная арка,
## технический канал со сливом, боковой двор, гаражи (строит мир), остановка такси, видимый
## дальнейший путь (улица к арке под гирляндами), киоск «НЛО напрокат», лоток с доской
## «Свежее дешевле, чем завтра». Модели — tools/blender/build_parking_set.py.

const UFO_KIOSK_POS := Vector3(-10.3, 0, -16)
const PAVEL_POS := Vector3(-7.9, 0, -15.2)
const BOOTH_POS := Vector3(-10.2, 0, -8.5)
const GATE_POS := Vector3(-8.3, 0, -11.2)
const TAXI_POS := Vector3(-7.5, 0, 4)
const CANAL_X := Vector2(9.6, 12.8)      # от перил до стены дома
const CANAL_Z := Vector2(-13.0, 10.0)
const STALLS := [Vector3(14.8, 0, -5.0), Vector3(14.8, 0, 3.5)]
const ARCH_POS := Vector3(0, 0, -68.8)

const NEON_PINK := Color(1.0, 0.3, 0.75)
const NEON_WARM := Color(1.0, 0.78, 0.4)


static func build(w: Node3D) -> void:
	_booth_and_gate(w)
	_ufo_kiosk(w)
	_taxi_stop(w)
	_canal(w)
	_market(w)
	_side_yard(w)
	_arch(w)
	_string_lights(w)
	_ac_units(w)


static func _sign(w: Node3D, text: String, pos: Vector3, yaw_deg: float, size: int, color: Color) -> Label3D:
	var l := Kit.label(w, text, pos, size, color, false)
	l.rotation_degrees.y = yaw_deg
	l.outline_size = 0
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


## Точка на модели: смещение в осях модели (лицо +Z) с поворотом yaw.
static func _at(base: Vector3, local: Vector3, yaw_deg: float) -> Vector3:
	return base + local.rotated(Vector3.UP, deg_to_rad(yaw_deg))


static func _booth_and_gate(w: Node3D) -> void:
	var yaw := 90.0
	Props.collider(w, Vector3(2.4, 2.8, 3.4), BOOTH_POS + Vector3(0, 1.4, 0))
	Props.place(w, "parking_booth", BOOTH_POS, yaw)
	_sign(w, "ПАРКОВКА ПЛАТНАЯ.\nСОН ТОЖЕ.", _at(BOOTH_POS, Vector3(0, 3.35, 1.56), yaw), yaw, 56, NEON_WARM) \
			.modulate = Color(1.5, 1.2, 0.8)
	var lamp := OmniLight3D.new()
	lamp.position = _at(BOOTH_POS, Vector3(1.3, 4.0, 1.7), yaw)
	lamp.light_color = NEON_WARM
	lamp.light_energy = 1.6
	lamp.omni_range = 6.0
	w.add_child(lamp)
	Props.collider(w, Vector3(0.5, 1.2, 0.5), GATE_POS + Vector3(0, 0.6, 0))
	Props.place(w, "boom_gate", GATE_POS, 0.0)
	Props.collider(w, Vector3(4.6, 0.3, 0.2), GATE_POS + Vector3(2.7, 1.0, 0))


static func _ufo_kiosk(w: Node3D) -> void:
	var yaw := 90.0
	Props.collider(w, Vector3(2.6, 2.8, 4.0), UFO_KIOSK_POS + Vector3(0, 1.4, 0))
	Props.place(w, "ufo_kiosk", UFO_KIOSK_POS, yaw)
	var neon := _sign(w, "НЛО\nнапрокат", _at(UFO_KIOSK_POS, Vector3(0, 3.15, 1.5), yaw), yaw, 64, NEON_PINK)
	neon.modulate = Color(1.6, 0.8, 1.6)
	PogulyayDressing._blink(neon)
	var l := OmniLight3D.new()
	l.position = _at(UFO_KIOSK_POS, Vector3(0, 3.0, 2.0), yaw)
	l.light_color = Color(1.0, 0.5, 0.8)
	l.light_energy = 2.6
	l.omni_range = 7.0
	w.add_child(l)


static func _taxi_stop(w: Node3D) -> void:
	Props.collider(w, Vector3(1.8, 1.4, 4.3), TAXI_POS + Vector3(0, 0.7, 0))
	Props.place(w, "taxi", TAXI_POS, 180.0)
	var pole := TAXI_POS + Vector3(-1.4, 0, 3.3)
	Props.collider(w, Vector3(0.2, 2.8, 0.2), pole + Vector3(0, 1.4, 0))
	Props.place(w, "taxi_sign", pole, 90.0)
	_sign(w, "ТАКСИ", _at(pole, Vector3(0, 2.62, 0.09), 90.0), 90.0, 40, Color(0.1, 0.08, 0.05))
	_sign(w, "ТАКСИ", Vector3(-12.9, 4.2, 6.5), 90.0, 110, NEON_WARM).modulate = Color(1.4, 1.1, 0.6)


## Технический канал вдоль восточного дома: вода течёт к решётке, из трубы льётся слив.
static func _canal(w: Node3D) -> void:
	var length_z := CANAL_Z.y - CANAL_Z.x
	var cz := (CANAL_Z.x + CANAL_Z.y) / 2.0
	var width := CANAL_X.y - CANAL_X.x
	var cx := (CANAL_X.x + CANAL_X.y) / 2.0
	# тёмная вода «ниже» уровня двора и бетонные борта
	var water := MeshInstance3D.new()
	var wm := BoxMesh.new()
	wm.size = Vector3(width - 0.5, 0.02, length_z)
	water.mesh = wm
	water.position = Vector3(cx + 0.1, 0.035, cz)
	var noise := FastNoiseLite.new()
	noise.frequency = 0.05
	var ripples := NoiseTexture2D.new()
	ripples.noise = noise
	ripples.seamless = true
	ripples.as_normal_map = true
	ripples.bump_strength = 6.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.04, 0.07, 0.08)
	mat.metallic = 0.4
	mat.roughness = 0.04
	mat.normal_enabled = true
	mat.normal_texture = ripples
	mat.uv1_scale = Vector3(1.5, 4.0, 1)
	water.material_override = mat
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	water.set_meta("map_skip", true)
	w.add_child(water)
	var flow := water.create_tween().set_loops()
	flow.tween_property(mat, "uv1_offset:y", -1.0, 6.0).from(0.0)
	for x in [CANAL_X.x, CANAL_X.y - 0.05]:
		var curb := Kit.box(w, Vector3(0.3, 0.35, length_z), Vector3(x, 0.175, cz), Color.WHITE)
		curb.material_override = _concrete()
	Kit.box(w, Vector3(width, 0.04, 0.3), Vector3(cx, 0.06, CANAL_Z.x), Color(0.12, 0.12, 0.13))   # решётка
	# перила и невидимая стена
	Props.collider(w, Vector3(0.3, 1.2, length_z), Vector3(CANAL_X.x - 0.15, 0.6, cz))
	var z := CANAL_Z.x + 2.0
	while z < CANAL_Z.y:
		Props.place(w, "canal_rail", Vector3(CANAL_X.x - 0.15, 0.35, z), 90.0)
		z += 4.0
	# слив из стены
	var outlet := Vector3(CANAL_X.y - 0.2, 1.3, 2.5)
	Kit.cylinder(w, 0.22, 0.6, outlet, Color(0.3, 0.29, 0.27)).rotation_degrees.z = 90.0
	PogulyayDressing.particles(w, outlet + Vector3(-0.3, -0.1, 0), Color(0.65, 0.8, 0.9, 0.7), 40, 0.7,
			Vector3(-0.6, -2.2, 0), 0.1, 0.08, Vector3(0.08, 0.02, 0.12))
	PogulyayDressing.particles(w, Vector3(outlet.x - 0.7, 0.12, outlet.z), Color(0.8, 0.9, 1.0, 0.35), 16, 0.8,
			Vector3(0, 0.6, 0), 0.6, 0.25, Vector3(0.3, 0.02, 0.3))


static func _concrete() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.42, 0.41, 0.39)
	m.roughness = 0.6
	return m


static func _market(w: Node3D) -> void:
	# рынок на дальнем берегу канала, лотки смотрят к камере
	for st: Vector3 in STALLS:
		Props.collider(w, Vector3(3.0, 1.2, 1.4), st + Vector3(0, 0.6, 0))
		Props.place(w, "market_stall", st, 0.0)
	var l := OmniLight3D.new()          # один свет на оба лотка
	l.position = (STALLS[0] + STALLS[1]) / 2.0 + Vector3(0, 2.6, 1.0)
	l.light_color = NEON_WARM
	l.light_energy = 2.0
	l.omni_range = 8.0
	w.add_child(l)
	for c in [Vector3(16.0, 0, -0.8), Vector3(13.6, 0, 7.5), Vector3(16.1, 0, -9.0)]:
		Props.place(w, "beer_crate" if c.z > 0 else "boxes", c, randf_range(-30, 30))
	var board := Vector3(9.3, 0, -14.6)
	Props.collider(w, Vector3(0.9, 1.4, 0.4), board + Vector3(0, 0.7, 0))
	Props.place(w, "chalk_board", board, 45.0)
	_sign(w, "СВЕЖЕЕ\nДЕШЕВЛЕ,\nЧЕМ\nЗАВТРА", _at(board, Vector3(0, 1.08, 0.06), 45.0), 45.0, 30,
			Color(0.75, 0.12, 0.1))


## Боковой двор в просвете между западными домами: мусорка, бельё, своя лампа.
static func _side_yard(w: Node3D) -> void:
	var c := Vector3(-14.5, 0, -28)
	Props.collider(w, Vector3(1.8, 1.4, 1.2), c + Vector3(0.5, 0.7, -1.2))
	Props.place(w, "dumpster", c + Vector3(0.5, 0, -1.2), 90.0)
	for i in 5:
		var cloth := Kit.box(w, Vector3(0.05, 0.7, 0.6), c + Vector3(-0.4, 2.6, 1.5 - i * 0.7),
				[Color(0.85, 0.3, 0.3), Color(0.9, 0.9, 0.85), Color(0.3, 0.5, 0.8)][i % 3])
		cloth.rotation_degrees.x = randf_range(-6, 6)
	Kit.box(w, Vector3(0.02, 0.02, 4.0), c + Vector3(-0.4, 2.95, 0), Color(0.15, 0.15, 0.15))
	var l := OmniLight3D.new()
	l.position = c + Vector3(0, 3.5, 0)
	l.light_color = Color(1.0, 0.7, 0.4)
	l.light_energy = 1.4
	l.omni_range = 5.0
	w.add_child(l)
	_sign(w, "ДВОР · ПРОХОДА НЕТ\nДАЖЕ ДЛЯ ТАРЕЛОК", c + Vector3(1.6, 2.2, 2.0), 90.0, 24, Color(0.95, 0.9, 0.8))


## Кирпичная арка на выходе: модель на фасаде, дом над ней и соседние торцы — в кирпич.
static func _arch(w: Node3D) -> void:
	var arch := Props.place(w, "brick_arch", ARCH_POS, 0.0)
	if arch:
		Surfaces.retexture(arch)
	for n in w.get_children():
		if n is StaticBody3D and n.position.z < -66.0 and n.position.z > -78.0 and n.is_in_group("occluders"):
			Surfaces.brick_all(n)
	var l := OmniLight3D.new()
	l.position = ARCH_POS + Vector3(0, 6.6, 2.6)
	l.light_color = NEON_WARM
	l.light_energy = 2.5
	l.omni_range = 9.0
	w.add_child(l)


## Гирлянды поперёк улицы: ведут взгляд к арке (видимый дальнейший путь).
static func _string_lights(w: Node3D) -> void:
	var spans := [[-4.0, 6.4], [-21.0, 6.8], [-33.0, 6.2], [-45.0, 7.0], [-57.0, 6.6]]
	var points: Array[Vector3] = []
	for s in spans:
		var a := Vector3(-12.9, s[1], s[0])
		var b := Vector3(12.9, s[1] - 0.4, s[0] - 2.0)
		for i in 33:
			var t := i / 32.0
			points.append(a.lerp(b, t) - Vector3(0, 1.4 * 4.0 * t * (1.0 - t), 0))
	var sphere := SphereMesh.new()
	sphere.radius = 0.08
	sphere.height = 0.16
	sphere.radial_segments = 6
	sphere.rings = 3
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = sphere
	mm.instance_count = points.size()
	for i in points.size():
		mm.set_instance_transform(i, Transform3D(Basis(), points[i]))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = Kit.mat(NEON_WARM, 4.0)
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	w.add_child(mmi)


static func _ac_units(w: Node3D) -> void:
	for a in [[Vector3(-12.75, 3.4, -2.2), 90.0], [Vector3(-12.75, 6.4, -12.5), 90.0], [Vector3(-12.75, 9.3, 9.0), 90.0],
			[Vector3(12.75, 3.6, 7.5), -90.0], [Vector3(12.75, 6.5, -9.0), -90.0], [Vector3(12.75, 3.4, -24.0), -90.0],
			[Vector3(12.75, 9.5, -40.0), -90.0], [Vector3(-12.75, 6.2, -42.0), 90.0]]:
		Props.place(w, "ac_unit", a[0], a[1])
