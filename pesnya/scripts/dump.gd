class_name Dump
## 0.9 «Своё дело»: Помойка — городская свалка за промзоной. Горы хлама, кладбище холодильников, гора матрасов,
## лагерь изобретателей Деда Утиля и Кеши Вторсырьё с ветряком «вай-фай без пароля» и площадка пресса,
## куда приезжает мусоровоз Кощея — Король Хлама.

const BOUNDS := Rect2(-32.0, -26.0, 64.0, 50.0)
const KING_HOME := Vector3(14.0, 0, -12.0)
const ARENA_R := 10.5
const CAMP := Vector3(-12.0, 0, 2.0)
const IDEA_TABLE := Vector3(-8.0, 0, 1.2)
const PILE_TOP := Vector3(-2.0, 0, -19.0)


static func _fence(st: Node3D, a: Vector3, b: Vector3) -> void:
	var cols := [Color("8a929e"), Color("6a7a8a"), Color("9a8a6a"), Color("7a8a7a"), Color("a86a4a")]
	var d := b - a
	var n := int(d.length() / 2.4)
	var dir := d.normalized()
	for i in range(n):
		var p := a + dir * (i * 2.4 + 1.2)
		var sheet := Kit.part(st, Kit.BOX, Kit.mat(cols[(i * 7 + int(a.x)) % cols.size()], 0.7, 0.5), Vector3(2.5, 2.4 + (i % 3) * 0.2, 0.08), p + Vector3(0, 1.2, 0))
		sheet.rotation.y = atan2(dir.x, dir.z) + PI / 2
		sheet.rotation.z = sin(i * 1.7) * 0.03


static func build(parent: Node3D) -> Dictionary:
	var root := Node3D.new()
	root.name = "World"
	parent.add_child(root)
	var st := Node3D.new()
	st.name = "Static"
	root.add_child(st)
	var rects: Array = []
	var circles: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 909

	# ---------------- ground: packed dirt, a gravel road, the asphalt pad of the press
	Kit.part(st, Kit.BOX, Kit.mat(Color("6a5e4a"), 1.0), Vector3(220, 0.2, 220), Vector3(0, -0.12, 0))
	Kit.part(st, Kit.BOX, Kit.mat(Color("8a8070"), 0.95), Vector3(5.0, 0.1, 30), Vector3(0, -0.02, 9.0))
	Kit.part(st, Kit.BOX, Kit.mat(Color("8a8070"), 0.95), Vector3(4.0, 0.1, 15), Vector3(6.0, -0.02, -3.0), Vector3(0, -0.85, 0))
	Kit.part(st, Kit.CYL, Kit.mat(Color("4a4a50"), 0.9), Vector3(ARENA_R * 2.1, 0.1, ARENA_R * 2.1), KING_HOME + Vector3(0, -0.01, 0))
	Chars.ring(root, KING_HOME + Vector3(0, 0.06, 0), ARENA_R, Color("ff8a1a"), 0.12, 1.4)
	for p in [Vector3(4, 0, 6), Vector3(-6, 0, -6), Vector3(18, 0, 4), Vector3(-20, 0, 10)]:
		Kit.part(st, Kit.CYL, Kit.mat(Color("2a3448"), 0.05, 0.6), Vector3(2.6, 0.01, 1.6), p + Vector3(0, 0.04, 0))
	for k in range(60):
		var p := Vector3(rng.randf_range(-30, 30), 0.03, rng.randf_range(-24, 22))
		Kit.part(st, Kit.BOX, Kit.mat([Color("e8e0d0"), Color("c8323c"), Color("3a7ac8"), Color("f2c21a")][k % 4], 0.8), Vector3(0.3, 0.02, 0.2), p, Vector3(0, rng.randf() * 3, 0))

	# ---------------- the fence around the dump and the gate «ВСЁ ПРИГОДИТСЯ»
	_fence(st, Vector3(-32, 0, -26), Vector3(32, 0, -26))
	_fence(st, Vector3(-32, 0, -26), Vector3(-32, 0, 24))
	_fence(st, Vector3(32, 0, -26), Vector3(32, 0, 24))
	_fence(st, Vector3(-32, 0, 24), Vector3(-3.5, 0, 24))
	_fence(st, Vector3(3.5, 0, 24), Vector3(32, 0, 24))
	var post := Kit.mat(Color("5a6a7a"), 0.5, 0.6)
	for x in [-3.4, 3.4]:
		Kit.part(st, Kit.BOX, post, Vector3(0.4, 6.8, 0.4), Vector3(x, 3.4, 23.8))
		circles.append(Vector3(x, 23.8, 0.35))
	# the sign hangs high: the camera behind a hero who just came in passes under it
	Kit.part(st, Kit.BOX, Kit.mat(Color("2a3a2a"), 0.6), Vector3(7.2, 0.9, 0.12), Vector3(0, 6.6, 23.8))
	Chars.label(root, "ГОРОДСКАЯ СВАЛКА «ВСЁ ПРИГОДИТСЯ»", 70, Color(3.0, 2.6, 1.4), Vector3(0, 6.6, 23.72), Vector3(0, PI, 0), 0.0068, 8)
	Chars.ring(root, Vector3(0, 0.05, 22.6), 1.2, Color("55cdbe"), 0.08, 3.0)

	# ---------------- the inventors' camp
	Mobs09.shack(st, Vector3(-13.0, 0, -1.6), 0.0)
	rects.append(Rect2(-15.1, -3.2, 4.2, 2.4))
	var flame := Mobs09.bonfire(root, Vector3(-12.2, 0, 4.6))
	circles.append(Vector3(-12.2, 4.6, 0.8))
	Mobs09.sofa(st, Vector3(-17.4, 0, 3.4), PI / 2)
	rects.append(Rect2(-17.9, 2.2, 1.0, 2.4))
	var rotor := Mobs09.windmill(root, Vector3(-18.6, 0, -4.4))
	circles.append(Vector3(-18.6, -4.4, 0.8))
	Mobs09.old_tv(st, Vector3(-9.4, 0, -1.4), 0.3)
	circles.append(Vector3(-9.4, -1.4, 0.6))
	# Кеша's table «Лавка идей» under a light bulb
	var wood := Kit.mat(Color("a8743e"), 0.85)
	Kit.part(st, Kit.BOX, wood, Vector3(2.0, 0.1, 0.9), IDEA_TABLE + Vector3(0, 0.95, 0))
	for sx in [-0.9, 0.9]:
		Kit.part(st, Kit.BOX, wood, Vector3(0.1, 0.95, 0.8), IDEA_TABLE + Vector3(sx, 0.47, 0))
	for k in range(4):
		Kit.part(st, Kit.BOX, Kit.mat(Color("2a5ac8"), 0.6, 0.0, Color("4a8aff"), 0.4), Vector3(0.4, 0.02, 0.3), IDEA_TABLE + Vector3(-0.6 + k * 0.4, 1.02, sin(k) * 0.1), Vector3(0, k * 0.3, 0))
	Kit.part(st, Kit.CYL, Kit.mat(Color("2a2a30"), 0.4, 0.6), Vector3(0.05, 2.2, 0.05), IDEA_TABLE + Vector3(0.95, 1.1, -0.35))
	Kit.part(root, Kit.SPH, Kit.neon(Color("ffe8a0"), 4.0), Vector3(0.28, 0.34, 0.28), IDEA_TABLE + Vector3(0.6, 2.25, -0.35))
	Chars.label(root, "ЛАВКА ИДЕЙ", 70, Color(3.0, 2.6, 1.2), IDEA_TABLE + Vector3(0, 1.75, -0.5), Vector3.ZERO, 0.0062, 8)
	rects.append(Rect2(IDEA_TABLE.x - 1.05, IDEA_TABLE.z - 0.5, 2.1, 1.0))

	# ---------------- the junk mountain (Джек Скалолаз climbs it) and more piles making the paths
	Mobs09.junk_pile(st, PILE_TOP, 6.0, 11)
	circles.append(Vector3(PILE_TOP.x, PILE_TOP.z, 5.6))
	Kit.part(st, Kit.CYL, Kit.mat(Color("8a929e"), 0.3, 0.8), Vector3(0.08, 3.0, 0.08), PILE_TOP + Vector3(0.4, 4.6, 0))
	Kit.part(st, Kit.BOX, Kit.mat(Color("e8323c"), 0.7), Vector3(1.0, 0.6, 0.03), PILE_TOP + Vector3(0.92, 5.7, 0))
	Chars.label(root, "ГОРА ХЛАМА · ВЫСОТА 6 м", 50, Color("f4f4f4"), PILE_TOP + Vector3(0, 1.8, 6.0), Vector3.ZERO, 0.0055, 6)
	for e in [[Vector3(-26, 0, 20), 2.6, 2], [Vector3(-28, 0, -24), 3.0, 3], [Vector3(10, 0, -24), 2.6, 4], [Vector3(29, 0, -24), 2.8, 5],
			[Vector3(29, 0, 20), 2.4, 6], [Vector3(-8, 0, -10), 1.8, 7], [Vector3(6, 0, 20), 2.2, 8], [Vector3(-26, 0, 6), 2.2, 9]]:
		Mobs09.junk_pile(st, e[0], e[1], e[2])
		circles.append(Vector3(e[0].x, e[0].z, e[1] * 0.92))

	# ---------------- the fridge graveyard (west)
	for k in range(14):
		var p := Vector3(-27.5 + (k % 5) * 2.2 + rng.randf_range(-0.3, 0.3), 0, -7.0 - int(k / 5) * 4.6 + rng.randf_range(-0.4, 0.4))
		if p.distance_to(Vector3(-22.4, 0, -16.6)) < 2.4:
			continue
		Mobs09.fridge_decor(st, p, rng.randf_range(-0.6, 0.6), rng.randf_range(-0.12, 0.12))
		circles.append(Vector3(p.x, p.z, 0.75))
	Chars.label(root, "КЛАДБИЩЕ ХОЛОДИЛЬНИКОВ · ТИХО, ОНИ СПЯТ", 50, Color("cfe8ff"), Vector3(-22.0, 2.6, -4.6), Vector3.ZERO, 0.0055, 6)
	# Молодой Мельник's oak barrel
	var bar := Kit.mat(Color("8a5a2a"), 0.85)
	Kit.part(st, Kit.CYL, bar, Vector3(1.0, 1.3, 1.0), Vector3(-23.6, 0.65, -17.6))
	for y in [0.25, 1.05]:
		Kit.torus(st, Kit.mat(Color("3a3a42"), 0.4, 0.7), 0.04, 0.52, Vector3(-23.6, y, -17.6), Vector3.ZERO)
	circles.append(Vector3(-23.6, -17.6, 0.6))

	# ---------------- the mattress hill (east) and the crane with a magnet
	Mobs09.mattress_pile(st, Vector3(26.0, 0, 6.0))
	Mobs09.mattress_pile(st, Vector3(27.4, 0, 13.4))
	circles.append(Vector3(26.0, 6.0, 1.4))
	circles.append(Vector3(27.4, 13.4, 1.4))
	Mobs09.crane(st, Vector3(28.4, 0, -4.0))
	rects.append(Rect2(26.9, -5.8, 3.0, 3.6))

	# ---------------- rubbish containers (the rats live here) and the plane wreck
	Mobs09.container(st, Vector3(12.0, 0, 12.0), 0.3, Color("2a6ab8"))
	Mobs09.container(st, Vector3(16.0, 0, 16.2), -0.2, Color("3a8a4a"))
	Mobs09.container(st, Vector3(8.6, 0, 17.0), 0.1, Color("e8833a"))
	for p in [Vector3(12.0, 0, 12.0), Vector3(16.0, 0, 16.2), Vector3(8.6, 0, 17.0)]:
		circles.append(Vector3(p.x, p.z, 1.2))
	Mobs09.plane_wreck(st, Vector3(-25.0, 0, 14.0), 0.6)
	circles.append(Vector3(-25.0, 14.0, 1.4))
	circles.append(Vector3(-23.6, 15.9, 0.9))

	# ---------------- the press pad: junk walls around it with an opening to the road, the press station
	var road_a := atan2(-10.0, 9.0)   # the opening looks at the road from the camp
	for k in range(20):
		var a := k * TAU / 20.0
		if absf(wrapf(a - road_a, -PI, PI)) < 0.55:
			continue
		var p := KING_HOME + Vector3(sin(a) * (ARENA_R + 2.4), 0, cos(a) * (ARENA_R + 2.4))
		if p.x > 30.5 or p.z < -25.0 or p.distance_to(KING_HOME + Vector3(7.6, 0, -9.0)) < 4.0:
			continue
		Mobs09.junk_pile(st, p, 1.6, 40 + k)
		circles.append(Vector3(p.x, p.z, 1.45))
	var press := Node3D.new()
	press.position = KING_HOME + Vector3(7.6, 0, -9.0)
	press.rotation.y = -0.7
	st.add_child(press)
	Kit.part(press, Kit.BOX, Kit.mat(Color("3a4a3a"), 0.6, 0.4), Vector3(5.0, 3.6, 3.0), Vector3(0, 1.8, 0))
	Kit.part(press, Kit.BOX, Kit.mat(Color("f2b21c"), 0.5, 0.4), Vector3(5.2, 0.3, 3.2), Vector3(0, 3.0, 0))
	Chars.label(press, "ПРЕСС-СТАНЦИЯ «ТИШИНА ПЛЮС»", 60, Color("f4f4f4"), Vector3(0, 2.2, 1.53), Vector3.ZERO, 0.006, 6)
	circles.append(Vector3(press.position.x, press.position.z, 2.6))
	Chars.label(root, "ПЛОЩАДКА ПРЕССА · ВЪЕЗД МУСОРОВОЗАМ", 56, Color("ffd8a0"), KING_HOME + Vector3(-8.6, 2.4, 7.4), Vector3(0, atan2(-10.0, 9.0), 0), 0.006, 6)

	# ---------------- lamps, skyline, smoke stacks of the industrial zone
	for p in [Vector3(-3.0, 0, 4.0), Vector3(4.0, 0, 14.0), Vector3(-16.0, 0, 12.0), Vector3(20.0, 0, 2.0)]:
		Kit.part(st, Kit.CYL, Kit.mat(Color("2a2a32"), 0.4, 0.6), Vector3(0.16, 5, 0.16), p + Vector3(0, 2.5, 0))
		Kit.part(st, Kit.BOX, Kit.neon(Color("ffe2b0"), 2.0), Vector3(0.5, 0.06, 0.3), p + Vector3(0, 5.0, 0.3))
		circles.append(Vector3(p.x, p.z, 0.25))
	var f1 := Kit.facade_material(Color("b8a890"), 0.25, 51)
	for h in [[Vector3(-10, 0, -50), Vector3(44, 16, 12), f1], [Vector3(50, 0, -10), Vector3(12, 20, 44), f1], [Vector3(-50, 0, 0), Vector3(12, 14, 40), f1]]:
		Kit.part(st, Kit.BOX, h[2], h[1], h[0] + Vector3(0, h[1].y / 2, 0))
	for p in [Vector3(30, 0, -44), Vector3(40, 0, -36)]:
		Kit.part(st, Kit.CYL, Kit.mat(Color("8a7a6a"), 0.9), Vector3(2.4, 28, 2.4), p + Vector3(0, 14, 0))
		Kit.part(st, Kit.CYL, Kit.mat(Color("c8323c"), 0.8), Vector3(2.5, 1.2, 2.5), p + Vector3(0, 25, 0))
	for p in [Vector3(-30, 0, 30), Vector3(24, 0, 32), Vector3(-36, 0, -10)]:
		Chars.tree(st, p, 1.2, Color("6a7a3a"))

	Kit.bake_static(st)
	return {"root": root, "rects": rects, "circles": circles, "id": "dump", "name": "Помойка", "bounds": BOUNDS,
		"map_rects": [Rect2(-32, -26, 64, 50)],
		"rotor": rotor, "flame": flame,
		"spawns": {"from_stroyka": [Vector3(0, 0, 18.6), PI], "start": [Vector3(0, 0, 18.6), PI], "respawn": [Vector3(3.0, 0, 17.0), PI]},
		"portals": [{"pos": Vector3(0, 0, 22.6), "r": 1.3, "to": "stroyka", "spawn": "from_dump", "label": "Стройка Глушилки"}],
		"npcs": [],
		"mobs": [["rat", Vector3(11.0, 0, 8.6), 17], ["rat", Vector3(16.6, 0, 12.0), 18], ["rat", Vector3(13.0, 0, 19.4), 18], ["rat", Vector3(6.6, 0, 12.6), 17],
			["rat", Vector3(19.4, 0, 18.4), 19], ["rat", Vector3(-20.0, 0, -13.6), 19],
			["fridge", Vector3(-25.0, 0, -9.4), 19], ["fridge", Vector3(-20.6, 0, -12.0), 19], ["fridge", Vector3(-26.4, 0, -14.2), 20],
			["fridge", Vector3(-18.4, 0, -7.6), 20], ["fridge", Vector3(-24.0, 0, -20.6), 21], ["fridge", Vector3(-16.4, 0, -17.6), 21], ["fridge", Vector3(-28.0, 0, -2.0), 20],
			["mattress", Vector3(22.6, 0, 4.0), 18], ["mattress", Vector3(23.0, 0, 9.6), 19], ["mattress", Vector3(28.6, 0, 9.0), 19],
			["mattress", Vector3(24.0, 0, 17.0), 20], ["mattress", Vector3(21.0, 0, 13.4), 20],
			["bag", Vector3(2.0, 0, -8.0), 18], ["bag", Vector3(-5.0, 0, -4.0), 18], ["bag", Vector3(-14.0, 0, -11.6), 19], ["bag", Vector3(4.0, 0, 3.0), 18],
			["gull", Vector3(6.0, 0, 8.0), 17], ["gull", Vector3(-6.0, 0, 10.0), 17], ["gull", Vector3(-22.0, 0, 18.0), 18]]}
