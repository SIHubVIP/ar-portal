class_name Park
## 0.7: Парк «Заря» — the old park across Kalinov bridge. Koschei bought it through «ООО Тишина Плюс» and sells the dawn
## by subscription: a dry fountain full of ghost bags, a lawn mowed into «ОБНОВИСЬ», robo-ducks on the pond, the summer
## stage «Заря» where the Firebird used to sing, and the ferris wheel «Колесо Обновлений» spinning a loading circle.

const BOUNDS := Rect2(-36.0, -30.0, 72.0, 56.0)
const WHEEL := Vector3(22.0, 0, 13.0)
const HUB_Y := 8.5
const RIM_R := 7.0
const FOUNTAIN := Vector3(0, 0, -8.0)
const POND := Vector3(22.0, 0, -8.0)
const POND_R := 7.0
const STAGE := Vector3(0, 0, 20.5)
const STAGE_FRONT := Vector3(0, 0, 14.6)
const GATE_Z := -22.0
## dawn stones for «Рассвет по подписке»: [position, name, text when found]
const STONES := [
	[Vector3(0.0, 0, -12.6), "Камень у фонтана", "Под сухим фонтаном — тёплый розовый камень. Если приложить к уху, он тихонько поёт «ля»."],
	[Vector3(13.4, 0, -2.6), "Камень у пруда", "У самой воды, где утро бывает первым, — второй камень. Он светится, как отражение рассвета."],
	[Vector3(-23.0, 0, 4.4), "Камень на поляне", "В траве, которую газонокосилки не успели остричь в «ОБНОВИСЬ», — третий камень. Он насвистывает."],
]


static func _bench(st: Node3D, rects: Array, p: Vector3, rot: float) -> void:
	var b := Node3D.new()
	b.position = p
	b.rotation.y = rot
	st.add_child(b)
	Kit.part(b, Kit.BOX, Kit.mat(Color("c86a3a"), 0.7), Vector3(2.2, 0.08, 0.5), Vector3(0, 0.5, 0))
	Kit.part(b, Kit.BOX, Kit.mat(Color("c86a3a"), 0.7), Vector3(2.2, 0.5, 0.08), Vector3(0, 0.85, -0.25))
	for x in [-0.9, 0.9]:
		Kit.part(b, Kit.BOX, Kit.mat(Color("2a2a2a")), Vector3(0.08, 0.5, 0.5), Vector3(x, 0.25, 0))
	if absf(sin(rot)) > 0.5:
		rects.append(Rect2(p.x - 0.3, p.z - 1.1, 0.6, 2.2))
	else:
		rects.append(Rect2(p.x - 1.1, p.z - 0.3, 2.2, 0.6))


static func _lamp(st: Node3D, circles: Array, p: Vector3) -> void:
	Kit.part(st, Kit.CYL, Kit.mat(Color("2a3a32"), 0.4, 0.6), Vector3(0.16, 3.8, 0.16), p + Vector3(0, 1.9, 0))
	Kit.part(st, Kit.SPH, Kit.neon(Color("ffd8b0"), 2.2), Vector3.ONE * 0.46, p + Vector3(0, 3.95, 0))
	circles.append(Vector3(p.x, p.z, 0.25))


static func _goal(st: Node3D, circles: Array, p: Vector3, rot: float) -> void:
	var g := Node3D.new()
	g.position = p
	g.rotation.y = rot
	st.add_child(g)
	var wm := Kit.mat(Color("f4f4f4"), 0.5)
	for z in [-1.6, 1.6]:
		Kit.part(g, Kit.CYL, wm, Vector3(0.12, 2.0, 0.12), Vector3(0, 1.0, z))
	Kit.part(g, Kit.CYL, wm, Vector3(0.12, 3.2, 0.12), Vector3(0, 2.0, 0), Vector3(PI / 2, 0, 0))
	var net := StandardMaterial3D.new()
	net.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	net.albedo_color = Color(1, 1, 1, 0.25)
	Kit.part(g, Kit.BOX, net, Vector3(0.04, 2.0, 3.2), Vector3(-0.9, 1.0, 0))
	for z in [-1.6, 1.6]:
		var w := p + Vector3(0, 0, z).rotated(Vector3.UP, rot)
		circles.append(Vector3(w.x, w.z, 0.2))


## The remix console (0.7): a DJ desk next to every boss arena. Returns the node (static, baked).
static func console(parent: Node3D, pos: Vector3, rot: float) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	n.rotation.y = rot
	parent.add_child(n)
	Kit.part(n, Kit.BOX, Kit.mat(Color("1a1b24"), 0.4, 0.4), Vector3(1.8, 1.0, 0.9), Vector3(0, 0.5, 0))
	Kit.part(n, Kit.BOX, Kit.mat(Color("2a2c38"), 0.3, 0.5), Vector3(1.9, 0.1, 1.0), Vector3(0, 1.04, 0), Vector3(-0.25, 0, 0))
	for s in [-1, 1]:
		Kit.part(n, Kit.CYL, Kit.mat(Color("0e0e12"), 0.2), Vector3(0.5, 0.05, 0.5), Vector3(0.48 * s, 1.12, 0.02), Vector3(-0.25, 0, 0))
		Kit.part(n, Kit.CYL, Kit.neon(Color("ff5dd0"), 2.2), Vector3(0.12, 0.06, 0.12), Vector3(0.48 * s, 1.13, 0.02), Vector3(-0.25, 0, 0))
	for k in range(5):
		Kit.part(n, Kit.BOX, Kit.neon([Kit.TEAL, Kit.GOLD, Color("ff5dd0")][k % 3], 2.0), Vector3(0.1, 0.03, 0.12), Vector3(-0.2 + k * 0.1, 1.1, 0.3), Vector3(-0.25, 0, 0))
	Kit.part(n, Kit.BOX, Kit.neon(Color("b06eff"), 1.6), Vector3(1.82, 0.08, 0.04), Vector3(0, 0.82, 0.46))
	Kit.bake_tree(n)
	Chars.label(n, "РЕМИКС", 70, Color(2.6, 1.6, 3.0), Vector3(0, 1.9, 0), Vector3.ZERO, 0.0075, 8)
	return n


## The ferris wheel «Колесо Обновлений». Faces −Z (towards the park gate). Used both as the map decoration and as the boss.
## Returns {root, body (booth), head (hub), wheels: [rim], wings: [cabins], spinner, lights}
static func wheel() -> Dictionary:
	Kit.init()
	var g := Node3D.new()
	var steel := Kit.mat(Color("e8e4dc"), 0.35, 0.6)
	var legm := Kit.mat(Color("2a7a8a"), 0.4, 0.5)
	var dark := Kit.mat(Color("2a2c34"), 0.4, 0.5)
	# A-frame legs from the ground to the hub
	for sz in [-1.3, 1.3]:
		for sx in [-1, 1]:
			var a := Vector3(4.6 * sx, 0, sz)
			var b := Vector3(0.4 * sx, HUB_Y, sz * 0.5)
			var mid := (a + b) * 0.5
			var leg := Kit.part(g, Kit.CYL, legm, Vector3(0.34, a.distance_to(b), 0.34), mid)
			leg.rotation = Vector3(0, 0, -atan2(b.x - a.x, b.y - a.y))
		Kit.part(g, Kit.BOX, legm, Vector3(6.4, 0.2, 0.2), Vector3(0, 3.0, sz * 0.95))
	# the booth at the base: here the hero hits it, here sits the loading machine
	var body := Node3D.new()
	g.add_child(body)
	Kit.part(body, Kit.BOX, Kit.mat(Color("f4f0e6"), 0.6), Vector3(3.4, 2.4, 2.2), Vector3(0, 1.2, 0))
	Kit.part(body, Kit.BOX, Kit.mat(Color("e8323c"), 0.5), Vector3(3.6, 0.3, 2.4), Vector3(0, 2.55, 0))
	Kit.part(body, Kit.BOX, Kit.neon(Color("4ad8ff"), 1.4), Vector3(1.8, 0.7, 0.04), Vector3(0, 1.5, -1.11))
	Chars.label(body, "КОЛЕСО ОБНОВЛЕНИЙ", 64, Color(3.0, 2.4, 1.6), Vector3(0, 2.95, -1.25), Vector3(0, PI, 0), 0.0075, 8)
	# the hub with a loading spinner on the front
	var head := Node3D.new()
	head.position = Vector3(0, HUB_Y, 0)
	g.add_child(head)
	Kit.part(head, Kit.CYL, dark, Vector3(1.4, 2.0, 1.4), Vector3.ZERO, Vector3(PI / 2, 0, 0))
	Kit.part(head, Kit.CYL, Kit.mat(Color("f2c14e"), 0.3, 0.8), Vector3(1.0, 2.1, 1.0), Vector3.ZERO, Vector3(PI / 2, 0, 0))
	var spinner := Node3D.new()
	spinner.position = Vector3(0, 0, -1.15)
	head.add_child(spinner)
	for k in range(8):
		var a := k * TAU / 8.0
		var c := Color("4ad8ff").lerp(Color("1a2a3a"), k / 8.0)
		Kit.part(spinner, Kit.SPH, Kit.neon(c, 2.6 - k * 0.25), Vector3.ONE * (0.42 - k * 0.025), Vector3(sin(a) * 1.25, cos(a) * 1.25, 0))
	# the rim with spokes and cabins (cabins hang straight: their pivots get the opposite rotation)
	var rim := Node3D.new()
	rim.position = Vector3(0, HUB_Y, 0)
	g.add_child(rim)
	for s in [-0.6, 0.6]:
		Kit.torus(rim, steel, RIM_R - 0.18, RIM_R + 0.18, Vector3(0, 0, s), Vector3(PI / 2, 0, 0))
	var lights := []
	var cabins := []
	var cab_cols := [Color("ff7aa8"), Color("55cdbe"), Color("f5b55c"), Color("b06eff")]
	for k in range(8):
		var a := k * TAU / 8.0
		var tip := Vector3(sin(a) * RIM_R, cos(a) * RIM_R, 0)
		var sp := Kit.part(rim, Kit.CYL, steel, Vector3(0.12, RIM_R, 0.12), tip * 0.5)
		sp.rotation = Vector3(0, 0, -a)
		var lamp := Kit.part(rim, Kit.SPH, Kit.neon(Color("ffe2b0"), 2.4), Vector3.ONE * 0.3, tip * 1.03)
		lights.append(lamp)
		var cab := Node3D.new()
		cab.position = tip
		rim.add_child(cab)
		var cc: Color = cab_cols[k % 4]
		Kit.part(cab, Kit.CYL, dark, Vector3(0.08, 0.9, 0.08), Vector3(0, -0.45, 0))
		Kit.part(cab, Kit.BOX, Kit.mat(cc, 0.5), Vector3(1.3, 1.1, 1.1), Vector3(0, -1.35, 0))
		Kit.part(cab, Kit.BOX, Kit.mat(Color("1a2a3a"), 0.1, 0.3), Vector3(1.0, 0.45, 1.12), Vector3(0, -1.2, 0))
		Kit.part(cab, Kit.BOX, Kit.mat(cc.lightened(0.3), 0.5), Vector3(1.45, 0.12, 1.25), Vector3(0, -0.78, 0))
		cabins.append(cab)
	for k in range(16):
		var a2 := (k + 0.5) * TAU / 16.0
		Kit.part(rim, Kit.SPH, Kit.neon([Color("ff7aa8"), Kit.TEAL][k % 2], 2.0), Vector3.ONE * 0.16, Vector3(sin(a2) * RIM_R, cos(a2) * RIM_R, -0.62))
	return {"root": g, "body": body, "head": head, "wheels": [rim], "wings": cabins, "spinner": spinner, "lights": lights}


## Keeps the cabins hanging straight while the rim turns.
static func turn_wheel(w: Dictionary, angle: float, spin_angle: float) -> void:
	var rim: Node3D = w.wheels[0]
	rim.rotation.z = angle
	for c in w.wings:
		c.rotation.z = -angle
	w.spinner.rotation.z = -spin_angle


static func build(parent: Node3D, dawn: bool) -> Dictionary:
	var root := Node3D.new()
	root.name = "World"
	parent.add_child(root)
	var st := Node3D.new()
	st.name = "Static"
	root.add_child(st)
	var rects: Array = []
	var circles: Array = []

	# ground, the bridge end in the north, paths
	var grass := Color("6a9a4a") if dawn else Color("5a7a46")
	Kit.part(st, Kit.BOX, Kit.mat(grass, 1.0), Vector3(200, 0.2, 160), Vector3(0, -0.12, 0))
	var stone := Kit.mat(Color("a89a86"), 0.85)
	Kit.part(st, Kit.BOX, Kit.tile_material(Color("c8b8a0"), Color("a8987e")), Vector3(8, 0.12, 50), Vector3(0, -0.02, -6))
	Kit.part(st, Kit.BOX, Kit.tile_material(Color("c8b8a0"), Color("a8987e")), Vector3(56, 0.12, 5), Vector3(0, -0.019, -8))
	Kit.part(st, Kit.BOX, stone, Vector3(6.4, 0.6, 9.0), Vector3(0, 0.1, -34), Vector3(-0.08, 0, 0))
	for s in [-1, 1]:
		Kit.part(st, Kit.BOX, Kit.mat(Color("8e8270"), 0.9), Vector3(0.4, 1.0, 9.0), Vector3(3.0 * s, 0.6, -34), Vector3(-0.08, 0, 0))
	# the river behind the bridge
	var water := StandardMaterial3D.new()
	water.albedo_color = Color("2a6a9a")
	water.roughness = 0.08
	water.metallic = 0.3
	Kit.part(st, Kit.BOX, water, Vector3(220, 0.1, 40), Vector3(0, -0.9, -58))

	# fence with the gate «ПАРК «ЗАРЯ»»
	var fence := Kit.mat(Color("2a4a3a"), 0.6, 0.3)
	for x in range(-36, 37, 2):
		if absf(x) < 4:
			continue
		Kit.part(st, Kit.BOX, fence, Vector3(2.0, 1.6, 0.06), Vector3(x, 0.8, GATE_Z))
		Kit.part(st, Kit.CYL, fence, Vector3(0.1, 1.9, 0.1), Vector3(x - 1.0, 0.95, GATE_Z))
	rects.append(Rect2(-37, GATE_Z - 0.3, 33.6, 0.6))
	rects.append(Rect2(3.4, GATE_Z - 0.3, 33.6, 0.6))
	var arch := Kit.mat(Color("2a5a3a"), 0.5, 0.4)
	for x in [-3.6, 3.6]:
		Kit.part(st, Kit.BOX, arch, Vector3(0.9, 5.0, 0.9), Vector3(x, 2.5, GATE_Z))
		Kit.part(st, Kit.SPH, Kit.mat(Color("f2c14e"), 0.3, 0.8), Vector3.ONE * 0.6, Vector3(x, 5.3, GATE_Z))
		circles.append(Vector3(x, GATE_Z, 0.6))
	Kit.part(st, Kit.BOX, arch, Vector3(8.2, 0.9, 0.9), Vector3(0, 5.0, GATE_Z))
	for k in range(7):
		var a := -1.2 + k * 0.4
		Kit.part(st, Kit.BOX, Kit.neon(Color("ff9a5a") if dawn else Color("b89a8a"), 2.4 if dawn else 0.9), Vector3(0.16, 1.6, 0.06), Vector3(sin(a) * 1.4, 6.1 + cos(a) * 0.6, GATE_Z - 0.05), Vector3(0, 0, -a))
	Chars.label(root, "ПАРК «ЗАРЯ»", 120, Color(3.0, 2.2, 1.2), Vector3(0, 5.0, GATE_Z - 0.48), Vector3(0, PI, 0), 0.0095, 10)
	Chars.label(root, "ПАРК «ЗАРЯ»", 120, Color(3.0, 2.2, 1.2), Vector3(0, 5.0, GATE_Z + 0.48), Vector3.ZERO, 0.0095, 10)
	if not dawn:
		Chars.label(root, "ООО «ТИШИНА ПЛЮС» · РАССВЕТ ПО ПОДПИСКЕ", 64, Color(1.8, 1.8, 2.0), Vector3(0, 4.2, GATE_Z - 0.48), Vector3(0, PI, 0), 0.0068, 6)
	else:
		Chars.label(root, "РАССВЕТ — БЕСПЛАТНО (НА 3%)", 64, Color(2.6, 2.2, 1.4), Vector3(0, 4.2, GATE_Z - 0.48), Vector3(0, PI, 0), 0.0068, 6)
	# the guard's booth with a turnstile
	Kit.part(st, Kit.BOX, Kit.mat(Color("3a3e4a"), 0.6), Vector3(2.0, 2.4, 2.0), Vector3(7.4, 1.2, -19.6))
	Kit.part(st, Kit.BOX, Kit.mat(Color("1a2a3a"), 0.1, 0.3), Vector3(1.4, 0.8, 0.04), Vector3(7.4, 1.6, -18.58))
	Kit.part(st, Kit.BOX, Kit.mat(Color("e8323c"), 0.5), Vector3(2.2, 0.2, 2.2), Vector3(7.4, 2.5, -19.6))
	Chars.label(root, "ПРОВЕРКА ПОДПИСКИ", 46, Color(2.6, 2.6, 2.6), Vector3(7.4, 2.15, -18.5), Vector3.ZERO, 0.006, 6)
	rects.append(Rect2(6.3, -20.7, 2.2, 2.2))

	# the dry fountain full of ghost bags
	var fc := FOUNTAIN
	Kit.part(st, Kit.CYL, Kit.mat(Color("d8ccb8"), 0.8), Vector3(6.2, 0.7, 6.2), fc + Vector3(0, 0.35, 0))
	Kit.part(st, Kit.CYL, Kit.mat(Color("8a8070") if not dawn else Color("3a7ab8"), 0.6 if not dawn else 0.1), Vector3(5.4, 0.05, 5.4), fc + Vector3(0, 0.68, 0))
	Kit.part(st, Kit.CYL, Kit.mat(Color("d8ccb8"), 0.8), Vector3(0.9, 2.6, 0.9), fc + Vector3(0, 1.3, 0))
	Kit.part(st, Kit.CYL, Kit.mat(Color("d8ccb8"), 0.8), Vector3(2.4, 0.3, 2.4), fc + Vector3(0, 2.6, 0))
	Kit.part(st, Kit.SPH, Kit.mat(Color("f2c14e"), 0.3, 0.8), Vector3.ONE * 0.7, fc + Vector3(0, 3.0, 0))
	if not dawn:
		var bagm := StandardMaterial3D.new()
		bagm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		bagm.albedo_color = Color(0.95, 0.95, 0.97, 0.7)
		for k in range(6):
			var a := k * 1.05
			Kit.part(st, Kit.SPH, bagm, Vector3(0.6, 0.4, 0.5), fc + Vector3(sin(a) * 2.0, 0.8, cos(a) * 2.0), Vector3(0.3, a, 0.2))
	circles.append(Vector3(fc.x, fc.z, 3.25))

	# the big lawn in the west, mowed into «ОБНОВИСЬ» and smileys (before the dawn)
	Kit.part(st, Kit.BOX, Kit.mat(Color("7aaa52") if dawn else Color("6a8a4a"), 1.0), Vector3(22, 0.03, 22), Vector3(-23, 0.0, -5))
	if not dawn:
		var cut := Chars.label(root, "ОБНОВИСЬ", 220, Color(0.25, 0.38, 0.2), Vector3(-23, 0.05, -5), Vector3(-PI / 2, PI / 2, 0), 0.02, 0)
		cut.modulate = Color(0.28, 0.42, 0.22)
		for p in [Vector3(-30, 0.05, 3), Vector3(-15, 0.05, -14)]:
			var sm := Chars.label(root, ":)", 200, Color(0.28, 0.42, 0.22), p, Vector3(-PI / 2, 0, 0), 0.018, 0)
			sm.modulate = Color(0.28, 0.42, 0.22)
	_goal(st, circles, Vector3(-33.5, 0, -5), 0.0)
	_goal(st, circles, Vector3(-12.6, 0, -5), PI)

	# the pond with robo-ducks
	var pw := StandardMaterial3D.new()
	pw.albedo_color = Color("2a7aa8") if dawn else Color("3a5a6a")
	pw.roughness = 0.05
	pw.metallic = 0.3
	Kit.part(st, Kit.CYL, pw, Vector3(POND_R * 2.0, 0.06, POND_R * 2.0), POND + Vector3(0, 0.02, 0))
	Kit.torus(st, Kit.mat(Color("a89a86"), 0.85), POND_R - 0.1, POND_R + 0.45, POND + Vector3(0, 0.08, 0))
	Kit.part(st, Kit.BOX, Kit.mat(Color("8a5a32"), 0.85), Vector3(1.4, 0.15, 4.0), POND + Vector3(-5.4, 0.28, 3.4), Vector3(0, 0.6, 0))
	for k in range(5):
		var a := k * 1.3 + 0.4
		Kit.part(st, Kit.CYL, Kit.mat(Color("4a8a3a"), 0.8), Vector3(0.9, 0.04, 0.9), POND + Vector3(sin(a) * 4.0, 0.08, cos(a) * 3.6))
	circles.append(Vector3(POND.x, POND.z, POND_R + 0.2))

	# the summer stage «Заря»: a shell with sun rays behind it
	var sc := STAGE
	Kit.part(st, Kit.BOX, Kit.mat(Color("8a5a32"), 0.8), Vector3(13, 1.0, 6.0), sc + Vector3(0, 0.5, 0))
	Kit.part(st, Kit.BOX, Kit.mat(Color("6a4224"), 0.8), Vector3(13.2, 0.12, 6.2), sc + Vector3(0, 1.02, 0))
	var shell := Kit.mat(Color("f4ece0"), 0.6)
	for k in range(9):
		var a := -1.4 + k * 0.35
		Kit.part(st, Kit.BOX, shell, Vector3(1.9, 7.0, 0.3), sc + Vector3(sin(a) * 5.6, 4.2, 2.6 + cos(a) * 1.2), Vector3(0.12, a, 0))
	var ray_col := Color("ffb84a") if dawn else Color("9a8a7a")
	for k in range(11):
		var a := -1.5 + k * 0.3
		Kit.part(st, Kit.BOX, Kit.neon(ray_col, 2.6 if dawn else 0.6), Vector3(0.35, 6.0, 0.1), sc + Vector3(sin(a) * 4.6, 5.0 + cos(a) * 3.6, 4.0), Vector3(0, 0, -a))
	Kit.part(st, Kit.SPH, Kit.neon(Color("ff8a4a") if dawn else Color("6a6a7a"), 2.6 if dawn else 0.6), Vector3(3.6, 3.6, 0.6), sc + Vector3(0, 4.6, 3.9))
	Chars.label(root, "ЛЕТНЯЯ СЦЕНА «ЗАРЯ»", 96, Color(3.0, 2.4, 1.6), Vector3(0, 8.9, sc.z + 2.4), Vector3(0, PI, 0), 0.009, 10)
	rects.append(Rect2(sc.x - 6.6, sc.z - 3.1, 13.2, 7.6))
	# benches for the audience
	for x in [-7.0, 7.0]:
		for z in [6.0, 9.5]:
			_bench(st, rects, Vector3(x, 0, z), PI)

	# the ferris wheel's colliders (the wheel itself is a separate node: decoration or boss)
	for sz in [-1.3, 1.3]:
		for sx in [-4.6, 4.6]:
			circles.append(Vector3(WHEEL.x + sx, WHEEL.z + sz, 0.35))
	circles.append(Vector3(WHEEL.x, WHEEL.z, 2.2))
	Chars.label(root, "КАТАНИЕ — ПО ПОДПИСКЕ" if not dawn else "КАТАНИЕ — БЕСПЛАТНО", 60, Color(2.4, 2.4, 2.6), Vector3(WHEEL.x - 7.0, 2.6, WHEEL.z - 3.0), Vector3(0, PI + 0.4, 0), 0.007, 6)
	Kit.part(st, Kit.CYL, Kit.mat(Color("2a2a32"), 0.5, 0.5), Vector3(0.12, 2.4, 0.12), Vector3(WHEEL.x - 7.0, 1.2, WHEEL.z - 3.05))

	# ice cream kiosk by subscription
	var k2 := Node3D.new()
	k2.position = Vector3(-10, 0, 14)
	k2.rotation.y = PI - 0.5
	st.add_child(k2)
	Kit.part(k2, Kit.BOX, Kit.mat(Color("f4f0e6"), 0.7), Vector3(3, 2.6, 2.4), Vector3(0, 1.3, 0))
	Kit.part(k2, Kit.BOX, Kit.mat(Color("ff7aa8"), 0.6), Vector3(3.3, 0.5, 2.7), Vector3(0, 2.8, 0))
	Kit.part(k2, Kit.BOX, Kit.mat(Color("ffcf7a"), 0.3, 0.0, Color("ffcf7a"), 1.2), Vector3(1.8, 1.0, 0.05), Vector3(0, 1.5, 1.21))
	Kit.part(k2, Kit.CONE, Kit.mat(Color("e8b860"), 0.7), Vector3(0.5, 1.0, 0.5), Vector3(0, 3.6, 0), Vector3(PI, 0, 0))
	Kit.part(k2, Kit.SPH, Kit.mat(Color("ffb0c8"), 0.6), Vector3.ONE * 0.62, Vector3(0, 4.2, 0))
	var kl := Chars.label(root, "МОРОЖЕНОЕ ПО ПОДПИСКЕ" if not dawn else "МОРОЖЕНОЕ", 64, Color(3.0, 2.4, 2.6), Vector3.ZERO, Vector3.ZERO, 0.006, 8)
	kl.position = k2.position + Vector3(sin(PI - 0.5), 0, cos(PI - 0.5)) * 1.37 + Vector3(0, 2.8, 0)
	kl.rotation.y = PI - 0.5
	circles.append(Vector3(-10, 14, 1.9))

	# flower beds, lamps, trees, benches along the alley
	for p in [Vector3(-6, 0, -15), Vector3(6, 0, -15), Vector3(-6, 0, 2), Vector3(6, 0, 2)]:
		Kit.part(st, Kit.CYL, Kit.mat(Color("8a5a32"), 0.9), Vector3(2.6, 0.4, 2.6), p + Vector3(0, 0.2, 0))
		for k in range(7):
			var a := k * 0.9
			var fcol: Color = [Color("ff5d7a"), Color("ffd23a"), Color("ff9a4a"), Color("f4f4f4")][k % 4]
			if not dawn:
				fcol = fcol.lerp(Color("8a8a8a"), 0.55)
			Kit.part(st, Kit.SPH, Kit.mat(fcol, 0.7), Vector3.ONE * 0.36, p + Vector3(sin(a) * 0.8, 0.55, cos(a) * 0.8))
		circles.append(Vector3(p.x, p.z, 1.3))
	for z in [-18.0, -12.0, -3.0, 4.0, 10.0]:
		for x in [-4.4, 4.4]:
			_lamp(st, circles, Vector3(x, 0, z))
	_bench(st, rects, Vector3(-4.6, 0, -6.0), PI / 2)
	_bench(st, rects, Vector3(4.6, 0, -1.0), -PI / 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var leaf := Color("5aa03a") if dawn else Color("5a7a46")
	for p in [Vector3(-34, 0, -25), Vector3(-20, 0, -26), Vector3(-10, 0, -26), Vector3(12, 0, -26), Vector3(24, 0, -26), Vector3(34, 0, -24),
			Vector3(-34, 0, 12), Vector3(-30, 0, 20), Vector3(-20, 0, 22), Vector3(-26, 0, 14), Vector3(-15, 0, 22), Vector3(32, 0, 2),
			Vector3(33, 0, 22), Vector3(10, 0, 23), Vector3(-34, 0, -16), Vector3(14, 0, 4), Vector3(-9, 0, -17), Vector3(10, 0, -16)]:
		Chars.tree(st, p, rng.randf_range(1.0, 1.4), leaf.lerp(Color("c8a03a"), rng.randf() * 0.3))
		circles.append(Vector3(p.x, p.z, 0.6))
	# a skyline far away across the river
	var f1 := Kit.facade_material(Color("c8bba6"), 0.25, 71)
	var f2 := Kit.facade_material(Color("b5b9be"), 0.3, 72)
	for h in [[Vector3(-30, 0, -78), Vector3(40, 16, 12), f1], [Vector3(20, 0, -80), Vector3(46, 22, 12), f2], [Vector3(0, 0, 60), Vector3(80, 14, 12), f2],
			[Vector3(64, 0, 0), Vector3(12, 18, 60), f1], [Vector3(-64, 0, 0), Vector3(12, 15, 60), f2]]:
		Kit.part(st, Kit.BOX, h[2], h[1], h[0] + Vector3(0, h[1].y / 2, 0))

	# the way back across the bridge
	Chars.ring(root, Vector3(0, 0.05, -28.4), 1.2, Color("4ad8ff"), 0.08, 3.0)

	Kit.bake_static(st)
	return {"root": root, "rects": rects, "circles": circles, "id": "park", "name": "Парк «Заря»", "bounds": BOUNDS,
		"map_rects": [Rect2(-4, -30, 8, 44), Rect2(-28, -10.5, 56, 5), Rect2(-34, -16, 22, 22), Rect2(STAGE.x - 6.5, STAGE.z - 3, 13, 6)],
		"spawns": {"from_embankment": [Vector3(0, 0, -25.4), 0.0], "start": [Vector3(0, 0, -25.4), 0.0], "respawn": [Vector3(0, 0, -19.0), 0.0]},
		"portals": [{"pos": Vector3(0, 0, -28.4), "r": 1.3, "to": "embankment", "spawn": "from_park", "label": "Набережная (Калинов мост)"}],
		"npcs": [{"id": "guard", "pos": Vector3(5.0, 0, -18.8), "rot": -2.3}],
		"mobs": [["mower", Vector3(-28, 0, -12), 14], ["mower", Vector3(-22, 0, -1), 15], ["mower", Vector3(-17, 0, -13), 15], ["mower", Vector3(-27, 0, 2), 16],
			["mower", Vector3(-19, 0, -7), 14], ["mower", Vector3(-30, 0, -5), 16],
			["bag", Vector3(-5, 0, -11), 15], ["bag", Vector3(5.5, 0, -5), 15], ["bag", Vector3(4, 0, -13), 16], ["bag", Vector3(-6, 0, -3), 16],
			["bag", Vector3(8, 0, 1), 15], ["bag", Vector3(-8, 0, -14), 16],
			["duck", Vector3(13, 0, -14), 15], ["duck", Vector3(16, 0, 0.5), 16], ["duck", Vector3(28.5, 0, 0.5), 16], ["duck", Vector3(30, 0, -15), 17],
			["duck", Vector3(22, 0, -17.2), 17],
			["loader", Vector3(15, 0, 8), 16], ["loader", Vector3(28, 0, 7.5), 17], ["loader", Vector3(13.5, 0, 16), 17], ["loader", Vector3(30, 0, 18), 18],
			["loader", Vector3(21, 0, 20.5), 18]]}
