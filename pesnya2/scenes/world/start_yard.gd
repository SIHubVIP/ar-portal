class_name StartYard
extends RefCounted
## Двор «Похмельная» — старт MAIN_001. С 0.19 (D-061) это рисованная диорама на сетке
## (data/yard_diorama.txt): клетка 3 × 3 м, весь двор 72 × 78 м вместо прежних 222 × 208.
## Плиты мощения и тропы — отдельные гранёные плитки разного тона, как на референсах;
## две террасы на 1,2 м с каменными подпорными стенами, мхом и лестницами; пруд с кувшинками.
## По краям — северные корпуса с аркой выхода, западный дом с балконом Зины, ряд гаражей
## (№13 — вход на базу), на юге — будка, шлагбаум и такси. Всё сюжетное стоит на ровной
## земле (y = 0): на террасах только сквер, площадка, домино и выбивалка.

const CELL := 3.0
const GRID_ORIGIN := Vector2(-36, -153)
const TERRACE_H := 1.2
const MAP_PATH := "res://data/yard_diorama.txt"

const BOUNDS := Rect2(-36, -153, 72, 78)
const COURT := Rect2(-36, -141, 72, 66)
const ARCH_HALF_W := 3.0
const EXIT_ARCH := Vector3(0, 0, -141)
const EAST_GAP := Vector2(-94, -82)
const KIOSK := Vector3(19, 0, -124)
const PAVEL := Vector3(10, 0, -118)
const BOOTH := Vector3(19, 0, -88)
const BARRIER := Vector3(13, 0, -79)
const GARAGE_13 := Vector3(28.5, 0, -112.5)
const QUEUE := Vector3(-21, 0, -110)
const ZINA_BALCONY := Vector3(-26.2, 3.2, -122)
const NEON_PINK := Color(1.0, 0.3, 0.75)
const NEON_WARM := Color(1.0, 0.78, 0.4)
const LAMPS_KEY := Vector2i(-99, -99)

const WEST_BLOCK := Rect2(-36, -135, 9, 36)
const WING_W := Rect2(-36, -153, 33, 12)
const WING_E := Rect2(3, -153, 33, 12)
const GARAGES := Rect2(30, -135, 6, 40)
const PARKING := Rect2(-21, -117, 24, 15)

## Тона плиток: каждая клетка своя — «шахматка» рисованной карты.
const GRASS_TONES := [Color(0.36, 0.56, 0.2), Color(0.42, 0.6, 0.22), Color(0.32, 0.5, 0.2), Color(0.46, 0.62, 0.26),
	Color(0.38, 0.54, 0.24)]
const PATH_TONES := [Color(0.72, 0.58, 0.4), Color(0.78, 0.64, 0.44), Color(0.66, 0.53, 0.37), Color(0.74, 0.62, 0.46)]
const SLAB_TONES := [Color(0.66, 0.62, 0.56), Color(0.6, 0.57, 0.52), Color(0.7, 0.66, 0.58), Color(0.56, 0.55, 0.52),
	Color(0.64, 0.6, 0.5)]
const STONE_TONES := [Color(0.5, 0.48, 0.45), Color(0.56, 0.53, 0.48), Color(0.45, 0.45, 0.44), Color(0.6, 0.56, 0.5)]
const MOSS := Color(0.34, 0.52, 0.18)

static var _grid: PackedStringArray = []
static var _extra_lamps := PackedVector3Array()
static var _parked: Dictionary = {}          # сетка машины → её места
static var _yb: DistrictDressing.Batch       # общий пакет двора: плитки, стены, зелень — несколько MultiMesh
static var _slab_mesh: ArrayMesh


static func build(w: Node3D) -> void:
	_grid = grid()
	_extra_lamps = PackedVector3Array()
	_yb = DistrictDressing.Batch.new()
	_tiles(w)
	_terraces(w)
	_pond(w)
	_greenery()
	_houses(w)
	_arch(w)
	_garages(w)
	_lot(w)
	_kiosk(w)
	_booth(w)
	_yard_life(w)
	_story(w)
	_walls_talk(w)
	_trash(w)
	_bounds(w)
	_yb.lamps.append_array(_extra_lamps)
	for step in DistrictDressing.flush_steps(w, LAMPS_KEY, _yb):
		step.call()
	_flush_tiles(w)


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


# ---------- сетка ----------

## Строки карты без комментариев: 26 строк по 24 клетки.
static func grid() -> PackedStringArray:
	var out := PackedStringArray()
	var f := FileAccess.open(MAP_PATH, FileAccess.READ)
	while f != null and not f.eof_reached():
		var line := f.get_line()
		if line.is_empty() or line.begins_with(";"):
			continue
		out.append(line)
	return out


static func tile_at(i: int, j: int) -> String:
	if j < 0 or j >= _grid.size() or i < 0 or i >= _grid[j].length():
		return " "
	return _grid[j][i]


static func cell_center(i: int, j: int, y := 0.0) -> Vector3:
	return Vector3(GRID_ORIGIN.x + (i + 0.5) * CELL, y, GRID_ORIGIN.y + (j + 0.5) * CELL)


static func is_terrace(ch: String) -> bool:
	return ch in ["#", "Y", "B", "F"]


static func is_stair(ch: String) -> bool:
	return ch in ["^", "v", "<", ">"]


## Высота земли в точке двора: верх террасы или 0.
static func ground_y(x: float, z: float) -> float:
	if _grid.is_empty():
		_grid = grid()
	var i := int(floor((x - GRID_ORIGIN.x) / CELL))
	var j := int(floor((z - GRID_ORIGIN.y) / CELL))
	return TERRACE_H if is_terrace(tile_at(i, j)) else 0.0


# ---------- плитки ----------

## Гранёная плита 1 × 1 × 1 с фаской по верху: из неё масштабом — плиты мощения, тропы, газон.
static func slab_mesh() -> ArrayMesh:
	if _slab_mesh != null:
		return _slab_mesh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var b := 0.5
	var t := 0.47            # верх чуть уже низа — узкая фаска, швы читаются, но не чернеют
	var lo := [Vector3(-b, 0, -b), Vector3(b, 0, -b), Vector3(b, 0, b), Vector3(-b, 0, b)]
	var hi := [Vector3(-t, 1, -t), Vector3(t, 1, -t), Vector3(t, 1, t), Vector3(-t, 1, t)]
	_quad(st, hi[0], hi[1], hi[2], hi[3])
	for k in 4:
		var n := (k + 1) % 4
		_quad(st, lo[n], lo[k], hi[k], hi[n])
	st.generate_normals()
	_slab_mesh = st.commit()
	return _slab_mesh


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for v in [a, c, b, a, d, c]:
		st.add_vertex(v)


static var _tiles_list: Array = []


static func _tile(at: Vector3, size: Vector3, col: Color, yaw := 0.0) -> void:
	_tiles_list.append([Transform3D(Basis(Vector3.UP, yaw) * Basis.from_scale(size), at), col])


static func _tiles(w: Node3D) -> void:
	_tiles_list = []
	# подложка-затирка: в швах между плитками тёмная земля, а не газон района
	var grout := Kit.box(w, Vector3(BOUNDS.size.x, 0.04, BOUNDS.size.y - 12.0), Vector3(BOUNDS.get_center().x, 0.02, BOUNDS.get_center().y + 6.0),
			Color(0.3, 0.25, 0.19))
	grout.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	grout.set_meta("map_skip", true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 19019
	for j in _grid.size():
		for i in _grid[j].length():
			var ch := tile_at(i, j)
			var c := cell_center(i, j)
			match ch:
				"c":
					# плита 3 × 3 м из четырёх плиток по 1,5 м: сетка видна, как на картинке
					for k in 4:
						var off := Vector3((k % 2 - 0.5) * 1.5, 0, (k / 2 - 0.5) * 1.5)
						_tile(c + off + Vector3(0, rng.randf_range(0.0, 0.03), 0), Vector3(1.42, 0.12, 1.42),
								SLAB_TONES[rng.randi() % SLAB_TONES.size()].darkened(rng.randf_range(0.0, 0.08)))
				"P":
					for k in 4:
						var off2 := Vector3((k % 2 - 0.5) * 1.5, 0, (k / 2 - 0.5) * 1.5)
						_tile(c + off2, Vector3(1.42, 0.12, 1.42), SLAB_TONES[rng.randi() % SLAB_TONES.size()])
					Props.collider(w, Vector3(2.4, 0.7, 2.4), c + Vector3(0, 0.35, 0)).set_meta("map_skip", true)
				",":
					_tile(c + Vector3(0, rng.randf_range(0.0, 0.02), 0), Vector3(2.96, 0.08, 2.96),
							PATH_TONES[rng.randi() % PATH_TONES.size()].darkened(rng.randf_range(0.0, 0.06)))
				".", "T", "b", "r", "f", "h":
					_tile(c, Vector3(2.98, 0.05, 2.98), GRASS_TONES[rng.randi() % GRASS_TONES.size()].darkened(rng.randf_range(0.0, 0.08)))
				_:
					if is_terrace(ch) or is_stair(ch):
						var tone: Color = GRASS_TONES[rng.randi() % GRASS_TONES.size()].lightened(0.05)
						if not is_stair(ch):
							_tile(c + Vector3(0, TERRACE_H, 0), Vector3(2.98, 0.07, 2.98), tone.darkened(rng.randf_range(0.0, 0.08)))


static func _flush_tiles(w: Node3D) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = slab_mesh()
	mm.instance_count = _tiles_list.size()
	for k in _tiles_list.size():
		mm.set_instance_transform(k, _tiles_list[k][0])
		mm.set_instance_color(k, _tiles_list[k][1])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "YardTiles"
	mmi.multimesh = mm
	mmi.material_override = DistrictDressing._material("plain")
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.set_meta("map_skip", true)
	w.add_child(mmi)
	_tiles_list = []


# ---------- террасы ----------

## Терраса: тело-коробка на клетку (коллизия), каменная кладка там, где сосед ниже,
## мох по кромке и плющ, свисающий со стены. Лестница — наклонная коллизия и ступени.
static func _terraces(w: Node3D) -> void:
	var b := _yb
	var rng := RandomNumberGenerator.new()
	rng.seed = 1912
	var body := StaticBody3D.new()
	body.name = "YardTerraces"
	body.set_meta("map_skip", true)
	w.add_child(body)
	var dirs := {"^": Vector2i(0, -1), "v": Vector2i(0, 1), "<": Vector2i(-1, 0), ">": Vector2i(1, 0)}
	for j in _grid.size():
		for i in _grid[j].length():
			var ch := tile_at(i, j)
			var c := cell_center(i, j)
			if is_terrace(ch):
				var cs := CollisionShape3D.new()
				var bs := BoxShape3D.new()
				bs.size = Vector3(CELL, TERRACE_H, CELL)
				cs.shape = bs
				cs.position = c + Vector3(0, TERRACE_H / 2.0, 0)
				body.add_child(cs)
				# тёмная земля внутри — чтобы в щели кладки не просвечивало
				b.box("plain", c + Vector3(0, TERRACE_H / 2.0, 0), Vector3(CELL - 0.3, TERRACE_H, CELL - 0.3), 0.0, Color(0.28, 0.22, 0.16))
				for d: Vector2i in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
					var n := tile_at(i + d.x, j + d.y)
					if is_terrace(n) or is_stair(n):
						continue
					_wall(b, c, Vector3(d.x, 0, d.y), rng)
			elif is_stair(ch):
				_stairs(w, body, b, c, dirs[ch], rng)


## Подпорная стенка на краю клетки: два ряда тёсаных камней вразбежку, моховая шапка, плющ.
static func _wall(b: DistrictDressing.Batch, c: Vector3, n: Vector3, rng: RandomNumberGenerator) -> void:
	var side := Vector3(-n.z, 0, n.x)
	var face := c + n * (CELL / 2.0 - 0.2)
	var yaw := atan2(side.x, side.z)
	for row in 2:
		var u := -CELL / 2.0 + (0.0 if row == 0 else 0.5)
		var y := 0.3 + row * 0.6
		while u < CELL / 2.0 - 0.05:
			var ln := minf(rng.randf_range(0.8, 1.3), CELL / 2.0 - u)
			if ln > 0.25:
				var col: Color = STONE_TONES[rng.randi() % STONE_TONES.size()].darkened(rng.randf_range(0.0, 0.12))
				b.box("plain", face + side * (u + ln / 2.0) + Vector3(0, y, 0) + n * rng.randf_range(0.0, 0.06),
						Vector3(0.5, 0.56, ln - 0.06), yaw, col)
			u += ln
	# мох по кромке и зелёные пряди вниз по стене
	b.box("plain", face + n * 0.12 + Vector3(0, TERRACE_H + 0.04, 0), Vector3(0.42, 0.16, CELL + 0.1), yaw,
			MOSS.darkened(rng.randf_range(0.0, 0.15)))
	for k in rng.randi_range(0, 3):
		var ln := rng.randf_range(0.4, 1.0)
		b.box("plain", face + n * 0.3 + side * rng.randf_range(-1.3, 1.3) + Vector3(0, TERRACE_H - ln / 2.0, 0),
				Vector3(0.06, ln, 0.35), yaw, Color(0.3, 0.48, 0.16).darkened(rng.randf_range(0.0, 0.2)))
	if rng.randf() < 0.35:
		DistrictDressing._bush(b, c + n * (CELL / 2.0 + 0.5) + side * rng.randf_range(-1.0, 1.0), rng, 0.6)


## Лестница: четыре ступени по 0,3 м вниз в сторону d, по бокам — каменные щёки.
static func _stairs(w: Node3D, body: StaticBody3D, b: DistrictDressing.Batch, c: Vector3, d: Vector2i,
		rng: RandomNumberGenerator) -> void:
	var down := Vector3(d.x, 0, d.y)
	var side := Vector3(-down.z, 0, down.x)
	var yaw := atan2(side.x, side.z)
	for k in 4:
		var h := TERRACE_H - k * 0.3
		var at := c - down * CELL / 2.0 + down * (k * 0.75 + 0.375)
		b.box("plain", at + Vector3(0, h / 2.0, 0), Vector3(0.75, h, CELL - 0.6), yaw,
				STONE_TONES[(k + rng.randi()) % STONE_TONES.size()].lightened(0.08))
	for s: float in [-1.0, 1.0]:
		b.box("plain", c + side * s * (CELL / 2.0 - 0.15) + Vector3(0, TERRACE_H / 2.0 + 0.1, 0), Vector3(0.3, TERRACE_H + 0.2, CELL),
				atan2(down.x, down.z), STONE_TONES[0].darkened(0.1))
		b.box("plain", c + side * s * (CELL / 2.0 - 0.15) + Vector3(0, TERRACE_H + 0.25, 0), Vector3(0.36, 0.1, CELL + 0.05),
				atan2(down.x, down.z), MOSS)
	# пандус под ступенями: 22° — герой поднимается без прыжка
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	var run := Vector2(CELL, TERRACE_H)
	bs.size = Vector3(CELL - 0.6, 0.2, run.length())
	cs.shape = bs
	var tilt := atan2(TERRACE_H, CELL)
	cs.basis = Basis(Vector3.UP, atan2(down.x, down.z)) * Basis(Vector3.RIGHT, tilt)
	cs.position = c + Vector3(0, TERRACE_H / 2.0 - 0.1, 0)
	body.add_child(cs)
	for s: float in [-1.0, 1.0]:
		var wall := CollisionShape3D.new()
		var wb := BoxShape3D.new()
		wb.size = Vector3(0.3, TERRACE_H + 0.2, CELL) if d.y != 0 else Vector3(CELL, TERRACE_H + 0.2, 0.3)
		wall.shape = wb
		wall.position = c + side * s * (CELL / 2.0 - 0.15) + Vector3(0, TERRACE_H / 2.0 + 0.1, 0)
		body.add_child(wall)


# ---------- пруд ----------

static func _pond(w: Node3D) -> void:
	var cells: Array = []
	for j in _grid.size():
		for i in _grid[j].length():
			if tile_at(i, j) == "~":
				cells.append(cell_center(i, j))
	if cells.is_empty():
		return
	var lo: Vector3 = cells[0]
	var hi: Vector3 = cells[0]
	for c: Vector3 in cells:
		lo = Vector3(minf(lo.x, c.x), 0, minf(lo.z, c.z))
		hi = Vector3(maxf(hi.x, c.x), 0, maxf(hi.z, c.z))
	var size := Vector3(hi.x - lo.x + CELL, 0, hi.z - lo.z + CELL)
	var mid := (lo + hi) / 2.0
	var water := Kit.box(w, Vector3(size.x - 0.6, 0.06, size.z - 0.6), mid + Vector3(0, 0.04, 0), Color(0.18, 0.42, 0.42))
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.46, 0.46)
	mat.roughness = 0.08
	mat.metallic_specular = 0.9
	water.material_override = mat
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	water.set_meta("map_skip", true)
	Props.collider(w, Vector3(size.x - 0.6, 1.0, size.z - 0.6), mid + Vector3(0, 0.5, 0)).set_meta("map_skip", true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1919
	# бортик из валунов и кувшинки, один жёлтый утёнок-пищалка
	var per := 2.0 * (size.x + size.z)
	var t := 0.0
	while t < per:
		var p: Vector3
		if t < size.x:
			p = lo + Vector3(-CELL / 2.0 + t, 0, -CELL / 2.0)
		elif t < size.x + size.z:
			p = lo + Vector3(size.x - CELL / 2.0, 0, -CELL / 2.0 + t - size.x)
		elif t < 2.0 * size.x + size.z:
			p = lo + Vector3(size.x - CELL / 2.0 - (t - size.x - size.z), 0, size.z - CELL / 2.0)
		else:
			p = lo + Vector3(-CELL / 2.0, 0, size.z - CELL / 2.0 - (t - 2.0 * size.x - size.z))
		_yb.add("rock", Transform3D(Basis(Vector3.UP, rng.randf() * TAU) * Basis.from_scale(Vector3(rng.randf_range(0.8, 1.3), rng.randf_range(0.4, 0.7), rng.randf_range(0.7, 1.1))),
				p + Vector3(0, 0.15, 0)), STONE_TONES[rng.randi() % STONE_TONES.size()])
		t += rng.randf_range(0.8, 1.3)
	for k in 7:
		var p := mid + Vector3(rng.randf_range(-size.x / 2.0 + 1.2, size.x / 2.0 - 1.2), 0.09, rng.randf_range(-size.z / 2.0 + 1.2, size.z / 2.0 - 1.2))
		_yb.add("tank", Transform3D(Basis().scaled(Vector3(0.9, 0.02, 0.9)), p), Color(0.3, 0.55, 0.2))
		if k % 3 == 0:
			_yb.add("veg", Transform3D(Basis().scaled(Vector3(0.25, 0.2, 0.25)), p + Vector3(0.1, 0.1, 0)), Color(1.0, 0.75, 0.85))
	var duck := mid + Vector3(0.8, 0.15, -0.5)
	_yb.add("veg", Transform3D(Basis().scaled(Vector3(0.35, 0.25, 0.45)), duck), Color(1.0, 0.85, 0.15))
	_yb.add("veg", Transform3D(Basis().scaled(Vector3(0.22, 0.22, 0.22)), duck + Vector3(0, 0.2, -0.18)), Color(1.0, 0.85, 0.15))
	_yb.add("veg", Transform3D(Basis().scaled(Vector3(0.1, 0.06, 0.12)), duck + Vector3(0, 0.18, -0.32)), Color(1.0, 0.45, 0.1))
	_sign(w, "КУПАНИЕ ПО ЗАПИСИ\nЧЕРЕЗ ГОСУСЛУГИ ФЛОТА", lo + Vector3(-CELL / 2.0 - 0.6, 1.4, -CELL / 2.0 - 0.2), 0.0, 0.22,
			Color(0.1, 0.1, 0.1), "board", {"bg": Color(0.95, 0.92, 0.8)})


# ---------- зелень по клеткам ----------

static func _greenery() -> void:
	var b := _yb
	var rng := RandomNumberGenerator.new()
	rng.seed = 1918
	for j in _grid.size():
		for i in _grid[j].length():
			var ch := tile_at(i, j)
			var y := TERRACE_H if is_terrace(ch) else 0.0
			var c := cell_center(i, j, y) + Vector3(rng.randf_range(-0.5, 0.5), 0, rng.randf_range(-0.5, 0.5))
			match ch:
				"T", "Y":
					DistrictDressing._tree(b, c, rng, rng.randf_range(1.3, 1.7), false)
				"b", "B":
					DistrictDressing._bush(b, c, rng, rng.randf_range(0.9, 1.3))
					if rng.randf() < 0.5:
						DistrictDressing._bush(b, c + Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)), rng, 0.7)
				"r":
					DistrictDressing._rock(b, c, rng, rng.randf_range(0.9, 1.3))
				"P":
					# дерево в каменной кадке посреди мощения, вокруг кадки — лавочка-кольцо
					var pc := cell_center(i, j)
					b.add("tank", Transform3D(Basis().scaled(Vector3(2.4, 0.6, 2.4)), pc + Vector3(0, 0.3, 0)), STONE_TONES[1].lightened(0.1))
					b.add("tank", Transform3D(Basis().scaled(Vector3(2.1, 0.05, 2.1)), pc + Vector3(0, 0.62, 0)), Color(0.3, 0.22, 0.14))
					b.add("tank", Transform3D(Basis().scaled(Vector3(2.7, 0.08, 2.7)), pc + Vector3(0, 0.6, 0)), Color(0.55, 0.38, 0.22))
					DistrictDressing._tree(b, pc + Vector3(0, 0.6, 0), rng, 1.2, false)
				"f", "F":
					_flowerbed(b, c, rng)
				"h":
					for k in 3:
						DistrictDressing._bush(b, cell_center(i, j) + Vector3(-1.0 + k * 1.0, 0, 0.6), rng, 0.75)
				"#":
					# газон террасы: редкие цветы и травяные кочки
					if rng.randf() < 0.3:
						DistrictDressing._bush(b, c, rng, 0.5)


## Клумба: каменный бортик кругом и цветы трёх цветов.
static func _flowerbed(b: DistrictDressing.Batch, c: Vector3, rng: RandomNumberGenerator) -> void:
	for k in 10:
		var a := TAU * k / 10.0
		b.add("rock", Transform3D(Basis(Vector3.UP, a) * Basis.from_scale(Vector3(0.5, 0.3, 0.4)), c + Vector3(cos(a) * 1.1, 0.12, sin(a) * 1.1)),
				STONE_TONES[k % STONE_TONES.size()].lightened(0.1))
	b.add("tank", Transform3D(Basis().scaled(Vector3(2.0, 0.2, 2.0)), c + Vector3(0, 0.1, 0)), Color(0.3, 0.2, 0.12))
	var cols := [Color(1.0, 0.45, 0.55), Color(1.0, 0.85, 0.3), Color(0.7, 0.5, 1.0), Color(1.0, 1.0, 0.95)]
	for k in 14:
		var p := c + Vector3(rng.randf_range(-0.75, 0.75), 0.32 + rng.randf_range(0.0, 0.15), rng.randf_range(-0.75, 0.75))
		b.add("veg", Transform3D(Basis().scaled(Vector3.ONE * rng.randf_range(0.18, 0.28)), p), cols[rng.randi() % cols.size()])
	DistrictDressing._bush(b, c, rng, 0.45)


static func _c3(r: Rect2, y := 0.0) -> Vector3:
	return Vector3(r.get_center().x, y, r.get_center().y)


static func _sign(w: Node3D, text: String, pos: Vector3, yaw_deg: float, height: float, color: Color, kind := "neon",
		opts := {}) -> Signboard:
	return Signboard.make(w, text, kind, color, pos, yaw_deg, height, opts)


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
	var nw := _house(w, WING_W, 5, true, 2541)
	var ne := _house(w, WING_E, 5, true, 2542)
	var west := _house(w, WEST_BLOCK, 5, false, 2565)
	for e: Vector3 in nw.entrances + ne.entrances + west.entrances:
		if COURT.grow(1.0).has_point(Vector2(e.x, e.z)):
			_extra_lamps.append(e + Vector3(0, 2.4, 0))
	# неоновые вывески на корпусах
	var face_x := WEST_BLOCK.end.x + 0.05
	_sign(w, "ИНТИМ 24/7", Vector3(face_x, 7.6, -128), 90.0, 0.85, NEON_PINK, "neon", {"flicker": true})
	_sign(w, "теперь с щупальцами", Vector3(face_x, 6.6, -128), 90.0, 0.42, Color(0.5, 1, 0.8), "letters", {"font": "script"})
	_sign(w, "КЛАНЯЙТЕСЬ ТАРЕЛКЕ —\nЭТО БЕСПЛАТНО*", Vector3(face_x, 11.0, -106), 90.0, 0.8, Color.WHITE, "lightbox",
			{"bg": Color(0.25, 0.55, 0.95), "ink": Color(1, 1, 1)})
	_sign(w, "*при наличии согласия", Vector3(face_x, 9.4, -106), 90.0, 0.32, Color(0.1, 0.12, 0.2), "board",
			{"bg": Color(0.85, 0.88, 0.95)})
	var fz := WING_W.end.y + 0.05
	_sign(w, "ЛОМБАРД\n«ВЕЧНОСТЬ»", Vector3(-18, 4.4, fz), 0.0, 0.7, Color(0.3, 1, 0.8), "neon", {"flicker": true})
	_sign(w, "ШАУРМА 24\nДАЖЕ ПОСЛЕ КОНЦА СВЕТА", Vector3(14, 4.2, fz), 0.0, 0.5, Color.WHITE,
			"lightbox", {"bg": Color(1.0, 0.82, 0.25), "ink": Color(0.6, 0.08, 0.05)})
	_sign(w, "КЛУБ\n«ТРИДЦАТЬ ЛАЙКОВ»", Vector3(30, 7.5, fz), 0.0, 0.7, Color(0.9, 0.3, 1), "neon", {"flicker": true})


## Арка: дом над проходом между корпусами, мостовая, кирпичная рамка с фонарём.
static func _arch(w: Node3D) -> void:
	var z0 := WING_W.position.y
	var depth := WING_W.size.y
	var h := 15.4
	var brick := BuildingKit.BRICK[1]
	var top_h := h - 5.2
	var top := Props.collider(w, Vector3(ARCH_HALF_W * 2.0, top_h, depth), Vector3(0, 5.2 + top_h / 2.0, z0 + depth / 2.0), true)
	var tm := MeshInstance3D.new()
	tm.mesh = BuildingKit.block(ARCH_HALF_W * 2.0, depth, top_h, true, brick, Color(0.32, 0.3, 0.28))
	tm.position = Vector3(0, -top_h / 2.0, 0)
	top.add_child(tm)
	Kit.box(w, Vector3(ARCH_HALF_W * 2.0, 0.2, depth), Vector3(0, 5.1, z0 + depth / 2.0), Color(0.18, 0.15, 0.13))
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
	var n := 8
	var gw := GARAGES.size.y / n
	for i in n:
		var r := Rect2(GARAGES.position.x, GARAGES.position.y + i * gw, GARAGES.size.x, gw)
		var c := _c3(r)
		var body := Props.collider(w, Vector3(r.size.x, 3.0, r.size.y), c + Vector3(0, 1.5, 0))
		Kit.box(body, Vector3(r.size.x, 3.0, r.size.y - 0.1), Vector3.ZERO, Color(0.62, 0.55, 0.45).lerp(Color(0.7, 0.45, 0.32), rng.randf() * 0.6))
		# скатная крыша-козырёк, рыжая, чуть свисает к двору
		var roof := Kit.box(body, Vector3(r.size.x + 0.9, 0.22, r.size.y + 0.2), Vector3(-0.3, 1.65, 0), Color(0.62, 0.3, 0.2).darkened(rng.randf() * 0.2))
		roof.rotation_degrees.z = -6.0
		var front_x := r.position.x - 0.03
		var col: Color = Color(0.85, 0.6, 0.15) if i == 4 else doors[rng.randi() % doors.size()]
		Kit.box(w, Vector3(0.08, 2.3, r.size.y - 1.0), Vector3(front_x, 1.15, c.z), col)
		if rng.randf() < 0.5 and i != 4:
			Signboard.make(w, DistrictDressing.GRAFFITI[rng.randi() % DistrictDressing.GRAFFITI.size()], "graffiti",
					DistrictDressing.GRAFFITI_COLORS[rng.randi() % DistrictDressing.GRAFFITI_COLORS.size()],
					Vector3(front_x - 0.03, 2.5, c.z), -90.0, 0.3, {"far": DistrictDressing.SIGN_FAR_M})
		if rng.randf() < 0.5:
			_yb.model("tires", Vector3(front_x - 1.2, 0, c.z + rng.randf_range(-1.5, 1.5)), rng.randf() * TAU)
	Signboard.make(w, "ГАРАЖ №13", "board", Color(0.1, 0.08, 0.05), Vector3(GARAGES.position.x - 0.08, 2.75, GARAGE_13.z), -90.0, 0.4,
			{"bg": Color(1.0, 0.8, 0.3), "lamp": true})
	Signboard.make(w, "ГСК «ЧЕК ЭНДЖИН»", "letters", Color(1.0, 0.55, 0.2), Vector3(GARAGES.position.x - 0.1, 4.0, -101), -90.0, 0.8)


# ---------- парковка ----------

static func _lot(w: Node3D) -> void:
	var r := PARKING
	var asphalt := Kit.box(w, Vector3(r.size.x, 0.08, r.size.y), _c3(r, 0.06), Color.WHITE)
	asphalt.material_override = Surfaces.ground("asphalt", 4.0, Color(1.6, 1.6, 1.72), Color(0.8, 0.8, 0.84), 0.5, 0.35,
			[Color(1.08, 1.06, 1.02), Color(0.84, 0.88, 0.94), 0.7])
	asphalt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	asphalt.set_meta("map_skip", true)
	var x := r.position.x + 1.0
	while x <= r.end.x - 1.0:
		Kit.box(w, Vector3(0.14, 0.02, 4.6), Vector3(x, 0.11, r.position.y + 2.4), Color(0.92, 0.9, 0.84))
		Kit.box(w, Vector3(0.14, 0.02, 4.6), Vector3(x, 0.11, r.end.y - 2.4), Color(0.92, 0.9, 0.84))
		x += 2.8
	for side: float in [-1.0, 1.0]:
		Kit.box(w, Vector3(r.size.x, 0.2, 0.25), Vector3(r.get_center().x, 0.1, r.get_center().y + side * r.size.y / 2.0),
				Color(0.62, 0.6, 0.56))
		Kit.box(w, Vector3(0.25, 0.2, r.size.y), Vector3(r.get_center().x + side * r.size.x / 2.0, 0.1, r.get_center().y),
				Color(0.62, 0.6, 0.56))
	var label := Kit.label(w, "ПАРКОВКА «ПОХМЕЛЬНАЯ»", Vector3(r.get_center().x + 4, 0.12, r.get_center().y + 1.5), 60,
			Color(1, 1, 1, 0.45), false)
	label.rotation_degrees = Vector3(-90, 0, 0)
	label.outline_size = 0
	# места вдоль краёв заняты наполовину; у кабриолета и находок — пусто
	var rng := RandomNumberGenerator.new()
	rng.seed = 2672
	var cars := [Color(0.9, 0.88, 0.82), Color(0.25, 0.32, 0.5), Color(0.55, 0.2, 0.16), Color(0.4, 0.42, 0.36),
		Color(0.75, 0.62, 0.3), Color(0.3, 0.45, 0.42)]
	for row: float in [r.position.y + 2.4, r.end.y - 2.4]:
		var slot := r.position.x + 2.4
		while slot < r.end.x - 1.5:
			# у кабриолета и находок (телефон, ботинок, уведомление) места пустые
			var near_story := (slot > -18.0 and slot < 3.5 and row < r.get_center().y) or (slot > -8.5 and slot < 0.5 and row > r.get_center().y)
			if not near_story and rng.randf() < 0.6:
				_car(w, Vector3(slot, 0, row), rng.randf_range(-0.1, 0.1) + (PI if rng.randf() < 0.5 else 0.0),
						cars[rng.randi() % cars.size()])
			slot += 2.8
	_flush_cars(w)
	# столбики по восточному краю
	var z := r.position.y + 1.5
	while z < r.end.y - 1.0:
		var p := Vector3(r.end.x + 0.8, 0, z)
		DistrictSites._b(_yb, p + Vector3(0, 0.45, 0), Vector3(0.22, 0.9, 0.22), Color(0.2, 0.2, 0.22))
		DistrictSites._b(_yb, p + Vector3(0, 0.75, 0), Vector3(0.24, 0.12, 0.24), Color(0.95, 0.8, 0.15))
		z += 3.2


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
	for k in 4:
		Props.place(w, ["boxes", "beer_crate", "trash_bags", "boxes"][k], KIOSK + Vector3(-4.0 + k * 2.2, 0, 3.6 + (k % 2)), k * 47.0)
	Kit.box(w, Vector3(2.6, 0.08, 1.6), KIOSK + Vector3(3.5, 0.3, 3.2), Color(0.55, 0.7, 0.8, 0.6)).rotation_degrees.z = 14.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 2626
	_yb.model("tires", KIOSK + Vector3(4.6, 0, 3.0), 0.3)
	for k in 8:
		DistrictSites._b(_yb, KIOSK + Vector3(-3.0 + rng.randf_range(-1.5, 1.5), 0.15, 5.5 + rng.randf_range(-1, 1)),
				Vector3(0.08, 0.3, 0.08), [Color(0.2, 0.45, 0.2), Color(0.45, 0.3, 0.15), Color(0.85, 0.85, 0.8)][k % 3])


static func _booth(w: Node3D) -> void:
	var yaw := 0.0
	Props.collider(w, Vector3(3.4, 2.8, 2.4), BOOTH + Vector3(0, 1.4, 0))
	Props.place(w, "parking_booth", BOOTH, yaw)
	_sign(w, "ПАРКОВКА\nПЛАТНАЯ.\nСОН ТОЖЕ.", BOOTH + Vector3(0, 2.0, 1.45), yaw, 0.42, Color(0.1, 0.08, 0.06), "lightbox",
			{"bg": Color(1.0, 0.92, 0.78), "ink": Color(0.1, 0.08, 0.06)})
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
	Props.collider(w, Vector3(1.8, 1.4, 4.3), BOOTH + Vector3(7.5, 0.7, 2))
	Props.place(w, "taxi", BOOTH + Vector3(7.5, 0, 2), 180.0)
	var pole := BOOTH + Vector3(10, 0, 4.6)
	Props.place(w, "taxi_sign", pole, 0.0)
	_sign(w, "ТАКСИ", pole + Vector3(0, 2.62, 0.09), 0.0, 0.27, Color(0.1, 0.08, 0.05), "board", {"bg": Color(0.98, 0.8, 0.15)})
	# паркомат «оплата снами»
	var meter := BOOTH + Vector3(-4.2, 0, 2.2)
	DistrictSites._b(_yb, meter + Vector3(0, 0.75, 0), Vector3(0.35, 1.5, 0.3), Color(0.55, 0.58, 0.6))
	DistrictSites._b(_yb, meter + Vector3(0, 1.2, 0.16), Vector3(0.22, 0.16, 0.02), Color(0.3, 0.9, 0.6), 0.0, "glow")
	Props.collider(w, Vector3(0.4, 1.5, 0.35), meter + Vector3(0, 0.75, 0))
	_sign(w, "ОПЛАТА СНАМИ", meter + Vector3(0, 1.75, 0.17), 0.0, 0.16, Color(0.1, 0.1, 0.1), "board",
			{"bg": Color(0.95, 0.85, 0.2)})


# ---------- жизнь двора ----------

## Террасы — сквер (домино, лавки, бельё) и площадка (качели, клумбы из шин, выбивалка);
## у подъездов бабушки на лавках, у тропы инспектор-пришелец с ховербайком.
static func _yard_life(w: Node3D) -> void:
	var b := _yb
	var rng := RandomNumberGenerator.new()
	rng.seed = 2612
	var top := TERRACE_H
	# сквер на северо-западной террасе: доминошный стол «рыба!»
	var dom := Vector3(-12, top, -129)
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
	b.model("bench", Vector3(-17, top, -125.5), 0.0)
	# бельё на террасе
	var at := Vector3(-5.5, top, -131)
	batch_laundry(b, at, rng)
	# площадка на юго-западной террасе
	DistrictDressing._playground(b, Vector3(-17, top, -92), 0.0, rng)
	var tyre_cols := [Color(0.95, 0.85, 0.2), Color(0.9, 0.25, 0.2), Color(0.25, 0.55, 0.9), Color(0.95, 0.95, 0.92)]
	var bed := Vector3(-8, top, -89)
	for k in 6:
		var p := bed + Vector3(cos(TAU * k / 6.0) * 1.3, 0, sin(TAU * k / 6.0) * 1.3)
		b.add("tank", Transform3D(Basis().scaled(Vector3(0.8, 0.3, 0.8)), p + Vector3(0, 0.15, 0)), tyre_cols[k % tyre_cols.size()])
		b.add("veg", Transform3D(Basis().scaled(Vector3.ONE * 0.5), p + Vector3(0, 0.42, 0)),
				[Color(0.95, 0.4, 0.3), Color(0.98, 0.8, 0.25), Color(0.75, 0.4, 0.9)][k % 3])
	Props.collider(w, Vector3(9, 2.5, 7), Vector3(-15, top + 1.2, -90))
	# выбивалка с ковром на краю площадки
	var beat := Vector3(-20.5, top, -84)
	for sx: float in [-1.0, 1.0]:
		DistrictSites._b(b, beat + Vector3(sx * 2.0, 1.1, 0), Vector3(0.08, 2.2, 0.08), Color(0.3, 0.32, 0.35))
	DistrictSites._b(b, beat + Vector3(0, 2.2, 0), Vector3(4.1, 0.08, 0.08), Color(0.3, 0.32, 0.35))
	DistrictSites._b(b, beat + Vector3(0, 1.45, 0.04), Vector3(2.6, 1.5, 0.04), Color(0.62, 0.12, 0.12))
	DistrictSites._b(b, beat + Vector3(0, 1.45, 0.07), Vector3(1.8, 1.0, 0.02), Color(0.12, 0.2, 0.45))
	DistrictSites._b(b, beat + Vector3(0, 1.45, 0.09), Vector3(0.8, 0.5, 0.02), Color(0.92, 0.8, 0.35))
	Props.collider(w, Vector3(4.2, 2.3, 0.3), beat + Vector3(0, 1.15, 0))
	DistrictSites._person(w, beat + Vector3(0.6, 0, -1.4), 0.0, rng, {"skirt": true, "style": "bun"})
	# бабушки на лавках у подъездов
	for e: Vector3 in _extra_lamps.slice(0, 4):
		var p := e - Vector3(0, 2.4, 0) + Vector3(2.8, 0, 0.6)
		if not COURT.has_point(Vector2(p.x, p.z)) or absf(p.z - EXIT_ARCH.z) > 6.0:
			continue
		b.model("bench", p, PI)
		Props.collider(w, Vector3(2.4, 0.5, 0.7), p + Vector3(0, 0.25, 0))
		for k in 2:
			DistrictSites._person(w, p + Vector3(-0.5 + k * 1.0, 0, 0.2), PI, rng, {"skirt": true, "style": "bun",
					"hair": Color(0.85, 0.85, 0.82)})
	# огородики за западным домом
	DistrictDressing._garden(b, Vector3(-31.5, 0, -91), Vector2(6, 5), rng)
	DistrictDressing._garden(b, Vector3(-31.5, 0, -83), Vector2(6, 5), rng)
	# инспектор парковки: пришелец в жилетке и ховербайк
	var warden := Vector3(6.5, 0, -99)
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
	Kit.box(bike, Vector3(0.75, 0.06, 2.05), Vector3(0, -0.17, 0), Color(0.7, 0.3, 1.0), 4.0)
	bike.create_tween().set_loops().set_trans(Tween.TRANS_SINE).tween_property(bike, "position:y", 0.6, 1.1).from(0.4)
	Props.collider(w, Vector3(0.8, 0.8, 2.1), warden + Vector3(1.6, 0.4, 1.2))
	# мусорки у торца западного дома и у гаражей
	for pos in [Vector3(-25, 0, -97.5), Vector3(27, 0, -133)]:
		b.model("dumpster", pos, PI / 2.0)
		Props.collider(w, Vector3(1.4, 1.6, 1.9), pos + Vector3(0, 0.8, 0))
	# фонари по тропам и у парковки
	for pos in [Vector3(-23, 0, -131), Vector3(-23, 0, -100), Vector3(-2, 0, -119), Vector3(4, 0, -137), Vector3(26, 0, -137),
			Vector3(8, 0, -108), Vector3(26, 0, -97), Vector3(14, 0, -86), Vector3(-1, 0, -84)]:
		DistrictSites._lantern(b, pos)


static func batch_laundry(b: DistrictDressing.Batch, at: Vector3, _rng: RandomNumberGenerator) -> void:
	b.box("lamp_post", at + Vector3(-3.6, 1.1, 0), Vector3(0.08, 2.2, 0.08))
	b.box("lamp_post", at + Vector3(3.6, 1.1, 0), Vector3(0.08, 2.2, 0.08))
	for i in 8:
		b.add("cloth", Transform3D(Basis().scaled(Vector3(0.6, 0.75, 0.03)), at + Vector3(-3.1 + i * 0.88, 1.75, 0)),
				[Color(0.85, 0.3, 0.3), Color(0.95, 0.95, 0.9), Color(0.3, 0.5, 0.8), Color(0.95, 0.8, 0.3)][i % 4])


# ---------- следы вчерашней ночи ----------

static func _story(w: Node3D) -> void:
	# сгоревшая машина у ограждения «место посадки», угли ещё тлеют
	var wreck_at := Vector3(8, 0, -131)
	Props.collider(w, Vector3(2.2, 1.5, 4.4), wreck_at + Vector3(0, 0.75, 0))
	if Props.place(w, "car_wreck", wreck_at, 70.0):
		Kit.particles(w, wreck_at + Vector3(0, 1.2, 0), Color(1, 0.45, 0.1, 0.9), 24, 1.6, Vector3(0, 1.8, 0), 0.5, 0.06,
				Vector3(0.8, 0.2, 1.6))
		Kit.particles(w, wreck_at + Vector3(0, 1.6, 0), Color(0.2, 0.2, 0.22, 0.35), 14, 4.0, Vector3(0, 1.5, 0), 0.3, 1.1,
				Vector3(0.6, 0.2, 1.2))
	for x in [5.5, 10.5]:
		Props.place(w, "barrier", Vector3(x, 0, wreck_at.z + 3.5), 0.0)
	Kit.box(w, Vector3(6.5, 0.06, 0.02), Vector3(8, 0.9, wreck_at.z + 3.6), Color(1, 0.85, 0.1))
	Kit.label(w, "МЕСТО ПОСАДКИ · НЕ ПЕРЕСЕКАТЬ", Vector3(8, 1.15, wreck_at.z + 3.7), 22, Color(1, 0.85, 0.1), false)
	# сбитый дрон-сборщик ещё искрит
	var drone := Vector3(25, 0, -118)
	Props.collider(w, Vector3(1.8, 1, 1.8), drone + Vector3(0, 0.5, 0))
	if Props.place(w, "drone_wreck", drone, 40.0):
		Kit.particles(w, drone + Vector3(0.1, 1.0, -0.3), Color(0.5, 1, 0.95, 1), 16, 0.5, Vector3(0, 2.0, 0), 1.0, 0.04,
				Vector3(0.2, 0.1, 0.2))
	_ground_text(w, "ОН ПЕРВЫЙ НАЧАЛ", drone + Vector3(-2.5, 0.14, 2.4), Color(1, 1, 1, 0.75), 40)
	# мелом: контур пришельца и банки
	_chalk_alien(w, Vector3(-15, 0.12, -99.5))
	_ground_text(w, "ГРИША. ОН БЫЛ ЗЕЛЁНЫЙ, НО НАШ", Vector3(-15, 0.13, -97.2), Color(1, 1, 1, 0.7), 34)
	# пришелец, привязанный к фонарю, в розовых трусах
	_tied_alien(w, Vector3(24.5, 0, -137.0))
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
	Kit.cylinder(w, 0.39, 0.007, c + Vector3(0, 0.001, -1.6), Color(0.6, 0.5, 0.36)).scale = Vector3(1, 1, 0.8)
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
	var fx := WEST_BLOCK.end.x + 0.06
	var fz := WING_E.end.y + 0.06
	for g in [["ГЛ'ОРП — ЛОХ", Vector3(fx, 1.6, -114), 90.0, Color(0.3, 1, 0.9)],
			["ВАСЯ + ЗЕЛЁНАЯ = ЛЮБОВЬ", Vector3(fx, 1.4, -132), 90.0, Color(1, 0.35, 0.65)],
			["ПРИШЕЛЬЦЫ, ВЕРНИТЕ ПЕНСИЮ", Vector3(20, 1.8, fz), 0.0, Color(1, 0.85, 0.1)],
			["КУПЛЮ ПОЧКУ ПРИШЕЛЬЦА · ЛЮБУЮ", Vector3(-28, 1.9, fz), 0.0, Color(0.95, 0.95, 0.95)]]:
		Signboard.make(w, g[0], "graffiti", g[3], g[1], g[2], 0.5)
	var paper := Color(0.92, 0.9, 0.84)
	for p in [["ВНИМАНИЕ!\nУЛЫБКА\nОБЯЗАТЕЛЬНА", Vector3(fx, 1.9, -102), 90.0, Color(0.1, 0.25, 0.6), paper],
			["ПРОПАЛ КОТ\nзовут Протокол\nвернуть за\nвознаграждение", Vector3(fx, 1.6, -118), 90.0, Color(0.1, 0.1, 0.1), paper],
			["МИКРОЗАЙМ\nЗА 5 МИНУТ\nДОЛГ НАВСЕГДА", Vector3(10, 1.9, fz), 0.0, Color(1, 1, 1), Color(0.8, 0.12, 0.1)],
			["СДАМ КОМНАТУ\nПРИШЕЛЬЦАМ\nбез детей", Vector3(30, 1.7, fz), 0.0, Color(0.1, 0.1, 0.1), Color(0.95, 0.9, 0.5)],
			["РОЗЫСК\nПЕСНЯ\nзапрещена\nдо написания", Vector3(-20, 2.0, fz), 0.0, Color(0.6, 0.08, 0.06), paper],
			["СДАЙ ДРОНА —\nПОЛУЧИ\nСПАСИБО", Vector3(-9, 1.8, fz), 0.0, Color(0.05, 0.3, 0.15), paper]]:
		Signboard.make(w, p[0], "poster", p[3], p[1], p[2], 0.21, {"bg": p[4]})
	var board := BOOTH + Vector3(-5.5, 0, 1.5)
	Props.collider(w, Vector3(0.9, 1.4, 0.4), board + Vector3(0, 0.7, 0))
	Props.place(w, "chalk_board", board, 0.0)
	Signboard.make(w, "СВЕЖЕЕ\nДЕШЕВЛЕ,\nЧЕМ\nЗАВТРА", "poster", Color(0.75, 0.12, 0.1), board + Vector3(0, 1.08, 0.06), 0.0, 0.19,
			{"tilt": 0.0, "font": "hand"})


static func _trash(w: Node3D) -> void:
	var spots := [["trash_bags", Vector3(-25, 0, -95.5)], ["boxes", Vector3(13, 0, -127)], ["beer_crate", Vector3(-22, 0, -119)],
			["trash_bags", Vector3(27, 0, -128)], ["boxes", Vector3(27, 0, -104)], ["beer_crate", Vector3(-1, 0, -100)],
			["boxes", Vector3(24, 0, -92)], ["beer_crate", Vector3(4, 0, -125)]]
	for s in spots:
		Breakable.spawn(w, s[0], s[1], randf_range(0, 360))


# ---------- границы ----------

static func _bounds(w: Node3D) -> void:
	var r := BOUNDS
	var east_x := r.end.x
	var north := COURT.position.y
	for wall in [[Vector3(r.position.x, 2, r.get_center().y), Vector3(1, 4, r.size.y)],
			[Vector3(east_x, 2, (north + EAST_GAP.x) / 2.0), Vector3(1, 4, EAST_GAP.x - north)],
			[Vector3(east_x, 2, (EAST_GAP.y + r.end.y) / 2.0), Vector3(1, 4, r.end.y - EAST_GAP.y)],
			[Vector3(r.get_center().x, 2, r.end.y), Vector3(r.size.x, 4, 1)]]:
		Props.collider(w, wall[1], wall[0]).set_meta("map_skip", true)
	# ворота в арке
	var gate := Props.collider(w, Vector3(ARCH_HALF_W * 2.0, 4, 1), Vector3(0, 2, north - 0.6))
	gate.name = "ExitGate"
	gate.set_meta("map_skip", true)
	Kit.box(gate, Vector3(ARCH_HALF_W * 2.0, 2.2, 0.08), Vector3(0, -0.9, 0), Color(0.25, 0.27, 0.3))
	for i in 7:
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
	# с юга — низкий штакетник с калиткой у шлагбаума, за ним парк
	var x := r.position.x + 1.25
	while x < r.end.x:
		if absf(x - BARRIER.x - 3.0) > 4.0:
			Props.place(w, "fence", Vector3(x, 0, r.end.y - 0.4), 0.0)
		x += 2.5
