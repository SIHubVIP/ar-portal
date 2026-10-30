class_name BuildingKit
extends RefCounted
## Дома Погуляя по макету «Рубин» (0.11): постсоветский город в 2–5 этажей, как на концептах
## пакета — двускатные крыши из ржавого профнастила, карнизы, подъезды с козырьками и
## лампочкой, балконы с разноцветными экранами, водостоки, трубы и антенны на крыше.
##
## Сетка дома — две поверхности: 0 — стены (фасадный шейдер house_windows: кирпич или
## штукатурка, окна по этажам в мировых координатах), 1 — детали (plain_color, цвет в
## вершинах, альфа 0 — светится). Стены красятся цветом вершин, поэтому один материал на
## все дома одного типа стен. Мелкие дома (частный сектор, гаражи, сараи, мастерские) — единичные
## сетки для MultiMesh: план 1 × 1 м растягивается экземпляром, высота в метрах.

const FLOOR_M := 3.0
const HOUSE_SHADER := preload("res://assets/shaders/house_windows.gdshader")

## Тёплые штукатурки и кирпичи концептов: охра, крем, выцветший розовый, серо-зелёный.
const PLASTER := [Color(0.78, 0.66, 0.48), Color(0.82, 0.74, 0.58), Color(0.74, 0.58, 0.5), Color(0.66, 0.66, 0.56),
	Color(0.86, 0.78, 0.62), Color(0.72, 0.62, 0.52), Color(0.62, 0.68, 0.62)]
const BRICK := [Color(0.58, 0.3, 0.22), Color(0.64, 0.36, 0.26), Color(0.52, 0.3, 0.24), Color(0.7, 0.44, 0.32)]
const ROOFS := [Color(0.42, 0.24, 0.17), Color(0.36, 0.33, 0.3), Color(0.3, 0.36, 0.32), Color(0.5, 0.3, 0.2)]
const BALCONY := [Color(0.85, 0.83, 0.78), Color(0.55, 0.32, 0.2), Color(0.3, 0.45, 0.4), Color(0.4, 0.48, 0.62),
	Color(0.72, 0.62, 0.42)]

static var _wall_mats: Dictionary = {}
static var _detail_mats: Dictionary = {}
static var _units: Dictionary = {}


## Материал стен: brick — кирпич, иначе штукатурка; small — мелкие дома в MultiMesh
## (цвет экземпляра, вырез по глубине вместо коридора камеры); shops — витрины внизу.
static func wall_material(brick: bool, small := false, shops := false) -> ShaderMaterial:
	var key := "%s%s%s" % [brick, small, shops]
	if not _wall_mats.has(key):
		var m := ShaderMaterial.new()
		m.shader = HOUSE_SHADER
		m.set_shader_parameter("use_color", true)
		m.set_shader_parameter("brick", brick)
		m.set_shader_parameter("shops", shops)
		m.set_shader_parameter("depth_cut", small)
		m.set_shader_parameter("use_custom", small)
		m.set_shader_parameter("floor_h", FLOOR_M)
		m.set_shader_parameter("lit_share", 0.42 if not small else 0.5)
		_wall_mats[key] = m
	return _wall_mats[key]


static func detail_material(small := false) -> ShaderMaterial:
	if not _detail_mats.has(small):
		var m := ShaderMaterial.new()
		m.shader = Signboard.PLAIN_SHADER
		m.set_shader_parameter("roughness_value", 0.8)
		m.set_shader_parameter("depth_cut", small)
		_detail_mats[small] = m
	return _detail_mats[small]


# ---------- многоквартирный дом ----------

## Дом w × d (вдоль X и Z), floors этажей; at — мировая точка центра основания: окна шейдера
## идут по мировой сетке, и балконы со входами ставятся по ней же. Возвращает
## {mesh, entrances: [Vector3 мировые точки у дверей], height}.
static func house(w: float, d: float, floors: int, at: Vector3, brick: bool, rng: RandomNumberGenerator) -> Dictionary:
	var walls := SurfaceTool.new()
	walls.begin(Mesh.PRIMITIVE_TRIANGLES)
	var det := SurfaceTool.new()
	det.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := floors * FLOOR_M + 0.4
	var wall: Color = (BRICK if brick else PLASTER)[rng.randi() % (BRICK if brick else PLASTER).size()]
	wall = wall.lerp(Color(0.5, 0.48, 0.45), rng.randf_range(0.0, 0.15))
	_box(walls, Vector3(0, h / 2.0, 0), Vector3(w, h, d), wall)
	# двускатная крыша вдоль длинной стороны, фронтоны — стеной
	var along_x := w >= d
	var span := d if along_x else w
	var ridge := clampf(span * 0.2, 1.6, 3.6)
	var roof: Color = ROOFS[rng.randi() % ROOFS.size()]
	_gable(walls, det, Vector3(0, h, 0), w, d, ridge, along_x, wall, roof)
	# карниз и цоколь
	_box(det, Vector3(0, h - 0.12, 0), Vector3(w + 0.36, 0.24, d + 0.36), Color(0.78, 0.76, 0.72))
	_box(det, Vector3(0, 0.3, 0), Vector3(w + 0.12, 0.6, d + 0.12), Color(0.38, 0.36, 0.34))
	# фасады: «перед» — юг (+Z) или восток (+X) — подъезды; «зад» — балконы
	var length := w if along_x else d
	var axis := Vector3(1, 0, 0) if along_x else Vector3(0, 0, 1)
	var front := Vector3(0, 0, 1) if along_x else Vector3(1, 0, 0)
	var half_depth := (d if along_x else w) / 2.0
	var entrances: Array = []
	var n_doors := maxi(1, int(round(length / 16.0)))
	var bay := 2.6
	for i in n_doors:
		var t := -length / 2.0 + length * (i + 0.5) / n_doors
		# на сетке окон шейдера: дверь ровно в простенке
		var world_u := (at.x if along_x else at.z) + t
		t = (floor(world_u / bay) + 0.5) * bay - (at.x if along_x else at.z)
		var c := axis * t + front * half_depth
		_box(det, c + Vector3(0, 1.15, 0) + front * 0.04, _orient(Vector3(1.3, 2.3, 0.1), along_x),
				[Color(0.3, 0.2, 0.12), Color(0.22, 0.32, 0.26), Color(0.35, 0.3, 0.42)][rng.randi() % 3])
		_box(det, c + Vector3(0, 2.75, 0) + front * 0.75, _orient(Vector3(2.4, 0.16, 1.5), along_x), Color(0.55, 0.53, 0.5))
		_box(det, c + Vector3(0, 0.12, 0) + front * 0.9, _orient(Vector3(2.4, 0.24, 1.6), along_x), Color(0.5, 0.49, 0.47))
		_box(det, c + Vector3(0, 2.5, 0) + front * 0.12, _orient(Vector3(0.3, 0.18, 0.12), along_x), Color(1.0, 0.82, 0.5, 0.0))
		entrances.append(at + c + front * 1.6)
		# лестничная клетка: узкие окна посередине пролётов — светлая полоса над дверью
		for f in range(1, floors):
			_box(det, c + Vector3(0, f * FLOOR_M + 1.6, 0) + front * 0.03, _orient(Vector3(0.7, 1.1, 0.06), along_x),
					Color(0.95, 0.85, 0.6, 0.35))
	# балконы: сзади почти у каждого второго окна, спереди — между подъездами
	for side: float in [-1.0, 1.0]:
		var face := front * side
		for f in range(1, floors):
			var u := -length / 2.0 + bay
			while u < length / 2.0 - bay:
				var world_u := (at.x if along_x else at.z) + u
				var cell := int(floor(world_u / bay))
				var near_door := false
				for e in entrances:
					var eu: float = ((e as Vector3).x if along_x else (e as Vector3).z) - (at.x if along_x else at.z)
					if absf(eu - u) < bay * 1.2:
						near_door = true
				var chance := 0.55 if side < 0.0 else 0.3
				if not near_door and posmod(cell, 2) == 0 and _h(cell, f, side) < chance:
					var bc := axis * ((cell + 0.5) * bay - (at.x if along_x else at.z)) + face * (half_depth + 0.55)
					var col: Color = BALCONY[int(_h(cell, f * 3, side) * BALCONY.size()) % BALCONY.size()]
					_box(det, bc + Vector3(0, f * FLOOR_M + 0.06, 0), _orient(Vector3(2.3, 0.14, 1.1), along_x), Color(0.6, 0.58, 0.55))
					_box(det, bc + Vector3(0, f * FLOOR_M + 0.6, 0) + face * 0.5, _orient(Vector3(2.3, 1.0, 0.06), along_x), col)
					if _h(cell, f, side * 7.0) < 0.35:
						# застеклённый балкон: рамы и тёплый свет
						_box(det, bc + Vector3(0, f * FLOOR_M + 1.75, 0) + face * 0.5, _orient(Vector3(2.3, 1.3, 0.05), along_x),
								Color(0.95, 0.75, 0.45, 0.6) if _h(cell, f, 3.0) < 0.5 else Color(0.25, 0.28, 0.3))
					elif _h(cell, f, 11.0) < 0.3:
						# бельё на верёвке
						for k in 3:
							_box(det, bc + Vector3(-0.6 + k * 0.6, f * FLOOR_M + 1.6, 0) + face * 0.3,
									_orient(Vector3(0.45, 0.5, 0.03), along_x),
									[Color(0.9, 0.3, 0.3), Color(0.95, 0.95, 0.9), Color(0.35, 0.5, 0.85)][k])
				u += bay
	# водостоки на углах и трубы, антенны на крыше
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			_box(det, Vector3(sx * (w / 2.0 + 0.08), h / 2.0, sz * (d / 2.0 - 0.3)), Vector3(0.14, h, 0.14), Color(0.42, 0.42, 0.44))
	for i in maxi(2, int(length / 12.0)):
		var t := -length / 2.0 + length * (i + 0.5) / maxi(2, int(length / 12.0))
		var stack := axis * t + front * rng.randf_range(-span * 0.18, span * 0.18)
		_box(det, stack + Vector3(0, h + ridge * 0.55 + 0.6, 0), Vector3(0.7, 1.6, 0.7), [Color(0.55, 0.3, 0.22), Color(0.5, 0.48, 0.45)][i % 2])
	for i in rng.randi_range(1, 3):
		var p := axis * rng.randf_range(-length / 2.5, length / 2.5) + Vector3(0, h + ridge + 1.0, 0)
		_box(det, p, Vector3(0.05, 2.2, 0.05), Color(0.2, 0.2, 0.22))
		_box(det, p + Vector3(0, 0.8, 0), _orient(Vector3(1.4, 0.04, 0.04), not along_x), Color(0.2, 0.2, 0.22))
	if rng.randf() < 0.6:
		_box(det, axis * rng.randf_range(-length / 3.0, length / 3.0) + front * (half_depth + 0.2) + Vector3(0, h - 1.4, 0),
				Vector3(0.7, 0.7, 0.18), Color(0.85, 0.85, 0.82))      # тарелка спутниковая
	var mesh := ArrayMesh.new()
	walls.commit(mesh)
	det.commit(mesh)
	mesh.surface_set_material(0, wall_material(brick))
	mesh.surface_set_material(1, detail_material())
	return {"mesh": mesh, "entrances": entrances, "height": h + ridge}


## Общественный корпус с плоской кровлей и парапетом (МФЦ, театр, рынок, котельная): стены —
## фасадный шейдер с окнами, кровля, парапет, цоколь и водостоки — детали. Центр основания в нуле.
static func block(w: float, d: float, h: float, brick: bool, wall: Color, roof: Color, shops := false) -> ArrayMesh:
	var walls := SurfaceTool.new()
	walls.begin(Mesh.PRIMITIVE_TRIANGLES)
	var det := SurfaceTool.new()
	det.begin(Mesh.PRIMITIVE_TRIANGLES)
	_box(walls, Vector3(0, h / 2.0, 0), Vector3(w, h, d), wall)
	_box(det, Vector3(0, h + 0.05, 0), Vector3(w - 0.1, 0.1, d - 0.1), roof)
	for side: float in [-1.0, 1.0]:
		_box(det, Vector3(0, h + 0.4, side * (d / 2.0 - 0.15)), Vector3(w + 0.1, 0.8, 0.3), wall.darkened(0.1))
		_box(det, Vector3(side * (w / 2.0 - 0.15), h + 0.4, 0), Vector3(0.3, 0.8, d), wall.darkened(0.1))
	_box(det, Vector3(0, h - 0.2, 0), Vector3(w + 0.3, 0.3, d + 0.3), Color(0.8, 0.78, 0.74))
	_box(det, Vector3(0, 0.35, 0), Vector3(w + 0.12, 0.7, d + 0.12), Color(0.4, 0.38, 0.36))
	var mesh := ArrayMesh.new()
	walls.commit(mesh)
	det.commit(mesh)
	mesh.surface_set_material(0, wall_material(brick, false, shops))
	mesh.surface_set_material(1, detail_material())
	return mesh


# ---------- мелкие дома (MultiMesh) ----------

## Единичная сетка мелкого дома. kind: cottage (1–2 этажа, двускатная крыша, крыльцо, труба),
## garage (металл, ворота), shed (дощатый сарай), workshop (длинный корпус, ворота, фонарь).
## План растягивается до 1 × 1 м; лицо — +Z. variant меняет цвет крыши и дверей.
static func unit(kind: String, floors: int, brick: bool, variant: int) -> ArrayMesh:
	var key := "%s|%d|%s|%d" % [kind, floors, brick, variant]
	if _units.has(key):
		return _units[key]
	var walls := SurfaceTool.new()
	walls.begin(Mesh.PRIMITIVE_TRIANGLES)
	var det := SurfaceTool.new()
	det.begin(Mesh.PRIMITIVE_TRIANGLES)
	var roof: Color = ROOFS[variant % ROOFS.size()]
	var mesh := ArrayMesh.new()
	match kind:
		"cottage":
			var h := floors * FLOOR_M
			_box(walls, Vector3(0, h / 2.0, 0), Vector3(1, h, 1), Color.WHITE)
			_gable(walls, det, Vector3(0, h, 0), 1.0, 1.0, 2.2, true, Color.WHITE, roof, 0.06)
			_box(det, Vector3(0.22, h + 1.6, -0.15), Vector3(0.07, 1.4, 0.07), Color(0.5, 0.28, 0.2))     # труба
			_box(det, Vector3(-0.2, 1.05, 0.505), Vector3(0.11, 2.1, 0.01),
					[Color(0.3, 0.2, 0.12), Color(0.25, 0.4, 0.3), Color(0.5, 0.25, 0.2), Color(0.3, 0.35, 0.5)][variant % 4])
			_box(det, Vector3(-0.2, 2.45, 0.58), Vector3(0.24, 0.08, 0.16), roof.darkened(0.1))          # козырёк крыльца
			_box(det, Vector3(-0.2, 0.15, 0.6), Vector3(0.24, 0.3, 0.2), Color(0.5, 0.48, 0.45))         # ступени
			_box(det, Vector3(-0.2, 2.25, 0.515), Vector3(0.03, 0.12, 0.02), Color(1.0, 0.8, 0.5, 0.0))  # лампочка
			_box(det, Vector3(0, 0.25, 0), Vector3(1.02, 0.5, 1.02), Color(0.4, 0.37, 0.34))              # цоколь
		"garage":
			_box(det, Vector3(0, 1.3, 0), Vector3(1, 2.6, 1), Color(0.5, 0.46, 0.42))
			_box(det, Vector3(0, 2.68, -0.05), Vector3(1.04, 0.16, 1.12), roof)
			_box(det, Vector3(0, 1.05, 0.505), Vector3(0.78, 2.1, 0.01),
					[Color(0.3, 0.42, 0.34), Color(0.55, 0.32, 0.2), Color(0.35, 0.38, 0.5), Color(0.6, 0.55, 0.3)][variant % 4])
		"shed":
			_box(det, Vector3(0, 1.1, 0), Vector3(1, 2.2, 1), Color(0.46, 0.33, 0.22))
			_box(det, Vector3(0, 2.3, 0.04), Vector3(1.12, 0.12, 1.2), roof)
			_box(det, Vector3(0.15, 0.95, 0.505), Vector3(0.35, 1.9, 0.01), Color(0.32, 0.22, 0.14))
		_:
			var h2 := 4.5 if floors <= 1 else 6.0
			_box(walls, Vector3(0, h2 / 2.0, 0), Vector3(1, h2, 1), Color.WHITE)
			_box(det, Vector3(0, h2 + 0.2, 0), Vector3(1.03, 0.4, 1.03), roof)
			_box(det, Vector3(0, h2 + 0.75, 0), Vector3(0.6, 0.7, 0.25), Color(0.75, 0.8, 0.8, 0.5))      # световой фонарь
			_box(det, Vector3(0.18, 1.8, 0.505), Vector3(0.36, 3.6, 0.01), Color(0.32, 0.36, 0.4))       # ворота
			_box(det, Vector3(0.18, 3.85, 0.53), Vector3(0.12, 0.12, 0.05), Color(1.0, 0.8, 0.5, 0.0))
	if kind == "cottage" or kind == "workshop":
		walls.commit(mesh)
		mesh.surface_set_material(0, wall_material(brick, true))
	det.commit(mesh)
	mesh.surface_set_material(mesh.get_surface_count() - 1, detail_material(true))
	_units[key] = mesh
	return mesh


## Цвет стены мелкого дома для экземпляра: штукатурка пастельная, дерево — тёмные доски.
static func small_wall_color(mat: String, rng: RandomNumberGenerator) -> Color:
	match mat:
		"brick":
			return BRICK[rng.randi() % BRICK.size()]
		"wood":
			return Color(0.48, 0.34, 0.22).lerp(Color(0.38, 0.4, 0.3), rng.randf() * 0.5)
		"metal":
			return Color(0.5, 0.5, 0.52).lerp(Color(0.55, 0.35, 0.25), rng.randf() * 0.6)
	var pastel := [Color(0.86, 0.8, 0.58), Color(0.7, 0.8, 0.84), Color(0.74, 0.84, 0.7), Color(0.88, 0.72, 0.66),
		Color(0.9, 0.86, 0.76), Color(0.8, 0.7, 0.86)]
	return pastel[rng.randi() % pastel.size()]


# ---------- геометрия ----------

static func _h(a: int, b: int, c: float) -> float:
	return fposmod(sin(a * 12.9898 + b * 78.233 + c * 37.719) * 43758.5453, 1.0)


static func _orient(size: Vector3, along_x: bool) -> Vector3:
	return size if along_x else Vector3(size.z, size.y, size.x)


## Коробка с нормалями граней и цветом вершин.
static func _box(st: SurfaceTool, c: Vector3, s: Vector3, col: Color) -> void:
	var hx := s.x / 2.0
	var hy := s.y / 2.0
	var hz := s.z / 2.0
	var faces := [
		[Vector3(1, 0, 0), [Vector3(hx, -hy, hz), Vector3(hx, -hy, -hz), Vector3(hx, hy, -hz), Vector3(hx, hy, hz)]],
		[Vector3(-1, 0, 0), [Vector3(-hx, -hy, -hz), Vector3(-hx, -hy, hz), Vector3(-hx, hy, hz), Vector3(-hx, hy, -hz)]],
		[Vector3(0, 1, 0), [Vector3(-hx, hy, hz), Vector3(hx, hy, hz), Vector3(hx, hy, -hz), Vector3(-hx, hy, -hz)]],
		[Vector3(0, -1, 0), [Vector3(-hx, -hy, -hz), Vector3(hx, -hy, -hz), Vector3(hx, -hy, hz), Vector3(-hx, -hy, hz)]],
		[Vector3(0, 0, 1), [Vector3(-hx, -hy, hz), Vector3(hx, -hy, hz), Vector3(hx, hy, hz), Vector3(-hx, hy, hz)]],
		[Vector3(0, 0, -1), [Vector3(hx, -hy, -hz), Vector3(-hx, -hy, -hz), Vector3(-hx, hy, -hz), Vector3(hx, hy, -hz)]],
	]
	for f in faces:
		var v: Array = f[1]
		_tri(st, f[0], col, c + v[0], c + v[2], c + v[1])
		_tri(st, f[0], col, c + v[0], c + v[3], c + v[2])


static func _tri(st: SurfaceTool, n: Vector3, col: Color, a: Vector3, b: Vector3, c: Vector3) -> void:
	for p in [a, b, c]:
		st.set_normal(n)
		st.set_color(col)
		st.add_vertex(p)


## Двускатная крыша над прямоугольником w × d на высоте base.y: скаты — детали, фронтоны —
## стена. along_x — конёк вдоль X. Обход вершин — по часовой стрелке с лицевой стороны.
static func _gable(walls: SurfaceTool, det: SurfaceTool, base: Vector3, w: float, d: float, ridge: float, along_x: bool,
		wall: Color, roof: Color, over := 0.35) -> void:
	var lx := w / 2.0 + over
	var lz := d / 2.0 + over
	var apex := ridge * 0.97
	if along_x:
		var top_l := base + Vector3(-lx, ridge, 0)
		var top_r := base + Vector3(lx, ridge, 0)
		var s_l := base + Vector3(-lx, -0.05, lz)
		var s_r := base + Vector3(lx, -0.05, lz)
		var n_l := base + Vector3(-lx, -0.05, -lz)
		var n_r := base + Vector3(lx, -0.05, -lz)
		var ns := Vector3(0, lz, ridge).normalized()
		var nn := Vector3(0, lz, -ridge).normalized()
		_tri(det, ns, roof.darkened(0.08), s_l, top_l, top_r)
		_tri(det, ns, roof.darkened(0.08), s_l, top_r, s_r)
		_tri(det, nn, roof, n_r, top_r, top_l)
		_tri(det, nn, roof, n_r, top_l, n_l)
		var e := base + Vector3(w / 2.0, 0, 0)
		var wst := base + Vector3(-w / 2.0, 0, 0)
		_tri(walls, Vector3(1, 0, 0), wall, e + Vector3(0, 0, d / 2.0), e + Vector3(0, apex, 0), e + Vector3(0, 0, -d / 2.0))
		_tri(walls, Vector3(-1, 0, 0), wall, wst + Vector3(0, 0, -d / 2.0), wst + Vector3(0, apex, 0), wst + Vector3(0, 0, d / 2.0))
	else:
		var top_n := base + Vector3(0, ridge, -lz)
		var top_s := base + Vector3(0, ridge, lz)
		var e_n := base + Vector3(lx, -0.05, -lz)
		var e_s := base + Vector3(lx, -0.05, lz)
		var w_n := base + Vector3(-lx, -0.05, -lz)
		var w_s := base + Vector3(-lx, -0.05, lz)
		var ne := Vector3(ridge, lx, 0).normalized()
		var nw := Vector3(-ridge, lx, 0).normalized()
		_tri(det, ne, roof.darkened(0.08), e_s, top_s, top_n)
		_tri(det, ne, roof.darkened(0.08), e_s, top_n, e_n)
		_tri(det, nw, roof, w_n, top_n, top_s)
		_tri(det, nw, roof, w_n, top_s, w_s)
		var sth := base + Vector3(0, 0, d / 2.0)
		var nth := base + Vector3(0, 0, -d / 2.0)
		_tri(walls, Vector3(0, 0, 1), wall, sth + Vector3(-w / 2.0, 0, 0), sth + Vector3(0, apex, 0), sth + Vector3(w / 2.0, 0, 0))
		_tri(walls, Vector3(0, 0, -1), wall, nth + Vector3(w / 2.0, 0, 0), nth + Vector3(0, apex, 0), nth + Vector3(-w / 2.0, 0, 0))
