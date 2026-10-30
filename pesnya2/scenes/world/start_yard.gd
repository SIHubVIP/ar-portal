class_name StartYard
extends RefCounted
## Двор «Похмельная» по макету «Рубин» (площадка PG_C1_core_start, 0.11, D-051): старт MAIN_001.
## Размеры и места — из пакета (data/pogulyay_layout.json → sites.start): два пятиэтажных
## кирпичных корпуса на севере и кирпичная арка между ними, штукатурный дом на западе, ряд из
## двенадцати гаражей на востоке, парковка 86 × 62 м с чужим бирюзовым кабриолетом, разбитый
## киоск «НЛО напрокат», шлагбаум с будкой «Парковка платная. Сон тоже», аллея деревьев и
## скамеек, технический слив вдоль гаражей. Облик — по концептам PG_C1_start_art и 01_start:
## осень, тёплые окна, площадка, мусорки, бельё, следы вчерашней ночи.
## Мировые координаты = план − District.SOURCE_ORIGIN_M (360, 2690). Выходы — арка на севере и проход
## южнее гаражей на востоке; до конца MAIN_001 оба закрыты воротами.

const COURT := Rect2(-92, -140, 184, 190)
const BOUNDS := Rect2(-91, -131, 183, 181)
const ARCH_HALF_W := 3.5
const EXIT_ARCH := Vector3(0, 0, -131)
const EAST_GAP := Vector2(22, 48)
const KIOSK := Vector3(42, 0, -20)
const PAVEL := Vector3(36, 0, -11)
const BOOTH := Vector3(27, 0, 17)
const BARRIER := Vector3(20, 0, 14)
const GARAGE_13 := Vector3(91.5, 0, -51)
const QUEUE := Vector3(-86, 0, -66)
const ZINA_BALCONY := Vector3(-90.2, 3.2, -78)
const DRAIN_X := Vector2(72, 74)
const NEON_PINK := Color(1.0, 0.3, 0.75)
const NEON_WARM := Color(1.0, 0.78, 0.4)
const LAMPS_KEY := Vector2i(-99, -99)

static var _site: Dictionary = {}
static var _extra_lamps := PackedVector3Array()
static var _parked: Dictionary = {}          # сетка машины → её места
static var _yb: DistrictDressing.Batch       # общий пакет двора: машины, кусты, деревья — несколько MultiMesh


static func build(w: Node3D) -> void:
	_site = District.site("start")
	_extra_lamps = PackedVector3Array()
	_yb = DistrictDressing.Batch.new()
	_ground(w)
	_houses(w)
	_arch(w)
	_garages(w)
	_lot(w)
	_kiosk(w)
	_booth(w)
	_drain(w)
	_yard_life(w)
	_lot_details(w)
	_courtyard(w)
	_story(w)
	_walls_talk(w)
	_trash(w)
	_bounds(w)


## Открыть выходы со двора: ворота уезжают вверх, коллизия снимается.
static func open_exit(w: Node3D, instant := false) -> void:
	for name in ["ExitGate", "ExitGateEast"]:
		var gate := w.get_node_or_null(name) as StaticBody3D
		if gate == null or gate.has_meta("opened"):
			continue
		gate.set_meta("opened", true)
		gate.collision_layer = 0
		if instant:
			gate.position.y += 4.5
		else:
			gate.create_tween().tween_property(gate, "position:y", gate.position.y + 4.5, 1.2)


## Точка двора из исходных метров «Рубин» в мир (окно двора — чистый сдвиг, D-059).
static func _sw(p: Vector2, h := 0.0) -> Vector3:
	return District.site_to_world(_site, p, h)


static func _o(name: String) -> Dictionary:
	return DistrictSites._o(_site, name)


## Прямоугольник объекта пакета в мировых координатах (x, z).
static func _wr(name: String) -> Rect2:
	var r := DistrictSites._r(_o(name))
	var p := _sw(r.position)
	return Rect2(Vector2(p.x, p.z), r.size)


static func _c3(r: Rect2, y := 0.0) -> Vector3:
	return Vector3(r.get_center().x, y, r.get_center().y)


static func _sign(w: Node3D, text: String, pos: Vector3, yaw_deg: float, height: float, color: Color, kind := "neon",
		opts := {}) -> Signboard:
	return Signboard.make(w, text, kind, color, pos, yaw_deg, height, opts)


# ---------- земля ----------

static func _ground(w: Node3D) -> void:
	# мощение двора: плитка, по ней — асфальт парковки; земля под деревьями
	var court := Kit.box(w, Vector3(COURT.size.x, 0.06, COURT.size.y), _c3(COURT, 0.03), Color.WHITE)
	court.material_override = Surfaces.ground("slabs", 2.0, Color(1.02, 0.94, 0.84), Color(0.8, 0.95, 0.7), 0.5, 0.6,
			[Color(1.1, 1.05, 0.92), Color(0.78, 0.86, 0.84), 0.8])     # 0.18: рисованная плитка, мох и тени пятнами
	court.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	court.set_meta("map_skip", true)
	var lawn := Kit.box(w, Vector3(150, 0.07, 26), Vector3(-2, 0.035, -100), Color.WHITE)
	lawn.material_override = Surfaces.ground("dirt", 4.0, Color(1.32, 1.8, 1.05), Color(1.25, 0.69, 1.33), 0.45, 0.35,
			[Color(1.2, 1.14, 0.84), Color(0.74, 0.86, 0.9), 0.9])       # 0.18: сочный газон, как в районе
	lawn.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lawn.set_meta("map_skip", true)
	# листья россыпью по всему двору
	var rng := RandomNumberGenerator.new()
	rng.seed = 2640
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var q := BoxMesh.new()
	q.size = Vector3(1, 0.02, 1)
	mm.mesh = q
	mm.instance_count = 2400
	for i in mm.instance_count:
		var p := Vector3(rng.randf_range(COURT.position.x + 2, COURT.end.x - 2), 0.07, rng.randf_range(COURT.position.y + 4, COURT.end.y - 2))
		mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, rng.randf() * TAU) * Basis.from_scale(Vector3(rng.randf_range(0.18, 0.42), 1,
				rng.randf_range(0.12, 0.3))), p))
		mm.set_instance_color(i, DistrictDressing.AUTUMN[rng.randi() % DistrictDressing.AUTUMN.size()].darkened(rng.randf() * 0.25))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = DistrictDressing._material("plain")
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.set_meta("map_skip", true)
	w.add_child(mmi)


# ---------- дома ----------

static func _house(w: Node3D, r: Rect2, floors: int, brick: bool, seed_: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	var at := _c3(r)
	var built := BuildingKit.house(r.size.x, r.size.y, floors, at, brick, rng)
	var h := floors * BuildingKit.FLOOR_M + 0.4
	var body := Props.collider(w, Vector3(r.size.x, h, r.size.y), at + Vector3(0, h / 2.0, 0), true)
	var mi := MeshInstance3D.new()
	mi.mesh = built.mesh
	mi.position = Vector3(0, -h / 2.0, 0)
	body.add_child(mi)
	return built


static func _houses(w: Node3D) -> void:
	var nw := _house(w, _wr("PG_C1_north_wing_w"), 5, true, 2541)
	var ne := _house(w, _wr("PG_C1_north_wing_e"), 5, true, 2542)
	var west := _house(w, _wr("PG_C1_west_block"), 5, false, 2565)
	for e: Vector3 in nw.entrances + ne.entrances + west.entrances:
		_extra_lamps.append(e + Vector3(0, 2.4, 0))
	# неоновая планета и вывески на корпусах, как на концепте
	var wb := _wr("PG_C1_west_block")
	var face_x := wb.end.x + 0.05
	_sign(w, "ИНТИМ 24/7", Vector3(face_x, 7.6, -100), 90.0, 0.85, NEON_PINK, "neon", {"flicker": true})
	_sign(w, "теперь с щупальцами", Vector3(face_x, 6.6, -100), 90.0, 0.42, Color(0.5, 1, 0.8), "letters", {"font": "script"})
	_sign(w, "КЛАНЯЙТЕСЬ ТАРЕЛКЕ —\nЭТО БЕСПЛАТНО*", Vector3(face_x, 11.0, -60), 90.0, 0.8, Color.WHITE, "lightbox",
			{"bg": Color(0.25, 0.55, 0.95), "ink": Color(1, 1, 1)})
	_sign(w, "*при наличии согласия", Vector3(face_x, 9.4, -60), 90.0, 0.32, Color(0.1, 0.12, 0.2), "board",
			{"bg": Color(0.85, 0.88, 0.95)})
	var n_w := _wr("PG_C1_north_wing_w")
	_sign(w, "ЛОМБАРД\n«ВЕЧНОСТЬ»", Vector3(n_w.get_center().x - 22, 4.4, n_w.end.y + 0.05), 0.0, 0.7, Color(0.3, 1, 0.8), "neon",
			{"flicker": true})
	var n_e := _wr("PG_C1_north_wing_e")
	_sign(w, "ШАУРМА 24\nДАЖЕ ПОСЛЕ КОНЦА СВЕТА", Vector3(n_e.get_center().x + 20, 4.2, n_e.end.y + 0.05), 0.0, 0.5, Color.WHITE,
			"lightbox", {"bg": Color(1.0, 0.82, 0.25), "ink": Color(0.6, 0.08, 0.05)})
	_sign(w, "КЛУБ\n«ТРИДЦАТЬ ЛАЙКОВ»", Vector3(n_e.end.x - 8, 7.5, n_e.end.y + 0.05), 0.0, 0.7, Color(0.9, 0.3, 1), "neon",
			{"flicker": true})


## Арка между северными корпусами: кирпичные пилоны, дом над проходом, ворота.
static func _arch(w: Node3D) -> void:
	var l := _wr("PG_C1_arch_l")
	var r := _wr("PG_C1_arch_r")
	var x0 := l.position.x
	var x1 := r.end.x
	var z0 := l.position.y
	var depth := l.size.y
	var h := 15.4
	var brick := BuildingKit.BRICK[1]
	for side: float in [-1.0, 1.0]:
		var px := (x0 + (-ARCH_HALF_W)) / 2.0 if side < 0.0 else (ARCH_HALF_W + x1) / 2.0
		var pw := (-ARCH_HALF_W - x0) if side < 0.0 else (x1 - ARCH_HALF_W)
		var body := Props.collider(w, Vector3(pw, h, depth), Vector3(px, h / 2.0, z0 + depth / 2.0), true)
		var mi := MeshInstance3D.new()
		mi.mesh = BuildingKit.block(pw, depth, h, true, brick, Color(0.32, 0.3, 0.28))
		mi.position = Vector3(0, -h / 2.0, 0)
		body.add_child(mi)
	var top_h := h - 5.2
	var top := Props.collider(w, Vector3(ARCH_HALF_W * 2.0, top_h, depth), Vector3(0, 5.2 + top_h / 2.0, z0 + depth / 2.0), true)
	var tm := MeshInstance3D.new()
	tm.mesh = BuildingKit.block(ARCH_HALF_W * 2.0, depth, top_h, true, brick, Color(0.32, 0.3, 0.28))
	tm.position = Vector3(0, -top_h / 2.0, 0)
	top.add_child(tm)
	# тёмный свод и мостовая в проезде, кирпичная рамка арки с фонарём
	Kit.box(w, Vector3(ARCH_HALF_W * 2.0, 0.2, depth), Vector3(0, 5.1, z0 + depth / 2.0), Color(0.18, 0.15, 0.13))
	var tunnel := Kit.box(w, Vector3(ARCH_HALF_W * 2.0, 0.07, depth + 4), Vector3(0, 0.035, z0 + depth / 2.0), Color.WHITE)
	tunnel.material_override = Surfaces.cobble()
	var frame := Props.place(w, "brick_arch", Vector3(0, 0, EXIT_ARCH.z + 0.3), 0.0)
	if frame:
		Surfaces.retexture(frame)
	_sign(w, "ПОГУЛЯЙ", Vector3(0, 13.2, EXIT_ARCH.z + 0.1), 0.0, 2.4, Color(1, 0.3, 0.6), "letters")
	var lamp := OmniLight3D.new()
	lamp.position = EXIT_ARCH + Vector3(0, 4.6, 2.0)
	lamp.light_color = NEON_WARM
	lamp.light_energy = 2.2
	lamp.omni_range = 9.0
	w.add_child(lamp)


# ---------- гаражи ----------

static func _garages(w: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 454
	var doors := [Color(0.3, 0.42, 0.34), Color(0.55, 0.32, 0.2), Color(0.35, 0.38, 0.5), Color(0.6, 0.55, 0.3),
		Color(0.45, 0.45, 0.47)]
	for i in 12:
		var r := _wr("PG_C1_garage_%d" % i)
		var c := _c3(r)
		var body := Props.collider(w, Vector3(r.size.x, 3.0, r.size.y), c + Vector3(0, 1.5, 0))
		Kit.box(body, Vector3(r.size.x, 3.0, r.size.y), Vector3.ZERO, Color(0.5, 0.47, 0.43).lerp(Color(0.55, 0.36, 0.26), rng.randf() * 0.5))
		Kit.box(body, Vector3(r.size.x + 0.6, 0.25, r.size.y + 0.3), Vector3(0.3, 1.6, 0), Color(0.42, 0.26, 0.18))
		# по двое ворот к двору (запад)
		var front_x := r.position.x - 0.03
		for k in 2:
			var dz := (k - 0.5) * r.size.y / 2.0
			var col: Color = doors[rng.randi() % doors.size()]
			if i == 6 and k == 0:
				col = Color(0.85, 0.6, 0.15)
			Kit.box(w, Vector3(0.08, 2.3, r.size.y / 2.0 - 0.8), Vector3(front_x, 1.15, c.z + dz), col)
		if rng.randf() < 0.5:
			Signboard.make(w, DistrictDressing.GRAFFITI[rng.randi() % DistrictDressing.GRAFFITI.size()], "graffiti",
					DistrictDressing.GRAFFITI_COLORS[rng.randi() % DistrictDressing.GRAFFITI_COLORS.size()],
					Vector3(front_x - 0.03, 2.6, c.z), -90.0, 0.35, {"far": DistrictDressing.SIGN_FAR_M})
		if rng.randf() < 0.6:
			Props.place(w, "tires", Vector3(front_x - 1.4, 0, c.z + rng.randf_range(-3, 3)), rng.randf() * 360.0)
	Signboard.make(w, "ГАРАЖ №13", "board", Color(0.1, 0.08, 0.05), GARAGE_13 + Vector3(2.4, 2.8, 2.2), -90.0, 0.4,
			{"bg": Color(1.0, 0.8, 0.3), "lamp": true})
	# гаражный кооператив «Чек энджин» — вывеска над рядом
	Signboard.make(w, "ГСК «ЧЕК ЭНДЖИН»", "letters", Color(1.0, 0.55, 0.2), Vector3(93.5, 4.4, -100), -90.0, 0.9)


# ---------- парковка ----------

static func _lot(w: Node3D) -> void:
	var lot := DistrictSites._r(_o("PG_C1_parking"))
	var p := _sw(lot.position)
	var r := Rect2(Vector2(p.x, p.z), lot.size)
	var asphalt := Kit.box(w, Vector3(r.size.x, 0.05, r.size.y), _c3(r, 0.06), Color.WHITE)
	asphalt.material_override = Surfaces.ground("asphalt", 4.0, Color(1.6, 1.6, 1.72), Color(0.8, 0.8, 0.84), 0.5, 0.35,
			[Color(1.08, 1.06, 1.02), Color(0.84, 0.88, 0.94), 0.7])
	asphalt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	asphalt.set_meta("map_skip", true)
	# места по 2,8 м вдоль северного и южного края, бордюр по периметру
	var x := r.position.x + 1.0
	while x <= r.end.x - 1.0:
		Kit.box(w, Vector3(0.14, 0.02, 5.0), Vector3(x, 0.095, r.position.y + 2.6), Color(0.92, 0.9, 0.84))
		Kit.box(w, Vector3(0.14, 0.02, 5.0), Vector3(x, 0.095, r.end.y - 2.6), Color(0.92, 0.9, 0.84))
		x += 2.8
	for side: float in [-1.0, 1.0]:
		Kit.box(w, Vector3(r.size.x, 0.18, 0.25), Vector3(r.get_center().x, 0.09, r.get_center().y + side * r.size.y / 2.0),
				Color(0.55, 0.54, 0.52))
		Kit.box(w, Vector3(0.25, 0.18, r.size.y), Vector3(r.get_center().x + side * r.size.x / 2.0, 0.09, r.get_center().y),
				Color(0.55, 0.54, 0.52))
	var label := Kit.label(w, "ПАРКОВКА «ПОХМЕЛЬНАЯ»", Vector3(r.get_center().x, 0.1, r.end.y - 9), 90, Color(1, 1, 1, 0.45), false)
	label.rotation_degrees = Vector3(-90, 0, 0)
	label.outline_size = 0
	# машины пакета (кроме кабриолета — его ставит сцена) и ещё пара у бордюра
	var rng := RandomNumberGenerator.new()
	rng.seed = 2672
	var cars := [Color(0.9, 0.88, 0.82), Color(0.25, 0.32, 0.5), Color(0.55, 0.2, 0.16), Color(0.4, 0.42, 0.36),
		Color(0.75, 0.62, 0.3), Color(0.3, 0.45, 0.42)]
	var i := 0
	for o in DistrictSites._all(_site, "PG_C1_car"):
		if String(o.name) != "PG_C1_car":
			continue
		var cr := DistrictSites._r(o)
		_car(w, _sw(cr.get_center()), PI / 2.0 + rng.randf_range(-0.25, 0.25), cars[i % cars.size()])
		i += 1
	# места вдоль краёв заняты наполовину; у кабриолета и находок — пусто
	var slot := r.position.x + 2.4
	while slot < r.end.x - 2.0:
		for row: float in [r.position.y + 2.6, r.end.y - 2.6]:
			var near_story := row > r.get_center().y and slot > -62.0 and slot < -34.0
			if not near_story and rng.randf() < 0.55:
				_car(w, Vector3(slot, 0, row), rng.randf_range(-0.1, 0.1) + (PI if rng.randf() < 0.5 else 0.0),
						cars[rng.randi() % cars.size()])
		slot += 2.8
	_flush_cars(w)
	# кусты и деревья по краю парковки, как на концепте: осенние клумбы за бордюром
	for t in range(0, int(r.size.x), 3):
		if rng.randf() < 0.8:
			_bush(Vector3(r.position.x + t + rng.randf(), 0, r.position.y - 1.6), rng)
	for t in range(4, int(r.size.y) - 4, 3):
		if rng.randf() < 0.8:
			_bush(Vector3(r.position.x - 1.6, 0, r.position.y + t + rng.randf()), rng)
	for c: Vector3 in [Vector3(r.position.x - 4, 0, r.position.y - 4), Vector3(r.end.x + 4, 0, r.position.y - 4),
			Vector3(r.position.x - 4, 0, r.get_center().y), Vector3(r.get_center().x, 0, r.position.y - 5)]:
		DistrictDressing._tree(_yb, c, rng, 1.3)


## Куст у парковки (0.18): общий рисованный куст района, иногда с цветами.
static func _bush(at: Vector3, rng: RandomNumberGenerator) -> void:
	DistrictDressing._bush(_yb, at, rng, rng.randf_range(0.8, 1.2))


## Машина двора (CarKit): тело — коллизия, сетка копится по цвету и виду, после парковки
## каждая группа — один MultiMesh с тенью.
static func _car(w: Node3D, pos: Vector3, yaw: float, color: Color) -> void:
	var car := Props.collider(w, Vector3(1.9, 1.4, 4.3), pos + Vector3(0, 0.7, 0))
	car.rotation.y = yaw
	var mesh := CarKit.mesh(color, false, (_parked.size() * 7) % 3)
	if not _parked.has(mesh):
		_parked[mesh] = []
	_parked[mesh].append(Transform3D(Basis(Vector3.UP, yaw), pos))


static func _flush_cars(w: Node3D) -> void:
	for mesh: Mesh in _parked:
		var list: Array = _parked[mesh]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = list.size()
		for i in list.size():
			mm.set_instance_transform(i, list[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		w.add_child(mmi)
	_parked.clear()


# ---------- киоск «НЛО напрокат» и будка ----------

static func _kiosk(w: Node3D) -> void:
	Props.collider(w, Vector3(8, 3.0, 6), KIOSK + Vector3(0, 1.5, 0))
	if Props.place(w, "ufo_kiosk", KIOSK, 0.0) == null:
		Kit.box(w, Vector3(8, 3, 6), KIOSK + Vector3(0, 1.5, 0), Color(0.2, 0.45, 0.45))
	_sign(w, "НЛО\nНАПРОКАТ", KIOSK + Vector3(0.3, 3.2, 1.6), 0.0, 0.52, NEON_PINK, "neon", {"icon": "ufo", "flicker": true})
	_sign(w, "КИОСК 24/7 · РАССРОЧКА НА ВСЁ", KIOSK + Vector3(0, 2.3, 1.62), 0.0, 0.3, Color.WHITE, "lightbox",
			{"bg": Color(0.95, 0.25, 0.2), "ink": Color(1, 1, 0.9)})
	var l := OmniLight3D.new()
	l.position = KIOSK + Vector3(0, 3.0, 2.2)
	l.light_color = Color(1.0, 0.5, 0.8)
	l.light_energy = 2.2
	l.omni_range = 7.0
	w.add_child(l)
	# разгром у киоска: опрокинутая витрина, коробки, провода
	for k in 4:
		Props.place(w, ["boxes", "beer_crate", "trash_bags", "boxes"][k], KIOSK + Vector3(-4.0 + k * 2.2, 0, 3.6 + (k % 2)), k * 47.0)
	Kit.box(w, Vector3(2.6, 0.08, 1.6), KIOSK + Vector3(3.5, 0.3, 3.2), Color(0.55, 0.7, 0.8, 0.6)).rotation_degrees.z = 14.0


static func _booth(w: Node3D) -> void:
	var yaw := 0.0
	Props.collider(w, Vector3(3.4, 2.8, 2.4), BOOTH + Vector3(0, 1.4, 0))
	Props.place(w, "parking_booth", BOOTH, yaw)
	_sign(w, "ПАРКОВКА\nПЛАТНАЯ.\nСОН ТОЖЕ.", BOOTH + Vector3(0, 2.0, 1.45), yaw, 0.42, Color(0.1, 0.08, 0.06), "lightbox",
			{"bg": Color(1.0, 0.92, 0.78), "ink": Color(0.1, 0.08, 0.06)})
	_sign(w, "P", BOOTH + Vector3(-2.6, 2.1, 0.8), yaw, 0.6, Color.WHITE, "board", {"bg": Color(0.1, 0.3, 0.75)})
	Kit.box(w, Vector3(0.1, 2.0, 0.1), BOOTH + Vector3(-2.6, 1.0, 0.75), Color(0.3, 0.3, 0.32))
	_sign(w, "ПОГУЛЯЙ\nНЕ СПИТ", BOOTH + Vector3(1.75, 1.3, 0), 90.0, 0.4, Color(0.95, 0.95, 0.95), "graffiti")
	var lamp := OmniLight3D.new()
	lamp.position = BOOTH + Vector3(1.3, 3.6, 1.7)
	lamp.light_color = NEON_WARM
	lamp.light_energy = 1.4
	lamp.omni_range = 6.0
	w.add_child(lamp)
	Props.collider(w, Vector3(0.5, 1.2, 0.5), BARRIER + Vector3(0, 0.6, 0))
	Props.place(w, "boom_gate", BARRIER, 0.0)
	for k in 3:
		Props.place(w, "barrier", BARRIER + Vector3(-3.0 - k * 1.4, 0, 1.0), 0.0)
	# таксомотор у будки — кто-то ждёт, кто-то спит
	Props.collider(w, Vector3(1.8, 1.4, 4.3), BOOTH + Vector3(7.5, 0.7, 2))
	Props.place(w, "taxi", BOOTH + Vector3(7.5, 0, 2), 180.0)
	var pole := BOOTH + Vector3(10, 0, 4.6)
	Props.place(w, "taxi_sign", pole, 0.0)
	_sign(w, "ТАКСИ", pole + Vector3(0, 2.62, 0.09), 0.0, 0.27, Color(0.1, 0.08, 0.05), "board", {"bg": Color(0.98, 0.8, 0.15)})


# ---------- слив вдоль гаражей ----------

static func _drain(w: Node3D) -> void:
	var o := DistrictSites._r(_o("PG_C1_drain_channel"))
	var p := _sw(o.position)
	var len_z := o.size.y
	var cx := p.x + o.size.x / 2.0
	var cz := p.z + len_z / 2.0
	var water := Kit.box(w, Vector3(1.6, 0.03, len_z), Vector3(cx, 0.03, cz), Color(0.12, 0.16, 0.16))
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.16, 0.16)
	mat.roughness = 0.1
	mat.metallic_specular = 0.8
	water.material_override = mat
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for side: float in [-1.0, 1.0]:
		Kit.box(w, Vector3(0.3, 0.3, len_z), Vector3(cx + side * 1.0, 0.15, cz), Color(0.48, 0.47, 0.45))
	Props.collider(w, Vector3(2.4, 1.0, len_z), Vector3(cx, 0.5, cz))
	var z := p.z + 6.0
	while z < p.z + len_z:
		Kit.box(w, Vector3(2.0, 0.04, 0.6), Vector3(cx, 0.32, z), Color(0.15, 0.15, 0.16))   # мостики-решётки
		z += 24.0
	Kit.particles(w, Vector3(cx, 0.4, p.z + 3.0), Color(0.75, 0.85, 0.95, 0.35), 14, 1.2, Vector3(0, 0.8, 0), 0.6, 0.3,
			Vector3(0.5, 0.05, 0.5))


# ---------- двор: деревья, скамейки, площадка, мусорки, бельё ----------

## Середина двора (0.12): хоккейная коробка, клумбы из крашеных шин, выбивалка с ковром,
## доминошный стол с мужиками, бетонный теннисный стол, бабушки на лавках у подъездов.
static func _yard_life(w: Node3D) -> void:
	var b := _yb
	var rng := RandomNumberGenerator.new()
	rng.seed = 2612
	# коробка 30 × 15 м: борта с калиткой, зелёное поле, ворота, разметка
	var box := Vector3(28, 0, -70)
	DistrictSites._b(b, box + Vector3(0, 0.05, 0), Vector3(30, 0.06, 15), Color(0.24, 0.38, 0.3))
	for side: float in [-1.0, 1.0]:
		DistrictSites._b(b, box + Vector3(0, 0.6, side * 7.5), Vector3(30, 1.1, 0.12), Color(0.9, 0.9, 0.86))
		DistrictSites._b(b, box + Vector3(0, 1.1, side * 7.5), Vector3(30, 0.1, 0.16), Color(0.25, 0.4, 0.75))
		DistrictSites._b(b, box + Vector3(side * 15, 0.6, side * 2.0), Vector3(0.12, 1.1, 11), Color(0.9, 0.9, 0.86))
		Props.collider(w, Vector3(30, 1.2, 0.2), box + Vector3(0, 0.6, side * 7.5))
		Props.collider(w, Vector3(0.2, 1.2, 11), box + Vector3(side * 15, 0.6, side * 2.0))
		# ворота: рама с сеткой
		var g := box + Vector3(side * 13.2, 0, 0)
		DistrictSites._b(b, g + Vector3(0, 0.6, -1.0), Vector3(0.08, 1.2, 0.08), Color(0.85, 0.15, 0.12))
		DistrictSites._b(b, g + Vector3(0, 0.6, 1.0), Vector3(0.08, 1.2, 0.08), Color(0.85, 0.15, 0.12))
		DistrictSites._b(b, g + Vector3(0, 1.2, 0), Vector3(0.08, 0.08, 2.0), Color(0.85, 0.15, 0.12))
		DistrictSites._b(b, g + Vector3(side * 0.5, 0.6, 0), Vector3(0.02, 1.1, 1.9), Color(0.85, 0.85, 0.85, 1.0))
		DistrictSites._b(b, box + Vector3(side * 7.5, 0.09, 0), Vector3(0.25, 0.01, 15), Color(0.85, 0.3, 0.3), 0.0, "paint")
	DistrictSites._b(b, box + Vector3(0, 0.09, 0), Vector3(0.25, 0.01, 15), Color(0.85, 0.3, 0.3), 0.0, "paint")
	_sign(w, "ХОККЕЙ ПО ТАЛОНАМ", box + Vector3(0, 1.9, 7.6), 0.0, 0.45, Color(0.15, 0.2, 0.4), "board",
			{"bg": Color(0.95, 0.95, 0.9)})
	for k in 4:
		DistrictSites._person(w, box + Vector3(-8 + k * 5.0, 0, rng.randf_range(-3, 3)), rng.randf() * TAU, rng)
	# клумбы из шин, крашеных в цвета светофора и чужого флага
	var tyre_cols := [Color(0.95, 0.85, 0.2), Color(0.9, 0.25, 0.2), Color(0.25, 0.55, 0.9), Color(0.95, 0.95, 0.92),
		Color(0.4, 0.85, 0.5)]
	for row in 3:
		var at := Vector3(-14 + row * 8.0, 0, -58)
		for k in 6:
			var p := at + Vector3(cos(TAU * k / 6.0) * 1.6, 0, sin(TAU * k / 6.0) * 1.6)
			b.add("tank", Transform3D(Basis().scaled(Vector3(0.9, 0.32, 0.9)), p + Vector3(0, 0.16, 0)), tyre_cols[(k + row) % tyre_cols.size()])
			b.add("veg", Transform3D(Basis().scaled(Vector3.ONE * 0.55), p + Vector3(0, 0.45, 0)),
					[Color(0.95, 0.4, 0.3), Color(0.98, 0.8, 0.25), Color(0.75, 0.4, 0.9)][(k + row) % 3])
		b.add("tank", Transform3D(Basis().scaled(Vector3(1.6, 0.5, 1.6)), at + Vector3(0, 0.25, 0)), tyre_cols[row])
		b.add("veg", Transform3D(Basis().scaled(Vector3(1.0, 0.9, 1.0)), at + Vector3(0, 0.8, 0)), Color(0.85, 0.35, 0.2))
	# выбивалка: П-образная труба и ковёр с узором, рядом таз
	var beat := Vector3(55, 0, -96)
	for sx: float in [-1.0, 1.0]:
		DistrictSites._b(b, beat + Vector3(sx * 2.0, 1.1, 0), Vector3(0.08, 2.2, 0.08), Color(0.3, 0.32, 0.35))
	DistrictSites._b(b, beat + Vector3(0, 2.2, 0), Vector3(4.1, 0.08, 0.08), Color(0.3, 0.32, 0.35))
	DistrictSites._b(b, beat + Vector3(0, 1.45, 0.04), Vector3(2.6, 1.5, 0.04), Color(0.62, 0.12, 0.12))
	DistrictSites._b(b, beat + Vector3(0, 1.45, 0.07), Vector3(1.8, 1.0, 0.02), Color(0.12, 0.2, 0.45))
	DistrictSites._b(b, beat + Vector3(0, 1.45, 0.09), Vector3(0.8, 0.5, 0.02), Color(0.92, 0.8, 0.35))
	Props.collider(w, Vector3(4.2, 2.3, 0.3), beat + Vector3(0, 1.15, 0))
	DistrictSites._person(w, beat + Vector3(0.6, 0, 1.4), PI, rng, {"skirt": true, "style": "bun"})
	# доминошный стол под деревом: «рыба!»
	var dom := Vector3(-22, 0, -72)
	DistrictDressing._tree(b, dom + Vector3(3.5, 0, -3.0), rng, 1.8)
	DistrictSites._b(b, dom + Vector3(0, 0.75, 0), Vector3(2.2, 0.08, 1.2), Color(0.45, 0.3, 0.18))
	DistrictSites._b(b, dom + Vector3(0, 0.37, 0), Vector3(0.15, 0.75, 0.15), Color(0.3, 0.3, 0.32))
	for k in 6:
		DistrictSites._b(b, dom + Vector3(-0.8 + k * 0.3, 0.8, rng.randf_range(-0.3, 0.3)), Vector3(0.1, 0.02, 0.2), Color(0.95, 0.95, 0.9),
				rng.randf() * PI)
	for side: float in [-1.0, 1.0]:
		DistrictSites._b(b, dom + Vector3(0, 0.45, side * 1.2), Vector3(2.4, 0.08, 0.4), Color(0.5, 0.34, 0.2))
		DistrictSites._person(w, dom + Vector3(-0.5, 0, side * 1.25), PI if side > 0 else 0.0, rng, {"skirt": false, "style": "bald"})
		DistrictSites._person(w, dom + Vector3(0.6, 0, side * 1.25), PI if side > 0 else 0.0, rng, {"skirt": false})
	Props.collider(w, Vector3(2.4, 0.9, 3.0), dom + Vector3(0, 0.45, 0))
	_sign(w, "КТО ЗАБИЛ — ТОТ И ПРАВ", dom + Vector3(0, 2.2, -1.6), 0.0, 0.32, Color(0.95, 0.9, 0.8), "board",
			{"bg": Color(0.25, 0.3, 0.25)})
	# теннисный стол из бетона: сетка — стальной лист
	var tt := Vector3(58, 0, -45)
	DistrictSites._b(b, tt + Vector3(0, 0.76, 0), Vector3(1.5, 0.1, 2.7), Color(0.25, 0.45, 0.35))
	DistrictSites._b(b, tt + Vector3(0, 0.38, 0), Vector3(0.4, 0.76, 1.6), Color(0.6, 0.58, 0.55))
	DistrictSites._b(b, tt + Vector3(0, 0.93, 0), Vector3(1.6, 0.2, 0.03), Color(0.5, 0.52, 0.55))
	DistrictSites._b(b, tt + Vector3(0, 0.815, 0), Vector3(0.03, 0.01, 2.7), Color(0.95, 0.95, 0.95), 0.0, "paint")
	Props.collider(w, Vector3(1.6, 1.0, 2.8), tt + Vector3(0, 0.5, 0))
	# бабушки на лавках у подъездов северных корпусов
	for e: Vector3 in _extra_lamps.slice(0, 4):
		var p := e - Vector3(0, 2.4, 0) + Vector3(2.8, 0, 2.2)
		b.model("bench", p, PI)
		Props.collider(w, Vector3(2.4, 0.5, 0.7), p + Vector3(0, 0.25, 0))
		for k in 2:
			DistrictSites._person(w, p + Vector3(-0.5 + k * 1.0, 0, 0.2), PI, rng, {"skirt": true, "style": "bun",
					"hair": Color(0.85, 0.85, 0.82)})


## Мелочи у парковки (0.13, концепт 01_start): столбики вдоль восточного края, паркомат,
## инспектор-пришелец в жилетке с ховербайком, ящики и шины у киоска.
static func _lot_details(w: Node3D) -> void:
	var b := _yb
	var lot := DistrictSites._r(_o("PG_C1_parking"))
	var east := lot.end.x - District.SOURCE_ORIGIN_M.x + 1.0
	var z := lot.position.y - District.SOURCE_ORIGIN_M.y + 3.0
	while z < lot.end.y - District.SOURCE_ORIGIN_M.y - 4.0:
		var p := Vector3(east, 0, z)
		DistrictSites._b(b, p + Vector3(0, 0.45, 0), Vector3(0.22, 0.9, 0.22), Color(0.2, 0.2, 0.22))
		DistrictSites._b(b, p + Vector3(0, 0.75, 0), Vector3(0.24, 0.12, 0.24), Color(0.95, 0.8, 0.15))
		Props.collider(w, Vector3(0.24, 0.9, 0.24), p + Vector3(0, 0.45, 0))
		z += 3.2
	# паркомат: серый столб с экраном, жёлтая наклейка «оплата снами»
	var meter := BOOTH + Vector3(-4.2, 0, 2.2)
	DistrictSites._b(b, meter + Vector3(0, 0.75, 0), Vector3(0.35, 1.5, 0.3), Color(0.55, 0.58, 0.6))
	DistrictSites._b(b, meter + Vector3(0, 1.2, 0.16), Vector3(0.22, 0.16, 0.02), Color(0.3, 0.9, 0.6), 0.0, "glow")
	DistrictSites._b(b, meter + Vector3(0, 0.85, 0.16), Vector3(0.24, 0.14, 0.02), Color(0.95, 0.85, 0.2))
	Props.collider(w, Vector3(0.4, 1.5, 0.35), meter + Vector3(0, 0.75, 0))
	_sign(w, "ОПЛАТА СНАМИ", meter + Vector3(0, 1.75, 0.17), 0.0, 0.16, Color(0.1, 0.1, 0.1), "board",
			{"bg": Color(0.95, 0.85, 0.2)})
	# инспектор парковки: пришелец в жилетке, рядом ховербайк качается над асфальтом
	var rng := RandomNumberGenerator.new()
	rng.seed = 2626
	var warden := Vector3(east + 5.5, 0, 6.0)
	DistrictSites._alien(w, warden, -PI / 2.0, rng)
	_sign(w, "ИНСПЕКТОР\nТАРЕЛОК", warden + Vector3(0, 2.3, 0), 90.0, 0.2, Color(0.1, 0.1, 0.1), "board",
			{"bg": Color(0.95, 0.85, 0.15)})
	var bike := Node3D.new()
	bike.name = "HoverBike"
	bike.position = warden + Vector3(1.6, 0.45, 1.2)
	bike.rotation.y = 0.4
	w.add_child(bike)
	Kit.box(bike, Vector3(0.7, 0.3, 2.0), Vector3.ZERO, Color(0.2, 0.22, 0.4))
	Kit.box(bike, Vector3(0.5, 0.25, 0.7), Vector3(0, 0.25, -0.3), Color(0.12, 0.12, 0.15))
	Kit.box(bike, Vector3(0.6, 0.35, 0.08), Vector3(0, 0.35, 0.8), Color(0.5, 0.8, 1.0, 0.6))
	Kit.box(bike, Vector3(0.75, 0.06, 2.05), Vector3(0, -0.17, 0), Color(0.7, 0.3, 1.0), 4.0)
	bike.create_tween().set_loops().set_trans(Tween.TRANS_SINE).tween_property(bike, "position:y", 0.6, 1.1).from(0.4)
	Props.collider(w, Vector3(0.8, 0.8, 2.1), warden + Vector3(1.6, 0.4, 1.2))
	# у киоска: ящики, шины, бутылки — склад «запчастей»
	for k in 5:
		b.model("boxes", KIOSK + Vector3(-4.5 + rng.randf_range(-0.6, 0.6), 0, 3.5 + k * 1.1), rng.randf() * TAU)
	b.model("tires", KIOSK + Vector3(4.6, 0, 3.0), 0.3)
	b.model("tires", KIOSK + Vector3(5.2, 0, 4.4), 1.2)
	for k in 8:
		DistrictSites._b(b, KIOSK + Vector3(-3.0 + rng.randf_range(-1.5, 1.5), 0.15, 5.5 + rng.randf_range(-1, 1)),
				Vector3(0.08, 0.3, 0.08), [Color(0.2, 0.45, 0.2), Color(0.45, 0.3, 0.15), Color(0.85, 0.85, 0.8)][k % 3])


static func _courtyard(w: Node3D) -> void:
	var batch := _yb
	var rng := RandomNumberGenerator.new()
	rng.seed = 2588
	for o in DistrictSites._all(_site, "PG_C1_courtyard_tree_trunk"):
		var c := _sw(DistrictSites._r(o).get_center())
		DistrictDressing._tree(batch, c, rng, 1.9)
		DistrictDressing._tree(batch, c + Vector3(rng.randf_range(8, 12), 0, rng.randf_range(-6, 6)), rng, 1.5)
	# газон и края двора заросли, как на концепте: деревья вдоль западного дома и у площадки
	for i in 9:
		DistrictDressing._tree(batch, Vector3(-82 + rng.randf_range(-2, 2), 0, -84 + i * 12.0), rng, rng.randf_range(1.3, 1.8))
	for p: Vector3 in [Vector3(-70, 0, -58), Vector3(-36, 0, -62), Vector3(-30, 0, -84), Vector3(5, 0, -70), Vector3(30, 0, -80),
			Vector3(55, 0, -70), Vector3(62, 0, -108), Vector3(-60, 0, -108), Vector3(10, 0, -110)]:
		DistrictDressing._tree(batch, p, rng, rng.randf_range(1.4, 2.0))
		for k in 3:
			_bush(p + Vector3(rng.randf_range(-5, 5), 0, rng.randf_range(-5, 5)), rng)
	for o in DistrictSites._all(_site, "PG_C1_bench"):
		var c := _sw(DistrictSites._r(o).get_center())
		Props.collider(w, Vector3(2.4, 0.5, 0.7), c + Vector3(0, 0.25, 0))
		batch.model("bench", c, 0.0)
		batch.props.append([c + Vector3(1.8, 0, 0.3), "bin"])
	# детская площадка у западного дома: качели, горка, песочница, карусель
	DistrictDressing._playground(batch, Vector3(-62, 0, -70), 0.0, rng)
	DistrictDressing._playground(batch, Vector3(-44, 0, -74), PI / 2.0, rng)
	batch.add("tank", Transform3D(Basis().scaled(Vector3(3.2, 0.25, 3.2)), Vector3(-50, 0.4, -62)), Color(0.85, 0.3, 0.2))
	batch.add("tank", Transform3D(Basis().scaled(Vector3(0.2, 1.4, 0.2)), Vector3(-50, 0.9, -62)), Color(0.9, 0.75, 0.2))
	Props.collider(w, Vector3(11, 2.5, 8), Vector3(-58, 1.2, -71))
	# мусорки у торца и у гаражей
	for pos in [Vector3(-84, 0, -36), Vector3(-84, 0, -32.5), Vector3(84, 0, -122)]:
		batch.model("dumpster", pos, PI / 2.0)
		Props.collider(w, Vector3(1.4, 1.6, 1.9), pos + Vector3(0, 0.8, 0))
	batch.model("trash_bags", Vector3(-83, 0, -29.5), 0.6)
	# бельё между столбами у западного дома
	for k in 2:
		var at := Vector3(-80, 0, -112 + k * 10)
		batch.box("lamp_post", at + Vector3(0, 1.1, -4.5), Vector3(0.08, 2.2, 0.08))
		batch.box("lamp_post", at + Vector3(0, 1.1, 4.5), Vector3(0.08, 2.2, 0.08))
		for i in 9:
			batch.add("cloth", Transform3D(Basis().scaled(Vector3(0.03, 0.75, 0.6)), at + Vector3(0, 1.75, -3.8 + i * 0.95)),
					[Color(0.85, 0.3, 0.3), Color(0.95, 0.95, 0.9), Color(0.3, 0.5, 0.8), Color(0.95, 0.8, 0.3)][(i + k) % 4])
	# огородики под окнами северного корпуса
	for k in 3:
		DistrictDressing._garden(batch, Vector3(-80 + k * 13, 0, -122), Vector2(10, 7), rng)
	# фонари двора по аллее и вокруг парковки
	for pos in [Vector3(-75, 0, -92), Vector3(-25, 0, -92), Vector3(25, 0, -92), Vector3(70, 0, -92), Vector3(-75, 0, -20),
			Vector3(-75, 0, 25), Vector3(25, 0, -45), Vector3(55, 0, 30), Vector3(-30, 0, 30)]:
		DistrictSites._lantern(batch, pos)
	batch.lamps.append_array(_extra_lamps)
	for step in DistrictDressing.flush_steps(w, LAMPS_KEY, batch):
		step.call()


# ---------- следы вчерашней ночи ----------

static func _story(w: Node3D) -> void:
	# сгоревшая машина у ограждения «место посадки», угли ещё тлеют
	var wreck_at := Vector3(-10, 0, -70)
	Props.collider(w, Vector3(2.2, 1.5, 4.4), wreck_at + Vector3(0, 0.75, 0))
	if Props.place(w, "car_wreck", wreck_at, 20.0):
		Kit.particles(w, wreck_at + Vector3(0, 1.2, 0), Color(1, 0.45, 0.1, 0.9), 24, 1.6, Vector3(0, 1.8, 0), 0.5, 0.06,
				Vector3(0.8, 0.2, 1.6))
		Kit.particles(w, wreck_at + Vector3(0, 1.6, 0), Color(0.2, 0.2, 0.22, 0.35), 14, 4.0, Vector3(0, 1.5, 0), 0.3, 1.1,
				Vector3(0.6, 0.2, 1.2))
	for x in [-12.5, -7.5]:
		Props.place(w, "barrier", Vector3(x, 0, wreck_at.z + 3.5), 0.0)
	Kit.box(w, Vector3(6.5, 0.06, 0.02), Vector3(-10, 0.9, wreck_at.z + 3.6), Color(1, 0.85, 0.1))
	Kit.label(w, "МЕСТО ПОСАДКИ · НЕ ПЕРЕСЕКАТЬ · СТРАХОВКА НЕ ПОКРЫВАЕТ", Vector3(-10, 1.15, wreck_at.z + 3.7), 22,
			Color(1, 0.85, 0.1), false)
	# сбитый дрон-сборщик ещё искрит
	var drone := Vector3(10, 0, -30)
	Props.collider(w, Vector3(1.8, 1, 1.8), drone + Vector3(0, 0.5, 0))
	if Props.place(w, "drone_wreck", drone, 40.0):
		Kit.particles(w, drone + Vector3(0.1, 1.0, -0.3), Color(0.5, 1, 0.95, 1), 16, 0.5, Vector3(0, 2.0, 0), 1.0, 0.04,
				Vector3(0.2, 0.1, 0.2))
	_ground_text(w, "ОН ПЕРВЫЙ НАЧАЛ", drone + Vector3(0, 0.1, 2.4), Color(1, 1, 1, 0.75), 40)
	# мелом: контур пришельца и банки
	_chalk_alien(w, Vector3(-30, 0.1, -10))
	_ground_text(w, "ГРИША. ОН БЫЛ ЗЕЛЁНЫЙ, НО НАШ", Vector3(-30, 0.11, -7.6), Color(1, 1, 1, 0.7), 34)
	# пришелец, привязанный к фонарю, в розовых трусах
	_tied_alien(w, Vector3(24.5, 0, -45.0))
	# плакат «разыскивается» на будке
	Signboard.make(w, "РАЗЫСКИВАЕТСЯ\nугонщик кабриолета\nфлота №0001\nнаграда: 3 благодарности", "poster",
			Color(0.15, 0.1, 0.08), BOOTH + Vector3(-1.75, 1.6, 0), -90.0, 0.17, {"bg": Color(0.92, 0.88, 0.75)})


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
	Kit.box(w, Vector3(0.18, 4.0, 0.18), pos + Vector3(0, 2.0, -0.35), Color(0.2, 0.2, 0.22))
	var a := Node3D.new()
	a.position = pos
	w.add_child(a)
	Kit.capsule(a, 0.24, 0.75, Vector3(0, 0.75, 0), Color(0.56, 0.82, 0.48))
	Kit.sphere(a, 0.3, Vector3(0, 1.4, 0), Color(0.56, 0.82, 0.48))
	Kit.box(a, Vector3(0.5, 0.18, 0.32), Vector3(0, 0.48, 0), Color(1, 0.35, 0.65))
	for side in [-1, 1]:
		Kit.sphere(a, 0.09, Vector3(side * 0.11, 1.45, 0.25), Color(0.05, 0.05, 0.1))
		Kit.cylinder(a, 0.02, 0.35, Vector3(side * 0.11, 1.82, 0), Color(0.4, 0.7, 0.3))
	for y in [0.6, 0.95, 1.15]:
		Kit.cylinder(a, 0.3, 0.05, Vector3(0, y, -0.1), Color(0.75, 0.6, 0.35))
	Kit.box(a, Vector3(0.7, 0.4, 0.02), Vector3(0, 0.95, 0.3), Color(0.95, 0.92, 0.85))
	var sign := Kit.label(a, "НЕ КОРМИТЬ\nназвал бабу Зину\n«примитивной формой»", Vector3(0, 0.95, 0.32), 16,
			Color(0.1, 0.1, 0.1), false)
	sign.outline_size = 0
	var tw := a.create_tween().set_loops()
	tw.tween_property(a, "rotation_degrees:z", 3.0, 0.4)
	tw.tween_property(a, "rotation_degrees:z", -3.0, 0.4)


static func _ground_text(w: Node3D, text: String, pos: Vector3, color: Color, size: int) -> void:
	var l := Kit.label(w, text, pos, size, color, false)
	l.rotation_degrees = Vector3(-90, 0, 0)
	l.outline_size = 0


## Граффити и объявления на стенах двора.
static func _walls_talk(w: Node3D) -> void:
	var wb := _wr("PG_C1_west_block")
	var fx := wb.end.x + 0.06
	var n_e := _wr("PG_C1_north_wing_e")
	var fz := n_e.end.y + 0.06
	for g in [["ГЛ'ОРП — ЛОХ", Vector3(fx, 1.6, -52), 90.0, Color(0.3, 1, 0.9)],
			["ВАСЯ + ЗЕЛЁНАЯ = ЛЮБОВЬ", Vector3(fx, 1.4, -112), 90.0, Color(1, 0.35, 0.65)],
			["ПРИШЕЛЬЦЫ, ВЕРНИТЕ ПЕНСИЮ", Vector3(40, 1.8, fz), 0.0, Color(1, 0.85, 0.1)],
			["КУПЛЮ ПОЧКУ ПРИШЕЛЬЦА · ЛЮБУЮ", Vector3(-40, 1.9, fz), 0.0, Color(0.95, 0.95, 0.95)]]:
		Signboard.make(w, g[0], "graffiti", g[3], g[1], g[2], 0.5)
	var paper := Color(0.92, 0.9, 0.84)
	for p in [["ВНИМАНИЕ!\nУЛЫБКА\nОБЯЗАТЕЛЬНА", Vector3(fx, 1.9, -40), 90.0, Color(0.1, 0.25, 0.6), paper],
			["ПРОПАЛ КОТ\nзовут Протокол\nвернуть за\nвознаграждение", Vector3(fx, 1.6, -92), 90.0, Color(0.1, 0.1, 0.1), paper],
			["МИКРОЗАЙМ\nЗА 5 МИНУТ\nДОЛГ НАВСЕГДА", Vector3(20, 1.9, fz), 0.0, Color(1, 1, 1), Color(0.8, 0.12, 0.1)],
			["СДАМ КОМНАТУ\nПРИШЕЛЬЦАМ\nбез детей", Vector3(60, 1.7, fz), 0.0, Color(0.1, 0.1, 0.1), Color(0.95, 0.9, 0.5)],
			["РОЗЫСК\nПЕСНЯ\nзапрещена\nдо написания", Vector3(-62, 2.0, fz - 0.0), 0.0, Color(0.6, 0.08, 0.06), paper],
			["СДАЙ ДРОНА —\nПОЛУЧИ\nСПАСИБО", Vector3(-20, 1.8, fz), 0.0, Color(0.05, 0.3, 0.15), paper],
			["БОЛЬШЕ,\nЧЕМ ЛЮДИ", Vector3(70, 2.3, fz), 0.0, Color(0.8, 0.1, 0.08), Color(0.86, 0.82, 0.72)]]:
		Signboard.make(w, p[0], "poster", p[3], p[1], p[2], 0.21, {"bg": p[4]})
	# лоток с доской у будки, как на эталоне
	var board := BOOTH + Vector3(-5.5, 0, 1.5)
	Props.collider(w, Vector3(0.9, 1.4, 0.4), board + Vector3(0, 0.7, 0))
	Props.place(w, "chalk_board", board, 0.0)
	Signboard.make(w, "СВЕЖЕЕ\nДЕШЕВЛЕ,\nЧЕМ\nЗАВТРА", "poster", Color(0.75, 0.12, 0.1), board + Vector3(0, 1.08, 0.06), 0.0, 0.19,
			{"tilt": 0.0, "font": "hand"})


static func _trash(w: Node3D) -> void:
	var spots := [["trash_bags", Vector3(-80, 0, -26)], ["boxes", Vector3(36, 0, -14)], ["beer_crate", Vector3(-44, 0, 10)],
			["trash_bags", Vector3(40, 0, -26)], ["boxes", Vector3(86, 0, -60)], ["beer_crate", Vector3(-58, 0, -40)],
			["trash_bags", Vector3(84, 0, -125)], ["boxes", Vector3(14, 0, 20)], ["beer_crate", Vector3(-20, 0, 12)],
			["trash_bags", Vector3(-70, 0, 14)], ["boxes", Vector3(60, 0, -110)], ["beer_crate", Vector3(-30, 0, -95)]]
	for s in spots:
		Breakable.spawn(w, s[0], s[1], randf_range(0, 360))


# ---------- границы ----------

static func _bounds(w: Node3D) -> void:
	var r := BOUNDS
	var east_x := r.end.x
	for wall in [[Vector3(r.position.x, 2, r.get_center().y), Vector3(1, 4, r.size.y)],
			[Vector3(east_x, 2, (r.position.y + EAST_GAP.x) / 2.0), Vector3(1, 4, EAST_GAP.x - r.position.y)],
			[Vector3((r.position.x - ARCH_HALF_W) / 2.0, 2, r.position.y), Vector3(-ARCH_HALF_W - r.position.x, 4, 1)],
			[Vector3((r.end.x + ARCH_HALF_W) / 2.0, 2, r.position.y), Vector3(r.end.x - ARCH_HALF_W, 4, 1)],
			[Vector3(r.get_center().x, 2, r.end.y), Vector3(r.size.x, 4, 1)]]:
		Props.collider(w, wall[1], wall[0]).set_meta("map_skip", true)
	# ворота в арке
	var gate := Props.collider(w, Vector3(ARCH_HALF_W * 2.0, 4, 1), Vector3(0, 2, r.position.y + 0.6))
	gate.name = "ExitGate"
	gate.set_meta("map_skip", true)
	Kit.box(gate, Vector3(ARCH_HALF_W * 2.0, 2.2, 0.08), Vector3(0, -0.9, 0), Color(0.25, 0.27, 0.3))
	for i in 9:
		Kit.box(gate, Vector3(0.06, 2.2, 0.06), Vector3(-ARCH_HALF_W + 0.6 + i * 0.8, -0.9, 0.06), Color(0.5, 0.5, 0.5))
	# восточный проход южнее гаражей: решётчатые ворота «на переучёте»
	var gap := EAST_GAP.y - EAST_GAP.x
	var east := Props.collider(w, Vector3(1, 4, gap), Vector3(east_x, 2, (EAST_GAP.x + EAST_GAP.y) / 2.0))
	east.name = "ExitGateEast"
	east.set_meta("map_skip", true)
	Kit.box(east, Vector3(0.08, 2.2, gap), Vector3(0, -0.9, 0), Color(0.3, 0.32, 0.3))
	for i in int(gap / 1.2):
		Kit.box(east, Vector3(0.06, 2.2, 0.06), Vector3(-0.06, -0.9, -gap / 2.0 + 0.6 + i * 1.2), Color(0.5, 0.5, 0.5))
	Signboard.make(east, "ПРОХОД ЗАКРЫТ\nНА ПЕРЕУЧЁТ ЖИЛЬЦОВ", "board", Color(0.1, 0.1, 0.1), Vector3(-0.1, -0.4, 0), -90.0, 0.32,
			{"bg": Color(0.95, 0.85, 0.2)})
	# с юга — низкая ограда с калиткой у шлагбаума, за ней улица
	var x := r.position.x + 1.25
	while x < r.end.x:
		if absf(x - BARRIER.x - 3.0) > 4.0:
			Props.place(w, "fence", Vector3(x, 0, r.end.y - 0.4), 0.0)
		x += 2.5
