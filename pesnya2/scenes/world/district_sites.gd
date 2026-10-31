class_name DistrictSites
extends RefCounted
## Площадки и ориентиры секторов по макету «Рубин» (0.11, D-051). Объёмы, места и размеры —
## из пакета (data/pogulyay_layout.json → sites), облик — по концептам 02_market и 03_square:
##   market   — рынок «Сытый конец»: павильон с красно-кремовой сводчатой крышей, ряды
##              с навесами, ворота с вывеской, склады, продавец взвешивает реактор;
##   square   — площадь с тарелкой: МФЦ с колоннами, разбившаяся тарелка на крыше, очередь
##              за талонами, памятник на клумбе, копицентр, архив, вагончик регистрации;
##   park     — колесо обозрения и пенопластовое НЛО; theatre — театр «Овация»;
##   showcase — показательный ЖК с тарелкой на крыше; workshops — мастерские «Без лица»;
##   tv       — телецентр с мачтой; boiler — котельная с двумя трубами.
## Мелочь — коробки участка (Batch, один MultiMesh), корпуса — BuildingKit.block с телом-окклюдером.

const CREAM := Color(0.86, 0.78, 0.6)
const RED := Color(0.72, 0.16, 0.12)
const AWNINGS := [Color(0.72, 0.16, 0.12), Color(0.16, 0.48, 0.36), Color(0.2, 0.36, 0.6), Color(0.85, 0.55, 0.15)]
const WARM := Color(1.0, 0.78, 0.45)


## Сдвиг окна площадки (0.17, компактный город): код площадок считает в исходных метрах
## плана «Рубин», sw() переводит их в мир через окно сектора. На время build — сдвиг этой площадки.
static var shift := Vector2.ZERO


static func sw(p: Vector2, h := 0.0) -> Vector3:
	return District.to_world(p + shift, h)


static func build(root: Node3D, site: Dictionary, batch: DistrictDressing.Batch) -> void:
	shift = District.site_shift(site)
	_build(root, site, batch)
	shift = Vector2.ZERO


static func _build(root: Node3D, site: Dictionary, batch: DistrictDressing.Batch) -> void:
	if String(site.id).begins_with("dl_"):
		DelovoySites.build(root, site, batch)
		return
	if String(site.id).begins_with("ds_"):
		DosvidSites.build(root, site, batch)
		return
	match String(site.id):
		"market":
			_market(root, site, batch)
		"square":
			_square(root, site, batch)
		"park":
			_park(root, site, batch)
		"theatre":
			_theatre(root, site, batch)
		"showcase":
			_showcase(root, site, batch)
		"workshops":
			_workshops(root, site, batch)
		"tv":
			_tv(root, site, batch)
		"boiler":
			_boiler(root, site, batch)


# ---------- общее ----------

static func _o(site: Dictionary, name: String) -> Dictionary:
	for o in site.objects:
		if o.name == name:
			return o
	return {}


static func _all(site: Dictionary, prefix: String) -> Array:
	return site.objects.filter(func(o: Dictionary) -> bool: return String(o.name).begins_with(prefix))


static func _r(o: Dictionary) -> Rect2:
	var r: Array = o.r
	return Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))


static func _w(x: float, y: float, h := 0.0) -> Vector3:
	return DistrictSites.sw(Vector2(x, y), h)


static func _b(batch: DistrictDressing.Batch, center: Vector3, size: Vector3, color: Color, yaw := 0.0, kind := "site") -> void:
	batch.box(kind, center, size, yaw, color)


## Корпус: сетка BuildingKit.block и тело-окклюдер (камера вырезает его перед героем).
static func _hall(root: Node3D, r: Rect2, h: float, brick: bool, wall: Color, roof := Color(0.3, 0.3, 0.32),
		shops := false) -> Vector3:
	var c := DistrictSites.sw(r.get_center())
	var body := Props.collider(root, Vector3(r.size.x, h, r.size.y), c + Vector3(0, h / 2.0, 0), true)
	var mi := MeshInstance3D.new()
	mi.mesh = BuildingKit.block(r.size.x, r.size.y, h, brick, wall, roof, shops)
	mi.position = Vector3(0, -h / 2.0, 0)
	body.add_child(mi)
	return c


## Плитка площади: светлые плиты (текстура участка), поверх дороги и земли.
static func _paving(batch: DistrictDressing.Batch, r: Rect2, y := 0.035) -> void:
	batch.box("path", DistrictSites.sw(r.get_center(), y), Vector3(r.size.x, 0.04, r.size.y))


static func _person(root: Node3D, pos: Vector3, yaw: float, rng: RandomNumberGenerator, look := {}) -> Node3D:
	var l := NpcModel.random_look(rng)
	l.merge(look, true)
	var m := NpcModel.make(l)
	m.position = pos
	m.rotation.y = yaw
	root.add_child(m)
	return m


## Пришелец в толпе: зелёная или синяя кожа, большая голова, рабочая жилетка.
static func _alien(root: Node3D, pos: Vector3, yaw: float, rng: RandomNumberGenerator, big := false) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	n.rotation.y = yaw
	root.add_child(n)
	var skin: Color = [Color(0.45, 0.78, 0.5), Color(0.35, 0.6, 0.85), Color(0.6, 0.45, 0.8)][rng.randi() % 3]
	var k := 1.35 if big else 1.0
	Kit.capsule(n, 0.3 * k, 0.9 * k, Vector3(0, 0.8 * k, 0), Color(0.25, 0.25, 0.3) if not big else Color(0.2, 0.18, 0.26))
	Kit.sphere(n, 0.36 * k, Vector3(0, 1.55 * k, 0), skin)
	for side in [-1, 1]:
		Kit.sphere(n, 0.11 * k, Vector3(side * 0.13 * k, 1.6 * k, 0.29 * k), Color(0.04, 0.04, 0.08))
	if big:
		# броня захватчика: светящиеся вставки
		for i in 3:
			Kit.box(n, Vector3(0.7, 0.08, 0.5), Vector3(0, 0.6 + i * 0.3, 0), Color(0.6, 0.3, 1.0), 2.0)
	else:
		Kit.box(n, Vector3(0.62, 0.5, 0.05), Vector3(0, 1.0, 0.25), Color(0.95, 0.85, 0.15))
	return n


static func _sign(batch: DistrictDressing.Batch, root: Node3D, text: String, kind: String, color: Color, pos: Vector3,
		yaw_deg: float, height: float, opts := {}) -> void:
	var o := opts.duplicate()
	if not o.has("far"):
		o.far = DistrictDressing.ROOF_SIGN_FAR_M
	batch.sign(root, text, kind, color, pos, yaw_deg, height, o)


## Тёплая гирлянда между двумя точками: провод и лампочки, одна лампа — настоящий свет.
static func _garland(batch: DistrictDressing.Batch, a: Vector3, b: Vector3, step := 1.1, light := true) -> void:
	var d := b - a
	var n := maxi(2, int(d.length() / step))
	for i in n + 1:
		var t := float(i) / n
		var p := a.lerp(b, t) + Vector3(0, -0.45 * sin(t * PI), 0)
		_b(batch, p, Vector3(0.12, 0.14, 0.12), WARM, 0.0, "glow")
	var mid := a.lerp(b, 0.5) + Vector3(0, -0.45, 0)
	_b(batch, mid, Vector3(0.03, 0.03, d.length()), Color(0.1, 0.1, 0.1), atan2(d.x, d.z))
	if light:
		batch.lamps.append(mid)


static func _lantern(batch: DistrictDressing.Batch, at: Vector3) -> void:
	_b(batch, at + Vector3(0, 1.9, 0), Vector3(0.14, 3.8, 0.14), Color(0.15, 0.15, 0.16))
	_b(batch, at + Vector3(0, 0.3, 0), Vector3(0.4, 0.6, 0.4), Color(0.15, 0.15, 0.16))
	_b(batch, at + Vector3(0, 4.0, 0), Vector3(0.45, 0.55, 0.45), WARM, 0.0, "glow")
	_b(batch, at + Vector3(0, 4.35, 0), Vector3(0.6, 0.12, 0.6), Color(0.12, 0.12, 0.13))
	batch.add("pool", Transform3D(Basis().scaled(Vector3(9, 1, 9)), at + Vector3(0, 0.07, 0)), Color(0.85, 0.65, 0.4))
	batch.lamps.append(at + Vector3(0, 3.9, 0))


static func _tree_row(batch: DistrictDressing.Batch, site: Dictionary, prefix: String) -> void:
	for o in _all(site, prefix):
		var r := _r(o)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(Vector2i(int(r.position.x), int(r.position.y)))
		DistrictDressing._tree(batch, DistrictSites.sw(r.get_center()), rng, 1.4)


# ---------- рынок «Сытый конец» ----------

static func _market(root: Node3D, site: Dictionary, batch: DistrictDressing.Batch) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2600
	_paving(batch, _r(_o(site, "PG_C2_courtyard_paving")))
	_tree_row(batch, site, "PG_C2_boundary_tree_trunk")
	# павильон: кирпичные стены с витринами и сводчатая крыша полосами красного и крема
	var hall := _r(_o(site, "PG_C2_market_hall"))
	var hc := _hall(root, hall, 5.5, true, Color(0.62, 0.32, 0.24), Color(0.3, 0.2, 0.18), true)
	var bands := 10
	var segs := 10
	var rz := hall.size.y / 2.0 + 0.6
	var ry := 6.5
	for i in bands:
		var x0 := -hall.size.x / 2.0 - 0.5 + (hall.size.x + 1.0) * i / bands
		var bw := (hall.size.x + 1.0) / bands
		var col := RED if i % 2 == 0 else Color(0.9, 0.86, 0.76)
		for j in segs:
			var t0 := PI * j / segs
			var t1 := PI * (j + 1) / segs
			var p0 := Vector3(0, ry * sin(t0), -rz * cos(t0))
			var p1 := Vector3(0, ry * sin(t1), -rz * cos(t1))
			var mid := (p0 + p1) / 2.0
			var tilt := atan2(p1.y - p0.y, p1.z - p0.z)
			var basis := Basis(Vector3.RIGHT, -tilt) * Basis.from_scale(Vector3(bw, 0.25, p0.distance_to(p1) + 0.05))
			batch.add("site", Transform3D(basis, hc + Vector3(x0 + bw / 2.0, 5.5 + mid.y, mid.z)), col.darkened(0.05 * (j % 2)))
	# торцы свода: кремовые полукруги со световым окном-«веером»
	for side: float in [-1.0, 1.0]:
		for j in 8:
			var z := -rz + (2.0 * rz) * (j + 0.5) / 8.0
			var top := ry * sqrt(maxf(0.0, 1.0 - pow(z / rz, 2.0)))
			_b(batch, hc + Vector3(side * hall.size.x / 2.0, 5.5 + top / 2.0, z), Vector3(0.3, top, 2.0 * rz / 8.0 + 0.05),
					Color(0.88, 0.84, 0.74))
		_b(batch, hc + Vector3(side * (hall.size.x / 2.0 + 0.16), 8.4, 0), Vector3(0.05, 2.4, 8.0), Color(1.0, 0.8, 0.5, 0.4), 0.0, "glow")
	# вход павильона на юг: козырёк, лампы, буквы
	var door := _w(1500, hall.end.y)
	_b(batch, door + Vector3(0, 3.2, 1.2), Vector3(8, 0.25, 2.6), Color(0.35, 0.32, 0.3))
	_sign(batch, root, "РЫНОК", "letters", Color(1.0, 0.85, 0.5), door + Vector3(0, 4.5, 0.2), 0.0, 1.6)
	_sign(batch, root, "СЕГОДНЯ ДЕШЕВЛЕ,\nЧЕМ ЗАВТРА", "poster", RED, door + Vector3(-12, 3.4, 0.08), 0.0, 0.42,
			{"bg": Color(0.95, 0.92, 0.85)})
	_garland(batch, door + Vector3(-20, 5.3, 0.4), door + Vector3(20, 5.3, 0.4))
	# склады: западный корпус и складской двор на востоке
	var flank := _r(_o(site, "PG_C2_west_flank"))
	var fc := _hall(root, flank, 9.0, true, Color(0.55, 0.3, 0.22))
	_sign(batch, root, "ПИЩЕВЫЕ СКЛАДЫ\n«ДО ПОСЛЕДНЕЙ КРОШКИ»", "board", Color(0.95, 0.9, 0.8),
			fc + Vector3(flank.size.x / 2.0 + 0.05, 6.5, 0), 90.0, 0.55, {"bg": Color(0.25, 0.22, 0.2), "lamp": true})
	_sign(batch, root, "ИНОПЛАНЕТНЫЕ ЗАПЧАСТИ\nОПТОМ И В РОЗНИЦУ", "lightbox", Color(0.15, 0.9, 0.7),
			fc + Vector3(flank.size.x / 2.0 + 0.05, 4.2, -26), 90.0, 0.5, {"bg": Color(0.08, 0.12, 0.16), "ink": Color(0.3, 1.0, 0.8)})
	_sign(batch, root, "РЫНОК ЖИВ ♥", "graffiti", Color(0.95, 0.9, 0.85), fc + Vector3(flank.size.x / 2.0 + 0.05, 2.0, 30), 90.0, 0.7)
	var store := _r(_o(site, "PG_C2_market_store"))
	var sc := _hall(root, store, 6.0, false, Color(0.78, 0.72, 0.6))
	_sign(batch, root, "СКЛАДСКОЙ ДВОР\nВЪЕЗД ДЛЯ СВОИХ", "board", Color(0.1, 0.1, 0.1), sc + Vector3(-store.size.x / 2.0 - 0.05, 3.8, 0),
			-90.0, 0.4, {"bg": Color(0.95, 0.8, 0.2)})
	for i in 4:
		batch.model("boxes", sc + Vector3(-store.size.x / 2.0 - 3.0, 0, -12 + i * 7), rng.randf() * TAU)
	# торговые ряды: навес, прилавок, товар, продавец
	var stalls := _all(site, "PG_C2_market_stall_")
	var goods := [["КАПУСТА 30", Color(0.5, 0.75, 0.3)], ["КАРТОШКА 25", Color(0.75, 0.6, 0.35)],
		["КОЛБАСА 90", Color(0.65, 0.2, 0.15)], ["ЯБЛОКИ 40", Color(0.85, 0.2, 0.15)], ["МОРКОВЬ 20", Color(0.95, 0.5, 0.15)],
		["СВЁКЛА 15", Color(0.5, 0.12, 0.2)]]
	for i in stalls.size():
		var st: Dictionary = stalls[i]
		var r := _r(st)
		var c := DistrictSites.sw(r.get_center())
		var awn: Color = RED if st.mat == "red" else AWNINGS[1 + (i % 3)]
		var alien_parts := i == 7 or i == 10
		for sx: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				_b(batch, c + Vector3(sx * (r.size.x / 2.0 - 0.2), 1.4, sz * (r.size.y / 2.0 - 0.2)), Vector3(0.1, 2.8, 0.1),
						Color(0.3, 0.3, 0.32))
		batch.add("site", Transform3D(Basis(Vector3.RIGHT, -0.18) * Basis.from_scale(Vector3(r.size.x + 0.6, 0.08, r.size.y + 0.4)),
				c + Vector3(0, 3.0, 0)), awn)
		_b(batch, c + Vector3(0, 2.75, r.size.y / 2.0 + 0.15), Vector3(r.size.x + 0.6, 0.35, 0.05), awn.darkened(0.2))
		# прилавок к проходу (юг) и ящики с товаром
		_b(batch, c + Vector3(0, 0.5, r.size.y / 2.0 - 0.6), Vector3(r.size.x - 0.6, 1.0, 1.2), Color(0.45, 0.32, 0.2))
		var good: Array = goods[i % goods.size()]
		for k in 5:
			var crate := c + Vector3(-r.size.x / 2.0 + 1.0 + k * 1.5, 1.15, r.size.y / 2.0 - 0.6)
			_b(batch, crate, Vector3(1.2, 0.3, 0.9), Color(0.55, 0.4, 0.25))
			if alien_parts:
				_b(batch, crate + Vector3(0, 0.3, 0), Vector3(0.8, 0.25, 0.5), Color(0.6, 0.3, 1.0), rng.randf() * 0.6, "glow")
			else:
				for q in 3:
					batch.add("veg", Transform3D(Basis().scaled(Vector3.ONE * 0.36),
							crate + Vector3(-0.35 + q * 0.35, 0.28, rng.randf_range(-0.2, 0.2))), Color(good[1]).darkened(rng.randf() * 0.2))
		# гирлянда под навесом
		_garland(batch, c + Vector3(-r.size.x / 2.0, 2.6, r.size.y / 2.0), c + Vector3(r.size.x / 2.0, 2.6, r.size.y / 2.0), 1.1, i % 3 == 0)
		if alien_parts:
			_sign(batch, root, "ИНОПЛАНЕТНЫЕ\nЗАПЧАСТИ\nОПТОМ И В РОЗНИЦУ", "chalk", Color(0.95, 0.95, 0.9),
					c + Vector3(0, 2.0, r.size.y / 2.0 + 0.3), 0.0, 0.26, {"far": DistrictDressing.SIGN_FAR_M})
		else:
			_sign(batch, root, String(good[0]), "chalk", Color(0.95, 0.95, 0.9), c + Vector3(r.size.x / 2.0 - 1.0, 1.5,
					r.size.y / 2.0 + 0.1), 0.0, 0.22, {"far": DistrictDressing.SIGN_FAR_M})
		if i % 2 == 0 or alien_parts:
			_person(root, c + Vector3(rng.randf_range(-2, 2), 0, r.size.y / 2.0 - 1.8), 0.0, rng,
					{"skirt": rng.randf() < 0.5, "style": "scarf" if rng.randf() < 0.4 else "short"})
	# «Захватчикам без сдачи»: растяжка над рядами, продавец взвешивает реактор
	var mid_row := DistrictSites.sw(Vector2(1500, 2640))
	_sign(batch, root, "ЗАХВАТЧИКАМ\nБЕЗ СДАЧИ", "poster", RED, mid_row + Vector3(18, 3.6, -6.3), 0.0, 0.6,
			{"bg": Color(0.97, 0.93, 0.85)})
	var scales := DistrictSites.sw(Vector2(1518, 2626))
	_b(batch, scales + Vector3(0, 1.25, 0), Vector3(0.9, 0.3, 0.6), Color(0.85, 0.85, 0.82))
	_b(batch, scales + Vector3(0, 1.45, 0), Vector3(0.7, 0.05, 0.7), Color(0.7, 0.7, 0.72))
	batch.add("glow", Transform3D(Basis().scaled(Vector3.ONE * 0.6), scales + Vector3(0, 1.8, 0)), Color(0.3, 0.9, 1.0))
	_alien(root, scales + Vector3(1.6, 0, 2.0), -2.4, rng, true)
	_sign(batch, root, "РЕАКТОР Б/У · ВЗВЕСИМ ЧЕСТНО", "chalk", Color(0.95, 0.95, 0.9), scales + Vector3(0, 2.4, 0.4), 0.0, 0.2,
			{"far": DistrictDressing.SIGN_FAR_M})
	# покупатели в проходах
	for k in 9:
		var p := DistrictSites.sw(Vector2(rng.randf_range(1460, 1540), [2610.0, 2627.0, 2643.0, 2660.0][k % 4]))
		if k == 4:
			_alien(root, p, rng.randf() * TAU, rng)
		else:
			_person(root, p, rng.randf() * TAU, rng)
	# вход в торговый коллектор — будущая сцена
	var hatch := DistrictSites.sw(Vector2(1440, 2668))
	batch.add("tank", Transform3D(Basis().scaled(Vector3(1.6, 0.12, 1.6)), hatch + Vector3(0, 0.06, 0)), Color(0.18, 0.18, 0.2))
	_sign(batch, root, "ТОРГОВЫЙ КОЛЛЕКТОР\nВХОД ПО ПРОПУСКАМ", "board", Color(0.95, 0.9, 0.2), hatch + Vector3(0, 1.4, -1.2), 0.0,
			0.22, {"bg": Color(0.15, 0.15, 0.17), "far": DistrictDressing.SIGN_FAR_M})
	_b(batch, hatch + Vector3(0, 0.7, -1.2), Vector3(0.08, 1.4, 0.08), Color(0.3, 0.3, 0.32))
	# ворота «Сытый конец» и ограда двора с юга
	var gl := _r(_o(site, "PG_C2_market_gate_l"))
	var gr := _r(_o(site, "PG_C2_market_gate_r"))
	var gate := DistrictSites.sw((gl.get_center() + gr.get_center()) / 2.0)
	var half := gate.distance_to(DistrictSites.sw(gl.get_center()))
	for side: float in [-1.0, 1.0]:
		var post := gate + Vector3(side * half, 0, 0)
		_b(batch, post + Vector3(0, 3.0, 0), Vector3(0.5, 6.0, 0.5), Color(0.25, 0.22, 0.2))
		Props.collider(root, Vector3(0.5, 6.0, 0.5), post + Vector3(0, 3.0, 0))
		_b(batch, post + Vector3(-side * 1.8, 1.3, 0), Vector3(3.2, 2.6, 0.08), Color(0.2, 0.2, 0.22))     # створки распахнуты
	_b(batch, gate + Vector3(0, 6.1, 0), Vector3(half * 2.0 + 1.0, 0.4, 0.4), Color(0.25, 0.22, 0.2))
	_sign(batch, root, "СЫТЫЙ КОНЕЦ", "lightbox", RED, gate + Vector3(0, 6.9, 0.3), 0.0, 0.95,
			{"bg": Color(0.97, 0.93, 0.85), "ink": RED, "lamp": false})
	_garland(batch, gate + Vector3(-half, 5.4, 0.3), gate + Vector3(half, 5.4, 0.3), 0.6)
	var x := 1410.0
	while x < 1590.0:
		if absf(x - 1500.0) > half + 1.0:
			batch.model("fence", DistrictSites.sw(Vector2(x, 2700)), 0.0, 0.7)
		x += 2.0
	for k in 6:
		_lantern(batch, DistrictSites.sw(Vector2(1420 + k * 32, 2604)))


# ---------- площадь с тарелкой ----------

static func _square(root: Node3D, site: Dictionary, batch: DistrictDressing.Batch) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1500
	_paving(batch, _r(_o(site, "PG_B2_courtyard_paving")))
	_paving(batch, _r(_o(site, "PG_B2_mfc_plaza")), 0.045)
	# светлые полосы гранита сеткой 20 м и кольцо вокруг памятника: площадь не сливается в одно поле
	var pav := _r(_o(site, "PG_B2_courtyard_paving"))
	var gx := pav.position.x + 12.0
	while gx < pav.end.x - 6.0:
		_b(batch, _w(gx, pav.get_center().y, 0.058), Vector3(1.0, 0.03, pav.size.y - 4.0), Color(0.4, 0.37, 0.33), 0.0, "paint")
		gx += 20.0
	var gy := pav.position.y + 12.0
	while gy < pav.end.y - 6.0:
		_b(batch, _w(pav.get_center().x, gy, 0.058), Vector3(pav.size.x - 4.0, 0.03, 1.0), Color(0.4, 0.37, 0.33), 0.0, "paint")
		gy += 20.0
	_tree_row(batch, site, "PG_B2_town_tree_trunk")
	# МФЦ: кремовая классика, портик из шести колонн, фронтон, лестница
	var mfc := _r(_o(site, "PG_B2_mfc_office"))
	var mc := _hall(root, mfc, 12.0, false, CREAM, Color(0.36, 0.34, 0.32))
	var front := mc + Vector3(0, 0, mfc.size.y / 2.0)
	for i in 6:
		var x := -12.5 + i * 5.0
		batch.add("tank", Transform3D(Basis().scaled(Vector3(1.2, 9.0, 1.2)), front + Vector3(x, 4.8, 2.6)), Color(0.9, 0.86, 0.76))
		_b(batch, front + Vector3(x, 0.45, 2.6), Vector3(1.6, 0.5, 1.6), Color(0.8, 0.76, 0.68))
	_b(batch, front + Vector3(0, 9.9, 2.4), Vector3(30, 1.2, 4.2), Color(0.88, 0.83, 0.72))
	for k in 5:
		var w := 30.0 - k * 6.0
		_b(batch, front + Vector3(0, 10.75 + k * 0.6, 2.2), Vector3(w, 0.6, 3.6), Color(0.86, 0.8, 0.68).darkened(k * 0.02))
	_b(batch, front + Vector3(0, 11.6, 4.05), Vector3(2.4, 1.6, 0.1), Color(0.75, 0.62, 0.35))           # герб
	for k in 3:
		_b(batch, front + Vector3(0, 0.15 + k * 0.3, 5.6 - k * 0.8), Vector3(32, 0.3, 1.6 + k * 0.8), Color(0.62, 0.6, 0.56))
	Props.collider(root, Vector3(32, 1.0, 4), front + Vector3(0, 0.5, 4.5))
	_sign(batch, root, "ВТОРЖЕНИЕ ПО ТАЛОНАМ", "poster", RED, front + Vector3(0, 7.4, 3.4), 0.0, 0.85,
			{"bg": Color(0.95, 0.93, 0.88), "font": "block", "tilt": 0.0})
	_sign(batch, root, "ВАША\nПЛАНЕТА\nНЕ В ТОЙ\nФОРМЕ", "poster", Color(0.12, 0.12, 0.14), front + Vector3(-25, 6.5, 0.1), 0.0, 0.8,
			{"bg": Color(0.93, 0.9, 0.84), "font": "block", "tilt": 0.0})
	_sign(batch, root, "ТРУД\nТАЛОН\nКОНТАКТ", "poster", Color(0.12, 0.12, 0.14), front + Vector3(25, 6.5, 0.1), 0.0, 0.8,
			{"bg": Color(0.9, 0.88, 0.82), "font": "block", "tilt": 0.0})
	_sign(batch, root, "ОКНО 3", "neon", Color(1.0, 0.2, 0.15), front + Vector3(0, 3.6, 0.15), 0.0, 0.45)
	_sign(batch, root, "ИНФОРМАЦИЯ", "board", Color(0.1, 0.1, 0.1), front + Vector3(-8, 1.8, 3.5), 0.0, 0.28,
			{"bg": Color(0.92, 0.92, 0.9), "lamp": true})
	_sign(batch, root, "МФЦ «ОКНО № 0»", "letters", Color(1.0, 0.85, 0.5), front + Vector3(0, 13.9, 2.4), 0.0, 1.0)
	# тарелка: рухнула на восточное крыло, опирается на леса
	var ufo_o := _r(_o(site, "PG_B2_mfc_ufo"))
	var ufo := Node3D.new()
	ufo.name = "CrashedUfo"
	ufo.position = DistrictSites.sw(ufo_o.get_center(), 14.5)
	ufo.rotation_degrees = Vector3(14, 25, -18)
	root.add_child(ufo)
	Kit.cylinder(ufo, 17.0, 2.4, Vector3.ZERO, Color(0.3, 0.32, 0.37), 0.0, 14.5)
	Kit.cylinder(ufo, 13.5, 0.5, Vector3(0, 1.4, 0), Color(0.22, 0.24, 0.28), 0.0, 12.5)         # верхнее кольцо брони
	Kit.cylinder(ufo, 9.5, 0.4, Vector3(0, 1.8, 0), Color(0.45, 0.47, 0.52), 0.0, 9.0)
	Kit.cylinder(ufo, 8.0, 2.0, Vector3(0, -2.0, 0), Color(0.22, 0.23, 0.27), 0.0, 13.0)
	# пробоина и копоть с той стороны, которой тарелка легла на крыло
	Kit.box(ufo, Vector3(7, 0.3, 4), Vector3(-9, 1.25, -4), Color(0.08, 0.07, 0.07)).rotation_degrees.y = 25
	Kit.box(ufo, Vector3(2.4, 0.32, 1.4), Vector3(-9.5, 1.3, -3.6), Color(1.0, 0.45, 0.15), 2.5).rotation_degrees.y = 25
	Kit.sphere(ufo, 6.5, Vector3(0, 2.6, 0), Color(0.45, 0.85, 1.0, 0.85), 0.8)
	for i in 18:
		var a := TAU * i / 18.0
		Kit.box(ufo, Vector3(1.2, 0.35, 0.6), Vector3(cos(a) * 16.6, 0.2, sin(a) * 16.6), Color(0.3, 1.0, 0.85), 3.5 if i % 3 else 0.0) \
				.rotation.y = -a
	Kit.box(ufo, Vector3(3.5, 3.5, 0.1), Vector3(6, 1.3, 10.5), Color(0.75, 0.15, 0.12)).rotation_degrees.y = 30    # эмблема
	# 0.12: броня по секторам, огни по верхнему кольцу, мигающий маяк и дым из пробоины
	# (в общем пакете площадки: 24 детали — два вызова отрисовки вместо 24)
	var ux := ufo.transform
	for i in 12:
		var a3 := TAU * i / 12.0
		batch.add("site", ux * Transform3D(Basis(Vector3.UP, PI / 2.0 - a3) * Basis.from_scale(Vector3(0.3, 0.3, 2.4)),
				Vector3(cos(a3) * 15.6, 0.32, sin(a3) * 15.6)), Color(0.12, 0.13, 0.16))
		batch.add("glow", ux * Transform3D(Basis().scaled(Vector3.ONE * 0.6), Vector3(cos(a3 + 0.26) * 13.0, 1.75, sin(a3 + 0.26) * 13.0)),
				Color(1.0, 0.75, 0.3) if i % 2 else Color(0.3, 1.0, 0.85))
	var beacon := Kit.sphere(ufo, 0.6, Vector3(0, 9.3, 0), Color(1.0, 0.2, 0.15), 5.0)
	beacon.create_tween().set_loops().tween_property(beacon, "scale", Vector3.ONE * 0.2, 0.6).from(Vector3.ONE)
	var smoke := Kit.particles(ufo, Vector3(-9.5, 1.6, -3.6), Color(0.22, 0.2, 0.2, 0.55), 24, 6.0, Vector3(0, 2.2, 0), 0.25, 4.0,
			Vector3(1.2, 0.2, 0.8))
	smoke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for k in 4:
		var leg := ufo.position + Vector3(-6 + k * 4.0, -7.5, 9 - k * 2.0)
		_b(batch, leg, Vector3(0.25, 15.0, 0.25), Color(0.85, 0.65, 0.15))
		_b(batch, leg + Vector3(0, -2.0 + k, 0), Vector3(4.0, 0.15, 0.15), Color(0.85, 0.65, 0.15), 0.6)
	# очередь за талонами: стойки с канатом, люди и пришельцы
	var rows := _all(site, "PG_B2_mfc_queue")
	for i in rows.size():
		var r := _r(rows[i])
		var y := r.position.y
		var x := r.position.x
		while x <= r.end.x:
			_b(batch, _w(x, y, 0.5), Vector3(0.1, 1.0, 0.1), Color(0.75, 0.72, 0.6))
			_b(batch, _w(x, y, 1.0), Vector3(0.22, 0.12, 0.22), Color(0.85, 0.75, 0.3))
			x += 4.0
		_b(batch, _w(r.get_center().x, y, 0.85), Vector3(r.size.x, 0.05, 0.05), Color(0.75, 0.1, 0.1))
	for k in 16:
		var row := k / 4
		var t := float(k % 4)
		var x2 := 1456.0 + t * 10.0 if row % 2 == 0 else 1490.0 - t * 10.0
		var p := _w(x2, 1495.0 + row * 6.0)
		if k % 5 == 2:
			_alien(root, p, -PI / 2.0 if row % 2 == 0 else PI / 2.0, rng)
		else:
			_person(root, p, -PI / 2.0 if row % 2 == 0 else PI / 2.0, rng)
	_sign(batch, root, "ТАЛОНЫ →", "board", Color(0.1, 0.1, 0.1), _w(1450, 1532, 1.3), 0.0, 0.3, {"bg": Color(0.95, 0.95, 0.92)})
	# турникеты пропускного ряда
	for o in _all(site, "PG_B2_ticket_barrier"):
		var r2 := _r(o)
		var c2 := DistrictSites.sw(r2.get_center())
		_b(batch, c2 + Vector3(0, 0.55, 0), Vector3(0.4, 1.1, r2.size.y), Color(0.55, 0.57, 0.6))
		_b(batch, c2 + Vector3(0, 1.0, 0), Vector3(0.1, 0.1, r2.size.y), Color(0.3, 1.0, 0.5, 0.2), 0.0, "glow")
	# памятник на круглой клумбе: указывает на МФЦ
	var mon := _w(1500, 1556)
	batch.add("tank", Transform3D(Basis().scaled(Vector3(12, 0.5, 12)), mon + Vector3(0, 0.25, 0)), Color(0.42, 0.4, 0.38))
	batch.add("tank", Transform3D(Basis().scaled(Vector3(11, 0.55, 11)), mon + Vector3(0, 0.3, 0)), Color(0.22, 0.16, 0.12))
	for k in 36:
		var a2 := TAU * k / 36.0
		batch.add("veg", Transform3D(Basis().scaled(Vector3.ONE * 0.5), mon + Vector3(cos(a2) * 4.6, 0.65, sin(a2) * 4.6)),
				[Color(0.9, 0.3, 0.4), Color(0.95, 0.75, 0.2), Color(0.6, 0.35, 0.85), Color(0.95, 0.5, 0.2)][k % 4])
	_b(batch, mon + Vector3(0, 1.8, 0), Vector3(2.6, 3.2, 2.6), Color(0.6, 0.58, 0.55))
	Props.collider(root, Vector3(3.2, 6.0, 3.2), mon + Vector3(0, 3.0, 0))
	var bronze := Color(0.32, 0.36, 0.3)
	_b(batch, mon + Vector3(0, 4.6, 0), Vector3(1.1, 2.6, 0.8), bronze)
	batch.add("veg", Transform3D(Basis().scaled(Vector3.ONE * 0.65), mon + Vector3(0, 6.2, 0)), bronze)
	batch.add("site", Transform3D(Basis(Vector3.RIGHT, -1.2) * Basis.from_scale(Vector3(0.28, 0.28, 1.6)), mon + Vector3(0.5, 5.6, -0.7)), bronze)
	_sign(batch, root, "ОН ТОЖЕ ЖДАЛ ТАЛОН", "board", Color(0.9, 0.85, 0.7), mon + Vector3(0, 1.8, 1.32), 0.0, 0.22,
			{"bg": Color(0.3, 0.28, 0.25), "far": DistrictDressing.SIGN_FAR_M})
	# архив и копицентр, вагончик регистрации пришельцев, кафе
	var arch := _r(_o(site, "PG_B2_archive"))
	var ac := _hall(root, arch, 12.0, true, Color(0.55, 0.32, 0.25))
	_sign(batch, root, "АРХИВ\nДЕЛ ЖИВЫХ", "board", Color(0.95, 0.9, 0.8), ac + Vector3(-arch.size.x / 2.0 - 0.05, 4.0, 10), -90.0, 0.5,
			{"bg": Color(0.2, 0.25, 0.35), "lamp": true})
	var copy := _r(_o(site, "PG_B2_copyshop"))
	var cc := _hall(root, copy, 5.0, false, Color(0.3, 0.5, 0.46), Color(0.25, 0.25, 0.27), true)
	_sign(batch, root, "КОПИЦЕНТР\n«КОПИЯ ТЕБЯ»", "lightbox", Color(0.2, 0.5, 0.9), cc + Vector3(copy.size.x / 2.0 + 0.05, 4.0, 0), 90.0,
			0.42, {"bg": Color(0.92, 0.95, 1.0)})
	_sign(batch, root, "РУБИН\nВСЁ ЕЩЁ НАШ ♥", "graffiti", Color(0.85, 0.15, 0.15), cc + Vector3(0, 2.3, copy.size.y / 2.0 + 0.05), 0.0,
			0.6)
	var trailer := _w(1430, 1545)
	_b(batch, trailer + Vector3(0, 1.5, 0), Vector3(7.0, 2.8, 2.8), Color(0.22, 0.38, 0.28))
	_b(batch, trailer + Vector3(0, 3.0, 0), Vector3(7.4, 0.2, 3.2), Color(0.18, 0.3, 0.22))
	Props.collider(root, Vector3(7.0, 3.0, 2.8), trailer + Vector3(0, 1.5, 0))
	_sign(batch, root, "РЕГИСТРАЦИЯ\nПРИШЕЛЬЦЕВ", "lightbox", Color(0.1, 0.25, 0.15), trailer + Vector3(0, 2.2, 1.45), 0.0, 0.42,
			{"bg": Color(0.9, 0.95, 0.9)})
	_b(batch, trailer + Vector3(-1.5, 0.5, 2.6), Vector3(1.6, 0.06, 1.0), Color(0.5, 0.35, 0.22))
	_person(root, trailer + Vector3(-1.5, 0, 3.4), PI, rng)
	var cafe := _w(1572, 1548)
	_b(batch, cafe + Vector3(0, 1.4, 0), Vector3(4.5, 2.8, 3.0), Color(0.75, 0.3, 0.2))
	_b(batch, cafe + Vector3(0, 2.95, 0.4), Vector3(5.0, 0.15, 4.0), Color(0.55, 0.15, 0.12))
	Props.collider(root, Vector3(4.5, 2.8, 3.0), cafe + Vector3(0, 1.4, 0))
	_sign(batch, root, "ЧЕБУРЕКИ · ШАВЕРМА\nПЛАНЕТНАЯ КУХНЯ\nРАБОТАЕТ НА ВСЕХ", "lightbox", RED, cafe + Vector3(-2.3, 2.0, 0), -90.0,
			0.26, {"bg": Color(1.0, 0.93, 0.75), "far": DistrictDressing.SIGN_FAR_M})
	for k in 3:
		var tb := cafe + Vector3(-6.0, 0, -4.0 + k * 3.5)
		_b(batch, tb + Vector3(0, 0.75, 0), Vector3(1.0, 0.06, 1.0), Color(0.85, 0.85, 0.82))
		_b(batch, tb + Vector3(0, 0.37, 0), Vector3(0.1, 0.75, 0.1), Color(0.3, 0.3, 0.32))
		_person(root, tb + Vector3(0.9, 0, 0), -PI / 2.0, rng)
	_garland(batch, cafe + Vector3(-8, 3.0, -6), cafe + Vector3(-2.2, 3.0, -1.5))
	for k in 6:
		_lantern(batch, _w(1420 + k * 32, 1590))
	for k in 3:
		_lantern(batch, _w(1440 + k * 60, 1486))
	_square_garden(root, batch, rng)


## Сквер вокруг площади (как на концепте 03_square): аллеи деревьев по краям, клумбы
## с лавками, квасная бочка, гуляющие и голуби у памятника.
static func _square_garden(root: Node3D, batch: DistrictDressing.Batch, rng: RandomNumberGenerator) -> void:
	var spots: Array[Vector2] = []
	for k in 12:
		var y := 1422.0 + k * 15.0
		if y < 1498.0 or y > 1542.0:
			spots.append(Vector2(1420, y))          # запад, кроме копицентра
		if y > 1516.0:
			spots.append(Vector2(1580, y))          # восток южнее архива
	for k in 11:
		spots.append(Vector2(1432 + k * 14.0, 1582))
	for p in spots:
		DistrictDressing._tree(batch, _w(p.x + rng.randf_range(-1, 1), p.y + rng.randf_range(-1, 1)), rng, rng.randf_range(1.3, 1.7))
	# клумбы: бордюр, земля, цветы рядами, лавки по длинным сторонам
	for c: Vector2 in [Vector2(1434, 1440), Vector2(1566, 1440), Vector2(1450, 1562), Vector2(1550, 1562)]:
		var at := _w(c.x, c.y)
		_b(batch, at + Vector3(0, 0.15, 0), Vector3(16, 0.3, 7), Color(0.62, 0.6, 0.56))
		_b(batch, at + Vector3(0, 0.2, 0), Vector3(15.2, 0.32, 6.2), Color(0.22, 0.16, 0.12))
		var flowers := [Color(0.92, 0.3, 0.35), Color(0.98, 0.78, 0.2), Color(0.62, 0.36, 0.86), Color(0.98, 0.55, 0.2),
			Color(0.95, 0.95, 0.9)]
		for i in 13:
			for j in 5:
				batch.add("veg", Transform3D(Basis().scaled(Vector3.ONE * rng.randf_range(0.35, 0.55)),
						at + Vector3(-6.6 + i * 1.1, 0.5, -2.4 + j * 1.2)), flowers[(i / 3 + j) % flowers.size()])
		for side: float in [-1.0, 1.0]:
			batch.model("bench", at + Vector3(rng.randf_range(-4, 4), 0, side * 5.0), 0.0 if side > 0 else PI)
			Props.collider(root, Vector3(2.4, 0.5, 0.7), at + Vector3(0, 0.25, side * 5.0))
		Props.collider(root, Vector3(16, 0.6, 7), at + Vector3(0, 0.3, 0))
	# квас «из другой галактики»: жёлтая бочка на колёсах
	var kvas := _w(1440, 1470)
	batch.add("tank", Transform3D(Basis(Vector3.FORWARD, PI / 2.0) * Basis.from_scale(Vector3(1.4, 3.2, 1.4)), kvas + Vector3(0, 1.3, 0)),
			Color(0.95, 0.75, 0.15))
	for sx: float in [-1.0, 1.0]:
		_b(batch, kvas + Vector3(sx * 0.9, 0.35, 0.75), Vector3(0.7, 0.7, 0.2), Color(0.1, 0.1, 0.1))
		_b(batch, kvas + Vector3(sx * 0.9, 0.35, -0.75), Vector3(0.7, 0.7, 0.2), Color(0.1, 0.1, 0.1))
	_sign(batch, root, "КВАС\nИЗ ДРУГОЙ ГАЛАКТИКИ", "board", Color(0.6, 0.12, 0.08), kvas + Vector3(0, 1.4, 0.72), 0.0, 0.26,
			{"bg": Color(0.98, 0.9, 0.55)})
	Props.collider(root, Vector3(3.4, 2.0, 1.6), kvas + Vector3(0, 1.0, 0))
	_person(root, kvas + Vector3(-0.5, 0, 1.6), PI, rng)
	_person(root, kvas + Vector3(0.6, 0, 2.4), PI, rng)
	# гуляющие по скверу и голуби у памятника
	for k in 10:
		var p := _w(rng.randf_range(1430, 1570), rng.randf_range(1548, 1575))
		_person(root, p, rng.randf() * TAU, rng)
	var mon := _w(1500, 1556)
	for k in 24:
		var a := rng.randf() * TAU
		var d := rng.randf_range(7.0, 12.0)
		var pp := mon + Vector3(cos(a) * d, 0.12, sin(a) * d)
		batch.add("veg", Transform3D(Basis(Vector3.UP, rng.randf() * TAU) * Basis.from_scale(Vector3(0.22, 0.18, 0.32)), pp),
				Color(0.5, 0.5, 0.55).lerp(Color(0.35, 0.36, 0.42), rng.randf()))


# ---------- ориентиры секторов ----------

## A1: колесо обозрения (кабинки не переворачиваются) и пенопластовое НЛО у касс.
static func _park(root: Node3D, site: Dictionary, batch: DistrictDressing.Batch) -> void:
	var sup := _r(_o(site, "PG_A1_wheel_support"))
	var hub := DistrictSites.sw(sup.get_center(), 29.5)
	for side: float in [-1.0, 1.0]:
		for lean: float in [-1.0, 1.0]:
			var foot := DistrictSites.sw(sup.get_center()) + Vector3(lean * 9.0, 0, side * 3.0)
			var mid := (foot + hub + Vector3(0, 0, side * 1.2)) / 2.0
			var d := hub - foot
			batch.add("site", Transform3D(Basis(Vector3.BACK, -atan2(d.x, d.y)) * Basis.from_scale(Vector3(0.6, d.length(), 0.6)), mid),
					Color(0.85, 0.85, 0.82))
	Props.collider(root, Vector3(20, 4, 8), DistrictSites.sw(sup.get_center(), 2.0))
	var wheel := Node3D.new()
	wheel.name = "FerrisWheel"
	wheel.position = hub
	root.add_child(wheel)
	var rim := Node3D.new()
	wheel.add_child(rim)
	var radius := 25.0
	for i in 36:
		var a := TAU * i / 36.0
		var p := Vector3(cos(a) * radius, sin(a) * radius, 0)
		Kit.box(rim, Vector3(4.5, 0.35, 0.35), p, Color(0.9, 0.9, 0.88)).rotation.z = a + PI / 2.0
		Kit.box(rim, Vector3(0.3, 0.3, 0.3), p * 1.02, [Color(1, 0.3, 0.5), Color(0.3, 0.9, 1), Color(1, 0.85, 0.3)][i % 3], 3.0)
	for i in 12:
		var a := TAU * i / 12.0
		Kit.box(rim, Vector3(radius, 0.18, 0.18), Vector3(cos(a), sin(a), 0) * radius / 2.0, Color(0.8, 0.8, 0.78)).rotation.z = a
		var cabin := Node3D.new()
		cabin.position = Vector3(cos(a), sin(a), 0) * radius
		rim.add_child(cabin)
		Kit.box(cabin, Vector3(3.0, 2.4, 2.4), Vector3(0, -1.6, 0), [RED, Color(0.2, 0.55, 0.85), Color(0.95, 0.75, 0.2)][i % 3])
		Kit.box(cabin, Vector3(3.2, 0.3, 2.6), Vector3(0, -0.3, 0), Color(0.9, 0.9, 0.88))
		Kit.box(cabin, Vector3(2.6, 0.9, 2.5), Vector3(0, -1.2, 0), Color(1.0, 0.85, 0.55), 1.5)
		var keep := cabin.create_tween().set_loops()
		keep.tween_property(cabin, "rotation:z", -TAU, 160.0).from(0.0)
	Kit.cylinder(wheel, 1.6, 2.0, Vector3.ZERO, Color(0.7, 0.7, 0.7)).rotation.x = PI / 2.0
	var spin := rim.create_tween().set_loops()
	spin.tween_property(rim, "rotation:z", TAU, 160.0).from(0.0)
	var fake := _r(_o(site, "PG_A1_fake_ufo"))
	var fc := DistrictSites.sw(fake.get_center())
	batch.add("tank", Transform3D(Basis().scaled(Vector3(22, 1.6, 22)), fc + Vector3(0, 2.2, 0)), Color(0.75, 0.78, 0.82))
	batch.add("tank", Transform3D(Basis().scaled(Vector3(14, 1.4, 14)), fc + Vector3(0, 0.9, 0)), Color(0.5, 0.52, 0.58))
	batch.add("crown", Transform3D(Basis().scaled(Vector3(8, 5, 8)), fc + Vector3(0, 3.6, 0)), Color(0.45, 0.9, 0.85))
	for i in 12:
		var a := TAU * i / 12.0
		_b(batch, fc + Vector3(cos(a) * 10.8, 2.2, sin(a) * 10.8), Vector3(0.6, 0.4, 0.6), [Color(1, 0.3, 0.7), Color(0.3, 1, 0.9)][i % 2],
				0.0, "glow")
	Props.collider(root, Vector3(20, 4, 20), fc + Vector3(0, 2, 0))
	_sign(batch, root, "НЛО ИЗ ПЕНОПЛАСТА\nФОТО — 100 ₽", "neon", Color(1.0, 0.35, 0.75), fc + Vector3(0, 5.5, 11.2), 0.0, 0.55,
			{"icon": "ufo", "flicker": true})
	var gate := _w(500, 636)
	for side: float in [-1.0, 1.0]:
		_b(batch, gate + Vector3(side * 6.0, 3.0, 0), Vector3(0.7, 6.0, 0.7), Color(0.75, 0.2, 0.3))
	_b(batch, gate + Vector3(0, 6.2, 0), Vector3(13, 0.6, 0.6), Color(0.75, 0.2, 0.3))
	_sign(batch, root, "ПАРК ЧУЖОГО СЧАСТЬЯ", "letters", Color(1.0, 0.8, 0.35), gate + Vector3(0, 7.4, 0.2), 0.0, 1.1)
	_garland(batch, gate + Vector3(-6, 5.6, 0.4), gate + Vector3(6, 5.6, 0.4), 0.7)
	var kassa := _w(470, 610)
	_b(batch, kassa + Vector3(0, 1.4, 0), Vector3(3.0, 2.8, 2.4), Color(0.9, 0.85, 0.75))
	_b(batch, kassa + Vector3(0, 2.95, 0), Vector3(3.6, 0.3, 3.0), RED)
	Props.collider(root, Vector3(3, 2.8, 2.4), kassa + Vector3(0, 1.4, 0))
	_sign(batch, root, "КАССЫ\nСЧАСТЬЕ ПО ЧЕКУ", "lightbox", RED, kassa + Vector3(0, 2.2, 1.25), 0.0, 0.3, {"bg": Color(1, 0.95, 0.85)})
	for k in 5:
		_lantern(batch, _w(440 + k * 30, 620))


static func _portico(batch: DistrictDressing.Batch, front: Vector3, width: float, h: float, cols: int, color: Color) -> void:
	for i in cols:
		var x := -width / 2.0 + width * (i + 0.5) / cols
		batch.add("tank", Transform3D(Basis().scaled(Vector3(1.1, h, 1.1)), front + Vector3(x, h / 2.0 + 0.6, 2.4)), color)
	_b(batch, front + Vector3(0, h + 1.2, 2.2), Vector3(width + 2.0, 1.2, 3.8), color.darkened(0.04))
	for k in 4:
		_b(batch, front + Vector3(0, h + 2.1 + k * 0.6, 2.0), Vector3(width + 2.0 - k * (width / 4.5), 0.6, 3.2), color.darkened(0.06))
	for k in 3:
		_b(batch, front + Vector3(0, 0.15 + k * 0.3, 5.2 - k * 0.7), Vector3(width + 2.0, 0.3, 1.4 + k * 0.7), Color(0.62, 0.6, 0.56))


## A2: театр «Овация» — портик из восьми колонн, афиши.
static func _theatre(root: Node3D, site: Dictionary, batch: DistrictDressing.Batch) -> void:
	var r := _r(_o(site, "PG_A2_theatre"))
	var c := _hall(root, r, 15.0, false, Color(0.86, 0.8, 0.66))
	var front := c + Vector3(0, 0, r.size.y / 2.0)
	_portico(batch, front, 40.0, 11.0, 8, Color(0.92, 0.88, 0.8))
	_sign(batch, root, "ТЕАТР «ОВАЦИЯ»", "letters", Color(1.0, 0.82, 0.45), front + Vector3(0, 16.6, 2.2), 0.0, 1.4)
	_sign(batch, root, "ПРЕМЬЕРА:\nАПЛОДИСМЕНТЫ\nПО ПРИКАЗУ", "poster", RED, front + Vector3(-26, 4.0, 0.1), 0.0, 0.45,
			{"bg": Color(0.95, 0.9, 0.8)})
	_sign(batch, root, "БИЛЕТЫ — В ОБМЕН\nНА ВОСТОРГ", "poster", Color(0.15, 0.15, 0.3), front + Vector3(26, 4.0, 0.1), 0.0, 0.4,
			{"bg": Color(0.9, 0.85, 0.7)})
	for k in 4:
		_lantern(batch, front + Vector3(-24 + k * 16, 0, 10))


## A3: показательный ЖК — офис с очередью и целая тарелка на крыше.
static func _showcase(root: Node3D, site: Dictionary, batch: DistrictDressing.Batch) -> void:
	var r := _r(_o(site, "PG_A3_office"))
	var c := _hall(root, r, 12.0, false, Color(0.9, 0.9, 0.86), Color(0.3, 0.32, 0.35), true)
	_paving(batch, _r(_o(site, "PG_A3_plaza")))
	var u := _r(_o(site, "PG_A3_ufo"))
	var uc := DistrictSites.sw(u.get_center(), 13.5)
	batch.add("tank", Transform3D(Basis().scaled(Vector3(30, 2.0, 30)), uc), Color(0.62, 0.64, 0.7))
	batch.add("crown", Transform3D(Basis().scaled(Vector3(12, 6, 12)), uc + Vector3(0, 1.6, 0)), Color(0.5, 0.85, 1.0))
	for i in 14:
		var a := TAU * i / 14.0
		_b(batch, uc + Vector3(cos(a) * 14.6, 0, sin(a) * 14.6), Vector3(0.8, 0.4, 0.8), Color(0.3, 1.0, 0.8), 0.0, "glow")
	_sign(batch, root, "ПОКАЗАТЕЛЬНЫЙ КВАРТАЛ\nВСЁ ЛУЧШЕЕ — НАПОКАЗ", "lightbox", Color(0.1, 0.2, 0.4),
			c + Vector3(0, 9.0, r.size.y / 2.0 + 0.1), 0.0, 0.7, {"bg": Color(0.95, 0.97, 1.0)})
	for o in _all(site, "PG_A3_queue"):
		var q := _r(o)
		_b(batch, _w(q.get_center().x, q.position.y, 0.85), Vector3(q.size.x, 0.05, 0.05), Color(0.75, 0.1, 0.1))
	var rng := RandomNumberGenerator.new()
	rng.seed = 2500
	for k in 8:
		_person(root, _w(2456 + (k % 4) * 11.0, 495.0 + (k / 4) * 12.0), -PI / 2.0, rng)


## B1: мастерские «Без лица» — кирпичный корпус, ворота, лом во дворе.
static func _workshops(root: Node3D, site: Dictionary, batch: DistrictDressing.Batch) -> void:
	var r := _r(_o(site, "PG_B1_main"))
	var c := _hall(root, r, 12.0, true, Color(0.58, 0.33, 0.25))
	var front := c + Vector3(0, 0, r.size.y / 2.0)
	for k in 3:
		_b(batch, front + Vector3(-18 + k * 18, 2.4, 0.08), Vector3(5.0, 4.8, 0.15), Color(0.3, 0.38, 0.4))
	_sign(batch, root, "МАСТЕРСКИЕ «БЕЗ ЛИЦА»\nРЕМОНТ ВСЕГО, КРОМЕ СОВЕСТИ", "board", Color(0.95, 0.9, 0.8), front + Vector3(0, 6.6, 0.15),
			0.0, 0.5, {"bg": Color(0.22, 0.2, 0.18), "lamp": true})
	var rng := RandomNumberGenerator.new()
	rng.seed = 1487
	for k in 3:
		batch.model("car_wreck", front + Vector3(-20 + k * 14, 0, 7), rng.randf() * TAU)
		batch.model("tires", front + Vector3(-14 + k * 14, 0, 9), rng.randf() * TAU)
	for k in 3:
		_lantern(batch, front + Vector3(-20 + k * 20, 0, 13))


## B3: телецентр и мачта в красно-белую полоску, на ней тарелки и мигающий огонь.
static func _tv(root: Node3D, site: Dictionary, batch: DistrictDressing.Batch) -> void:
	var r := _r(_o(site, "PG_B3_studio"))
	var c := _hall(root, r, 12.0, false, Color(0.7, 0.74, 0.78), Color(0.3, 0.3, 0.33), true)
	_sign(batch, root, "ТЕЛЕЦЕНТР «ПОГУЛЯЙ»", "letters", Color(0.5, 0.85, 1.0), c + Vector3(0, 13.4, r.size.y / 2.0), 0.0, 1.2)
	_sign(batch, root, "ТРИДЦАТЬ ЛАЙКОВ —\nИ ТЫ В ЭФИРЕ", "neon", Color(1.0, 0.3, 0.8), c + Vector3(0, 6.5, r.size.y / 2.0 + 0.1), 0.0,
			0.6, {"flicker": true})
	var m := _r(_o(site, "PG_B3_mast"))
	var base := DistrictSites.sw(m.get_center())
	var h := 65.0
	var segs := 13
	for i in segs:
		var y0 := h * i / segs
		var w := lerpf(7.0, 1.2, float(i) / segs)
		var col := RED if i % 2 == 0 else Color(0.95, 0.95, 0.92)
		for sx: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				_b(batch, base + Vector3(sx * w / 2.0, y0 + h / segs / 2.0, sz * w / 2.0), Vector3(0.3, h / segs, 0.3), col)
		_b(batch, base + Vector3(0, y0 + h / segs - 0.2, 0), Vector3(w, 0.15, 0.15), col)
		_b(batch, base + Vector3(0, y0 + h / segs - 0.2, 0), Vector3(0.15, 0.15, w), col)
		if i in [5, 8, 10]:
			batch.add("tank", Transform3D(Basis(Vector3.RIGHT, PI / 2.0) * Basis.from_scale(Vector3(3.2, 0.4, 3.2)),
					base + Vector3(0, y0, w / 2.0 + 1.0)), Color(0.9, 0.9, 0.88))
	_b(batch, base + Vector3(0, h + 0.6, 0), Vector3(0.8, 0.8, 0.8), Color(1.0, 0.15, 0.1), 0.0, "glow")
	Props.collider(root, Vector3(8, 10, 8), base + Vector3(0, 5, 0))


## C3: котельная — кирпичный корпус и две трубы с дымом.
static func _boiler(root: Node3D, site: Dictionary, batch: DistrictDressing.Batch) -> void:
	var r := _r(_o(site, "PG_C3_boiler"))
	var c := _hall(root, r, 15.0, true, Color(0.56, 0.3, 0.22))
	_sign(batch, root, "КОТЕЛЬНАЯ № 3 · ЭНЕРГОУЗЕЛ\nТЕПЛО ПО ГРАФИКУ", "board", Color(0.95, 0.9, 0.8),
			c + Vector3(0, 7.5, r.size.y / 2.0 + 0.1), 0.0, 0.6, {"bg": Color(0.2, 0.22, 0.25), "lamp": true})
	for name in ["PG_C3_chimney", "PG_C3_chimney2"]:
		var o := _r(_o(site, name))
		var h := float(_o(site, name).z[1])
		var foot := DistrictSites.sw(o.get_center())
		var bands := int(h / 5.0)
		for i in bands:
			batch.add("tank", Transform3D(Basis().scaled(Vector3(3.4 - i * 0.08, h / bands, 3.4 - i * 0.08)),
					foot + Vector3(0, (i + 0.5) * h / bands, 0)), RED if i % 2 == 1 and i > bands - 4 else Color(0.6, 0.34, 0.26))
		Props.collider(root, Vector3(3.4, h, 3.4), foot + Vector3(0, h / 2.0, 0))
		var smoke := GPUParticles3D.new()
		smoke.amount = 14
		smoke.lifetime = 7.0
		smoke.position = foot + Vector3(0, h + 1.0, 0)
		smoke.visibility_aabb = AABB(Vector3(-20, -2, -20), Vector3(40, 40, 40))
		var pm := ParticleProcessMaterial.new()
		pm.direction = Vector3(0.4, 1, 0.1)
		pm.spread = 12.0
		pm.initial_velocity_min = 1.5
		pm.initial_velocity_max = 2.5
		pm.gravity = Vector3(0.3, 0.2, 0)
		pm.scale_min = 2.0
		pm.scale_max = 4.5
		pm.color = Color(0.85, 0.82, 0.78, 0.35)
		smoke.process_material = pm
		var q := QuadMesh.new()
		q.size = Vector2(2, 2)
		var sm := StandardMaterial3D.new()
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		sm.vertex_color_use_as_albedo = true
		sm.albedo_texture = Kit.soft_dot()
		q.material = sm
		smoke.draw_pass_1 = q
		smoke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(smoke)
