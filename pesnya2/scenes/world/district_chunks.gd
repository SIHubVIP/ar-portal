class_name DistrictChunks
extends Node3D
## Этап 1 ТЗ «Погуляй»: весь район 3000 × 3000 м из 144 участков по 250 м.
## Загружены участок героя и восемь соседних; дальние выгружаются с запасом (гистерезис),
## новый участок строится по одному за кадр, чтобы не дёргать ввод. Участок — дороги,
## дома-блоки по силуэтам схемы, метки точек реестра. Пол и внешние стены района — общие.
## Квартал «Похмельная» строит сам мир: участки в нём не ставят ни домов, ни дорог.

const LOAD_RADIUS := 1
const KEEP_RADIUS := 2
const HOUSE_FLOOR_M := 3.0
const POINT_COLORS := {"npc": Color(0.45, 0.9, 0.65), "boss": Color(0.95, 0.38, 0.45), "safe": Color(0.45, 0.78, 0.95),
		"underground": Color(0.95, 0.72, 0.3), "place": Color(0.93, 0.87, 0.75), "mob": Color(1, 0.5, 0.3)}

var player: Node3D
var loaded: Dictionary = {}        # Vector2i → Node3D
var _queue: Array[Vector2i] = []
var _tick := 0.0
var _segments: Array = []
var _mats: Dictionary = {}


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
	if not _queue.is_empty():
		var c: Vector2i = _queue.pop_front()
		if not loaded.has(c):
			loaded[c] = _build_chunk(c)


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
	var root := Node3D.new()
	root.name = "Chunk_%02d_%02d" % [c.x, c.y]
	root.set_meta("map_skip", true)
	add_child(root)
	var rect := District.chunk_rect(c)
	var start := District.start_area()
	# пол участка (вне двора «Похмельной», у него свой)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(District.CHUNK_M, District.CHUNK_M)
	ground.mesh = pm
	ground.position = District.to_world(rect.get_center(), -0.02)
	ground.material_override = _mat("ground")
	root.add_child(ground)
	for s in _segments:
		_road_piece(root, s, rect, start)
	var rng := RandomNumberGenerator.new()
	for h in District.houses():
		var hc := h.get_center()
		if not rect.has_point(hc):
			continue
		rng.seed = hash(Vector2i(int(h.position.x), int(h.position.y)))
		var floors := rng.randi_range(3, 9)
		var height := floors * HOUSE_FLOOR_M
		var body := Props.collider(root, Vector3(h.size.x, height, h.size.y), District.to_world(hc, height / 2.0), true)
		var mi := Kit.box(body, Vector3(h.size.x, height, h.size.y), Vector3.ZERO, Color.WHITE)
		mi.material_override = _mat("house_%d" % (rng.randi() % 4))
	for p in District.data().get("points", []):
		var pm2 := District.pos(p)
		# одна копия NPC: пока Павел у киоска во дворе, метки в парке нет
		if rect.has_point(pm2) and not start.has_point(pm2) and District.override_for(p.id).is_empty():
			_point_marker(root, p)
	return root


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
	mi.position = District.to_world(mid, 0.02 if s.major else 0.01)
	mi.rotation.y = -atan2(dir.y, dir.x)
	mi.material_override = _mat("road" if s.major else "street")
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
	var m := StandardMaterial3D.new()
	match kind:
		"ground":
			m.albedo_color = Color(0.2, 0.2, 0.21)
			m.roughness = 0.9
		"road":
			m.albedo_color = Color(0.13, 0.13, 0.15)
			m.roughness = 0.35
		"street":
			m.albedo_color = Color(0.16, 0.16, 0.17)
			m.roughness = 0.45
		_:
			var palette := [Color(0.55, 0.36, 0.3), Color(0.6, 0.58, 0.54), Color(0.48, 0.5, 0.55), Color(0.62, 0.5, 0.4)]
			m.albedo_color = palette[int(kind.right(1)) % palette.size()]
			m.roughness = 0.85
	_mats[kind] = m
	return m
