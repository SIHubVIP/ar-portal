class_name MapCanvas
extends Control
## Рисует квартал сверху: дома — тёмные плиты, улицы и тротуары — серые, разметка — светлая.
## Геометрию собирает collect() один раз из коллизий и плоских коробок мира, так что карта
## всегда совпадает с тем, во что упирается герой. Вид задают origin (центр в метрах),
## scale (пикселей на метр) и rot (поворот вместе с камерой). С district = true под кварталом
## рисуется остальной Погуляй из манифеста: дороги с шириной коридора и дома со схемы.

const COLORS := {"road": Color(0.34, 0.34, 0.36), "walk": Color(0.27, 0.27, 0.29), "mark": Color(0.55, 0.55, 0.55),
		"prop": Color(0.2, 0.2, 0.22), "block": Color(0.09, 0.09, 0.1), "edge": Color(0.36, 0.36, 0.4)}
const BG := Color(0.13, 0.13, 0.14)

## [{xf: Transform2D, size: Vector2, kind: String}]
var shapes: Array = []
var origin := Vector2.ZERO
var scale_px := 4.0
var rot := 0.0
var district := false

static var _roads: Array = []       # [{pts: PackedVector2Array (x, z), w: float}]
static var _houses: Array[Rect2] = []


## Мировая точка (x, z) → точка на контроле.
func to_screen(world: Vector3) -> Vector2:
	return _view() * Vector2(world.x, world.z)


func _view() -> Transform2D:
	return Transform2D(rot, Vector2(scale_px, scale_px), 0.0, size / 2.0) * Transform2D(0.0, -origin)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG)
	var view := _view()
	if district:
		_draw_district(view)
	for pass_kind in ["walk", "road", "mark", "prop", "block"]:
		for s in shapes:
			if s.kind != pass_kind:
				continue
			draw_set_transform_matrix(view * s.xf)
			var r := Rect2(-s.size / 2.0, s.size)
			draw_rect(r, COLORS[pass_kind])
			if pass_kind == "block":
				draw_rect(r, COLORS.edge, false, 1.0 / scale_px)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_district(view: Transform2D) -> void:
	if _roads.is_empty():
		_load_district()
	draw_set_transform_matrix(view)
	var reach := size.length() / 2.0 / scale_px + 20.0
	var area := Rect2(origin - Vector2(reach, reach), Vector2(reach, reach) * 2.0)
	for h in _houses:
		if area.intersects(h):
			draw_rect(h, COLORS.block)
	for r in _roads:
		draw_polyline(r.pts, COLORS.road, r.w)
	draw_set_transform_matrix(Transform2D.IDENTITY)


static func _load_district() -> void:
	var o := District.ORIGIN_M
	for r in District.data().get("road_centerlines", []):
		var pts := PackedVector2Array()
		for q in r.polyline_plan_m:
			pts.append(District.m(q) - o)
		_roads.append({"pts": pts, "w": float(r.corridor_width_m)})
	for s in District.road_segments():
		if s.id == "lane":
			_roads.append({"pts": PackedVector2Array([s.a - o, s.b - o]), "w": float(s.w)})
	for h in District.houses():
		_houses.append(Rect2(h.position - o, h.size))


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
		if not mi.mesh is BoxMesh or _skipped(mi):
			continue
		var sz := (mi.mesh as BoxMesh).size
		if sz.y > 0.3 or mi.global_position.y > 0.3 or sz.x >= 100.0:
			continue
		var kind := "mark" if minf(sz.x, sz.z) < 0.4 else ("walk" if mi.global_position.y > 0.05 else "road")
		out.append(_shape(mi.global_transform, sz, kind))
	return out


static func _skipped(n: Node) -> bool:
	var p := n.get_parent()
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
