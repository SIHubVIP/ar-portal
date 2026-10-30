class_name DosvidSites
extends RefCounted
## Площадки района «До свидания» по пакету «Рубин» (0.15, D-057): опасная промышленная окраина,
## где пришельцы теряют запчасти, авторитет и терпение. Объёмы и места — из
## data/pogulyay_layout.json → sites (id "ds_*"), облик — по артам docs/source/rubin_dosvidaniya:
##   ds_bazaar  — B2 «Базар под куполом»: ряды под рёбрами битого купола, станция пришельцев над
##                площадью, общежитие на западе, разборка тарелок на востоке;
##   ds_garages — C1 «Гаражи без вопросов»: 44 гаража рядами, мастерская, таль над ямой
##                с инопланетным двигателем, пост со шлагбаумом;
##   ds_boiler  — C2 «Котельная прощаний»: кирпичный корпус, две трубы, насосная, теплотрасса
##                на опорах, мостик с лестницей и ядро, подключённое к теплосети;
##   ds_depot, ds_scrap, ds_cemetery, ds_dorm, ds_bath, ds_canal — ориентиры остальных секторов.
## Общие приёмы — у DistrictSites; здесь короткие обёртки, чтобы строки читались.

const RUST := Color(0.48, 0.27, 0.16)
const BRICK := Color(0.55, 0.3, 0.22)
const ALIEN := Color(0.6, 0.35, 1.0)
const YELLOW := Color(0.95, 0.75, 0.15)
const GARAGE_COLORS := [Color(0.35, 0.45, 0.5), Color(0.55, 0.25, 0.2), Color(0.3, 0.42, 0.32), Color(0.5, 0.48, 0.42),
		Color(0.25, 0.32, 0.45), Color(0.6, 0.45, 0.25)]


static func build(root: Node3D, site: Dictionary, batch: DistrictDressing.Batch) -> void:
	match String(site.id):
		"ds_bazaar":
			_bazaar(root, site, batch)
		"ds_garages":
			_garages(root, site, batch)
		"ds_boiler":
			_boiler(root, site, batch)
		"ds_depot":
			_depot(root, site, batch)
		"ds_scrap":
			_scrap(root, site, batch)
		"ds_cemetery":
			_cemetery(root, site, batch)
		"ds_dorm":
			_dorm(root, site, batch)
		"ds_bath":
			_bath(root, site, batch)
		"ds_canal":
			_canal(root, site, batch)


# ---------- обёртки ----------

static func _r(site: Dictionary, name: String) -> Rect2:
	return DistrictSites._r(DistrictSites._o(site, name))


static func _all(site: Dictionary, prefix: String) -> Array:
	return DistrictSites._all(site, prefix)


static func _w(x: float, y: float, h := 0.0) -> Vector3:
	return District.to_world(Vector2(x, y), h)


static func _c(r: Rect2, h := 0.0) -> Vector3:
	return District.to_world(r.get_center(), h)


static func _b(batch: DistrictDressing.Batch, center: Vector3, size: Vector3, color: Color, yaw := 0.0, kind := "site") -> void:
	batch.box(kind, center, size, yaw, color)


static func _sign(batch: DistrictDressing.Batch, root: Node3D, text: String, kind: String, color: Color, pos: Vector3,
		yaw_deg: float, height: float, opts := {}) -> void:
	DistrictSites._sign(batch, root, text, kind, color, pos, yaw_deg, height, opts)


static func _rng(seed: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return rng


## Труба полосами снизу вверх, коллизия и дым (котельные, баня, депо).
static func _chimney(root: Node3D, batch: DistrictDressing.Batch, site: Dictionary, name: String, smoke := Color(0.75, 0.72, 0.7, 0.4)) -> void:
	var o := DistrictSites._o(site, name)
	var foot := _c(DistrictSites._r(o))
	var h := float(o.z[1])
	var bands := int(h / 5.0)
	for i in bands:
		batch.add("tank", Transform3D(Basis().scaled(Vector3(4.6 - i * 0.12, h / bands, 4.6 - i * 0.12)),
				foot + Vector3(0, (i + 0.5) * h / bands, 0)), DistrictSites.RED if i % 2 == 1 and i > bands - 4 else BRICK.darkened(0.05 * (i % 2)))
	Props.collider(root, Vector3(4.6, h, 4.6), foot + Vector3(0, h / 2.0, 0))
	var p := Kit.particles(root, foot + Vector3(0, h + 1.0, 0), smoke, 12, 7.0, Vector3(0.6, 2.0, 0.2), 0.15, 4.5)
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Куча лома: ржавые листы, бочки, детали корпуса тарелки с огоньками.
static func _scrap_heap(batch: DistrictDressing.Batch, at: Vector3, size: Vector2, rng: RandomNumberGenerator, alien := true) -> void:
	for k in int(size.x * size.y / 6.0):
		var p := at + Vector3(rng.randf_range(-size.x, size.x) / 2.0, 0, rng.randf_range(-size.y, size.y) / 2.0)
		var s := Vector3(rng.randf_range(0.8, 2.6), rng.randf_range(0.3, 1.6), rng.randf_range(0.6, 2.2))
		var col: Color = [RUST, RUST.darkened(0.3), Color(0.42, 0.44, 0.48), Color(0.3, 0.32, 0.36)][rng.randi() % 4]
		batch.add("site", Transform3D(Basis.from_euler(Vector3(rng.randf_range(-0.4, 0.4), rng.randf() * TAU, rng.randf_range(-0.4, 0.4)))
				* Basis.from_scale(s), p + Vector3(0, s.y / 2.0, 0)), col)
	if alien:
		for k in 3:
			var g := at + Vector3(rng.randf_range(-size.x, size.x) / 3.0, rng.randf_range(0.6, 1.4), rng.randf_range(-size.y, size.y) / 3.0)
			_b(batch, g, Vector3(0.35, 0.35, 0.35), ALIEN, 0.0, "glow")


# ---------- B2 «Базар под куполом» ----------

static func _bazaar(root: Node3D, site: Dictionary, batch: DistrictDressing.Batch) -> void:
	var rng := _rng(4515)
	var yard := _r(site, "DS_B2_courtyard")
	DistrictSites._paving(batch, yard)
	DistrictSites._tree_row(batch, site, "DS_B2_edge_tree_trunk")
	var center := _w(4500, -1500)
	# купол: восемь рёбер дугой (радиус 65 м, от 5 до 50 м), кольцо на опорах, остатки мембраны
	var ribs := 8
	for i in ribs:
		var a := TAU * i / ribs + 0.2
		if i == 5:
			continue          # одно ребро выломано: лежит на земле у разборки
		var segs := 9
		for k in segs:
			var t0 := float(k) / segs * PI / 2.0
			var t1 := float(k + 1) / segs * PI / 2.0
			var p0 := Vector3(cos(t0) * 65.0 * cos(a), 5.0 + sin(t0) * 45.0, cos(t0) * 65.0 * sin(a))
			var p1 := Vector3(cos(t1) * 65.0 * cos(a), 5.0 + sin(t1) * 45.0, cos(t1) * 65.0 * sin(a))
			var d := p1 - p0
			batch.add("site", Transform3D(Basis.looking_at(d.normalized(), Vector3.UP) * Basis.from_scale(Vector3(1.1, 0.8, d.length() + 0.4)),
					center + p0 + d / 2.0), Color(0.35, 0.3, 0.38))
			if k % 3 == 1:
				_b(batch, center + p0 + d / 2.0 + Vector3(0, -0.6, 0), Vector3(0.5, 0.5, 0.5), ALIEN, 0.0, "glow")
		# опора ребра у земли
		var foot := center + Vector3(cos(a) * 65.0, 0, sin(a) * 65.0)
		_b(batch, foot + Vector3(0, 2.5, 0), Vector3(1.4, 5.0, 1.4), Color(0.3, 0.28, 0.3))
		Props.collider(root, Vector3(1.4, 5.0, 1.4), foot + Vector3(0, 2.5, 0))
	for i in 32:
		var a0 := TAU * i / 32.0
		var a1 := TAU * (i + 1) / 32.0
		var p0 := Vector3(cos(a0) * 65.0, 5.0, sin(a0) * 65.0)
		var p1 := Vector3(cos(a1) * 65.0, 5.0, sin(a1) * 65.0)
		var d := p1 - p0
		batch.add("site", Transform3D(Basis.looking_at(d.normalized(), Vector3.UP) * Basis.from_scale(Vector3(0.6, 0.6, d.length() + 0.2)),
				center + p0 + d / 2.0), Color(0.42, 0.4, 0.42))
	# от мембраны остались лиловые огни на кольце: сама плёнка — будущая художественная часть (бриф)
	for k in 24:
		var a := TAU * k / 24.0
		_b(batch, center + Vector3(cos(a) * 65.0, 5.6, sin(a) * 65.0), Vector3(0.6, 0.4, 0.6), ALIEN, 0.0, "glow")
	var fallen := center + Vector3(cos(TAU * 5 / ribs + 0.2) * 70.0, 0.6, sin(TAU * 5 / ribs + 0.2) * 70.0)
	_b(batch, fallen, Vector3(1.1, 1.0, 28.0), Color(0.35, 0.3, 0.38), 0.7)
	Props.collider(root, Vector3(1.2, 1.2, 28.0), fallen).rotation.y = 0.7
	# станция пришельцев висит над куполом на 48 м: диск, огни, щупальца-кабели вниз
	var st := Node3D.new()
	st.name = "BazaarStation"
	st.position = center + Vector3(0, 49.5, 0)
	root.add_child(st)
	Kit.cylinder(st, 14.0, 2.6, Vector3.ZERO, Color(0.4, 0.4, 0.46), 0.0, 11.0)
	Kit.cylinder(st, 7.0, 3.0, Vector3(0, 2.4, 0), Color(0.32, 0.32, 0.38), 0.0, 4.5)
	Kit.cylinder(st, 5.0, 2.0, Vector3(0, -2.2, 0), Color(0.25, 0.25, 0.3), 0.0, 8.0)
	var sx := st.transform
	for i in 16:
		var a := TAU * i / 16.0
		batch.add("glow", sx * Transform3D(Basis().scaled(Vector3.ONE * 0.8), Vector3(cos(a) * 13.0, -0.4, sin(a) * 13.0)),
				ALIEN if i % 2 else Color(0.3, 1.0, 0.85))
	for i in 6:
		var a := TAU * i / 6.0
		var top := center + Vector3(cos(a) * 8.0, 47.0, sin(a) * 8.0)
		var low := center + Vector3(cos(a) * 30.0, 38.0 - (i % 3) * 3.0, sin(a) * 30.0)
		var d := low - top
		batch.add("site", Transform3D(Basis.looking_at(d.normalized(), Vector3.UP) * Basis.from_scale(Vector3(0.5, 0.5, d.length())), top + d / 2.0),
				Color(0.2, 0.18, 0.24))
	var beam := Kit.sphere(st, 1.0, Vector3(0, -3.6, 0), ALIEN, 5.0)
	beam.create_tween().set_loops().tween_property(beam, "scale", Vector3.ONE * 0.3, 1.1).from(Vector3.ONE)
	# павильон и магазин
	var hall := _r(site, "DS_B2_market_hall")
	var hc := DistrictSites._hall(root, hall, 9.0, true, BRICK.darkened(0.1), Color(0.3, 0.3, 0.32), true)
	_sign(batch, root, "ВАШ КОРАБЛЬ УЖЕ\nНА ПРИЛАВКЕ", "lightbox", Color(0.6, 0.15, 0.1), hc + Vector3(0, 6.6, hall.size.y / 2.0 + 0.1),
			0.0, 0.55, {"bg": Color(1.0, 0.95, 0.85)})
	var store := _r(site, "DS_B2_market_store")
	var sc := DistrictSites._hall(root, store, 6.0, false, Color(0.72, 0.7, 0.62), Color(0.3, 0.3, 0.32), true)
	_sign(batch, root, "ГАРАНТИЯ ДО ПЕРВОГО\nВТОРЖЕНИЯ", "board", Color(0.1, 0.1, 0.1), sc + Vector3(-store.size.x / 2.0 - 0.1, 4.2, 6), -90.0,
			0.36, {"bg": Color(0.98, 0.9, 0.3), "lamp": true})
	# ряды: прилавки с навесами, товар — детали тарелок светится лиловым
	for o in _all(site, "DS_B2_market_stall_"):
		var r := DistrictSites._r(o)
		var c := _c(r)
		var col: Color = DistrictSites.AWNINGS[rng.randi() % DistrictSites.AWNINGS.size()]
		_b(batch, c + Vector3(0, 0.5, 0), Vector3(r.size.x, 1.0, r.size.y - 1.2), Color(0.45, 0.36, 0.26))
		_b(batch, c + Vector3(0, 2.8, 0), Vector3(r.size.x + 0.6, 0.12, r.size.y + 0.4), col, 0.0, "awning")
		for sx2: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				_b(batch, c + Vector3(sx2 * r.size.x / 2.0, 1.4, sz * r.size.y / 2.0), Vector3(0.1, 2.8, 0.1), Color(0.25, 0.25, 0.27))
		for k in 4:
			_b(batch, c + Vector3(-r.size.x / 2.0 + 1.0 + k * 2.0, 1.2, 0), Vector3(0.6, 0.35, 0.5),
					ALIEN if k % 2 == 0 else Color(0.6, 0.62, 0.66), 0.0, "glow" if k % 2 == 0 else "site")
		Props.collider(root, Vector3(r.size.x, 1.0, r.size.y - 1.2), c + Vector3(0, 0.5, 0))
		if rng.randf() < 0.6:
			if rng.randf() < 0.3:
				DistrictSites._alien(root, c + Vector3(0, 0, r.size.y / 2.0 + 0.6), PI, rng)
			else:
				DistrictSites._person(root, c + Vector3(0, 0, -r.size.y / 2.0 + 0.2), 0.0, rng)
	# покупатели между рядами и облава: два патрульных пришельца с огнями на броне
	for k in 26:
		var p := _w(4455.0 + rng.randf() * 90.0, -1488.0 + rng.randf() * 50.0)
		if k % 6 == 0:
			DistrictSites._alien(root, p, rng.randf() * TAU, rng)
		else:
			DistrictSites._person(root, p, rng.randf() * TAU, rng)
	DistrictSites._alien(root, _w(4508, -1430), PI, rng, true)
	DistrictSites._alien(root, _w(4520, -1436), PI * 1.2, rng, true)
	# офицер покупает свой же двигатель — сценка у разборки
	var deal := _w(4572, -1462)
	_b(batch, deal + Vector3(0, 0.45, 0), Vector3(2.4, 0.9, 1.4), Color(0.45, 0.36, 0.26))
	batch.add("tank", Transform3D(Basis(Vector3.FORWARD, PI / 2.0) * Basis.from_scale(Vector3(1.2, 2.0, 1.2)), deal + Vector3(0, 1.6, 0)),
			Color(0.55, 0.58, 0.64))
	_b(batch, deal + Vector3(1.1, 1.6, 0), Vector3(0.4, 0.4, 0.4), ALIEN, 0.0, "glow")
	DistrictSites._alien(root, deal + Vector3(0, 0, -1.6), 0.0, rng, true)
	DistrictSites._person(root, deal + Vector3(0, 0, 1.5), PI, rng, {"top": Color(0.3, 0.3, 0.32)})
	_sign(batch, root, "ДВИГАТЕЛЬ Б/У\nСНЯТ С РАБОТАЮЩЕГО", "board", Color(0.1, 0.1, 0.1), deal + Vector3(0, 1.3, 0.72), 0.0, 0.16,
			{"bg": Color(1, 1, 0.92), "far": DistrictDressing.SIGN_FAR_M})
	# разборка тарелок на востоке: четыре кучи корпусов с огнями
	for o in _all(site, "DS_B2_alien_scrap"):
		var r := DistrictSites._r(o)
		var c := _c(r)
		batch.add("tank", Transform3D(Basis.from_euler(Vector3(rng.randf_range(0.3, 0.7), rng.randf() * TAU, 0)) * Basis.from_scale(Vector3(9, 1.4, 9)),
				c + Vector3(0, 2.2, 0)), Color(0.5, 0.52, 0.58))
		_scrap_heap(batch, c, r.size, rng)
		Props.collider(root, Vector3(r.size.x, 4.0, r.size.y), c + Vector3(0, 2.0, 0))
	# общежитие на западе
	var dorm := _r(site, "DS_B2_old_dormitory")
	var dc := DistrictSites._hall(root, dorm, 12.0, true, BRICK)
	_sign(batch, root, "ОБЩЕЖИТИЕ\nМЕСТ НЕТ С 1987", "board", Color(0.95, 0.9, 0.8), dc + Vector3(dorm.size.x / 2.0 + 0.1, 4.0, 40), 90.0, 0.4,
			{"bg": Color(0.25, 0.22, 0.2), "lamp": true})
	# ворота с вывеской
	for name in ["DS_B2_market_gate_l", "DS_B2_market_gate_r"]:
		var g := _c(_r(site, name))
		_b(batch, g + Vector3(0, 3.5, 0), Vector3(0.6, 7.0, 0.6), RUST)
		Props.collider(root, Vector3(0.7, 7.0, 0.7), g + Vector3(0, 3.5, 0))
	var sg := _r(site, "DS_B2_market_sign")
	_b(batch, _c(sg, 7.2), Vector3(15.0, 0.4, 0.4), RUST)
	_sign(batch, root, "БАЗАР ПОД КУПОЛОМ", "board", Color(0.15, 0.1, 0.08), _c(sg, 6.2) + Vector3(0, 0, 0.4), 0.0, 1.5,
			{"bg": Color(0.92, 0.85, 0.7), "lamp": true})
	for k in 5:
		DistrictSites._lantern(batch, _w(4420 + k * 40, -1400))
	for k in 4:
		var a := TAU * k / 4.0 + 0.6
		DistrictSites._lantern(batch, center + Vector3(cos(a) * 40.0, 0, sin(a) * 40.0))


# ---------- C1 «Гаражи без вопросов» ----------

static func _garages(root: Node3D, site: Dictionary, batch: DistrictDressing.Batch) -> void:
	var rng := _rng(3525)
	var yard := _r(site, "DS_C1_courtyard")
	batch.box("pocket", _c(yard, 0.04), Vector3(yard.size.x, 0.04, yard.size.y), 0.0, Color(1.15, 1.1, 1.05))
	DistrictSites._tree_row(batch, site, "DS_C1_edge_tree_trunk")
	# гаражи: железные коробки с двускатной крышей, ворота разного цвета, кое-где открыты
	var doors := _all(site, "DS_C1_garage_door")
	var i := 0
	for o in site.objects:
		if o.name != "DS_C1_garage":
			continue
		var r := DistrictSites._r(o)
		var c := _c(r)
		var col: Color = GARAGE_COLORS[(i * 7 + int(r.position.y)) % GARAGE_COLORS.size()]
		_b(batch, c + Vector3(0, 1.5, 0), Vector3(r.size.x, 3.0, r.size.y), col.darkened(0.15))
		_b(batch, c + Vector3(0, 3.1, 0), Vector3(r.size.x + 0.4, 0.2, r.size.y + 0.4), Color(0.36, 0.33, 0.3))
		for k in 6:
			_b(batch, c + Vector3(-r.size.x / 2.0 + 0.9 + k * (r.size.x - 1.8) / 5.0, 3.24, 0), Vector3(0.12, 0.08, r.size.y + 0.4),
					RUST.darkened(0.25))
		_b(batch, c + Vector3(0, 2.4, r.size.y / 2.0 + 0.03), Vector3(r.size.x - 0.4, 0.05, 0.05), Color(0.2, 0.2, 0.22))
		Props.collider(root, Vector3(r.size.x, 3.0, r.size.y), c + Vector3(0, 1.5, 0), true)
		i += 1
	for o in doors:
		var r := DistrictSites._r(o)
		var c := _c(r)
		var open := rng.randf() < 0.25
		var col: Color = GARAGE_COLORS[rng.randi() % GARAGE_COLORS.size()]
		if open:
			_b(batch, c + Vector3(0, 1.3, 0), Vector3(r.size.x + 0.05, 2.6, r.size.y * 0.9), Color(0.08, 0.07, 0.06))
			_b(batch, c + Vector3(0, 2.4, 0), Vector3(r.size.x + 0.1, 0.12, 0.12), Color(1.0, 0.75, 0.4, 0.0), 0.0, "glow")
			batch.lamps.append(c + Vector3(0, 2.4, 0))
		else:
			_b(batch, c + Vector3(0, 1.3, 0), Vector3(r.size.x + 0.05, 2.6, r.size.y * 0.9), col)
	# мастерская на севере
	var ws := _r(site, "DS_C1_repair_workshop")
	var wc := DistrictSites._hall(root, ws, 6.0, true, BRICK)
	var front := wc + Vector3(0, 0, ws.size.y / 2.0)
	_sign(batch, root, "ГАРАЖИ БЕЗ ВОПРОСОВ", "letters", Color(0.95, 0.88, 0.75), front + Vector3(0, 5.0, 0.15), 0.0, 0.8)
	_sign(batch, root, "РАЗВАЛ-СХОЖДЕНИЕ\nЦИВИЛИЗАЦИЙ", "board", Color(0.95, 0.9, 0.8), front + Vector3(-20, 2.6, 0.12), 0.0, 0.34,
			{"bg": Color(0.22, 0.2, 0.18), "lamp": true})
	for k in 2:
		_b(batch, front + Vector3(-8 + k * 16, 1.8, 0.08), Vector3(5.0, 3.6, 0.12), Color(0.1, 0.09, 0.08))
		_b(batch, front + Vector3(-8 + k * 16, 3.5, 0.2), Vector3(4.0, 0.12, 0.12), Color(1.0, 0.8, 0.5, 0.0), 0.0, "glow")
	var car := CarKit.make(root, Color(0.65, 0.55, 0.35), false, 0)
	car.position = front + Vector3(-8, 0, 2.5)
	Props.collider(root, Vector3(CarKit.WIDTH, 1.5, CarKit.LENGTH), car.position + Vector3(0, 0.75, 0))
	# центральный проход: смотровая яма и таль с инопланетным двигателем
	var pit := _r(site, "DS_C1_inspection_pit")
	var pc := _c(pit)
	_b(batch, pc + Vector3(0, 0.06, 0), Vector3(pit.size.x, 0.04, pit.size.y), Color(0.04, 0.04, 0.04))
	for sx: float in [-1.0, 1.0]:
		_b(batch, pc + Vector3(sx * (pit.size.x / 2.0 + 0.15), 0.08, 0), Vector3(0.3, 0.06, pit.size.y), YELLOW, 0.0, "paint")
	_b(batch, pc + Vector3(0, -0.4, 0), Vector3(0.3, 0.3, 0.3), Color(1.0, 0.8, 0.5, 0.0), 0.0, "glow")
	var hoist := _c(_r(site, "DS_C1_hoist"))
	_b(batch, hoist + Vector3(0, 4.0, 0), Vector3(0.5, 8.0, 0.5), YELLOW)
	_b(batch, hoist + Vector3(-23, 4.0, 0), Vector3(0.5, 8.0, 0.5), YELLOW)
	Props.collider(root, Vector3(0.6, 8.0, 0.6), hoist + Vector3(0, 4.0, 0))
	Props.collider(root, Vector3(0.6, 8.0, 0.6), hoist + Vector3(-23, 4.0, 0))
	_b(batch, hoist + Vector3(-11.5, 8.0, 0), Vector3(23.6, 0.6, 0.6), YELLOW)
	var eng := _c(_r(site, "DS_C1_alien_engine"), 3.5)
	var engine := Node3D.new()
	engine.name = "HoistEngine"
	engine.position = eng
	root.add_child(engine)
	Kit.sphere(engine, 1.8, Vector3.ZERO, Color(0.35, 0.36, 0.42))
	Kit.cylinder(engine, 2.4, 0.4, Vector3.ZERO, Color(0.25, 0.25, 0.3), 0.0, 2.4)
	Kit.sphere(engine, 0.8, Vector3(0, 0, 1.5), ALIEN, 4.0)
	engine.create_tween().set_loops().tween_property(engine, "rotation:y", TAU, 6.0).from(0.0)
	_b(batch, eng + Vector3(0, 2.5, 0), Vector3(0.05, 3.0, 0.05), Color(0.2, 0.2, 0.2))
	for k in 4:
		DistrictSites._person(root, eng + Vector3(-3.0 + k * 2.0, -3.5, 3.5 + (k % 2)), PI, rng, {"top": Color(0.3, 0.32, 0.36)})
	_sign(batch, root, "ДОКУМЕНТЫ СГОРЕЛИ\nВ ГИПЕРПРЫЖКЕ", "board", Color(0.1, 0.1, 0.1), _w(3580, -470, 2.4), -90.0, 0.4,
			{"bg": Color(0.92, 0.9, 0.85)})
	_b(batch, _w(3580.3, -470, 1.2), Vector3(0.12, 2.4, 0.12), Color(0.25, 0.25, 0.27))
	# корабль захватчика «как бесхозный мопед»: облезлая тарелка-самоделка на колёсах
	var moped := _w(3560, -505)
	batch.add("tank", Transform3D(Basis().scaled(Vector3(6.5, 1.0, 3.2)), moped + Vector3(0, 1.2, 0)), Color(0.62, 0.45, 0.35))
	batch.add("crown", Transform3D(Basis().scaled(Vector3(2.0, 1.2, 1.6)), moped + Vector3(0.5, 1.9, 0)), Color(0.45, 0.75, 0.85))
	for sx: float in [-2.0, 2.0]:
		for sz: float in [-1.2, 1.2]:
			batch.add("tank", Transform3D(Basis(Vector3.RIGHT, PI / 2.0) * Basis.from_scale(Vector3(0.9, 0.35, 0.9)), moped + Vector3(sx, 0.45, sz)),
					Color(0.08, 0.08, 0.08))
	Props.collider(root, Vector3(6.5, 2.0, 3.2), moped + Vector3(0, 1.0, 0))
	_sign(batch, root, "БЕСХОЗНЫЙ МОПЕД\nСПИСАН", "board", Color(0.1, 0.1, 0.1), moped + Vector3(0, 1.4, 1.65), 0.0, 0.16,
			{"bg": Color(1, 0.95, 0.85), "far": DistrictDressing.SIGN_FAR_M})
	DistrictSites._alien(root, moped + Vector3(-4, 0, 1), PI / 2.0, rng)
	# лом у западного ряда
	for o in _all(site, "DS_C1_scrap_stack"):
		var r := DistrictSites._r(o)
		_scrap_heap(batch, _c(r), r.size, rng, rng.randf() < 0.4)
	for k in 6:
		batch.model("tires", _w(3445 + rng.randf() * 10, -430 - k * 25.0), rng.randf() * TAU)
	# пост со шлагбаумом на юге
	var booth := _r(site, "DS_C1_guard_booth")
	var bc := DistrictSites._hall(root, booth, 3.0, false, Color(0.3, 0.5, 0.46), Color(0.22, 0.22, 0.24))
	_b(batch, bc + Vector3(0, 1.8, booth.size.y / 2.0 + 0.05), Vector3(4.0, 1.0, 0.05), Color(1.0, 0.82, 0.5, 0.0), 0.0, "glow")
	DistrictSites._person(root, bc + Vector3(-2.0, 0, booth.size.y / 2.0 + 1.0), PI, rng, {"top": Color(0.2, 0.25, 0.2)})
	var arm := _r(site, "DS_C1_checkpoint_arm")
	var ac := _c(arm, 1.1)
	for k in 8:
		_b(batch, ac + Vector3(-arm.size.x / 2.0 + (k + 0.5) * arm.size.x / 8.0, 0, 0), Vector3(arm.size.x / 8.0, 0.15, 0.15),
				DistrictSites.RED if k % 2 == 0 else Color(0.95, 0.95, 0.92))
	_b(batch, ac + Vector3(arm.size.x / 2.0, -0.5, 0), Vector3(0.4, 1.2, 0.4), Color(0.3, 0.3, 0.32))
	for k in 4:
		DistrictSites._lantern(batch, _w(3420 + k * 54, -396))


# ---------- C2 «Котельная прощаний» ----------

static func _boiler(root: Node3D, site: Dictionary, batch: DistrictDressing.Batch) -> void:
	var rng := _rng(4535)
	var yard := _r(site, "DS_C2_courtyard")
	batch.box("pocket", _c(yard, 0.04), Vector3(yard.size.x, 0.04, yard.size.y), 0.0, Color(1.1, 1.05, 1.0))
	DistrictSites._tree_row(batch, site, "DS_C2_edge_tree_trunk")
	var bo := _r(site, "DS_C2_heat_plant_boiler")
	var bc := DistrictSites._hall(root, bo, 15.0, true, BRICK.darkened(0.05))
	var front := bc + Vector3(0, 0, bo.size.y / 2.0)
	_sign(batch, root, "КОТЕЛЬНАЯ ПРОЩАНИЙ", "letters", Color(1.0, 0.8, 0.5), front + Vector3(0, 13.0, 0.15), 0.0, 1.0)
	_sign(batch, root, "ТЕПЛО — ПОСЛЕ\nКОНЦА СВЕТА", "board", Color(0.95, 0.9, 0.8), front + Vector3(-18, 4.0, 0.12), 0.0, 0.42,
			{"bg": Color(0.2, 0.22, 0.25), "lamp": true})
	_sign(batch, root, "ГАЛАКТИЧЕСКИЙ ДОЛГ\nЗА ОТОПЛЕНИЕ:\n∞ ₽ 00 КОП.", "lightbox", Color(0.7, 0.1, 0.1), front + Vector3(18, 4.5, 0.12), 0.0,
			0.42, {"bg": Color(1.0, 0.96, 0.88)})
	for name in ["DS_C2_heat_plant_chimney", "DS_C2_heat_plant_chimney2"]:
		_chimney(root, batch, site, name)
	var ph := _r(site, "DS_C2_pump_house")
	var pc := DistrictSites._hall(root, ph, 7.0, true, BRICK)
	_sign(batch, root, "НАСОСНАЯ", "board", Color(0.95, 0.9, 0.8), pc + Vector3(0, 5.2, ph.size.y / 2.0 + 0.1), 0.0, 0.3,
			{"bg": Color(0.2, 0.22, 0.25)})
	# теплотрасса на опорах: две трубы в серебристой изоляции с юга к котельной
	for o in _all(site, "DS_C2_heating_pipe"):
		var r := DistrictSites._r(o)
		batch.add("tank", Transform3D(Basis(Vector3.RIGHT, PI / 2.0) * Basis.from_scale(Vector3(1.3, r.size.y, 1.3)), _c(r, 4.0)),
				Color(0.72, 0.72, 0.7))
		var y := r.position.y + 8.0
		while y < r.end.y:
			_b(batch, _w(r.get_center().x, y, 4.0), Vector3(1.5, 0.25, 0.3), Color(0.5, 0.5, 0.5))
			y += 8.0
	for o in _all(site, "DS_C2_pipe_support"):
		var c := _c(DistrictSites._r(o))
		_b(batch, c + Vector3(0, 2.5, 0), Vector3(0.5, 5.0, 0.5), RUST)
		Props.collider(root, Vector3(0.5, 5.0, 0.5), c + Vector3(0, 2.5, 0))
	for o in _all(site, "DS_C2_crossbar"):
		var r := DistrictSites._r(o)
		_b(batch, _c(r, 4.0), Vector3(r.size.x, 0.5, 0.5), RUST)
	# пар из стыка трубы
	var leak := Kit.particles(root, _w(4475, -470, 4.6), Color(0.95, 0.95, 0.95, 0.4), 18, 3.0, Vector3(0.3, 2.5, 0), 0.3, 2.5)
	leak.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# мостик над трубами и лестница
	var cw := _r(site, "DS_C2_catwalk")
	var cc := _c(cw, 4.15)
	_b(batch, cc, Vector3(cw.size.x, 0.3, cw.size.y), Color(0.4, 0.42, 0.44))
	for sz: float in [-1.0, 1.0]:
		_b(batch, cc + Vector3(0, 1.0, sz * cw.size.y / 2.0), Vector3(cw.size.x, 0.08, 0.08), YELLOW)
		var x := -cw.size.x / 2.0
		while x <= cw.size.x / 2.0:
			_b(batch, cc + Vector3(x, 0.5, sz * cw.size.y / 2.0), Vector3(0.08, 1.0, 0.08), YELLOW)
			x += 2.5
	for o in _all(site, "DS_C2_catwalk_step"):
		var r := DistrictSites._r(o)
		var o_z: Array = o.z
		_b(batch, _c(r, float(o_z[1]) - 0.15), Vector3(r.size.x, 0.25, r.size.y), Color(0.4, 0.42, 0.44))
	# ядро пришельцев, подключённое к теплосети: шар в клетке, кабели к трубам, мигает
	var core := _c(_r(site, "DS_C2_alien_heat_core"))
	var cn := Node3D.new()
	cn.name = "HeatCore"
	cn.position = core + Vector3(0, 4.0, 0)
	root.add_child(cn)
	Kit.sphere(cn, 3.2, Vector3.ZERO, ALIEN, 3.0)
	for k in 6:
		var a := TAU * k / 6.0
		_b(batch, core + Vector3(cos(a) * 5.5, 4.0, sin(a) * 5.5), Vector3(0.3, 8.0, 0.3), Color(0.3, 0.3, 0.32))
	_b(batch, core + Vector3(0, 8.1, 0), Vector3(11.5, 0.3, 11.5), Color(0.3, 0.3, 0.32))
	Props.collider(root, Vector3(11.5, 8.0, 11.5), core + Vector3(0, 4.0, 0))
	cn.create_tween().set_loops().tween_property(cn, "scale", Vector3.ONE * 0.85, 0.9).from(Vector3.ONE).set_trans(Tween.TRANS_SINE)
	# кабели от клетки по земле к теплотрассе: воровское подключение
	for k in 3:
		var from := core + Vector3(-5.8, 0.15, -3.0 + k * 3.0)
		var tgt := _w(4481, -452 + k * 10.0, 0.15)
		var d := tgt - from
		batch.add("site", Transform3D(Basis.looking_at(d.normalized(), Vector3.UP) * Basis.from_scale(Vector3(0.3, 0.3, d.length())), from + d / 2.0),
				Color(0.15, 0.12, 0.2))
		_b(batch, tgt + Vector3(0, 2.0, 0), Vector3(0.3, 4.0, 0.3), Color(0.15, 0.12, 0.2))
	_sign(batch, root, "СЧЁТ ЗА ОТОПЛЕНИЕ\nТУМАННОСТИ АНДРОМЕДА", "board", Color(0.1, 0.1, 0.1), core + Vector3(0, 2.0, 6.0), 0.0, 0.22,
			{"bg": Color(1, 1, 0.92), "far": DistrictDressing.SIGN_FAR_M})
	DistrictSites._alien(root, core + Vector3(-3, 0, 7), PI, rng)
	DistrictSites._person(root, core + Vector3(2, 0, 7.5), PI * 0.8, rng, {"top": Color(0.95, 0.55, 0.1)})
	# служебный контейнер
	var sv := _r(site, "DS_C2_service_container")
	var svc := DistrictSites._hall(root, sv, 4.0, false, Color(0.3, 0.5, 0.46), Color(0.25, 0.25, 0.27))
	_sign(batch, root, "АВАРИЙНАЯ\nСЛУЖБА · ОБЕД", "board", Color(0.1, 0.1, 0.1), svc + Vector3(-sv.size.x / 2.0 - 0.1, 2.6, 0), -90.0, 0.26,
			{"bg": Color(0.95, 0.95, 0.9)})
	for k in 4:
		DistrictSites._lantern(batch, _w(4420 + k * 54, -396))


# ---------- остальные сектора ----------

## A1 «Ржавый путь»: депо в бывшей котельной, пути, вагоны и ремонтные сараи.
static func _depot(root: Node3D, site: Dictionary, batch: DistrictDressing.Batch) -> void:
	var rng := _rng(3500)
	var r := _r(site, "DS_A1_boiler")
	var c := DistrictSites._hall(root, r, 15.0, true, BRICK)
	var front := c + Vector3(0, 0, r.size.y / 2.0)
	_sign(batch, root, "ДЕПО «РЖАВЫЙ ПУТЬ»\nПОЕЗДОВ НЕ БУДЕТ", "board", Color(0.95, 0.9, 0.8), front + Vector3(0, 8.0, 0.12), 0.0, 0.55,
			{"bg": Color(0.2, 0.22, 0.25), "lamp": true})
	for name in ["DS_A1_chimney", "DS_A1_chimney2"]:
		_chimney(root, batch, site, name, Color(0.4, 0.38, 0.36, 0.3))
	for k in 3:
		var x := -18.0 + k * 18.0
		_b(batch, front + Vector3(x, 3.0, 0.08), Vector3(6.0, 6.0, 0.15), Color(0.08, 0.07, 0.06))
		for sx: float in [-0.75, 0.75]:
			_b(batch, front + Vector3(x + sx, 0.08, 25.0), Vector3(0.12, 0.12, 50.0), Color(0.4, 0.36, 0.32))
		var z := 2.0
		while z < 50.0:
			_b(batch, front + Vector3(x, 0.04, z), Vector3(2.6, 0.08, 0.3), Color(0.3, 0.22, 0.16))
			z += 1.0
	for k in 2:
		var wagon := front + Vector3(-18.0 + k * 36.0, 0, 16.0 + k * 8.0)
		_b(batch, wagon + Vector3(0, 2.0, 0), Vector3(3.0, 3.0, 12.0), [RUST, Color(0.3, 0.38, 0.3)][k])
		_b(batch, wagon + Vector3(0, 3.6, 0), Vector3(3.1, 0.3, 12.2), RUST.darkened(0.3))
		Props.collider(root, Vector3(3.0, 3.6, 12.0), wagon + Vector3(0, 1.8, 0))
	_scrap_heap(batch, front + Vector3(28, 0, 12), Vector2(8, 6), rng, false)
	DistrictSites._person(root, front + Vector3(6, 0, 8), PI, rng, {"top": Color(0.95, 0.55, 0.1)})


## A2 «Вторчермет вселенной»: скупка корабельных деталей, весы, кран и горы лома.
static func _scrap(root: Node3D, site: Dictionary, batch: DistrictDressing.Batch) -> void:
	var rng := _rng(4500)
	var r := _r(site, "DS_A2_boiler")
	var c := DistrictSites._hall(root, r, 15.0, true, BRICK.darkened(0.1))
	var front := c + Vector3(0, 0, r.size.y / 2.0)
	_sign(batch, root, "ВТОРЧЕРМЕТ ВСЕЛЕННОЙ\nПРИНИМАЕМ ТАРЕЛКИ НА ВЕС", "board", Color(1.0, 0.9, 0.6), front + Vector3(0, 8.0, 0.12), 0.0,
			0.55, {"bg": Color(0.5, 0.12, 0.08), "lamp": true})
	for name in ["DS_A2_chimney", "DS_A2_chimney2"]:
		_chimney(root, batch, site, name, Color(0.4, 0.38, 0.36, 0.3))
	var scale := front + Vector3(0, 0, 14)
	_b(batch, scale + Vector3(0, 0.15, 0), Vector3(4.0, 0.3, 9.0), Color(0.35, 0.36, 0.38))
	_b(batch, scale + Vector3(3.2, 1.3, 0), Vector3(1.2, 2.6, 1.2), Color(0.85, 0.82, 0.75))
	_b(batch, scale + Vector3(3.81, 1.8, 0), Vector3(0.02, 0.4, 0.8), Color(0.3, 1.0, 0.5, 0.0), 0.0, "glow")
	batch.add("tank", Transform3D(Basis().scaled(Vector3(5.5, 1.0, 5.5)), scale + Vector3(0, 1.0, 0)), Color(0.55, 0.58, 0.64))
	_sign(batch, root, "ВЕС: 1 ТАРЕЛКА\nК ВЫПЛАТЕ: 300 ₽", "board", Color(0.1, 0.1, 0.1), scale + Vector3(3.2, 2.9, 0.62), 0.0, 0.16,
			{"bg": Color(1, 1, 0.92), "far": DistrictDressing.SIGN_FAR_M})
	for k in 3:
		_scrap_heap(batch, front + Vector3(-24 + k * 24, 0, 30), Vector2(10, 8), rng)
	var crane := front + Vector3(26, 0, 14)
	_b(batch, crane + Vector3(0, 7.0, 0), Vector3(0.8, 14.0, 0.8), YELLOW)
	_b(batch, crane + Vector3(-6, 14.0, 0), Vector3(14.0, 0.7, 0.7), YELLOW)
	_b(batch, crane + Vector3(-11, 10.5, 0), Vector3(0.05, 7.0, 0.05), Color(0.2, 0.2, 0.2))
	_b(batch, crane + Vector3(-11, 7.0, 0), Vector3(1.8, 0.4, 1.8), Color(0.3, 0.3, 0.32))
	Props.collider(root, Vector3(1.0, 14.0, 1.0), crane + Vector3(0, 7.0, 0))
	DistrictSites._alien(root, scale + Vector3(-3, 0, 0), PI / 2.0, rng)


## A3 «Последний адрес»: кладбищенская контора у ржавого колеса и надгробие флоту.
static func _cemetery(root: Node3D, site: Dictionary, batch: DistrictDressing.Batch) -> void:
	var rng := _rng(5500)
	var sup := _c(_r(site, "DS_A3_wheel_support"))
	var hub := sup + Vector3(0, 28.0, 0)
	# колесо: обод из 24 звеньев в плоскости X-Y, спицы, кабинки внизу обода, две опоры А
	for i in 24:
		var a0 := TAU * i / 24.0
		var a1 := TAU * (i + 1) / 24.0
		var p0 := Vector3(cos(a0) * 25.0, sin(a0) * 25.0, 0)
		var p1 := Vector3(cos(a1) * 25.0, sin(a1) * 25.0, 0)
		var d := p1 - p0
		batch.add("site", Transform3D(Basis(Vector3.BACK, atan2(d.y, d.x)) * Basis.from_scale(Vector3(d.length() + 0.2, 0.5, 0.5)), hub + p0 + d / 2.0),
				RUST)
		if i % 2 == 0:
			batch.add("site", Transform3D(Basis(Vector3.BACK, a0) * Basis.from_scale(Vector3(25.0, 0.2, 0.2)), hub + p0 / 2.0), RUST.darkened(0.2))
	for o in _all(site, "DS_A3_wheel_cabin"):
		var cr := DistrictSites._r(o)
		var cz: Array = o.z
		_b(batch, _c(cr, (float(cz[0]) + float(cz[1])) / 2.0 - 1.0), Vector3(3.0, 2.6, 2.6), Color(0.55, 0.2, 0.15).darkened(rng.randf() * 0.3))
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var foot := sup + Vector3(sx * 9.0, 0, sz * 3.0)
			var d := hub - foot
			batch.add("site", Transform3D(Basis.looking_at(d.normalized(), Vector3.UP) * Basis.from_scale(Vector3(0.6, 0.6, d.length())), foot + d / 2.0),
					RUST.darkened(0.1))
			Props.collider(root, Vector3(1.0, 4.0, 1.0), foot + Vector3(0, 2.0, 0))
	_sign(batch, root, "КОЛЕСО ПОСЛЕДНЕГО ПУТИ\nКРУГ — 0 ₽, ОБРАТНО — ДОРОЖЕ", "board", Color(0.95, 0.9, 0.8), sup + Vector3(0, 3.0, 4.0), 0.0,
			0.36, {"bg": Color(0.15, 0.15, 0.17), "lamp": true})
	# «надгробие флоту»: тарелка лежит на постаменте с венками
	var u := _c(_r(site, "DS_A3_fake_ufo"))
	_b(batch, u + Vector3(0, 0.6, 0), Vector3(22, 1.2, 22), Color(0.5, 0.5, 0.52))
	batch.add("tank", Transform3D(Basis().scaled(Vector3(20, 1.8, 20)), u + Vector3(0, 2.2, 0)), Color(0.55, 0.58, 0.64))
	batch.add("crown", Transform3D(Basis().scaled(Vector3(7, 3.4, 7)), u + Vector3(0, 3.4, 0)), Color(0.45, 0.6, 0.7))
	Props.collider(root, Vector3(22, 4.0, 22), u + Vector3(0, 2.0, 0))
	_sign(batch, root, "ЗДЕСЬ ПОКОИТСЯ\nФЛОТ ВТОРЖЕНИЯ\nПРИЛЕТЕЛ НЕ ВОВРЕМЯ", "board", Color(0.9, 0.88, 0.8), u + Vector3(0, 1.0, 11.1), 0.0,
			0.36, {"bg": Color(0.2, 0.2, 0.22)})
	for k in 6:
		var a := TAU * k / 6.0
		var wr := u + Vector3(cos(a) * 12.5, 0.5, sin(a) * 12.5)
		batch.add("veg", Transform3D(Basis().scaled(Vector3(1.0, 1.0, 0.3)), wr), [Color(0.2, 0.45, 0.2), Color(0.8, 0.2, 0.25)][k % 2])
	# участки: оградки, кресты и плиты рядами
	for gx in 8:
		for gy in 4:
			var p := sup + Vector3(-40.0 + gx * 5.0, 0, 16.0 + gy * 6.0)
			var col := Color(0.25, 0.25, 0.27) if (gx + gy) % 3 else Color(0.35, 0.45, 0.55)
			for s2: float in [-1.0, 1.0]:
				_b(batch, p + Vector3(s2 * 1.5, 0.4, 0), Vector3(0.05, 0.8, 3.0), col)
				_b(batch, p + Vector3(0, 0.4, s2 * 1.5), Vector3(3.0, 0.8, 0.05), col)
			if (gx * 3 + gy) % 2 == 0:
				_b(batch, p + Vector3(0, 0.8, -1.0), Vector3(0.12, 1.6, 0.12), Color(0.5, 0.5, 0.5))
				_b(batch, p + Vector3(0, 1.2, -1.0), Vector3(0.8, 0.12, 0.12), Color(0.5, 0.5, 0.5))
			else:
				_b(batch, p + Vector3(0, 0.55, -1.0), Vector3(1.0, 1.1, 0.2), Color(0.42, 0.42, 0.45))
	DistrictSites._person(root, sup + Vector3(-12, 0, 13), 0.0, rng, DelovoySites.GRANNY)


## B1 «Общежитие согласных»: общежитие, двор мутантов, бывшая столовая.
static func _dorm(root: Node3D, site: Dictionary, batch: DistrictDressing.Batch) -> void:
	var rng := _rng(3501)
	var r := _r(site, "DS_B1_main")
	var c := DistrictSites._hall(root, r, 12.0, false, Color(0.75, 0.7, 0.58), Color(0.3, 0.3, 0.32), true)
	var front := c + Vector3(0, 0, r.size.y / 2.0)
	_sign(batch, root, "ОБЩЕЖИТИЕ СОГЛАСНЫХ", "letters", Color(1.0, 0.85, 0.5), front + Vector3(0, 13.0, 0.15), 0.0, 0.9)
	_sign(batch, root, "НЕСОГЛАСНЫХ\nНЕ ЗАСЕЛЯЕМ", "board", Color(0.1, 0.1, 0.1), front + Vector3(-14, 2.4, 0.12), 0.0, 0.3,
			{"bg": Color(0.95, 0.95, 0.9), "lamp": true})
	_sign(batch, root, "СТОЛОВАЯ (БЫВШ.)\nКОМПОТ — ПО ТАЛОНАМ", "board", Color(0.1, 0.1, 0.1), front + Vector3(14, 2.4, 0.12), 0.0, 0.3,
			{"bg": Color(0.95, 0.9, 0.8)})
	for k in 3:
		var tb := front + Vector3(-10 + k * 10, 0, 12)
		_b(batch, tb + Vector3(0, 0.75, 0), Vector3(2.4, 0.08, 1.0), Color(0.6, 0.5, 0.35))
		DistrictSites._alien(root, tb + Vector3(0, 0, -1.0), 0.0, rng)
		DistrictSites._person(root, tb + Vector3(0, 0, 1.0), PI, rng)
	DistrictDressing._playground(batch, front + Vector3(22, 0, 16), 0.0, rng)


## B3 «Баня преображения»: баня в старой котельной, пар из труб, очередь с вениками.
static func _bath(root: Node3D, site: Dictionary, batch: DistrictDressing.Batch) -> void:
	var rng := _rng(5501)
	var r := _r(site, "DS_B3_boiler")
	var c := DistrictSites._hall(root, r, 15.0, true, BRICK)
	var front := c + Vector3(0, 0, r.size.y / 2.0)
	_sign(batch, root, "БАНЯ ПРЕОБРАЖЕНИЯ\nВЫХОДИТЕ ДРУГИМ ВИДОМ", "lightbox", Color(0.1, 0.25, 0.4), front + Vector3(0, 8.0, 0.12), 0.0, 0.55,
			{"bg": Color(0.92, 0.96, 1.0)})
	for name in ["DS_B3_chimney", "DS_B3_chimney2"]:
		_chimney(root, batch, site, name, Color(0.95, 0.95, 0.95, 0.45))
	for k in 6:
		DistrictSites._person(root, front + Vector3(-6 + k * 1.2, 0, 3.5), PI, rng, {"top": Color(0.95, 0.95, 0.92)})
	var steam := Kit.particles(root, front + Vector3(0, 3.0, 0.5), Color(0.95, 0.95, 0.95, 0.35), 16, 3.5, Vector3(0, 1.5, 1.0), 0.4, 3.0)
	steam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## C3 «Последний сток»: канал, сараи брошенного поста эвакуации.
static func _canal(root: Node3D, site: Dictionary, batch: DistrictDressing.Batch) -> void:
	var rng := _rng(5502)
	var first := Vector3.ZERO
	for i in 4:
		var r := _r(site, "DS_C3%d" % i)
		var c := DistrictSites._hall(root, r, 4.0, false, Color(0.32, 0.45, 0.42), Color(0.25, 0.25, 0.27))
		if i == 0:
			first = c
	# канал вдоль сараев: тёмная вода, бетонные борта, мостки
	var canal := first + Vector3(30, 0, 36)
	_b(batch, canal + Vector3(0, 0.03, 0), Vector3(90, 0.02, 8), Color(0.12, 0.18, 0.2), 0.0, "plain")
	for sz: float in [-1.0, 1.0]:
		_b(batch, canal + Vector3(0, 0.3, sz * 4.3), Vector3(90, 0.6, 0.6), Color(0.55, 0.54, 0.5))
		Props.collider(root, Vector3(90, 1.0, 0.6), canal + Vector3(0, 0.5, sz * 4.3))
	_b(batch, canal + Vector3(-10, 0.6, 0), Vector3(3.0, 0.2, 9.2), Color(0.4, 0.3, 0.2))
	_sign(batch, root, "ПОСТ ЭВАКУАЦИИ\nЗАКРЫТ НА ЭВАКУАЦИЮ", "board", Color(0.1, 0.1, 0.1), first + Vector3(-6.5, 2.2, 20), -90.0, 0.32,
			{"bg": Color(0.98, 0.9, 0.3), "lamp": true})
	DistrictSites._alien(root, canal + Vector3(5, 0, -6), 0.0, rng)
