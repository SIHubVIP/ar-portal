class_name Laundry
## 0.8 «Мыльная опера»: Прачечная «Ромашка», о которой мечтал Невысокий Лис — ряды стиралок, строгий ресепшен Тамары,
## съёмочная площадка сериала «Отжим» и зал премьеры, где Кощей спрятал Барабан Судьбы.

const BOUNDS := Rect2(-32.0, -22.0, 64.0, 44.0)
const DRUM_HOME := Vector3(0, 0, -15.0)
const TAKE_SPOT := Vector3(18.0, 0, -8.0)      # «Ещё дубль!» — the waves of irons
const SEATS := [Vector3(-5.0, 0, -6.0), Vector3(-3.4, 0, -6.0), Vector3(-1.8, 0, -6.0), Vector3(1.8, 0, -6.0), Vector3(3.4, 0, -6.0), Vector3(5.0, 0, -6.0),
	Vector3(-5.0, 0, -8.0), Vector3(-3.4, 0, -8.0), Vector3(-1.8, 0, -8.0), Vector3(1.8, 0, -8.0), Vector3(3.4, 0, -8.0), Vector3(5.0, 0, -8.0)]


static func _washer_prop(st: Node3D, at: Vector3, rot: float, col: Color) -> void:
	var w := Node3D.new()
	w.position = at
	w.rotation.y = rot
	st.add_child(w)
	Kit.part(w, Kit.BOX, Kit.mat(Color("eef0f4"), 0.35, 0.1), Vector3(1.5, 1.6, 1.3), Vector3(0, 0.8, 0))
	Kit.part(w, Kit.BOX, Kit.mat(Color("c8ccd8"), 0.4), Vector3(1.52, 0.24, 1.32), Vector3(0, 1.5, 0))
	Kit.torus(w, Kit.mat(Color("b8c0cc"), 0.2, 0.9), 0.42, 0.52, Vector3(0, 0.78, 0.66), Vector3(PI / 2, 0, 0))
	Kit.part(w, Kit.CYL, Kit.mat(col.darkened(0.3), 0.5), Vector3(0.82, 0.04, 0.82), Vector3(0, 0.78, 0.62), Vector3(PI / 2, 0, 0))
	Kit.part(w, Kit.BOX, Kit.neon(Color("4ad8ff"), 1.2), Vector3(0.36, 0.1, 0.02), Vector3(0.3, 1.5, 0.67))


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

	# ---------------- ground: the street and the white-and-blue tiles inside
	Kit.part(st, Kit.BOX, Kit.mat(Color("5c7a42"), 1.0), Vector3(200, 0.2, 200), Vector3(0, -0.14, 0))
	Kit.part(st, Kit.BOX, Kit.mat(Color("55565e"), 0.95), Vector3(70, 0.1, 9), Vector3(0, -0.03, 18.5))
	Kit.part(st, Kit.BOX, Kit.tile_material(Color("dfe2ee"), Color("a6b4d2")), Vector3(64, 0.1, 36), Vector3(0, -0.02, -4.0))
	# daisies painted on the floor of the reception
	for k in range(5):
		var c := Vector3(-8.0 + k * 4.0, 0.04, 11.0)
		for p in range(6):
			var a := p * TAU / 6.0
			Kit.part(st, Kit.CYL, Kit.mat(Color("ffffff"), 0.6), Vector3(0.5, 0.01, 0.24), c + Vector3(sin(a) * 0.36, 0, cos(a) * 0.36), Vector3(0, a, 0))
		Kit.part(st, Kit.CYL, Kit.mat(Color("ffd23a"), 0.6), Vector3(0.36, 0.015, 0.36), c)

	# ---------------- the facade with the glass entrance
	var wall := Kit.mat(Color("f4f6fa"), 0.6)
	var blue := Kit.mat(Color("3a7ac8"), 0.5)
	Kit.part(st, Kit.BOX, wall, Vector3(28, 5.0, 0.6), Vector3(-18.0, 2.5, 13.8))
	Kit.part(st, Kit.BOX, wall, Vector3(28, 5.0, 0.6), Vector3(18.0, 2.5, 13.8))
	Kit.part(st, Kit.BOX, wall, Vector3(8.0, 1.2, 0.6), Vector3(0, 4.4, 13.8))
	Kit.part(st, Kit.BOX, blue, Vector3(64.2, 0.4, 0.7), Vector3(0, 5.1, 13.8))
	rects.append(Rect2(-32.0, 13.5, 28.0, 0.6))
	rects.append(Rect2(4.0, 13.5, 28.0, 0.6))
	for x in [-4.0, 4.0]:
		Kit.part(st, Kit.BOX, Kit.mat(Color("c8ccd4"), 0.2, 0.9), Vector3(0.2, 3.8, 0.7), Vector3(x, 1.9, 13.8))
		circles.append(Vector3(x, 13.8, 0.3))
	for x in [-24.0, -12.0, 12.0, 24.0]:
		Kit.part(st, Kit.BOX, Kit.mat(Color("a8d8ff"), 0.05, 0.3), Vector3(6.0, 2.6, 0.05), Vector3(x, 2.0, 14.12))
	var logo := Node3D.new()
	logo.position = Vector3(-7.4, 6.4, 14.3)
	root.add_child(logo)
	for p in range(8):
		var a := p * TAU / 8.0
		Kit.part(logo, Kit.SPH, Kit.neon(Color("ffffff"), 2.0), Vector3(0.36, 0.7, 0.1), Vector3(sin(a) * 0.55, cos(a) * 0.55, 0), Vector3(0, 0, -a))
	Kit.part(logo, Kit.SPH, Kit.neon(Color("ffd23a"), 2.6), Vector3(0.5, 0.5, 0.14))
	Kit.part(st, Kit.BOX, Kit.mat(Color("1d2b4a"), 0.5), Vector3(14.0, 1.6, 0.3), Vector3(0.6, 6.4, 14.1))
	Chars.label(root, "ПРАЧЕЧНАЯ «РОМАШКА»", 140, Color(2.6, 3.0, 3.6), Vector3(0.6, 6.55, 14.3), Vector3.ZERO, 0.0088, 10)
	Chars.label(root, "стирка · сушка · глажка · съёмки сериала «Отжим»", 56, Color(2.6, 2.6, 2.4), Vector3(0.6, 5.85, 14.3), Vector3.ZERO, 0.0062, 6)
	Chars.ring(root, Vector3(0, 0.05, 20.6), 1.2, Color("55cdbe"), 0.08, 3.0)
	# the street: lamps, daisy bushes and a laundry van
	for x in [-22.0, -10.0, 10.0, 22.0]:
		Kit.part(st, Kit.CYL, Kit.mat(Color("2a2a32"), 0.4, 0.6), Vector3(0.16, 5, 0.16), Vector3(x, 2.5, 16.0))
		Kit.part(st, Kit.BOX, Kit.neon(Color("ffe2b0"), 2.0), Vector3(0.5, 0.06, 0.3), Vector3(x, 5.0, 16.4))
		circles.append(Vector3(x, 16.0, 0.25))
	for p in [Vector3(-16, 0, 15.6), Vector3(16, 0, 15.6), Vector3(-28, 0, 15.6), Vector3(28, 0, 15.6)]:
		Kit.part(st, Kit.SPH, Kit.mat(Color("4a8a3a"), 0.9), Vector3(2.4, 1.2, 1.2), p + Vector3(0, 0.6, 0))
		for k in range(5):
			Kit.part(st, Kit.SPH, Kit.mat(Color("ffffff"), 0.6), Vector3.ONE * 0.22, p + Vector3(-0.9 + k * 0.45, 1.2, 0.4))
		rects.append(Rect2(p.x - 1.2, p.z - 0.6, 2.4, 1.2))
	var van := Node3D.new()
	van.position = Vector3(-24.0, 0, 19.0)
	van.rotation.y = PI / 2
	st.add_child(van)
	Kit.part(van, Kit.BOX, Kit.mat(Color("3a7ac8"), 0.4, 0.2), Vector3(2.2, 2.4, 5.4), Vector3(0, 1.4, 0))
	Kit.part(van, Kit.BOX, Kit.mat(Color("a8d8ff"), 0.05, 0.3), Vector3(2.0, 0.8, 0.05), Vector3(0, 1.9, 2.72))
	for z in [-1.8, 1.8]:
		for x in [-1.05, 1.05]:
			Kit.part(van, Kit.CYL, Kit.mat(Color("1a1a1e"), 0.8), Vector3(0.8, 0.3, 0.8), Vector3(x, 0.4, z), Vector3(0, 0, PI / 2))
	Chars.label(root, "«РОМАШКА» · ДОСТАВКА ЧИСТОТЫ", 60, Color(3.0, 3.0, 3.0), Vector3(-24.0, 1.8, 17.85), Vector3.ZERO, 0.0062, 6)
	rects.append(Rect2(-26.8, 17.8, 5.6, 2.4))

	# ---------------- the reception of Тамара: a strict desk, a ticket machine, a queue like at an airport
	Kit.part(st, Kit.BOX, Kit.mat(Color("1d2b4a"), 0.5), Vector3(6.0, 1.1, 1.2), Vector3(0, 0.55, 8.6))
	Kit.part(st, Kit.BOX, Kit.mat(Color("f4f6fa"), 0.3), Vector3(6.2, 0.08, 1.3), Vector3(0, 1.14, 8.6))
	Kit.part(st, Kit.BOX, Kit.mat(Color("f2c21a"), 0.4), Vector3(0.5, 0.7, 0.4), Vector3(2.4, 1.5, 8.6))
	Chars.label(root, "ТАЛОН", 46, Color("1a1a1e"), Vector3(2.4, 1.7, 8.82), Vector3.ZERO, 0.0045, 0)
	# the queue board stands on a pole beside the desk (0.8: no longer hangs in the camera's way)
	var board := Node3D.new()
	board.position = Vector3(-4.8, 0, 8.9)
	board.rotation.y = 0.35
	root.add_child(board)
	Kit.part(board, Kit.CYL, Kit.mat(Color("c8ccd4"), 0.2, 0.9), Vector3(0.12, 2.4, 0.12), Vector3(0, 1.2, 0))
	Kit.part(board, Kit.BOX, Kit.mat(Color("1a1a1e"), 0.5), Vector3(3.4, 1.0, 0.1), Vector3(0, 2.85, 0))
	Chars.label(board, "СЕЙЧАС ОБСЛУЖИВАЕТСЯ: ТАЛОН №1", 40, Color(1.4, 3.2, 1.6), Vector3(0, 3.05, 0.07), Vector3.ZERO, 0.0042, 4)
	Chars.label(board, "НЕТ ТАЛОНЧИКА — НЕТ СТИРКИ", 40, Color(3.0, 2.0, 1.6), Vector3(0, 2.68, 0.07), Vector3.ZERO, 0.0042, 4)
	circles.append(Vector3(-4.8, 8.9, 0.3))
	rects.append(Rect2(-3.0, 8.0, 6.0, 1.2))
	for k in range(4):
		for x in [-12.0, -5.5]:
			var pz := 9.2 + k * 1.0
			Kit.part(st, Kit.CYL, Kit.mat(Color("c8ccd4"), 0.2, 0.9), Vector3(0.1, 1.0, 0.1), Vector3(x, 0.5, pz))
			Kit.part(st, Kit.CYL, Kit.mat(Color("c8ccd4"), 0.2, 0.9), Vector3(0.3, 0.05, 0.3), Vector3(x, 0.02, pz))
		Kit.part(st, Kit.BOX, Kit.mat(Color("d8322c"), 0.7), Vector3(6.5, 0.08, 0.02), Vector3(-8.75, 0.92, 9.2 + k * 1.0))
	for k in range(5):
		var cp := Vector3(-27.0 + k * 1.6, 0, 11.4)
		Kit.part(st, Kit.BOX, Kit.mat(Color("3a7ac8"), 0.6), Vector3(1.2, 0.12, 1.0), cp + Vector3(0, 0.5, 0))
		Kit.part(st, Kit.BOX, Kit.mat(Color("3a7ac8"), 0.6), Vector3(1.2, 0.8, 0.12), cp + Vector3(0, 0.9, 0.5))
	rects.append(Rect2(-27.8, 10.8, 8.0, 1.4))

	# ---------------- the washer hall in the west: three rows of machines, dryers on the wall
	var cols := [Color("e8323c"), Color("3a7ac8"), Color("2a9a5a"), Color("ffd23a"), Color("ff9ad0"), Color("8a4ad8")]
	for row in [-16.0, -9.0, -2.0]:
		for k in range(6):
			_washer_prop(st, Vector3(-28.0 + k * 3.2, 0, row), 0.0, cols[(k + int(row)) % cols.size()])
		rects.append(Rect2(-29.0, row - 0.7, 18.8, 1.4))
	for k in range(7):
		var dz := -19.0 + k * 3.0
		Kit.part(st, Kit.BOX, Kit.mat(Color("dfe2ea"), 0.4), Vector3(1.2, 3.4, 2.6), Vector3(-31.2, 1.7, dz))
		Kit.torus(st, Kit.mat(Color("b8c0cc"), 0.2, 0.9), 0.32, 0.4, Vector3(-30.58, 1.0, dz), Vector3(0, 0, PI / 2))
		Kit.torus(st, Kit.mat(Color("b8c0cc"), 0.2, 0.9), 0.32, 0.4, Vector3(-30.58, 2.5, dz), Vector3(0, 0, PI / 2))
	rects.append(Rect2(-32.0, -21.0, 1.6, 21.0))
	for p in [Vector3(-12.0, 0, -12.5), Vector3(-24.0, 0, -5.5), Vector3(-18.0, 0, 3.5)]:
		Kit.part(st, Kit.BOX, Kit.mat(Color("b88a5a"), 0.8), Vector3(1.6, 0.9, 1.0), p + Vector3(0, 0.45, 0))
		for k in range(3):
			Kit.part(st, Kit.BOX, Kit.mat(cols[(k + int(p.x)) % 6], 0.9), Vector3(0.5, 0.12, 0.4), p + Vector3(-0.45 + k * 0.45, 0.95, 0))
		rects.append(Rect2(p.x - 0.8, p.z - 0.5, 1.6, 1.0))
	Chars.label(root, "СТИРКА · ПО ТАЛОНЧИКУ", 70, Color(2.4, 3.0, 3.6), Vector3(-20.0, 4.2, -21.5), Vector3.ZERO, 0.0075, 6)
	Kit.part(st, Kit.BOX, wall, Vector3(30.0, 4.6, 0.6), Vector3(-17.0, 2.3, -21.8))

	# ---------------- the premiere hall in the middle: a screen, red curtains, two rows of seats
	Kit.part(st, Kit.BOX, wall, Vector3(16.0, 7.0, 0.6), Vector3(0, 3.5, -21.8))
	Kit.part(st, Kit.BOX, Kit.mat(Color("101420"), 0.2, 0.3), Vector3(12.0, 5.0, 0.1), Vector3(0, 3.8, -21.45))
	Chars.label(root, "«ОТЖИМ» · ПРЕМЬЕРА", 130, Color(3.6, 3.0, 2.0), Vector3(0, 4.6, -21.38), Vector3.ZERO, 0.0095, 8)
	Chars.label(root, "весь сбор — на выкуп парка «Заря»", 64, Color(2.6, 2.6, 2.6), Vector3(0, 3.5, -21.38), Vector3.ZERO, 0.0068, 6)
	for x in [-7.2, 7.2]:
		Kit.part(st, Kit.BOX, Kit.mat(Color("a8182a"), 0.9), Vector3(2.0, 6.6, 0.4), Vector3(x, 3.3, -21.2))
	for x in [-7.8, 7.2]:
		Kit.part(st, Kit.BOX, wall, Vector3(0.6, 3.2, 9.0), Vector3(x + 0.3, 1.6, -16.5))
		rects.append(Rect2(x, -21.0, 0.6, 9.0))
	for s in SEATS:
		Kit.part(st, Kit.BOX, Kit.mat(Color("a8182a"), 0.8), Vector3(1.2, 0.5, 1.0), s + Vector3(0, 0.45, 0))
		Kit.part(st, Kit.BOX, Kit.mat(Color("a8182a"), 0.8), Vector3(1.2, 1.0, 0.16), s + Vector3(0, 0.95, 0.5))
	for z in [-6.0, -8.0]:
		rects.append(Rect2(-5.7, z - 0.5, 4.6, 1.1))
		rects.append(Rect2(1.1, z - 0.5, 4.6, 1.1))
	for x in [-3.0, 3.0]:
		Kit.part(st, Kit.CYL, Kit.mat(Color("2a2a32"), 0.4, 0.6), Vector3(0.12, 4.0, 0.12), Vector3(x, 2.0, -11.0))
		Kit.part(st, Kit.CYL, Kit.neon(Color("fff4d0"), 2.6), Vector3(0.6, 0.3, 0.6), Vector3(x, 4.1, -11.2), Vector3(-0.8, 0, 0))
		circles.append(Vector3(x, -11.0, 0.2))

	# ---------------- the film set in the east: the flat of the granny-detective, cameras, lights, the director's chair
	Kit.part(st, Kit.BOX, wall, Vector3(24.0, 5.0, 0.6), Vector3(20.0, 2.5, -21.8))
	var paper := Kit.mat(Color("d8b8a0"), 0.9)
	Kit.part(st, Kit.BOX, paper, Vector3(14.0, 4.2, 0.2), Vector3(21.0, 2.1, -20.6))
	for k in range(7):
		Kit.part(st, Kit.BOX, Kit.mat(Color("c89a7a"), 0.9), Vector3(0.12, 4.2, 0.02), Vector3(15.0 + k * 2.0, 2.1, -20.48))
	Kit.part(st, Kit.BOX, Kit.mat(Color("a8d8ff"), 0.05, 0.3), Vector3(3.0, 2.0, 0.05), Vector3(18.0, 2.6, -20.45))
	Kit.part(st, Kit.BOX, Kit.mat(Color("6a3a2a"), 0.7), Vector3(1.8, 2.2, 0.1), Vector3(25.0, 2.7, -20.45))
	Chars.label(root, "ШЕРЛОК ЗИНА", 50, Color("f2c14e"), Vector3(25.0, 1.4, -20.38), Vector3.ZERO, 0.0045, 4)
	Kit.part(st, Kit.BOX, Kit.mat(Color("8a2a3a"), 0.9), Vector3(4.0, 0.9, 1.4), Vector3(21.0, 0.45, -18.6))
	Kit.part(st, Kit.BOX, Kit.mat(Color("8a2a3a"), 0.9), Vector3(4.0, 1.0, 0.3), Vector3(21.0, 1.2, -19.2))
	Kit.part(st, Kit.CYL, Kit.mat(Color("6a8a5a"), 0.9), Vector3(5.0, 0.03, 3.4), Vector3(21.0, 0.02, -16.5))
	Kit.part(st, Kit.CYL, Kit.mat(Color("c8a03a"), 0.4, 0.6), Vector3(0.1, 1.8, 0.1), Vector3(24.2, 0.9, -19.0))
	Kit.part(st, Kit.CONE, Kit.mat(Color("f4e0a0"), 0.8), Vector3(0.7, 0.5, 0.7), Vector3(24.2, 1.9, -19.0))
	rects.append(Rect2(19.0, -19.6, 4.0, 1.7))
	Chars.label(root, "СЕРИАЛ «ОТЖИМ» · СЪЁМОЧНАЯ ПЛОЩАДКА · ТИХО! ИДЁТ ЗАПИСЬ", 56, Color(3.2, 1.6, 1.4), Vector3(20.0, 4.6, -21.45), Vector3.ZERO, 0.0062, 6)
	for cam in [[Vector3(14.0, 0, -6.0), -2.4], [Vector3(26.0, 0, -5.0), 2.6], [Vector3(10.6, 0, -15.0), -1.0]]:
		var c := Node3D.new()
		c.position = cam[0]
		c.rotation.y = cam[1]
		st.add_child(c)
		for a in range(3):
			Kit.part(c, Kit.CYL, Kit.mat(Color("2a2a32"), 0.4, 0.6), Vector3(0.06, 1.7, 0.06), Vector3(sin(a * TAU / 3.0) * 0.3, 0.8, cos(a * TAU / 3.0) * 0.3), Vector3(cos(a * TAU / 3.0) * 0.2, 0, -sin(a * TAU / 3.0) * 0.2))
		Kit.part(c, Kit.BOX, Kit.mat(Color("1a1a1e"), 0.4, 0.4), Vector3(0.5, 0.5, 0.9), Vector3(0, 1.75, 0))
		Kit.part(c, Kit.CYL, Kit.mat(Color("1a1a1e"), 0.2, 0.6), Vector3(0.36, 0.5, 0.36), Vector3(0, 1.75, 0.6), Vector3(PI / 2, 0, 0))
		Kit.part(c, Kit.SPH, Kit.neon(Color("ff2a3a"), 3.0), Vector3.ONE * 0.08, Vector3(0.2, 2.05, 0.3))
		circles.append(Vector3(cam[0].x, cam[0].z, 0.5))
	for lp in [Vector3(12.0, 0, -18.0), Vector3(29.0, 0, -14.0)]:
		Kit.part(st, Kit.CYL, Kit.mat(Color("2a2a32"), 0.4, 0.6), Vector3(0.1, 3.4, 0.1), lp + Vector3(0, 1.7, 0))
		Kit.part(st, Kit.BOX, Kit.mat(Color("1a1a1e"), 0.4, 0.4), Vector3(0.8, 0.6, 0.6), lp + Vector3(0, 3.5, 0))
		Kit.part(st, Kit.BOX, Kit.neon(Color("fff4d0"), 3.0), Vector3(0.7, 0.5, 0.04), lp + Vector3(0, 3.5, 0.32))
		circles.append(Vector3(lp.x, lp.z, 0.3))
	var chair := Node3D.new()
	chair.position = Vector3(16.6, 0, -0.6)
	chair.rotation.y = -2.5
	st.add_child(chair)
	Kit.part(chair, Kit.BOX, Kit.mat(Color("2a2a32"), 0.5), Vector3(0.9, 0.06, 0.8), Vector3(0, 0.7, 0))
	Kit.part(chair, Kit.BOX, Kit.mat(Color("1a1a1e"), 0.8), Vector3(0.9, 0.5, 0.06), Vector3(0, 1.2, -0.38))
	for x in [-0.4, 0.4]:
		Kit.part(chair, Kit.BOX, Kit.mat(Color("a87a4a"), 0.7), Vector3(0.06, 1.4, 0.06), Vector3(x, 0.7, 0), Vector3(0.3, 0, 0))
	Chars.label(root, "Д. ДУБЛЕВИЧ", 40, Color("f2c14e"), Vector3(16.6, 1.22, -0.25), Vector3(0, -2.5 + PI, 0), 0.004, 4)
	circles.append(Vector3(16.6, -0.6, 0.5))

	Kit.bake_static(st)
	for l in [[Vector3(-18, 4.0, -9.0), Color("e8f4ff"), 1.4, 18.0], [Vector3(0, 4.0, -13.0), Color("fff0e0"), 1.2, 14.0],
			[Vector3(20, 4.0, -12.0), Color("ffe8c8"), 1.6, 16.0], [Vector3(0, 4.0, 9.0), Color("ffffff"), 1.0, 12.0]]:
		var o := OmniLight3D.new()
		o.position = l[0]
		o.light_color = l[1]
		o.light_energy = l[2]
		o.omni_range = l[3]
		root.add_child(o)
	return {"root": root, "rects": rects, "circles": circles, "id": "laundry", "name": "Прачечная «Ромашка»", "bounds": BOUNDS,
		"map_rects": [Rect2(-4, 13, 8, 9), Rect2(-32, 14, 64, 8), Rect2(-31, -21, 62, 34)],
		"spawns": {"from_yard": [Vector3(0, 0, 17.5), PI], "start": [Vector3(0, 0, 17.5), PI], "respawn": [Vector3(3.5, 0, 16.0), PI]},
		"portals": [{"pos": Vector3(0, 0, 20.6), "r": 1.3, "to": "yard", "spawn": "from_laundry", "label": "Двор «Берёзки»"}],
		"npcs": [],
		"mobs": [["sock", Vector3(-20, 0, -12.5), 16], ["sock", Vector3(-18.8, 0, -12.0), 16], ["sock", Vector3(-14, 0, -5.5), 17], ["sock", Vector3(-12.8, 0, -5.0), 17],
			["sock", Vector3(20, 0, -9.0), 18], ["sock", Vector3(21.2, 0, -9.6), 18], ["sock", Vector3(-24, 0, 2.5), 16], ["sock", Vector3(-22.8, 0, 3.0), 16],
			["washer", Vector3(-26, 0, -12.5), 17], ["washer", Vector3(-12, 0, -19), 18], ["washer", Vector3(-16, 0, 1.5), 17],
			["iron", Vector3(12, 0, -16), 18], ["iron", Vector3(25, 0, -15), 19], ["iron", Vector3(28, 0, -8), 19], ["iron", Vector3(13, 0, 2), 18],
			["bubble", Vector3(-22, 0, -5.5), 17], ["bubble", Vector3(-10, 0, -12.5), 17], ["bubble", Vector3(10, 0, -6), 18], ["bubble", Vector3(26, 0, 1), 18],
			["bubble", Vector3(-28, 0, -19), 17]]}
