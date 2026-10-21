class_name World
## Двор «Берёзки»: static courtyard geometry + simple 2D (XZ) colliders.

const BOUNDS := Rect2(-19.0, -29.0, 38.0, 47.0)   # x, z, w, h — where the player may walk

static func _house(p: Node3D, pos: Vector3, size: Vector3, m: Material) -> void:
	Kit.part(p, Kit.BOX, m, size, pos + Vector3(0, size.y / 2, 0))
	Kit.part(p, Kit.BOX, Kit.mat(Color("6a6460"), 0.9), Vector3(size.x + 0.4, 0.4, size.z + 0.4), pos + Vector3(0, size.y + 0.2, 0))
	var n := int(size.x / 12.0)
	for i in range(n):
		var x := pos.x - size.x / 2 + 6 + i * 12
		Kit.part(p, Kit.BOX, Kit.mat(Color("7a7470"), 0.8), Vector3(2.6, 0.2, 1.4), Vector3(x, 2.6, pos.z + size.z / 2 + 0.7))
		Kit.part(p, Kit.BOX, Kit.mat(Color("4a3a32"), 0.6), Vector3(1.2, 2.2, 0.1), Vector3(x, 1.1, pos.z + size.z / 2 + 0.02))


static func build_yard(parent: Node3D) -> Dictionary:
	var root := Node3D.new()
	root.name = "World"
	parent.add_child(root)
	var st := Node3D.new()
	st.name = "Static"
	root.add_child(st)
	var rects: Array = []     # Rect2 in XZ
	var circles: Array = []   # Vector3(x, z, r)

	# ground
	Kit.part(st, Kit.BOX, Kit.mat(Color("5c7a42"), 1.0), Vector3(160, 0.2, 160), Vector3(0, -0.12, -5))
	Kit.part(st, Kit.BOX, Kit.mat(Color("5a5a62"), 0.95), Vector3(12, 0.1, 50), Vector3(0, -0.02, -6))
	Kit.part(st, Kit.BOX, Kit.mat(Color("5a5a62"), 0.95), Vector3(40, 0.1, 7), Vector3(0, -0.019, -24))
	for x in [-6.1, 6.1]:
		Kit.part(st, Kit.BOX, Kit.mat(Color("9a948a"), 0.9), Vector3(0.3, 0.16, 50), Vector3(x, 0.03, -6))
	# hopscotch
	for k in range(6):
		Kit.part(st, Kit.BOX, Kit.mat(Color("f4f0e6"), 0.9), Vector3(0.9, 0.012, 0.05), Vector3(3.5, 0.04, 2 - k * 0.9))
	for k in range(4):
		Kit.part(st, Kit.BOX, Kit.mat(Color("ff7aa8"), 0.9), Vector3(0.7, 0.012, 0.7), Vector3(3.5, 0.035, 1.55 - k * 0.9))

	# panel houses around the yard
	var f1 := Kit.facade_material(Color("c8bba6"), 0.18, 11)
	var f2 := Kit.facade_material(Color("b5b9be"), 0.2, 12)
	var f3 := Kit.facade_material(Color("d0b49a"), 0.2, 13)
	_house(st, Vector3(-30, 0, -44), Vector3(36, 15, 12), f1)
	_house(st, Vector3(26, 0, -46), Vector3(34, 15, 12), f2)
	_house(st, Vector3(-32, 0, -6), Vector3(12, 15, 40), f3)
	_house(st, Vector3(32, 0, -8), Vector3(12, 15, 36), f1)
	_house(st, Vector3(4, 0, -84), Vector3(50, 42, 14), f2)
	_house(st, Vector3(-26, 0, 30), Vector3(30, 15, 12), f2)
	_house(st, Vector3(26, 0, 32), Vector3(30, 15, 12), f3)

	# garage row (north edge) — the boss arena is in front of it; a passage to ГК «Песня» on the right
	var rust := [Color("8a4a3a"), Color("5a6a7a"), Color("7a6a4a"), Color("4a5a4a"), Color("6a4a5a")]
	for i in range(-5, 4):
		var g := Node3D.new()
		g.position = Vector3(i * 3.4, 0, -30)
		st.add_child(g)
		var c: Color = rust[(i + 5) % 5]
		Kit.part(g, Kit.BOX, Kit.mat(Color("b8b0a0"), 0.95), Vector3(3.4, 2.8, 6), Vector3(0, 1.4, -3))
		Kit.part(g, Kit.BOX, Kit.mat(c, 0.7, 0.3), Vector3(2.8, 2.2, 0.08), Vector3(0, 1.1, 0.02))
		for k in range(9):
			Kit.part(g, Kit.BOX, Kit.mat(c.darkened(0.2), 0.7, 0.3), Vector3(2.8, 0.03, 0.03), Vector3(0, 0.2 + k * 0.24, 0.07))
		Kit.part(g, Kit.BOX, Kit.mat(Color("3a3a3a"), 0.9), Vector3(3.5, 0.15, 6.4), Vector3(0, 2.85, -3))
	rects.append(Rect2(-19.0, -36.0, 31.0, 6.2))
	rects.append(Rect2(18.6, -36.0, 2.0, 6.2))
	Chars.label(root, "ГАРАЖИ", 120, Color(1.8, 1.6, 1.2), Vector3(-3, 3.6, -29.9), Vector3.ZERO, 0.01, 10)
	# arch to the garage cooperative
	var arch := Kit.mat(Color("2a5a3a"), 0.5, 0.4)
	for x in [13.2, 18.0]:
		Kit.part(st, Kit.BOX, arch, Vector3(0.35, 4.2, 0.35), Vector3(x, 2.1, -29.6))
		circles.append(Vector3(x, -29.6, 0.3))
	Kit.part(st, Kit.BOX, arch, Vector3(5.2, 0.6, 0.3), Vector3(15.6, 4.2, -29.6))
	Chars.label(root, "ГК «ПЕСНЯ»", 90, Color(3.0, 2.2, 1.0), Vector3(15.6, 4.2, -29.4), Vector3.ZERO, 0.0085, 10)
	Chars.label(root, "проход к гаражам ↑", 60, Color(1.6, 1.6, 1.6), Vector3(15.6, 3.5, -29.4), Vector3.ZERO, 0.007, 8)
	Chars.ring(root, Vector3(15.6, 0.05, -28.4), 1.2, Color("55cdbe"), 0.08, 3.0)
	Kit.part(st, Kit.BOX, Kit.mat(Color("5a5a62"), 0.95), Vector3(4.6, 0.1, 8.0), Vector3(15.6, -0.018, -32))

	# playground
	var red := Kit.mat(Color("d8423c"), 0.6)
	var yel := Kit.mat(Color("f2b21c"), 0.6)
	var blu := Kit.mat(Color("3a7ac8"), 0.6)
	for x in [8.5, 11.5]:
		for z in [-4.0, -5.4]:
			Kit.part(st, Kit.CYL, red, Vector3(0.12, 2.6, 0.12), Vector3(x, 1.3, z), Vector3(0.18 * (1 if z < -4.5 else -1), 0, 0))
	Kit.part(st, Kit.CYL, red, Vector3(0.12, 3.2, 0.12), Vector3(10, 2.55, -4.7), Vector3(0, 0, PI / 2))
	for x in [9.4, 10.6]:
		Kit.part(st, Kit.BOX, Kit.mat(Color("5a5a62")), Vector3(0.02, 1.8, 0.02), Vector3(x - 0.2, 1.6, -4.7))
		Kit.part(st, Kit.BOX, Kit.mat(Color("5a5a62")), Vector3(0.02, 1.8, 0.02), Vector3(x + 0.2, 1.6, -4.7))
		Kit.part(st, Kit.BOX, yel, Vector3(0.6, 0.06, 0.3), Vector3(x, 0.7, -4.7))
	for x in [8.5, 11.5]:
		circles.append(Vector3(x, -4.7, 0.5))
	Kit.part(st, Kit.BOX, blu, Vector3(1.4, 1.6, 1.4), Vector3(11, 0.8, -10))
	Kit.part(st, Kit.BOX, yel, Vector3(0.9, 0.08, 3.2), Vector3(11, 0.9, -8), Vector3(-0.5, 0, 0))
	rects.append(Rect2(10.3, -10.7, 1.4, 1.4))
	# sandbox
	Kit.part(st, Kit.BOX, Kit.mat(Color("8a5a32"), 0.9), Vector3(3.2, 0.3, 3.2), Vector3(13.5, 0.15, 2))
	Kit.part(st, Kit.BOX, Kit.mat(Color("e8cf8a"), 1.0), Vector3(2.8, 0.31, 2.8), Vector3(13.5, 0.16, 2))

	# benches
	for z in [-2.0, -8.0]:
		var b := Node3D.new()
		b.position = Vector3(-6.9, 0, z)
		b.rotation.y = PI / 2
		st.add_child(b)
		Kit.part(b, Kit.BOX, Kit.mat(Color("3a8a5a"), 0.7), Vector3(2.2, 0.08, 0.5), Vector3(0, 0.5, 0))
		Kit.part(b, Kit.BOX, Kit.mat(Color("3a8a5a"), 0.7), Vector3(2.2, 0.5, 0.08), Vector3(0, 0.85, -0.25))
		for x in [-0.9, 0.9]:
			Kit.part(b, Kit.BOX, Kit.mat(Color("2a2a2a")), Vector3(0.08, 0.5, 0.5), Vector3(x, 0.25, 0))
		rects.append(Rect2(-7.25, z - 1.1, 0.6, 2.2))

	# kiosk
	var k := Node3D.new()
	k.position = Vector3(-11, 0, -15)
	k.rotation.y = 0.5
	st.add_child(k)
	Kit.part(k, Kit.BOX, Kit.mat(Color("e8e0d0"), 0.7), Vector3(3, 2.6, 2.4), Vector3(0, 1.3, 0))
	Kit.part(k, Kit.BOX, Kit.mat(Color("d8423c"), 0.6), Vector3(3.3, 0.5, 2.7), Vector3(0, 2.8, 0))
	Kit.part(k, Kit.BOX, Kit.mat(Color("ffcf7a"), 0.3, 0.0, Color("ffcf7a"), 1.2), Vector3(1.8, 1.0, 0.05), Vector3(0, 1.5, 1.21))
	var kl := Chars.label(root, "ШАУРМА", 90, Color(4, 3.5, 2.6), Vector3.ZERO, Vector3.ZERO, 0.007, 10)
	kl.position = k.position + Vector3(sin(0.5), 0, cos(0.5)) * 1.37 + Vector3(0, 2.8, 0)
	kl.rotation.y = 0.5
	circles.append(Vector3(-11, -15, 1.9))

	# street lamps
	for z in [6.0, -6.0, -18.0]:
		for x in [-6.4, 6.4]:
			Kit.part(st, Kit.CYL, Kit.mat(Color("2a2a32"), 0.4, 0.6), Vector3(0.16, 5, 0.16), Vector3(x, 2.5, z))
			Kit.part(st, Kit.BOX, Kit.mat(Color("2a2a32"), 0.4, 0.6), Vector3(1.0, 0.12, 0.25), Vector3(x - sign(x) * 0.45, 5, z))
			Kit.part(st, Kit.BOX, Kit.neon(Color("ffe2b0"), 2.0), Vector3(0.5, 0.05, 0.2), Vector3(x - sign(x) * 0.7, 4.93, z))
			circles.append(Vector3(x, z, 0.25))

	# trees
	var tree_pos := [Vector3(-9, 0, -4), Vector3(9, 0, -16), Vector3(-9.5, 0, 4), Vector3(9.5, 0, 6), Vector3(-14, 0, -22),
		Vector3(15, 0, -11), Vector3(-16, 0, -9), Vector3(16, 0, 12), Vector3(-16, 0, 13), Vector3(11, 0, -25), Vector3(-3, 0, -26)]
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for p in tree_pos:
		Chars.tree(st, p, rng.randf_range(0.9, 1.3), Color("4a8a3a").lerp(Color("c8a03a"), rng.randf() * 0.4))
		circles.append(Vector3(p.x, p.z, 0.55))

	# fence around the yard (low, decorative + bounds)
	var fence := Kit.mat(Color("2a5a3a"), 0.6, 0.3)
	for x in range(-19, 20, 2):
		for z in [18.4, -0.0]:
			if z == 18.4 and absf(x) > 4:
				Kit.part(st, Kit.BOX, fence, Vector3(2.0, 0.9, 0.06), Vector3(x, 0.45, z))
	for z in range(-28, 19, 2):
		for x in [-19.4, 19.4]:
			Kit.part(st, Kit.BOX, fence, Vector3(0.06, 0.9, 2.0), Vector3(x, 0.45, z))

	Kit.bake_static(st)
	return {"root": root, "rects": rects, "circles": circles, "id": "yard", "name": "Двор «Берёзки»", "bounds": BOUNDS,
		"map_rects": [Rect2(-6, -31, 12, 50), Rect2(-20, -27, 40, 7), Rect2(13.5, -36, 4.2, 8)],
		"spawns": {"start": [Vector3(0, 0, 12), PI], "from_garages": [Vector3(15.6, 0, -25.6), 0.0], "respawn": [Vector3(-3.6, 0, -4.2), PI / 2]},
		"portals": [{"pos": Vector3(15.6, 0, -28.4), "r": 1.3, "to": "garages", "spawn": "from_yard", "label": "ГК «Песня»"}],
		"npcs": [{"id": "zina", "pos": Vector3(-5.9, 0, -5.0), "rot": PI / 2}, {"id": "misha", "pos": Vector3(4.6, 0, 13.6), "rot": PI + 0.4},
			{"id": "lyuba", "pos": Vector3(-9.7, 0, -13.1), "rot": 0.5}],
		"mobs": [["pigeon", Vector3(3, 0, -6), 2], ["pigeon", Vector3(-2, 0, -11), 3], ["pigeon", Vector3(6, 0, -14), 4], ["pigeon", Vector3(-9, 0, -19), 2],
			["pigeon", Vector3(2, 0, -19), 3], ["pigeon", Vector3(-13, 0, 3), 4], ["pigeon", Vector3(12, 0, 9), 2],
			["scooter", Vector3(0, 0, -2), 3], ["scooter", Vector3(-3, 0, -22), 4], ["scooter", Vector3(9, 0, 3), 5],
			["vacuum", Vector3(-15, 0, -21), 5], ["vacuum", Vector3(15, 0, -6), 6]]}


## Push a point (x,z) with radius r out of all colliders and keep it inside the yard.
static func resolve(p: Vector3, r: float, rects: Array, circles: Array, b: Rect2 = BOUNDS) -> Vector3:
	p.x = clampf(p.x, b.position.x + r, b.end.x - r)
	p.z = clampf(p.z, b.position.y + r, b.end.y - r)
	for c in circles:
		var d := Vector2(p.x - c.x, p.z - c.y)
		var rr: float = c.z + r
		var l := d.length()
		if l < rr:
			if l < 0.001:
				d = Vector2(1, 0)
				l = 1.0
			var n := d / l
			p.x = c.x + n.x * rr
			p.z = c.y + n.y * rr
	for rc in rects:
		var e: Rect2 = rc.grow(r)
		if p.x > e.position.x and p.x < e.end.x and p.z > e.position.y and p.z < e.end.y:
			var dl := p.x - e.position.x
			var dr := e.end.x - p.x
			var dt := p.z - e.position.y
			var db := e.end.y - p.z
			var m := minf(minf(dl, dr), minf(dt, db))
			if m == dl:
				p.x = e.position.x
			elif m == dr:
				p.x = e.end.x
			elif m == dt:
				p.z = e.position.y
			else:
				p.z = e.end.y
	return p
