class_name District
extends RefCounted
## Район «Погуляй» по ТЗ 1.0: 3000 × 3000 м, точки и дороги из data/district_pogulyay.json.
## План: X на восток, Y на юг, метры от северо-западного угла. В Godot 1 единица = 1 метр,
## север = -Z. Все переводы координат — только здесь.
##
## Данные — манифест владельца pogulyay-map.json (схема 1.1) плюс силуэты домов со схемы.
##
## Начало координат Godot стоит у кабриолета во дворе «Похмельной» (360, 2690), а не в центре
## района (1500, 1500), как в формуле манифеста: это тот же план без масштаба и поворота,
## сдвинутый на постоянный вектор, чтобы квартал (построенный вокруг нуля) остался на месте.
## Двор лежит между магистралью h12 (y = 2600) и главной осью (y = 2740), арка выходит на h12;
## точка P0 (360, 2640) оказывается во дворе в 50 м к северу от машины. Сменить на центр
## района — поменять ORIGIN_M, когда квартал переедет в участки (решение D-030).

const SIZE_M := 3000.0
const CHUNK_M := 250.0
const CHUNKS := 12
const ORIGIN_M := Vector2(360, 2690)
const LANE_W_M := 6.0
const LANE_MIN_BLOCK_M := 140.0
const LANE_CLEAR_M := 1.5
const LANE_MIN_HOUSE_M := 6.0

static var _data: Dictionary = {}
static var _houses: Array[Rect2] = []
static var _segments: Array = []
static var _lane_rects: Array[Rect2] = []


static func data() -> Dictionary:
	if _data.is_empty():
		var f := FileAccess.open("res://data/district_pogulyay.json", FileAccess.READ)
		if f:
			_data = JSON.parse_string(f.get_as_text())
	return _data


static func to_world(m: Vector2, y := 0.0) -> Vector3:
	return Vector3(m.x - ORIGIN_M.x, y, m.y - ORIGIN_M.y)


static func to_plan(p: Vector3) -> Vector2:
	return Vector2(p.x + ORIGIN_M.x, p.z + ORIGIN_M.y)


static func m(arr: Array) -> Vector2:
	return Vector2(float(arr[0]), float(arr[1]))


## Участок по ТЗ п. 10: floor(x / 250), край 3000 м относится к последнему участку.
static func chunk_of(plan: Vector2) -> Vector2i:
	return Vector2i(clampi(floori(plan.x / CHUNK_M), 0, CHUNKS - 1), clampi(floori(plan.y / CHUNK_M), 0, CHUNKS - 1))


static func chunk_rect(c: Vector2i) -> Rect2:
	return Rect2(Vector2(c) * CHUNK_M, Vector2(CHUNK_M, CHUNK_M))


## Точки манифеста по типу: npc, boss, mob, place, safe, underground.
static func points(type := "") -> Array:
	return data().get("points", []).filter(func(p): return type == "" or p.type == type)


static func point(id: String) -> Dictionary:
	for p in data().get("points", []):
		if p.id == id:
			return p
	return {}


static func pos(p: Dictionary) -> Vector2:
	return m(p.plan_position_m)


## Действующее переопределение позиции NPC (Павел у киоска, пока идёт MAIN_001) или {}.
## Одна активная копия NPC: пока переопределение действует, основной точки нет.
static func override_for(id: String) -> Dictionary:
	for o in data().get("npc_position_overrides", []):
		if o.npc_id == id and condition_met(String(o.condition)):
			return o
	return {}


## Позиция NPC сейчас, метры плана: точка во дворе, если она задана, иначе точка манифеста.
static func npc_pos(id: String) -> Vector2:
	var o := override_for(id)
	if o.is_empty():
		return pos(point(id))
	return m(o.get("yard_plan_position_m", o.plan_position_m))


## Условие вида «MAIN_001_started_and_not_completed»; state — для проверки без QuestService.
static func condition_met(c: String, state := "") -> bool:
	if c.ends_with("_started_and_not_completed"):
		var st := state if state != "" else QuestService.state_of(c.trim_suffix("_started_and_not_completed"))
		return st == QuestService.ACTIVE or st == QuestService.TURN_IN_READY
	return false


## Сектор A1..C3 по ТЗ п. 3.
static func sector_at(plan: Vector2) -> Dictionary:
	plan = plan.clamp(Vector2.ZERO, Vector2(SIZE_M - 0.01, SIZE_M - 0.01))
	for z in data().get("sectors", []):
		var r: Array = z.bounds_plan_m
		if plan.x >= r[0] and plan.x < r[2] and plan.y >= r[1] and plan.y < r[3]:
			return z
	return {}


## Можно ли стоять в точке плана: внутри района, не в доме и не во дворе старта.
static func walkable(plan: Vector2) -> bool:
	if plan.x < 2.0 or plan.y < 2.0 or plan.x > SIZE_M - 2.0 or plan.y > SIZE_M - 2.0:
		return false
	if start_area().has_point(plan):
		return false
	for h in houses():
		if h.grow(0.8).has_point(plan):
			return false
	return true


## Безопасная зона района, внутри которой лежит точка плана, или {}.
static func safe_zone_at(plan: Vector2) -> Dictionary:
	for p in points("safe"):
		if plan.distance_to(pos(p)) <= float(p.get("radius_m", 0)):
			return p
	return {}


## Дороги как отрезки с шириной коридора из манифеста: 24 м магистрали, кольцо и ось, 12 м улицы.
static func road_segments() -> Array:
	if not _segments.is_empty():
		return _segments
	var out: Array = []
	for r in data().get("road_centerlines", []):
		var pts: Array = r.polyline_plan_m
		var w := float(r.corridor_width_m)
		for i in pts.size() - 1:
			out.append({"a": m(pts[i]), "b": m(pts[i + 1]), "w": w, "id": r.id, "major": w >= 20.0})
	out.append_array(_lanes())
	_segments = out
	return out


## Переулки этапа 3: в каждом квартале сетки, где между коридорами улиц больше LANE_MIN_BLOCK_M,
## по середине идёт сквозной проход от улицы до улицы. Вертикальный и горизонтальный проходы
## одного квартала пересекаются и дают петли. Двор старта и арены боссов переулки обходят.
static func _lanes() -> Array:
	var xs: Array = []
	var ys: Array = []
	for r in data().get("road_centerlines", []):
		var id := String(r.id)
		var p0: Array = r.polyline_plan_m[0]
		if id.begins_with("v"):
			xs.append([float(p0[0]), float(r.corridor_width_m)])
		elif id.begins_with("h"):
			ys.append([float(p0[1]), float(r.corridor_width_m)])
	xs.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	ys.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var keep_out: Array[Rect2] = [start_area().grow(10)]
	for p in points("boss"):
		var sz := m(p.arena_size_m)
		keep_out.append(Rect2(pos(p) - sz / 2.0, sz).grow(10))
	var out: Array = []
	for i in xs.size() - 1:
		for j in ys.size() - 1:
			var x0: float = xs[i][0]
			var x1: float = xs[i + 1][0]
			var y0: float = ys[j][0]
			var y1: float = ys[j + 1][0]
			var gap_x: float = x1 - x0 - (xs[i][1] + xs[i + 1][1]) / 2.0
			var gap_y: float = y1 - y0 - (ys[j][1] + ys[j + 1][1]) / 2.0
			var cx := (x0 + x1) / 2.0
			var cy := (y0 + y1) / 2.0
			if gap_x > LANE_MIN_BLOCK_M:
				_add_lane(out, Vector2(cx, y0), Vector2(cx, y1), keep_out)
			if gap_y > LANE_MIN_BLOCK_M:
				_add_lane(out, Vector2(x0, cy), Vector2(x1, cy), keep_out)
	return out


static func _add_lane(out: Array, a: Vector2, b: Vector2, keep_out: Array[Rect2]) -> void:
	for k in keep_out:
		if _segment_hits_rect(a, b, k):
			return
	out.append({"a": a, "b": b, "w": LANE_W_M, "id": "lane", "major": false})


static func _segment_hits_rect(a: Vector2, b: Vector2, r: Rect2) -> bool:
	for t in 33:
		if r.has_point(a.lerp(b, t / 32.0)):
			return true
	return false


## Дома со схемы (метры плана), которые реально стоят в районе: не на дороге, не на точке
## реестра, не на арене и не во дворе старта. Один список и для участков, и для карт.
static func houses() -> Array[Rect2]:
	if _houses.is_empty():
		var start := start_area().grow(6)
		for h in data().get("houses_plan_m", []):
			var r := Rect2(float(h[0]), float(h[1]), float(h[2]), float(h[3]))
			if not start.has_point(r.get_center()) and not _blocked(r.get_center(), r.size):
				_houses.append_array(_split_by_lanes(r))
	return _houses


## Переулок режет дом на два корпуса с проходом LANE_W_M + 2 × LANE_CLEAR_M; узкие обрезки
## меньше LANE_MIN_HOUSE_M не строятся.
static func _split_by_lanes(h: Rect2) -> Array[Rect2]:
	if _lane_rects.is_empty():
		for s in road_segments():
			if s.id == "lane":
				_lane_rects.append(Rect2(s.a, Vector2.ZERO).expand(s.b).grow(s.w / 2.0 + LANE_CLEAR_M))
	var parts: Array[Rect2] = [h]
	for lane in _lane_rects:
		if not lane.intersects(h):
			continue
		var next: Array[Rect2] = []
		for r in parts:
			if not lane.intersects(r):
				next.append(r)
				continue
			var vertical: bool = lane.size.y > lane.size.x
			var pieces: Array[Rect2] = []
			if vertical:
				pieces = [Rect2(r.position, Vector2(lane.position.x - r.position.x, r.size.y)),
					Rect2(Vector2(lane.end.x, r.position.y), Vector2(r.end.x - lane.end.x, r.size.y))]
			else:
				pieces = [Rect2(r.position, Vector2(r.size.x, lane.position.y - r.position.y)),
					Rect2(Vector2(r.position.x, lane.end.y), Vector2(r.size.x, r.end.y - lane.end.y))]
			for q in pieces:
				if q.size.x >= LANE_MIN_HOUSE_M and q.size.y >= LANE_MIN_HOUSE_M:
					next.append(q)
		parts = next
	return parts


static func _blocked(center: Vector2, size: Vector2) -> bool:
	var r := maxf(size.x, size.y) * 0.6
	for s in road_segments():
		if s.id != "lane" and dist_to_segment(center, s.a, s.b) < s.w / 2.0 + r + 2.0:
			return true
	for p in data().get("points", []):
		var pm := pos(p)
		if p.type == "boss":
			var a := Rect2(pm - m(p.arena_size_m) / 2.0, m(p.arena_size_m))
			if a.grow(r).has_point(center):
				return true
		elif center.distance_to(pm) < r + (12.0 if p.type != "safe" else 25.0):
			return true
	return false


## Расстояние от точки до отрезка дороги.
static func dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return p.distance_to(a + ab * t)


## Квартал «Похмельная» собран вручную вокруг старта: участки не строят в нём дома и дороги.
static func start_area() -> Rect2:
	return Rect2(ORIGIN_M + Vector2(-42, -78), Vector2(84, 108))


## Двор старта выходит на h12 через арку: отсюда начинается проверка доступности.
static func yard_exit() -> Vector2:
	return Vector2(ORIGIN_M.x, start_area().position.y - 6.0)


## Проверка этапа 3: поиск в ширину по сетке cell × cell метров от выхода из двора.
## Непроходимы дома (с запасом под капсулу героя), края района и сам двор (в него ведёт арка).
## Точка доступна, если в радиусе REACH_SNAP_M от неё есть достигнутая клетка.
## Возвращает {id: {"reachable": bool, "path_m": float, "snap_m": float}}.
const REACH_SNAP_M := 12.0

static func reachability(cell := 4.0) -> Dictionary:
	var n := int(SIZE_M / cell)
	var blocked := PackedByteArray()
	blocked.resize(n * n)
	var yard := start_area()
	for r in houses() + [yard]:
		var g: Rect2 = r.grow(0.4)
		for gy in range(maxi(0, int(g.position.y / cell)), mini(n, int(g.end.y / cell) + 1)):
			var cy := (gy + 0.5) * cell
			if cy < g.position.y or cy > g.end.y:
				continue
			for gx in range(maxi(0, int(g.position.x / cell)), mini(n, int(g.end.x / cell) + 1)):
				var cx := (gx + 0.5) * cell
				if cx >= g.position.x and cx <= g.end.x:
					blocked[gy * n + gx] = 1
	var dist := PackedInt32Array()
	dist.resize(n * n)
	dist.fill(-1)
	var e := yard_exit()
	var s := int(e.y / cell) * n + int(e.x / cell)
	var queue := PackedInt32Array([s])
	dist[s] = 0
	var head := 0
	while head < queue.size():
		var c := queue[head]
		head += 1
		var cx := c % n
		var cy := c / n
		var d := dist[c] + 1
		for nb in [c - 1 if cx > 0 else -1, c + 1 if cx < n - 1 else -1, c - n if cy > 0 else -1, c + n if cy < n - 1 else -1]:
			if nb >= 0 and dist[nb] < 0 and blocked[nb] == 0:
				dist[nb] = d
				queue.append(nb)
	var out := {}
	var snap := int(ceil(REACH_SNAP_M / cell))
	for p in data().get("points", []):
		var pm := pos(p)
		var best := {"reachable": false, "path_m": -1.0, "snap_m": -1.0}
		if yard.has_point(pm):
			best = {"reachable": true, "path_m": 0.0, "snap_m": 0.0, "yard": true}
		else:
			var px := int(pm.x / cell)
			var py := int(pm.y / cell)
			for gy in range(maxi(0, py - snap), mini(n, py + snap + 1)):
				for gx in range(maxi(0, px - snap), mini(n, px + snap + 1)):
					var dd := dist[gy * n + gx]
					var off := Vector2((gx + 0.5) * cell, (gy + 0.5) * cell).distance_to(pm)
					if dd >= 0 and off <= REACH_SNAP_M and (not best.reachable or dd * cell < best.path_m):
						best = {"reachable": true, "path_m": dd * cell, "snap_m": off}
		out[p.id] = best
	return out
