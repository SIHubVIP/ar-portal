class_name SoftMesh
extends RefCounted
## Мягкая геометрия (0.24, D-067): шестигранник со скруглёнными рёбрами — грани чуть ужаты,
## между ними фаска, в углах треугольник. Нормали на фаске плавно переходят от одной грани
## к другой, поэтому даже одна фаска читается как скругление: блик бежит по ребру, силуэт
## перестаёт быть «бумажным». 44 треугольника вместо 12.

const FACES := [[0, 1, 2, 3], [4, 5, 6, 7], [0, 1, 5, 4], [1, 2, 6, 5], [2, 3, 7, 6], [3, 0, 4, 7]]

static var _boxes: Dictionary = {}


## Скругление по умолчанию для коробки: ~18 % меньшей стороны, не больше 7 см.
static func bevel_for(size: Vector3) -> float:
	return clampf(minf(size.x, minf(size.y, size.z)) * 0.18, 0.004, 0.07)


## Шестигранник по 8 углам: низ 0–3, верх 4–7 (−x−z, +x−z, +x+z, −x+z), как CarKit._hex.
static func hex(st: SurfaceTool, v: Array, col: Color, bevel: float) -> void:
	var center := Vector3.ZERO
	for p: Vector3 in v:
		center += p
	center /= 8.0
	var normals: Array[Vector3] = []
	var inset: Array = []            # inset[f][угол] = точка грани f у этого угла
	for f: Array in FACES:
		var n := Vector3.ZERO
		for k in 4:
			var a: Vector3 = v[f[k]]
			var b: Vector3 = v[f[(k + 1) % 4]]
			n += a.cross(b)              # формула Ньюэлла: устойчива к вырожденным граням
		if n.length_squared() < 1e-12:
			n = Vector3.UP
		n = n.normalized()
		var fc: Vector3 = (v[f[0]] + v[f[1]] + v[f[2]] + v[f[3]]) / 4.0
		if n.dot(fc - center) < 0.0:
			n = -n
		normals.append(n)
		var shortest := INF
		for k in 4:
			var len: float = (v[f[(k + 1) % 4]] as Vector3).distance_to(v[f[k]])
			if len > 1e-5:
				shortest = minf(shortest, len)
		var bf := minf(bevel, shortest * 0.4) if shortest < INF else 0.0
		var pts := {}
		for k in 4:
			var p: Vector3 = v[f[k]]
			var to_next: Vector3 = v[f[(k + 1) % 4]] - p
			var to_prev: Vector3 = v[f[(k + 3) % 4]] - p
			var q := p
			if to_next.length_squared() > 1e-10:
				q += to_next.normalized() * bf
			if to_prev.length_squared() > 1e-10:
				q += to_prev.normalized() * bf
			pts[f[k]] = q
		inset.append(pts)
	# грани
	for fi in 6:
		var f: Array = FACES[fi]
		var n := normals[fi]
		var p: Dictionary = inset[fi]
		_tri(st, [p[f[0]], p[f[1]], p[f[2]]], [n, n, n], col, center)
		_tri(st, [p[f[0]], p[f[2]], p[f[3]]], [n, n, n], col, center)
	# фаски по рёбрам: у каждого ребра ровно две грани
	var edges := {}
	for fi in 6:
		var f: Array = FACES[fi]
		for k in 4:
			var a: int = f[k]
			var b: int = f[(k + 1) % 4]
			var key := Vector2i(mini(a, b), maxi(a, b))
			if not edges.has(key):
				edges[key] = []
			edges[key].append(fi)
	for key: Vector2i in edges:
		var fs: Array = edges[key]
		if fs.size() != 2:
			continue
		var f0: int = fs[0]
		var f1: int = fs[1]
		var a0: Vector3 = inset[f0][key.x]
		var b0: Vector3 = inset[f0][key.y]
		var a1: Vector3 = inset[f1][key.x]
		var b1: Vector3 = inset[f1][key.y]
		var n0 := normals[f0]
		var n1 := normals[f1]
		_tri(st, [a0, b0, b1], [n0, n0, n1], col, center)
		_tri(st, [a0, b1, a1], [n0, n1, n1], col, center)
	# углы: три грани сходятся в каждой вершине
	for vi in 8:
		var pts: Array = []
		var ns: Array = []
		for fi in 6:
			if (FACES[fi] as Array).has(vi):
				pts.append(inset[fi][vi])
				ns.append(normals[fi])
		if pts.size() == 3:
			_tri(st, pts, ns, col, center)


static func box(st: SurfaceTool, c: Vector3, s: Vector3, col: Color, bevel := -1.0) -> void:
	var h := s / 2.0
	hex(st, [c + Vector3(-h.x, -h.y, -h.z), c + Vector3(h.x, -h.y, -h.z), c + Vector3(h.x, -h.y, h.z),
		c + Vector3(-h.x, -h.y, h.z), c + Vector3(-h.x, h.y, -h.z), c + Vector3(h.x, h.y, -h.z),
		c + Vector3(h.x, h.y, h.z), c + Vector3(-h.x, h.y, h.z)], col, bevel_for(s) if bevel < 0.0 else bevel)


## Готовая сетка мягкой коробки размера size (кэш по размеру: в мире сотни одинаковых).
static func box_mesh(size: Vector3) -> ArrayMesh:
	var key := "%.3f|%.3f|%.3f" % [size.x, size.y, size.z]
	if _boxes.has(key):
		return _boxes[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	box(st, Vector3.ZERO, size, Color.WHITE)
	var m := st.commit()
	_boxes[key] = m
	return m


## Треугольник лицом наружу (от center); в Godot лицевая сторона — обход по часовой.
static func _tri(st: SurfaceTool, p: Array, n: Array, col: Color, center: Vector3) -> void:
	var a: Vector3 = p[0]
	var b: Vector3 = p[1]
	var c: Vector3 = p[2]
	var g := (b - a).cross(c - a)
	if g.length_squared() < 1e-14:
		return
	var order := [0, 1, 2]
	if g.dot((a + b + c) / 3.0 - center) > 0.0:
		order = [0, 2, 1]
	for i: int in order:
		st.set_normal(n[i])
		st.set_color(col)
		st.add_vertex(p[i])
