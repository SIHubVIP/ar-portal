class_name Mobs08
## 0.8 «Мыльная опера»: models of the Чебуречная and the Прачечная — mobs, the bosses Тесто Вечности and Барабан Судьбы,
## new people (тётя Сочня, Пельмень Недоеденный, сантехник Вентилёв, Тамара Ресепшн, Дубль Дублевич, the medics
## Отличный Чел и Отличная Особь, Бог Здорово in the sky) and props (Скамейка Здорово, скорая «Отлично-03»).
## Mobs return {root, body, head, wings, wheels} like Chars.*; people return Chars.human dictionaries.

static func _m(c: Color, rough := 0.6, metal := 0.0) -> StandardMaterial3D:
	return Kit.mat(c, rough, metal)


static func _shadow(g: Node3D, r: float) -> void:
	var sh := StandardMaterial3D.new()
	sh.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sh.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sh.albedo_color = Color(0, 0, 0, 0.28)
	Kit.part(g, Kit.DISC, sh, Vector3(r, 1, r), Vector3(0, 0.03, 0))


static func _eyes(p: Node3D, y: float, z: float, dx: float, s := 0.14, angry := 0.0) -> void:
	for k in [-1, 1]:
		Kit.part(p, Kit.SPH, _m(Color("ffffff"), 0.3), Vector3(s, s * 1.15, s * 0.5), Vector3(dx * k, y, z))
		Kit.part(p, Kit.SPH, _m(Color("15161c"), 0.2), Vector3(s * 0.5, s * 0.6, s * 0.3), Vector3(dx * k, y - s * 0.05, z + s * 0.2))
		if angry != 0.0:
			Kit.part(p, Kit.BOX, _m(Color("2a1a14")), Vector3(s * 1.1, s * 0.22, s * 0.2), Vector3(dx * k, y + s * 0.75, z + s * 0.1), Vector3(0, 0, -angry * k))


static func _glass(c: Color, a := 0.35) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(c, a)
	m.roughness = 0.05
	m.metallic = 0.2
	m.rim_enabled = true
	m.rim = 0.6
	return m


# =================================================================== Чебуречная: mobs
## Таракан-ниндзя: a brown cockroach in a black mask with a red headband and a toothpick katana
static func roach() -> Dictionary:
	Kit.init()
	var g := Node3D.new()
	var body := Node3D.new()
	g.add_child(body)
	var brown := _m(Color("6a3a1e"), 0.25, 0.3)
	Kit.part(body, Kit.SPH, brown, Vector3(0.9, 0.42, 1.35), Vector3(0, 0.45, -0.1))
	Kit.part(body, Kit.BOX, _m(Color("4a2410"), 0.3, 0.3), Vector3(0.04, 0.3, 1.1), Vector3(0, 0.62, -0.15))
	var head := Node3D.new()
	head.position = Vector3(0, 0.55, 0.62)
	body.add_child(head)
	Kit.part(head, Kit.SPH, brown, Vector3(0.58, 0.46, 0.5))
	Kit.part(head, Kit.CYL, _m(Color("15161c"), 0.6), Vector3(0.6, 0.16, 0.52), Vector3(0, 0.04, 0))
	Kit.part(head, Kit.CYL, _m(Color("d8322c"), 0.6), Vector3(0.62, 0.07, 0.54), Vector3(0, 0.17, 0))
	for k in [-1, 1]:
		Kit.part(head, Kit.BOX, _m(Color("d8322c"), 0.6), Vector3(0.06, 0.04, 0.4), Vector3(0.08 * k, 0.17, -0.42), Vector3(0.4, 0.3 * k, 0))
		Kit.part(head, Kit.BOX, Kit.mat(Color("ffffff"), 0.3, 0.0, Color("ffffff"), 0.6), Vector3(0.14, 0.04, 0.02), Vector3(0.12 * k, 0.04, 0.26), Vector3(0, 0, -0.3 * k))
		var ant := Kit.part(head, Kit.CYL, _m(Color("3a1a0a")), Vector3(0.025, 0.9, 0.025), Vector3(0.12 * k, 0.5, 0.2), Vector3(-0.5, 0, 0.35 * k))
		ant.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# the toothpick katana on its back
	Kit.part(body, Kit.CYL, _m(Color("e8d0a0"), 0.6), Vector3(0.04, 1.0, 0.04), Vector3(0.2, 0.85, -0.3), Vector3(0.9, 0, 0.5))
	var legs := []
	for side in [-1, 1]:
		for k in range(3):
			var l := Node3D.new()
			l.position = Vector3(0.38 * side, 0.4, 0.3 - k * 0.35)
			body.add_child(l)
			Kit.part(l, Kit.CYL, _m(Color("3a1a0a")), Vector3(0.05, 0.55, 0.05), Vector3(0.18 * side, -0.18, 0), Vector3(0, 0, 0.9 * side))
			legs.append(l)
	_shadow(g, 1.3)
	return {"root": g, "body": body, "head": head, "wings": [], "wheels": legs}


## Муха-коллектор: a fat green fly with red facet eyes, a tie and a bill clipboard — collects «debts for chebureks»
static func fly() -> Dictionary:
	Kit.init()
	var g := Node3D.new()
	var body := Node3D.new()
	body.position = Vector3(0, 1.8, 0)
	g.add_child(body)
	var green := _m(Color("2a4a2a"), 0.2, 0.6)
	Kit.part(body, Kit.SPH, green, Vector3(0.7, 0.62, 0.95))
	Kit.part(body, Kit.SPH, _m(Color("1a2a1a"), 0.3, 0.5), Vector3(0.55, 0.5, 0.7), Vector3(0, -0.05, -0.55))
	Kit.part(body, Kit.BOX, _m(Color("d8322c"), 0.6), Vector3(0.12, 0.34, 0.04), Vector3(0, -0.05, 0.42), Vector3(0.3, 0, 0))
	var head := Node3D.new()
	head.position = Vector3(0, 0.12, 0.48)
	body.add_child(head)
	Kit.part(head, Kit.SPH, green, Vector3.ONE * 0.46)
	for k in [-1, 1]:
		Kit.part(head, Kit.SPH, Kit.mat(Color("c8182a"), 0.15, 0.4, Color("ff2a3a"), 0.6), Vector3(0.3, 0.34, 0.26), Vector3(0.17 * k, 0.06, 0.12))
	Kit.part(head, Kit.CYL, _m(Color("15161c")), Vector3(0.05, 0.24, 0.05), Vector3(0, -0.2, 0.18), Vector3(0.6, 0, 0))
	var wings := []
	var wm := _glass(Color("dfeeff"), 0.45)
	for k in [-1, 1]:
		var w := Node3D.new()
		w.position = Vector3(0.18 * k, 0.28, -0.05)
		body.add_child(w)
		Kit.part(w, Kit.SPH, wm, Vector3(0.7, 0.04, 0.42), Vector3(0.35 * k, 0, -0.08))
		wings.append(w)
	var legs := []
	for k in range(3):
		for side in [-1, 1]:
			var l := Kit.part(body, Kit.CYL, _m(Color("15161c")), Vector3(0.03, 0.4, 0.03), Vector3(0.2 * side, -0.38, 0.2 - k * 0.2), Vector3(0, 0, 0.4 * side))
			legs.append(l)
	# the bill «СЧЁТ»
	var bill := Node3D.new()
	bill.position = Vector3(0.0, -0.3, 0.5)
	body.add_child(bill)
	Kit.part(bill, Kit.BOX, _m(Color("f4f0e6"), 0.8), Vector3(0.3, 0.38, 0.02), Vector3.ZERO, Vector3(-0.3, 0, 0))
	Chars.label(bill, "СЧЁТ", 40, Color("2a2a34"), Vector3(0, 0.08, 0.02), Vector3(-0.3, 0, 0), 0.004, 0)
	_shadow(g, 0.8)
	return {"root": g, "body": body, "head": head, "wings": wings, "wheels": legs}


## Чебурек-брызгун: a golden half-moon cheburek standing on its edge, crimped rim, angry brows, hot steam on top
static func cheb() -> Dictionary:
	Kit.init()
	var g := Node3D.new()
	var body := Node3D.new()
	g.add_child(body)
	var crust := _m(Color("d89a3a"), 0.55)
	Kit.part(body, Kit.SPH, crust, Vector3(1.7, 2.0, 0.42), Vector3(0, 0.05, 0))
	Kit.part(body, Kit.SPH, _m(Color("e8b45a"), 0.5), Vector3(1.5, 1.8, 0.46), Vector3(0, 0.05, 0))
	for k in range(13):
		var a := -PI / 2 + k * PI / 12.0
		Kit.part(body, Kit.SPH, _m(Color("c4842a"), 0.6), Vector3(0.2, 0.2, 0.36), Vector3(sin(a) * 0.82, 0.05 + cos(a) * 0.98, 0))
	for k in range(6):
		Kit.part(body, Kit.SPH, _m(Color("b8742a"), 0.7), Vector3.ONE * 0.08, Vector3(-0.45 + k * 0.18, 0.4 + sin(k * 2.1) * 0.25, 0.23))
	var head := Node3D.new()
	head.position = Vector3(0, 0.5, 0.22)
	body.add_child(head)
	_eyes(head, 0.05, 0.02, 0.2, 0.18, 0.5)
	Kit.part(head, Kit.SPH, _m(Color("6a2a1a"), 0.5), Vector3(0.3, 0.12, 0.05), Vector3(0, -0.24, 0.02))
	# juice drops and steam
	var steam := []
	for k in range(3):
		var st := Kit.part(body, Kit.SPH, Kit.glow_material(Color(1, 1, 1), 0.35), Vector3.ONE * (0.32 - k * 0.06), Vector3(-0.2 + k * 0.2, 1.25 + k * 0.25, 0))
		st.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		steam.append(st)
	Kit.part(body, Kit.SPH, Kit.mat(Color("ffcc33"), 0.1, 0.0, Color("ffcc33"), 0.8), Vector3(0.12, 0.18, 0.12), Vector3(0.6, 0.2, 0.2))
	var feet := []
	for k in [-1, 1]:
		var f := Kit.part(body, Kit.SPH, _m(Color("c4842a"), 0.6), Vector3(0.3, 0.16, 0.36), Vector3(0.35 * k, 0.08, 0.1))
		feet.append(f)
	_shadow(g, 1.5)
	return {"root": g, "body": body, "head": head, "wings": steam, "wheels": feet}


## Вантуз-прыгун: a red rubber plunger on a wooden handle with googly eyes; it hops and sticks
static func plunger() -> Dictionary:
	Kit.init()
	var g := Node3D.new()
	var body := Node3D.new()
	g.add_child(body)
	var red := _m(Color("c8202c"), 0.35)
	var cup := CylinderMesh.new()
	cup.top_radius = 0.22
	cup.bottom_radius = 0.5
	cup.height = 0.55
	cup.radial_segments = 20
	Kit.part(body, cup, red, Vector3.ONE, Vector3(0, 0.3, 0))
	Kit.part(body, Kit.CYL, _m(Color("8a1a20"), 0.4), Vector3(1.0, 0.06, 1.0), Vector3(0, 0.04, 0))
	Kit.part(body, Kit.CYL, _m(Color("a8743a"), 0.7), Vector3(0.14, 1.1, 0.14), Vector3(0, 1.05, 0))
	Kit.part(body, Kit.SPH, _m(Color("a8743a"), 0.7), Vector3.ONE * 0.2, Vector3(0, 1.62, 0))
	var head := Node3D.new()
	head.position = Vector3(0, 0.36, 0.3)
	body.add_child(head)
	for k in [-1, 1]:
		Kit.part(head, Kit.SPH, _m(Color("ffffff"), 0.3), Vector3.ONE * 0.18, Vector3(0.12 * k, 0.05, 0))
		Kit.part(head, Kit.SPH, _m(Color("15161c"), 0.2), Vector3.ONE * 0.08, Vector3(0.12 * k + 0.02 * k, 0.03, 0.08))
	Kit.part(head, Kit.BOX, _m(Color("3a0a10")), Vector3(0.2, 0.04, 0.02), Vector3(0, -0.12, 0.05))
	_shadow(g, 1.0)
	return {"root": g, "body": body, "head": head, "wings": [], "wheels": []}


## Пельмешек: a small angry dumpling the Тесто Вечности splits into
static func pelmeshek() -> Dictionary:
	Kit.init()
	var g := Node3D.new()
	var body := Node3D.new()
	g.add_child(body)
	var dough := _m(Color("f4e6c8"), 0.8)
	Kit.part(body, Kit.SPH, dough, Vector3(0.8, 0.55, 0.62), Vector3(0, 0.3, 0))
	for k in range(7):
		Kit.part(body, Kit.SPH, _m(Color("ead6b0"), 0.8), Vector3(0.16, 0.16, 0.14), Vector3(-0.3 + k * 0.1, 0.55 + sin(k * 0.9) * 0.02, 0))
	var head := Node3D.new()
	head.position = Vector3(0, 0.32, 0.28)
	body.add_child(head)
	_eyes(head, 0.02, 0.0, 0.12, 0.11, 0.5)
	var feet := []
	for k in [-1, 1]:
		feet.append(Kit.part(body, Kit.SPH, dough, Vector3(0.16, 0.1, 0.2), Vector3(0.18 * k, 0.04, 0.06)))
	_shadow(g, 0.7)
	return {"root": g, "body": body, "head": head, "wings": [], "wheels": feet}


# =================================================================== Прачечная: mobs
## Носок-одиночка: a striped sock looking for its pair; colours differ (and never match)
static func sock(seed := 0) -> Dictionary:
	Kit.init()
	var cols := [[Color("e8323c"), Color("f4f4f4")], [Color("3a7ac8"), Color("ffd23a")], [Color("2a9a5a"), Color("f4f4f4")], [Color("8a4ad8"), Color("ff9ad0")]]
	var c: Array = cols[seed % cols.size()]
	var g := Node3D.new()
	var body := Node3D.new()
	g.add_child(body)
	var m1 := _m(c[0], 0.9)
	var m2 := _m(c[1], 0.9)
	Kit.part(body, Kit.CYL, m1, Vector3(0.5, 1.0, 0.5), Vector3(0, 0.85, 0))
	for k in range(4):
		Kit.part(body, Kit.CYL, m2, Vector3(0.52, 0.1, 0.52), Vector3(0, 0.5 + k * 0.24, 0))
	Kit.part(body, Kit.CAP, m1, Vector3(1.2, 1.1, 1.3), Vector3(0, 0.28, 0.25), Vector3(PI / 2, 0, 0))
	Kit.part(body, Kit.SPH, m2, Vector3(0.38, 0.3, 0.3), Vector3(0, 0.25, 0.62))
	Kit.part(body, Kit.CYL, m2, Vector3(0.56, 0.14, 0.56), Vector3(0, 1.38, 0))
	var head := Node3D.new()
	head.position = Vector3(0, 1.05, 0.25)
	body.add_child(head)
	_eyes(head, 0.0, 0.0, 0.1, 0.13, -0.4)
	Kit.part(head, Kit.SPH, _m(Color("2a1a1a")), Vector3(0.12, 0.06, 0.03), Vector3(0, -0.16, 0.02))
	_shadow(g, 0.9)
	return {"root": g, "body": body, "head": head, "wings": [], "wheels": []}


## Стиралка-центрифуга: a small washing machine on legs; the drum spins behind the round glass door
static func washer() -> Dictionary:
	Kit.init()
	var g := Node3D.new()
	var body := Node3D.new()
	g.add_child(body)
	var white := _m(Color("eef0f4"), 0.35, 0.1)
	Kit.part(body, Kit.BOX, white, Vector3(1.3, 1.4, 1.1), Vector3(0, 0.95, 0))
	Kit.part(body, Kit.BOX, _m(Color("c8ccd8"), 0.4), Vector3(1.32, 0.26, 1.12), Vector3(0, 1.78, 0))
	var head := Node3D.new()
	head.position = Vector3(0, 1.78, 0.56)
	body.add_child(head)
	for k in [-1, 1]:
		Kit.part(head, Kit.BOX, Kit.neon(Color("ff3a4a"), 3.0), Vector3(0.2, 0.06, 0.02), Vector3(0.22 * k, 0.02, 0.01), Vector3(0, 0, -0.3 * k))
	Kit.part(head, Kit.CYL, _m(Color("8a92a2"), 0.3, 0.8), Vector3(0.16, 0.06, 0.16), Vector3(0.48, 0, 0.02), Vector3(PI / 2, 0, 0))
	Kit.torus(body, _m(Color("b8c0cc"), 0.2, 0.9), 0.36, 0.46, Vector3(0, 0.9, 0.56), Vector3(PI / 2, 0, 0))
	var drum := Node3D.new()
	drum.position = Vector3(0, 0.9, 0.5)
	body.add_child(drum)
	Kit.part(drum, Kit.CYL, _m(Color("2a3a5a"), 0.4), Vector3(0.72, 0.04, 0.72), Vector3.ZERO, Vector3(PI / 2, 0, 0))
	for k in range(3):
		var a := k * TAU / 3.0
		Kit.part(drum, Kit.SPH, _m([Color("e8323c"), Color("3a7ac8"), Color("f2c21a")][k], 0.9), Vector3(0.18, 0.12, 0.06), Vector3(sin(a) * 0.2, cos(a) * 0.2, 0.03))
	Kit.part(body, Kit.CYL, _glass(Color("bfe4ff"), 0.3), Vector3(0.74, 0.04, 0.74), Vector3(0, 0.9, 0.57), Vector3(PI / 2, 0, 0))
	var legs := []
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			legs.append(Kit.part(body, Kit.CYL, _m(Color("3a3e48"), 0.4, 0.6), Vector3(0.12, 0.26, 0.12), Vector3(0.5 * sx, 0.13, 0.42 * sz)))
	_shadow(g, 1.6)
	return {"root": g, "body": body, "head": head, "wings": [], "wheels": [drum]}


## Утюг-гладиатор: an iron with a gladiator helmet over its handle and steam vents; charges and «irons» you
static func iron() -> Dictionary:
	Kit.init()
	var g := Node3D.new()
	var body := Node3D.new()
	g.add_child(body)
	var steel := _m(Color("c8ccd4"), 0.15, 0.95)
	var plate := PrismMesh.new()
	Kit.part(body, plate, steel, Vector3(1.0, 1.5, 0.22), Vector3(0, 0.15, 0.15), Vector3(-PI / 2, 0, 0))
	Kit.part(body, Kit.BOX, steel, Vector3(1.0, 0.22, 0.8), Vector3(0, 0.15, -0.35))
	Kit.part(body, Kit.SPH, _m(Color("3a7ac8"), 0.35, 0.3), Vector3(0.95, 0.62, 1.5), Vector3(0, 0.48, -0.05))
	var head := Node3D.new()
	head.position = Vector3(0, 0.62, 0.62)
	body.add_child(head)
	_eyes(head, 0.0, 0.0, 0.16, 0.14, 0.45)
	# handle with a gladiator helmet and a red crest
	Kit.part(body, Kit.BOX, _m(Color("22232b"), 0.4), Vector3(0.16, 0.5, 0.16), Vector3(0, 0.95, -0.45))
	Kit.part(body, Kit.BOX, _m(Color("22232b"), 0.4), Vector3(0.16, 0.16, 0.9), Vector3(0, 1.2, -0.1))
	Kit.part(body, Kit.SPH, _m(Color("d8a43a"), 0.25, 0.9), Vector3(0.5, 0.4, 0.55), Vector3(0, 1.36, -0.1))
	for k in range(5):
		Kit.part(body, Kit.BOX, _m(Color("d8322c"), 0.8), Vector3(0.08, 0.22, 0.1), Vector3(0, 1.6, -0.34 + k * 0.12))
	var vents := []
	for k in [-1, 1]:
		var v := Kit.part(body, Kit.SPH, Kit.glow_material(Color(1, 1, 1), 0.3), Vector3.ONE * 0.24, Vector3(0.28 * k, 0.1, -0.7))
		v.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		vents.append(v)
	_shadow(g, 1.3)
	return {"root": g, "body": body, "head": head, "wings": vents, "wheels": []}


## Пена-пузырь: a rainbow soap bubble with a face inside and foam at the bottom; pops when it reaches you
static func bubble() -> Dictionary:
	Kit.init()
	var g := Node3D.new()
	var body := Node3D.new()
	body.position = Vector3(0, 1.2, 0)
	g.add_child(body)
	var film := StandardMaterial3D.new()
	film.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	film.albedo_color = Color(0.85, 0.95, 1.0, 0.22)
	film.roughness = 0.02
	film.metallic = 0.4
	film.rim_enabled = true
	film.rim = 1.0
	film.rim_tint = 1.0
	film.emission_enabled = true
	film.emission = Color("ff9ad0")
	film.emission_energy_multiplier = 0.25
	Kit.part(body, Kit.SPH, film, Vector3.ONE * 1.25)
	var head := Node3D.new()
	head.position = Vector3(0, 0.02, 0.3)
	body.add_child(head)
	_eyes(head, 0.05, 0.0, 0.12, 0.12)
	Kit.part(head, Kit.SPH, _m(Color("ff7aa8"), 0.4), Vector3(0.14, 0.08, 0.04), Vector3(0, -0.14, 0.02))
	var foam := []
	for k in range(6):
		var a := k * TAU / 6.0
		foam.append(Kit.part(body, Kit.SPH, _m(Color("ffffff"), 0.9), Vector3.ONE * 0.26, Vector3(sin(a) * 0.36, -0.6, cos(a) * 0.36)))
	Kit.part(body, Kit.SPH, Kit.glow_material(Color(1, 1, 1), 0.5), Vector3(0.24, 0.16, 0.05), Vector3(-0.28, 0.32, 0.5))
	_shadow(g, 0.9)
	return {"root": g, "body": body, "head": head, "wings": foam, "wheels": []}


## A sock shot by the Барабан Судьбы
static func sock_shot() -> Node3D:
	var n := Node3D.new()
	var c: Color = [Color("e8323c"), Color("3a7ac8"), Color("2a9a5a"), Color("ffd23a")][randi() % 4]
	Kit.part(n, Kit.CAP, Kit.mat(c, 0.9), Vector3(0.7, 0.8, 0.7), Vector3.ZERO, Vector3(PI / 2, 0, 0))
	Kit.part(n, Kit.CYL, Kit.mat(Color("f4f4f4"), 0.9), Vector3(0.2, 0.08, 0.2), Vector3(0, 0, -0.2), Vector3(PI / 2, 0, 0))
	return n


## A blob of hot cheburek juice (shot)
static func juice_shot() -> Node3D:
	var n := Node3D.new()
	Kit.part(n, Kit.SPH, Kit.mat(Color("ffcc33"), 0.1, 0.0, Color("ffaa22"), 1.2), Vector3.ONE * 0.32)
	return n


# =================================================================== bosses
## Тесто Вечности: a huge living blob of magic dough with flour patches, a rolling-pin brow and two dough arms
static func dough() -> Dictionary:
	Kit.init()
	var g := Node3D.new()
	var body := Node3D.new()
	g.add_child(body)
	var dm := _m(Color("f2e2bf"), 0.85)
	var dm2 := _m(Color("ead4a8"), 0.85)
	Kit.part(body, Kit.SPH, dm, Vector3(4.2, 3.2, 3.6), Vector3(0, 1.5, 0))
	var lumps := []
	for k in range(7):
		var a := k * TAU / 7.0
		lumps.append(Kit.part(body, Kit.SPH, dm2 if k % 2 else dm, Vector3.ONE * (1.1 + (k % 3) * 0.25), Vector3(sin(a) * 1.6, 0.5 + (k % 2) * 0.6, cos(a) * 1.4)))
	Kit.part(body, Kit.SPH, dm, Vector3(2.4, 1.6, 2.2), Vector3(0, 3.0, -0.2))
	for k in range(9):
		var a2 := k * 0.9
		Kit.part(body, Kit.SPH, _m(Color("ffffff"), 1.0), Vector3(0.5, 0.12, 0.4), Vector3(sin(a2) * 1.2, 3.3 + cos(a2) * 0.3, cos(a2) * 1.0 - 0.2))
	var head := Node3D.new()
	head.position = Vector3(0, 2.2, 1.55)
	body.add_child(head)
	for k in [-1, 1]:
		Kit.part(head, Kit.SPH, _m(Color("2a1a14"), 0.3), Vector3(0.42, 0.5, 0.2), Vector3(0.6 * k, 0.3, 0.08))
		Kit.part(head, Kit.SPH, Kit.mat(Color("ffffff"), 0.2, 0.0, Color("ffffff"), 0.4), Vector3.ONE * 0.12, Vector3(0.62 * k + 0.06, 0.4, 0.2))
	# the rolling pin brow
	Kit.part(head, Kit.CYL, _m(Color("b8844a"), 0.6), Vector3(0.24, 2.0, 0.24), Vector3(0, 0.85, 0.1), Vector3(0, 0, PI / 2 - 0.12))
	for k in [-1, 1]:
		Kit.part(head, Kit.CYL, _m(Color("8a5a2a"), 0.6), Vector3(0.12, 0.36, 0.12), Vector3(1.15 * k, 0.85 + 0.14 * k, 0.1), Vector3(0, 0, PI / 2 - 0.12))
	var mouth := Node3D.new()   # a pivot: bake_tree keeps it, so the mouth can open
	mouth.position = Vector3(0, -0.45, 0.05)
	head.add_child(mouth)
	Kit.part(mouth, Kit.SPH, _m(Color("6a3a2a"), 0.6), Vector3(1.0, 0.36, 0.2))
	var arms := []
	for k in [-1, 1]:
		var a3 := Node3D.new()
		a3.position = Vector3(2.0 * k, 1.8, 0.3)
		body.add_child(a3)
		Kit.part(a3, Kit.CAP, dm, Vector3(2.4, 3.2, 2.4), Vector3(0.5 * k, -0.6, 0.3), Vector3(0.4, 0, 0.7 * k))
		Kit.part(a3, Kit.SPH, dm2, Vector3(0.9, 0.8, 0.9), Vector3(0.95 * k, -1.35, 0.7))
		arms.append(a3)
	_shadow(g, 5.4)
	return {"root": g, "body": body, "head": head, "wings": arms, "wheels": lumps, "mouth": mouth}


## Барабан Судьбы: a giant front-loading washing machine of forgetfulness, «ОТЖИМ 1400» on its display;
## socks spin in the drum behind the porthole
static func drum() -> Dictionary:
	Kit.init()
	var g := Node3D.new()
	var body := Node3D.new()
	g.add_child(body)
	var white := _m(Color("eef0f4"), 0.35, 0.1)
	var chrome := _m(Color("c8d0dc"), 0.15, 0.95)
	Kit.part(body, Kit.BOX, white, Vector3(5.2, 5.0, 4.0), Vector3(0, 3.0, 0))
	Kit.part(body, Kit.BOX, _m(Color("d8dce4"), 0.4), Vector3(5.3, 0.4, 4.1), Vector3(0, 0.3, 0))
	# the control panel = the face
	var head := Node3D.new()
	head.position = Vector3(0, 5.0, 2.02)
	body.add_child(head)
	Kit.part(head, Kit.BOX, _m(Color("2a2e3a"), 0.3, 0.2), Vector3(4.8, 0.95, 0.06))
	Kit.part(head, Kit.BOX, Kit.neon(Color("4ad8ff"), 1.4), Vector3(1.6, 0.42, 0.04), Vector3(0.7, 0.05, 0.03))
	Chars.label(head, "ОТЖИМ 1400", 90, Color(1.6, 3.2, 3.6), Vector3(0.7, 0.05, 0.07), Vector3.ZERO, 0.0062, 0)
	for k in [-1, 1]:
		Kit.part(head, Kit.BOX, Kit.neon(Color("ff3a4a"), 3.6), Vector3(0.44, 0.12, 0.04), Vector3(-1.4 + 0.42 * k, 0.12, 0.04), Vector3(0, 0, -0.35 * k))
	Kit.part(head, Kit.CYL, chrome, Vector3(0.5, 0.18, 0.5), Vector3(-2.1, -0.02, 0.06), Vector3(PI / 2, 0, 0))
	Kit.part(head, Kit.CYL, chrome, Vector3(0.36, 0.18, 0.36), Vector3(1.95, -0.02, 0.06), Vector3(PI / 2, 0, 0))
	# the porthole and the drum with socks
	Kit.torus(body, chrome, 1.45, 1.75, Vector3(0, 2.55, 2.02), Vector3(PI / 2, 0, 0))
	var drum := Node3D.new()
	drum.position = Vector3(0, 2.55, 1.9)
	body.add_child(drum)
	Kit.part(drum, Kit.CYL, _m(Color("1a2236"), 0.4, 0.4), Vector3(2.9, 0.06, 2.9), Vector3.ZERO, Vector3(PI / 2, 0, 0))
	for k in range(6):
		var a := k * TAU / 6.0
		var c: Color = [Color("e8323c"), Color("3a7ac8"), Color("2a9a5a"), Color("ffd23a"), Color("ff9ad0"), Color("f4f4f4")][k]
		Kit.part(drum, Kit.CAP, _m(c, 0.9), Vector3(0.9, 0.9, 0.9), Vector3(sin(a) * 0.85, cos(a) * 0.85, 0.12), Vector3(0, 0, a))
	for k in range(3):
		var a2 := k * TAU / 3.0
		Kit.part(drum, Kit.BOX, _m(Color("8a92a2"), 0.3, 0.8), Vector3(0.18, 0.5, 0.14), Vector3(sin(a2) * 1.25, cos(a2) * 1.25, 0.08), Vector3(0, 0, -a2))
	var glass := Kit.part(body, Kit.CYL, _glass(Color("bfe4ff"), 0.28), Vector3(2.95, 0.06, 2.95), Vector3(0, 2.55, 2.05), Vector3(PI / 2, 0, 0))
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# the detergent drawer and the hose «tail»
	Kit.part(body, Kit.BOX, _m(Color("d8dce4"), 0.4), Vector3(1.2, 0.36, 0.1), Vector3(-1.7, 4.3, 2.04))
	Kit.part(body, Kit.CYL, _m(Color("8a92a2"), 0.5), Vector3(0.3, 2.4, 0.3), Vector3(2.4, 1.2, -2.2), Vector3(0.7, 0, 0))
	var feet := []
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			feet.append(Kit.part(body, Kit.CYL, _m(Color("3a3e48"), 0.4, 0.6), Vector3(0.5, 0.5, 0.5), Vector3(2.1 * sx, 0.1, 1.6 * sz)))
	_shadow(g, 6.6)
	return {"root": g, "body": body, "head": head, "wings": feet, "wheels": [drum], "glass": glass}


# =================================================================== people
## Тётя Сочня: the plump owner of the Чебуречная in a flowered apron and a red headscarf, with a spatula
static func sochnya() -> Dictionary:
	var h := Chars.human({"top": Color("e8a8b8"), "pants": Color("3a2a3a"), "shoes": Color("6a3a2a"), "hair": "headscarf", "scarf": Color("d8322c"),
		"skirt": true, "skirt_color": Color("6a2a3a"), "width": 1.28, "smirk": 0.3, "skin": Color("f0b894")})
	Kit.part(h.body, Kit.BOX, _m(Color("f8f4ee"), 0.8), Vector3(0.78, 0.86, 0.06), Vector3(0, 0.82, 0.36))
	for p in [Vector3(-0.2, 1.0, 0.4), Vector3(0.18, 0.78, 0.4), Vector3(-0.1, 0.55, 0.4), Vector3(0.22, 1.1, 0.4)]:
		Kit.part(h.body, Kit.SPH, _m(Color("e8323c"), 0.6), Vector3.ONE * 0.1, p)
	for k in [-1, 1]:
		Kit.part(h.head, Kit.SPH, _m(Color("f08a8a"), 0.7), Vector3(0.16, 0.1, 0.05), Vector3(0.2 * k, -0.08, 0.3))
	var sp := Node3D.new()
	h.hands[1].add_child(sp)
	Kit.part(sp, Kit.CYL, _m(Color("6a4a2a"), 0.7), Vector3(0.05, 0.5, 0.05), Vector3(0, -0.05, 0.12), Vector3(0.6, 0, 0))
	Kit.part(sp, Kit.BOX, _m(Color("c8ccd4"), 0.2, 0.9), Vector3(0.2, 0.02, 0.24), Vector3(0, 0.12, 0.32), Vector3(0.6, 0, 0))
	return h


## Пельмень Недоеденный: a talking dumpling with a bite missing, on a plate (placed on a high table)
static func pelmen() -> Dictionary:
	Kit.init()
	var g := Node3D.new()
	var body := Node3D.new()
	body.position = Vector3(0, 1.08, 0)
	g.add_child(body)
	Kit.part(body, Kit.CYL, _m(Color("f8f8f8"), 0.3), Vector3(0.9, 0.04, 0.9), Vector3(0, 0, 0))
	Kit.part(body, Kit.CYL, _m(Color("3a7ac8"), 0.3), Vector3(0.92, 0.02, 0.92), Vector3(0, 0.025, 0))
	var head := Node3D.new()
	head.position = Vector3(0, 0.22, 0)
	body.add_child(head)
	var dm := _m(Color("f4e6c8"), 0.8)
	Kit.part(head, Kit.SPH, dm, Vector3(0.62, 0.38, 0.48))
	for k in range(6):
		Kit.part(head, Kit.SPH, _m(Color("ead6b0"), 0.8), Vector3(0.12, 0.12, 0.1), Vector3(-0.22 + k * 0.09, 0.17, 0))
	# the bite: a darker hollow on the right side
	Kit.part(head, Kit.SPH, _m(Color("d8a86a"), 0.9), Vector3(0.26, 0.26, 0.3), Vector3(0.28, 0.02, 0.02))
	Kit.part(head, Kit.SPH, _m(Color("8a5a3a"), 0.9), Vector3(0.14, 0.14, 0.18), Vector3(0.33, 0.02, 0.02))
	_eyes(head, 0.04, 0.2, 0.09, 0.09)
	Kit.part(head, Kit.SPH, _m(Color("6a2a2a"), 0.5), Vector3(0.1, 0.04, 0.03), Vector3(-0.02, -0.07, 0.23))
	# a dab of sour cream («уважение»)
	Kit.part(body, Kit.SPH, _m(Color("ffffff"), 0.6), Vector3(0.18, 0.08, 0.16), Vector3(-0.28, 0.06, 0.12))
	return {"root": g, "body": body, "head": head}


## Сантехник Вентилёв: blue overalls, a cap, a moustache, a huge adjustable wrench and a bucket to sit on
static func ventilev() -> Dictionary:
	var h := Chars.human({"top": Color("2a5ab8"), "pants": Color("2a4a8a"), "shoes": Color("2a2a2a"), "hair": "cap_back", "hair_color": Color("e8a83a"),
		"smirk": 0.2, "skin": Color("e8b08a")})
	Kit.part(h.head, Kit.BOX, _m(Color("5a3a24"), 0.8), Vector3(0.36, 0.08, 0.06), Vector3(0, -0.11, 0.33))
	for k in [-1, 1]:
		Kit.part(h.body, Kit.BOX, _m(Color("2a4a8a"), 0.8), Vector3(0.1, 0.5, 0.04), Vector3(0.22 * k, 1.1, 0.3))
		Kit.part(h.body, Kit.SPH, _m(Color("f2c14e"), 0.3, 0.8), Vector3.ONE * 0.06, Vector3(0.22 * k, 0.9, 0.33))
	var wr := Node3D.new()
	h.hands[1].add_child(wr)
	Kit.part(wr, Kit.BOX, _m(Color("c8ccd4"), 0.2, 0.9), Vector3(0.1, 0.7, 0.06), Vector3(0, 0.2, 0.08))
	Kit.part(wr, Kit.BOX, _m(Color("c8ccd4"), 0.2, 0.9), Vector3(0.26, 0.12, 0.08), Vector3(0.06, 0.56, 0.08))
	Kit.part(h.root, Kit.CYL, _m(Color("c8323c"), 0.5), Vector3(0.5, 0.6, 0.5), Vector3(-0.6, 0.3, -0.3))
	return h


## Тамара Ресепшн: strict receptionist in a navy uniform, a bun, glasses and a headset — «нет талончика — нет стирки»
static func tamara() -> Dictionary:
	var h := Chars.human({"top": Color("1d2b4a"), "pants": Color("1a1a24"), "shoes": Color("1a1a1a"), "hair": "bun", "hair_color": Color("7a3a1a"),
		"skirt": true, "skirt_color": Color("1d2b4a"), "smirk": -0.05, "brow": Color("5a2a14")})
	var fr := _m(Color("15161c"), 0.3)
	for k in [-1, 1]:
		Kit.part(h.head, Kit.CYL, fr, Vector3(0.18, 0.02, 0.18), Vector3(0.13 * k, 0.03, 0.34), Vector3(PI / 2, 0, 0))
	Kit.torus(h.head, fr, 0.34, 0.37, Vector3(0, 0.08, 0), Vector3(0, 0, PI / 2))
	Kit.part(h.head, Kit.CYL, fr, Vector3(0.02, 0.26, 0.02), Vector3(-0.32, -0.12, 0.2), Vector3(0.9, 0.4, 0))
	Kit.part(h.body, Kit.BOX, _m(Color("f2c14e"), 0.3, 0.6), Vector3(0.2, 0.08, 0.02), Vector3(0.2, 1.2, 0.29))
	Kit.part(h.body, Kit.BOX, _m(Color("f8f4ee"), 0.7), Vector3(0.2, 0.3, 0.02), Vector3(0, 1.15, 0.28))
	return h


## Режиссёр Дубль Дублевич: a beret, a long red scarf, sunglasses up on his head and a megaphone
static func dublevich() -> Dictionary:
	var h := Chars.human({"top": Color("2a2a30"), "pants": Color("4a4a54"), "shoes": Color("8a5a2a"), "hair": "slick", "hair_color": Color("3a2a22"),
		"smirk": 0.35, "skin": Color("e8b48a")})
	Kit.part(h.head, Kit.SPH, _m(Color("1a1a1e"), 0.9), Vector3(0.78, 0.22, 0.74), Vector3(0.06, 0.34, -0.02), Vector3(0, 0, -0.25))
	Kit.part(h.head, Kit.BOX, _m(Color("15161c"), 0.2), Vector3(0.56, 0.1, 0.06), Vector3(0, 0.3, 0.28))
	Kit.torus(h.body, _m(Color("d8322c"), 0.9), 0.26, 0.36, Vector3(0, 1.36, 0.02), Vector3(PI / 2, 0, 0))
	Kit.part(h.body, Kit.BOX, _m(Color("d8322c"), 0.9), Vector3(0.16, 0.9, 0.06), Vector3(0.16, 0.92, 0.3), Vector3(0, 0, 0.1))
	var mega := Node3D.new()
	h.hands[1].add_child(mega)
	var horn := CylinderMesh.new()
	horn.top_radius = 0.06
	horn.bottom_radius = 0.22
	horn.height = 0.5
	Kit.part(mega, horn, _m(Color("f2c21a"), 0.4), Vector3.ONE, Vector3(0, 0.0, 0.25), Vector3(PI / 2, 0, 0))
	return h


## Отличный Чел: tall, a white coat over a tracksuit, a stethoscope with soft pads like headphones, thumb up
static func chel() -> Dictionary:
	var h := Chars.human({"top": Color("f8f8fa"), "pants": Color("2a4a9a"), "shoes": Color("f4f4f4"), "hair": "short", "hair_color": Color("3a2418"),
		"smirk": 0.45, "scale": Vector3(1.06, 1.08, 1.06), "stripe": true})
	Kit.part(h.body, Kit.BOX, _m(Color("2a4a9a"), 0.8), Vector3(0.36, 0.5, 0.04), Vector3(0, 1.0, 0.27))
	Kit.torus(h.body, _m(Color("2a2a34"), 0.4), 0.2, 0.25, Vector3(0, 1.28, 0.06), Vector3(PI / 2 - 0.4, 0, 0))
	Kit.part(h.body, Kit.CYL, _m(Color("c8ccd4"), 0.2, 0.9), Vector3(0.14, 0.06, 0.14), Vector3(0.1, 0.92, 0.3), Vector3(PI / 2, 0, 0))
	for k in [-1, 1]:
		Kit.part(h.head, Kit.SPH, _m(Color("ff5d7a"), 0.6), Vector3(0.14, 0.18, 0.14), Vector3(0.36 * k, 0.0, 0))
	Kit.part(h.body, Kit.BOX, Kit.neon(Color("ff3a4a"), 2.0), Vector3(0.14, 0.04, 0.02), Vector3(-0.2, 1.2, 0.3))
	Kit.part(h.body, Kit.BOX, Kit.neon(Color("ff3a4a"), 2.0), Vector3(0.04, 0.14, 0.02), Vector3(-0.2, 1.2, 0.3))
	# thumb up
	h.arms[0].rotation = Vector3(-1.2, 0, -0.2)
	Kit.part(h.hands[0], Kit.CAP, _m(Color("e9b48a"), 0.55), Vector3(0.24, 0.36, 0.24), Vector3(0, 0.12, 0.04))
	return h


## Отличная Особь: quick and loud, pink scrubs, a cap with a red cross, a heart-shaped medkit and a tablet with heart stickers
static func osob() -> Dictionary:
	var h := Chars.human({"top": Color("ff8ab8"), "pants": Color("ff8ab8"), "shoes": Color("f4f4f4"), "hair": "bun", "hair_color": Color("e8b44a"),
		"smirk": 0.4})
	Kit.part(h.head, Kit.CYL, _m(Color("f8f8fa"), 0.7), Vector3(0.6, 0.18, 0.6), Vector3(0, 0.34, -0.02))
	Kit.part(h.head, Kit.BOX, _m(Color("e8323c")), Vector3(0.16, 0.05, 0.02), Vector3(0, 0.36, 0.3))
	Kit.part(h.head, Kit.BOX, _m(Color("e8323c")), Vector3(0.05, 0.16, 0.02), Vector3(0, 0.36, 0.3))
	var kit := Node3D.new()
	h.hands[1].add_child(kit)
	for k in [-1, 1]:
		Kit.part(kit, Kit.SPH, _m(Color("e8323c"), 0.4), Vector3(0.26, 0.26, 0.16), Vector3(0.09 * k, -0.02, 0.12))
	Kit.part(kit, Kit.CONE, _m(Color("e8323c"), 0.4), Vector3(0.36, 0.26, 0.16), Vector3(0, -0.18, 0.12), Vector3(PI, 0, 0))
	Kit.part(kit, Kit.BOX, _m(Color("f8f8fa")), Vector3(0.12, 0.04, 0.02), Vector3(0, -0.04, 0.21))
	Kit.part(kit, Kit.BOX, _m(Color("f8f8fa")), Vector3(0.04, 0.12, 0.02), Vector3(0, -0.04, 0.21))
	var tab := Node3D.new()
	h.hands[0].add_child(tab)
	Kit.part(tab, Kit.BOX, _m(Color("2a2c34"), 0.4), Vector3(0.24, 0.32, 0.03), Vector3(0, 0.0, 0.12), Vector3(-0.4, 0, 0))
	Kit.part(tab, Kit.BOX, Kit.neon(Color("ff9ad0"), 1.4), Vector3(0.08, 0.08, 0.01), Vector3(0.05, 0.05, 0.14), Vector3(-0.4, 0, 0))
	return h


## Бог Здорово in the sky: a huge kind face — cloud beard, sun halo, rosy cheeks, a white-and-gold tracksuit collar
static func god_face() -> Dictionary:
	Kit.init()
	var g := Node3D.new()
	var body := Node3D.new()
	g.add_child(body)
	var skin := Kit.mat(Color("f6c8a0"), 0.6, 0.0, Color("f6c8a0"), 0.25)
	var cloud := Kit.mat(Color("ffffff"), 0.9, 0.0, Color("ffffff"), 0.5)
	Kit.part(body, Kit.SPH, skin, Vector3(4.2, 4.6, 3.6), Vector3(0, 0, 0))
	for k in range(14):
		var a := -PI * 0.15 + k * (PI * 1.3) / 13.0
		Kit.part(body, Kit.SPH, cloud, Vector3.ONE * (1.3 + (k % 3) * 0.35), Vector3(cos(a) * 1.9, -1.4 - sin(a) * 1.2, 1.1 + (k % 2) * 0.3))
	for k in range(6):
		Kit.part(body, Kit.SPH, cloud, Vector3.ONE * (1.1 + (k % 2) * 0.4), Vector3(-1.5 + k * 0.6, 2.1 + (k % 2) * 0.3, 0.6))
	for k in [-1, 1]:
		Kit.part(body, Kit.SPH, Kit.mat(Color("ff8a8a"), 0.7, 0.0, Color("ff8a8a"), 0.3), Vector3(0.9, 0.6, 0.3), Vector3(1.15 * k, -0.15, 1.62))
		# kind closed eyes — little arcs
		Kit.torus(body, _m(Color("3a2418")), 0.28, 0.36, Vector3(0.75 * k, 0.55, 1.7), Vector3(PI / 2, 0, 0))
	Kit.part(body, Kit.SPH, _m(Color("8a3a2a"), 0.5), Vector3(1.2, 0.55, 0.3), Vector3(0, -0.75, 1.68))
	Kit.part(body, Kit.SPH, skin, Vector3(0.5, 0.45, 0.45), Vector3(0, 0.05, 1.85))
	var halo := Node3D.new()
	halo.position = Vector3(0, 0.6, -0.6)
	body.add_child(halo)
	Kit.torus(halo, Kit.neon(Color("ffd23a"), 3.0), 3.3, 3.7, Vector3.ZERO, Vector3(PI / 2, 0, 0))
	for k in range(12):
		var a2 := k * TAU / 12.0
		Kit.part(halo, Kit.BOX, Kit.neon(Color("ffe08a"), 2.4), Vector3(0.24, 1.2, 0.1), Vector3(sin(a2) * 4.4, cos(a2) * 4.4, 0), Vector3(0, 0, -a2))
	Kit.part(body, Kit.CYL, Kit.mat(Color("f8f8fa"), 0.5, 0.0, Color("f8f8fa"), 0.3), Vector3(3.8, 0.7, 3.2), Vector3(0, -2.9, 0))
	Kit.part(body, Kit.CYL, Kit.neon(Color("ffd23a"), 1.6), Vector3(3.85, 0.18, 3.25), Vector3(0, -2.65, 0))
	return {"root": g, "body": body, "head": body, "halo": halo}


# =================================================================== props
## Скамейка Здорово: a green bench with a golden arch «ЗДОРОВО!» and a little sun; it glows when a blessing is waiting
static func bench(parent: Node3D, at: Vector3, rot: float, with_seat := true) -> Dictionary:
	Kit.init()
	var b := Node3D.new()
	b.position = at
	b.rotation.y = rot
	parent.add_child(b)
	if with_seat:
		Kit.part(b, Kit.BOX, _m(Color("3a8a5a"), 0.7), Vector3(2.2, 0.08, 0.5), Vector3(0, 0.5, 0))
		Kit.part(b, Kit.BOX, _m(Color("3a8a5a"), 0.7), Vector3(2.2, 0.5, 0.08), Vector3(0, 0.85, -0.25))
		for x in [-0.9, 0.9]:
			Kit.part(b, Kit.BOX, _m(Color("2a2a2a")), Vector3(0.08, 0.5, 0.5), Vector3(x, 0.25, 0))
	var gold := Kit.mat(Color("f2c14e"), 0.25, 0.9)
	for x in [-1.15, 1.15]:
		Kit.part(b, Kit.CYL, gold, Vector3(0.08, 2.0, 0.08), Vector3(x, 1.0, -0.36))
	Kit.torus(b, gold, 1.08, 1.18, Vector3(0, 2.0, -0.36), Vector3(PI / 2, 0, 0)).scale = Vector3(1.0, 1.0, 0.45)
	Kit.part(b, Kit.SPH, Kit.neon(Color("ffd23a"), 2.6), Vector3.ONE * 0.34, Vector3(0, 2.55, -0.36))
	Chars.label(b, "ЗДОРОВО!", 70, Color(3.2, 2.6, 1.2), Vector3(0, 2.15, -0.3), Vector3.ZERO, 0.0062, 6)
	var glow := Chars.ring(b, Vector3(0, 0.05, 0.6), 1.3, Color("ffd23a"), 0.08, 2.6)
	return {"node": b, "glow": glow}


## Скорая «Отлично-03»: a white van with a red stripe, a blue light bar and a heart on the side
static func ambulance(parent: Node3D, at: Vector3, rot: float) -> Node3D:
	Kit.init()
	var v := Node3D.new()
	v.position = at
	v.rotation.y = rot
	parent.add_child(v)
	var white := _m(Color("f4f6fa"), 0.35, 0.2)
	Kit.part(v, Kit.BOX, white, Vector3(2.2, 2.2, 4.0), Vector3(0, 1.45, -0.6))
	Kit.part(v, Kit.BOX, white, Vector3(2.2, 1.5, 1.6), Vector3(0, 1.1, 2.2))
	Kit.part(v, Kit.BOX, _glass(Color("8ac8ff"), 0.6), Vector3(2.0, 0.7, 0.05), Vector3(0, 1.55, 3.0), Vector3(-0.25, 0, 0))
	for k in [-1, 1]:
		Kit.part(v, Kit.BOX, _m(Color("e8323c"), 0.5), Vector3(0.02, 0.3, 5.6), Vector3(1.11 * k, 1.1, 0.2))
		Kit.part(v, Kit.BOX, _glass(Color("8ac8ff"), 0.6), Vector3(0.02, 0.6, 0.9), Vector3(1.11 * k, 1.55, 2.2))
		Chars.label(v, "ОТЛИЧНО-03", 70, Color("e8323c"), Vector3(1.12 * k, 2.0, -0.6), Vector3(0, PI / 2 * k, 0), 0.007, 0)
		for z in [-1.8, 1.9]:
			Kit.part(v, Kit.CYL, _m(Color("1a1a1e"), 0.8), Vector3(0.8, 0.3, 0.8), Vector3(1.05 * k, 0.4, z), Vector3(0, 0, PI / 2))
	for k in [-1, 1]:
		Kit.part(v, Kit.SPH, _m(Color("e8323c"), 0.4), Vector3(0.36, 0.36, 0.1), Vector3(0.14 * k, 1.75, -2.62))
	Kit.part(v, Kit.CONE, _m(Color("e8323c"), 0.4), Vector3(0.56, 0.36, 0.1), Vector3(0, 1.5, -2.62), Vector3(PI, 0, 0))
	Kit.part(v, Kit.BOX, Kit.neon(Color("4a8aff"), 3.0), Vector3(1.4, 0.16, 0.3), Vector3(0, 2.62, 0.9))
	Kit.part(v, Kit.BOX, Kit.neon(Color("ff3a4a"), 3.0), Vector3(0.3, 0.16, 0.3), Vector3(0.55, 2.63, 0.9))
	Kit.bake_tree(v)
	return v
