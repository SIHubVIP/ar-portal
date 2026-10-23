class_name Base
## ГК «Песня»: the garage cooperative with the player's box №40, building slots and the robot Вася.

const BOUNDS := Rect2(-31.0, -6.2, 62.0, 12.4)
const SLOTS := {
	"studio": Vector3(0, 0, -5.0),
	"solar": Vector3(3.4, 0, -5.0),
	"grill": Vector3(-4.8, 0, -3.0),
	"garden": Vector3(-9.0, 0, -3.4),
	"gym": Vector3(-4.6, 0, 3.4),
	"stage": Vector3(4.8, 0, 3.0),
}
const ROBOT_HOME := Vector3(-1.9, 0, -4.2)
const GATE_WEST := Vector3(-31.0, 0, 0)


static func _garage(p: Node3D, x: float, z_front: float, facing_south: bool, col: Color, number: int, labels: Node3D, door := true) -> void:
	var g := Node3D.new()
	g.position = Vector3(x, 0, z_front)
	g.rotation.y = 0.0 if facing_south else PI
	p.add_child(g)
	Kit.part(g, Kit.BOX, Kit.mat(Color("b8b0a0"), 0.95), Vector3(3.4, 2.8, 6), Vector3(0, 1.4, -3))
	if door:
		Kit.part(g, Kit.BOX, Kit.mat(col, 0.7, 0.3), Vector3(2.8, 2.2, 0.08), Vector3(0, 1.1, 0.02))
		for k in range(9):
			Kit.part(g, Kit.BOX, Kit.mat(col.darkened(0.2), 0.7, 0.3), Vector3(2.8, 0.03, 0.03), Vector3(0, 0.2 + k * 0.24, 0.07))
	Kit.part(g, Kit.BOX, Kit.mat(Color("3a3a3a"), 0.9), Vector3(3.5, 0.15, 6.4), Vector3(0, 2.85, -3))
	var l := Chars.label(labels, str(number), 60, Color("f4f4f4"), Vector3.ZERO, Vector3.ZERO, 0.006, 0)
	l.position = g.position + Vector3(0, 2.45, 0.08 if facing_south else -0.08)
	l.rotation.y = g.rotation.y


## 0.9: box №13 is hollow (walls, roof, floor) — the workshop «Идея» is seen through the open front
static func _garage_open(p: Node3D, x: float, z_front: float, labels: Node3D) -> void:
	var wall := Kit.mat(Color("b8b0a0"), 0.95)
	for sx in [-1, 1]:
		Kit.part(p, Kit.BOX, wall, Vector3(0.15, 2.8, 6.0), Vector3(x + 1.62 * sx, 1.4, z_front + 3.0))
	Kit.part(p, Kit.BOX, wall, Vector3(3.4, 2.8, 0.15), Vector3(x, 1.4, z_front + 5.95))
	Kit.part(p, Kit.BOX, Kit.mat(Color("3a3a3a"), 0.9), Vector3(3.5, 0.15, 6.4), Vector3(x, 2.85, z_front + 3.0))
	Kit.part(p, Kit.BOX, Kit.mat(Color("6a6a6a"), 0.95), Vector3(3.2, 0.04, 5.8), Vector3(x, 0.0, z_front + 3.0))
	var l := Chars.label(labels, "13", 60, Color("f4f4f4"), Vector3.ZERO, Vector3.ZERO, 0.006, 0)
	l.position = Vector3(x, 2.45, z_front - 0.08)
	l.rotation.y = PI


static func build_garages(parent: Node3D) -> Dictionary:
	var root := Node3D.new()
	root.name = "World"
	parent.add_child(root)
	var st := Node3D.new()
	root.add_child(st)
	var rects: Array = []
	var circles: Array = []
	Kit.part(st, Kit.BOX, Kit.mat(Color("5c6a42"), 1.0), Vector3(200, 0.2, 200), Vector3(0, -0.12, 0))
	Kit.part(st, Kit.BOX, Kit.mat(Color("55555c"), 0.95), Vector3(70, 0.1, 13), Vector3(0, -0.02, 0))
	# puddles
	for p in [Vector3(-12, 0, 1.5), Vector3(9, 0, -1.2), Vector3(20, 0, 2.2)]:
		Kit.part(st, Kit.CYL, Kit.mat(Color("2a3448"), 0.05, 0.6), Vector3(2.2, 0.01, 1.4), p + Vector3(0, 0.04, 0))
	var rust := [Color("8a4a3a"), Color("5a6a7a"), Color("7a6a4a"), Color("4a5a4a"), Color("6a4a5a"), Color("7a3a3a")]
	for i in range(-9, 10):
		var x := i * 3.4
		if i != 0:
			_garage(st, x, -6.6, true, rust[(i + 9) % rust.size()], 40 + i, root)
		if i == -6:
			_garage_open(st, x, 6.6, root)   # 0.9: box №13 — hollow, for the inventors' workshop
		else:
			_garage(st, x, 6.6, false, rust[(i + 12) % rust.size()], 70 + i, root)
	# box 40 — ours: teal, neon sign, Aolovo logo; the door belongs to the studio slot
	_garage(st, 0, -6.6, true, Color("2a7a8a"), 40, root, false)
	Kit.part(st, Kit.BOX, Kit.mat(Color("2a7a8a"), 0.6, 0.2), Vector3(3.4, 0.5, 0.1), Vector3(0, 2.55, -6.55))
	var sign := Chars.label(root, "ПЕСНЯ", 140, Color(4.0, 3.0, 1.4), Vector3(0, 3.5, -6.4), Vector3.ZERO, 0.009, 10)
	sign.name = "Sign40"
	var logo := Sprite3D.new()
	logo.texture = load("res://brand/logo_light.png")
	logo.pixel_size = 0.0011
	logo.position = Vector3(3.4, 2.56, -6.5)
	root.add_child(logo)
	rects.append(Rect2(-33, -14, 66, 7.4))
	rects.append(Rect2(-33, 6.6, 66, 7.4))
	# west gate to the hypermarket, east arch back to the yard
	var arch := Kit.mat(Color("2a5a3a"), 0.5, 0.4)
	for z in [-5.6, 5.6]:
		Kit.part(st, Kit.BOX, arch, Vector3(0.35, 4.2, 0.35), Vector3(31.3, 2.1, z))
		Kit.part(st, Kit.BOX, Kit.mat(Color("6a6a6a"), 0.5, 0.6), Vector3(0.3, 2.4, 0.3), Vector3(-31.6, 1.2, z))
	Kit.part(st, Kit.BOX, arch, Vector3(0.3, 0.6, 11.6), Vector3(31.3, 4.2, 0))
	var ea := Chars.label(root, "ДВОР «БЕРЁЗКИ»", 90, Color(3.0, 2.2, 1.0), Vector3(31.1, 4.2, 0), Vector3(0, -PI / 2, 0), 0.0085, 10)
	ea.name = "EastSign"
	Chars.ring(root, Vector3(29.8, 0.05, 0), 1.2, Color("55cdbe"), 0.08, 3.0)
	Kit.part(st, Kit.BOX, Kit.mat(Color("2a5ac8"), 0.6), Vector3(0.08, 1.0, 4.6), Vector3(-31.3, 2.9, 0))
	Chars.label(root, "← ГИПЕРМАРКЕТ «ЁЖИК» 2 КМ", 52, Color("ffffff"), Vector3(-31.2, 3.05, 0), Vector3(0, PI / 2, 0), 0.0055, 0)
	Chars.label(root, "СТРОЙРЫНОК · СВАЛКА", 44, Color("cfe0ff"), Vector3(-31.2, 2.65, 0), Vector3(0, PI / 2, 0), 0.0055, 0)
	# 0.3: the way to Koschei's construction site
	Kit.part(st, Kit.BOX, Kit.mat(Color("c8323c"), 0.6), Vector3(0.08, 0.7, 5.4), Vector3(-31.3, 4.0, 0))
	var ws := Chars.label(root, "СТРОЙКА ГЛУШИЛКИ · ВХОД ПО ПУТЁВКЕ", 46, Color("ffffff"), Vector3(-31.2, 4.02, 0), Vector3(0, PI / 2, 0), 0.0055, 0)
	ws.name = "WestSign"
	# the board of the cooperative (Petrovich)
	Kit.part(st, Kit.BOX, Kit.mat(Color("3a8a5a"), 0.6), Vector3(2.6, 0.6, 0.08), Vector3(10.2, 2.45, 6.5))
	Chars.label(root, "ПРАВЛЕНИЕ ГК", 60, Color("ffffff"), Vector3(10.2, 2.45, 6.44), Vector3(0, PI, 0), 0.0055, 0)
	# props: tyres, barrels, lamp posts, string lights
	for p in [Vector3(14, 0, -5.2), Vector3(-15, 0, 5.1), Vector3(22, 0, -5.0)]:
		for k in range(3):
			Kit.torus(st, Kit.mat(Color("1d1e24"), 0.8), 0.18, 0.42, p + Vector3(0, 0.12 + k * 0.24, 0), Vector3(0, 0, 0))
		circles.append(Vector3(p.x, p.z, 0.5))
	for p in [Vector3(-20, 0, -5.2), Vector3(17, 0, 5.1)]:
		Kit.part(st, Kit.CYL, Kit.mat(Color("2a5ac8"), 0.5, 0.4), Vector3(0.6, 0.9, 0.6), p + Vector3(0, 0.45, 0))
		Kit.part(st, Kit.CYL, Kit.mat(Color("2a5ac8"), 0.5, 0.4), Vector3(0.6, 0.9, 0.6), p + Vector3(0.65, 0.45, 0.1))
		circles.append(Vector3(p.x + 0.3, p.z, 0.65))
	for x in [-24.0, -12.0, 12.0, 24.0]:
		Kit.part(st, Kit.CYL, Kit.mat(Color("2a2a32"), 0.4, 0.6), Vector3(0.16, 5, 0.16), Vector3(x, 2.5, -5.8))
		Kit.part(st, Kit.BOX, Kit.neon(Color("ffe2b0"), 2.0), Vector3(0.5, 0.05, 0.25), Vector3(x, 4.95, -5.3))
		circles.append(Vector3(x, -5.8, 0.25))
	var cols := [Kit.GOLD, Color("ff5d7a"), Kit.TEAL]
	for k in range(40):
		var t := k / 39.0
		Kit.part(st, Kit.SPH, Kit.neon(cols[k % 3], 4.0), Vector3.ONE * 0.12, Vector3(-14 + t * 28, 3.4 - sin(t * PI * 2.0) * 0.3, -1.0 + sin(t * 9.0) * 0.2))
	# skyline behind the garages
	var f1 := Kit.facade_material(Color("c8bba6"), 0.25, 31)
	var f2 := Kit.facade_material(Color("b5b9be"), 0.3, 32)
	for h in [[Vector3(-22, 0, -40), Vector3(40, 15, 12), f1], [Vector3(24, 0, -44), Vector3(34, 27, 12), f2], [Vector3(0, 0, 40), Vector3(60, 15, 12), f2], [Vector3(-60, 0, 0), Vector3(14, 36, 40), f1]]:
		Kit.part(st, Kit.BOX, h[2], h[1], h[0] + Vector3(0, h[1].y / 2, 0))
		Kit.part(st, Kit.BOX, Kit.mat(Color("6a6460"), 0.9), Vector3(h[1].x + 0.4, 0.4, h[1].z + 0.4), h[0] + Vector3(0, h[1].y + 0.2, 0))
	for p in [Vector3(-26, 0, -18), Vector3(26, 0, 18), Vector3(-8, 0, 20), Vector3(14, 0, -20)]:
		Chars.tree(st, p, 1.2, Color("5a8a3a"))
	Kit.bake_static(st)
	# building anchors (rebuilt when levels change)
	var anchors := {}
	for id in SLOTS:
		var a := Node3D.new()
		a.name = "Slot_" + id
		root.add_child(a)
		a.position = SLOTS[id]
		anchors[id] = a
	var wa := Node3D.new()
	wa.name = "Workshop13"
	root.add_child(wa)
	wa.position = GameData.BOX13
	return {"root": root, "workshop_anchor": wa, "rects": rects, "circles": circles, "id": "garages", "name": "ГК «Песня»", "bounds": BOUNDS,
		"map_rects": [Rect2(-33, -6.2, 66, 12.4)],
		"spawns": {"from_yard": [Vector3(27.5, 0, 0), -PI / 2], "start": [Vector3(27.5, 0, 0), -PI / 2], "respawn": [Vector3(2, 0, 0), PI],
			"from_stroyka": [Vector3(-27.4, 0, 0), PI / 2]},
		"portals": [{"pos": Vector3(29.8, 0, 0), "r": 1.3, "to": "yard", "spawn": "from_garages", "label": "Двор «Берёзки»"}],
		"npcs": [{"id": "petrovich", "pos": Vector3(10.2, 0, 4.6), "rot": PI}],
		"mobs": [], "anchors": anchors}


# ------------------------------------------------------------------ building visuals
static func _ghost(p: Node3D, size: Vector3, center: Vector3, text: String) -> void:
	var gm := StandardMaterial3D.new()
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.albedo_color = Color(0.3, 0.85, 1.0, 0.16)
	Kit.part(p, Kit.BOX, gm, size, center)
	var edge := Kit.neon(Color("6ad8ff"), 2.0)
	for sx in [-0.5, 0.5]:
		for sz in [-0.5, 0.5]:
			Kit.part(p, Kit.BOX, edge, Vector3(0.05, size.y, 0.05), center + Vector3(size.x * sx, 0, size.z * sz))
	for sy in [-0.5, 0.5]:
		for sz in [-0.5, 0.5]:
			Kit.part(p, Kit.BOX, edge, Vector3(size.x, 0.05, 0.05), center + Vector3(0, size.y * sy, size.z * sz))
		for sx in [-0.5, 0.5]:
			Kit.part(p, Kit.BOX, edge, Vector3(0.05, 0.05, size.z), center + Vector3(size.x * sx, size.y * sy, 0))
	var l := Chars.label(p, text, 56, Color(1.4, 2.2, 2.6), center + Vector3(0, size.y * 0.5 + 0.45, 0), Vector3.ZERO, 0.006, 8)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED


static func building(id: String, lvl: int) -> Node3D:
	var g := Node3D.new()
	var name: String = GameData.BUILDINGS[id].name
	var dark := Kit.mat(Color("2a2a30"), 0.5, 0.6)
	var wood := Kit.mat(Color("a8743e"), 0.85)
	match id:
		"studio":
			if lvl == 0:
				Kit.part(g, Kit.BOX, Kit.mat(Color("2a7a8a"), 0.7, 0.3), Vector3(2.8, 2.2, 0.08), Vector3(0, 1.1, -1.58))
				var l0 := Chars.label(g, "СТРОЙКА · " + name, 56, Color(1.4, 2.2, 2.6), Vector3(0, 2.0, -1.4), Vector3.ZERO, 0.006, 8)
				l0.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			else:
				Kit.part(g, Kit.BOX, Kit.mat(Color("ffcf7a"), 0.3, 0.0, Color("ffb050"), 1.4), Vector3(2.6, 1.9, 0.05), Vector3(0, 1.0, -4.0))
				Kit.part(g, Kit.BOX, dark, Vector3(1.4, 0.8, 0.6), Vector3(0, 0.4, -3.0))
				Kit.part(g, Kit.BOX, Kit.neon(Kit.TEAL, 2.0), Vector3(1.2, 0.05, 0.4), Vector3(0, 0.82, -2.95))
				for s in [-1, 1]:
					Kit.part(g, Kit.BOX, dark, Vector3(0.5, 1.0, 0.5), Vector3(0.95 * s, 0.5, -2.2))
					Kit.part(g, Kit.CYL, Kit.neon(Kit.TEAL, 2.5), Vector3(0.32, 0.03, 0.32), Vector3(0.95 * s, 0.6, -1.94), Vector3(PI / 2, 0, 0))
				if lvl >= 2:
					Chars.label(g, "СТУДИЯ", 110, Color(1.2, 3.0, 2.8), Vector3(0, 2.25, -1.45), Vector3.ZERO, 0.007, 8)
				if lvl >= 3:
					for s in [-1, 1]:
						Kit.part(g, Kit.BOX, dark, Vector3(0.8, 1.6, 0.7), Vector3(1.9 * s, 0.8, -1.0))
						Kit.part(g, Kit.CYL, Kit.neon(Kit.GOLD, 3.0), Vector3(0.5, 0.03, 0.5), Vector3(1.9 * s, 1.1, -0.64), Vector3(PI / 2, 0, 0))
						Kit.part(g, Kit.CYL, Kit.neon(Kit.GOLD, 3.0), Vector3(0.3, 0.03, 0.3), Vector3(1.9 * s, 0.5, -0.64), Vector3(PI / 2, 0, 0))
		"solar":
			if lvl == 0:
				_ghost(g, Vector3(5.6, 0.5, 3.0), Vector3(-1.7, 3.3, -4.5), "СТРОЙКА · " + name)
			else:
				for k in range(lvl):
					Kit.part(g, Kit.BOX, Kit.mat(Color("1a2a5a"), 0.15, 0.6), Vector3(1.6, 0.06, 1.1), Vector3(-3.4 + k * 1.75, 3.25, -4.0), Vector3(0.45, 0, 0))
					Kit.part(g, Kit.BOX, Kit.neon(Color("4a8aff"), 0.8), Vector3(1.5, 0.065, 0.04), Vector3(-3.4 + k * 1.75, 3.27, -4.0), Vector3(0.45, 0, 0))
				if lvl >= 3:
					Kit.part(g, Kit.BOX, Kit.mat(Color("e8e8e8"), 0.4), Vector3(0.7, 0.9, 0.5), Vector3(1.0, 0.45, -1.2))
					Kit.part(g, Kit.BOX, Kit.neon(Color("4aff8a"), 2.0), Vector3(0.4, 0.08, 0.02), Vector3(1.0, 0.7, -0.94))
		"grill":
			if lvl == 0:
				_ghost(g, Vector3(1.6, 1.2, 1.0), Vector3(0, 0.6, 0), "СТРОЙКА · " + name)
			else:
				Kit.part(g, Kit.BOX, dark, Vector3(1.3, 0.35, 0.5), Vector3(0, 0.85, 0))
				for sx in [-0.55, 0.55]:
					for sz in [-0.18, 0.18]:
						Kit.part(g, Kit.CYL, dark, Vector3(0.05, 0.7, 0.05), Vector3(sx, 0.35, sz))
				Kit.part(g, Kit.BOX, Kit.neon(Color("ff7a2a"), 3.0), Vector3(1.1, 0.05, 0.36), Vector3(0, 1.03, 0))
				for k in range(4):
					Kit.part(g, Kit.BOX, Kit.mat(Color("8a3a2a"), 0.6), Vector3(0.08, 0.08, 0.6), Vector3(-0.4 + k * 0.27, 1.1, 0))
				if lvl >= 2:
					Kit.part(g, Kit.BOX, wood, Vector3(1.4, 0.06, 0.8), Vector3(0, 0.75, 1.2))
					for sx in [-0.6, 0.6]:
						Kit.part(g, Kit.BOX, wood, Vector3(0.06, 0.75, 0.6), Vector3(sx, 0.37, 1.2))
					Kit.part(g, Kit.CYL, Kit.mat(Color("e8e8e8"), 0.4), Vector3(0.25, 0.3, 0.25), Vector3(0.3, 0.93, 1.2))
				if lvl >= 3:
					for sx in [-1.1, 1.1]:
						for sz in [-0.6, 1.8]:
							Kit.part(g, Kit.BOX, wood, Vector3(0.12, 2.6, 0.12), Vector3(sx, 1.3, sz))
					var roof := PrismMesh.new()
					Kit.part(g, roof, Kit.mat(Color("8a3a2a"), 0.8), Vector3(2.8, 0.8, 3.0), Vector3(0, 3.0, 0.6))
					var cols := [Kit.GOLD, Color("ff5d7a"), Kit.TEAL]
					for k in range(10):
						Kit.part(g, Kit.SPH, Kit.neon(cols[k % 3], 4.0), Vector3.ONE * 0.1, Vector3(-1.1 + k * 0.245, 2.5 - sin(k / 9.0 * PI) * 0.2, 1.85))
		"garden":
			if lvl == 0:
				_ghost(g, Vector3(2.4, 0.6, 1.4), Vector3(0, 0.3, 0), "СТРОЙКА · " + name)
			else:
				var beds := 1 if lvl == 1 else 2
				for b in range(beds):
					var bz := b * 1.6 - (0.8 if beds == 2 else 0.0)
					Kit.part(g, Kit.BOX, wood, Vector3(2.4, 0.3, 1.2), Vector3(0, 0.15, bz))
					Kit.part(g, Kit.BOX, Kit.mat(Color("3a2a1a"), 1.0), Vector3(2.2, 0.31, 1.0), Vector3(0, 0.16, bz))
					for k in range(5):
						Kit.part(g, Kit.SPH, Kit.mat(Color("4a9a3a"), 0.8), Vector3.ONE * (0.32 + (k % 2) * 0.08), Vector3(-0.9 + k * 0.45, 0.45, bz))
						if b == 0 and k % 2 == 0:
							Kit.part(g, Kit.SPH, Kit.mat(Color("e83a2a"), 0.4), Vector3.ONE * 0.13, Vector3(-0.9 + k * 0.45 + 0.1, 0.55, bz + 0.1))
				if lvl >= 2:
					Kit.part(g, Kit.CYL, wood, Vector3(0.08, 2.0, 0.08), Vector3(1.6, 1.0, 0))
					Kit.part(g, Kit.CYL, wood, Vector3(0.06, 1.0, 0.06), Vector3(1.6, 1.5, 0), Vector3(0, 0, PI / 2))
					Kit.part(g, Kit.SPH, Kit.mat(Color("e8d8a0"), 0.9), Vector3.ONE * 0.35, Vector3(1.6, 2.15, 0))
					Kit.part(g, Kit.CYL, Kit.mat(Color("2a7a8a"), 0.7), Vector3(0.4, 0.15, 0.4), Vector3(1.6, 2.35, 0))
				if lvl >= 3:
					var gm := StandardMaterial3D.new()
					gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					gm.albedo_color = Color(0.8, 0.95, 1.0, 0.22)
					gm.roughness = 0.1
					Kit.part(g, Kit.BOX, gm, Vector3(3.0, 1.8, 3.6), Vector3(0, 0.9, 0))
		"gym":
			if lvl == 0:
				_ghost(g, Vector3(2.4, 1.6, 1.6), Vector3(0, 0.8, 0), "СТРОЙКА · " + name)
			else:
				for k in range(3):
					Kit.torus(g, Kit.mat(Color("1d1e24"), 0.8), 0.18, 0.42, Vector3(-1.2, 0.12 + k * 0.24, 0.4))
				Kit.part(g, Kit.BOX, Kit.mat(Color("3a3a48"), 0.6), Vector3(0.4, 0.45, 1.3), Vector3(0.3, 0.22, 0))
				Kit.part(g, Kit.CYL, Kit.mat(Color("c4c9d4"), 0.3, 0.9), Vector3(0.05, 1.6, 0.05), Vector3(0.3, 0.9, -0.4), Vector3(0, 0, PI / 2))
				for s in [-1, 1]:
					Kit.part(g, Kit.CYL, dark, Vector3(0.45, 0.1, 0.45), Vector3(0.3 + 0.7 * s, 0.9, -0.4), Vector3(0, 0, PI / 2))
				if lvl >= 2:
					Kit.part(g, Kit.BOX, wood, Vector3(0.12, 2.4, 0.12), Vector3(1.3, 1.2, -0.6))
					Kit.part(g, Kit.BOX, wood, Vector3(0.9, 0.12, 0.12), Vector3(1.0, 2.35, -0.6))
					Kit.part(g, Kit.CAP, Kit.mat(Color("c83a3a"), 0.6), Vector3(1.4, 1.0, 1.4), Vector3(0.75, 1.5, -0.6))
				if lvl >= 3:
					Kit.part(g, Kit.BOX, Kit.mat(Color("2a5ac8"), 0.9), Vector3(2.2, 0.04, 1.2), Vector3(0, 0.02, 0.9))
					Chars.label(g, "КАЧАЛКА", 80, Color(3.0, 1.2, 1.2), Vector3(0, 2.6, -1.0), Vector3(0, PI, 0), 0.007, 8)
		"stage":
			if lvl == 0:
				_ghost(g, Vector3(3.2, 0.6, 2.2), Vector3(0, 0.3, 0), "СТРОЙКА · " + name)
			else:
				Kit.part(g, Kit.BOX, Kit.mat(Color("3a2a22"), 0.7), Vector3(3.2, 0.45, 2.2), Vector3(0, 0.22, 0))
				Kit.part(g, Kit.BOX, Kit.neon(Kit.GOLD, 1.6), Vector3(3.2, 0.05, 0.05), Vector3(0, 0.45, -1.1))
				if lvl >= 2:
					for s in [-1, 1]:
						Kit.part(g, Kit.BOX, dark, Vector3(0.6, 1.0, 0.5), Vector3(1.2 * s, 0.95, 0.6))
						Kit.part(g, Kit.CYL, Kit.neon(Kit.TEAL, 2.5), Vector3(0.36, 0.03, 0.36), Vector3(1.2 * s, 1.05, 0.34), Vector3(PI / 2, 0, 0))
					Kit.part(g, Kit.CYL, Kit.mat(Color("c4c9d4"), 0.3, 0.9), Vector3(0.04, 1.3, 0.04), Vector3(0, 1.1, 0))
					Kit.part(g, Kit.SPH, Kit.mat(Color("2a2a30"), 0.3), Vector3.ONE * 0.14, Vector3(0, 1.8, 0))
				if lvl >= 3:
					for s in [-1, 1]:
						Kit.part(g, Kit.BOX, Kit.mat(Color("c4c9d4"), 0.3, 0.9), Vector3(0.12, 3.2, 0.12), Vector3(1.55 * s, 1.6, 1.0))
					Kit.part(g, Kit.BOX, Kit.mat(Color("c4c9d4"), 0.3, 0.9), Vector3(3.2, 0.14, 0.14), Vector3(0, 3.2, 1.0))
					for k in range(4):
						Kit.part(g, Kit.CYL, Kit.neon([Kit.GOLD, Color("ff5d7a"), Kit.TEAL, Color("c38bff")][k], 3.0), Vector3(0.2, 0.2, 0.2), Vector3(-1.1 + k * 0.73, 3.0, 1.0))
					Chars.label(g, "СЦЕНА", 100, Color(3.0, 2.2, 1.0), Vector3(0, 3.6, 1.0), Vector3(0, PI, 0), 0.008, 8)
	if lvl >= 4:
		Mobs09.building_extra(g, id, lvl)
	if lvl > 0:
		var star := Chars.label(g, "%s · ур. %d" % [name, lvl], 44, Color(1.0, 0.95, 0.8), Vector3(0, 2.6 if id != "solar" else 4.2, 0 if id != "studio" else -1.4), Vector3.ZERO, 0.005, 6)
		star.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		if id == "solar":
			star.position = Vector3(-1.7, 4.2, -4.0)
	Kit.bake_tree(g)
	return g
