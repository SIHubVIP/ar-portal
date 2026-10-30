class_name District
extends RefCounted
## Район «Погуляй» 3000 × 3000 м. План: X на восток, Y на юг, метры от северо-западного угла.
## В Godot 1 единица = 1 метр, север = -Z. Все переводы координат — только здесь.
##
## Точки реестра (NPC, боссы, мобы, места) — data/district_pogulyay.json (манифест ТЗ).
## Улицы, дома, деревья, огороды и площадки — data/pogulyay_layout.json (0.11, D-051): макет
## утверждённого пакета «Рубин» (tools/importers/import_rubin_layout.py) — коллектор 20 м,
## местные улицы 10 м, переулки, дома 2–5 этажей и наполнение промежутков.
##
## Начало координат Godot — у прежнего кабриолета (360, 2690): двор «Похмельной» по макету
## занимает 268…452 × 2550…2740, арка — в северном корпусе на x = 360.

const SIZE_M := 3000.0
const CHUNK_M := 250.0
const CHUNKS := 12
const ORIGIN_M := Vector2(360, 2690)

static var _data: Dictionary = {}
static var _layout: Dictionary = {}
static var _houses: Array[Rect2] = []
static var _buildings: Array = []
static var _segments: Array = []


static func data() -> Dictionary:
	if _data.is_empty():
		var f := FileAccess.open("res://data/district_pogulyay.json", FileAccess.READ)
		if f:
			_data = JSON.parse_string(f.get_as_text())
	return _data


## Макет «Рубин»: streets, buildings, trees, plots, sites, cores (метры плана).
static func layout() -> Dictionary:
	if _layout.is_empty():
		var f := FileAccess.open("res://data/pogulyay_layout.json", FileAccess.READ)
		if f:
			_layout = JSON.parse_string(f.get_as_text())
	return _layout


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


## Улицы макета как отрезки: {a, b, w, kind, id, major}. kind — collector (20 м), local (10 м),
## alley (кольца 4 м), path (дорожки у домов), lane (переулки 5 м наполнения). id "street" —
## улица с тротуарами и фонарями, "lane" — проход без тротуаров; major — коллектор.
static func road_segments() -> Array:
	if not _segments.is_empty():
		return _segments
	var out: Array = []
	for r in layout().get("streets", []):
		var kind := String(r.kind)
		out.append({"a": m(r.a), "b": m(r.b), "w": float(r.w), "kind": kind,
				"id": "street" if kind == "collector" or kind == "local" else "lane", "major": kind == "collector"})
	_segments = out
	return out


## Дома макета (метры плана) — прямоугольники для коллизий, карт и проверки доступности.
static func houses() -> Array[Rect2]:
	if _houses.is_empty():
		for b in buildings():
			_houses.append(b.rect)
	return _houses


## Дома с подробностями: {rect, h, mat, kind, site?}. kind: house (многоквартирный 2–5 этажей),
## site (корпус площадки или ориентира — строит DistrictSites), cottage, workshop, garage, shed.
static func buildings() -> Array:
	if _buildings.is_empty():
		for b in layout().get("buildings", []):
			var r: Array = b.r
			var d: Dictionary = b.duplicate()
			d.rect = Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))
			_buildings.append(d)
	return _buildings


## Деревья макета: [x, y, радиус кроны, высота, "tree" | "grove"].
static func trees() -> Array:
	return layout().get("trees", [])


## Участки двора: {r: [x, y, w, d], kind: garden | playground | laundry}.
static func plots() -> Array:
	return layout().get("plots", [])


## Площадки и ориентиры секторов: {id, r: [x0, y0, x1, y1], objects}.
static func sites() -> Array:
	return layout().get("sites", [])


static func site(id: String) -> Dictionary:
	for s in sites():
		if s.id == id:
			return s
	return {}


## Расстояние от точки до отрезка дороги.
static func dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return p.distance_to(a + ab * t)


## Двор «Похмельной» собран вручную (StartYard): участки не строят в нём дома и дороги.
## Корпуса двора, гаражи и двор 268…452 × 2550…2740; южная улица — уже за ним.
static func start_area() -> Rect2:
	return Rect2(248, 2536, 222, 208)


## Двор выходит на север через арку северного корпуса: отсюда начинается проверка доступности.
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
