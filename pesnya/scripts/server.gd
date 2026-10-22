class_name ServerRoom
## Серверная Кощея (0.4): the top floor of the silence tower. A soft padded corridor, a door that opens only to rhymes on the beat,
## and the server hall with the iron oak where Koschei keeps his immortality on a flash drive.

const BOUNDS := Rect2(-30.0, -16.0, 64.0, 32.0)
const DOOR_X := 6.0
const OAK := Vector3(-14.0, 0, 0)
const CHEST := Vector3(-14.0, 0, 2.9)
const BOSS_SPOT := Vector3(-20.0, 0, 0)


static func _rack(st: Node3D, p: Vector3, rot: float) -> void:
	var r := Node3D.new()
	r.position = p
	r.rotation.y = rot
	st.add_child(r)
	Kit.part(r, Kit.BOX, Kit.mat(Color("2c313c"), 0.5, 0.2), Vector3(2.6, 3.4, 1.2), Vector3(0, 1.7, 0))
	Kit.part(r, Kit.BOX, Kit.mat(Color("3e4552"), 0.5, 0.2), Vector3(2.4, 3.2, 0.05), Vector3(0, 1.7, 0.6))
	for k in range(7):
		var y := 0.45 + k * 0.42
		Kit.part(r, Kit.BOX, Kit.mat(Color("3a404c"), 0.5, 0.5), Vector3(2.2, 0.05, 0.04), Vector3(0, y + 0.18, 0.62))
		var c := Color("4ad8ff") if (k + int(p.x)) % 3 else Color("4aff8a")
		Kit.part(r, Kit.BOX, Kit.neon(c, 3.0), Vector3(0.06, 0.06, 0.03), Vector3(-0.9 + (k % 3) * 0.12, y, 0.64))
		Kit.part(r, Kit.BOX, Kit.neon(Color("4ad8ff"), 2.0), Vector3(0.5, 0.03, 0.03), Vector3(0.6, y, 0.64))


static func build(parent: Node3D) -> Dictionary:
	var root := Node3D.new()
	root.name = "World"
	parent.add_child(root)
	var st := Node3D.new()
	st.name = "Static"
	root.add_child(st)
	var rects: Array = []
	var circles: Array = []

	# ---------------- soft corridor (x 6..34)
	var foam := Kit.tile_material(Color("b9bdc6"), Color("9ea3ad"))
	var carpet := Kit.mat(Color("8e929c"), 1.0)
	Kit.part(st, Kit.BOX, carpet, Vector3(30, 0.2, 6.4), Vector3(20, -0.1, 0))
	# 0.8: the walls start exactly at the hall wall (no stub to walk into), cushions keep clear of the posters
	var posters := [["ТИШИНА — ЭТО ПРОДУКТ", 12.0, -1], ["ГОВОРИ ШЁПОТОМ", 18.0, 1], ["999 ₽ В МЕСЯЦ. ВЕЧНО.", 24.0, -1],
		["ПАРОЛЬ: ТИШИНА123", 28.0, 1], ["СПАСИБО ЗА ТИШИНУ", 10.0, 1]]
	for z in [-3.4, 3.4]:
		Kit.part(st, Kit.BOX, foam, Vector3(29, 5.2, 0.6), Vector3(20.5, 2.6, z))
		# soft cushions on the walls, flat against them, never in front of a poster
		for k in range(12):
			var cx := 9.0 + k * 2.2
			var cy := 1.5 + (k % 2) * 1.2
			var blocked := false
			for pz in posters:
				if signf(z) == float(pz[2]) and absf(cx - float(pz[1])) < 2.9 and cy > 1.9:
					blocked = true
			if blocked:
				cy = 1.3
			Kit.part(st, Kit.SPH, Kit.mat(Color("d6d9de"), 0.95), Vector3(1.8, 1.2, 0.22), Vector3(cx, cy, z * 0.9))
	rects.append(Rect2(DOOR_X, -16, 30, 13.2))
	rects.append(Rect2(DOOR_X, 2.8, 30, 13.2))
	for pz in posters:
		var zz: float = 2.86 * pz[2]
		Kit.part(st, Kit.BOX, Kit.mat(Color("f4f4f4"), 0.8), Vector3(3.6, 1.0, 0.05), Vector3(pz[1], 3.5, zz))
		Chars.label(root, pz[0], 60, Color("3a3e48"), Vector3(pz[1], 3.5, zz - 0.04 * pz[2]), Vector3(0, 0 if pz[2] < 0 else PI, 0), 0.0065, 0)
	# lift at the east end
	Kit.part(st, Kit.BOX, Kit.mat(Color("a8b0bc"), 0.25, 0.9), Vector3(0.3, 4.0, 3.2), Vector3(34.0, 2.0, 0))
	Kit.part(st, Kit.BOX, Kit.mat(Color("6a7280"), 0.3, 0.8), Vector3(0.32, 4.0, 0.08), Vector3(34.0, 2.0, 0))
	Chars.label(root, "ЛИФТ · ШУМОДАВ", 60, Color(2.6, 2.2, 1.4), Vector3(33.8, 4.4, 0), Vector3(0, -PI / 2, 0), 0.007, 6)
	Chars.ring(root, Vector3(32.4, 0.05, 0), 1.2, Color("55cdbe"), 0.08, 3.0)

	# ---------------- server hall (x -30..6)
	Kit.part(st, Kit.BOX, Kit.mat(Color("1e222c"), 0.45, 0.15), Vector3(40, 0.2, 34), Vector3(-12, -0.1, 0))
	for k in range(9):
		Kit.part(st, Kit.BOX, Kit.neon(Color("2a6aff"), 1.2), Vector3(0.05, 0.02, 32), Vector3(-28 + k * 4.0, 0.01, 0))
	for k in range(9):
		Kit.part(st, Kit.BOX, Kit.neon(Color("2a6aff"), 1.2), Vector3(36, 0.02, 0.05), Vector3(-12, 0.012, -16 + k * 4.0))
	# walls of the hall
	var wall := Kit.mat(Color("2e333e"), 0.6, 0.1)
	Kit.part(st, Kit.BOX, wall, Vector3(0.6, 7, 34), Vector3(-30.4, 3.5, 0))
	Kit.part(st, Kit.BOX, wall, Vector3(37, 7, 0.6), Vector3(-12, 3.5, -16.4))
	Kit.part(st, Kit.BOX, wall, Vector3(37, 7, 0.6), Vector3(-12, 3.5, 16.4))
	for z in [-9.7, 9.7]:
		Kit.part(st, Kit.BOX, wall, Vector3(0.6, 7, 12.6), Vector3(6.3, 3.5, z))
	# a huge screen on the west wall
	Kit.part(st, Kit.BOX, Kit.mat(Color("0c1018"), 0.1, 0.4), Vector3(0.2, 4.2, 10), Vector3(-30.0, 3.6, 0))
	Chars.label(root, "КОЩЕЙТЕХ · СЕРВЕРНАЯ", 110, Color(1.6, 2.4, 3.0), Vector3(-29.85, 4.6, 0), Vector3(0, PI / 2, 0), 0.008, 0)
	Chars.label(root, "БЕССМЕРТИЕ: ОБЛАЧНОЕ ХРАНИЛИЩЕ", 70, Color(1.2, 1.8, 2.2), Vector3(-29.85, 3.4, 0), Vector3(0, PI / 2, 0), 0.007, 0)
	Chars.label(root, "БЭКАП: НЕ НУЖЕН (Я БЕССМЕРТНЫЙ)", 60, Color(1.0, 1.4, 1.8), Vector3(-29.85, 2.5, 0), Vector3(0, PI / 2, 0), 0.0065, 0)
	# rows of server racks
	for z in [-12.5, 12.5]:
		for k in range(8):
			_rack(st, Vector3(-27 + k * 3.0, 0, z), 0.0 if z < 0 else PI)
		rects.append(Rect2(-28.5, z - 0.8, 24.2, 1.6))
	for z in [-7.0, 7.0]:
		for k in range(3):
			_rack(st, Vector3(-27 + k * 3.0, 0, z), 0.0 if z < 0 else PI)
			_rack(st, Vector3(-4 + k * 3.0 - 3.0, 0, z), 0.0 if z < 0 else PI)
		rects.append(Rect2(-28.5, z - 0.8, 9.2, 1.6))
		rects.append(Rect2(-8.5, z - 0.8, 9.2, 1.6))
	# cable trays on the floor
	for k in range(3):
		Kit.part(st, Kit.BOX, Kit.mat(Color("2a2e38"), 0.5, 0.6), Vector3(0.6, 0.12, 14), Vector3(-24 + k * 8, 0.06, 0))

	# ---------------- the iron oak: a server rack grown into a tree
	var steel := Kit.mat(Color("a2aab8"), 0.45, 0.3)
	var steel2 := Kit.mat(Color("848c9a"), 0.5, 0.3)
	Kit.part(st, Kit.CYL, steel, Vector3(2.4, 9, 2.4), OAK + Vector3(0, 4.5, 0))
	for a in range(6):
		var ang := a * TAU / 6.0
		Kit.part(st, Kit.CYL, steel2, Vector3(0.5, 3.2, 0.5), OAK + Vector3(cos(ang) * 1.6, 0.5, sin(ang) * 1.6), Vector3(sin(ang) * 1.1, 0, -cos(ang) * 1.1))
	var branches := [[Vector3(3.0, 7.5, 1.0), 0.9], [Vector3(-3.2, 8.0, -0.6), 0.85], [Vector3(0.6, 8.6, 3.2), 0.8], [Vector3(-0.8, 8.4, -3.0), 0.8],
		[Vector3(2.2, 9.6, -2.0), 0.7], [Vector3(-2.4, 9.8, 2.0), 0.7]]
	var leaf_cols := [Color("2ee88a"), Color("4ad8ff"), Color("55cdbe")]
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	for b in branches:
		var tip: Vector3 = OAK + b[0]
		var base: Vector3 = OAK + Vector3(0, b[0].y - 2.4, 0)
		var mid := (tip + base) * 0.5
		var d := tip - base
		var br := Kit.part(st, Kit.CYL, steel2, Vector3(b[1] * 0.6, d.length(), b[1] * 0.6), mid)
		br.look_at_from_position(mid, tip, Vector3.UP if absf(d.normalized().dot(Vector3.UP)) < 0.95 else Vector3.RIGHT)
		br.rotate_object_local(Vector3.RIGHT, PI / 2)
		for k in range(9):
			var lp := tip + Vector3(rng.randf_range(-1.3, 1.3), rng.randf_range(-0.6, 0.9), rng.randf_range(-1.3, 1.3))
			Kit.part(st, Kit.SPH, Kit.neon(leaf_cols[k % 3], 2.6), Vector3.ONE * rng.randf_range(0.18, 0.32), lp)
	# hanging cables like vines
	for k in range(8):
		var ang2 := k * TAU / 8.0
		Kit.part(st, Kit.CYL, Kit.mat(Color("1a1a1e"), 0.6), Vector3(0.06, 4.0, 0.06), OAK + Vector3(cos(ang2) * 2.6, 6.0, sin(ang2) * 2.6))
	circles.append(Vector3(OAK.x, OAK.z, 1.6))
	Chars.ring(root, OAK + Vector3(0, 0.03, 0), 3.2, Kit.TEAL, 0.06, 1.6)

	Kit.bake_static(st)

	# ---------------- dynamic parts: the rap-code door and the chest on the oak
	var door := Node3D.new()
	door.position = Vector3(DOOR_X, 0, 0)
	root.add_child(door)
	Kit.part(door, Kit.CYL, Kit.mat(Color("8a92a2"), 0.3, 0.9), Vector3(5.6, 0.5, 5.6), Vector3(0, 2.8, 0), Vector3(0, 0, PI / 2))
	for k in range(4):
		Kit.torus(door, Kit.mat(Color("2a2e38"), 0.4, 0.7), 0.5 + k * 0.5, 0.58 + k * 0.5, Vector3(0.28, 2.8, 0), Vector3(0, 0, PI / 2))
	Kit.part(door, Kit.CYL, Kit.neon(Color("ff3a4a"), 3.0), Vector3(0.6, 0.05, 0.6), Vector3(0.3, 2.8, 0), Vector3(0, 0, PI / 2))
	Chars.label(door, "ВХОД ТОЛЬКО ПО РИФМЕ", 56, Color(3.0, 1.6, 1.4), Vector3(0.6, 5.9, 0), Vector3(0, PI / 2, 0), 0.0065, 6)
	Kit.bake_tree(door)
	var lamp := Kit.part(door, Kit.SPH, Kit.neon(Color("ff3a4a"), 4.0), Vector3.ONE * 0.35, Vector3(0.4, 5.3, 0))
	var chest := Node3D.new()
	chest.position = OAK + Vector3(0.0, 6.6, 2.9)
	root.add_child(chest)
	Kit.part(chest, Kit.BOX, Kit.mat(Color("8a5a2a"), 0.7), Vector3(1.2, 0.8, 0.8), Vector3(0, 0, 0))
	Kit.part(chest, Kit.BOX, Kit.mat(Color("e8b84a"), 0.3, 0.8), Vector3(1.25, 0.12, 0.85), Vector3(0, 0.35, 0))
	Kit.part(chest, Kit.BOX, Kit.mat(Color("e8b84a"), 0.3, 0.8), Vector3(0.2, 0.25, 0.05), Vector3(0, 0.05, 0.42))
	for s in [-0.4, 0.4]:
		Kit.part(chest, Kit.CYL, Kit.mat(Color("3a3a40"), 0.4, 0.8), Vector3(0.04, 2.0, 0.04), Vector3(s, 1.4, 0))
	Kit.bake_tree(chest)
	# lights
	var lights := []
	for l in [[OAK + Vector3(0, 6, 0), Kit.TEAL, 3.0, 16.0], [Vector3(20, 4.2, 0), Color("fff4e8"), 1.0, 18.0], [Vector3(-4, 4, 0), Color("6a8aff"), 1.8, 14.0]]:
		var o := OmniLight3D.new()
		o.position = l[0]
		o.light_color = l[1]
		o.light_energy = l[2]
		o.omni_range = l[3]
		root.add_child(o)
		lights.append(o)
	var door_rect := Rect2(DOOR_X - 0.4, -3.4, 0.8, 6.8)
	rects.append(door_rect)
	return {"root": root, "rects": rects, "circles": circles, "id": "server", "name": "Серверная Кощея", "bounds": BOUNDS,
		"map_rects": [Rect2(6, -3, 28, 6), Rect2(-30, -16, 36, 32)],
		"spawns": {"from_stroyka": [Vector3(30.0, 0, 0), -PI / 2], "start": [Vector3(30.0, 0, 0), -PI / 2], "respawn": [Vector3(27, 0, 0), -PI / 2]},
		"portals": [{"pos": Vector3(32.4, 0, 0), "r": 1.3, "to": "stroyka", "spawn": "from_server", "label": "Лифт вниз"}],
		"npcs": [], "door": door, "door_rect": door_rect, "door_lamp": lamp, "chest": chest,
		"mobs": [["hare", Vector3(-2, 0, -3), 9], ["hare", Vector3(-4, 0, 4), 9], ["hare", Vector3(-8, 0, -10), 10], ["hare", Vector3(-20, 0, -9.5), 10],
			["hare", Vector3(-22, 0, 9.5), 10], ["hare", Vector3(-8, 0, 10), 9], ["hare", Vector3(0, 0, 10), 9], ["hare", Vector3(-26, 0, 0), 10],
			["drone", Vector3(-10, 0, -4), 9], ["drone", Vector3(-20, 0, 4), 10]]}
