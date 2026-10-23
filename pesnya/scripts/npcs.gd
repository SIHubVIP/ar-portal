class_name Npcs
## 0.6: models of the new neighbours. Each returns {root, body, head} like the other NPCs.

static func _m(c: Color, rough := 0.6, metal := 0.0) -> StandardMaterial3D:
	return Kit.mat(c, rough, metal)


## Height of the name plate above each model.
const PLATE_H := {"pavlin": 2.6, "lis": 2.0, "jack": 2.1, "maloy": 2.0, "chef": 3.1, "zari": 3.0, "yarik": 2.6, "shcheben": 2.4, "pelmen": 2.1, "sochnya": 2.4, "dublevich": 2.4, "vasya": 2.9, "ded": 2.5}


static func build(id: String) -> Dictionary:
	Kit.init()
	match id:
		"pavlin": return pavlin()
		"lis": return lis()
		"pilot": return pilot()
		"kent": return kent()
		"jack": return jack()
		"klyukva": return klyukva()
		"shcheben": return shcheben()
		"maloy": return maloy()
		"chef": return chef()
		"melnik": return melnik()
		"zari": return zari()
		"yarik": return yarik()
		"sochnya": return Mobs08.sochnya()
		"pelmen": return Mobs08.pelmen()
		"ventilev": return Mobs08.ventilev()
		"tamara": return Mobs08.tamara()
		"dublevich": return Mobs08.dublevich()
		"chel": return Mobs08.chel()
		"osob": return Mobs08.osob()
		"vasya": return Mobs09.vasya()
		"kesha": return Mobs09.kesha()
		"ded": return Mobs09.ded()
	return Chars.petrovich_npc()


# Павлин Футболист (0.8: a humanoid, like Невысокий Лис): a peacock-headed footballer in the yard team's kit,
# a crest with glowing tips, a tail fan on his back and the ball always at his foot
static func pavlin() -> Dictionary:
	var blue := Color("1f5ab8")
	var h := Chars.human({"top": Color("2a8a4a"), "pants": Color("f4f4f4"), "shoes": Color("1a1a1a"), "hair": "none", "skin": blue,
		"scale": Vector3(0.9, 0.9, 0.9), "smirk": 0.3, "width": 0.96, "stripe": true})
	var bm := _m(blue, 0.35, 0.3)
	# white shirt band and the number 10
	Kit.part(h.body, Kit.CYL, _m(Color("f4f4f4"), 0.7), Vector3(0.78, 0.1, 0.52), Vector3(0, 1.18, 0))
	Chars.label(h.body, "10", 70, Color("f4f4f4"), Vector3(0, 0.9, 0.29), Vector3.ZERO, 0.0055, 0)
	# peacock face: a beak, a white eye patch and the crest of three feathers
	Kit.part(h.head, Kit.CONE, _m(Color("e8c84a"), 0.4), Vector3(0.14, 0.3, 0.14), Vector3(0, -0.06, 0.42), Vector3(PI / 2, 0, 0))
	for s in [-1, 1]:
		Kit.part(h.head, Kit.SPH, _m(Color("f4f4f4"), 0.6), Vector3(0.2, 0.12, 0.06), Vector3(0.14 * s, 0.08, 0.3))
	for k in range(3):
		Kit.part(h.head, Kit.CYL, _m(Color("1a3a6a"), 0.5), Vector3(0.025, 0.34, 0.025), Vector3((k - 1) * 0.08, 0.46, -0.04), Vector3(0, 0, (k - 1) * 0.3))
		Kit.part(h.head, Kit.SPH, Kit.neon(Color("4ad8ff"), 1.4), Vector3.ONE * 0.09, Vector3((k - 1) * 0.13, 0.64, -0.04))
	Kit.part(h.head, Kit.SPH, bm, Vector3(0.5, 0.3, 0.4), Vector3(0, -0.28, 0.02))
	# the tail fan with «eyes» on his back
	var cols := [Color("2a9a5a"), Color("3aaa6a"), Color("1f8a8a")]
	for k in range(9):
		var a := -1.0 + k * 0.25
		var f := Node3D.new()
		f.position = Vector3(0, 0.75, -0.32)
		f.rotation = Vector3(-0.55, 0, a)
		h.body.add_child(f)
		Kit.part(f, Kit.BOX, _m(cols[k % 3], 0.5), Vector3(0.18, 1.2, 0.03), Vector3(0, 0.66, 0))
		Kit.part(f, Kit.SPH, Kit.neon(Color("ffd23a"), 1.2), Vector3(0.15, 0.17, 0.04), Vector3(0, 1.18, -0.01))
		Kit.part(f, Kit.SPH, Kit.neon(Color("2a5aff"), 1.6), Vector3(0.07, 0.08, 0.05), Vector3(0, 1.18, -0.02))
	# captain's armband and the ball at his foot
	Kit.part(h.arms[0], Kit.CYL, _m(Color("ffd23a"), 0.5), Vector3(0.3, 0.1, 0.3), Vector3(0, -0.15, 0))
	Kit.part(h.root, Kit.SPH, _m(Color("ffffff"), 0.4), Vector3.ONE * 0.42, Vector3(0.45, 0.21, 0.55))
	Kit.part(h.root, Kit.SPH, _m(Color("1a1a1a"), 0.4), Vector3.ONE * 0.18, Vector3(0.45, 0.39, 0.6))
	return h


# Невысокий Лис: a short fox in a clean apron, yellow gloves and a spray bottle
static func lis() -> Dictionary:
	var h := Chars.human({"top": Color("f0f0f0"), "pants": Color("3a4a6a"), "shoes": Color("f4f4f4"), "hair": "none", "skin": Color("e8803a"),
		"scale": Vector3(0.78, 0.78, 0.78), "smirk": 0.25})
	var orange := _m(Color("e8803a"), 0.8)
	Kit.part(h.head, Kit.CONE, orange, Vector3(0.36, 0.5, 0.3), Vector3(0, -0.02, 0.36), Vector3(PI / 2, 0, 0))
	Kit.part(h.head, Kit.SPH, _m(Color("1a1a1a"), 0.3), Vector3.ONE * 0.09, Vector3(0, -0.02, 0.62))
	Kit.part(h.head, Kit.SPH, _m(Color("f8f4ee"), 0.8), Vector3(0.5, 0.26, 0.3), Vector3(0, -0.2, 0.22))
	for s in [-1, 1]:
		Kit.part(h.head, Kit.CONE, orange, Vector3(0.18, 0.34, 0.1), Vector3(0.2 * s, 0.42, -0.02), Vector3(0, 0, -0.25 * s))
		Kit.part(h.head, Kit.CONE, _m(Color("2a1a14"), 0.8), Vector3(0.08, 0.14, 0.06), Vector3(0.22 * s, 0.56, -0.02), Vector3(0, 0, -0.25 * s))
	Kit.part(h.body, Kit.BOX, _m(Color("8ad8c8"), 0.7), Vector3(0.62, 0.7, 0.06), Vector3(0, 0.9, 0.27))
	for hd in h.hands:
		Kit.part(hd, Kit.SPH, _m(Color("f2d21c"), 0.4), Vector3.ONE * 0.2)
	var sp := Node3D.new()
	h.hands[1].add_child(sp)
	Kit.part(sp, Kit.CYL, _m(Color("4ad8ff"), 0.2), Vector3(0.14, 0.32, 0.14), Vector3(0, -0.15, 0.06))
	Kit.part(sp, Kit.BOX, _m(Color("f4f4f4"), 0.4), Vector3(0.06, 0.08, 0.16), Vector3(0, 0.05, 0.12))
	# tail
	Kit.part(h.body, Kit.SPH, orange, Vector3(0.32, 0.32, 0.8), Vector3(0, 0.55, -0.5), Vector3(0.5, 0, 0))
	Kit.part(h.body, Kit.SPH, _m(Color("f8f4ee"), 0.8), Vector3.ONE * 0.22, Vector3(0, 0.36, -0.82))
	return h


# Шустрый Пилот: flight jacket, goggles, white scarf and a bowl of protein porridge
static func pilot() -> Dictionary:
	var h := Chars.human({"top": Color("8a5a32"), "top_rough": 0.5, "pants": Color("2a3a5a"), "shoes": Color("2a1a14"), "hair": "short",
		"hair_color": Color("6a4a2a"), "smirk": 0.35})
	var dark := _m(Color("2a2a30"), 0.4, 0.3)
	Kit.torus(h.head, _m(Color("5a3a22"), 0.6), 0.34, 0.38, Vector3(0, 0.16, 0), Vector3(0.2, 0, 0))
	for s in [-1, 1]:
		Kit.part(h.head, Kit.CYL, dark, Vector3(0.18, 0.06, 0.18), Vector3(0.12 * s, 0.3, 0.26), Vector3(PI / 2 - 0.6, 0, 0))
		Kit.part(h.head, Kit.CYL, Kit.neon(Color("4ad8ff"), 1.4), Vector3(0.13, 0.065, 0.13), Vector3(0.12 * s, 0.3, 0.27), Vector3(PI / 2 - 0.6, 0, 0))
	Kit.part(h.body, Kit.CYL, _m(Color("f4f4f4"), 0.8), Vector3(0.5, 0.14, 0.5), Vector3(0, 1.38, 0))
	Kit.part(h.body, Kit.BOX, _m(Color("f4f4f4"), 0.8), Vector3(0.12, 0.4, 0.04), Vector3(0.12, 1.12, 0.28), Vector3(0, 0, 0.2))
	var bowl := Node3D.new()
	h.hands[0].add_child(bowl)
	Kit.part(bowl, Kit.CYL, _m(Color("e8e0d0"), 0.5), Vector3(0.3, 0.14, 0.3), Vector3(0, -0.1, 0.1))
	Kit.part(bowl, Kit.CYL, _m(Color("f2d8a0"), 0.9), Vector3(0.26, 0.02, 0.26), Vector3(0, -0.03, 0.1))
	Kit.part(bowl, Kit.BOX, _m(Color("c4c9d4"), 0.3, 0.8), Vector3(0.03, 0.03, 0.3), Vector3(0.05, 0.02, 0.15), Vector3(0.5, 0, 0))
	return h


# Кент Организатор: hoodie «GG», cap backwards, headset with a mic, a gamepad
static func kent() -> Dictionary:
	var h := Chars.human({"top": Color("4a2a7a"), "pants": Color("1a1a22"), "shoes": Color("f4f4f4"), "hair": "beanie", "hair_color": Color("1a1a22"),
		"smirk": 0.3, "width": 1.08})
	Chars.label(h.body, "GG", 70, Color("55cdbe"), Vector3(0, 1.05, 0.29), Vector3.ZERO, 0.006, 0)
	var dark := _m(Color("1a1b22"), 0.4, 0.3)
	Kit.torus(h.head, dark, 0.34, 0.38, Vector3(0, 0.05, 0), Vector3(0, 0, PI / 2))
	for s in [-1, 1]:
		Kit.part(h.head, Kit.CYL, Kit.neon(Color("ff5d7a"), 2.0), Vector3(0.24, 0.1, 0.24), Vector3(0.36 * s, 0.0, 0), Vector3(0, 0, PI / 2))
	Kit.part(h.head, Kit.CYL, dark, Vector3(0.03, 0.3, 0.03), Vector3(-0.3, -0.16, 0.18), Vector3(0.9, 0.5, 0))
	var pad := Node3D.new()
	h.hands[1].add_child(pad)
	Kit.part(pad, Kit.BOX, _m(Color("2a2c34"), 0.4), Vector3(0.36, 0.08, 0.2), Vector3(0, -0.08, 0.12))
	Kit.part(pad, Kit.SPH, Kit.neon(Color("55cdbe"), 2.0), Vector3.ONE * 0.05, Vector3(0.1, -0.03, 0.12))
	return h


# Джек Скалолаз: a lively kid with a red helmet, a rope coil and a chalk bag
static func jack() -> Dictionary:
	var h := Chars.human({"top": Color("ff9a1c"), "pants": Color("3a4a3a"), "shoes": Color("2a5ab8"), "hair": "short", "hair_color": Color("c87a2a"),
		"scale": Vector3(0.8, 0.8, 0.8), "smirk": 0.45})
	Kit.part(h.head, Kit.SPH, _m(Color("e8323c"), 0.35), Vector3(0.66, 0.4, 0.68), Vector3(0, 0.2, 0))
	Kit.torus(h.body, _m(Color("2a9ad8"), 0.6), 0.22, 0.3, Vector3(0.1, 0.95, 0.0), Vector3(0, 0, 0.7))
	Kit.part(h.body, Kit.CYL, _m(Color("f4f4f4"), 0.8), Vector3(0.2, 0.22, 0.2), Vector3(-0.32, 0.5, -0.1))
	return h


# Товарищ Клюква: a respected soldier in green with a cranberry-red beret and medals
static func klyukva() -> Dictionary:
	var h := Chars.human({"top": Color("4a5a3a"), "pants": Color("3e4c32"), "shoes": Color("1a1a1a"), "hair": "short", "hair_color": Color("6a6a6a"),
		"smirk": 0.1, "brow": Color("6a6a6a")})
	Kit.part(h.head, Kit.CYL, _m(Color("b81a3a"), 0.8), Vector3(0.62, 0.12, 0.62), Vector3(0.04, 0.3, -0.02), Vector3(0, 0, -0.25))
	Kit.part(h.head, Kit.SPH, _m(Color("f2c14e"), 0.2, 1.0), Vector3.ONE * 0.06, Vector3(-0.18, 0.32, 0.26))
	Kit.part(h.head, Kit.BOX, _m(Color("6a6a6a"), 0.8), Vector3(0.24, 0.06, 0.05), Vector3(0, -0.1, 0.31))
	for k in range(3):
		Kit.part(h.body, Kit.SPH, _m(Color("f2c14e"), 0.2, 1.0), Vector3.ONE * 0.07, Vector3(-0.12 + k * 0.08, 1.12, 0.29))
	Kit.part(h.body, Kit.BOX, _m(Color("2a2a22"), 0.6), Vector3(0.66, 0.06, 0.46), Vector3(0, 0.62, 0))
	return h


# Щебень Не Атлет: a man of gravel with a magnificent beard
static func shcheben() -> Dictionary:
	var h := Chars.human({"top": Color("6a6e74"), "pants": Color("4a4e54"), "shoes": Color("2a2a2a"), "hair": "none", "skin": Color("a8a49c"),
		"width": 1.3, "smirk": 0.2})
	var stone := _m(Color("8e8a82"), 0.95)
	for p in [Vector3(-0.3, 1.4, 0.1), Vector3(0.32, 1.38, 0.05), Vector3(0.1, 1.3, 0.25), Vector3(-0.15, 0.9, 0.28)]:
		Kit.part(h.body, Kit.BOX, stone, Vector3(0.18, 0.14, 0.16), p, Vector3(0.3, 0.6, 0.2))
	var beard := _m(Color("6a4a2a"), 0.95)
	Kit.part(h.head, Kit.SPH, beard, Vector3(0.6, 0.6, 0.42), Vector3(0, -0.34, 0.18))
	Kit.part(h.head, Kit.SPH, beard, Vector3(0.36, 0.5, 0.3), Vector3(0, -0.66, 0.2))
	Kit.part(h.head, Kit.BOX, _m(Color("e8323c"), 0.7), Vector3(0.6, 0.1, 0.6), Vector3(0, 0.28, 0))
	return h


# Мистер Малой: a small kid in an oversized hoodie with a glowing phone
static func maloy() -> Dictionary:
	var h := Chars.human({"top": Color("5a7a8a"), "pants": Color("1e2a3a"), "shoes": Color("f4f4f4"), "hair": "beanie", "hair_color": Color("f2c14e"),
		"scale": Vector3(0.76, 0.76, 0.76), "smirk": 0.4, "width": 1.15, "backpack": true})
	var ph := Node3D.new()
	h.hands[1].add_child(ph)
	Kit.part(ph, Kit.BOX, _m(Color("1a1a1e"), 0.3), Vector3(0.12, 0.22, 0.03), Vector3(0, -0.1, 0.1), Vector3(-0.6, 0, 0))
	Kit.part(ph, Kit.BOX, Kit.neon(Color("4ad8ff"), 2.4), Vector3(0.1, 0.18, 0.005), Vector3(0, -0.095, 0.118), Vector3(-0.6, 0, 0))
	return h


# Меткий Змей: a polite snake chef in a tall white hat with a ladle
static func chef() -> Dictionary:
	var g := Node3D.new()
	var body := Node3D.new()
	g.add_child(body)
	var green := _m(Color("6aba4a"), 0.5)
	for k in range(4):
		Kit.torus(body, green, 0.16, 0.5 - k * 0.08, Vector3(0, 0.16 + k * 0.26, 0), Vector3.ZERO)
	for k in range(4):
		Kit.part(body, Kit.SPH, green, Vector3.ONE * (0.34 - k * 0.02), Vector3(0, 1.1 + k * 0.28, 0.05 + k * 0.03))
	Kit.part(body, Kit.BOX, _m(Color("f4f4f4"), 0.8), Vector3(0.4, 0.5, 0.06), Vector3(0, 1.3, 0.2))
	var head := Node3D.new()
	head.position = Vector3(0, 2.25, 0.18)
	body.add_child(head)
	Kit.part(head, Kit.SPH, green, Vector3(0.5, 0.38, 0.62))
	for s in [-1, 1]:
		Kit.part(head, Kit.SPH, _m(Color("ffffff"), 0.3), Vector3.ONE * 0.14, Vector3(0.14 * s, 0.1, 0.22))
		Kit.part(head, Kit.SPH, _m(Color("101010"), 0.2), Vector3(0.04, 0.1, 0.04), Vector3(0.15 * s, 0.1, 0.29))
	Kit.part(head, Kit.BOX, _m(Color("e8323c"), 0.5), Vector3(0.04, 0.02, 0.24), Vector3(0, -0.1, 0.38))
	Kit.part(head, Kit.CYL, _m(Color("ffffff"), 0.8), Vector3(0.4, 0.32, 0.4), Vector3(0, 0.3, -0.04))
	Kit.part(head, Kit.SPH, _m(Color("ffffff"), 0.8), Vector3(0.56, 0.32, 0.56), Vector3(0, 0.5, -0.04))
	var ladle := Node3D.new()
	ladle.position = Vector3(0.36, 1.5, 0.2)
	ladle.rotation = Vector3(0.2, 0, -0.4)
	body.add_child(ladle)
	Kit.part(ladle, Kit.CYL, _m(Color("c4c9d4"), 0.3, 0.8), Vector3(0.04, 0.7, 0.04), Vector3(0, 0.3, 0))
	Kit.part(ladle, Kit.SPH, _m(Color("c4c9d4"), 0.3, 0.8), Vector3(0.22, 0.12, 0.22), Vector3(0, 0.68, 0))
	return {"root": g, "body": body, "head": head}


# Молодой Мельник: young miller with a flour-dusted apron, a flat cap and a mug of kvass
static func melnik() -> Dictionary:
	var h := Chars.human({"top": Color("f4f0e6"), "pants": Color("6a5a3a"), "shoes": Color("4a3020"), "hair": "short", "hair_color": Color("d8b46a"),
		"smirk": 0.4})
	Kit.part(h.head, Kit.CYL, _m(Color("8a7a5a"), 0.9), Vector3(0.62, 0.14, 0.62), Vector3(0, 0.27, 0.02))
	Kit.part(h.head, Kit.BOX, _m(Color("7a6a4a"), 0.9), Vector3(0.4, 0.04, 0.2), Vector3(0, 0.22, 0.34), Vector3(0.25, 0, 0))
	for s in [-1, 1]:
		Kit.part(h.head, Kit.SPH, _m(Color("ff9a9a"), 0.8), Vector3(0.1, 0.06, 0.03), Vector3(0.17 * s, -0.04, 0.3))
	Kit.part(h.body, Kit.BOX, _m(Color("e8dcc0"), 0.95), Vector3(0.6, 0.8, 0.06), Vector3(0, 0.85, 0.27))
	for p in [Vector3(-0.1, 0.8, 0.31), Vector3(0.14, 1.0, 0.31), Vector3(0.05, 0.6, 0.31)]:
		Kit.part(h.body, Kit.SPH, _m(Color("ffffff"), 1.0), Vector3(0.12, 0.08, 0.02), p)
	var mug := Node3D.new()
	h.hands[0].add_child(mug)
	Kit.part(mug, Kit.CYL, _m(Color("7a4a22"), 0.6), Vector3(0.18, 0.24, 0.18), Vector3(0, -0.12, 0.1))
	Kit.part(mug, Kit.CYL, _m(Color("f4e8c8"), 0.9), Vector3(0.17, 0.05, 0.17), Vector3(0, 0.0, 0.1))
	return h


# Мыслитель Зари: a fairy-tale sage in a starry robe with a dawn-coloured lantern on his staff
static func zari() -> Dictionary:
	var h := Chars.human({"top": Color("1e2a6a"), "pants": Color("1e2a6a"), "shoes": Color("2a1a14"), "hair": "none", "skin": Color("e8c8a8"),
		"skirt": true, "skirt_color": Color("1e2a6a"), "smirk": 0.15, "brow": Color("f4f4f4"), "scale": Vector3(1.0, 1.08, 1.0)})
	Kit.part(h.head, Kit.CONE, _m(Color("f4f4f4"), 0.9), Vector3(0.36, 0.9, 0.26), Vector3(0, -0.55, 0.24), Vector3(PI, 0, 0))
	Kit.part(h.head, Kit.CONE, _m(Color("2a3a8a"), 0.7), Vector3(0.62, 0.9, 0.62), Vector3(0, 0.62, -0.04))
	Kit.part(h.head, Kit.SPH, Kit.neon(Color("ffd23a"), 2.4), Vector3.ONE * 0.12, Vector3(0.1, 0.7, 0.2))
	for p in [Vector3(-0.2, 1.2, 0.29), Vector3(0.18, 0.9, 0.29), Vector3(-0.1, 0.6, 0.32), Vector3(0.25, 0.4, 0.3)]:
		Kit.part(h.body, Kit.SPH, Kit.neon(Color("ffd23a"), 2.0), Vector3.ONE * 0.06, p)
	var staff := Node3D.new()
	h.hands[1].add_child(staff)
	Kit.part(staff, Kit.CYL, _m(Color("6a4a2a"), 0.8), Vector3(0.06, 2.0, 0.06), Vector3(0, 0.3, 0.05))
	Kit.part(staff, Kit.SPH, Kit.neon(Color("ff9a4a"), 3.0), Vector3.ONE * 0.24, Vector3(0, 1.36, 0.05))
	return h


# Ярик-Фонарик: a living street lamp who does not know who he is
static func yarik() -> Dictionary:
	var g := Node3D.new()
	var body := Node3D.new()
	g.add_child(body)
	var dark := _m(Color("2a2e3a"), 0.4, 0.6)
	for s in [-1, 1]:
		Kit.part(body, Kit.CYL, dark, Vector3(0.1, 0.5, 0.1), Vector3(0.14 * s, 0.25, 0))
		Kit.part(body, Kit.BOX, dark, Vector3(0.16, 0.06, 0.26), Vector3(0.14 * s, 0.03, 0.06))
	Kit.part(body, Kit.CYL, dark, Vector3(0.22, 1.1, 0.22), Vector3(0, 1.0, 0))
	for s in [-1, 1]:
		Kit.part(body, Kit.CYL, dark, Vector3(0.06, 0.5, 0.06), Vector3(0.18 * s, 1.15, 0), Vector3(0, 0, 0.5 * s))
	var head := Node3D.new()
	head.position = Vector3(0, 1.85, 0)
	body.add_child(head)
	Kit.part(head, Kit.BOX, dark, Vector3(0.62, 0.08, 0.62), Vector3(0, -0.3, 0))
	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(1.0, 0.9, 0.6, 0.3)
	glass.roughness = 0.05
	Kit.part(head, Kit.BOX, glass, Vector3(0.5, 0.56, 0.5), Vector3(0, 0.0, 0))
	Kit.part(head, Kit.SPH, Kit.neon(Color("ffb84a"), 4.0), Vector3.ONE * 0.26, Vector3(0, 0.0, 0))
	var roof := PrismMesh.new()
	Kit.part(head, roof, dark, Vector3(0.7, 0.3, 0.7), Vector3(0, 0.43, 0))
	for s in [-1, 1]:
		Kit.part(head, Kit.SPH, _m(Color("101010"), 0.2), Vector3.ONE * 0.06, Vector3(0.1 * s, 0.08, 0.26))
	return {"root": g, "body": body, "head": head}
