class_name Cheb
## 0.8 «Мыльная опера»: Чебуречная «Сочная» у трамвайной остановки — липкие столики, лучшие чебуреки района,
## санузел-лабиринт, который «не работает с 2009 года», и двор за кухней, где из трубы лезет Тесто Вечности.

const BOUNDS := Rect2(-30.0, -24.0, 60.0, 48.0)
const DOUGH_HOME := Vector3(-22.0, 0, -12.0)
const LOUPE := Vector3(6.0, 0, -3.2)       # «Звезда сериала»: the magnifier by the till
const TABLES := [Vector3(-9.5, 0, -1.0), Vector3(-6.5, 0, 2.0), Vector3(-2.5, 0, 1.0), Vector3(3.0, 0, 2.2), Vector3(7.2, 0, 1.8), Vector3(9.2, 0, -2.0)]


static func _table(st: Node3D, at: Vector3, rng: RandomNumberGenerator) -> void:
	var dark := Kit.mat(Color("3a3e48"), 0.5, 0.6)
	Kit.part(st, Kit.CYL, dark, Vector3(0.12, 1.0, 0.12), at + Vector3(0, 0.5, 0))
	Kit.part(st, Kit.CYL, dark, Vector3(0.7, 0.06, 0.7), at + Vector3(0, 0.03, 0))
	Kit.part(st, Kit.CYL, Kit.mat(Color("c8b89a"), 0.35), Vector3(1.2, 0.06, 1.2), at + Vector3(0, 1.0, 0))
	# sticky spots, a napkin holder and ketchup
	Kit.part(st, Kit.CYL, Kit.mat(Color("a89070"), 0.2), Vector3(0.3, 0.005, 0.24), at + Vector3(rng.randf_range(-0.3, 0.3), 1.035, rng.randf_range(-0.3, 0.3)))
	Kit.part(st, Kit.BOX, Kit.mat(Color("c8ccd4"), 0.3, 0.8), Vector3(0.16, 0.14, 0.08), at + Vector3(0.25, 1.1, -0.2))
	Kit.part(st, Kit.CYL, Kit.mat(Color("d8322c"), 0.4), Vector3(0.08, 0.22, 0.08), at + Vector3(-0.25, 1.14, -0.15))


static func _pipe(st: Node3D, a: Vector3, b: Vector3, r: float, m: Material) -> void:
	var mid := (a + b) * 0.5
	var d := b - a
	var p := Kit.part(st, Kit.CYL, m, Vector3(r * 2.0, d.length(), r * 2.0), mid)
	if absf(d.normalized().dot(Vector3.UP)) < 0.95:
		p.look_at_from_position(mid, b, Vector3.UP)
		p.rotate_object_local(Vector3.RIGHT, PI / 2)


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
	rng.seed = 808

	# ---------------- ground: the street, tiles inside, concrete behind
	Kit.part(st, Kit.BOX, Kit.mat(Color("5c7a42"), 1.0), Vector3(200, 0.2, 200), Vector3(0, -0.14, 0))
	Kit.part(st, Kit.BOX, Kit.mat(Color("55565e"), 0.95), Vector3(64, 0.1, 18), Vector3(0, -0.03, 15.5))
	Kit.part(st, Kit.BOX, Kit.tile_material(Color("d8c8a8"), Color("b8a888")), Vector3(28, 0.1, 12.6), Vector3(0, -0.02, -0.3))
	Kit.part(st, Kit.BOX, Kit.mat(Color("8a8a86"), 0.95), Vector3(44, 0.1, 18), Vector3(-8, -0.035, -15))
	Kit.part(st, Kit.BOX, Kit.tile_material(Color("b8d8e8"), Color("8aa8c0")), Vector3(16, 0.1, 30), Vector3(22, -0.02, -9))
	# tram rails and the stop
	for z in [19.4, 20.9]:
		Kit.part(st, Kit.BOX, Kit.mat(Color("b8bcc4"), 0.3, 0.9), Vector3(64, 0.08, 0.1), Vector3(0, 0.04, z))
	for x in range(-30, 31, 2):
		Kit.part(st, Kit.BOX, Kit.mat(Color("4a3a2a"), 0.9), Vector3(0.3, 0.04, 2.2), Vector3(x, 0.01, 20.15))
	var stop := Node3D.new()
	stop.position = Vector3(-12.0, 0, 17.4)
	st.add_child(stop)
	for x in [-1.8, 1.8]:
		Kit.part(stop, Kit.CYL, Kit.mat(Color("2a2a32"), 0.4, 0.6), Vector3(0.12, 2.8, 0.12), Vector3(x, 1.4, 0.6))
	Kit.part(stop, Kit.BOX, Kit.mat(Color("2a5a8a"), 0.5), Vector3(4.2, 0.12, 1.8), Vector3(0, 2.85, 0))
	Kit.part(stop, Kit.BOX, Kit.mat(Color("a8d8ff"), 0.1, 0.2), Vector3(4.0, 2.0, 0.05), Vector3(0, 1.5, -0.7))
	Kit.part(stop, Kit.BOX, Kit.mat(Color("8a6a4a"), 0.8), Vector3(3.0, 0.1, 0.5), Vector3(0, 0.5, -0.3))
	Chars.label(root, "ОСТАНОВКА «ЧЕБУРЕЧНАЯ» · ТРАМВАЙ №9", 52, Color(2.6, 2.6, 2.6), Vector3(-12.0, 3.25, 17.4), Vector3.ZERO, 0.0062, 6)
	rects.append(Rect2(-14.0, 16.4, 4.0, 1.0))
	# a red-and-yellow tram waiting at the stop
	var tram := Node3D.new()
	tram.position = Vector3(16.0, 0, 20.15)
	st.add_child(tram)
	Kit.part(tram, Kit.BOX, Kit.mat(Color("d8322c"), 0.5), Vector3(14, 1.4, 2.6), Vector3(0, 1.0, 0))
	Kit.part(tram, Kit.BOX, Kit.mat(Color("f2c21a"), 0.5), Vector3(14, 1.2, 2.6), Vector3(0, 2.3, 0))
	Kit.part(tram, Kit.BOX, Kit.mat(Color("1a2a3a"), 0.1, 0.3), Vector3(13, 0.8, 2.62), Vector3(0, 2.3, 0))
	Kit.part(tram, Kit.BOX, Kit.mat(Color("eeeeee"), 0.6), Vector3(14, 0.3, 2.4), Vector3(0, 3.05, 0))
	Kit.part(tram, Kit.CYL, Kit.mat(Color("2a2a32"), 0.4, 0.6), Vector3(0.08, 1.6, 0.08), Vector3(0, 3.9, 0), Vector3(0, 0, 0.6))
	Chars.label(root, "9 · ЧЕБУРЕЧНАЯ — ДВОР «БЕРЁЗКИ»", 56, Color(3.0, 2.6, 1.4), Vector3(9.2, 3.05, 20.15), Vector3(0, -PI / 2, 0), 0.0062, 6)
	rects.append(Rect2(9.0, 18.85, 14.0, 2.6))
	Chars.ring(root, Vector3(0, 0.05, 22.6), 1.2, Color("55cdbe"), 0.08, 3.0)

	# ---------------- the building: open front, awning, the big sign
	var wall := Kit.mat(Color("e8d8b8"), 0.85)
	var trim := Kit.mat(Color("8a4a2a"), 0.7)
	Kit.part(st, Kit.BOX, wall, Vector3(28.6, 4.5, 0.6), Vector3(0, 2.25, -6.3))
	Kit.part(st, Kit.BOX, wall, Vector3(0.6, 4.5, 12.6), Vector3(-14.0, 2.25, -0.3))
	Kit.part(st, Kit.BOX, wall, Vector3(0.6, 4.5, 3.0), Vector3(14.0, 2.25, -5.1))
	Kit.part(st, Kit.BOX, wall, Vector3(0.6, 4.5, 6.4), Vector3(14.0, 2.25, 2.8))
	Kit.part(st, Kit.BOX, wall, Vector3(0.6, 0.9, 3.2), Vector3(14.0, 4.05, -2.0))
	Kit.part(st, Kit.BOX, trim, Vector3(29.0, 0.3, 13.0), Vector3(0, 4.6, -0.3))
	rects.append(Rect2(-14.3, -6.6, 28.6, 0.6))
	rects.append(Rect2(-14.3, -6.6, 0.6, 12.6))
	rects.append(Rect2(13.7, -6.6, 0.6, 3.0))
	rects.append(Rect2(13.7, -0.4, 0.6, 6.4))
	for x in [-13.6, -7.0, 7.0, 13.6]:
		Kit.part(st, Kit.CYL, trim, Vector3(0.36, 4.5, 0.36), Vector3(x, 2.25, 6.0))
		circles.append(Vector3(x, 6.0, 0.3))
	for k in range(14):
		var c := Color("d8322c") if k % 2 == 0 else Color("f4f0e6")
		Kit.part(st, Kit.BOX, Kit.mat(c, 0.8), Vector3(2.0, 0.06, 2.0), Vector3(-13.0 + k * 2.0, 4.2, 6.9), Vector3(0.45, 0, 0))
	Kit.part(st, Kit.BOX, Kit.mat(Color("2a1a14"), 0.5), Vector3(16.0, 1.5, 0.3), Vector3(0, 5.6, 6.2))
	Chars.label(root, "ЧЕБУРЕЧНАЯ «СОЧНАЯ»", 150, Color(3.6, 2.4, 1.0), Vector3(0, 5.75, 6.4), Vector3.ZERO, 0.0092, 10)
	Chars.label(root, "чебуреки · пельмени · сок · с 1987 года", 60, Color(2.4, 2.2, 1.8), Vector3(0, 5.1, 6.4), Vector3.ZERO, 0.0066, 6)

	# the counter, the kitchen and the menu board
	var wood := Kit.mat(Color("8a5a32"), 0.7)
	Kit.part(st, Kit.BOX, wood, Vector3(12.0, 1.1, 0.9), Vector3(0, 0.55, -4.0))
	Kit.part(st, Kit.BOX, Kit.mat(Color("c8c0b0"), 0.3), Vector3(12.2, 0.08, 1.0), Vector3(0, 1.14, -4.0))
	rects.append(Rect2(-6.0, -4.45, 12.0, 0.9))
	Kit.part(st, Kit.BOX, Kit.mat(Color("3a3e48"), 0.4, 0.5), Vector3(0.7, 0.5, 0.5), LOUPE + Vector3(0.9, 1.4, -0.75))
	Kit.part(st, Kit.BOX, Kit.neon(Color("4aff8a"), 1.4), Vector3(0.5, 0.16, 0.02), LOUPE + Vector3(0.9, 1.55, -0.49))
	for k in range(5):
		var p := Vector3(-4.6 + k * 2.0, 1.22, -4.0)
		Kit.part(st, Kit.CYL, Kit.mat(Color("f8f8f8"), 0.3), Vector3(0.7, 0.04, 0.7), p)
		Kit.part(st, Kit.SPH, Kit.mat(Color("e8b45a"), 0.5), Vector3(0.6, 0.12, 0.34), p + Vector3(0, 0.08, 0))
	Kit.part(st, Kit.BOX, Kit.mat(Color("3a3e48"), 0.4, 0.6), Vector3(2.4, 1.0, 1.0), Vector3(-4.0, 0.5, -5.5))
	for x in [-4.6, -3.4]:
		Kit.part(st, Kit.CYL, Kit.neon(Color("ff6a2a"), 2.0), Vector3(0.5, 0.03, 0.5), Vector3(x, 1.02, -5.5))
	Kit.part(st, Kit.CYL, Kit.mat(Color("8a92a2"), 0.3, 0.8), Vector3(1.4, 1.1, 1.4), Vector3(4.0, 0.55, -5.4))
	Kit.part(st, Kit.CYL, Kit.mat(Color("e8b030"), 0.1, 0.0, Color("ffaa22"), 0.5), Vector3(1.2, 0.04, 1.2), Vector3(4.0, 1.1, -5.4))
	Kit.part(st, Kit.BOX, Kit.mat(Color("1a1a1e"), 0.6), Vector3(7.0, 1.8, 0.08), Vector3(0, 3.0, -5.96))
	Chars.label(root, "МЕНЮ", 90, Color(3.0, 2.8, 2.4), Vector3(0, 3.55, -5.9), Vector3.ZERO, 0.0075, 4)
	Chars.label(root, "ЧЕБУРЕК — 30 · ПЕЛЬМЕНИ — 50 · СОК — 20", 56, Color(2.6, 2.6, 2.6), Vector3(0, 3.0, -5.9), Vector3.ZERO, 0.0062, 4)
	Chars.label(root, "СМЕТАНА — ЗА УВАЖЕНИЕ", 56, Color(3.0, 2.2, 1.4), Vector3(0, 2.5, -5.9), Vector3.ZERO, 0.0062, 4)
	for t in TABLES:
		_table(st, t, rng)
		circles.append(Vector3(t.x, t.z, 0.6))
	# the toilet door with the famous sign
	Kit.part(st, Kit.BOX, Kit.mat(Color("6a8aa8"), 0.5), Vector3(0.08, 3.0, 3.0), Vector3(14.32, 1.5, -2.0), Vector3(0, -0.9, 0))
	Chars.label(root, "САНУЗЕЛ · НЕ РАБОТАЕТ С 2009", 56, Color(2.8, 1.4, 1.2), Vector3(13.6, 3.45, -2.0), Vector3(0, -PI / 2, 0), 0.0062, 6)
	Chars.label(root, "НЕ РАБОТАЕТ С 2009", 56, Color(2.8, 1.4, 1.2), Vector3(14.4, 3.45, -2.0), Vector3(0, PI / 2, 0), 0.0062, 6)

	# ---------------- the toilets: a maze of pipes (x 14..30)
	var tile_w := Kit.tile_material(Color("dfe8ee"), Color("b8c8d4"))
	var pipe_m := Kit.mat(Color("8a92a2"), 0.35, 0.8)
	var rust := Kit.mat(Color("a85a2a"), 0.7, 0.4)
	Kit.part(st, Kit.BOX, tile_w, Vector3(0.6, 4.5, 17.4), Vector3(14.0, 2.25, -15.3))
	rects.append(Rect2(13.7, -24.0, 0.6, 17.4))
	Kit.part(st, Kit.BOX, tile_w, Vector3(16.0, 3.0, 0.6), Vector3(22.0, 1.5, 6.0))
	rects.append(Rect2(14.0, 5.7, 16.0, 0.6))
	for wdef in [[Vector3(19.5, 0, -6.0), 11.0], [Vector3(24.5, 0, -13.0), 11.0], [Vector3(19.5, 0, -18.5), 11.0]]:
		var c0: Vector3 = wdef[0]
		var ln: float = wdef[1]
		Kit.part(st, Kit.BOX, tile_w, Vector3(ln, 2.4, 0.6), c0 + Vector3(0, 1.2, 0))
		rects.append(Rect2(c0.x - ln / 2.0, c0.z - 0.3, ln, 0.6))
		_pipe(st, c0 + Vector3(-ln / 2.0, 2.7, 0.45), c0 + Vector3(ln / 2.0, 2.7, 0.45), 0.22, pipe_m)
		_pipe(st, c0 + Vector3(-ln / 2.0, 0.5, -0.45), c0 + Vector3(ln / 2.0, 0.5, -0.45), 0.16, rust)
		for k in range(3):
			var vx := c0.x - ln / 2.0 + 2.0 + k * 3.5
			Kit.torus(st, Kit.mat(Color("d8322c"), 0.5), 0.18, 0.26, Vector3(vx, 2.7, c0.z + 0.72), Vector3(PI / 2, 0, 0))
	for x in [29.4]:
		_pipe(st, Vector3(x, 0.3, -23.0), Vector3(x, 0.3, 5.0), 0.3, pipe_m)
		_pipe(st, Vector3(x, 3.4, -23.0), Vector3(x, 3.4, 5.0), 0.2, rust)
	rects.append(Rect2(29.0, -24.0, 1.0, 30.0))
	# stalls and sinks in the first room
	for k in range(4):
		var sx := 17.0 + k * 3.0
		Kit.part(st, Kit.BOX, Kit.mat(Color("6a8aa8"), 0.5), Vector3(0.1, 2.2, 2.2), Vector3(sx - 1.4, 1.1, 4.3))
		Kit.part(st, Kit.BOX, Kit.mat(Color("88a8c4"), 0.5), Vector3(2.6, 2.0, 0.08), Vector3(sx, 1.0, 3.2), Vector3(0, 0.25 * (k % 2), 0))
		Kit.part(st, Kit.CYL, Kit.mat(Color("f8f8f8"), 0.3), Vector3(0.5, 0.5, 0.6), Vector3(sx, 0.25, 4.8))
	rects.append(Rect2(15.6, 3.2, 12.0, 2.5))
	for k in range(3):
		Kit.part(st, Kit.BOX, Kit.mat(Color("f4f4f4"), 0.3), Vector3(1.0, 0.25, 0.6), Vector3(18.0 + k * 3.0, 1.0, -5.3))
		Kit.part(st, Kit.BOX, Kit.mat(Color("a8c8e0"), 0.05, 0.6), Vector3(0.9, 1.0, 0.04), Vector3(18.0 + k * 3.0, 1.9, -5.65))
	for p in [Vector3(21, 0, -1), Vector3(26.5, 0, -9.5), Vector3(17, 0, -15.5), Vector3(24, 0, -21)]:
		Kit.part(st, Kit.CYL, Kit.mat(Color("6aa8d8"), 0.05, 0.3), Vector3(1.8, 0.01, 1.2), p + Vector3(0, 0.02, 0))
	Chars.label(root, "НЕ РАБОТАЕТ С 2009 (ТАБЛИЧКА РАБОТАЕТ)", 52, Color(2.6, 1.4, 1.2), Vector3(22.0, 3.2, 5.66), Vector3(0, PI, 0), 0.006, 6)
	# Вентилёв's corner: a bucket, a radio, a lamp
	Kit.part(st, Kit.BOX, Kit.mat(Color("3a3e48"), 0.4, 0.4), Vector3(0.5, 0.3, 0.26), Vector3(15.0, 0.15, -23.0))
	Kit.part(st, Kit.SPH, Kit.neon(Color("ffe2b0"), 2.0), Vector3.ONE * 0.24, Vector3(15.2, 2.6, -23.4))

	# ---------------- the alley behind the kitchen and the backyard with the drain
	var crate := Kit.mat(Color("a87a4a"), 0.8)
	for p in [Vector3(-9, 0, -9), Vector3(-7.6, 0, -9.4), Vector3(8, 0, -8.6), Vector3(10.5, 0, -12), Vector3(-2, 0, -21), Vector3(5, 0, -22.2)]:
		Kit.part(st, Kit.BOX, crate, Vector3(1.1, 1.1, 1.1), p + Vector3(0, 0.55, 0), Vector3(0, rng.randf() * 0.5, 0))
		rects.append(Rect2(p.x - 0.6, p.z - 0.6, 1.2, 1.2))
	for p in [Vector3(-12.2, 0, -10.5), Vector3(12.0, 0, -18.5)]:
		Kit.part(st, Kit.BOX, Kit.mat(Color("2a6a3a"), 0.6, 0.3), Vector3(1.6, 1.4, 1.2), p + Vector3(0, 0.7, 0))
		Kit.part(st, Kit.BOX, Kit.mat(Color("1a4a2a"), 0.6, 0.3), Vector3(1.7, 0.12, 1.3), p + Vector3(0, 1.45, 0))
		rects.append(Rect2(p.x - 0.8, p.z - 0.6, 1.6, 1.2))
	for p in [Vector3(-27.5, 0, -2), Vector3(-28.4, 0, -3.2), Vector3(-17, 0, -22.4)]:
		Kit.part(st, Kit.SPH, Kit.mat(Color("f0ece0"), 0.9), Vector3(0.9, 0.7, 0.7), p + Vector3(0, 0.35, 0))
		Chars.label(root, "МУКА", 40, Color("6a4a2a"), p + Vector3(0, 0.4, 0.36), Vector3.ZERO, 0.004, 0)
	# the drain pipe where the endless dough comes from
	var drain := Kit.mat(Color("6a7280"), 0.4, 0.7)
	Kit.part(st, Kit.CYL, drain, Vector3(4.4, 3.0, 4.4), Vector3(-22.0, 2.2, -23.0), Vector3(PI / 2, 0, 0))
	Kit.part(st, Kit.CYL, Kit.mat(Color("1a1a1e"), 0.8), Vector3(3.6, 3.04, 3.6), Vector3(-22.0, 2.2, -23.0), Vector3(PI / 2, 0, 0))
	for k in range(6):
		Kit.part(st, Kit.SPH, Kit.mat(Color("f2e2bf"), 0.85), Vector3(1.0 + k * 0.2, 0.5, 1.2), Vector3(-23.5 + k * 0.6, 0.25 + (k % 2) * 0.2, -21.0 + k * 0.4))
	Chars.label(root, "СЛИВ · КОЩЕЙ ПРОДУКТС", 60, Color(2.0, 2.0, 2.2), Vector3(-22.0, 4.6, -21.4), Vector3.ZERO, 0.0065, 6)
	rects.append(Rect2(-24.4, -24.0, 4.8, 1.6))
	# fences
	var fence := Kit.mat(Color("6a5a4a"), 0.8)
	for x in range(-29, 14, 2):
		Kit.part(st, Kit.BOX, fence, Vector3(2.0, 2.0, 0.08), Vector3(x, 1.0, -23.9))
	for z in range(-23, 8, 2):
		Kit.part(st, Kit.BOX, fence, Vector3(0.08, 2.0, 2.0), Vector3(-29.9, 1.0, z))

	# street lamps and flower beds
	for x in [-20.0, -6.0, 6.0, 20.0]:
		Kit.part(st, Kit.CYL, Kit.mat(Color("2a2a32"), 0.4, 0.6), Vector3(0.16, 5, 0.16), Vector3(x, 2.5, 9.0))
		Kit.part(st, Kit.BOX, Kit.neon(Color("ffe2b0"), 2.0), Vector3(0.5, 0.06, 0.3), Vector3(x, 5.0, 9.4))
		circles.append(Vector3(x, 9.0, 0.25))
	for p in [Vector3(-23, 0, 9.5), Vector3(24.5, 0, 9.5)]:
		Kit.part(st, Kit.BOX, Kit.mat(Color("8a5a32"), 0.9), Vector3(3.0, 0.4, 1.2), p + Vector3(0, 0.2, 0))
		for k in range(5):
			Kit.part(st, Kit.SPH, Kit.mat([Color("ff5d7a"), Color("ffd23a"), Color("f4f4f4")][k % 3], 0.7), Vector3.ONE * 0.35, p + Vector3(-1.1 + k * 0.55, 0.55, 0))
		rects.append(Rect2(p.x - 1.5, p.z - 0.6, 3.0, 1.2))
	Chars.tree(st, Vector3(-27, 0, 20), 1.1, Color("4a8a3a"))
	Chars.tree(st, Vector3(27, 0, 13), 1.0, Color("5a8a3a"))
	circles.append(Vector3(-27, 20, 0.55))
	circles.append(Vector3(27, 13, 0.55))

	Kit.bake_static(st)
	for l in [[Vector3(0, 3.6, -1.0), Color("ffd8a0"), 1.6, 14.0], [Vector3(22, 3.0, -9.0), Color("c8e8ff"), 1.4, 16.0], [Vector3(-22, 4.0, -12), Color("ffe8c8"), 1.2, 14.0]]:
		var o := OmniLight3D.new()
		o.position = l[0]
		o.light_color = l[1]
		o.light_energy = l[2]
		o.omni_range = l[3]
		root.add_child(o)
	return {"root": root, "rects": rects, "circles": circles, "id": "cheburek", "name": "Чебуречная «Сочная»", "bounds": BOUNDS,
		"map_rects": [Rect2(-30, 6, 60, 18), Rect2(-14, -6.6, 28, 12.6), Rect2(-30, -24, 16, 32), Rect2(-14, -24, 28, 17.4), Rect2(14, -24, 16, 30)],
		"spawns": {"from_yard": [Vector3(0, 0, 18.5), PI], "start": [Vector3(0, 0, 18.5), PI], "respawn": [Vector3(3.5, 0, 16.5), PI]},
		"portals": [{"pos": Vector3(0, 0, 22.6), "r": 1.3, "to": "yard", "spawn": "from_cheburek", "label": "Двор «Берёзки»"}],
		"npcs": [],
		"mobs": [["roach", Vector3(-9, 0, 4.5), 15], ["roach", Vector3(-2, 0, 4.0), 15], ["roach", Vector3(5, 0, 4.8), 16], ["roach", Vector3(-6, 0, -14), 16],
			["roach", Vector3(4, 0, -16), 17], ["roach", Vector3(-24, 0, -4), 16], ["roach", Vector3(-27, 0, 3), 17],
			["fly", Vector3(-16, 0, 15), 14], ["fly", Vector3(7, 0, 12), 15], ["fly", Vector3(19, 0, 11), 15], ["fly", Vector3(-22, 0, -16), 17],
			["cheb", Vector3(-20, 0, 13), 15], ["cheb", Vector3(-26, 0, -8), 16], ["cheb", Vector3(-17, 0, -18), 17], ["cheb", Vector3(24, 0, 13), 16],
			["plunger_mob", Vector3(20, 0, 1), 16], ["plunger_mob", Vector3(26, 0, -2), 16], ["plunger_mob", Vector3(27, 0, -9), 17],
			["plunger_mob", Vector3(17, 0, -9.5), 17], ["plunger_mob", Vector3(22, 0, -16), 17], ["plunger_mob", Vector3(27, 0, -21), 18]]}
