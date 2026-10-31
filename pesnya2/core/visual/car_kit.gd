class_name CarKit
extends RefCounted
## Легковушка из гранёных объёмов (0.12): кузов с капотом и багажником ниже крыши, скошенные
## лобовое и заднее стёкла, крыша цвета кузова, колёса-восьмигранники с дисками, бамперы,
## решётка, фары, фонари, номер и зеркала. Одна сетка на цвет и вид (cached), цвета — в вершинах,
## материал — plain_color: альфа вершины 0 — светится (фары включены у машин на ходу).
## Перёд — +Z, длина 4,3 м, ширина 1,76 м; низ колёс — y = 0.

const LENGTH := 4.3
const WIDTH := 1.76
const GLASS := Color(0.14, 0.18, 0.23)
const TYRE := Color(0.06, 0.06, 0.06)
const TRIM := Color(0.16, 0.16, 0.17)

static var _cache: Dictionary = {}


## variant: 0 — седан, 1 — универсал (длинная крыша), 2 — хэтчбек (короче корма).
static func mesh(body: Color, lit := false, variant := 0) -> ArrayMesh:
	var key := "%s|%s|%d" % [body.to_html(), lit, variant]
	if _cache.has(key):
		return _cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw := WIDTH / 2.0
	var hl := LENGTH / 2.0
	var tail := -hl + (0.35 if variant == 2 else 0.0)
	# нижний кузов: борта чуть заваливаются внутрь, капот спереди ниже крыльев
	_hex(st, [Vector3(-hw, 0.32, tail), Vector3(hw, 0.32, tail), Vector3(hw, 0.32, hl), Vector3(-hw, 0.32, hl),
		Vector3(-hw + 0.05, 0.86, tail + 0.08), Vector3(hw - 0.05, 0.86, tail + 0.08), Vector3(hw - 0.05, 0.8, hl - 0.06),
		Vector3(-hw + 0.05, 0.8, hl - 0.06)], body, 0.14)
	# салон: стёкла кругом, низ шире верха, лобовое и заднее скошены
	var c0 := tail + (0.75 if variant == 0 else 0.35)
	var c1 := 0.75
	var r0 := c0 + (0.4 if variant == 0 else 0.12)
	var r1 := 0.05
	_hex(st, [Vector3(-hw + 0.1, 0.86, c0), Vector3(hw - 0.1, 0.86, c0), Vector3(hw - 0.1, 0.86, c1), Vector3(-hw + 0.1, 0.86, c1),
		Vector3(-hw + 0.24, 1.4, r0), Vector3(hw - 0.24, 1.4, r0), Vector3(hw - 0.24, 1.4, r1), Vector3(-hw + 0.24, 1.4, r1)], GLASS, 0.08)
	# крыша и стойки цвета кузова
	_hex(st, [Vector3(-hw + 0.22, 1.38, r0 - 0.02), Vector3(hw - 0.22, 1.38, r0 - 0.02), Vector3(hw - 0.22, 1.38, r1 + 0.02),
		Vector3(-hw + 0.22, 1.38, r1 + 0.02), Vector3(-hw + 0.26, 1.45, r0 + 0.03), Vector3(hw - 0.26, 1.45, r0 + 0.03),
		Vector3(hw - 0.26, 1.45, r1 - 0.03), Vector3(-hw + 0.26, 1.45, r1 - 0.03)], body, 0.06)
	var mid := (r0 + r1) / 2.0
	for sx: float in [-1.0, 1.0]:
		_box(st, Vector3(sx * (hw - 0.17), 1.13, mid), Vector3(0.05, 0.54, 0.09), body)      # средняя стойка
	# колёса с дисками и чёрные арки
	for sz: float in [hl - 0.78, tail + 0.75]:
		for sx: float in [-1.0, 1.0]:
			_wheel(st, Vector3(sx * (hw - 0.1), 0.33, sz), 0.33, 0.24, sx)
			_box(st, Vector3(sx * (hw + 0.005), 0.52, sz), Vector3(0.02, 0.36, 0.92), TRIM)
	# бамперы, решётка, номера
	_box(st, Vector3(0, 0.42, hl + 0.03), Vector3(WIDTH + 0.02, 0.18, 0.12), TRIM)
	_box(st, Vector3(0, 0.42, tail - 0.03), Vector3(WIDTH + 0.02, 0.18, 0.12), TRIM)
	_box(st, Vector3(0, 0.66, hl + 0.005), Vector3(0.8, 0.18, 0.02), Color(0.1, 0.1, 0.11))
	_box(st, Vector3(0, 0.42, hl + 0.095), Vector3(0.52, 0.12, 0.01), Color(0.92, 0.92, 0.9))
	_box(st, Vector3(0, 0.62, tail - 0.005), Vector3(0.52, 0.12, 0.01), Color(0.92, 0.92, 0.9))
	# фары и фонари: у машин на ходу горят (альфа 0)
	var head := Color(1.0, 0.95, 0.8, 0.0 if lit else 1.0)
	var rear := Color(0.9, 0.08, 0.05, 0.3 if lit else 1.0)
	for sx: float in [-1.0, 1.0]:
		_box(st, Vector3(sx * 0.62, 0.68, hl + 0.005), Vector3(0.3, 0.14, 0.02), head)
		_box(st, Vector3(sx * 0.66, 0.7, tail - 0.005), Vector3(0.26, 0.12, 0.02), rear)
		_box(st, Vector3(sx * (hw + 0.07), 0.98, c1 - 0.08), Vector3(0.12, 0.08, 0.06), body)    # зеркало
	var m := st.commit()
	m.surface_set_material(0, DistrictDressing._material("plain"))
	_cache[key] = m
	return m


## Машина узлом (для машин улицы): сетка нужного цвета под Node3D.
static func make(parent: Node3D, body: Color, lit := false, variant := 0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh(body, lit, variant)
	parent.add_child(mi)
	return mi


static func _wheel(st: SurfaceTool, c: Vector3, r: float, w: float, side: float) -> void:
	var n := 8
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var p0 := Vector3(0, sin(a0) * r, cos(a0) * r)
		var p1 := Vector3(0, sin(a1) * r, cos(a1) * r)
		var o := Vector3(w / 2.0, 0, 0)
		_quad(st, c + p0 - o, c + p1 - o, c + p1 + o, c + p0 + o, TYRE, c)
		_tri_out(st, c + o * side, c + p0 + o * side, c + p1 + o * side, Color(0.6, 0.6, 0.62) if i % 2 else TYRE, c)
		_tri_out(st, c - o * side, c + p0 - o * side, c + p1 - o * side, TYRE, c)


static func _box(st: SurfaceTool, c: Vector3, s: Vector3, col: Color) -> void:
	var h := s / 2.0
	_hex(st, [c + Vector3(-h.x, -h.y, -h.z), c + Vector3(h.x, -h.y, -h.z), c + Vector3(h.x, -h.y, h.z), c + Vector3(-h.x, -h.y, h.z),
		c + Vector3(-h.x, h.y, -h.z), c + Vector3(h.x, h.y, -h.z), c + Vector3(h.x, h.y, h.z), c + Vector3(-h.x, h.y, h.z)], col,
		SoftMesh.bevel_for(s))


## Шестигранник по 8 углам: низ 0–3, верх 4–7 (−x−z, +x−z, +x+z, −x+z). Грани наружу.
static func _hex(st: SurfaceTool, v: Array, col: Color, bevel := 0.05) -> void:
	# 0.24: рёбра скруглены (SoftMesh) — мультяшный объём вместо картонных граней
	if bevel > 0.0:
		SoftMesh.hex(st, v, col, bevel)
		return
	var center := Vector3.ZERO
	for p: Vector3 in v:
		center += p
	center /= 8.0
	for f: Array in [[0, 1, 2, 3], [4, 5, 6, 7], [0, 1, 5, 4], [1, 2, 6, 5], [2, 3, 7, 6], [3, 0, 4, 7]]:
		_quad(st, v[f[0]], v[f[1]], v[f[2]], v[f[3]], col, center)


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color, center: Vector3) -> void:
	_tri_out(st, a, b, c, col, center)
	_tri_out(st, a, c, d, col, center)


## Треугольник лицом от center: в Godot лицевая сторона — обход по часовой, то есть
## cross(b − a, c − a) смотрит внутрь.
static func _tri_out(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, col: Color, center: Vector3) -> void:
	var n := (b - a).cross(c - a)
	if n.length_squared() < 1e-10:
		return
	var out := ((a + b + c) / 3.0 - center)
	if n.dot(out) > 0.0:
		var t := b
		b = c
		c = t
		n = -n
	var normal := -n.normalized()
	for p in [a, b, c]:
		st.set_normal(normal)
		st.set_color(col)
		st.add_vertex(p)
