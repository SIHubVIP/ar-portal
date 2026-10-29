class_name PogulyayDressing
extends RefCounted
## Наполнение Погуляя: ночь, свет фонарей и неона, прожекторы тарелки, следы вторжения,
## мусор, который можно разнести, частицы и границы карты. Сюжет здесь не решается —
## это декорации, которые рассказывают, что тут было вчера.

const LAMPS_LEFT_X := -8.6
const LAMPS_RIGHT_X := 8.6
## Игровая область: за её пределы не выйти (невидимые стены + заборы в просветах).
const BOUNDS := Rect2(-16.5, -66.5, 33.0, 86.0)
## Полуширина проёма кирпичной арки на севере двора: выход в остальной Погуляй (ТЗ п. 5 «открыть выход из двора»).
const ARCH_HALF_W := 3.5


## Открыть выход из двора: ворота уезжают вверх, коллизия снимается.
static func open_exit(w: Node3D, instant := false) -> void:
	var gate := w.get_node_or_null("ExitGate") as StaticBody3D
	if gate == null or gate.has_meta("opened"):
		return
	gate.set_meta("opened", true)
	gate.collision_layer = 0
	if instant:
		gate.position.y += 4.5
	else:
		gate.create_tween().tween_property(gate, "position:y", gate.position.y + 4.5, 1.2)


static func build(w: Node3D) -> void:
	_ground(w)
	_lamps(w)
	_neon(w)
	_ufo_searchlights(w)
	_story_traces(w)
	_trash(w)
	_graffiti(w)
	_bounds(w)


# ---------- земля ----------

static func _ground(w: Node3D) -> void:
	# мокрая брусчатка на всей земле двора (этап 2 ТЗ: эталон парковки)
	for n in w.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh is BoxMesh and (mi.mesh as BoxMesh).size.x >= 12.0 and (mi.mesh as BoxMesh).size.y <= 1.0 \
				and mi.global_position.y <= 0.2:
			mi.material_override = Surfaces.cobble()
	# лужи: в них отражается неон
	var puddle := StandardMaterial3D.new()
	puddle.albedo_color = Color(0.16, 0.17, 0.22, 0.7)
	puddle.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puddle.metallic = 0.3
	puddle.roughness = 0.08
	for p in [Vector3(-3, 0.03, -6), Vector3(2.5, 0.03, -22), Vector3(-1.5, 0.03, -47), Vector3(4, 0.03, 6)]:
		var mi := Kit.cylinder(w, randf_range(0.9, 1.6), 0.02, p, Color.BLACK)
		mi.material_override = puddle
		mi.scale = Vector3(1.0, 1, randf_range(0.5, 0.9))
	# люки с паром
	for p in [Vector3(-2.5, 0.03, -16), Vector3(2.2, 0.03, -34), Vector3(0.5, 0.03, -58)]:
		Kit.cylinder(w, 0.45, 0.03, p, Color(0.15, 0.15, 0.16))
		particles(w, p, Color(0.75, 0.78, 0.85, 0.25), 18, 3.0, Vector3(0, 1.2, 0), 0.6, 0.9, Vector3(0.3, 0, 0.3))


# ---------- свет ----------

static func _lamps(w: Node3D) -> void:
	for z in range(0, -62, -12):
		_lamp(w, Vector3(LAMPS_LEFT_X, 0, z), 90.0, true)
		_lamp(w, Vector3(LAMPS_RIGHT_X, 0, z - 6), -90.0, false)


## Мошкара у фонарей — только на левой стороне: каждая система частиц — отдельный проход на телефоне.
static func _lamp(w: Node3D, pos: Vector3, yaw: float, bugs: bool) -> void:
	Props.collider(w, Vector3(0.3, 3, 0.3), pos + Vector3(0, 1.5, 0))
	Props.place(w, "streetlamp", pos, yaw)
	# голова фонаря в модели: 1.55 м вперёд по «лицу» и 5.7 м вверх
	var head := pos + Vector3(0, 5.5, 1.55).rotated(Vector3.UP, deg_to_rad(yaw))
	var light := OmniLight3D.new()
	light.position = head
	light.light_color = Color(1.0, 0.68, 0.36)
	light.light_energy = 2.6
	light.omni_range = 12.0
	light.omni_attenuation = 1.8
	w.add_child(light)
	if bugs:
		particles(w, head - Vector3(0, 0.6, 0), Color(1, 0.85, 0.5, 0.8), 10, 4.0, Vector3(0, 0.15, 0), 0.4, 0.05,
				Vector3(1.0, 0.8, 1.0))


static func _neon(w: Node3D) -> void:
	for n in [[Vector3(0, 22, -64), Color(1, 0.3, 0.6), 18.0, 6.0], [Vector3(11.5, 4, -22), Color(1, 0.8, 0.2), 7.0, 2.5],
			[Vector3(11.5, 6, -46), Color(0.9, 0.3, 1), 8.0, 3.0], [Vector3(-11.5, 5, -20), Color(1, 0.2, 0.6), 8.0, 3.0],
			[Vector3(-11.5, 5, 6), Color(0.3, 1, 0.8), 7.0, 2.0], [Vector3(-13, 3.5, -52), Color(0.3, 0.6, 1), 7.0, 2.5]]:
		var l := OmniLight3D.new()
		l.position = n[0]
		l.light_color = n[1]
		l.omni_range = n[2]
		l.light_energy = n[3]
		w.add_child(l)
	Signboard.make(w, "ИНТИМ 24/7", "neon", Color(1, 0.35, 0.75), Vector3(-12.95, 5.6, -20), 90.0, 0.85, {"flicker": true})
	Signboard.make(w, "теперь с щупальцами", "letters", Color(0.5, 1, 0.8), Vector3(-12.95, 4.5, -20), 90.0, 0.45,
			{"font": "script"})


static func _blink(n: Node3D) -> void:
	var tw := n.create_tween().set_loops()
	tw.tween_interval(randf_range(2.0, 5.0))
	tw.tween_property(n, "modulate:a", 0.25, 0.05)
	tw.tween_property(n, "modulate:a", 1.0, 0.05)
	tw.tween_property(n, "modulate:a", 0.4, 0.08)
	tw.tween_property(n, "modulate:a", 1.0, 0.05)


## Прожекторы тарелки шарят по улице: напоминание, что за тобой следят.
static func _ufo_searchlights(w: Node3D) -> void:
	for i in 1:                     # один прожектор: на телефоне каждый луч освещает весь двор
		var pivot := Node3D.new()
		pivot.position = Vector3(-10 + i * 20, 45, -40)
		w.add_child(pivot)
		var spot := SpotLight3D.new()
		spot.light_color = Color(0.55, 1, 0.75)
		spot.light_energy = 9.0
		spot.spot_range = 90.0
		spot.spot_angle = 7.0
		spot.rotation_degrees = Vector3(-90 + 25, 0, 0)
		pivot.add_child(spot)
		var tw := pivot.create_tween().set_loops()
		tw.tween_property(pivot, "rotation_degrees:y", 360.0 * (1 if i == 0 else -1), 26.0 + i * 7).from(i * 120.0)


# ---------- следы сюжета ----------

static func _story_traces(w: Node3D) -> void:
	# сгоревшая машина у ограждения «место посадки», угли ещё тлеют
	Props.collider(w, Vector3(2.2, 1.5, 4.4), Vector3(-3.5, 0.75, -40))
	var wreck := Props.place(w, "car_wreck", Vector3(-3.5, 0, -40), 20.0)
	if wreck:
		particles(w, Vector3(-3.5, 1.2, -40), Color(1, 0.45, 0.1, 0.9), 24, 1.6, Vector3(0, 1.8, 0), 0.5, 0.06,
				Vector3(0.8, 0.2, 1.6))
		particles(w, Vector3(-3.5, 1.6, -40), Color(0.2, 0.2, 0.22, 0.35), 14, 4.0, Vector3(0, 1.5, 0), 0.3, 1.1,
				Vector3(0.6, 0.2, 1.2))
	for x in [-6.0, -1.0]:
		Props.place(w, "barrier", Vector3(x, 0, -36.5), 0.0)
	var tape := Kit.box(w, Vector3(6.5, 0.06, 0.02), Vector3(-3.5, 0.9, -36.4), Color(1, 0.85, 0.1))
	tape.rotation_degrees.z = 2.0
	Kit.label(w, "МЕСТО ПОСАДКИ · НЕ ПЕРЕСЕКАТЬ · СТРАХОВКА НЕ ПОКРЫВАЕТ", Vector3(-3.5, 1.15, -36.3), 22,
			Color(1, 0.85, 0.1), false)
	# сбитый дрон-сборщик, ещё искрит
	Props.collider(w, Vector3(1.8, 1, 1.8), Vector3(4.5, 0.5, -17))
	if Props.place(w, "drone_wreck", Vector3(4.5, 0, -17), 40.0):
		particles(w, Vector3(4.6, 1.0, -17.3), Color(0.5, 1, 0.95, 1), 16, 0.5, Vector3(0, 2.0, 0), 1.0, 0.04,
				Vector3(0.2, 0.1, 0.2))
	_ground_text(w, "ОН ПЕРВЫЙ НАЧАЛ", Vector3(4.5, 0.04, -14.6), Color(1, 1, 1, 0.75), 40)
	# мелом: контур пришельца с антеннами и пивные банки вокруг
	_chalk_alien(w, Vector3(-2.2, 0.035, -11))
	_ground_text(w, "ГРИША. ОН БЫЛ ЗЕЛЁНЫЙ, НО НАШ", Vector3(-2.2, 0.04, -8.6), Color(1, 1, 1, 0.7), 34)
	# пришелец, привязанный к фонарю, в розовых трусах
	_tied_alien(w, Vector3(LAMPS_RIGHT_X - 0.45, 0, -30))
	# лифчик на антенне у балкона тёти Зины
	Kit.cylinder(w, 0.03, 2.4, Vector3(-12.2, 5.5, 0.4), Color(0.6, 0.6, 0.65))
	Kit.box(w, Vector3(0.04, 0.04, 1.0), Vector3(-12.2, 6.5, 0.4), Color(0.6, 0.6, 0.65))
	var bra := Props.place(w, "bra", Vector3(-12.2, 6.25, 0.6), 90.0)
	if bra:
		var tw := bra.create_tween().set_loops()
		tw.tween_property(bra, "rotation_degrees:z", 8.0, 1.3).set_trans(Tween.TRANS_SINE)
		tw.tween_property(bra, "rotation_degrees:z", -8.0, 1.3).set_trans(Tween.TRANS_SINE)
	# плакат «разыскивается» — это про героя и кабриолет
	var poster := Kit.box(w, Vector3(0.04, 1.8, 1.4), Vector3(12.95, 2.3, -3), Color(0.92, 0.88, 0.75))
	poster.rotation_degrees.y = 0.0
	var wanted := Kit.label(w, "РАЗЫСКИВАЕТСЯ\n\nугонщик кабриолета\nфлота №0001\n\nнаграда:\n3 благодарности", Vector3(12.9, 2.3, -3),
			26, Color(0.15, 0.1, 0.08), false)
	wanted.rotation_degrees.y = -90.0
	wanted.outline_size = 0
	# очередь за квартирой оставила после себя мусор
	Props.place(w, "tires", Vector3(-11.8, 0, -1.5), 30.0)
	Props.place(w, "tires", Vector3(11.8, 0, -27.5), -60.0)


static func _chalk_alien(w: Node3D, c: Vector3) -> void:
	var chalk := Color(0.95, 0.95, 0.95, 0.8)
	var lines := [[Vector3(0, 0, -1.1), 0.0, 1.4], [Vector3(-0.35, 0, -0.1), 0.0, 1.3], [Vector3(0.35, 0, -0.1), 0.0, 1.3],
			[Vector3(-0.9, 0, -0.5), 60.0, 1.1], [Vector3(0.9, 0, -0.5), -60.0, 1.1],
			[Vector3(-0.45, 0, 1.0), 20.0, 1.0], [Vector3(0.45, 0, 1.0), -20.0, 1.0],
			[Vector3(-0.3, 0, -2.2), -25.0, 0.6], [Vector3(0.3, 0, -2.2), 25.0, 0.6]]
	for l in lines:
		var b := Kit.box(w, Vector3(0.06, 0.005, l[2]), c + l[0], chalk)
		b.rotation_degrees.y = l[1]
	var head := Kit.cylinder(w, 0.45, 0.005, c + Vector3(0, 0, -1.6), chalk)
	head.scale = Vector3(1, 1, 0.8)
	Kit.cylinder(w, 0.39, 0.007, c + Vector3(0, 0.001, -1.6), Color(0.3, 0.3, 0.33)).scale = Vector3(1, 1, 0.8)
	for p in [Vector3(1.2, 0.06, 0.4), Vector3(-1.1, 0.06, 0.9), Vector3(0.7, 0.06, -1.9)]:
		Kit.cylinder(w, 0.05, 0.13, c + p, Color(0.8, 0.1, 0.12), 0.0).rotation_degrees.z = 90.0


static func _tied_alien(w: Node3D, pos: Vector3) -> void:
	var a := Node3D.new()
	a.position = pos
	a.rotation_degrees.y = -90.0
	w.add_child(a)
	Kit.capsule(a, 0.24, 0.75, Vector3(0, 0.75, 0), Color(0.56, 0.82, 0.48))
	Kit.sphere(a, 0.3, Vector3(0, 1.4, 0), Color(0.56, 0.82, 0.48))
	Kit.box(a, Vector3(0.5, 0.18, 0.32), Vector3(0, 0.48, 0), Color(1, 0.35, 0.65))  # розовые трусы
	for side in [-1, 1]:
		Kit.sphere(a, 0.09, Vector3(side * 0.11, 1.45, 0.25), Color(0.05, 0.05, 0.1))
		Kit.cylinder(a, 0.02, 0.35, Vector3(side * 0.11, 1.82, 0), Color(0.4, 0.7, 0.3))
	for y in [0.6, 0.95, 1.15]:
		Kit.cylinder(a, 0.3, 0.05, Vector3(0, y, -0.1), Color(0.75, 0.6, 0.35))  # верёвка
	Kit.box(a, Vector3(0.7, 0.4, 0.02), Vector3(0, 0.95, 0.3), Color(0.95, 0.92, 0.85))
	var sign := Kit.label(a, "НЕ КОРМИТЬ\nназвал бабу Зину\n«примитивной формой»", Vector3(0, 0.95, 0.32), 16,
			Color(0.1, 0.1, 0.1), false)
	sign.outline_size = 0
	var tw := a.create_tween().set_loops()
	tw.tween_property(a, "rotation_degrees:z", 3.0, 0.4)
	tw.tween_property(a, "rotation_degrees:z", -3.0, 0.4)


# ---------- мусор: его можно разнести ----------

static func _trash(w: Node3D) -> void:
	var spots := [["trash_bags", Vector3(-10.8, 0, -5)], ["boxes", Vector3(-10.9, 0, -19.4)], ["beer_crate", Vector3(7.6, 0, 12.4)],
			["trash_bags", Vector3(8.0, 0, -15.6)], ["boxes", Vector3(10.3, 0, -24)], ["beer_crate", Vector3(-10.2, 0, -25)],
			["trash_bags", Vector3(-10.6, 0, -33)], ["boxes", Vector3(10.6, 0, -38)], ["trash_bags", Vector3(-15, 0, -60)],
			["beer_crate", Vector3(6, 0, -58)], ["boxes", Vector3(-8.5, 0, 12.5)], ["trash_bags", Vector3(12, 0, 12)]]
	for s in spots:
		Breakable.spawn(w, s[0], s[1], randf_range(0, 360))


static func _graffiti(w: Node3D) -> void:
	for g in [["ГЛ'ОРП — ЛОХ", Vector3(-12.95, 1.6, -3.6), 90.0, Color(0.3, 1, 0.9)],
			["ПРИШЕЛЬЦЫ, ВЕРНИТЕ ПЕНСИЮ", Vector3(12.95, 1.8, -28), -90.0, Color(1, 0.85, 0.1)],
			["ВАСЯ + ЗЕЛЁНАЯ = ЛЮБОВЬ", Vector3(-12.95, 1.4, -36), 90.0, Color(1, 0.35, 0.65)],
			["Сдам почку. Свою. Недорого\n8-900-ПОЧКА-00", Vector3(12.95, 1.6, -15), -90.0, Color(0.95, 0.95, 0.95)],
			["КУПЛЮ ПОЧКУ ПРИШЕЛЬЦА · ЛЮБУЮ", Vector3(-12.95, 2.0, 11), 90.0, Color(0.95, 0.95, 0.95)],
			["ТУТ БЫЛ ВАСЯ И ПРИШЕЛЕЦ\nОБА ПЬЯНЫЕ", Vector3(-15.3, 1.2, -58), 90.0, Color(1, 0.6, 0.2)]]:
		Signboard.make(w, g[0], "graffiti", g[3], g[1] + Vector3(0.03 if g[2] > 0.0 else -0.03, 0, 0), g[2], 0.5)


static func _ground_text(w: Node3D, text: String, pos: Vector3, color: Color, size: int) -> void:
	var l := Kit.label(w, text, pos, size, color, false)
	l.rotation_degrees = Vector3(-90, 0, 0)
	l.outline_size = 0


# ---------- границы карты ----------

static func _bounds(w: Node3D) -> void:
	var r := BOUNDS
	# север — с проходом под аркой (ARCH_HALF_W): его закрывает ворота, пока двор не пройден
	var side_w := (r.size.x / 2.0 - ARCH_HALF_W)
	for wall in [[Vector3(r.position.x, 2, r.get_center().y), Vector3(1, 4, r.size.y)],
			[Vector3(r.end.x, 2, r.get_center().y), Vector3(1, 4, r.size.y)],
			[Vector3(r.position.x + side_w / 2.0, 2, r.position.y), Vector3(side_w, 4, 1)],
			[Vector3(r.end.x - side_w / 2.0, 2, r.position.y), Vector3(side_w, 4, 1)],
			[Vector3(r.get_center().x, 2, r.end.y), Vector3(r.size.x, 4, 1)]]:
		Props.collider(w, wall[1], wall[0]).set_meta("map_skip", true)
	var gate := Props.collider(w, Vector3(ARCH_HALF_W * 2.0, 4, 1), Vector3(0, 2, r.position.y))
	gate.name = "ExitGate"
	gate.set_meta("map_skip", true)
	Kit.box(gate, Vector3(ARCH_HALF_W * 2.0, 2.2, 0.08), Vector3(0, -0.9, 0), Color(0.25, 0.27, 0.3))
	for i in 9:
		Kit.box(gate, Vector3(0.06, 2.2, 0.06), Vector3(-ARCH_HALF_W + 0.6 + i * 1.1, -0.9, 0.06), Color(0.5, 0.5, 0.5))
	# просветы между домами закрыты бетонным забором (по 2.5 м)
	for gap in [[-15.6, -6.0, -3.0], [-15.6, -30.0, -26.0], [-15.6, -66.0, -46.0], [-15.6, 15.0, 19.0],
			[15.6, -11.0, -8.0], [15.6, -37.0, -33.0], [15.6, -66.0, -55.0], [15.6, 12.0, 19.0]]:
		var z: float = gap[1]
		while z < gap[2]:
			Props.place(w, "fence", Vector3(gap[0], 0, z + 1.25), 90.0)
			z += 2.5
	# дома за забором, чтобы за границей не было пустоты
	for b in [[Vector3(-25, 0, -56), Vector3(12, 15, 18), 0.0], [Vector3(25, 0, -62), Vector3(12, 24, 12), 180.0],
			[Vector3(-25, 0, 26), Vector3(12, 18, 14), 0.0], [Vector3(25, 0, 24), Vector3(12, 15, 16), 180.0],
			[Vector3(0, 0, 30), Vector3(30, 15, 10), 0.0]]:
		var size: Vector3 = b[1]
		var floors := roundi(size.y / 3.0)
		var body := Props.collider(w, size, b[0] + Vector3(0, size.y / 2, 0), true)
		if Props.place(body, "panel_%d" % floors, Vector3(0, -size.y / 2, 0), b[2],
				Vector3(size.x / 12.0, 1, size.z / 20.0)) == null:
			Kit.box(body, size, Vector3.ZERO, Color(0.5, 0.5, 0.55))


# ---------- частицы ----------

static var _dot: Texture2D


static func _soft_dot() -> Texture2D:
	if _dot == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 32
		t.height = 32
		_dot = t
	return _dot

## Простые светящиеся частицы: пар, искры, пыль у фонарей, угли.
static func particles(w: Node3D, pos: Vector3, color: Color, amount: int, lifetime: float, velocity: Vector3,
		spread: float, size: float, box := Vector3(0.2, 0.2, 0.2)) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.position = pos
	p.amount = amount
	p.lifetime = lifetime
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = box
	m.direction = velocity.normalized() if velocity.length() > 0.0 else Vector3.UP
	m.initial_velocity_min = velocity.length() * 0.6
	m.initial_velocity_max = velocity.length() * 1.2
	m.spread = spread * 90.0
	m.gravity = Vector3.ZERO
	m.scale_min = 0.6
	m.scale_max = 1.2
	var fade := Gradient.new()
	fade.set_color(0, color)
	fade.set_color(1, Color(color, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = fade
	m.color_ramp = ramp
	p.process_material = m
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color(1, 1, 1)
	mat.albedo_texture = _soft_dot()
	q.material = mat
	p.draw_pass_1 = q
	p.visibility_aabb = AABB(Vector3(-4, -2, -4), Vector3(8, 8, 8))
	w.add_child(p)
	return p
