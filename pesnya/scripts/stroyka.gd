class_name Stroyka
## Стройка Глушилки (0.3): construction site of Koschei's silence tower behind the garage cooperative.
## Entered through the west gate of ГК «Песня». Tishinka drones, runaway scooters and the boss Shumodav.

const BOUNDS := Rect2(-28.0, -18.0, 56.0, 36.0)
const ARENA := Vector3(-16.0, 0, 0)
const BOSS_HOME := Vector3(-18.5, 0, 0)


static func _fence(st: Node3D, a: Vector3, b: Vector3, col: Color) -> void:
	var d := b - a
	var n := int(d.length() / 2.0)
	var dir := d.normalized()
	var m := Kit.mat(col, 0.6, 0.3)
	var post := Kit.mat(Color("d8d8d8"), 0.5, 0.6)
	for i in range(n):
		var c := a + dir * (i * 2.0 + 1.0)
		var p := Kit.part(st, Kit.BOX, m, Vector3(1.96, 2.2, 0.06), c + Vector3(0, 1.1, 0))
		p.rotation.y = atan2(dir.x, dir.z) + PI / 2
		Kit.part(st, Kit.BOX, post, Vector3(0.1, 2.3, 0.1), a + dir * (i * 2.0) + Vector3(0, 1.15, 0))


static func _slabs(st: Node3D, rects: Array, c: Vector3, size: Vector3, layers: int) -> void:
	var conc := Kit.mat(Color("9a9690"), 0.95)
	var conc2 := Kit.mat(Color("85817c"), 0.95)
	for k in range(layers):
		var off := Vector3(sin(k * 1.7) * 0.15, size.y * (k + 0.5), cos(k * 2.3) * 0.15)
		Kit.part(st, Kit.BOX, conc if k % 2 == 0 else conc2, size, c + off, Vector3(0, sin(k * 0.9) * 0.05, 0))
	rects.append(Rect2(c.x - size.x / 2 - 0.1, c.z - size.z / 2 - 0.1, size.x + 0.2, size.z + 0.2))


static func _cone(st: Node3D, p: Vector3) -> void:
	Kit.part(st, Kit.BOX, Kit.mat(Color("2a2a2a"), 0.8), Vector3(0.5, 0.06, 0.5), p + Vector3(0, 0.03, 0))
	Kit.part(st, Kit.CONE, Kit.mat(Color("ff6a1a"), 0.6), Vector3(0.36, 0.7, 0.36), p + Vector3(0, 0.4, 0))
	Kit.part(st, Kit.CYL, Kit.mat(Color("f4f4f4"), 0.6), Vector3(0.26, 0.1, 0.26), p + Vector3(0, 0.45, 0))


static func build(parent: Node3D) -> Dictionary:
	var root := Node3D.new()
	root.name = "World"
	parent.add_child(root)
	var st := Node3D.new()
	st.name = "Static"
	root.add_child(st)
	var rects: Array = []
	var circles: Array = []

	# ground: dirt, a gravel road from the gate, a concrete pad for the arena
	Kit.part(st, Kit.BOX, Kit.mat(Color("6e5c46"), 1.0), Vector3(220, 0.2, 220), Vector3(0, -0.12, 0))
	Kit.part(st, Kit.BOX, Kit.mat(Color("7c7468"), 0.95), Vector3(44, 0.1, 6), Vector3(6, -0.02, 0))
	Kit.part(st, Kit.CYL, Kit.mat(Color("8c8a86"), 0.9), Vector3(20, 0.1, 20), ARENA + Vector3(0, -0.01, 0))
	Chars.ring(root, ARENA + Vector3(0, 0.06, 0), 9.6, Color("ffd23a"), 0.1, 1.2)
	# tyre tracks and puddles
	for p in [Vector3(12, 0, 2.1), Vector3(2, 0, -2.0), Vector3(-6, 0, 1.6)]:
		Kit.part(st, Kit.CYL, Kit.mat(Color("2a3448"), 0.05, 0.6), Vector3(2.6, 0.01, 1.3), p + Vector3(0, 0.04, 0))

	# the silence tower «Глушилка» — a giant grey earplug behind the arena
	var tw := Node3D.new()
	tw.position = Vector3(-50, 0, 0)
	st.add_child(tw)
	var grey := Kit.mat(Color("b4b8bc"), 0.75, 0.1)
	var grey2 := Kit.mat(Color("8e9298"), 0.8, 0.1)
	Kit.part(tw, Kit.CAP, grey, Vector3(22, 74, 22), Vector3(0, 30, 0))
	for k in range(5):
		Kit.part(tw, Kit.CYL, grey2, Vector3(22.6, 0.8, 22.6), Vector3(0, 6 + k * 9, 0))
	Kit.part(tw, Kit.CYL, Kit.mat(Color("5a5e66"), 0.6, 0.5), Vector3(4, 6, 4), Vector3(0, 69, 0))
	# scaffolding around the base
	var scaf := Kit.mat(Color("c8a03a"), 0.5, 0.6)
	for k in range(8):
		var a := -0.42 + k * 0.12
		var p := Vector3(cos(a) * 12.0, 0, sin(a) * 12.0)
		Kit.part(tw, Kit.BOX, scaf, Vector3(0.2, 22, 0.2), p + Vector3(0, 11, 0))
	for h in [5.0, 10.0, 15.0, 20.0]:
		Kit.part(tw, Kit.BOX, scaf, Vector3(1.4, 0.12, 10.4), Vector3(11.6, h, 0))
	var logo := Chars.label(root, "КОЩЕЙТЕХ", 260, Color(2.6, 2.6, 2.8), Vector3(-38.6, 36, 0), Vector3(0, PI / 2, 0), 0.018, 0)
	logo.name = "TowerLogo"

	# tower crane
	var crane := Node3D.new()
	crane.position = Vector3(-4, 0, -15.5)
	st.add_child(crane)
	var yel := Kit.mat(Color("f2b21c"), 0.5, 0.4)
	Kit.part(crane, Kit.BOX, Kit.mat(Color("7a7a7a"), 0.9), Vector3(3, 0.8, 3), Vector3(0, 0.4, 0))
	for sx in [-0.55, 0.55]:
		for sz in [-0.55, 0.55]:
			Kit.part(crane, Kit.BOX, yel, Vector3(0.14, 30, 0.14), Vector3(sx, 15.4, sz))
	for k in range(15):
		Kit.part(crane, Kit.BOX, yel, Vector3(1.2, 0.08, 0.08), Vector3(0, 1.5 + k * 2.0, 0.55), Vector3(0, 0, 0.9))
		Kit.part(crane, Kit.BOX, yel, Vector3(0.08, 0.08, 1.2), Vector3(0.55, 2.5 + k * 2.0, 0), Vector3(0.9, 0, 0))
	Kit.part(crane, Kit.BOX, yel, Vector3(30, 0.9, 0.9), Vector3(11, 31, 0))
	Kit.part(crane, Kit.BOX, yel, Vector3(9, 0.9, 0.9), Vector3(-5.5, 31, 0))
	Kit.part(crane, Kit.BOX, Kit.mat(Color("8a8680"), 0.9), Vector3(2.4, 2.0, 1.6), Vector3(-8.5, 30, 0))
	Kit.part(crane, Kit.BOX, Kit.mat(Color("2a5ac8"), 0.4, 0.3), Vector3(1.6, 1.6, 1.6), Vector3(1.4, 29.6, 0))
	Kit.part(crane, Kit.CONE, yel, Vector3(1.2, 4, 1.2), Vector3(0, 33.5, 0))
	Kit.part(crane, Kit.CYL, Kit.mat(Color("2a2a2a"), 0.5, 0.8), Vector3(0.05, 20, 0.05), Vector3(18, 21, 0))
	Kit.part(crane, Kit.BOX, Kit.mat(Color("9a9690"), 0.95), Vector3(2.4, 0.8, 1.2), Vector3(18, 10.6, 0))
	Kit.part(crane, Kit.SPH, Kit.neon(Color("ff2a2a"), 5.0), Vector3.ONE * 0.4, Vector3(25.6, 31.6, 0))
	rects.append(Rect2(-5.6, -17.1, 3.2, 3.2))

	# piles of concrete slabs, pipes, sand, a cement mixer, site cabins
	_slabs(st, rects, Vector3(5, 0, -10), Vector3(5.2, 0.35, 2.6), 4)
	_slabs(st, rects, Vector3(11, 0, 9.5), Vector3(3.6, 0.35, 5.0), 3)
	_slabs(st, rects, Vector3(-3, 0, 11.5), Vector3(5.6, 0.35, 2.4), 5)
	_slabs(st, rects, Vector3(-24, 0, -11), Vector3(4.0, 0.4, 4.0), 6)
	var pipe := Kit.mat(Color("4a6a8a"), 0.5, 0.6)
	for k in range(5):
		var row := 0 if k < 3 else 1
		var x: float = 15.0 + (float(k) if k < 3 else float(k) - 2.5) * 0.75
		Kit.part(st, Kit.CYL, pipe, Vector3(0.7, 6, 0.7), Vector3(x, 0.38 + row * 0.62, -9.5), Vector3(PI / 2, 0, 0))
	rects.append(Rect2(14.5, -12.6, 2.4, 6.2))
	var sand := Kit.mat(Color("d8b46a"), 1.0)
	Kit.part(st, Kit.SPH, sand, Vector3(5, 2.2, 4), Vector3(3, 0, 7.5))
	circles.append(Vector3(3, 7.5, 2.0))
	Kit.part(st, Kit.SPH, sand, Vector3(3.4, 1.6, 3), Vector3(-26, 0, 11))
	# cement mixer
	var mx := Node3D.new()
	mx.position = Vector3(19, 0, 10)
	mx.rotation.y = 0.4
	st.add_child(mx)
	Kit.part(mx, Kit.BOX, Kit.mat(Color("3a3a42"), 0.6, 0.5), Vector3(1.6, 0.3, 2.4), Vector3(0, 0.6, 0))
	for sx in [-0.7, 0.7]:
		for sz in [-0.9, 0.9]:
			Kit.part(mx, Kit.CYL, Kit.mat(Color("1d1e24"), 0.8), Vector3(0.6, 0.2, 0.6), Vector3(sx, 0.3, sz), Vector3(0, 0, PI / 2))
	Kit.part(mx, Kit.CYL, Kit.mat(Color("f2b21c"), 0.5, 0.3), Vector3(1.4, 1.8, 1.4), Vector3(0, 1.6, 0.1), Vector3(0.9, 0, 0))
	Kit.part(mx, Kit.CYL, Kit.mat(Color("f2b21c"), 0.5, 0.3), Vector3(0.8, 0.6, 0.8), Vector3(0, 2.2, 1.0), Vector3(0.9, 0, 0))
	circles.append(Vector3(19, 10, 1.5))
	# site cabins («бытовки»)
	for i in range(2):
		var cb := Node3D.new()
		cb.position = Vector3(19 + i * 0.2, 0, -14.5 + i * 2.9)
		st.add_child(cb)
		Kit.part(cb, Kit.BOX, Kit.mat(Color("2a6ac8") if i == 0 else Color("e8e0d0"), 0.7, 0.2), Vector3(6, 2.6, 2.6), Vector3(0, 1.45, 0))
		Kit.part(cb, Kit.BOX, Kit.mat(Color("3a3a3a"), 0.9), Vector3(6.2, 0.12, 2.8), Vector3(0, 2.8, 0))
		for k in range(2):
			Kit.part(cb, Kit.BOX, Kit.mat(Color("ffcf7a"), 0.3, 0.0, Color("ffb050"), 1.6), Vector3(0.9, 0.7, 0.05), Vector3(-1.6 + k * 3.0, 1.7, 1.31))
	Chars.label(root, "ПРОРАБ", 70, Color(3.0, 2.6, 1.6), Vector3(19, 2.55, -13.15), Vector3.ZERO, 0.007, 8)
	rects.append(Rect2(15.9, -16.0, 6.4, 5.8))
	# traffic cones
	for p in [Vector3(8, 0, -3.4), Vector3(9, 0, 3.4), Vector3(-1, 0, -3.6), Vector3(-6.4, 0, 6.8), Vector3(-6.6, 0, -6.6),
			Vector3(13, 0, 13.5), Vector3(-12, 0, 13), Vector3(-12, 0, -13)]:
		_cone(st, p)
	# floodlights around the arena
	for a in [0.7, 2.4, 3.9, 5.5]:
		var fp := ARENA + Vector3(cos(a) * 10.6, 0, sin(a) * 10.6)
		Kit.part(st, Kit.CYL, Kit.mat(Color("2a2a32"), 0.4, 0.6), Vector3(0.22, 7, 0.22), fp + Vector3(0, 3.5, 0))
		var head := Kit.part(st, Kit.BOX, Kit.neon(Color("fff4d8"), 3.0), Vector3(1.2, 0.7, 0.2), fp + Vector3(0, 7, 0))
		head.rotation.y = atan2(ARENA.x - fp.x, ARENA.z - fp.z)
		circles.append(Vector3(fp.x, fp.z, 0.3))

	# construction fence with Koschei's signs
	var blue := Color("2a5ab8")
	_fence(st, Vector3(-28, 0, -18), Vector3(26, 0, -18), blue)
	_fence(st, Vector3(-28, 0, 18), Vector3(26, 0, 18), blue)
	_fence(st, Vector3(-28, 0, -18), Vector3(-28, 0, 18), blue)
	_fence(st, Vector3(28, 0, -18), Vector3(28, 0, -3.2), blue)
	_fence(st, Vector3(28, 0, 3.2), Vector3(28, 0, 18), blue)
	Chars.label(root, "КОЩЕЙТЕХ · СТРОЙКА ГЛУШИЛКИ", 90, Color("ffffff"), Vector3(-4, 1.5, -17.9), Vector3.ZERO, 0.008, 6)
	Chars.label(root, "ТИХО! ИДЁТ СТРОИТЕЛЬСТВО ТИШИНЫ", 80, Color("ffe8a0"), Vector3(-4, 1.5, 17.9), Vector3(0, PI, 0), 0.008, 6)
	Chars.label(root, "ПОСТОРОННИМ ВХОД ВОСПРЕЩЁН", 70, Color("ffffff"), Vector3(27.9, 1.6, -10), Vector3(0, -PI / 2, 0), 0.007, 6)
	# entrance gate back to the garages
	var arch := Kit.mat(Color("2a5a3a"), 0.5, 0.4)
	for z in [-3.2, 3.2]:
		Kit.part(st, Kit.BOX, arch, Vector3(0.35, 4.2, 0.35), Vector3(28.2, 2.1, z))
		circles.append(Vector3(28.2, z, 0.3))
	Kit.part(st, Kit.BOX, arch, Vector3(0.3, 0.6, 6.8), Vector3(28.2, 4.2, 0))
	Chars.label(root, "ГК «ПЕСНЯ»", 90, Color(3.0, 2.2, 1.0), Vector3(28.0, 4.2, 0), Vector3(0, -PI / 2, 0), 0.0085, 10)
	Chars.ring(root, Vector3(26.6, 0.05, 0), 1.2, Color("55cdbe"), 0.08, 3.0)

	# a skyline of panel blocks far away
	var f1 := Kit.facade_material(Color("c8bba6"), 0.3, 41)
	var f2 := Kit.facade_material(Color("b5b9be"), 0.35, 42)
	for h in [[Vector3(10, 0, -46), Vector3(40, 18, 12), f1], [Vector3(14, 0, 46), Vector3(46, 15, 12), f2], [Vector3(60, 0, 0), Vector3(12, 22, 50), f2]]:
		Kit.part(st, Kit.BOX, h[2], h[1], h[0] + Vector3(0, h[1].y / 2, 0))
	for p in [Vector3(24, 0, -24), Vector3(-30, 0, 26), Vector3(30, 0, 24), Vector3(-10, 0, -26)]:
		Chars.tree(st, p, 1.3, Color("7a8a3a"))

	Kit.bake_static(st)
	# the blinking beacon stays a separate node (static geometry above is merged and freed)
	var beacon := Kit.part(root, Kit.SPH, Kit.neon(Color("ff1a2a"), 8.0), Vector3.ONE * 2.2, Vector3(-50, 73.5, 0))
	return {"root": root, "rects": rects, "circles": circles, "id": "stroyka", "name": "Стройка Глушилки", "bounds": BOUNDS,
		"map_rects": [Rect2(-16, -3, 44, 6), Rect2(-25, -9, 18, 18)],
		"spawns": {"from_garages": [Vector3(24.0, 0, 0), -PI / 2], "start": [Vector3(24.0, 0, 0), -PI / 2], "respawn": [Vector3(21, 0, 4), -PI / 2]},
		"portals": [{"pos": Vector3(26.6, 0, 0), "r": 1.3, "to": "garages", "spawn": "from_stroyka", "label": "ГК «Песня»"}],
		"npcs": [],
		"beacon": beacon,
		"mobs": [["drone", Vector3(15, 0, -4), 6], ["drone", Vector3(11, 0, 5), 6], ["drone", Vector3(6, 0, -5), 7], ["drone", Vector3(2, 0, 2), 7],
			["drone", Vector3(-1, 0, -8), 7], ["drone", Vector3(-4, 0, 7), 8], ["drone", Vector3(7, 0, 13), 7], ["drone", Vector3(1, 0, -14), 8],
			["drone", Vector3(-8, 0, -2), 8],
			["scooter", Vector3(18, 0, 5), 6], ["scooter", Vector3(10, 0, -14), 7], ["scooter", Vector3(-9, 0, 12), 7]]}
