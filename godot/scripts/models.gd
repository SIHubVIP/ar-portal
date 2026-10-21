class_name Models
## Procedural models: heroes, rap items, props.

const SKINS := {
	"classic": {"body": Color("f5b55c"), "pants": Color("142a38"), "cap": Color("55cdbe"), "capD": Color("2a8f84"), "skin": Color("e9b48a")},
}

static func _m(c: Color, rough := 0.6, metal := 0.0) -> StandardMaterial3D:
	return Kit.mat(c, rough, metal)


## Returns a dictionary describing the hero rig.
static func make_rapper(sk: Dictionary) -> Dictionary:
	Kit.init()
	var root := Node3D.new()
	var body := Node3D.new()
	root.add_child(body)
	var hoodie := _m(sk.body, 0.85)
	var pants := _m(sk.pants, 0.9)
	var skin := _m(sk.skin, 0.55)
	var cap := _m(sk.cap, 0.7)
	var capd := _m(sk.capD, 0.7)
	var white := _m(Color("f4f1ea"), 0.5)
	var dark := _m(Color("1a1b22"), 0.45)
	var gold := _m(Color("f2c14e"), 0.22, 1.0)
	var legs := []
	var arms := []
	for s in [-1, 1]:
		var hip := Node3D.new()
		hip.position = Vector3(0.18 * s, 0.6, 0)
		body.add_child(hip)
		Kit.part(hip, Kit.CAP, pants, Vector3(0.64, 0.58, 0.64), Vector3(0, -0.26, 0))
		Kit.part(hip, Kit.BOX, white, Vector3(0.33, 0.18, 0.46), Vector3(0, -0.53, 0.06))
		Kit.part(hip, Kit.BOX, capd, Vector3(0.34, 0.05, 0.24), Vector3(0, -0.5, 0.03))
		Kit.part(hip, Kit.BOX, dark, Vector3(0.35, 0.05, 0.47), Vector3(0, -0.62, 0.06))
		legs.append(hip)
		var sh := Node3D.new()
		sh.position = Vector3(0.47 * s, 1.18, 0)
		body.add_child(sh)
		Kit.part(sh, Kit.CAP, hoodie, Vector3(0.54, 0.6, 0.54), Vector3(0, -0.27, 0))
		Kit.part(sh, Kit.SPH, skin, Vector3(0.2, 0.2, 0.2), Vector3(0, -0.6, 0))
		arms.append(sh)
	# hoodie torso (rounded), hood, pocket, strings
	Kit.part(body, Kit.CAP, hoodie, Vector3(1.55, 0.76, 1.02), Vector3(0, 0.93, 0))
	Kit.part(body, Kit.SPH, hoodie, Vector3(0.62, 0.32, 0.3), Vector3(0, 1.22, -0.25))
	Kit.part(body, Kit.BOX, pants, Vector3(0.46, 0.16, 0.05), Vector3(0, 0.76, 0.25))
	for x in [-0.09, 0.09]:
		Kit.part(body, Kit.CYL, white, Vector3(0.03, 0.2, 0.03), Vector3(x, 1.07, 0.26))
	# head, backwards cap, shades
	Kit.part(body, Kit.SPH, skin, Vector3(0.66, 0.64, 0.62), Vector3(0, 1.52, 0))
	Kit.part(body, Kit.SPH, cap, Vector3(0.7, 0.42, 0.68), Vector3(0, 1.72, -0.02))
	Kit.part(body, Kit.BOX, capd, Vector3(0.5, 0.05, 0.3), Vector3(0, 1.73, -0.42), Vector3(-0.25, 0, 0))
	Kit.part(body, Kit.BOX, dark, Vector3(0.56, 0.13, 0.06), Vector3(0, 1.56, 0.29))
	Kit.part(body, Kit.BOX, _m(Color("7af0ff"), 0.1, 0.8), Vector3(0.2, 0.09, 0.02), Vector3(-0.13, 1.56, 0.325))
	Kit.part(body, Kit.BOX, _m(Color("7af0ff"), 0.1, 0.8), Vector3(0.2, 0.09, 0.02), Vector3(0.13, 1.56, 0.325))
	Kit.part(body, Kit.BOX, dark, Vector3(0.16, 0.035, 0.03), Vector3(0, 1.34, 0.3))
	# headphones around the neck
	for s in [-1, 1]:
		Kit.part(body, Kit.CYL, dark, Vector3(0.26, 0.12, 0.26), Vector3(0.36 * s, 1.21, 0.03), Vector3(0, 0, PI / 2))
		Kit.part(body, Kit.CYL, capd, Vector3(0.18, 0.13, 0.18), Vector3(0.36 * s, 1.21, 0.03), Vector3(0, 0, PI / 2))
	Kit.torus(body, dark, 0.33, 0.38, Vector3(0, 1.22, -0.05), Vector3(PI / 2 - 0.2, 0, 0))
	# gold chain with a lion pendant (Aolovo)
	Kit.torus(body, gold, 0.22, 0.27, Vector3(0, 1.17, 0.1), Vector3(PI / 2 - 0.45, 0, 0))
	Kit.part(body, Kit.CYL, gold, Vector3(0.16, 0.05, 0.16), Vector3(0, 0.97, 0.27), Vector3(PI / 2, 0, 0))
	# speaker backpack: the tower stands on it, it pulses with the beat
	Kit.part(body, Kit.BOX, dark, Vector3(0.56, 0.62, 0.28), Vector3(0, 0.93, -0.39))
	var speaker := Node3D.new()
	speaker.position = Vector3(0, 0.93, -0.54)
	body.add_child(speaker)
	Kit.part(speaker, Kit.CYL, _m(Color("3a3d4a"), 0.4, 0.6), Vector3(0.4, 0.04, 0.4), Vector3.ZERO, Vector3(PI / 2, 0, 0))
	Kit.part(speaker, Kit.CYL, Kit.neon(Kit.TEAL, 2.2), Vector3(0.17, 0.06, 0.17), Vector3(0, 0, -0.01), Vector3(PI / 2, 0, 0))
	return _finish(root, body, legs, arms, -0.39, "rapper", speaker)


static func make_runner(sk: Dictionary) -> Dictionary:
	Kit.init()
	var root := Node3D.new()
	var body := Node3D.new()
	root.add_child(body)
	var shirt := _m(sk.body, 0.8)
	var pants := _m(sk.pants, 0.9)
	var skin := _m(sk.skin, 0.55)
	var dark := _m(Color("1a1b22"), 0.5)
	var legs := []
	var arms := []
	for s in [-1, 1]:
		var hip := Node3D.new()
		hip.position = Vector3(0.17 * s, 0.6, 0)
		body.add_child(hip)
		Kit.part(hip, Kit.CAP, pants, Vector3(0.5, 0.56, 0.5), Vector3(0, -0.26, 0))
		Kit.part(hip, Kit.BOX, dark, Vector3(0.28, 0.14, 0.4), Vector3(0, -0.54, 0.06))
		legs.append(hip)
		var sh := Node3D.new()
		sh.position = Vector3(0.43 * s, 1.18, 0)
		body.add_child(sh)
		Kit.part(sh, Kit.CAP, shirt, Vector3(0.44, 0.56, 0.44), Vector3(0, -0.26, 0))
		Kit.part(sh, Kit.SPH, skin, Vector3(0.19, 0.19, 0.19), Vector3(0, -0.58, 0))
		arms.append(sh)
	Kit.part(body, Kit.CAP, shirt, Vector3(1.3, 0.7, 0.86), Vector3(0, 0.92, 0))
	Kit.part(body, Kit.SPH, skin, Vector3(0.64, 0.64, 0.62), Vector3(0, 1.5, 0))
	Kit.part(body, Kit.SPH, _m(sk.cap), Vector3(0.68, 0.4, 0.66), Vector3(0, 1.72, 0))
	Kit.part(body, Kit.BOX, _m(sk.capD), Vector3(0.5, 0.05, 0.3), Vector3(0, 1.72, 0.42), Vector3(0.2, 0, 0))
	for x in [-0.13, 0.13]:
		Kit.part(body, Kit.SPH, dark, Vector3(0.09, 0.13, 0.05), Vector3(x, 1.54, 0.3))
	Kit.part(body, Kit.BOX, _m(Color("aab2bf"), 0.4, 0.5), Vector3(0.5, 0.56, 0.24), Vector3(0, 0.92, -0.35))
	return _finish(root, body, legs, arms, -0.35, "runner", null)


static func _finish(root: Node3D, body: Node3D, legs: Array, arms: Array, pack_z: float, kind: String, speaker) -> Dictionary:
	var flame := Kit.part(body, Kit.CONE, Kit.neon(Color("ffa040"), 2.5), Vector3(0.22, 0.45, 0.22), Vector3(0, 0.45, pack_z), Vector3(PI, 0, 0))
	flame.visible = false
	var tower_base := Node3D.new()
	tower_base.position = Vector3(0, 1.24, pack_z - 0.03)
	body.add_child(tower_base)
	root.rotation.y = PI
	return {"kind": kind, "root": root, "body": body, "legs": legs, "arms": arms, "flame": flame, "tower_base": tower_base, "speaker": speaker}


# ------------------------------------------------------------------ items
static func make_item(id: String) -> Node3D:
	Kit.init()
	var g := Node3D.new()
	var dark := _m(Color("1e1f27"), 0.4)
	var steel := _m(Color("c4c9d4"), 0.25, 1.0)
	var gold := _m(Color("f2c14e"), 0.2, 1.0)
	var white := _m(Color("f4f1ea"), 0.5)
	var screen := Kit.mat(Color("102030"), 0.1, 0.0, Color("56e0ff"), 1.8)
	match id:
		"mic":
			Kit.part(g, Kit.CYL, dark, Vector3(0.13, 0.4, 0.13), Vector3(0, 0.2, 0))
			Kit.part(g, Kit.CYL, gold, Vector3(0.18, 0.05, 0.18), Vector3(0, 0.42, 0))
			Kit.part(g, Kit.SPH, steel, Vector3(0.28, 0.28, 0.28), Vector3(0, 0.52, 0))
		"boombox":
			Kit.part(g, Kit.BOX, _m(Color("3a3d4a"), 0.5), Vector3(0.86, 0.42, 0.3), Vector3(0, 0.21, 0))
			for x in [-0.24, 0.24]:
				Kit.part(g, Kit.CYL, dark, Vector3(0.3, 0.04, 0.3), Vector3(x, 0.21, 0.15), Vector3(PI / 2, 0, 0))
				Kit.part(g, Kit.CYL, steel, Vector3(0.1, 0.05, 0.1), Vector3(x, 0.21, 0.165), Vector3(PI / 2, 0, 0))
			Kit.part(g, Kit.BOX, screen, Vector3(0.16, 0.08, 0.02), Vector3(0, 0.3, 0.155))
			Kit.part(g, Kit.BOX, steel, Vector3(0.6, 0.05, 0.05), Vector3(0, 0.47, 0))
		"player":
			Kit.part(g, Kit.BOX, white, Vector3(0.32, 0.46, 0.08), Vector3(0, 0.23, 0))
			Kit.part(g, Kit.BOX, screen, Vector3(0.24, 0.16, 0.085), Vector3(0, 0.33, 0))
			Kit.part(g, Kit.CYL, steel, Vector3(0.16, 0.09, 0.16), Vector3(0, 0.12, 0), Vector3(PI / 2, 0, 0))
		"notebook":
			Kit.part(g, Kit.BOX, _m(Color("f0c446")), Vector3(0.62, 0.06, 0.46), Vector3(0, 0.03, 0))
			Kit.part(g, Kit.BOX, white, Vector3(0.58, 0.05, 0.42), Vector3(0.01, 0.08, 0))
			Kit.part(g, Kit.BOX, _m(Color("f0c446")), Vector3(0.62, 0.03, 0.46), Vector3(0, 0.12, 0))
		"tablet":
			Kit.part(g, Kit.BOX, dark, Vector3(0.74, 0.05, 0.52), Vector3(0, 0.025, 0))
			Kit.part(g, Kit.BOX, screen, Vector3(0.64, 0.055, 0.42), Vector3(0, 0.03, 0))
		"headphones":
			for x in [-0.27, 0.27]:
				Kit.part(g, Kit.CYL, dark, Vector3(0.26, 0.12, 0.26), Vector3(x, 0.17, 0), Vector3(0, 0, PI / 2))
				Kit.part(g, Kit.CYL, _m(Kit.TEAL), Vector3(0.18, 0.13, 0.18), Vector3(x, 0.17, 0), Vector3(0, 0, PI / 2))
			Kit.torus(g, dark, 0.24, 0.3, Vector3(0, 0.2, 0), Vector3(PI / 2, 0, 0)).scale = Vector3(1, 1, 1)
		"chain":
			Kit.torus(g, gold, 0.25, 0.34, Vector3(0, 0.05, 0))
			Kit.part(g, Kit.CYL, gold, Vector3(0.16, 0.06, 0.16), Vector3(0, 0.05, 0.36))
		"vinyl":
			Kit.part(g, Kit.CYL, _m(Color("15151a"), 0.25), Vector3(0.86, 0.025, 0.86), Vector3(0, 0.0125, 0))
			Kit.part(g, Kit.CYL, _m(Color("e0447a")), Vector3(0.3, 0.03, 0.3), Vector3(0, 0.015, 0))
		"sneakers":
			Kit.part(g, Kit.BOX, _m(Color("ff8a3c")), Vector3(0.82, 0.3, 0.5), Vector3(0, 0.15, 0))
			Kit.part(g, Kit.BOX, white, Vector3(0.84, 0.06, 0.52), Vector3(0, 0.3, 0))
		"spray":
			Kit.part(g, Kit.CYL, _m(Color("8a4fe0"), 0.4, 0.3), Vector3(0.22, 0.42, 0.22), Vector3(0, 0.21, 0))
			Kit.part(g, Kit.CYL, steel, Vector3(0.16, 0.08, 0.16), Vector3(0, 0.46, 0))
		"balloon":
			Kit.part(g, Kit.SPH, Kit.mat(Color("e8434f"), 0.2, 0.0, Color("401010"), 0.4), Vector3(0.55, 0.62, 0.55), Vector3(0, 0.44, 0))
			Kit.part(g, Kit.CYL, white, Vector3(0.02, 0.2, 0.02), Vector3(0, 0.08, 0))
		"magnet":
			var red := _m(Color("d8483e"), 0.5)
			Kit.part(g, Kit.BOX, red, Vector3(0.16, 0.34, 0.22), Vector3(-0.2, 0.25, 0))
			Kit.part(g, Kit.BOX, red, Vector3(0.16, 0.34, 0.22), Vector3(0.2, 0.25, 0))
			Kit.part(g, Kit.BOX, red, Vector3(0.56, 0.12, 0.22), Vector3(0, 0.39, 0))
			for x in [-0.2, 0.2]:
				Kit.part(g, Kit.BOX, steel, Vector3(0.16, 0.1, 0.22), Vector3(x, 0.05, 0))
		"crate":
			Kit.part(g, Kit.BOX, _m(Color("c48e52"), 0.9), Vector3(0.8, 0.6, 0.62), Vector3(0, 0.3, 0))
			Kit.part(g, Kit.BOX, _m(Color("8c5f34"), 0.9), Vector3(0.82, 0.08, 0.64), Vector3(0, 0.3, 0))
		"gem":
			var p := PrismMesh.new()
			Kit.part(g, p, Kit.mat(Color("56e0ff"), 0.05, 0.3, Color("1c6a80"), 1.5), Vector3(0.45, 0.55, 0.45), Vector3(0, 0.28, 0))
		_:
			Kit.part(g, Kit.BOX, _m(Color("888888")), Vector3(0.6, 0.4, 0.6), Vector3(0, 0.2, 0))
	return g


static func make_obstacle(kind: int) -> Node3D:
	var g := Node3D.new()
	if kind == 0:
		Kit.part(g, Kit.BOX, Kit.mat(Color("b2b7c2"), 0.35, 0.7), Vector3(1.4, 0.9, 1.0), Vector3(0, 0.45, 0))
		Kit.part(g, Kit.CYL, Kit.mat(Color("5a5e6a"), 0.5, 0.5), Vector3(0.7, 0.05, 0.7), Vector3(0, 0.92, 0))
		Kit.part(g, Kit.BOX, Kit.mat(Color("2a2632")), Vector3(1.2, 0.5, 0.04), Vector3(0, 0.45, 0.51))
	else:
		Kit.part(g, Kit.BOX, Kit.mat(Color("b5543c"), 0.95), Vector3(1.0, 1.1, 1.0), Vector3(0, 0.55, 0))
		Kit.part(g, Kit.BOX, Kit.mat(Color("8a4a44"), 0.9), Vector3(1.2, 0.15, 1.2), Vector3(0, 1.1, 0))
	return g


static func make_drone() -> Dictionary:
	var g := Node3D.new()
	Kit.part(g, Kit.SPH, Kit.mat(Color("4a4e5a"), 0.3, 0.8), Vector3(1.0, 0.45, 0.8))
	var eye := Kit.part(g, Kit.SPH, Kit.neon(Color("ff3b5c"), 3.0), Vector3(0.28, 0.28, 0.28), Vector3(0, -0.05, 0.38))
	var rotors := []
	for s in [-1, 1]:
		Kit.part(g, Kit.BOX, Kit.mat(Color("1a1b22")), Vector3(0.06, 0.25, 0.06), Vector3(s * 0.55, 0.25, 0))
		var r := Kit.part(g, Kit.CYL, Kit.glow_material(Color(1, 1, 1), 0.25), Vector3(0.9, 0.02, 0.9), Vector3(s * 0.55, 0.38, 0))
		r.material_override = Kit.mat(Color(0.9, 0.9, 0.95), 0.3)
		r.transparency = 0.6
		rotors.append(r)
	return {"node": g, "eye": eye, "rotors": rotors}
