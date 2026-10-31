class_name MapCanvas
extends Control
## Рисует квартал сверху: дома — тёмные плиты, улицы и тротуары — серые, разметка — светлая.
## Геометрию собирает collect() один раз из коллизий и плоских коробок мира, так что карта
## всегда совпадает с тем, во что упирается герой. Вид задают origin (центр в метрах),
## scale (пикселей на метр) и rot (поворот вместе с камерой). С district = true под кварталом
## рисуется остальной Погуляй из манифеста: дороги с шириной коридора и дома со схемы.

## 0.20: карта нарисована как бумажная — газон, светлые дороги с кантом, коралловые дома с тенью.
const COLORS := {"road": Color(0.87, 0.83, 0.73), "walk": Color(0.94, 0.9, 0.8), "mark": Color(1, 1, 0.96),
		"prop": Color(0.66, 0.53, 0.42), "block": Color(0.93, 0.58, 0.43), "edge": Color(0.24, 0.15, 0.13),
		"road_edge": Color(0.5, 0.46, 0.38), "shadow": Color(0.16, 0.26, 0.14, 0.45)}
const BG := Color(0.55, 0.75, 0.41)
## Клетки двора-диорамы на карте: знак сетки data/yard_diorama.txt → цвет.
const YARD := {",": Color(0.9, 0.8, 0.6), "c": Color(0.86, 0.84, 0.78), "a": Color(0.47, 0.49, 0.55),
		"~": Color(0.42, 0.75, 0.93), "#": Color(0.66, 0.84, 0.48), "Y": Color(0.66, 0.84, 0.48),
		"B": Color(0.66, 0.84, 0.48), "F": Color(0.66, 0.84, 0.48), "^": Color(0.9, 0.8, 0.6), "v": Color(0.9, 0.8, 0.6),
		"<": Color(0.9, 0.8, 0.6), ">": Color(0.9, 0.8, 0.6), "f": Color(0.95, 0.6, 0.72), "h": Color(0.3, 0.55, 0.28),
		"T": Color(0.32, 0.6, 0.3), "b": Color(0.38, 0.66, 0.32), "P": Color(0.32, 0.6, 0.3)}

## [{xf: Transform2D, size: Vector2, kind: String}]
var shapes: Array = []
var origin := Vector2.ZERO
var scale_px := 4.0
var rot := 0.0
var district := false

static var _roads: Array = []       # [{pts: PackedVector2Array (x, z), w: float}]
static var _house_cells: Dictionary = {}
static var _houses: Array[Rect2] = []


## Мировая точка (x, z) → точка на контроле.
func to_screen(world: Vector3) -> Vector2:
	return _view() * Vector2(world.x, world.z)


func _view() -> Transform2D:
	return Transform2D(rot, Vector2(scale_px, scale_px), 0.0, size / 2.0) * Transform2D(0.0, -origin)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG)
	var view := _view()
	var px := 1.0 / scale_px
	if district:
		_draw_district(view)
	_draw_yard(view)
	for pass_kind in ["walk", "road", "mark", "prop", "shadow", "block"]:
		var kind: String = "block" if pass_kind == "shadow" else pass_kind
		for s in shapes:
			if s.kind != kind:
				continue
			var r := Rect2(-s.size / 2.0, s.size)
			if pass_kind == "shadow":
				# тень дома падает вправо-вниз на газон, как от солнца на диораме
				draw_set_transform_matrix(view * Transform2D(0.0, Vector2(1.4, 1.4)) * s.xf)
				draw_rect(r, COLORS.shadow)
				continue
			draw_set_transform_matrix(view * s.xf)
			draw_rect(r, COLORS[kind])
			if kind == "block":
				draw_rect(r.grow(-2.0 * px), COLORS.block.lightened(0.12))
				draw_rect(r, COLORS.edge, false, 2.0 * px)
			elif kind == "prop":
				draw_rect(r, COLORS.edge, false, 1.0 * px)
	draw_set_transform_matrix(Transform2D.IDENTITY)


## Двор-диорама: клетки сетки цветом покрытия — плитка, асфальт, пруд, террасы, клумбы.
func _draw_yard(view: Transform2D) -> void:
	var reach := size.length() / 2.0 / scale_px + 10.0
	var area := Rect2(origin - Vector2(reach, reach), Vector2(reach, reach) * 2.0)
	if not area.intersects(StartYard.BOUNDS):
		return
	draw_set_transform_matrix(view)
	var g := StartYard.grid()
	var c := StartYard.CELL
	for j in g.size():
		for i in g[j].length():
			var ch := g[j][i]
			if not YARD.has(ch):
				continue
			var at := StartYard.GRID_ORIGIN + Vector2(i, j) * c
			if ch == "T" or ch == "b" or ch == "P":
				draw_circle(at + Vector2(c, c) / 2.0 + Vector2(0.5, 0.5), c * 0.45, COLORS.shadow)
				draw_circle(at + Vector2(c, c) / 2.0, c * 0.45, YARD[ch])
			else:
				draw_rect(Rect2(at, Vector2(c, c)), YARD[ch])
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_district(view: Transform2D) -> void:
	if _roads.is_empty():
		_load_district()
	draw_set_transform_matrix(view)
	var reach := size.length() / 2.0 / scale_px + 20.0
	var area := Rect2(origin - Vector2(reach, reach), Vector2(reach, reach) * 2.0)
	# 0.14: домов двух районов ~16 тыс. — перебираем только корзины 250 м рядом с героем
	var c0 := Vector2i(floori(area.position.x / 250.0), floori(area.position.y / 250.0)) - Vector2i.ONE
	var c1 := Vector2i(floori(area.end.x / 250.0), floori(area.end.y / 250.0)) + Vector2i.ONE
	for cx in range(c0.x, c1.x + 1):
		for cy in range(c0.y, c1.y + 1):
			for h: Rect2 in _house_cells.get(Vector2i(cx, cy), []):
				if area.intersects(h):
					draw_rect(Rect2(h.position + Vector2(1.6, 1.6), h.size), COLORS.shadow)
					draw_rect(h, COLORS.block)
					draw_rect(h, COLORS.edge, false, 2.0 / scale_px)
	for r in _roads:
		# 337 улиц и переулков: рисуем только те, что попадают в круг миникарты; кант — шире и темнее
		if area.intersects(r.box):
			draw_polyline(r.pts, COLORS.road_edge, r.w + 3.0 / scale_px)
	for r in _roads:
		if area.intersects(r.box):
			draw_polyline(r.pts, COLORS.road, r.w)
	draw_set_transform_matrix(Transform2D.IDENTITY)


static func _load_district() -> void:
	var o := District.ORIGIN_M
	# улицы и переулки макета «Рубин» (0.11)
	for s in District.road_segments():
		_roads.append({"pts": PackedVector2Array([s.a - o, s.b - o]), "w": float(s.w)})
	for r in _roads:
		var box := Rect2(r.pts[0], Vector2.ZERO)
		for q in r.pts:
			box = box.expand(q)
		r.box = box.grow(r.w)
	for h in District.houses():
		var hr := Rect2(h.position - o, h.size)
		_houses.append(hr)
		var key := Vector2i(floori(hr.get_center().x / 250.0), floori(hr.get_center().y / 250.0))
		if not _house_cells.has(key):
			_house_cells[key] = []
		_house_cells[key].append(hr)


## Собирает формы для карты из уже построенного мира. Участки района (map_skip) не берутся:
## их дороги и дома карта рисует прямо из манифеста.
static func collect(world: Node) -> Array:
	var out: Array = []
	for n in world.find_children("*", "CollisionShape3D", true, false):
		var cs := n as CollisionShape3D
		if not cs.shape is BoxShape3D or _skipped(cs):
			continue
		var bs := cs.shape as BoxShape3D
		if bs.size.y < 0.4 or cs.get_parent() is CharacterBody3D:
			continue
		out.append(_shape(cs.global_transform, bs.size, "block" if bs.size.y >= 2.5 else "prop"))
	for n in world.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if not (mi.mesh is BoxMesh or mi.has_meta("box_size")) or _skipped(mi):
			continue
		var sz: Vector3 = mi.get_meta("box_size") if mi.has_meta("box_size") else (mi.mesh as BoxMesh).size
		if sz.y > 0.3 or mi.global_position.y > 0.3 or sz.x >= 100.0:
			continue
		var kind := "mark" if minf(sz.x, sz.z) < 0.4 else ("walk" if mi.global_position.y > 0.05 else "road")
		out.append(_shape(mi.global_transform, sz, kind))
	return out


static func _skipped(n: Node) -> bool:
	var p := n
	while p:
		if p.has_meta("map_skip"):
			return true
		p = p.get_parent()
	return false


static func _shape(t: Transform3D, size3: Vector3, kind: String) -> Dictionary:
	var yaw := t.basis.get_euler().y
	var sc := t.basis.get_scale()
	return {"xf": Transform2D(-yaw, Vector2(t.origin.x, t.origin.z)), "size": Vector2(size3.x * sc.x, size3.z * sc.z),
			"kind": kind}
