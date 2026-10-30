class_name DistrictChunks
extends Node3D
## Этап 1 ТЗ «Погуляй»: весь район 3000 × 3000 м из 144 участков по 250 м.
## Загружены участок героя и восемь соседних; дальние выгружаются с запасом (гистерезис),
## новый участок строится по кусочкам, чтобы не дёргать ввод. Участок по макету «Рубин»
## (0.11): улицы и переулки, дома 2–5 этажей (BuildingKit), частный сектор, гаражи и сараи
## одним MultiMesh на вид, деревья и огороды, площадки и ориентиры (DistrictSites), метки
## точек реестра. Пол и внешние стены района — общие. Двор «Похмельной» строит StartYard.

const LOAD_RADIUS := 1
const BUILD_BUDGET_US := 3000
const KEEP_RADIUS := 2
const HOUSE_FLOOR_M := 3.0
const SMALL_KINDS := ["cottage", "workshop", "garage", "shed"]
const POINT_COLORS := {"npc": Color(0.45, 0.9, 0.65), "boss": Color(0.95, 0.38, 0.45), "safe": Color(0.45, 0.78, 0.95),
		"underground": Color(0.95, 0.72, 0.3), "place": Color(0.93, 0.87, 0.75), "mob": Color(1, 0.5, 0.3)}

var player: Node3D
var loaded: Dictionary = {}        # Vector2i → Node3D
var _queue: Array[Vector2i] = []
var _tick := 0.0
var _segments: Array = []
var _mats: Dictionary = {}
var _steps: Array[Callable] = []
var _steps_root: Node3D


func _ready() -> void:
	_segments = District.road_segments()
	_build_floor_and_edges()


## Сразу строит участки вокруг героя (для старта и тестов), без очереди.
func load_now() -> void:
	_update(true)


func _physics_process(delta: float) -> void:
	_tick += delta
	if _tick >= 0.25:
		_tick = 0.0
		_update(false)
	# стройка по кусочкам: не больше BUILD_BUDGET_US микросекунд за кадр
	var t0 := Time.get_ticks_usec()
	while Time.get_ticks_usec() - t0 < BUILD_BUDGET_US:
		if _steps.is_empty():
			if _queue.is_empty():
				break
			var c: Vector2i = _queue.pop_front()
			if loaded.has(c):
				continue
			var root := _chunk_root(c)
			loaded[c] = root
			_steps = _chunk_steps(root, c)
			_steps_root = root
		elif not is_instance_valid(_steps_root) or _steps_root.is_queued_for_deletion():
			_steps.clear()          # участок выгрузили, пока он строился
		else:
			var step: Callable = _steps.pop_front()
			step.call()


func _update(immediate: bool) -> void:
	if player == null or not is_instance_valid(player):
		return
	var here := District.chunk_of(District.to_plan(player.global_position))
	for dx in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
		for dy in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
			var c := here + Vector2i(dx, dy)
			if c.x < 0 or c.y < 0 or c.x >= District.CHUNKS or c.y >= District.CHUNKS or loaded.has(c):
				continue
			if immediate:
				loaded[c] = _build_chunk(c)
			elif not _queue.has(c):
				_queue.append(c)
	for c in loaded.keys():
		if maxi(absi(c.x - here.x), absi(c.y - here.y)) > KEEP_RADIUS:
			loaded[c].queue_free()
			loaded.erase(c)


# ---------- общие пол и края ----------

func _build_floor_and_edges() -> void:
	var size := District.SIZE_M
	var center := District.to_world(Vector2(size, size) / 2.0)
	var floor_body := StaticBody3D.new()
	floor_body.name = "DistrictFloor"
	floor_body.position = center + Vector3(0, -0.5, 0)
	floor_body.set_meta("map_skip", true)
	add_child(floor_body)
	var fs := CollisionShape3D.new()
	var fb := BoxShape3D.new()
	fb.size = Vector3(size, 1, size)
	fs.shape = fb
	floor_body.add_child(fs)
	for wall in [[Vector2(size / 2, 0), Vector3(size, 6, 1)], [Vector2(size / 2, size), Vector3(size, 6, 1)],
			[Vector2(0, size / 2), Vector3(1, 6, size)], [Vector2(size, size / 2), Vector3(1, 6, size)]]:
		var b := Props.collider(self, wall[1], District.to_world(wall[0], 3.0))
		b.set_meta("map_skip", true)


# ---------- участок ----------

func _build_chunk(c: Vector2i) -> Node3D:
	var root := _chunk_root(c)
	var steps := _chunk_steps(root, c)
	while not steps.is_empty():
		var step: Callable = steps.pop_front()
		step.call()
	return root


func _chunk_root(c: Vector2i) -> Node3D:
	var root := Node3D.new()
	root.name = "Chunk_%02d_%02d" % [c.x, c.y]
	root.set_meta("map_skip", true)
	add_child(root)
	return root


## Участок как список мелких шагов: в игре они растягиваются на несколько кадров
## (BUILD_BUDGET_US на кадр), чтобы переход через границу участка не давал фриз (0.9).
func _chunk_steps(root: Node3D, c: Vector2i) -> Array[Callable]:
	var steps: Array[Callable] = []
	var rect := District.chunk_rect(c)
	var start := District.start_area()
	# пол участка (вне двора «Похмельной», у него свой)
	steps.append(func() -> void:
		var ground := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(District.CHUNK_M, District.CHUNK_M)
		ground.mesh = pm
		ground.position = District.to_world(rect.get_center(), -0.02)
		ground.material_override = _mat("ground")
		root.add_child(ground)
		for s in _segments:
			_road_piece(root, s, rect, start))
	# 0.10: улица — тротуары, фонари, ларьки, разметка; дома — витрины и вывески. Тяжёлое
	# (каждая улица, каждая вывеска) копится в batch.jobs и сразу уходит отдельными шагами.
	var batch := DistrictDressing.Batch.new()
	var drain := func() -> void:
		var jobs := batch.jobs.duplicate()
		batch.jobs.clear()
		for i in jobs.size():
			steps.insert(i, jobs[i])
	steps.append(func() -> void:
		if is_instance_valid(root):
			DistrictDressing.streets(root, c, _segments, batch)
			drain.call())
	var small: Array = []
	for b in District.buildings():
		var hc: Vector2 = (b.rect as Rect2).get_center()
		if not rect.has_point(hc) or start.has_point(hc):
			continue
		if b.kind == "house":
			steps.append(func() -> void:
				_house(root, b, batch)
				drain.call())
		elif SMALL_KINDS.has(b.kind):
			small.append(b)
	if not small.is_empty():
		steps.append(_small_houses.bind(root, small, batch))
	steps.append(func() -> void:
		if is_instance_valid(root):
			DistrictDressing.layout_fill(root, rect, batch))
	for st in District.sites():
		var sr: Array = st.r
		var sc := Vector2((float(sr[0]) + float(sr[2])) / 2.0, (float(sr[1]) + float(sr[3])) / 2.0)
		if rect.has_point(sc) and st.id != "start":
			steps.append(func() -> void:
				if is_instance_valid(root):
					DistrictSites.build(root, st, batch)
					drain.call())
	for p in District.data().get("points", []):
		var pm2 := District.pos(p)
		# одна копия NPC: пока Павел у киоска во дворе, метки в парке нет
		if rect.has_point(pm2) and not start.has_point(pm2) and District.override_for(p.id).is_empty():
			steps.append(_point_marker.bind(root, p))
	# flush ждёт, пока все отложенные улицы допишут свои мелочи
	var flush_step := func(self_ref: Callable) -> void:
		if not batch.jobs.is_empty():
			drain.call()
			steps.append(self_ref.bind(self_ref))
			return
		var fs := DistrictDressing.flush_steps(root, c, batch)
		for i in fs.size():
			steps.insert(i, fs[i])
	steps.append(flush_step.bind(flush_step))
	return steps


## Многоквартирный дом макета: своя сетка BuildingKit (окна шейдера и балконы — по мировой
## сетке), тело-окклюдер для выреза камерой, у подъездов свет; к улицам — витрины и вывески.
func _house(root: Node3D, b: Dictionary, batch: DistrictDressing.Batch = null) -> void:
	if not is_instance_valid(root):
		return
	var h: Rect2 = b.rect
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(int(h.position.x), int(h.position.y)))
	var floors := clampi(int(round(float(b.h) / HOUSE_FLOOR_M)), 2, 5)
	var at := District.to_world(h.get_center())
	var built := BuildingKit.house(h.size.x, h.size.y, floors, at, b.mat == "brick", rng)
	var height := floors * HOUSE_FLOOR_M + 0.4
	var body := Props.collider(root, Vector3(h.size.x, height, h.size.y), at + Vector3(0, height / 2.0, 0), true)
	var mi := MeshInstance3D.new()
	mi.mesh = built.mesh
	mi.position = Vector3(0, -height / 2.0, 0)
	body.add_child(mi)
	if batch != null:
		for e: Vector3 in built.entrances:
			batch.lamps.append(e + Vector3(0, 2.4, -0.0))
			batch.add("spill", Transform3D(Basis().scaled(Vector3(3.6, 1.0, 3.6)), e + Vector3(0, 0.07, 0)), Color(0.8, 0.62, 0.4))
		DistrictDressing.facades(root, h, height, _segments, batch, rng)


## Частный сектор, мастерские, гаражи и сараи участка: единичные сетки BuildingKit в
## MultiMesh (по сетке на вид), коллизия — одно тело с коробками. Лицом к ближайшему проходу.
func _small_houses(root: Node3D, list: Array, batch: DistrictDressing.Batch) -> void:
	if not is_instance_valid(root):
		return
	var groups: Dictionary = {}
	var body := StaticBody3D.new()
	body.name = "SmallHouses"
	root.add_child(body)
	for b in list:
		var r: Rect2 = b.rect
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(Vector2i(int(r.position.x * 10.0), int(r.position.y * 10.0)))
		var floors := 2 if float(b.h) >= 5.5 else 1
		var brick: bool = b.mat == "brick"
		var variant := rng.randi() % 4
		var key := "%s|%d|%s|%d" % [b.kind, floors, brick, variant]
		var size := r.size
		var yaw := _face_yaw(r)
		# лицо единичной сетки — +Z: на повороте 90° ширина и глубина меняются местами
		var turned := absf(sin(yaw)) > 0.5
		var sx := size.y if turned else size.x
		var sz := size.x if turned else size.y
		var xf := Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(sx, 1.0, sz)), District.to_world(r.get_center()))
		if not groups.has(key):
			groups[key] = [BuildingKit.unit(b.kind, floors, brick, variant), []]
		var tint := BuildingKit.small_wall_color(String(b.mat), rng)
		groups[key][1].append([xf, tint])
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		var hh := float(b.h)
		bs.size = Vector3(size.x, hh, size.y)
		cs.shape = bs
		cs.position = District.to_world(r.get_center(), hh / 2.0)
		body.add_child(cs)
		if b.kind == "cottage" or b.kind == "workshop":
			var front := Vector3(sin(yaw), 0, cos(yaw))
			var door := District.to_world(r.get_center()) + front * (sz / 2.0 + 0.6)
			if b.kind == "cottage":
				door += Vector3(cos(yaw), 0, -sin(yaw)) * (-0.2 * sx)
				batch.add("spill", Transform3D(Basis().scaled(Vector3(2.6, 1.0, 2.6)), door + Vector3(0, 0.07, 0)), Color(0.8, 0.62, 0.4))
			if rng.randf() < 0.35:
				batch.lamps.append(door + Vector3(0, 2.3, 0))
	for key in groups:
		var mesh: Mesh = groups[key][0]
		var items: Array = groups[key][1]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true            # белый: иначе GL-рендер берёт COLOR из пустого буфера
		mm.use_custom_data = true          # цвет стены — в данных экземпляра, крыша и двери своих цветов
		mm.mesh = mesh
		mm.instance_count = items.size()
		for i in items.size():
			mm.set_instance_transform(i, items[i][0])
			mm.set_instance_color(i, Color.WHITE)
			mm.set_instance_custom_data(i, items[i][1])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mmi)


## Поворот мелкого дома лицом к ближайшему проходу (улице или переулку) в пределах 20 м.
func _face_yaw(r: Rect2) -> float:
	var c := r.get_center()
	var best := 1e9
	var yaw := 0.0
	for s in _segments:
		var d := District.dist_to_segment(c, s.a, s.b) - float(s.w) / 2.0
		if d < best and d < 20.0:
			best = d
			var ab: Vector2 = s.b - s.a
			var t := clampf((c - s.a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
			var to: Vector2 = s.a + ab * t - c
			yaw = atan2(to.x, to.y)
			yaw = roundf(yaw / (PI / 2.0)) * (PI / 2.0)
	return yaw


## Кусок дороги внутри участка: отрезок обрезается по участку и двору старта.
func _road_piece(root: Node3D, s: Dictionary, rect: Rect2, start: Rect2) -> void:
	var clip := _clip(s.a, s.b, rect)
	if clip.is_empty():
		return
	var a: Vector2 = clip[0]
	var b: Vector2 = clip[1]
	# не заходить во двор «Похмельной»
	if start.has_point(a) and start.has_point(b):
		return
	var dir := (b - a)
	var length: float = dir.length()
	if length < 0.5:
		return
	var mid := (a + b) / 2.0
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	var overlap: float = s.w / 2.0
	bm.size = Vector3(length + overlap, 0.04, float(s.w))
	mi.mesh = bm
	var lane: bool = s.id == "lane"
	mi.position = District.to_world(mid, 0.02 if s.major else (0.005 if lane else 0.01))
	mi.rotation.y = -atan2(dir.y, dir.x)
	# коллектор и местные — асфальт, переулки — светлый асфальт, дорожки и кольца — плитка
	var kind := String(s.get("kind", ""))
	mi.material_override = _mat("road" if s.major else ("street" if not lane else ("path" if kind == "path" or kind == "alley" else "lane")))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)


## Отсечение отрезка прямоугольником (Лян — Барски). [] если снаружи.
static func _clip(a: Vector2, b: Vector2, r: Rect2) -> Array:
	var t0 := 0.0
	var t1 := 1.0
	var d := b - a
	for side in [[-d.x, a.x - r.position.x], [d.x, r.end.x - a.x], [-d.y, a.y - r.position.y], [d.y, r.end.y - a.y]]:
		var p: float = side[0]
		var q: float = side[1]
		if absf(p) < 0.00001:
			if q < 0.0:
				return []
		else:
			var t := q / p
			if p < 0.0:
				t0 = maxf(t0, t)
			else:
				t1 = minf(t1, t)
			if t0 > t1:
				return []
	return [a + d * t0, a + d * t1]


## Метка точки реестра: столб цвета легенды и табличка «ID · имя». Это разметка этапа 1,
## а не готовый NPC или арена: реальные персонажи и бои подключаются на этапе 4.
func _point_marker(root: Node3D, p: Dictionary) -> void:
	var pos := District.to_world(District.pos(p))
	var col: Color = POINT_COLORS.get(p.type, Color.WHITE)
	var n := Node3D.new()
	n.position = pos
	n.name = "Point_%s" % String(p.id).replace("-", "_")
	n.set_meta("point_id", p.id)
	root.add_child(n)
	Kit.cylinder(n, 0.25, 3.0, Vector3(0, 1.5, 0), col.darkened(0.3), 0.3)
	Kit.sphere(n, 0.5, Vector3(0, 3.3, 0), col, 1.5)
	var l := Kit.label(n, "%s · %s" % [p.id, p.get("name", "")], Vector3(0, 4.4, 0), 48, col.lightened(0.3))
	l.visibility_range_end = 70.0
	match String(p.type):
		"boss":
			var sz := District.m(p.arena_size_m)
			for e in [[Vector3(0, 1, -sz.y / 2), Vector3(sz.x, 2, 0.3)], [Vector3(0, 1, sz.y / 2), Vector3(sz.x, 2, 0.3)],
					[Vector3(-sz.x / 2, 1, 0), Vector3(0.3, 2, sz.y)], [Vector3(sz.x / 2, 1, 0), Vector3(0.3, 2, sz.y)]]:
				Kit.box(n, e[1], e[0], col.darkened(0.4))
		"safe", "mob":
			var ring := MeshInstance3D.new()
			var torus := TorusMesh.new()
			var radius := float(p.get("radius_m", 45))
			torus.inner_radius = radius - 0.4
			torus.outer_radius = radius
			torus.rings = 48
			torus.ring_segments = 4
			ring.mesh = torus
			ring.scale.y = 0.1
			ring.position.y = 0.05
			ring.material_override = Kit.mat(Color(col, 0.8), 0.8)
			ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			n.add_child(ring)
		"underground":
			Kit.box(n, Vector3(3, 0.3, 3), Vector3(0, 0.15, 0), Color(0.25, 0.22, 0.2))


func _mat(kind: String) -> Material:
	if _mats.has(kind):
		return _mats[kind]
	var m: Material
	match kind:
		# 0.10: текстуры вместо ровной заливки — земля дворов, мокрый асфальт, переулки
		"ground":
			m = Surfaces.dirt(Color(1.45, 1.5, 0.95))     # осенний газон с землёй
		"road":
			m = Surfaces.asphalt()
		"street":
			m = Surfaces.asphalt(Color(1.12, 1.1, 1.1))
		"lane":
			m = Surfaces.asphalt(Color(1.45, 1.35, 1.25))
		"path":
			m = Surfaces.slabs(Color(0.92, 0.88, 0.82))
		_:
			# прежние «house_N» (прогрев шейдеров): стены домов BuildingKit
			m = BuildingKit.wall_material(int(kind.right(1)) % 2 == 0)
	_mats[kind] = m
	return m
