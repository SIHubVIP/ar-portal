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

static var _data: Dictionary = {}
static var _houses: Array[Rect2] = []
static var _segments: Array = []


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
	_segments = out
	return out


## Дома со схемы (метры плана), которые реально стоят в районе: не на дороге, не на точке
## реестра, не на арене и не во дворе старта. Один список и для участков, и для карт.
static func houses() -> Array[Rect2]:
	if _houses.is_empty():
		var start := start_area().grow(6)
		for h in data().get("houses_plan_m", []):
			var r := Rect2(float(h[0]), float(h[1]), float(h[2]), float(h[3]))
			if not start.has_point(r.get_center()) and not _blocked(r.get_center(), r.size):
				_houses.append(r)
	return _houses


static func _blocked(center: Vector2, size: Vector2) -> bool:
	var r := maxf(size.x, size.y) * 0.6
	for s in road_segments():
		if dist_to_segment(center, s.a, s.b) < s.w / 2.0 + r + 2.0:
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
