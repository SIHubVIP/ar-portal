class_name Mobs09
## 0.9 «Своё дело»: models of the Помойка — mobs (крыса-коллектор, холодильник-кусака, матрас-пружина), the boss Король Хлама,
## the inventors Дед Утиль and Кеша Вторсырьё, props of the dump, the workshop in box №13, the levels 4–5 of the buildings
## and the mount skin «Тележка из «Ёжика»».
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


# =================================================================== mobs
## Крыса-коллектор: a grey rat in a collector's cap with a satchel of coins and a long pink tail
static func rat() -> Dictionary:
	Kit.init()
	var g := Node3D.new()
	var body := Node3D.new()
	g.add_child(body)
	var fur := _m(Color("7a7a84"), 0.9)
	var pink := _m(Color("f0a0b0"), 0.6)
	Kit.part(body, Kit.SPH, fur, Vector3(0.8, 0.62, 1.15), Vector3(0, 0.45, -0.05))
	Kit.part(body, Kit.SPH, _m(Color("b8b8c0"), 0.9), Vector3(0.56, 0.4, 0.8), Vector3(0, 0.32, 0.05))
	var head := Node3D.new()
	head.position = Vector3(0, 0.62, 0.52)
	body.add_child(head)
	Kit.part(head, Kit.SPH, fur, Vector3(0.5, 0.44, 0.56))
	Kit.part(head, Kit.CONE, fur, Vector3(0.3, 0.36, 0.3), Vector3(0, -0.04, 0.32), Vector3(PI / 2, 0, 0))
	Kit.part(head, Kit.SPH, pink, Vector3.ONE * 0.1, Vector3(0, -0.04, 0.5))
	for k in [-1, 1]:
		Kit.part(head, Kit.CYL, pink, Vector3(0.26, 0.03, 0.26), Vector3(0.2 * k, 0.24, -0.04), Vector3(PI / 2 - 0.3, 0, 0.4 * k))
		Kit.part(head, Kit.SPH, Kit.mat(Color("d81a2a"), 0.2, 0.0, Color("ff2a3a"), 0.8), Vector3.ONE * 0.08, Vector3(0.12 * k, 0.07, 0.24))
		for w in range(2):
			var wh := Kit.part(head, Kit.CYL, _m(Color("e8e8e8"), 0.5), Vector3(0.01, 0.32, 0.01), Vector3(0.12 * k, -0.06 + w * 0.04, 0.4), Vector3(0, 0, PI / 2 + 0.2 * k * (w - 0.5)))
			wh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# the collector's cap
	Kit.part(head, Kit.CYL, _m(Color("1a1d28"), 0.6), Vector3(0.42, 0.14, 0.42), Vector3(0, 0.24, -0.02))
	Kit.part(head, Kit.BOX, _m(Color("1a1d28"), 0.4), Vector3(0.34, 0.03, 0.2), Vector3(0, 0.18, 0.2), Vector3(0.25, 0, 0))
	Kit.part(head, Kit.CYL, Kit.mat(Color("f2c14e"), 0.2, 1.0, Color("f2c14e"), 0.5), Vector3(0.1, 0.02, 0.1), Vector3(0, 0.26, 0.2), Vector3(PI / 2, 0, 0))
	# the satchel with coins
	Kit.part(body, Kit.BOX, _m(Color("7a4a2a"), 0.8), Vector3(0.36, 0.3, 0.2), Vector3(0.42, 0.42, 0.0))
	for k in range(3):
		Kit.part(body, Kit.CYL, Kit.mat(Color("f2c14e"), 0.2, 1.0, Color("f2c14e"), 0.4), Vector3(0.12, 0.03, 0.12), Vector3(0.42, 0.6 + k * 0.03, -0.02 + k * 0.02))
	# the tail
	var tail := Node3D.new()
	tail.position = Vector3(0, 0.4, -0.6)
	body.add_child(tail)
	for k in range(5):
		Kit.part(tail, Kit.SPH, pink, Vector3.ONE * (0.1 - k * 0.012), Vector3(0, sin(k * 0.6) * 0.1, -k * 0.16))
	var legs := []
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			var l := Node3D.new()
			l.position = Vector3(0.26 * sx, 0.22, 0.28 * sz)
			body.add_child(l)
			Kit.part(l, Kit.SPH, pink, Vector3(0.14, 0.1, 0.2), Vector3(0, -0.16, 0.04))
			legs.append(l)
	_shadow(g, 1.1)
	return {"root": g, "body": body, "head": head, "wings": [tail], "wheels": legs}


## Холодильник-кусака: a retro cream fridge; the freezer door on top is the jaw with icy teeth, magnets for eyes
static func fridge() -> Dictionary:
	Kit.init()
	var g := Node3D.new()
	var body := Node3D.new()
	g.add_child(body)
	var cream := _m(Color("f2ecd8"), 0.35, 0.05)
	var chrome := _m(Color("c8ccd4"), 0.15, 0.95)
	Kit.part(body, Kit.CAP, cream, Vector3(1.4, 2.3, 1.1), Vector3(0, 1.25, 0))
	Kit.part(body, Kit.BOX, cream, Vector3(1.3, 1.6, 1.0), Vector3(0, 0.98, 0))
	Kit.part(body, Kit.BOX, _m(Color("d8d2bc"), 0.4), Vector3(1.32, 0.05, 1.02), Vector3(0, 1.62, 0))
	Kit.part(body, Kit.BOX, chrome, Vector3(0.08, 0.6, 0.08), Vector3(0.5, 1.0, 0.54))
	Kit.part(body, Kit.BOX, _m(Color("2a3a5a"), 0.5), Vector3(0.5, 0.1, 0.02), Vector3(0, 0.5, 0.51))
	Chars.label(body, "ЗИЛ-Кусь", 48, Color("8a7a5a"), Vector3(0, 0.5, 0.53), Vector3.ZERO, 0.0045, 0)
	# the freezer door: a hinge on the left, it opens to bite
	var jaw := Node3D.new()
	jaw.position = Vector3(-0.62, 1.95, 0.5)
	body.add_child(jaw)
	Kit.part(jaw, Kit.BOX, cream, Vector3(1.26, 0.62, 0.1), Vector3(0.62, 0, 0.02))
	Kit.part(jaw, Kit.BOX, chrome, Vector3(0.36, 0.06, 0.06), Vector3(1.0, -0.22, 0.09))
	# magnets for eyes and a magnet mustache
	for k in [-1, 1]:
		Kit.part(jaw, Kit.CYL, _m([Color("e8323c"), Color("3a7ac8")][(k + 1) / 2], 0.4), Vector3(0.22, 0.04, 0.22), Vector3(0.62 + 0.24 * k, 0.08, 0.09), Vector3(PI / 2, 0, 0))
		Kit.part(jaw, Kit.SPH, _m(Color("15161c"), 0.2), Vector3(0.08, 0.1, 0.04), Vector3(0.62 + 0.24 * k, 0.07, 0.11))
		Kit.part(jaw, Kit.BOX, _m(Color("2a1a14")), Vector3(0.18, 0.04, 0.03), Vector3(0.62 + 0.24 * k, 0.23, 0.1), Vector3(0, 0, 0.35 * k))
	# icy teeth and the blue inside
	Kit.part(body, Kit.BOX, Kit.mat(Color("8ad8ff"), 0.2, 0.0, Color("6ac8ff"), 0.6), Vector3(1.1, 0.5, 0.05), Vector3(0, 1.95, 0.46))
	for k in range(6):
		Kit.part(body, Kit.CONE, _m(Color("e8f8ff"), 0.15), Vector3(0.12, 0.2, 0.12), Vector3(-0.45 + k * 0.18, 1.74, 0.48), Vector3(PI, 0, 0))
	var feet := []
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			feet.append(Kit.part(body, Kit.CYL, _m(Color("3a3e48"), 0.4, 0.6), Vector3(0.14, 0.16, 0.14), Vector3(0.48 * sx, 0.08, 0.36 * sz)))
	var frost := Kit.part(body, Kit.SPH, Kit.glow_material(Color("bfe8ff"), 0.45), Vector3.ONE * 0.9, Vector3(0, 1.9, 0.95))
	frost.visible = false
	_shadow(g, 1.5)
	return {"root": g, "body": body, "head": jaw, "wings": [jaw], "wheels": feet, "frost": frost}


## Матрас-пружина: a striped mattress standing on its springs, grinning; a pillow on top like a hat
static func mattress() -> Dictionary:
	Kit.init()
	var g := Node3D.new()
	var body := Node3D.new()
	g.add_child(body)
	var blue := _m(Color("3a6ab8"), 0.9)
	var white := _m(Color("eef0f6"), 0.9)
	Kit.part(body, Kit.BOX, white, Vector3(1.3, 1.7, 0.4), Vector3(0, 1.35, 0))
	for k in range(5):
		Kit.part(body, Kit.BOX, blue, Vector3(0.12, 1.7, 0.41), Vector3(-0.52 + k * 0.26, 1.35, 0))
	for k in range(6):
		Kit.part(body, Kit.SPH, _m(Color("2a4a8a"), 0.8), Vector3.ONE * 0.06, Vector3(-0.45 + (k % 3) * 0.45, 1.8 - int(k / 3) * 0.7, 0.21))
	# the pillow «hat»
	Kit.part(body, Kit.SPH, _m(Color("fff8e8"), 0.95), Vector3(1.0, 0.3, 0.5), Vector3(0, 2.32, 0))
	var head := Node3D.new()
	head.position = Vector3(0, 1.55, 0.21)
	body.add_child(head)
	_eyes(head, 0.18, 0.02, 0.24, 0.17, -0.3)
	Kit.part(head, Kit.BOX, _m(Color("6a2a2a"), 0.6), Vector3(0.6, 0.1, 0.03), Vector3(0, -0.2, 0.02))
	for k in range(5):
		Kit.part(head, Kit.BOX, white, Vector3(0.08, 0.06, 0.03), Vector3(-0.2 + k * 0.1, -0.16, 0.035))
	# springs under it
	var springs := []
	var steel := _m(Color("a8aeb8"), 0.2, 0.9)
	for sx in [-0.4, 0.4]:
		var sp := Node3D.new()
		sp.position = Vector3(sx, 0.0, 0)
		body.add_child(sp)
		for k in range(4):
			Kit.torus(sp, steel, 0.11, 0.16, Vector3(0, 0.07 + k * 0.12, 0), Vector3.ZERO)
		springs.append(sp)
	# a spring popping out of the side
	Kit.torus(body, steel, 0.06, 0.1, Vector3(0.68, 1.0, 0.0), Vector3(0, 0, PI / 2))
	Kit.torus(body, steel, 0.06, 0.1, Vector3(0.78, 1.0, 0.0), Vector3(0, 0, PI / 2))
	_shadow(g, 1.3)
	return {"root": g, "body": body, "head": head, "wings": [], "wheels": springs}


## A rolling bag of trash thrown by the King (shot)
static func trash_shot() -> Node3D:
	var n := Node3D.new()
	Kit.part(n, Kit.SPH, Kit.mat(Color("1a1d24"), 0.3, 0.2), Vector3(0.6, 0.55, 0.6))
	Kit.part(n, Kit.CONE, Kit.mat(Color("1a1d24"), 0.3, 0.2), Vector3(0.2, 0.2, 0.2), Vector3(0, 0.34, 0))
	Kit.part(n, Kit.BOX, Kit.mat(Color("f2c21a"), 0.6), Vector3(0.24, 0.05, 0.05), Vector3(0, 0.42, 0))
	return n


# =================================================================== the boss
## Король Хлама: Koschei's garbage truck with a golden crown on the cab, headlights for eyes, a grille with teeth,
## bin-lifter forks for hands and the rear press — the jaw that «утрамбовывает»
static func king() -> Dictionary:
	Kit.init()
	var g := Node3D.new()
	var body := Node3D.new()
	g.add_child(body)
	var green := _m(Color("2a6a3a"), 0.5, 0.3)
	var green2 := _m(Color("1e4a2a"), 0.5, 0.3)
	var steel := _m(Color("7a808a"), 0.3, 0.8)
	var dark := _m(Color("22252c"), 0.6, 0.4)
	# chassis and wheels
	Kit.part(body, Kit.BOX, dark, Vector3(2.8, 0.5, 7.2), Vector3(0, 0.9, 0))
	var wheels := []
	for sx in [-1, 1]:
		for z in [2.3, -1.2, -2.6]:
			var w := Node3D.new()
			w.position = Vector3(1.35 * sx, 0.62, z)
			body.add_child(w)
			Kit.part(w, Kit.CYL, _m(Color("15161c"), 0.8), Vector3(1.24, 0.5, 1.24), Vector3.ZERO, Vector3(0, 0, PI / 2))
			Kit.part(w, Kit.CYL, steel, Vector3(0.6, 0.52, 0.6), Vector3.ZERO, Vector3(0, 0, PI / 2))
			for k in range(3):
				Kit.part(w, Kit.BOX, steel, Vector3(0.54, 0.08, 0.1), Vector3(0.0, 0, 0), Vector3(k * PI / 3, 0, 0))
			wheels.append(w)
	# the cab = the face
	var head := Node3D.new()
	head.position = Vector3(0, 1.9, 2.75)
	body.add_child(head)
	Kit.part(head, Kit.BOX, green, Vector3(2.8, 2.2, 1.8), Vector3(0, 0.3, 0))
	Kit.part(head, Kit.BOX, _m(Color("0c1220"), 0.1, 0.5), Vector3(2.5, 0.8, 0.06), Vector3(0, 0.75, 0.91))
	for k in [-1, 1]:
		Kit.part(head, Kit.CYL, steel, Vector3(0.62, 0.1, 0.62), Vector3(0.9 * k, -0.25, 0.92), Vector3(PI / 2, 0, 0))
		Kit.part(head, Kit.CYL, Kit.mat(Color("fff2a0"), 0.1, 0.0, Color("ffd84a"), 3.0), Vector3(0.5, 0.11, 0.5), Vector3(0.9 * k, -0.25, 0.95), Vector3(PI / 2, 0, 0))
		Kit.part(head, Kit.CYL, _m(Color("15161c"), 0.2), Vector3(0.2, 0.12, 0.2), Vector3(0.9 * k, -0.27, 0.99), Vector3(PI / 2, 0, 0))
		Kit.part(head, Kit.BOX, dark, Vector3(0.7, 0.12, 0.08), Vector3(0.9 * k, 0.12, 0.95), Vector3(0, 0, 0.35 * k))
	# grille with teeth = the mouth
	Kit.part(head, Kit.BOX, dark, Vector3(1.2, 0.5, 0.06), Vector3(0, -0.72, 0.93))
	for k in range(7):
		Kit.part(head, Kit.BOX, _m(Color("eeeeee"), 0.3, 0.4), Vector3(0.12, 0.2, 0.06), Vector3(-0.5 + k * 0.166, -0.6, 0.97))
		Kit.part(head, Kit.BOX, _m(Color("eeeeee"), 0.3, 0.4), Vector3(0.12, 0.2, 0.06), Vector3(-0.42 + k * 0.166, -0.86, 0.97))
	Kit.part(head, Kit.BOX, steel, Vector3(3.0, 0.3, 0.3), Vector3(0, -1.0, 0.95))
	# the crown
	var crown := Node3D.new()
	crown.position = Vector3(0, 1.5, 0)
	head.add_child(crown)
	var gold := Kit.mat(Color("f2c14e"), 0.2, 1.0, Color("f2a81e"), 0.4)
	Kit.part(crown, Kit.CYL, gold, Vector3(1.8, 0.4, 1.4), Vector3(0, 0, 0))
	for k in range(7):
		var a := k * TAU / 7.0
		Kit.part(crown, Kit.CONE, gold, Vector3(0.3, 0.6, 0.3), Vector3(sin(a) * 0.85, 0.45, cos(a) * 0.65))
		Kit.part(crown, Kit.SPH, Kit.neon([Color("ff3a4a"), Color("3a8aff"), Color("3aff8a")][k % 3], 2.5), Vector3.ONE * 0.14, Vector3(sin(a) * 0.9, 0.0, cos(a) * 0.7))
	# the body of the truck
	Kit.part(body, Kit.BOX, green, Vector3(2.9, 2.7, 4.6), Vector3(0, 2.5, -1.0))
	Kit.part(body, Kit.BOX, green2, Vector3(2.92, 0.3, 4.62), Vector3(0, 1.4, -1.0))
	for k in [-1, 1]:
		Chars.label(body, "КОРОЛЬ ХЛАМА", 90, Color("f2c14e"), Vector3(1.47 * k, 2.85, -1.0), Vector3(0, PI / 2 * k, 0), 0.008, 6)
		Chars.label(body, "ООО «ТИШИНА ПЛЮС» · УТИЛИЗАЦИЯ", 44, Color("e8e8e8"), Vector3(1.47 * k, 2.2, -1.0), Vector3(0, PI / 2 * k, 0), 0.006, 4)
	# the rear press — the hopper jaw
	var press := Node3D.new()
	press.position = Vector3(0, 3.6, -3.3)
	body.add_child(press)
	Kit.part(press, Kit.BOX, green2, Vector3(2.9, 0.4, 1.4), Vector3(0, 0, -0.7))
	Kit.part(press, Kit.BOX, green2, Vector3(2.9, 2.2, 0.3), Vector3(0, -1.1, -1.35))
	for k in range(6):
		Kit.part(press, Kit.CONE, _m(Color("c8ccd4"), 0.2, 0.9), Vector3(0.22, 0.4, 0.22), Vector3(-1.1 + k * 0.44, -2.2, -1.35), Vector3(PI, 0, 0))
	Kit.part(body, Kit.BOX, _m(Color("0a0a0c"), 0.9), Vector3(2.5, 2.0, 0.2), Vector3(0, 2.2, -3.45))
	# trash sticking out of the press
	var junk := [Color("e8323c"), Color("3a7ac8"), Color("f2c21a"), Color("f4f4f4"), Color("8a4ad8")]
	for k in range(8):
		Kit.part(body, Kit.BOX, _m(junk[k % junk.size()], 0.7), Vector3(0.4, 0.3, 0.3), Vector3(-1.0 + k * 0.28, 3.85 + sin(k * 2.0) * 0.1, -3.2 + cos(k) * 0.15), Vector3(k * 0.4, k * 0.7, 0))
	# bin-lifter forks in front = the hands
	var forks := []
	for k in [-1, 1]:
		var f := Node3D.new()
		f.position = Vector3(0.8 * k, 1.0, 3.7)
		body.add_child(f)
		Kit.part(f, Kit.BOX, steel, Vector3(0.18, 0.18, 1.2), Vector3(0, 0, 0.5))
		Kit.part(f, Kit.BOX, steel, Vector3(0.18, 0.7, 0.18), Vector3(0, 0.3, 1.05))
		forks.append(f)
	# orange beacons and the exhaust
	var beacons := []
	for k in [-1, 1]:
		var bp := Node3D.new()   # a pivot: bake_tree keeps it, so the beacon can blink
		bp.position = Vector3(1.2 * k, 3.98, 1.0)
		body.add_child(bp)
		Kit.part(bp, Kit.SPH, Kit.neon(Color("ff8a1a"), 4.0), Vector3(0.3, 0.24, 0.3))
		beacons.append(bp)
	Kit.part(body, Kit.CYL, steel, Vector3(0.18, 2.0, 0.18), Vector3(1.55, 3.1, 1.6))
	var smoke := Kit.part(body, Kit.SPH, Kit.glow_material(Color(0.6, 0.6, 0.65), 0.5), Vector3.ONE * 0.8, Vector3(1.55, 4.4, 1.6))
	smoke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_shadow(g, 5.0)
	return {"root": g, "body": body, "head": head, "wings": forks, "wheels": wheels, "press": press, "beacons": beacons, "smoke": smoke, "crown": crown}


# =================================================================== people
## Дед Утиль: an old inventor with a long white beard, welding goggles on the forehead, a patched coat and a pipe for a cane
static func ded() -> Dictionary:
	var h := Chars.human({"top": Color("7a5a3a"), "pants": Color("4a4a3a"), "shoes": Color("3a2a1a"), "hair_color": Color("e8e8e0"),
		"skin": Color("e8b898"), "smirk": 0.25, "width": 1.05, "brow": Color("d8d8d0")})
	var white := _m(Color("f2f2ea"), 0.9)
	Kit.part(h.head, Kit.SPH, white, Vector3(0.5, 0.5, 0.3), Vector3(0, -0.3, 0.22))
	Kit.part(h.head, Kit.CONE, white, Vector3(0.38, 0.6, 0.24), Vector3(0, -0.66, 0.26), Vector3(PI, 0, 0))
	for k in [-1, 1]:
		Kit.part(h.head, Kit.SPH, white, Vector3(0.2, 0.1, 0.1), Vector3(0.09 * k, -0.12, 0.33), Vector3(0, 0, 0.3 * k))
		var brass := _m(Color("c8963a"), 0.3, 0.8)
		Kit.part(h.head, Kit.CYL, brass, Vector3(0.2, 0.08, 0.2), Vector3(0.12 * k, 0.28, 0.24), Vector3(PI / 2 - 0.5, 0, 0))
		Kit.part(h.head, Kit.CYL, Kit.mat(Color("6ad8a0"), 0.05, 0.5, Color("6ad8a0"), 0.6), Vector3(0.16, 0.09, 0.16), Vector3(0.12 * k, 0.29, 0.26), Vector3(PI / 2 - 0.5, 0, 0))
	Kit.part(h.head, Kit.CYL, _m(Color("3a2a1a"), 0.6), Vector3(0.74, 0.06, 0.66), Vector3(0, 0.24, -0.02), Vector3(-0.2, 0, 0))
	# patches on the coat
	var pc := [Color("c8323c"), Color("3a7ac8"), Color("e8b83a"), Color("4a9a5a")]
	for k in range(4):
		Kit.part(h.body, Kit.BOX, _m(pc[k], 0.9), Vector3(0.2, 0.2, 0.03), Vector3(-0.3 + k * 0.2, 0.75 + (k % 2) * 0.3, 0.5), Vector3(0, 0, k * 0.3))
	# the pipe-cane
	var cane := Node3D.new()
	h.hands[1].add_child(cane)
	Kit.part(cane, Kit.CYL, _m(Color("8a929e"), 0.3, 0.8), Vector3(0.07, 1.3, 0.07), Vector3(0, -0.45, 0.08))
	Kit.part(cane, Kit.CYL, _m(Color("8a929e"), 0.3, 0.8), Vector3(0.07, 0.25, 0.07), Vector3(0, 0.2, 0.18), Vector3(PI / 2, 0, 0))
	# a backpack of gadgets with a tiny windmill
	Kit.part(h.body, Kit.BOX, _m(Color("5a4a3a"), 0.8), Vector3(0.6, 0.62, 0.3), Vector3(0, 0.95, -0.42))
	Kit.part(h.body, Kit.CYL, _m(Color("2a2a30"), 0.4, 0.6), Vector3(0.04, 0.8, 0.04), Vector3(0.22, 1.6, -0.45))
	var prop := Node3D.new()
	prop.position = Vector3(0.22, 2.0, -0.42)
	h.body.add_child(prop)
	for k in range(3):
		Kit.part(prop, Kit.BOX, _m(Color("e8323c"), 0.6), Vector3(0.05, 0.3, 0.02), Vector3(0, 0.15, 0).rotated(Vector3(0, 0, 1), k * TAU / 3.0), Vector3(0, 0, k * TAU / 3.0))
	h["prop"] = prop
	return h


## Кеша Вторсырьё: a young inventor in a hoodie stitched from colourful bags, a cap with a propeller, a robotic glove and a backpack with an antenna
static func kesha() -> Dictionary:
	var h := Chars.human({"top": Color("3a8a5a"), "pants": Color("2a3a5a"), "shoes": Color("e8e8e8"), "hair": "cap_back", "hair_color": Color("c86a2a"),
		"skin": Color("f0c49a"), "smirk": 0.35, "backpack": true})
	var pc := [Color("e8323c"), Color("3a7ac8"), Color("f2c21a"), Color("f4f4f4"), Color("8a4ad8")]
	for k in range(6):
		Kit.part(h.body, Kit.BOX, _m(pc[k % pc.size()], 0.9), Vector3(0.22, 0.18, 0.03), Vector3(-0.38 + (k % 3) * 0.38, 0.75 + int(k / 3) * 0.32, 0.49), Vector3(0, 0, (k - 2) * 0.2))
	# the propeller on the cap
	var prop := Node3D.new()
	prop.position = Vector3(0, 0.42, 0.0)
	h.head.add_child(prop)
	Kit.part(prop, Kit.CYL, _m(Color("2a2a30"), 0.4), Vector3(0.05, 0.12, 0.05), Vector3(0, -0.04, 0))
	Kit.part(prop, Kit.BOX, _m(Color("e8323c"), 0.6), Vector3(0.6, 0.02, 0.08), Vector3(0, 0.03, 0))
	Kit.part(prop, Kit.BOX, _m(Color("3a7ac8"), 0.6), Vector3(0.08, 0.02, 0.6), Vector3(0, 0.03, 0))
	h["prop"] = prop
	# the robotic glove
	var steel := _m(Color("a8b0bc"), 0.25, 0.9)
	Kit.part(h.hands[1], Kit.BOX, steel, Vector3(0.24, 0.22, 0.24))
	for k in range(3):
		Kit.part(h.hands[1], Kit.BOX, steel, Vector3(0.05, 0.16, 0.05), Vector3(-0.07 + k * 0.07, -0.16, 0.08))
	Kit.part(h.hands[1], Kit.SPH, Kit.neon(Kit.TEAL, 2.5), Vector3.ONE * 0.06, Vector3(0, 0.02, 0.13))
	# a screwdriver behind the ear and an antenna on the backpack
	Kit.part(h.head, Kit.CYL, _m(Color("f2c21a"), 0.5), Vector3(0.04, 0.3, 0.04), Vector3(0.36, 0.08, -0.02), Vector3(0.5, 0, 0.2))
	Kit.part(h.body, Kit.CYL, _m(Color("2a2a30"), 0.4, 0.6), Vector3(0.03, 0.9, 0.03), Vector3(-0.18, 1.6, -0.45))
	Kit.part(h.body, Kit.SPH, Kit.neon(Color("ff5d7a"), 3.0), Vector3.ONE * 0.08, Vector3(-0.18, 2.06, -0.45))
	return h


## Вася-3000 at the dump (the same robot as in the garages, with a small cart of finds)
static func vasya() -> Dictionary:
	var r := Chars.robot()
	var ct := Chars.cart()
	r.root.add_child(ct)
	ct.position = Vector3(0, 0, 1.55)
	return r


# =================================================================== props of the dump
static func junk_pile(parent: Node3D, at: Vector3, size: float, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var base := [Color("6a6458"), Color("5a5650"), Color("7a6a54")]
	Kit.part(parent, Kit.SPH, _m(base[seed % 3], 1.0), Vector3(size * 2.2, size * 1.1, size * 1.9), at + Vector3(0, size * 0.05, 0))
	var cols := [Color("e8323c"), Color("3a7ac8"), Color("f2c21a"), Color("eef0f4"), Color("4a9a5a"), Color("8a4ad8"), Color("2a2a30"), Color("a8743e")]
	for k in range(int(8 + size * 3)):
		var a := rng.randf() * TAU
		var rr := rng.randf_range(0.1, 0.95) * size
		var y := size * 0.55 * (1.0 - rr / size) + rng.randf() * 0.3
		var p := at + Vector3(sin(a) * rr, y, cos(a) * rr * 0.85)
		var c: Color = cols[rng.randi() % cols.size()]
		match rng.randi() % 5:
			0: Kit.part(parent, Kit.BOX, _m(c, 0.7), Vector3(rng.randf_range(0.3, 0.9), rng.randf_range(0.2, 0.6), rng.randf_range(0.3, 0.8)), p, Vector3(rng.randf(), rng.randf() * 3, rng.randf()))
			1: Kit.torus(parent, _m(Color("1d1e24"), 0.8), 0.16, 0.4, p, Vector3(rng.randf() * 1.5, 0, rng.randf()))
			2: Kit.part(parent, Kit.CYL, _m(c, 0.5, 0.3), Vector3(0.4, rng.randf_range(0.4, 0.9), 0.4), p, Vector3(rng.randf() * 1.5, 0, rng.randf() * 1.5))
			3: Kit.part(parent, Kit.SPH, _m(c, 0.8), Vector3.ONE * rng.randf_range(0.3, 0.6), p)
			_: Kit.part(parent, Kit.BOX, _m(Color("eef0f4"), 0.4), Vector3(0.7, 0.9, 0.6), p, Vector3(0, rng.randf() * 3, rng.randf() * 0.6))


## The inventors' shack: doors and pallets, a tarp roof, a light-bulb garland
static func shack(parent: Node3D, at: Vector3, rot: float) -> void:
	var s := Node3D.new()
	s.position = at
	s.rotation.y = rot
	parent.add_child(s)
	var wood := _m(Color("a8743e"), 0.85)
	var doors := [Color("2a7a8a"), Color("c8323c"), Color("e8e0d0"), Color("3a5a2a")]
	for k in range(4):
		Kit.part(s, Kit.BOX, _m(doors[k], 0.7), Vector3(0.9, 2.2, 0.08), Vector3(-1.4 + k * 0.92, 1.1, -1.4), Vector3(0, 0, (k - 1.5) * 0.02))
	for sx in [-1, 1]:
		Kit.part(s, Kit.BOX, wood, Vector3(0.12, 2.2, 2.8), Vector3(1.9 * sx, 1.1, 0))
		Kit.part(s, Kit.BOX, wood, Vector3(0.12, 2.6, 0.12), Vector3(1.9 * sx, 1.3, 1.4))
	Kit.part(s, Kit.BOX, _m(Color("2a5ac8"), 0.6), Vector3(4.2, 0.08, 3.6), Vector3(0, 2.5, 0.2), Vector3(0.12, 0, 0))
	Kit.part(s, Kit.BOX, wood, Vector3(3.6, 0.15, 1.0), Vector3(0, 0.1, -0.8))
	Chars.label(s, "ЛАБОРАТОРИЯ «ХЛАМ И ИДЕЯ»", 60, Color("ffe8a0"), Vector3(0, 2.25, -1.33), Vector3.ZERO, 0.0055, 6)
	var cols := [Kit.GOLD, Color("ff5d7a"), Kit.TEAL]
	for k in range(9):
		Kit.part(s, Kit.SPH, Kit.neon(cols[k % 3], 3.0), Vector3.ONE * 0.12, Vector3(-1.8 + k * 0.45, 2.35 - sin(k / 8.0 * PI) * 0.25, 1.45))


## A windmill made of old computer fans — «ветер без пароля». Returns the rotor to spin.
static func windmill(parent: Node3D, at: Vector3) -> Node3D:
	var w := Node3D.new()
	w.position = at
	parent.add_child(w)
	var steel := _m(Color("8a929e"), 0.3, 0.8)
	for k in range(3):
		var a := k * TAU / 3.0
		Kit.part(w, Kit.CYL, steel, Vector3(0.1, 5.2, 0.1), Vector3(sin(a) * 0.5, 2.5, cos(a) * 0.5), Vector3(cos(a) * 0.1, 0, -sin(a) * 0.1))
	Kit.part(w, Kit.BOX, _m(Color("2a2a30"), 0.4, 0.5), Vector3(0.6, 0.5, 0.9), Vector3(0, 5.2, 0))
	var rotor := Node3D.new()
	rotor.position = Vector3(0, 5.2, 0.55)
	w.add_child(rotor)
	for k in range(4):
		var b := Node3D.new()
		b.rotation.z = k * TAU / 4.0
		rotor.add_child(b)
		Kit.part(b, Kit.BOX, _m([Color("eef0f4"), Color("2a2a30"), Color("eef0f4"), Color("e8323c")][k], 0.5), Vector3(0.36, 1.6, 0.05), Vector3(0, 0.9, 0))
		Kit.part(b, Kit.CYL, _m(Color("1a1a1e"), 0.5), Vector3(0.4, 0.06, 0.4), Vector3(0, 1.4, 0.03), Vector3(PI / 2, 0, 0))
	Kit.part(rotor, Kit.SPH, Kit.neon(Kit.TEAL, 2.5), Vector3.ONE * 0.24)
	Chars.label(w, "ВАЙ-ФАЙ «ВЕТЕР» · БЕЗ ПАРОЛЯ", 44, Color("cfe8ff"), Vector3(0, 4.6, 0.5), Vector3.ZERO, 0.0055, 6)
	return rotor


static func sofa(parent: Node3D, at: Vector3, rot: float) -> void:
	var s := Node3D.new()
	s.position = at
	s.rotation.y = rot
	parent.add_child(s)
	var red := _m(Color("8a2a3a"), 0.95)
	Kit.part(s, Kit.BOX, red, Vector3(2.4, 0.5, 0.9), Vector3(0, 0.35, 0))
	Kit.part(s, Kit.BOX, red, Vector3(2.4, 0.8, 0.25), Vector3(0, 0.8, -0.4))
	for k in [-1, 1]:
		Kit.part(s, Kit.BOX, red, Vector3(0.25, 0.65, 0.9), Vector3(1.2 * k, 0.55, 0))
	Kit.torus(s, _m(Color("a8aeb8"), 0.2, 0.9), 0.05, 0.09, Vector3(0.5, 0.62, 0.1), Vector3(PI / 2, 0, 0))


static func bonfire(parent: Node3D, at: Vector3) -> Node3D:
	var b := Node3D.new()
	b.position = at
	parent.add_child(b)
	for k in range(6):
		var a := k * TAU / 6.0
		Kit.part(b, Kit.SPH, _m(Color("6a6a70"), 1.0), Vector3(0.32, 0.22, 0.3), Vector3(sin(a) * 0.55, 0.1, cos(a) * 0.55))
	for k in range(3):
		Kit.part(b, Kit.CYL, _m(Color("6a4a2a"), 0.9), Vector3(0.12, 0.9, 0.12), Vector3(0, 0.2, 0), Vector3(PI / 2, k * PI / 3, 0))
	var flame := Node3D.new()
	b.add_child(flame)
	Kit.part(flame, Kit.CONE, Kit.neon(Color("ff8a2a"), 4.0), Vector3(0.5, 0.8, 0.5), Vector3(0, 0.55, 0))
	Kit.part(flame, Kit.CONE, Kit.neon(Color("ffd84a"), 5.0), Vector3(0.28, 0.5, 0.28), Vector3(0, 0.5, 0))
	# the kettle on a tripod
	for k in range(3):
		var a := k * TAU / 3.0
		Kit.part(b, Kit.CYL, _m(Color("2a2a30"), 0.4, 0.6), Vector3(0.04, 1.5, 0.04), Vector3(sin(a) * 0.5, 0.7, cos(a) * 0.5), Vector3(-cos(a) * 0.35, 0, sin(a) * 0.35))
	Kit.part(b, Kit.SPH, _m(Color("c8963a"), 0.3, 0.8), Vector3(0.36, 0.3, 0.36), Vector3(0, 1.15, 0))
	var light := OmniLight3D.new()
	light.light_color = Color("ffb060")
	light.light_energy = 1.6
	light.omni_range = 6.0
	light.position = Vector3(0, 1.0, 0)
	b.add_child(light)
	return flame


static func fridge_decor(parent: Node3D, at: Vector3, rot: float, tilt := 0.0) -> void:
	var f := Node3D.new()
	f.position = at
	f.rotation = Vector3(tilt, rot, 0)
	parent.add_child(f)
	var c: Color = [Color("f2ecd8"), Color("e8eef4"), Color("c8e0d0"), Color("f0d8c8")][int(absf(at.x * 7.0 + at.z)) % 4]
	Kit.part(f, Kit.BOX, _m(c, 0.4), Vector3(1.2, 2.0, 1.0), Vector3(0, 1.0, 0))
	Kit.part(f, Kit.BOX, _m(Color("c8ccd4"), 0.15, 0.9), Vector3(0.07, 0.5, 0.07), Vector3(0.44, 1.2, 0.52))
	Kit.part(f, Kit.BOX, _m(c.darkened(0.15), 0.4), Vector3(1.22, 0.04, 1.02), Vector3(0, 1.45, 0))


static func container(parent: Node3D, at: Vector3, rot: float, col: Color) -> void:
	var c := Node3D.new()
	c.position = at
	c.rotation.y = rot
	parent.add_child(c)
	Kit.part(c, Kit.BOX, _m(col, 0.6, 0.3), Vector3(2.0, 1.3, 1.3), Vector3(0, 0.75, 0))
	Kit.part(c, Kit.BOX, _m(col.darkened(0.3), 0.6, 0.3), Vector3(2.05, 0.1, 1.35), Vector3(0, 1.43, 0), Vector3(0.15, 0, 0))
	for sx in [-0.8, 0.8]:
		for sz in [-0.5, 0.5]:
			Kit.part(c, Kit.CYL, _m(Color("15161c"), 0.8), Vector3(0.2, 0.08, 0.2), Vector3(sx, 0.1, sz), Vector3(0, 0, PI / 2))


## The written-off corn plane «Кукурузник» — a fuselage with one wing
static func plane_wreck(parent: Node3D, at: Vector3, rot: float) -> void:
	var p := Node3D.new()
	p.position = at
	p.rotation.y = rot
	parent.add_child(p)
	var green := _m(Color("4a7a4a"), 0.7, 0.2)
	Kit.part(p, Kit.CAP, green, Vector3(1.4, 5.0, 1.4), Vector3(0, 0.8, 0), Vector3(PI / 2, 0, 0.15))
	Kit.part(p, Kit.BOX, green, Vector3(5.6, 0.12, 1.2), Vector3(0.8, 1.2, 0.6), Vector3(0, 0, -0.12))
	Kit.part(p, Kit.BOX, green, Vector3(0.1, 1.0, 0.9), Vector3(0, 1.4, -2.4))
	Kit.part(p, Kit.CYL, _m(Color("2a2a30"), 0.4), Vector3(0.5, 0.3, 0.5), Vector3(0, 0.8, 2.5), Vector3(PI / 2, 0, 0))
	Chars.label(p, "СПИСАН", 60, Color("f4f4f4"), Vector3(0.72, 0.9, 0.0), Vector3(0, PI / 2, 0), 0.006, 4)


## The scrapyard crane with a magnet holding a car
static func crane(parent: Node3D, at: Vector3) -> void:
	var c := Node3D.new()
	c.position = at
	parent.add_child(c)
	var yel := _m(Color("f2b21c"), 0.5, 0.4)
	Kit.part(c, Kit.BOX, _m(Color("3a3a42"), 0.7), Vector3(3.0, 1.2, 3.6), Vector3(0, 0.6, 0))
	Kit.part(c, Kit.BOX, yel, Vector3(2.0, 1.6, 2.0), Vector3(0, 2.0, 0.2))
	Kit.part(c, Kit.BOX, yel, Vector3(0.5, 0.5, 9.0), Vector3(0, 5.0, 4.0), Vector3(-0.55, 0, 0))
	Kit.part(c, Kit.CYL, _m(Color("2a2a2a"), 0.5, 0.8), Vector3(0.04, 3.0, 0.04), Vector3(0, 5.7, 7.6))
	Kit.part(c, Kit.CYL, _m(Color("5a5e66"), 0.4, 0.8), Vector3(1.4, 0.3, 1.4), Vector3(0, 4.1, 7.6))
	var car := Node3D.new()
	car.position = Vector3(0, 3.0, 7.6)
	car.rotation = Vector3(0.1, 0.6, 0.15)
	c.add_child(car)
	Kit.part(car, Kit.BOX, _m(Color("c8323c"), 0.5, 0.4), Vector3(1.8, 0.7, 3.6), Vector3(0, -0.3, 0))
	Kit.part(car, Kit.BOX, _m(Color("c8323c"), 0.5, 0.4), Vector3(1.6, 0.6, 1.8), Vector3(0, 0.3, -0.2))
	Kit.part(car, Kit.BOX, _m(Color("8ab8d8"), 0.1, 0.4), Vector3(1.62, 0.4, 1.4), Vector3(0, 0.32, -0.2))


static func mattress_pile(parent: Node3D, at: Vector3) -> void:
	var cols := [Color("3a6ab8"), Color("e8e0d0"), Color("c8323c"), Color("4a9a5a")]
	for k in range(6):
		Kit.part(parent, Kit.BOX, _m(cols[k % 4], 0.95), Vector3(2.0, 0.3, 1.4), at + Vector3(sin(k * 1.3) * 0.3, 0.15 + k * 0.3, cos(k * 1.7) * 0.2), Vector3(0, k * 0.4, sin(k) * 0.05))
	Kit.torus(parent, _m(Color("a8aeb8"), 0.2, 0.9), 0.06, 0.1, at + Vector3(0.9, 1.9, 0.0), Vector3(0, 0, PI / 2))


static func old_tv(parent: Node3D, at: Vector3, rot: float) -> void:
	var t := Node3D.new()
	t.position = at
	t.rotation.y = rot
	parent.add_child(t)
	Kit.part(t, Kit.BOX, _m(Color("6a4a2a"), 0.6), Vector3(1.0, 0.8, 0.8), Vector3(0, 0.4, 0))
	Kit.part(t, Kit.BOX, Kit.mat(Color("c8e8ff"), 0.2, 0.0, Color("9ad8ff"), 1.6), Vector3(0.74, 0.56, 0.02), Vector3(-0.06, 0.42, 0.41))
	for k in [-1, 1]:
		Kit.part(t, Kit.CYL, _m(Color("2a2a30"), 0.4, 0.6), Vector3(0.02, 0.6, 0.02), Vector3(0.15 * k, 1.0, 0), Vector3(0, 0, 0.5 * k))


## The «Ёжик» cart, the mount skin from «Утилизация отменяется»: a big shopping cart with a propeller on the nose
static func ride_cart() -> Dictionary:
	Kit.init()
	var g := Node3D.new()
	var wire := _m(Color("c8ccd4"), 0.25, 1.0)
	var red := _m(Color("e8233c"), 0.5)
	var L := 2.4
	var W := 1.4
	var H := 1.0
	var by := 0.8
	for x in [-W / 2, W / 2]:
		for z in [-L / 2, L / 2]:
			Kit.part(g, Kit.BOX, wire, Vector3(0.05, H, 0.05), Vector3(x, by + H / 2, z))
	for k in range(5):
		var yy := by + k * H / 4
		for x in [-W / 2, W / 2]:
			Kit.part(g, Kit.BOX, wire, Vector3(0.03, 0.03, L), Vector3(x, yy, 0))
		for z in [-L / 2, L / 2]:
			Kit.part(g, Kit.BOX, wire, Vector3(W, 0.03, 0.03), Vector3(0, yy, z))
	for k in range(9):
		var zz := -L / 2 + k * L / 8
		for x in [-W / 2, W / 2]:
			Kit.part(g, Kit.BOX, wire, Vector3(0.02, H, 0.02), Vector3(x, by + H / 2, zz))
	Kit.part(g, Kit.BOX, _m(Color("2a2a30"), 0.6), Vector3(W, 0.06, L), Vector3(0, by, 0))
	Kit.part(g, Kit.CYL, red, Vector3(0.1, W + 0.2, 0.1), Vector3(0, by + H + 0.25, -L / 2 - 0.3), Vector3(0, 0, PI / 2))
	for x in [-W / 2, W / 2]:
		Kit.part(g, Kit.BOX, wire, Vector3(0.05, 0.5, 0.05), Vector3(x, by + H + 0.05, -L / 2 - 0.16), Vector3(-0.5, 0, 0))
	var wheels := []
	for x in [-W / 2 + 0.1, W / 2 - 0.1]:
		for z in [-L / 2 + 0.15, L / 2 - 0.15]:
			Kit.part(g, Kit.BOX, wire, Vector3(0.05, by - 0.2, 0.05), Vector3(x, (by + 0.2) / 2, z))
			var w := Node3D.new()
			w.position = Vector3(x, 0.16, z)
			g.add_child(w)
			Kit.part(w, Kit.CYL, _m(Color("1a1a1a")), Vector3(0.32, 0.1, 0.32), Vector3.ZERO, Vector3(0, 0, PI / 2))
			wheels.append(w)
	var prop := Node3D.new()
	prop.position = Vector3(0, by + 0.5, L / 2 + 0.2)
	g.add_child(prop)
	Kit.part(prop, Kit.CYL, _m(Color("2a2a30"), 0.4), Vector3(0.12, 0.2, 0.12), Vector3.ZERO, Vector3(PI / 2, 0, 0))
	Kit.part(prop, Kit.BOX, _m(Color("a8743e"), 0.7), Vector3(1.4, 0.16, 0.04), Vector3(0, 0, 0.08))
	Chars.label(g, "ЁЖИК", 70, Color("ffffff"), Vector3(W / 2 + 0.04, by + 0.5, 0), Vector3(0, PI / 2, 0), 0.006, 6)
	Chars.label(g, "ЁЖИК", 70, Color("ffffff"), Vector3(-W / 2 - 0.04, by + 0.5, 0), Vector3(0, -PI / 2, 0), 0.006, 6)
	return {"root": g, "wheels": wheels, "prop": prop, "floor": by}


# =================================================================== the workshop in box №13 (GK)
static func workshop(parent: Node3D, at: Vector3, built: bool) -> Node3D:
	var w := Node3D.new()
	w.position = at
	w.rotation.y = PI
	parent.add_child(w)
	if not built:
		Kit.part(w, Kit.BOX, _m(Color("6a6a70"), 0.7, 0.3), Vector3(2.8, 2.2, 0.08), Vector3(0, 1.1, 0.02))
		Chars.label(w, "СВОБОДЕН · НИКТО НЕ БЕРЁТ", 40, Color("f4f4f4"), Vector3(0, 1.4, 0.08), Vector3.ZERO, 0.0045, 4)
		return w
	var wood := _m(Color("a8743e"), 0.85)
	var dark := _m(Color("2a2a30"), 0.5, 0.6)
	# the workbench, tools and a lamp
	Kit.part(w, Kit.BOX, wood, Vector3(2.4, 0.1, 0.9), Vector3(0, 0.95, -1.4))
	for sx in [-1.1, 1.1]:
		Kit.part(w, Kit.BOX, wood, Vector3(0.1, 0.95, 0.8), Vector3(sx, 0.47, -1.4))
	Kit.part(w, Kit.BOX, _m(Color("c8323c"), 0.6), Vector3(0.5, 0.25, 0.3), Vector3(-0.7, 1.13, -1.5))
	Kit.part(w, Kit.CYL, _m(Color("a8aeb8"), 0.2, 0.9), Vector3(0.05, 0.5, 0.05), Vector3(0.2, 1.05, -1.3), Vector3(0, 0, PI / 2))
	Kit.part(w, Kit.BOX, Kit.mat(Color("2a5ac8"), 0.6, 0.0, Color("4a8aff"), 0.6), Vector3(1.6, 1.1, 0.04), Vector3(0, 1.9, -2.9))
	for k in range(4):
		Kit.part(w, Kit.BOX, Kit.neon(Color("cfe8ff"), 1.2), Vector3(1.2 - k * 0.2, 0.02, 0.02), Vector3(0, 1.6 + k * 0.22, -2.87))
	Kit.part(w, Kit.CYL, dark, Vector3(0.04, 0.6, 0.04), Vector3(0.9, 1.3, -1.7))
	Kit.part(w, Kit.SPH, Kit.neon(Color("ffe8a0"), 4.0), Vector3.ONE * 0.18, Vector3(0.9, 1.65, -1.5))
	var lamp := OmniLight3D.new()
	lamp.light_color = Color("ffd890")
	lamp.light_energy = 1.4
	lamp.omni_range = 5.0
	lamp.position = Vector3(0, 2.0, -1.0)
	w.add_child(lamp)
	# a sign over the box
	Kit.part(w, Kit.BOX, _m(Color("1a1d24"), 0.6), Vector3(3.2, 0.5, 0.08), Vector3(0, 2.5, 0.1))
	Chars.label(w, "МАСТЕРСКАЯ «ИДЕЯ»", 70, Color(3.0, 2.6, 1.2), Vector3(0, 2.5, 0.16), Vector3.ZERO, 0.0062, 8)
	# a fan windmill on the roof
	var rotor := windmill(w, Vector3(1.2, 2.85, -2.5))
	rotor.get_parent().scale = Vector3.ONE * 0.5
	return w


# =================================================================== levels 4–5 of the buildings
static func building_extra(g: Node3D, id: String, lvl: int) -> void:
	var steel := _m(Color("8a929e"), 0.3, 0.8)
	match id:
		"grill":
			# the reactor: a glowing core with rings; at 5 — a metal firebird on the roof
			var core := Kit.mat(Color("6af0ff"), 0.1, 0.0, Color("6af0ff"), 2.5)
			Kit.part(g, Kit.CYL, core, Vector3(0.5, 1.2, 0.5), Vector3(-1.2, 0.6, -0.2))
			for k in range(3):
				Kit.torus(g, steel, 0.04, 0.32, Vector3(-1.2, 0.25 + k * 0.35, -0.2), Vector3.ZERO)
			Kit.part(g, Kit.CYL, steel, Vector3(0.08, 1.0, 0.08), Vector3(-0.7, 1.0, -0.2), Vector3(0, 0, PI / 2))
			if lvl >= 5:
				var fire := Kit.neon(Color("ff8a2a"), 3.5)
				Kit.part(g, Kit.SPH, Kit.neon(Color("ffd84a"), 4.0), Vector3(0.4, 0.3, 0.5), Vector3(0, 3.5, 0.6))
				for k in [-1, 1]:
					Kit.part(g, Kit.BOX, fire, Vector3(1.2, 0.06, 0.4), Vector3(0.6 * k, 3.6, 0.6), Vector3(0, 0, 0.4 * k))
				Kit.part(g, Kit.CONE, fire, Vector3(0.3, 0.7, 0.3), Vector3(0, 3.4, 0.0), Vector3(-1.2, 0, 0))
		"garden":
			# a washer turned into hydroponics; at 5 — a jar of the eternal dough glowing in the greenhouse
			var white := _m(Color("eef0f4"), 0.35)
			Kit.part(g, Kit.BOX, white, Vector3(0.9, 1.0, 0.8), Vector3(-1.9, 0.5, 0))
			Kit.torus(g, steel, 0.24, 0.32, Vector3(-1.9, 0.55, 0.41), Vector3(PI / 2, 0, 0))
			for k in range(4):
				Kit.part(g, Kit.SPH, _m(Color("4a9a3a"), 0.8), Vector3.ONE * 0.18, Vector3(-1.9 + sin(k * 1.6) * 0.12, 0.55 + cos(k * 1.6) * 0.12, 0.44))
			Kit.part(g, Kit.CYL, _m(Color("3a7ac8"), 0.5), Vector3(0.08, 1.4, 0.08), Vector3(-1.2, 0.9, 0.0), Vector3(0, 0, PI / 2))
			if lvl >= 5:
				Kit.part(g, Kit.CYL, Kit.mat(Color("f2e2bf"), 0.4, 0.0, Color("ffd890"), 1.2), Vector3(0.5, 0.7, 0.5), Vector3(1.6, 0.35, 1.2))
				Kit.part(g, Kit.CYL, _m(Color("c8963a"), 0.3, 0.8), Vector3(0.55, 0.1, 0.55), Vector3(1.6, 0.75, 1.2))
		"gym":
			# concrete dumbbells from the stage of Shumodav; at 5 — a centrifuge drum with a seat
			var conc := _m(Color("9a9690"), 0.95)
			for k in range(2):
				Kit.part(g, Kit.BOX, conc, Vector3(0.5, 0.5, 0.5), Vector3(-0.4 + k * 1.4, 0.25, 1.6))
			Kit.part(g, Kit.CYL, steel, Vector3(0.06, 1.4, 0.06), Vector3(0.3, 0.25, 1.6), Vector3(0, 0, PI / 2))
			Chars.label(g, "БЕТОН", 60, Color("3a3a3a"), Vector3(-0.4, 0.3, 1.86), Vector3.ZERO, 0.004, 0)
			if lvl >= 5:
				Kit.torus(g, _m(Color("eef0f4"), 0.3), 0.6, 0.9, Vector3(-2.2, 1.0, 0.6), Vector3(0, PI / 2, PI / 2))
				Kit.part(g, Kit.BOX, _m(Color("c83a3a"), 0.6), Vector3(0.5, 0.1, 0.5), Vector3(-2.2, 0.9, 0.6))
		"stage":
			# pyrotechnic jets on the front corners; at 5 — a mini ferris wheel behind the stage
			for s in [-1, 1]:
				Kit.part(g, Kit.CYL, steel, Vector3(0.3, 0.5, 0.3), Vector3(1.4 * s, 0.7, -0.9))
				Kit.part(g, Kit.CONE, Kit.neon(Color("ff8a2a"), 4.0), Vector3(0.3, 0.9, 0.3), Vector3(1.4 * s, 1.4, -0.9))
			if lvl >= 5:
				var wh := Node3D.new()
				wh.position = Vector3(0, 2.4, 1.8)
				g.add_child(wh)
				Kit.torus(wh, Kit.neon(Kit.GOLD, 2.0), 1.1, 1.2, Vector3.ZERO, Vector3(PI / 2, 0, 0))
				for k in range(6):
					var a := k * TAU / 6.0
					Kit.part(wh, Kit.BOX, steel, Vector3(0.05, 1.15, 0.05), Vector3(sin(a) * 0.57, cos(a) * 0.57, 0), Vector3(0, 0, -a))
					Kit.part(wh, Kit.BOX, Kit.neon([Color("ff5d7a"), Kit.TEAL, Kit.GOLD][k % 3], 2.0), Vector3(0.24, 0.2, 0.2), Vector3(sin(a) * 1.15, cos(a) * 1.15 - 0.15, 0))
				Kit.part(g, Kit.BOX, steel, Vector3(0.1, 2.4, 0.1), Vector3(0, 1.2, 1.8))
		"studio":
			# a golden record on the wall; at 5 — the neon «БЕССМЕРТНЫЙ ХИТ»
			Kit.part(g, Kit.CYL, Kit.mat(Color("f2c14e"), 0.15, 1.0, Color("f2a81e"), 0.6), Vector3(0.9, 0.04, 0.9), Vector3(-1.7, 2.0, -2.9), Vector3(PI / 2, 0, 0))
			Kit.part(g, Kit.CYL, _m(Color("2a2a30"), 0.4), Vector3(0.2, 0.05, 0.2), Vector3(-1.7, 2.0, -2.88), Vector3(PI / 2, 0, 0))
			if lvl >= 5:
				Chars.label(g, "БЕССМЕРТНЫЙ ХИТ", 80, Color(3.2, 1.4, 2.6), Vector3(0, 2.75, -1.45), Vector3.ZERO, 0.006, 8)
		"solar":
			# a three-blade wind turbine on the roof; at 5 — panels glowing with light particles
			Kit.part(g, Kit.CYL, steel, Vector3(0.1, 2.0, 0.1), Vector3(1.2, 3.8, -4.4))
			for k in range(3):
				var a := k * TAU / 3.0
				Kit.part(g, Kit.BOX, _m(Color("eef0f4"), 0.4), Vector3(0.14, 1.2, 0.04), Vector3(1.2 + sin(a) * 0.6, 4.8 + cos(a) * 0.6, -4.2), Vector3(0, 0, -a))
			if lvl >= 5:
				for k in range(3):
					Kit.part(g, Kit.BOX, Kit.neon(Color("ffd84a"), 2.5), Vector3(1.5, 0.07, 0.05), Vector3(-3.4 + k * 1.75, 3.3, -3.6), Vector3(0.45, 0, 0))
	# an idea bulb over every upgraded building
	Kit.part(g, Kit.SPH, Kit.neon(Color("ffe8a0"), 3.0), Vector3(0.3, 0.36, 0.3), Vector3(0.0, 3.1 if id != "solar" else 4.9, -1.2 if id == "studio" else (-4.0 if id == "solar" else 0.0)))
