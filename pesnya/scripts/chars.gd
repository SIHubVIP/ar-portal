class_name Chars
## Stylized characters, mobs, boss, mount, robot and props for the «Песня» concept shots.

static var FONT: FontFile

static func _m(c: Color, rough := 0.6, metal := 0.0) -> StandardMaterial3D:
	return Kit.mat(c, rough, metal)


static func glowmat(c: Color, e := 2.0) -> StandardMaterial3D:
	return Kit.mat(c, 0.4, 0.0, c, e)


static func label(parent: Node3D, text: String, size: int, col: Color, pos: Vector3, rot := Vector3.ZERO, px := 0.006, outline := 8) -> Label3D:
	var l := Label3D.new()
	l.text = text
	if FONT == null:
		FONT = load("res://fonts/RussoOne-Regular.ttf")
	l.font = FONT
	l.font_size = size
	l.pixel_size = px
	l.modulate = col
	l.outline_size = outline
	l.outline_modulate = Color(0, 0, 0, 0.6)
	l.position = pos
	l.rotation = rot
	l.double_sided = false
	parent.add_child(l)
	return l


## Humanoid builder. Faces +Z. Returns {root, body, arms:[L,R], legs:[L,R], head, hands:[L,R]}
static func human(o: Dictionary) -> Dictionary:
	Kit.init()
	var root := Node3D.new()
	var body := Node3D.new()
	root.add_child(body)
	var skin := _m(o.get("skin", Color("e9b48a")), 0.55)
	var top := _m(o.get("top", Color("f5b55c")), o.get("top_rough", 0.85))
	var pants := _m(o.get("pants", Color("142a38")), 0.9)
	var shoes := _m(o.get("shoes", Color("f4f1ea")), 0.5)
	var sole := _m(Color("22232b"), 0.6)
	var w: float = o.get("width", 1.0)
	var legs := []
	var arms := []
	var hands := []
	for s in [-1, 1]:
		var hip := Node3D.new()
		hip.position = Vector3(0.17 * s * w, 0.62, 0)
		body.add_child(hip)
		Kit.part(hip, Kit.CAP, pants, Vector3(0.62, 0.6, 0.62), Vector3(0, -0.27, 0))
		Kit.part(hip, Kit.BOX, shoes, Vector3(0.3, 0.17, 0.46), Vector3(0, -0.55, 0.07))
		Kit.part(hip, Kit.BOX, sole, Vector3(0.32, 0.05, 0.48), Vector3(0, -0.63, 0.07))
		legs.append(hip)
		var sh := Node3D.new()
		sh.position = Vector3(0.45 * s * w, 1.2, 0)
		body.add_child(sh)
		Kit.part(sh, Kit.CAP, top, Vector3(0.52, 0.6, 0.52), Vector3(0, -0.27, 0))
		Kit.part(sh, Kit.SPH, skin, Vector3(0.21, 0.21, 0.21), Vector3(0, -0.6, 0))
		var hand := Node3D.new()
		hand.position = Vector3(0, -0.62, 0)
		sh.add_child(hand)
		hands.append(hand)
		arms.append(sh)
	Kit.part(body, Kit.CAP, top, Vector3(1.5 * w, 0.76, 1.0 * w), Vector3(0, 0.95, 0))
	var head := Node3D.new()
	head.position = Vector3(0, 1.6, 0)
	body.add_child(head)
	Kit.part(head, Kit.SPH, skin, Vector3(0.7, 0.68, 0.66))
	# face
	if not o.get("shades", false):
		for s in [-1, 1]:
			Kit.part(head, Kit.SPH, _m(Color("ffffff"), 0.3), Vector3(0.14, 0.16, 0.06), Vector3(0.13 * s, 0.03, 0.31))
			Kit.part(head, Kit.SPH, _m(Color("1a1420"), 0.2), Vector3(0.08, 0.1, 0.04), Vector3(0.13 * s, 0.02, 0.335))
			Kit.part(head, Kit.SPH, glowmat(Color.WHITE, 1.0), Vector3(0.025, 0.025, 0.02), Vector3(0.13 * s + 0.02, 0.05, 0.352))
			Kit.part(head, Kit.BOX, _m(o.get("brow", Color("3a2418"))), Vector3(0.13, 0.03, 0.03), Vector3(0.13 * s, 0.14, 0.32), Vector3(0, 0, -0.18 * s * o.get("angry", 0.0)))
	else:
		var dark := _m(Color("15161c"), 0.3)
		Kit.part(head, Kit.BOX, dark, Vector3(0.56, 0.13, 0.06), Vector3(0, 0.04, 0.3))
		for s in [-1, 1]:
			Kit.part(head, Kit.BOX, Kit.mat(Color("7af0ff"), 0.05, 0.9), Vector3(0.21, 0.1, 0.02), Vector3(0.13 * s, 0.04, 0.335))
	Kit.part(head, Kit.BOX, _m(Color("6a2a2a"), 0.5), Vector3(0.14, 0.035, 0.03), Vector3(0, -0.17, 0.31), Vector3(0, 0, o.get("smirk", 0.15)))
	Kit.part(head, Kit.SPH, skin, Vector3(0.12, 0.1, 0.1), Vector3(0, -0.04, 0.34))
	var hair: String = o.get("hair", "")
	var hc: Color = o.get("hair_color", Color("2a1d17"))
	if hair in ["police_cap", "mohawk", "cap_back"]:
		# short hair on the back and sides of the head
		Kit.part(head, Kit.SPH, _m(hc, 0.85), Vector3(0.72, 0.6, 0.62), Vector3(0, 0.04, -0.07))
	match hair:
		"police_cap":
			var navy := _m(Color("1d2b4a"), 0.6)
			var cap := Node3D.new()
			cap.position = Vector3(0, 0.25, -0.02)
			cap.rotation = Vector3(-0.08, 0, 0.16)
			head.add_child(cap)
			Kit.part(cap, Kit.CYL, navy, Vector3(0.66, 0.14, 0.66), Vector3(0, 0.0, 0))
			Kit.part(cap, Kit.CYL, _m(Color("e3c25a"), 0.3, 0.8), Vector3(0.67, 0.03, 0.67), Vector3(0, -0.05, 0))
			Kit.part(cap, Kit.CYL, navy, Vector3(0.82, 0.1, 0.84), Vector3(0, 0.1, 0.02), Vector3(-0.1, 0, 0))
			Kit.part(cap, Kit.BOX, _m(Color("101015"), 0.2), Vector3(0.5, 0.04, 0.26), Vector3(0, -0.06, 0.38), Vector3(0.35, 0, 0))
			Kit.part(cap, Kit.CYL, Kit.mat(Color("f2c14e"), 0.2, 1.0, Color("f2c14e"), 0.6), Vector3(0.16, 0.03, 0.16), Vector3(0, 0.06, 0.38), Vector3(PI / 2 - 0.1, 0, 0))
		"mohawk":
			for i in range(6):
				var t := i / 5.0
				Kit.part(head, Kit.CONE, glowmat(hc, 0.6), Vector3(0.1, 0.38 - absf(t - 0.4) * 0.25, 0.22), Vector3(0, 0.36 + sin(t * PI) * 0.02, 0.22 - t * 0.5), Vector3(-0.5 + t * 1.0, 0, 0))
		"headscarf":
			var sc := _m(o.get("scarf", Color("c8323c")), 0.85)
			Kit.part(head, Kit.SPH, sc, Vector3(0.8, 0.76, 0.7), Vector3(0, 0.06, -0.07))
			Kit.part(head, Kit.SPH, sc, Vector3(0.16, 0.12, 0.14), Vector3(0.0, -0.32, 0.2))
			for k in range(10):
				var a := k * 0.63
				Kit.part(head, Kit.SPH, _m(Color("fff1c8"), 0.8), Vector3(0.06, 0.06, 0.03), Vector3(sin(a) * 0.38, 0.12 + cos(a * 1.3) * 0.18, -0.07 + cos(a) * 0.3))
		"hood":
			var hd := _m(o.get("top", Color("2f5a3a")), 0.85)
			Kit.part(head, Kit.SPH, hd, Vector3(0.82, 0.8, 0.72), Vector3(0, 0.05, -0.08))
		"beanie":
			Kit.part(head, Kit.SPH, _m(hc, 0.9), Vector3(0.74, 0.5, 0.7), Vector3(0, 0.2, -0.02))
			Kit.part(head, Kit.SPH, _m(hc.lightened(0.3), 0.9), Vector3(0.16, 0.16, 0.16), Vector3(0, 0.46, -0.04))
		"bun":
			Kit.part(head, Kit.SPH, _m(hc, 0.8), Vector3(0.74, 0.5, 0.7), Vector3(0, 0.16, -0.05))
			Kit.part(head, Kit.SPH, _m(hc, 0.8), Vector3(0.3, 0.3, 0.3), Vector3(0, 0.38, -0.2))
		"slick":
			Kit.part(head, Kit.SPH, _m(hc, 0.3), Vector3(0.74, 0.46, 0.72), Vector3(0, 0.18, -0.04))
		"cap_back":
			Kit.part(head, Kit.SPH, _m(hc, 0.7), Vector3(0.72, 0.42, 0.7), Vector3(0, 0.14, -0.02))
			Kit.part(head, Kit.BOX, _m(hc.darkened(0.3), 0.7), Vector3(0.5, 0.05, 0.3), Vector3(0, 0.15, -0.42), Vector3(-0.25, 0, 0))
		_:
			Kit.part(head, Kit.SPH, _m(hc, 0.8), Vector3(0.72, 0.46, 0.7), Vector3(0, 0.15, -0.04))
	if o.get("glasses", false):
		var fr := _m(Color("15161c"), 0.3)
		for s in [-1, 1]:
			Kit.part(head, Kit.BOX, fr, Vector3(0.2, 0.16, 0.03), Vector3(0.13 * s, 0.03, 0.335))
			Kit.part(head, Kit.BOX, glowmat(Color("5cffb0"), 1.6), Vector3(0.16, 0.12, 0.02), Vector3(0.13 * s, 0.03, 0.35))
	if o.get("chain", false):
		var gold := _m(Color("f2c14e"), 0.2, 1.0)
		Kit.torus(body, gold, 0.22, 0.27, Vector3(0, 1.18, 0.12), Vector3(PI / 2 - 0.45, 0, 0))
		Kit.part(body, Kit.CYL, gold, Vector3(0.18, 0.05, 0.18), Vector3(0, 0.98, 0.3), Vector3(PI / 2, 0, 0))
	if o.has("vest"):
		var vc: Color = o.vest
		var vm := _m(vc, 0.7)
		Kit.part(body, Kit.CAP, vm, Vector3(1.62 * w, 0.62, 1.1 * w), Vector3(0, 0.98, 0))
		if not o.get("vest_plain", false):
			var refl := Kit.mat(Color("d8ff3a"), 0.4, 0.0, Color("d8ff3a"), 0.8)
			for yy in [0.84, 1.0]:
				Kit.part(body, Kit.CYL, refl, Vector3(0.83 * w, 0.045, 0.6 * w), Vector3(0, yy, 0))
		if o.has("back_text"):
			label(body, o.back_text, 56, o.get("back_color", Color("f4f6ff")), Vector3(0, 1.17, -0.3), Vector3(0, PI, 0), 0.0032, 4)
	if o.get("jacket_studs", false):
		var st := _m(Color("d0d4dc"), 0.2, 1.0)
		for s in [-1, 1]:
			for k in range(4):
				Kit.part(body, Kit.SPH, st, Vector3.ONE * 0.06, Vector3(s * (0.28 + k * 0.05), 1.26 - k * 0.02, -0.05 + k * 0.05))
	if o.has("armband"):
		var arm: Node3D = arms[0]
		Kit.part(arm, Kit.CYL, _m(Color("f4f4f4")), Vector3(0.3, 0.1, 0.3), Vector3(0, -0.18, 0))
		Kit.part(arm, Kit.BOX, glowmat(Color("2ee88a"), 1.2), Vector3(0.05, 0.08, 0.02), Vector3(-0.15, -0.18, 0.0), Vector3(0, PI / 2, 0))
		Kit.part(arm, Kit.BOX, glowmat(Color("2ee88a"), 1.2), Vector3(0.05, 0.02, 0.08), Vector3(-0.155, -0.18, 0.0))
	if o.get("skirt", false):
		Kit.part(body, Kit.CYL, _m(o.get("skirt_color", Color("6a3b52")), 0.9), Vector3(1.0 * w, 0.55, 0.9 * w), Vector3(0, 0.45, 0))
		var cone := CylinderMesh.new()
		cone.top_radius = 0.3
		cone.bottom_radius = 0.5
		cone.height = 1.0
		Kit.part(body, cone, _m(o.get("skirt_color", Color("6a3b52")), 0.9), Vector3(1.0 * w, 0.6, 0.9 * w), Vector3(0, 0.36, 0))
	if o.get("backpack", false):
		Kit.part(body, Kit.BOX, _m(Color("1a1b22"), 0.5), Vector3(0.56, 0.6, 0.28), Vector3(0, 0.95, -0.4))
		Kit.part(body, Kit.CYL, Kit.neon(Kit.TEAL, 2.0), Vector3(0.2, 0.06, 0.2), Vector3(0, 0.95, -0.55), Vector3(PI / 2, 0, 0))
	if o.get("stripe", false):
		for s in [-1, 1]:
			var leg: Node3D = legs[(s + 1) / 2]
			Kit.part(leg, Kit.BOX, _m(Color("f4f4f4")), Vector3(0.04, 0.5, 0.06), Vector3(0.155 * s, -0.25, 0))
			var arm: Node3D = arms[(s + 1) / 2]
			Kit.part(arm, Kit.BOX, _m(Color("f4f4f4")), Vector3(0.04, 0.45, 0.06), Vector3(0.13 * s, -0.25, 0))
	root.scale = o.get("scale", Vector3.ONE)
	return {"root": root, "body": body, "arms": arms, "legs": legs, "head": head, "hands": hands}


static func pose(h: Dictionary, p: Dictionary) -> void:
	h.arms[0].rotation = p.get("la", Vector3.ZERO)
	h.arms[1].rotation = p.get("ra", Vector3.ZERO)
	h.legs[0].rotation = p.get("ll", Vector3.ZERO)
	h.legs[1].rotation = p.get("rl", Vector3.ZERO)
	h.body.rotation = p.get("body", Vector3.ZERO)
	h.head.rotation = p.get("head", Vector3.ZERO)


# ------------------------------------------------------------------ the cast
static func rapper_cop() -> Dictionary:
	var h := human({"top": Color("f5b55c"), "pants": Color("1d2b4a"), "shoes": Color("f4f1ea"), "hair": "police_cap",
		"shades": true, "chain": true, "vest": Color("24365e"), "back_text": "МС ПАТРУЛЬ", "smirk": 0.25})
	# microphone-baton in the right hand
	var mic := Node3D.new()
	h.hands[1].add_child(mic)
	mic.rotation = Vector3(PI / 2, 0, 0)
	Kit.part(mic, Kit.CYL, _m(Color("15161c"), 0.3), Vector3(0.1, 0.62, 0.1), Vector3(0, 0.2, 0))
	Kit.part(mic, Kit.CYL, _m(Color("f2c14e"), 0.2, 1.0), Vector3(0.14, 0.05, 0.14), Vector3(0, 0.52, 0))
	Kit.part(mic, Kit.SPH, Kit.mat(Color("d8dde6"), 0.2, 1.0, Color("7af0ff"), 0.4), Vector3(0.24, 0.24, 0.24), Vector3(0, 0.62, 0))
	h["mic_tip"] = mic
	return h


static func punk_medic() -> Dictionary:
	var h := human({"top": Color("1c1c22"), "top_rough": 0.35, "pants": Color("3c5a8c"), "shoes": Color("1a1a1a"), "hair": "mohawk",
		"hair_color": Color("ff4fa8"), "jacket_studs": true, "armband": true, "angry": 0.6, "smirk": -0.2, "skin": Color("f0c4a4")})
	# guitar
	var g := Node3D.new()
	g.position = Vector3(0, 0.92, 0.36)
	g.rotation = Vector3(0, 0, -0.9)
	h.body.add_child(g)
	var red := _m(Color("e8233c"), 0.25, 0.2)
	Kit.part(g, Kit.SPH, red, Vector3(0.5, 0.42, 0.12), Vector3(0, -0.1, 0))
	Kit.part(g, Kit.SPH, red, Vector3(0.38, 0.32, 0.12), Vector3(0, 0.18, 0))
	Kit.part(g, Kit.BOX, _m(Color("2a1a10"), 0.6), Vector3(0.08, 0.8, 0.05), Vector3(0, 0.6, 0))
	Kit.part(g, Kit.BOX, _m(Color("15161c")), Vector3(0.14, 0.18, 0.05), Vector3(0, 1.05, 0))
	Kit.part(g, Kit.BOX, glowmat(Color("2ee88a"), 1.4), Vector3(0.05, 0.16, 0.02), Vector3(0, -0.05, 0.07))
	Kit.part(g, Kit.BOX, glowmat(Color("2ee88a"), 1.4), Vector3(0.16, 0.05, 0.02), Vector3(0, -0.05, 0.07))
	return h


static func granny_tank() -> Dictionary:
	var h := human({"top": Color("7a5a8c"), "pants": Color("5a4a3a"), "shoes": Color("3a2a22"), "hair": "headscarf",
		"scarf": Color("d8323c"), "skirt": true, "skirt_color": Color("4a3a5a"), "width": 1.25, "scale": Vector3(1.0, 0.86, 1.0),
		"angry": 1.0, "smirk": -0.1, "brow": Color("b8b8b8"), "skin": Color("eab79a")})
	# rolling pin (weapon) in right hand
	var pin := Node3D.new()
	h.hands[1].add_child(pin)
	pin.rotation = Vector3(PI / 2, 0, 0)
	var wood := _m(Color("d9a86a"), 0.7)
	Kit.part(pin, Kit.CYL, wood, Vector3(0.2, 0.7, 0.2), Vector3(0, 0.38, 0))
	Kit.part(pin, Kit.CYL, wood, Vector3(0.07, 0.2, 0.07), Vector3(0, -0.05, 0))
	Kit.part(pin, Kit.CYL, wood, Vector3(0.07, 0.2, 0.07), Vector3(0, 0.82, 0))
	# shopping bag shield (avoska with oranges)
	var bag := Node3D.new()
	h.hands[0].add_child(bag)
	bag.position = Vector3(0, -0.2, 0.15)
	Kit.part(bag, Kit.BOX, _m(Color("3a8a5a"), 0.8), Vector3(0.75, 0.6, 0.12), Vector3(0, -0.15, 0))
	for k in range(5):
		Kit.part(bag, Kit.SPH, _m(Color("ff9a1c"), 0.6), Vector3.ONE * 0.2, Vector3(-0.26 + k * 0.13, 0.17 + (k % 2) * 0.05, 0))
	Kit.torus(bag, _m(Color("2a5a3a")), 0.14, 0.18, Vector3(0, 0.24, 0), Vector3(PI / 2, 0, 0))
	# shield glow
	var sh := Kit.part(bag, Kit.SPH, Kit.glow_material(Color("ffd36b"), 0.35), Vector3(1.6, 1.6, 0.3), Vector3(0, -0.1, 0.1))
	sh.material_override = Kit.mat(Color(1, 0.8, 0.3), 0.2, 0.0, Color("ffb84a"), 1.2)
	sh.transparency = 0.75
	h["shield"] = sh
	return h


static func it_mage() -> Dictionary:
	var h := human({"top": Color("2f5a3a"), "pants": Color("2a2a32"), "shoes": Color("e8e8e8"), "hair": "hood", "glasses": true, "skin": Color("d8a07a")})
	var lap := Node3D.new()
	lap.position = Vector3(0.0, 1.0, 0.75)
	lap.rotation = Vector3(-0.3, 0, 0)
	h.body.add_child(lap)
	Kit.part(lap, Kit.BOX, _m(Color("aab0bc"), 0.3, 0.8), Vector3(0.7, 0.04, 0.48), Vector3.ZERO)
	Kit.part(lap, Kit.BOX, _m(Color("aab0bc"), 0.3, 0.8), Vector3(0.7, 0.46, 0.04), Vector3(0, 0.23, -0.24), Vector3(-0.25, 0, 0))
	Kit.part(lap, Kit.BOX, glowmat(Color("5cffb0"), 2.2), Vector3(0.62, 0.38, 0.01), Vector3(0, 0.23, -0.215), Vector3(-0.25, 0, 0))
	h["laptop"] = lap
	return h


static func gopnik() -> Dictionary:
	return human({"top": Color("1e2a6a"), "pants": Color("1e2a6a"), "shoes": Color("f4f4f4"), "hair": "beanie", "hair_color": Color("2a2a2a"), "stripe": true, "smirk": 0.3})


static func goth() -> Dictionary:
	return human({"top": Color("18141c"), "top_rough": 0.3, "pants": Color("18141c"), "shoes": Color("101010"), "hair": "slick", "hair_color": Color("0e0c12"),
		"skin": Color("f2e2dc"), "brow": Color("0e0c12"), "smirk": -0.25})


static func hipster() -> Dictionary:
	var h := human({"top": Color("c4683a"), "pants": Color("c8b48a"), "shoes": Color("7a4a2a"), "hair": "bun", "hair_color": Color("6a3a1a"), "glasses": false, "smirk": 0.2})
	# beard
	Kit.part(h.head, Kit.SPH, _m(Color("6a3a1a"), 0.9), Vector3(0.52, 0.36, 0.4), Vector3(0, -0.22, 0.14))
	return h


# ------------------------------------------------------------------ mobs
static func pigeon(angry := true, boss := false) -> Dictionary:
	var g := Node3D.new()
	var body := Node3D.new()
	g.add_child(body)
	var grey := _m(Color("8a93a8"), 0.7)
	var dark := _m(Color("5a6070"), 0.7)
	var neck := Kit.mat(Color("4a7a6a"), 0.25, 0.6, Color("6a3a8a"), 0.25)
	Kit.part(body, Kit.SPH, grey, Vector3(1.3, 1.25, 1.9), Vector3(0, 1.25, 0))
	Kit.part(body, Kit.SPH, _m(Color("a2abbd"), 0.7), Vector3(1.05, 1.0, 1.2), Vector3(0, 1.15, 0.35))
	Kit.part(body, Kit.SPH, neck, Vector3(0.85, 0.75, 0.8), Vector3(0, 1.85, 0.55))
	var head := Node3D.new()
	head.position = Vector3(0, 2.3, 0.72)
	body.add_child(head)
	Kit.part(head, Kit.SPH, grey, Vector3(0.62, 0.6, 0.66))
	Kit.part(head, Kit.CONE, _m(Color("3a3a40"), 0.4), Vector3(0.14, 0.42, 0.14), Vector3(0, -0.05, 0.42), Vector3(PI / 2, 0, 0))
	Kit.part(head, Kit.SPH, _m(Color("f0e6e0"), 0.5), Vector3(0.16, 0.08, 0.14), Vector3(0, 0.05, 0.3))
	for s in [-1, 1]:
		Kit.part(head, Kit.SPH, _m(Color("ff8a1c"), 0.3), Vector3(0.16, 0.16, 0.08), Vector3(0.18 * s, 0.06, 0.24))
		Kit.part(head, Kit.SPH, _m(Color("101010"), 0.2), Vector3(0.08, 0.08, 0.05), Vector3(0.19 * s, 0.06, 0.28))
		if angry:
			Kit.part(head, Kit.BOX, _m(Color("2a2a30")), Vector3(0.18, 0.04, 0.04), Vector3(0.17 * s, 0.17, 0.27), Vector3(0, 0, -0.45 * s))
	# flat cap
	var capc := Color("f2c14e") if boss else Color("4a4a52")
	Kit.part(head, Kit.CYL, _m(capc, 0.5 if boss else 0.9, 0.8 if boss else 0.0), Vector3(0.64, 0.12, 0.64), Vector3(0, 0.25, 0.02), Vector3(0.15, 0, 0))
	Kit.part(head, Kit.BOX, _m(capc.darkened(0.2), 0.9), Vector3(0.44, 0.05, 0.22), Vector3(0, 0.22, 0.34), Vector3(0.3, 0, 0))
	if boss:
		for s in [-1, 1]:
			Kit.part(head, Kit.SPH, Kit.neon(Color("ff3a2a"), 3.0), Vector3(0.09, 0.09, 0.05), Vector3(0.19 * s, 0.06, 0.3))
	# wings
	var wings := []
	for s in [-1, 1]:
		var wp := Node3D.new()
		wp.position = Vector3(0.6 * s, 1.55, 0.1)
		body.add_child(wp)
		for k in range(4):
			Kit.part(wp, Kit.BOX, dark if k % 2 else grey, Vector3(0.12, 0.7 - k * 0.08, 1.2 - k * 0.15), Vector3(s * (0.1 + k * 0.18), 0.1 - k * 0.12, -0.1 - k * 0.1), Vector3(0, 0, s * 0.1))
		wings.append(wp)
	# tail
	for k in range(5):
		Kit.part(body, Kit.BOX, dark, Vector3(0.18, 0.06, 0.8), Vector3(-0.3 + k * 0.15, 1.05, -1.1), Vector3(-0.3, (k - 2) * 0.15, 0))
	# legs
	var pink := _m(Color("e07a8a"), 0.5)
	for s in [-1, 1]:
		Kit.part(body, Kit.CYL, pink, Vector3(0.1, 0.6, 0.1), Vector3(0.3 * s, 0.3, 0.1))
		for t in [-0.4, 0.0, 0.4]:
			Kit.part(body, Kit.BOX, pink, Vector3(0.06, 0.05, 0.32), Vector3(0.3 * s + sin(t) * 0.12, 0.03, 0.1 + cos(t) * 0.14), Vector3(0, t, 0))
	# tiny gold chain
	Kit.torus(body, _m(Color("f2c14e"), 0.2, 1.0), 0.33, 0.38, Vector3(0, 1.85, 0.6), Vector3(PI / 2 - 0.5, 0, 0))
	return {"root": g, "body": body, "head": head, "wings": wings}


static func golem() -> Dictionary:
	var g := Node3D.new()
	var conc := Kit.mat(Color("8f8c88"), 0.95)
	var conc2 := Kit.mat(Color("6f6b68"), 0.95)
	var steel := Kit.mat(Color("5a6070"), 0.4, 0.8)
	var orange := Kit.mat(Color("ff6a1a"), 0.6)
	var white := Kit.mat(Color("f4f4f4"), 0.6)
	var red_eye := Kit.neon(Color("ff2a3a"), 5.0)
	# legs: stacked blocks
	for s in [-1, 1]:
		Kit.part(g, Kit.BOX, conc2, Vector3(1.6, 1.4, 1.6), Vector3(1.4 * s, 0.7, 0))
		Kit.part(g, Kit.BOX, conc, Vector3(1.4, 1.6, 1.4), Vector3(1.4 * s, 2.2, 0.1), Vector3(0.05, 0.1 * s, 0))
		for k in range(3):
			Kit.part(g, Kit.CYL, steel, Vector3(0.08, 1.2, 0.08), Vector3(1.4 * s + (k - 1) * 0.4, 1.5, 0.75))
	# torso
	Kit.part(g, Kit.BOX, conc, Vector3(4.6, 3.0, 2.6), Vector3(0, 4.6, 0), Vector3(0.12, 0, 0))
	Kit.part(g, Kit.BOX, conc2, Vector3(3.6, 1.2, 2.4), Vector3(0, 3.2, 0.1))
	# cracks glowing
	for k in range(5):
		Kit.part(g, Kit.BOX, Kit.neon(Color("ff4a2a"), 3.0), Vector3(0.06, 0.6 + k * 0.1, 0.02), Vector3(-1.4 + k * 0.7, 4.4 + (k % 2) * 0.5, 1.47), Vector3(0, 0, 0.4 - k * 0.2))
	# shoulders: cement mixer drums
	for s in [-1, 1]:
		var drum := Kit.part(g, Kit.CYL, Kit.mat(Color("f2b21c"), 0.5, 0.3), Vector3(1.6, 1.8, 1.6), Vector3(2.8 * s, 5.8, 0), Vector3(0, 0, PI / 2 + 0.3 * s))
		Kit.part(g, Kit.CYL, steel, Vector3(1.0, 0.3, 1.0), Vector3(3.7 * s, 6.1, 0), Vector3(0, 0, PI / 2 + 0.3 * s))
	# arms: I-beams + fists
	var arms := []
	for s in [-1, 1]:
		var a := Node3D.new()
		a.position = Vector3(3.2 * s, 5.4, 0.2)
		g.add_child(a)
		Kit.part(a, Kit.BOX, steel, Vector3(0.5, 3.0, 0.5), Vector3(0, -1.4, 0))
		Kit.part(a, Kit.BOX, steel, Vector3(0.9, 3.0, 0.12), Vector3(0, -1.4, 0))
		Kit.part(a, Kit.BOX, conc2, Vector3(1.5, 1.4, 1.5), Vector3(0, -3.1, 0))
		arms.append(a)
	# head
	var head := Node3D.new()
	head.position = Vector3(0, 6.9, 0.4)
	g.add_child(head)
	Kit.part(head, Kit.BOX, conc, Vector3(2.2, 1.6, 1.9))
	for s in [-1, 1]:
		Kit.part(head, Kit.BOX, red_eye, Vector3(0.45, 0.2, 0.05), Vector3(0.5 * s, 0.25, 0.96), Vector3(0, 0, 0.3 * s))
		# traffic-cone horns
		var horn := Node3D.new()
		horn.position = Vector3(0.8 * s, 0.8, 0)
		horn.rotation = Vector3(0, 0, -0.5 * s)
		head.add_child(horn)
		Kit.part(horn, Kit.CONE, orange, Vector3(0.6, 1.4, 0.6), Vector3(0, 0.6, 0))
		Kit.part(horn, Kit.CYL, white, Vector3(0.43, 0.15, 0.43), Vector3(0, 0.55, 0))
		Kit.part(horn, Kit.BOX, Kit.mat(Color("2a2a2a")), Vector3(0.8, 0.12, 0.8), Vector3(0, -0.06, 0))
	# megaphone mouth
	var meg := Node3D.new()
	meg.position = Vector3(0, -0.45, 1.0)
	meg.rotation = Vector3(PI / 2 - 0.25, 0, 0)
	head.add_child(meg)
	var horn_mesh := CylinderMesh.new()
	horn_mesh.top_radius = 0.18
	horn_mesh.bottom_radius = 0.75
	horn_mesh.height = 1.3
	Kit.part(meg, horn_mesh, white, Vector3.ONE, Vector3(0, 0.6, 0))
	Kit.part(meg, Kit.CYL, Kit.neon(Color("ff2a3a"), 4.0), Vector3(1.4, 0.04, 1.4), Vector3(0, 1.26, 0))
	Kit.part(meg, Kit.CYL, Kit.mat(Color("e8233c"), 0.5), Vector3(1.55, 0.12, 1.55), Vector3(0, 1.2, 0))
	return {"root": g, "head": head, "arms": arms, "mouth": meg}


# ------------------------------------------------------------------ mount: hut on chicken legs
static func izba() -> Dictionary:
	var g := Node3D.new()
	var hut := Node3D.new()
	hut.position = Vector3(0, 2.4, 0)
	g.add_child(hut)
	var log1 := Kit.mat(Color("8a5a32"), 0.85)
	var log2 := Kit.mat(Color("7a4c28"), 0.85)
	var W := 2.4
	var D := 2.0
	for r in range(6):
		var yy := r * 0.3 + 0.15
		var m := log1 if r % 2 == 0 else log2
		for s in [-1, 1]:
			Kit.part(hut, Kit.CYL, m, Vector3(0.32, W + 0.5, 0.32), Vector3(0, yy, s * D / 2), Vector3(0, 0, PI / 2))
			Kit.part(hut, Kit.CYL, m, Vector3(0.32, D + 0.5, 0.32), Vector3(s * W / 2, yy + 0.15, 0), Vector3(PI / 2, 0, 0))
	Kit.part(hut, Kit.BOX, log2, Vector3(W, 1.8, D), Vector3(0, 0.9, 0))
	Kit.part(hut, Kit.BOX, Kit.mat(Color("4a2c18"), 0.9), Vector3(W + 0.3, 0.25, D + 0.3), Vector3(0, -0.05, 0))
	# roof
	var roof := PrismMesh.new()
	Kit.part(hut, roof, Kit.mat(Color("4a6a3a"), 0.9), Vector3(D + 1.0, 1.3, W + 0.8), Vector3(0, 2.45, 0), Vector3(0, PI / 2, 0))
	# window with carved frame (front = +Z)
	Kit.part(hut, Kit.BOX, Kit.mat(Color("ffcf7a"), 0.3, 0.0, Color("ffb050"), 3.0), Vector3(0.7, 0.6, 0.05), Vector3(0.3, 1.0, D / 2 + 0.17))
	Kit.part(hut, Kit.BOX, Kit.mat(Color("f4f0e6"), 0.6), Vector3(0.9, 0.08, 0.06), Vector3(0.3, 1.36, D / 2 + 0.19))
	Kit.part(hut, Kit.BOX, Kit.mat(Color("f4f0e6"), 0.6), Vector3(0.9, 0.08, 0.06), Vector3(0.3, 0.66, D / 2 + 0.19))
	var tri := PrismMesh.new()
	Kit.part(hut, tri, Kit.mat(Color("f4f0e6"), 0.6), Vector3(1.0, 0.3, 0.05), Vector3(0.3, 1.55, D / 2 + 0.19))
	for s in [-1, 1]:
		Kit.part(hut, Kit.BOX, Kit.mat(Color("3a8ac8"), 0.6), Vector3(0.18, 0.66, 0.05), Vector3(0.3 + s * 0.48, 1.0, D / 2 + 0.19))
	# door
	Kit.part(hut, Kit.BOX, Kit.mat(Color("5a3418"), 0.8), Vector3(0.6, 1.1, 0.05), Vector3(-0.6, 0.6, D / 2 + 0.17))
	# chimney
	Kit.part(hut, Kit.BOX, Kit.mat(Color("a8503a"), 0.9), Vector3(0.36, 0.9, 0.36), Vector3(0.7, 2.9, -0.4))
	# subwoofers on the roof
	for s in [-1, 1]:
		var sp := Node3D.new()
		sp.position = Vector3(s * 0.95, 2.5, 0.3)
		sp.rotation = Vector3(0, s * 0.4, 0)
		hut.add_child(sp)
		Kit.part(sp, Kit.BOX, Kit.mat(Color("1a1b22"), 0.5), Vector3(0.7, 0.7, 0.5))
		Kit.part(sp, Kit.CYL, Kit.neon(Kit.TEAL, 3.0), Vector3(0.5, 0.04, 0.5), Vector3(0, 0, 0.26), Vector3(PI / 2, 0, 0))
		Kit.part(sp, Kit.CYL, Kit.mat(Color("2a2c34"), 0.3, 0.6), Vector3(0.3, 0.06, 0.3), Vector3(0, 0, 0.27), Vector3(PI / 2, 0, 0))
	# garland
	var cols := [Kit.GOLD, Color("ff5d7a"), Kit.TEAL, Color("2ed38f"), Color("c38bff")]
	for k in range(14):
		var t := k / 13.0
		Kit.part(hut, Kit.SPH, Kit.neon(cols[k % 5], 4.0), Vector3.ONE * 0.12, Vector3(-W / 2 - 0.3 + t * (W + 0.6), 1.92 - sin(t * PI) * 0.25, D / 2 + 0.35))
	# chicken legs
	var legs := []
	var yellow := Kit.mat(Color("f2a23a"), 0.55)
	var feather := Kit.mat(Color("e8dccb"), 0.95)
	for s in [-1, 1]:
		var hip := Node3D.new()
		hip.position = Vector3(0.6 * s, 2.45, 0)
		g.add_child(hip)
		Kit.part(hip, Kit.SPH, feather, Vector3(0.95, 1.1, 1.0), Vector3(0, -0.25, 0))
		for k in range(5):
			Kit.part(hip, Kit.CONE, feather, Vector3(0.2, 0.4, 0.12), Vector3((k - 2) * 0.12, -0.6, 0.25), Vector3(PI, 0, 0))
		var knee := Node3D.new()
		knee.position = Vector3(0, -0.6, 0)
		hip.add_child(knee)
		Kit.part(knee, Kit.CYL, yellow, Vector3(0.3, 1.5, 0.3), Vector3(0, -0.7, 0))
		Kit.part(knee, Kit.SPH, yellow, Vector3.ONE * 0.36, Vector3(0, 0, 0))
		var ankle := Node3D.new()
		ankle.position = Vector3(0, -1.45, 0)
		knee.add_child(ankle)
		Kit.part(ankle, Kit.SPH, yellow, Vector3.ONE * 0.26)
		for t in [-0.5, 0.0, 0.5]:
			var toe := Node3D.new()
			toe.rotation = Vector3(0, t, 0)
			ankle.add_child(toe)
			Kit.part(toe, Kit.CYL, yellow, Vector3(0.16, 0.7, 0.16), Vector3(0, -0.06, 0.34), Vector3(PI / 2 - 0.2, 0, 0))
			Kit.part(toe, Kit.CONE, Kit.mat(Color("2a2a2a"), 0.3), Vector3(0.1, 0.18, 0.1), Vector3(0, -0.12, 0.66), Vector3(PI / 2 + 0.3, 0, 0))
		var back := Node3D.new()
		ankle.add_child(back)
		Kit.part(back, Kit.CYL, yellow, Vector3(0.1, 0.3, 0.1), Vector3(0, -0.05, -0.18), Vector3(-PI / 2 + 0.3, 0, 0))
		legs.append({"hip": hip, "knee": knee, "ankle": ankle})
	return {"root": g, "hut": hut, "legs": legs}


# ------------------------------------------------------------------ robot helper & cart
static func robot() -> Dictionary:
	var g := Node3D.new()
	var white := Kit.mat(Color("eef1f6"), 0.25, 0.1)
	var joint := Kit.mat(Color("2a2e3a"), 0.4, 0.6)
	var teal := Kit.neon(Kit.TEAL, 2.5)
	var body := Node3D.new()
	g.add_child(body)
	var arms := []
	var legs := []
	for s in [-1, 1]:
		var hip := Node3D.new()
		hip.position = Vector3(0.2 * s, 0.75, 0)
		body.add_child(hip)
		Kit.part(hip, Kit.CAP, white, Vector3(0.6, 0.7, 0.6), Vector3(0, -0.33, 0))
		Kit.part(hip, Kit.SPH, joint, Vector3.ONE * 0.2, Vector3(0, -0.35, 0))
		Kit.part(hip, Kit.BOX, joint, Vector3(0.3, 0.12, 0.44), Vector3(0, -0.7, 0.06))
		legs.append(hip)
		var sh := Node3D.new()
		sh.position = Vector3(0.48 * s, 1.45, 0)
		body.add_child(sh)
		Kit.part(sh, Kit.SPH, joint, Vector3.ONE * 0.26)
		Kit.part(sh, Kit.CAP, white, Vector3(0.48, 0.65, 0.48), Vector3(0, -0.32, 0))
		Kit.part(sh, Kit.SPH, joint, Vector3.ONE * 0.2, Vector3(0, -0.68, 0))
		arms.append(sh)
	Kit.part(body, Kit.CAP, white, Vector3(1.6, 0.9, 1.1), Vector3(0, 1.2, 0))
	Kit.part(body, Kit.CYL, teal, Vector3(0.22, 0.04, 0.22), Vector3(0, 1.3, 0.29), Vector3(PI / 2, 0, 0))
	Kit.part(body, Kit.BOX, joint, Vector3(0.12, 0.25, 0.12), Vector3(0, 1.72, 0))
	var head := Node3D.new()
	head.position = Vector3(0, 2.05, 0)
	body.add_child(head)
	Kit.part(head, Kit.SPH, white, Vector3(0.78, 0.6, 0.66))
	Kit.part(head, Kit.SPH, Kit.mat(Color("0c1018"), 0.1, 0.3), Vector3(0.62, 0.42, 0.2), Vector3(0, 0, 0.25))
	for s in [-1, 1]:
		Kit.part(head, Kit.CAP, teal, Vector3(0.3, 0.12, 0.3), Vector3(0.13 * s, 0.04, 0.35))
	Kit.part(head, Kit.BOX, teal, Vector3(0.14, 0.025, 0.02), Vector3(0, -0.09, 0.355))
	Kit.part(head, Kit.CYL, joint, Vector3(0.04, 0.25, 0.04), Vector3(0.2, 0.38, 0), Vector3(0, 0, -0.3))
	Kit.part(head, Kit.SPH, Kit.neon(Color("ff5d7a"), 3.0), Vector3.ONE * 0.09, Vector3(0.24, 0.5, 0))
	label(body, "ВАСЯ-3000", 48, Color("2a2e3a"), Vector3(0, 1.08, -0.3), Vector3(0, PI, 0), 0.004, 0)
	return {"root": g, "body": body, "arms": arms, "legs": legs, "head": head}


static func cart() -> Node3D:
	var g := Node3D.new()
	var wire := Kit.mat(Color("c8ccd4"), 0.25, 1.0)
	var red := Kit.mat(Color("e8233c"), 0.5)
	var L := 1.3
	var Wd := 0.8
	var H := 0.7
	var base_y := 0.45
	# basket frame
	for x in [-Wd / 2, Wd / 2]:
		for z in [-L / 2, L / 2]:
			Kit.part(g, Kit.BOX, wire, Vector3(0.03, H, 0.03), Vector3(x, base_y + H / 2, z))
	for k in range(5):
		var yy := base_y + k * H / 4
		for x in [-Wd / 2, Wd / 2]:
			Kit.part(g, Kit.BOX, wire, Vector3(0.02, 0.02, L), Vector3(x, yy, 0))
		for z in [-L / 2, L / 2]:
			Kit.part(g, Kit.BOX, wire, Vector3(Wd, 0.02, 0.02), Vector3(0, yy, z))
	for k in range(7):
		var zz := -L / 2 + k * L / 6
		for x in [-Wd / 2, Wd / 2]:
			Kit.part(g, Kit.BOX, wire, Vector3(0.015, H, 0.015), Vector3(x, base_y + H / 2, zz))
	Kit.part(g, Kit.BOX, wire, Vector3(Wd, 0.02, L), Vector3(0, base_y, 0))
	# handle
	Kit.part(g, Kit.CYL, red, Vector3(0.06, Wd + 0.1, 0.06), Vector3(0, base_y + H + 0.15, -L / 2 - 0.18), Vector3(0, 0, PI / 2))
	for x in [-Wd / 2, Wd / 2]:
		Kit.part(g, Kit.BOX, wire, Vector3(0.03, 0.3, 0.03), Vector3(x, base_y + H, -L / 2 - 0.1), Vector3(-0.5, 0, 0))
	# wheels
	for x in [-Wd / 2 + 0.05, Wd / 2 - 0.05]:
		for z in [-L / 2 + 0.1, L / 2 - 0.1]:
			Kit.part(g, Kit.BOX, wire, Vector3(0.03, base_y - 0.1, 0.03), Vector3(x, (base_y + 0.1) / 2, z))
			Kit.part(g, Kit.CYL, Kit.mat(Color("1a1a1a")), Vector3(0.16, 0.06, 0.16), Vector3(x, 0.08, z), Vector3(0, 0, PI / 2))
	# contents: bricks, cement bags, planks, garland box
	var brick := Kit.mat(Color("b84a32"), 0.9)
	for i in range(3):
		for j in range(2):
			for k in range(2):
				Kit.part(g, Kit.BOX, brick, Vector3(0.24, 0.12, 0.12), Vector3(-0.2 + j * 0.26, base_y + 0.08 + k * 0.13, -0.4 + i * 0.13))
	var bag := Kit.mat(Color("cfc8b8"), 0.95)
	for i in range(2):
		Kit.part(g, Kit.BOX, bag, Vector3(0.36, 0.2, 0.5), Vector3(0.18, base_y + 0.14 + i * 0.21, 0.2), Vector3(0, 0, 0.1 * i))
	label(g, "ЦЕМЕНТ", 40, Color("4a4a4a"), Vector3(0.18, base_y + 0.36, 0.46), Vector3.ZERO, 0.003, 0)
	var wood := Kit.mat(Color("e0b46a"), 0.8)
	for i in range(3):
		Kit.part(g, Kit.BOX, wood, Vector3(0.12, 0.05, 1.9), Vector3(-0.3 + i * 0.13, base_y + 0.72 + i * 0.05, 0.1), Vector3(0.25, 0, 0))
	Kit.part(g, Kit.BOX, Kit.mat(Color("3a8ac8"), 0.6), Vector3(0.3, 0.25, 0.3), Vector3(-0.15, base_y + 0.5, 0.35))
	var cols := [Kit.GOLD, Color("ff5d7a"), Kit.TEAL]
	for k in range(6):
		Kit.part(g, Kit.SPH, Kit.neon(cols[k % 3], 3.5), Vector3.ONE * 0.06, Vector3(-0.15 + (k % 3 - 1) * 0.08, base_y + 0.66, 0.35 + (k / 3) * 0.08))
	return g


# ------------------------------------------------------------------ fx and props
static func note3d(parent: Node3D, pos: Vector3, c: Color, s := 1.0) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	n.scale = Vector3.ONE * s
	parent.add_child(n)
	var m := Kit.neon(c, 3.0)
	Kit.part(n, Kit.SPH, m, Vector3(0.22, 0.17, 0.12), Vector3(0, 0, 0), Vector3(0, 0, 0.4))
	Kit.part(n, Kit.BOX, m, Vector3(0.035, 0.5, 0.035), Vector3(0.1, 0.25, 0))
	Kit.part(n, Kit.BOX, m, Vector3(0.18, 0.06, 0.035), Vector3(0.18, 0.47, 0), Vector3(0, 0, -0.5))
	return n


static func beam(parent: Node3D, a: Vector3, b: Vector3, c: Color, width := 0.12, e := 4.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = Kit.CYL
	mi.material_override = Kit.neon(c, e)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.global_position = a.lerp(b, 0.5)
	mi.look_at(b, Vector3.UP if absf((b - a).normalized().y) < 0.95 else Vector3.RIGHT)
	mi.rotate_object_local(Vector3.RIGHT, PI / 2)
	mi.scale = Vector3(width, a.distance_to(b), width)
	return mi


static func glow(parent: Node3D, pos: Vector3, c: Color, size := 2.0, alpha := 0.6) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = QuadMesh.new()
	mi.material_override = Kit.glow_material(c, alpha)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos
	mi.scale = Vector3.ONE * size
	parent.add_child(mi)
	return mi


static func ring(parent: Node3D, pos: Vector3, r: float, c: Color, thick := 0.08, e := 3.0) -> MeshInstance3D:
	var t := TorusMesh.new()
	t.inner_radius = r - thick
	t.outer_radius = r
	t.rings = 64
	t.ring_segments = 8
	var mi := MeshInstance3D.new()
	mi.mesh = t
	mi.material_override = Kit.neon(c, e)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos
	parent.add_child(mi)
	return mi


static func tree(parent: Node3D, pos: Vector3, s := 1.0, leaf := Color("4a8a3a")) -> void:
	var t := Node3D.new()
	t.position = pos
	t.scale = Vector3.ONE * s
	parent.add_child(t)
	Kit.part(t, Kit.CYL, Kit.mat(Color("5a3a24"), 0.9), Vector3(0.35, 3.0, 0.35), Vector3(0, 1.5, 0))
	var lm := Kit.mat(leaf, 0.85)
	var lm2 := Kit.mat(leaf.lightened(0.15), 0.85)
	for k in range(6):
		var a := k * 1.1
		Kit.part(t, Kit.SPH, lm if k % 2 else lm2, Vector3.ONE * (1.6 + (k % 3) * 0.3), Vector3(sin(a) * 0.8, 3.3 + (k % 3) * 0.5, cos(a) * 0.8))
	Kit.part(t, Kit.SPH, lm2, Vector3.ONE * 1.9, Vector3(0, 4.2, 0))


static func loot_beam(parent: Node3D, pos: Vector3, c: Color, h := 5.0) -> void:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(c.r, c.g, c.b, 0.45)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var g := GradientTexture2D.new()
	var gr := Gradient.new()
	gr.set_color(0, Color(1, 1, 1, 1))
	gr.set_color(1, Color(1, 1, 1, 0))
	g.gradient = gr
	g.fill_from = Vector2(0, 1)
	g.fill_to = Vector2(0, 0)
	m.albedo_texture = g
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.18
	cyl.bottom_radius = 0.32
	cyl.height = h
	cyl.cap_top = false
	cyl.cap_bottom = false
	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos + Vector3(0, h / 2, 0)
	parent.add_child(mi)
	glow(parent, pos + Vector3(0, 0.3, 0), c, 2.2, 0.7)
	ring(parent, pos + Vector3(0, 0.03, 0), 0.6, c, 0.05, 3.0)


static func burst(parent: Node3D, pos: Vector3, cols: Array, n := 30, spd := 4.0, size := 0.08, preprocess := 0.25) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	var bm := SphereMesh.new()
	bm.radius = size
	bm.height = size * 2
	bm.radial_segments = 6
	bm.rings = 3
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.material = m
	p.mesh = bm
	p.amount = n
	p.lifetime = 1.2
	p.explosiveness = 0.0
	p.direction = Vector3(0, 1, 0)
	p.spread = 180
	p.initial_velocity_min = spd * 0.4
	p.initial_velocity_max = spd
	p.gravity = Vector3(0, -2, 0)
	var g := Gradient.new()
	g.offsets = PackedFloat32Array()
	g.colors = PackedColorArray()
	for i in range(cols.size()):
		g.add_point(float(i) / max(1, cols.size() - 1), cols[i] * 3.0)
	p.color_initial_ramp = g
	p.position = pos
	p.preprocess = preprocess + 0.6
	parent.add_child(p)
	p.emitting = true
	return p


# ------------------------------------------------------------------ playable heroes (race + class mix)
const HERO_NAMES := {"rapper_cop": "МС Патруль", "rapper_medic": "Доктор Флоу", "punk_cop": "Сержант Ирокез", "punk_medic": "ПанкДоктор"}


static func hero(race: String, cls: String) -> Dictionary:
	var o := {}
	if race == "punk":
		o = {"top": Color("1c1c22"), "top_rough": 0.35, "pants": Color("3c5a8c"), "shoes": Color("1a1a1a"), "hair": "mohawk",
			"hair_color": Color("ff4fa8"), "jacket_studs": true, "angry": 0.6, "smirk": -0.2, "skin": Color("f0c4a4")}
	else:
		o = {"top": Color("f5b55c"), "pants": Color("1d2b4a"), "shoes": Color("f4f1ea"), "hair": "cap_back", "hair_color": Color("55cdbe"),
			"shades": true, "chain": true, "smirk": 0.25}
	if cls == "cop":
		if race == "rapper":
			o.hair = "police_cap"
		o.vest = Color("24365e")
		o.back_text = "МС ПАТРУЛЬ" if race == "rapper" else "ПАНК-ПАТРУЛЬ"
	else:
		o.armband = true
		o.vest = Color("e8eef2")
		o.vest_plain = true
		o.back_text = "ДОКТОР ФЛОУ" if race == "rapper" else "ПАНКДОКТОР"
		o.back_color = Color("1f9a5a")
	var h := human(o)
	var tip := Node3D.new()
	if cls == "cop":
		var mic := Node3D.new()
		h.hands[1].add_child(mic)
		mic.rotation = Vector3(PI / 2, 0, 0)
		Kit.part(mic, Kit.CYL, _m(Color("15161c"), 0.3), Vector3(0.1, 0.62, 0.1), Vector3(0, 0.2, 0))
		Kit.part(mic, Kit.CYL, _m(Color("f2c14e"), 0.2, 1.0), Vector3(0.14, 0.05, 0.14), Vector3(0, 0.52, 0))
		Kit.part(mic, Kit.SPH, Kit.mat(Color("d8dde6"), 0.2, 1.0, Color("7af0ff"), 0.4), Vector3(0.24, 0.24, 0.24), Vector3(0, 0.62, 0))
		mic.add_child(tip)
		tip.position = Vector3(0, 0.7, 0)
	else:
		var g := Node3D.new()
		g.position = Vector3(0, 0.92, 0.36)
		g.rotation = Vector3(0, 0, -0.9)
		h.body.add_child(g)
		var red := _m(Color("e8233c") if race == "punk" else Color("2a8f84"), 0.25, 0.2)
		Kit.part(g, Kit.SPH, red, Vector3(0.5, 0.42, 0.12), Vector3(0, -0.1, 0))
		Kit.part(g, Kit.SPH, red, Vector3(0.38, 0.32, 0.12), Vector3(0, 0.18, 0))
		Kit.part(g, Kit.BOX, _m(Color("2a1a10"), 0.6), Vector3(0.08, 0.8, 0.05), Vector3(0, 0.6, 0))
		Kit.part(g, Kit.BOX, _m(Color("15161c")), Vector3(0.14, 0.18, 0.05), Vector3(0, 1.05, 0))
		Kit.part(g, Kit.BOX, glowmat(Color("2ee88a"), 1.4), Vector3(0.05, 0.16, 0.02), Vector3(0, -0.05, 0.07))
		Kit.part(g, Kit.BOX, glowmat(Color("2ee88a"), 1.4), Vector3(0.16, 0.05, 0.02), Vector3(0, -0.05, 0.07))
		g.add_child(tip)
		tip.position = Vector3(0, -0.1, 0.2)
		h["guitar"] = g
	h["tip"] = tip
	return h


static func granny_npc() -> Dictionary:
	var h := human({"top": Color("7a5a8c"), "pants": Color("5a4a3a"), "shoes": Color("3a2a22"), "hair": "headscarf",
		"scarf": Color("d8323c"), "skirt": true, "skirt_color": Color("4a3a5a"), "width": 1.25, "scale": Vector3(1.0, 0.86, 1.0),
		"smirk": 0.3, "brow": Color("b8b8b8"), "skin": Color("eab79a")})
	var bag := Node3D.new()
	h.hands[0].add_child(bag)
	bag.position = Vector3(0, -0.2, 0.05)
	Kit.part(bag, Kit.BOX, _m(Color("3a8a5a"), 0.8), Vector3(0.6, 0.5, 0.12), Vector3(0, -0.15, 0))
	for k in range(4):
		Kit.part(bag, Kit.SPH, _m(Color("ff9a1c"), 0.6), Vector3.ONE * 0.18, Vector3(-0.2 + k * 0.13, 0.13 + (k % 2) * 0.05, 0))
	return h


# ------------------------------------------------------------------ yard mobs: scooter and vacuum
static func scooter() -> Dictionary:
	var g := Node3D.new()
	var body := Node3D.new()
	g.add_child(body)
	var deck := _m(Color("2fb8a8"), 0.4, 0.3)
	var dark := _m(Color("1a1b22"), 0.5)
	var steel := _m(Color("c4c9d4"), 0.3, 0.9)
	Kit.part(body, Kit.BOX, deck, Vector3(0.38, 0.09, 1.15), Vector3(0, 0.22, 0))
	Kit.part(body, Kit.BOX, dark, Vector3(0.34, 0.02, 0.9), Vector3(0, 0.27, -0.05))
	var wheels := []
	for z in [-0.52, 0.52]:
		var w := Node3D.new()
		w.position = Vector3(0, 0.16, z)
		body.add_child(w)
		Kit.part(w, Kit.CYL, dark, Vector3(0.32, 0.1, 0.32), Vector3.ZERO, Vector3(0, 0, PI / 2))
		Kit.part(w, Kit.CYL, steel, Vector3(0.14, 0.11, 0.14), Vector3.ZERO, Vector3(0, 0, PI / 2))
		wheels.append(w)
	var stem := Node3D.new()
	stem.position = Vector3(0, 0.25, 0.5)
	body.add_child(stem)
	Kit.part(stem, Kit.CYL, steel, Vector3(0.08, 1.1, 0.08), Vector3(0, 0.55, 0))
	Kit.part(stem, Kit.CYL, steel, Vector3(0.06, 0.62, 0.06), Vector3(0, 1.1, 0), Vector3(0, 0, PI / 2))
	for s in [-1, 1]:
		Kit.part(stem, Kit.CYL, dark, Vector3(0.08, 0.14, 0.08), Vector3(0.3 * s, 1.1, 0), Vector3(0, 0, PI / 2))
	Kit.part(stem, Kit.SPH, _m(Color("f2c14e"), 0.2, 1.0), Vector3.ONE * 0.09, Vector3(-0.18, 1.16, 0))
	# angry face on the stem
	Kit.part(stem, Kit.BOX, dark, Vector3(0.36, 0.2, 0.08), Vector3(0, 0.82, 0.04))
	for s in [-1, 1]:
		Kit.part(stem, Kit.SPH, Kit.neon(Color("ff4a2a"), 3.0), Vector3(0.09, 0.07, 0.04), Vector3(0.08 * s, 0.83, 0.09))
		Kit.part(stem, Kit.BOX, _m(Color("2fb8a8")), Vector3(0.12, 0.03, 0.03), Vector3(0.08 * s, 0.9, 0.09), Vector3(0, 0, -0.5 * s))
	Kit.part(stem, Kit.CYL, Kit.neon(Color("fff0b0"), 2.0), Vector3(0.12, 0.03, 0.12), Vector3(0, 0.6, 0.06), Vector3(PI / 2, 0, 0))
	return {"root": g, "body": body, "head": stem, "wheels": wheels}


static func vacuum() -> Dictionary:
	var g := Node3D.new()
	var body := Node3D.new()
	g.add_child(body)
	var red := _m(Color("d8323c"), 0.35, 0.2)
	var dark := _m(Color("22232b"), 0.5)
	var grey := _m(Color("8a8f9a"), 0.4, 0.5)
	Kit.part(body, Kit.SPH, red, Vector3(0.95, 0.7, 1.2), Vector3(0, 0.48, -0.1))
	Kit.part(body, Kit.SPH, dark, Vector3(0.7, 0.3, 0.8), Vector3(0, 0.8, -0.2))
	Kit.part(body, Kit.CYL, grey, Vector3(0.5, 0.06, 0.5), Vector3(0, 0.93, -0.25))
	for s in [-1, 1]:
		Kit.part(body, Kit.CYL, dark, Vector3(0.36, 0.12, 0.36), Vector3(0.48 * s, 0.18, -0.35), Vector3(0, 0, PI / 2))
		Kit.part(body, Kit.SPH, Kit.neon(Color("ffd84a"), 3.0), Vector3(0.14, 0.1, 0.06), Vector3(0.17 * s, 0.62, 0.48))
		Kit.part(body, Kit.BOX, dark, Vector3(0.18, 0.04, 0.04), Vector3(0.17 * s, 0.72, 0.48), Vector3(0, 0, -0.45 * s))
	# cord tail with plug
	for k in range(4):
		Kit.part(body, Kit.CYL, dark, Vector3(0.04, 0.3, 0.04), Vector3(0.05 * k, 0.12, -0.75 - k * 0.25), Vector3(PI / 2 - 0.2, 0.3 * k, 0))
	Kit.part(body, Kit.BOX, _m(Color("f4f4f4")), Vector3(0.12, 0.12, 0.16), Vector3(0.2, 0.1, -1.75))
	# the hose that sways
	var hose := Node3D.new()
	hose.position = Vector3(0, 0.75, 0.45)
	body.add_child(hose)
	for k in range(5):
		Kit.part(hose, Kit.SPH, grey if k % 2 else dark, Vector3(0.18, 0.18, 0.18), Vector3(0, 0.18 * k - 0.02 * k * k, 0.16 * k))
	Kit.part(hose, Kit.CYL, grey, Vector3(0.09, 0.7, 0.09), Vector3(0, 0.55, 1.0), Vector3(0.9, 0, 0))
	Kit.part(hose, Kit.BOX, dark, Vector3(0.42, 0.1, 0.18), Vector3(0, 0.25, 1.32))
	return {"root": g, "body": body, "head": hose, "wheels": []}


# ------------------------------------------------------------------ townsfolk
static func _mustache(h: Dictionary, c: Color) -> void:
	Kit.part(h.head, Kit.SPH, _m(c, 0.8), Vector3(0.3, 0.07, 0.08), Vector3(0, -0.11, 0.32))


static func misha_npc() -> Dictionary:
	var h := human({"top": Color("3a4a6a"), "pants": Color("2a3a5a"), "shoes": Color("2a2a2a"), "hair": "beanie", "hair_color": Color("e86a1c"),
		"vest": Color("ff7a10"), "smirk": 0.3, "brow": Color("6a5a4a"), "skin": Color("e2a882")})
	_mustache(h, Color("6a5a4a"))
	var broom := Node3D.new()
	h.hands[1].add_child(broom)
	broom.rotation = Vector3(0.2, 0, 0.15)
	Kit.part(broom, Kit.CYL, _m(Color("c8a06a"), 0.8), Vector3(0.06, 1.6, 0.06), Vector3(0, -0.2, 0))
	Kit.part(broom, Kit.CONE, _m(Color("d8b85a"), 0.95), Vector3(0.4, 0.5, 0.4), Vector3(0, -1.15, 0), Vector3(PI, 0, 0))
	return h


static func lyuba_npc() -> Dictionary:
	var h := human({"top": Color("e86a9a"), "pants": Color("3a3a4a"), "shoes": Color("6a2a3a"), "hair": "bun", "hair_color": Color("c84a2a"),
		"skirt": true, "skirt_color": Color("5a3a6a"), "width": 1.12, "smirk": 0.35, "skin": Color("f0c0a0")})
	Kit.part(h.body, Kit.BOX, _m(Color("f8f6f0"), 0.8), Vector3(0.62, 0.8, 0.06), Vector3(0, 0.7, 0.33))
	label(h.body, "ЛЮБА", 40, Color("e8426a"), Vector3(0, 1.02, 0.37), Vector3.ZERO, 0.003, 0)
	return h


static func petrovich_npc() -> Dictionary:
	var h := human({"top": Color("6a5a3a"), "pants": Color("3a3a3a"), "shoes": Color("2a2018"), "hair": "slick", "hair_color": Color("9a9a9a"),
		"width": 1.15, "brow": Color("9a9a9a"), "smirk": 0.1, "glasses": false})
	_mustache(h, Color("b0b0b0"))
	var board := Node3D.new()
	h.hands[0].add_child(board)
	board.position = Vector3(0.05, -0.05, 0.12)
	board.rotation = Vector3(-0.9, 0, 0)
	Kit.part(board, Kit.BOX, _m(Color("8a5a32"), 0.8), Vector3(0.32, 0.42, 0.03))
	Kit.part(board, Kit.BOX, _m(Color("f4f4f4"), 0.8), Vector3(0.26, 0.32, 0.035), Vector3(0, -0.02, 0))
	return h


# ------------------------------------------------------------------ 0.3: Тишинка (silence drone)
static func drone() -> Dictionary:
	var g := Node3D.new()
	var body := Node3D.new()
	body.position = Vector3(0, 1.85, 0)
	g.add_child(body)
	var shell := _m(Color("9aa0aa"), 0.35, 0.4)
	var dark := _m(Color("2a2e38"), 0.4, 0.5)
	Kit.part(body, Kit.SPH, shell, Vector3(0.95, 0.8, 0.95))
	Kit.part(body, Kit.CYL, dark, Vector3(1.05, 0.12, 1.05), Vector3(0, -0.05, 0))
	# one big lens (the "eye")
	var head := Node3D.new()
	head.position = Vector3(0, 0.0, 0.38)
	body.add_child(head)
	Kit.part(head, Kit.CYL, dark, Vector3(0.52, 0.16, 0.52), Vector3.ZERO, Vector3(PI / 2, 0, 0))
	Kit.part(head, Kit.SPH, Kit.mat(Color("0c1018"), 0.05, 0.3), Vector3(0.4, 0.4, 0.2), Vector3(0, 0, 0.08))
	Kit.part(head, Kit.CYL, Kit.neon(Color("ff3a4a"), 3.5), Vector3(0.18, 0.02, 0.18), Vector3(0, 0, 0.17), Vector3(PI / 2, 0, 0))
	Kit.part(head, Kit.SPH, Kit.neon(Color("ffffff"), 2.0), Vector3.ONE * 0.06, Vector3(0.08, 0.08, 0.17))
	# antenna with a grey "mute" light
	Kit.part(body, Kit.CYL, dark, Vector3(0.03, 0.35, 0.03), Vector3(0, 0.5, -0.1))
	Kit.part(body, Kit.SPH, Kit.neon(Color("c8d0e0"), 2.0), Vector3.ONE * 0.1, Vector3(0, 0.7, -0.1))
	# four rotor arms
	var rotors := []
	for a in [PI / 4, 3 * PI / 4, 5 * PI / 4, 7 * PI / 4]:
		var dir := Vector3(cos(a), 0, sin(a))
		Kit.part(body, Kit.BOX, dark, Vector3(0.7, 0.06, 0.08), dir * 0.55 + Vector3(0, 0.12, 0), Vector3(0, -a, 0))
		var r := Node3D.new()
		r.position = dir * 0.88 + Vector3(0, 0.2, 0)
		body.add_child(r)
		Kit.part(r, Kit.CYL, dark, Vector3(0.08, 0.1, 0.08))
		Kit.part(r, Kit.BOX, _m(Color("d8dce4"), 0.5), Vector3(0.62, 0.02, 0.08), Vector3(0, 0.06, 0))
		Kit.part(r, Kit.BOX, _m(Color("d8dce4"), 0.5), Vector3(0.08, 0.02, 0.62), Vector3(0, 0.06, 0))
		rotors.append(r)
	# soft shadow blob on the ground
	var sh := StandardMaterial3D.new()
	sh.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sh.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sh.albedo_color = Color(0, 0, 0, 0.28)
	Kit.part(g, Kit.DISC, sh, Vector3(1.1, 1, 1.1), Vector3(0, 0.03, 0))
	return {"root": g, "body": body, "head": head, "wheels": rotors}


## Silence bubble shot by a Тишинка
static func bubble() -> Node3D:
	var n := Node3D.new()
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.82, 0.86, 0.95, 0.38)
	m.roughness = 0.05
	m.metallic = 0.3
	m.rim_enabled = true
	m.rim = 1.0
	Kit.part(n, Kit.SPH, m, Vector3.ONE * 0.62)
	Kit.part(n, Kit.SPH, Kit.neon(Color("e8eeff"), 1.4), Vector3(0.12, 0.08, 0.06), Vector3(-0.14, 0.15, 0.24))
	return n


# ------------------------------------------------------------------ 0.4: Кощей, ковёр-самолёт, робо-зайцы
static func koschei() -> Dictionary:
	var h := human({"top": Color("15151a"), "top_rough": 0.35, "pants": Color("15151a"), "shoes": Color("0e0e10"), "hair": "slick",
		"hair_color": Color("cfd3da"), "skin": Color("b4c8a8"), "width": 0.82, "scale": Vector3(0.92, 1.2, 0.92), "brow": Color("cfd3da"),
		"angry": 0.5, "smirk": -0.25})
	var silver := Kit.mat(Color("d8dde6"), 0.2, 1.0)
	Kit.torus(h.head, silver, 0.3, 0.34, Vector3(0, 0.26, 0), Vector3(0, 0, 0))
	for k in range(5):
		var a := -1.0 + k * 0.5
		Kit.part(h.head, Kit.CONE, silver, Vector3(0.05, 0.16, 0.05), Vector3(sin(a) * 0.32, 0.36, cos(a) * 0.32))
	Kit.part(h.head, Kit.SPH, Kit.neon(Color("9af0ff"), 2.0), Vector3.ONE * 0.06, Vector3(0.3, 0.05, 0.12))
	Kit.part(h.head, Kit.CONE, Kit.mat(Color("cfd3da"), 0.8), Vector3(0.14, 0.36, 0.1), Vector3(0, -0.4, 0.22), Vector3(PI, 0, 0))
	# flying carpet under his feet
	var carpet := Node3D.new()
	carpet.position = Vector3(0, 0.05, 0)
	h.root.add_child(carpet)
	Kit.part(carpet, Kit.BOX, Kit.mat(Color("8a1a2a"), 0.8), Vector3(1.5, 0.06, 2.2))
	Kit.part(carpet, Kit.BOX, Kit.mat(Color("e8b84a"), 0.6, 0.4), Vector3(1.2, 0.065, 1.9))
	Kit.part(carpet, Kit.BOX, Kit.mat(Color("2a3a7a"), 0.8), Vector3(0.9, 0.07, 1.6))
	for k in range(6):
		Kit.part(carpet, Kit.SPH, Kit.mat(Color("e8b84a"), 0.6, 0.4), Vector3.ONE * 0.1, Vector3(-0.6 + k * 0.24, 0, 1.12))
		Kit.part(carpet, Kit.SPH, Kit.mat(Color("e8b84a"), 0.6, 0.4), Vector3.ONE * 0.1, Vector3(-0.6 + k * 0.24, 0, -1.12))
	# a grey "subscription" dome (shown while his shield is up)
	var dm := StandardMaterial3D.new()
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.albedo_color = Color(0.75, 0.8, 0.92, 0.22)
	var dome := Kit.part(h.root, Kit.SPH, dm, Vector3(2.6, 3.4, 2.6), Vector3(0, 1.4, 0))
	h["carpet"] = carpet
	h["dome"] = dome
	return h


static func robohare(safe := false) -> Dictionary:
	var g := Node3D.new()
	var body := Node3D.new()
	g.add_child(body)
	var white := Kit.mat(Color("e8ecf2"), 0.3, 0.2)
	var steel := Kit.mat(Color("8a92a2"), 0.3, 0.8)
	var dark := Kit.mat(Color("23262e"), 0.4, 0.5)
	Kit.part(body, Kit.SPH, white, Vector3(0.9, 0.85, 1.15), Vector3(0, 0.7, 0))
	if safe:
		# a safe door on the belly
		Kit.part(body, Kit.BOX, steel, Vector3(0.62, 0.55, 0.08), Vector3(0, 0.68, 0.55))
		Kit.part(body, Kit.CYL, Kit.mat(Color("f2c14e"), 0.2, 1.0), Vector3(0.2, 0.06, 0.2), Vector3(0.12, 0.68, 0.6), Vector3(PI / 2, 0, 0))
		Kit.part(body, Kit.BOX, Kit.mat(Color("f2c14e"), 0.2, 1.0), Vector3(0.05, 0.16, 0.04), Vector3(-0.18, 0.68, 0.6))
	var head := Node3D.new()
	head.position = Vector3(0, 1.25, 0.35)
	body.add_child(head)
	Kit.part(head, Kit.SPH, white, Vector3(0.62, 0.55, 0.62))
	Kit.part(head, Kit.BOX, dark, Vector3(0.5, 0.14, 0.1), Vector3(0, 0.05, 0.28))
	Kit.part(head, Kit.BOX, Kit.neon(Color("ff3a4a"), 3.5), Vector3(0.42, 0.05, 0.02), Vector3(0, 0.05, 0.335))
	Kit.part(head, Kit.SPH, Kit.mat(Color("ff9ab0"), 0.5), Vector3.ONE * 0.08, Vector3(0, -0.08, 0.3))
	var ears := []
	for s in [-1, 1]:
		var e := Node3D.new()
		e.position = Vector3(0.14 * s, 0.25, -0.02)
		e.rotation = Vector3(-0.15, 0, -0.18 * s)
		head.add_child(e)
		Kit.part(e, Kit.BOX, white, Vector3(0.14, 0.75, 0.06), Vector3(0, 0.38, 0))
		Kit.part(e, Kit.BOX, Kit.neon(Color("ff9ab0"), 1.0), Vector3(0.07, 0.55, 0.02), Vector3(0, 0.38, 0.035))
		ears.append(e)
	var legs := []
	for s in [-1, 1]:
		var l := Node3D.new()
		l.position = Vector3(0.28 * s, 0.4, -0.2)
		body.add_child(l)
		Kit.part(l, Kit.BOX, steel, Vector3(0.16, 0.42, 0.16), Vector3(0, -0.2, 0))
		Kit.part(l, Kit.BOX, dark, Vector3(0.2, 0.08, 0.5), Vector3(0, -0.4, 0.15))
		legs.append(l)
	Kit.part(body, Kit.SPH, white, Vector3.ONE * 0.3, Vector3(0, 0.75, -0.6))
	Kit.part(body, Kit.CYL, Kit.neon(Kit.TEAL, 2.0), Vector3(0.1, 0.4, 0.1), Vector3(0, 1.2, -0.3))
	return {"root": g, "body": body, "head": head, "wings": ears, "wheels": legs}


## Rubber duck that squeaks «ПИИ-ИК» (pickup fx in the server room)
static func duck() -> Node3D:
	var n := Node3D.new()
	var y := Kit.mat(Color("ffd21a"), 0.35)
	Kit.part(n, Kit.SPH, y, Vector3(0.7, 0.5, 0.85), Vector3(0, 0.25, 0))
	Kit.part(n, Kit.SPH, y, Vector3.ONE * 0.4, Vector3(0, 0.62, 0.22))
	Kit.part(n, Kit.SPH, Kit.mat(Color("ff7a1a"), 0.4), Vector3(0.22, 0.1, 0.22), Vector3(0, 0.6, 0.45))
	for s in [-1, 1]:
		Kit.part(n, Kit.SPH, Kit.mat(Color("101010"), 0.2), Vector3.ONE * 0.06, Vector3(0.1 * s, 0.7, 0.38))
	return n
