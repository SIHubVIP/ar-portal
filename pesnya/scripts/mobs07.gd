class_name Mobs07
## 0.7: models of the park «Заря» — mobs (mower, ghost bag, robo-duck, loading circle) and two new people:
## the guard Подписочкин and Сингл Принц. Mobs return {root, body, head, wings, wheels} like Chars.*

static func _m(c: Color, rough := 0.6, metal := 0.0) -> StandardMaterial3D:
	return Kit.mat(c, rough, metal)


static func _shadow(g: Node3D, r: float) -> void:
	var sh := StandardMaterial3D.new()
	sh.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sh.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sh.albedo_color = Color(0, 0, 0, 0.28)
	Kit.part(g, Kit.DISC, sh, Vector3(r, 1, r), Vector3(0, 0.03, 0))


## Газонокосилка-бунтарь: a red push-mower with angry LED eyes and a spinning blade
static func mower() -> Dictionary:
	Kit.init()
	var g := Node3D.new()
	var body := Node3D.new()
	g.add_child(body)
	var red := _m(Color("d8322c"), 0.45, 0.2)
	var dark := _m(Color("22232b"), 0.5, 0.3)
	Kit.part(body, Kit.BOX, red, Vector3(1.3, 0.34, 1.1), Vector3(0, 0.42, 0))
	Kit.part(body, Kit.BOX, _m(Color("f4f4f4"), 0.6), Vector3(1.34, 0.08, 1.14), Vector3(0, 0.62, 0))
	# grass bag at the back
	Kit.part(body, Kit.BOX, _m(Color("3a5a3a"), 0.9), Vector3(0.9, 0.6, 0.6), Vector3(0, 0.62, -0.75))
	# handle
	for s in [-1, 1]:
		Kit.part(body, Kit.CYL, dark, Vector3(0.06, 1.3, 0.06), Vector3(0.38 * s, 1.05, -0.95), Vector3(-0.55, 0, 0))
	Kit.part(body, Kit.CYL, dark, Vector3(0.08, 0.85, 0.08), Vector3(0, 1.58, -1.3), Vector3(0, 0, PI / 2))
	# engine with the angry face
	var head := Node3D.new()
	head.position = Vector3(0, 0.82, 0.12)
	body.add_child(head)
	Kit.part(head, Kit.CYL, _m(Color("2a8a3a"), 0.5), Vector3(0.62, 0.36, 0.62))
	Kit.part(head, Kit.CYL, dark, Vector3(0.3, 0.12, 0.3), Vector3(0, 0.24, 0))
	for s in [-1, 1]:
		Kit.part(head, Kit.BOX, Kit.neon(Color("ff3a2a"), 3.4), Vector3(0.16, 0.06, 0.03), Vector3(0.13 * s, 0.05, 0.31), Vector3(0, 0, -0.35 * s))
	Kit.part(head, Kit.BOX, _m(Color("f4f4f4"), 0.4), Vector3(0.28, 0.05, 0.03), Vector3(0, -0.08, 0.31))
	# the blade under the deck
	var blade := Node3D.new()
	blade.position = Vector3(0, 0.22, 0.05)
	body.add_child(blade)
	Kit.part(blade, Kit.BOX, _m(Color("c8ccd4"), 0.2, 0.9), Vector3(1.1, 0.03, 0.14))
	Kit.part(blade, Kit.BOX, _m(Color("c8ccd4"), 0.2, 0.9), Vector3(0.14, 0.03, 1.1))
	var wheels := []
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			var w := Node3D.new()
			w.position = Vector3(0.66 * sx, 0.22, 0.4 * sz)
			body.add_child(w)
			Kit.part(w, Kit.CYL, dark, Vector3(0.42, 0.14, 0.42), Vector3.ZERO, Vector3(0, 0, PI / 2))
			Kit.part(w, Kit.CYL, _m(Color("f2c14e"), 0.4, 0.6), Vector3(0.18, 0.16, 0.18), Vector3.ZERO, Vector3(0, 0, PI / 2))
			wheels.append(w)
	_shadow(g, 1.6)
	return {"root": g, "body": body, "head": head, "wings": [blade], "wheels": wheels}


## Пакет-призрак: a floating plastic bag with handles, a «шшш» mouth and a wavy hem
static func bag() -> Dictionary:
	Kit.init()
	var g := Node3D.new()
	var body := Node3D.new()
	body.position = Vector3(0, 1.3, 0)
	g.add_child(body)
	var film := StandardMaterial3D.new()
	film.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	film.albedo_color = Color(0.96, 0.97, 1.0, 0.72)
	film.roughness = 0.15
	film.rim_enabled = true
	film.rim = 0.8
	Kit.part(body, Kit.SPH, film, Vector3(0.95, 1.2, 0.7))
	Kit.part(body, Kit.BOX, Kit.mat(Color("e8323c"), 0.5), Vector3(0.6, 0.12, 0.02), Vector3(0, 0.08, 0.33))
	Chars.label(body, "ТИШИНА+", 40, Color(1, 1, 1), Vector3(0, 0.08, 0.345), Vector3.ZERO, 0.0045, 0)
	var handles := []
	for s in [-1, 1]:
		var h := Node3D.new()
		h.position = Vector3(0.22 * s, 0.55, 0)
		body.add_child(h)
		Kit.torus(h, film, 0.12, 0.2, Vector3(0, 0.12, 0), Vector3(PI / 2, 0, 0))
		handles.append(h)
	var face := Node3D.new()
	face.position = Vector3(0, 0.2, 0.33)
	body.add_child(face)
	for s in [-1, 1]:
		Kit.part(face, Kit.SPH, _m(Color("15161c"), 0.3), Vector3(0.12, 0.17, 0.04), Vector3(0.15 * s, 0.1, 0.01))
	Kit.part(face, Kit.SPH, _m(Color("2a2a34"), 0.4), Vector3(0.18, 0.1, 0.04), Vector3(0, -0.12, 0.01))
	for k in range(4):
		Kit.part(body, Kit.CONE, film, Vector3(0.22, 0.42, 0.22), Vector3(-0.3 + k * 0.2, -0.62, (k % 2) * 0.08), Vector3(PI, 0, 0.2 - k * 0.12))
	_shadow(g, 0.9)
	return {"root": g, "body": body, "head": face, "wings": handles, "wheels": []}


## Робо-утка: a yellow metal duck with a speaker beak and a red visor
static func roboduck() -> Dictionary:
	Kit.init()
	var g := Node3D.new()
	var body := Node3D.new()
	g.add_child(body)
	var yel := _m(Color("f2c21a"), 0.3, 0.5)
	var steel := _m(Color("8a92a2"), 0.3, 0.8)
	Kit.part(body, Kit.SPH, yel, Vector3(1.0, 0.8, 1.25), Vector3(0, 0.75, 0))
	Kit.part(body, Kit.SPH, yel, Vector3(0.4, 0.4, 0.4), Vector3(0, 1.0, -0.6))
	Kit.part(body, Kit.CYL, steel, Vector3(0.7, 0.06, 0.9), Vector3(0, 0.62, 0))
	var head := Node3D.new()
	head.position = Vector3(0, 1.35, 0.42)
	body.add_child(head)
	Kit.part(head, Kit.SPH, yel, Vector3.ONE * 0.62)
	Kit.part(head, Kit.BOX, _m(Color("ff7a1a"), 0.4, 0.3), Vector3(0.34, 0.12, 0.36), Vector3(0, -0.06, 0.38))
	for k in range(3):
		Kit.part(head, Kit.BOX, _m(Color("22232b"), 0.4), Vector3(0.26, 0.015, 0.02), Vector3(0, -0.04 + k * 0.03 - 0.03, 0.565))
	Kit.part(head, Kit.BOX, Kit.neon(Color("ff2a3a"), 3.2), Vector3(0.46, 0.08, 0.06), Vector3(0, 0.1, 0.27))
	Kit.part(head, Kit.CYL, steel, Vector3(0.03, 0.3, 0.03), Vector3(0, 0.42, -0.05))
	Kit.part(head, Kit.SPH, Kit.neon(Color("ff2a3a"), 2.4), Vector3.ONE * 0.08, Vector3(0, 0.58, -0.05))
	var wings := []
	for s in [-1, 1]:
		var w := Node3D.new()
		w.position = Vector3(0.48 * s, 0.85, -0.05)
		body.add_child(w)
		Kit.part(w, Kit.SPH, _m(Color("e0b010"), 0.3, 0.5), Vector3(0.16, 0.42, 0.7), Vector3(0.04 * s, 0, 0))
		wings.append(w)
	var feet := []
	for s in [-1, 1]:
		var f := Node3D.new()
		f.position = Vector3(0.24 * s, 0.32, 0.05)
		body.add_child(f)
		Kit.part(f, Kit.CYL, steel, Vector3(0.08, 0.3, 0.08), Vector3(0, -0.14, 0))
		Kit.part(f, Kit.BOX, _m(Color("ff7a1a"), 0.5), Vector3(0.26, 0.05, 0.34), Vector3(0, -0.3, 0.1))
		feet.append(f)
	_shadow(g, 1.2)
	return {"root": g, "body": body, "head": head, "wings": wings, "wheels": feet}


## Quack wave shot by a robo-duck (a little yellow ring)
static func quack() -> Node3D:
	var n := Node3D.new()
	var r := Chars.ring(n, Vector3.ZERO, 0.32, Color("ffd21a"), 0.07, 3.2)
	r.rotation.x = PI / 2
	Kit.part(n, Kit.SPH, Kit.neon(Color("fff0a0"), 2.0), Vector3.ONE * 0.18)
	return n


## Кружочек загрузки: eight dots running in a circle around a pale core
static func loader() -> Dictionary:
	Kit.init()
	var g := Node3D.new()
	var body := Node3D.new()
	body.position = Vector3(0, 1.0, 0)
	g.add_child(body)
	var ring := Node3D.new()
	body.add_child(ring)
	for k in range(8):
		var a := k * TAU / 8.0
		var c := Color("4ad8ff").lerp(Color("2a3a5a"), k / 8.0)
		Kit.part(ring, Kit.SPH, Kit.neon(c, 2.8 - k * 0.28), Vector3.ONE * (0.36 - k * 0.02), Vector3(sin(a) * 0.72, cos(a) * 0.72, 0))
	var head := Node3D.new()
	body.add_child(head)
	var core := StandardMaterial3D.new()
	core.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	core.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core.albedo_color = Color(0.7, 0.9, 1.0, 0.35)
	Kit.part(head, Kit.SPH, core, Vector3.ONE * 0.62)
	Chars.label(head, "99%", 48, Color(2.4, 2.8, 3.0), Vector3(0, 0, 0.34), Vector3.ZERO, 0.005, 6)
	_shadow(g, 1.0)
	return {"root": g, "body": body, "head": head, "wings": [], "wheels": [ring]}


## Охранник Подписочкин: a sleepy guard of «ООО Тишина Плюс» with a card reader
static func guard() -> Dictionary:
	var h := Chars.human({"top": Color("2a2e3a"), "pants": Color("1e2230"), "shoes": Color("101014"), "hair": "police_cap", "hair_color": Color("4a3a2a"),
		"vest": Color("1a1b22"), "vest_plain": true, "back_text": "ТИШИНА ПЛЮС", "back_color": Color("c8d0e8"), "width": 1.12, "smirk": -0.1})
	Kit.part(h.body, Kit.BOX, Kit.mat(Color("c8d0e8"), 0.4, 0.0, Color("c8d0e8"), 0.4), Vector3(0.26, 0.12, 0.02), Vector3(0.22, 1.2, 0.33))
	var term := Node3D.new()
	h.hands[1].add_child(term)
	Kit.part(term, Kit.BOX, _m(Color("2a2c34"), 0.4), Vector3(0.16, 0.26, 0.06), Vector3(0, -0.12, 0.1), Vector3(-0.5, 0, 0))
	Kit.part(term, Kit.BOX, Kit.neon(Color("46d278"), 2.0), Vector3(0.12, 0.08, 0.01), Vector3(0, -0.06, 0.135), Vector3(-0.5, 0, 0))
	return h


## Сингл Принц: purple velvet jacket with gold epaulettes, a little tilted crown, dark glasses, ONE earbud and a suitcase-counter
static func prince() -> Dictionary:
	var h := Chars.human({"top": Color("5a2a8a"), "top_rough": 0.35, "pants": Color("1a1424"), "shoes": Color("f2c14e"), "hair": "slick",
		"hair_color": Color("1a1424"), "shades": true, "smirk": 0.3, "skin": Color("e8b48a")})
	var gold := Kit.mat(Color("f2c14e"), 0.2, 1.0)
	for s in [-1, 1]:
		Kit.part(h.body, Kit.BOX, gold, Vector3(0.34, 0.06, 0.34), Vector3(0.52 * s, 1.24, 0))
		for k in range(3):
			Kit.part(h.body, Kit.CYL, gold, Vector3(0.03, 0.14, 0.03), Vector3(0.52 * s + (k - 1) * 0.1, 1.16, 0.16))
	for k in range(3):
		Kit.part(h.body, Kit.SPH, gold, Vector3.ONE * 0.06, Vector3(0.0, 1.12 - k * 0.16, 0.36))
	var crown := Node3D.new()
	crown.position = Vector3(0.12, 0.4, 0)
	crown.rotation = Vector3(0, 0, -0.35)
	h.head.add_child(crown)
	Kit.part(crown, Kit.CYL, gold, Vector3(0.34, 0.1, 0.34))
	for k in range(5):
		var a := k * TAU / 5.0
		Kit.part(crown, Kit.CONE, gold, Vector3(0.07, 0.16, 0.07), Vector3(sin(a) * 0.15, 0.12, cos(a) * 0.15))
	Kit.part(crown, Kit.SPH, Kit.neon(Color("ff3a8a"), 2.6), Vector3.ONE * 0.06, Vector3(0, 0.03, 0.17))
	# one earbud («сингл же»)
	Kit.part(h.head, Kit.SPH, _m(Color("f4f4f4"), 0.3), Vector3.ONE * 0.1, Vector3(-0.35, 0.0, 0.02))
	# the suitcase that unfolds into a counter
	var case := Node3D.new()
	case.position = Vector3(0, 0, 0.9)
	h.root.add_child(case)
	Kit.part(case, Kit.BOX, _m(Color("6a3a1a"), 0.5), Vector3(1.3, 0.85, 0.5), Vector3(0, 0.43, 0))
	Kit.part(case, Kit.BOX, gold, Vector3(1.34, 0.06, 0.54), Vector3(0, 0.86, 0))
	Kit.part(case, Kit.BOX, _m(Color("3a1a4a"), 0.8), Vector3(1.2, 0.04, 0.44), Vector3(0, 0.9, 0))
	for k in range(3):
		Kit.part(case, Kit.BOX, Kit.neon([Color("ff5dd0"), Kit.GOLD, Kit.TEAL][k], 2.0), Vector3(0.18, 0.18, 0.18), Vector3(-0.36 + k * 0.36, 1.02, 0), Vector3(0, 0.6 * k, 0))
	Chars.label(case, "ТОЛЬКО СЕГОДНЯ", 48, Color(3.0, 2.4, 1.2), Vector3(0, 0.45, 0.26), Vector3.ZERO, 0.0045, 6)
	return h
