class_name Embankment
## Набережная и Калинов мост (0.5): a riverside promenade south of the yard. Speakers stuck on autoplay, cheeky seagulls,
## and Zmey Gorynych hiding Koschei's backup under the bridge.

const BOUNDS := Rect2(-34.0, -11.0, 68.0, 17.5)
const BRIDGE_X := -16.0
const BOSS_HOME := Vector3(-16.0, 0, 1.0)


static func _lamp(st: Node3D, circles: Array, p: Vector3) -> void:
	Kit.part(st, Kit.CYL, Kit.mat(Color("2a2a32"), 0.4, 0.6), Vector3(0.16, 4.4, 0.16), p + Vector3(0, 2.2, 0))
	Kit.part(st, Kit.SPH, Kit.neon(Color("ffe2b0"), 2.4), Vector3.ONE * 0.5, p + Vector3(0, 4.5, 0))
	circles.append(Vector3(p.x, p.z, 0.25))


static func build(parent: Node3D) -> Dictionary:
	var root := Node3D.new()
	root.name = "World"
	parent.add_child(root)
	var st := Node3D.new()
	st.name = "Static"
	root.add_child(st)
	var rects: Array = []
	var circles: Array = []

	# ground, promenade tiles, the granite edge and the river
	Kit.part(st, Kit.BOX, Kit.mat(Color("5c7a42"), 1.0), Vector3(200, 0.2, 80), Vector3(0, -0.12, -40))
	Kit.part(st, Kit.BOX, Kit.tile_material(Color("b8a890"), Color("9a8a74")), Vector3(76, 0.12, 18), Vector3(0, -0.02, -2))
	Kit.part(st, Kit.BOX, Kit.mat(Color("8a8278"), 0.8), Vector3(76, 1.2, 1.0), Vector3(0, -0.5, 7.4))
	var water := StandardMaterial3D.new()
	water.albedo_color = Color("2a6a9a")
	water.roughness = 0.08
	water.metallic = 0.3
	water.emission_enabled = true
	water.emission = Color("1a3a5a")
	water.emission_energy_multiplier = 0.4
	Kit.part(st, Kit.BOX, water, Vector3(220, 0.1, 70), Vector3(0, -1.0, 43))
	Kit.part(st, Kit.BOX, Kit.mat(Color("6a8a4a"), 1.0), Vector3(220, 0.3, 30), Vector3(0, -0.6, 92))
	# railing along the river
	var rail := Kit.mat(Color("2a3a4a"), 0.4, 0.6)
	for k in range(38):
		var x := -37.0 + k * 2.0
		if absf(x - BRIDGE_X) < 3.5:
			continue
		Kit.part(st, Kit.BOX, rail, Vector3(0.08, 1.0, 0.08), Vector3(x, 0.5, 6.7))
		Kit.part(st, Kit.BOX, rail, Vector3(2.0, 0.08, 0.08), Vector3(x + 1.0, 1.0, 6.7))
	rects.append(Rect2(-40, 6.5, 80, 6))

	# Kalinov bridge: a stone arch over the river
	var stone := Kit.mat(Color("a89a86"), 0.85)
	var stone2 := Kit.mat(Color("8e8270"), 0.9)
	for k in range(12):
		var z := 6.5 + k * 3.0
		var y := 2.4 + sin(k / 11.0 * PI) * 2.6
		Kit.part(st, Kit.BOX, stone, Vector3(6.4, 0.7, 3.1), Vector3(BRIDGE_X, y, z), Vector3(-cos(k / 11.0 * PI) * 0.26, 0, 0))
		for s in [-1, 1]:
			Kit.part(st, Kit.BOX, stone2, Vector3(0.4, 1.0, 3.1), Vector3(BRIDGE_X + 3.0 * s, y + 0.8, z), Vector3(-cos(k / 11.0 * PI) * 0.26, 0, 0))
	for z in [12.0, 24.0]:
		Kit.part(st, Kit.BOX, stone2, Vector3(3.6, 6.0, 2.4), Vector3(BRIDGE_X, 1.0, z))
	# a ramp from the promenade up to the bridge (decoration) and the dark arch where Gorynych sleeps
	Kit.part(st, Kit.BOX, stone, Vector3(6.4, 0.6, 3.0), Vector3(BRIDGE_X, 0.9, 5.4), Vector3(0.45, 0, 0))
	Chars.label(root, "КАЛИНОВ МОСТ", 120, Color(3.0, 2.4, 1.4), Vector3(BRIDGE_X, 4.6, 6.0), Vector3(0, PI, 0), 0.009, 10)

	# the river station with a spire, cafés and the north buildings
	var f1 := Kit.facade_material(Color("e8d8b8"), 0.3, 51)
	var f2 := Kit.facade_material(Color("c8bba6"), 0.25, 52)
	Kit.part(st, Kit.BOX, f1, Vector3(22, 9, 8), Vector3(14, 4.5, -16))
	Kit.part(st, Kit.BOX, Kit.mat(Color("2a6a5a"), 0.6), Vector3(22.6, 0.6, 8.6), Vector3(14, 9.2, -16))
	Kit.part(st, Kit.CYL, Kit.mat(Color("e8d8b8"), 0.8), Vector3(3, 6, 3), Vector3(14, 12.4, -16))
	Kit.part(st, Kit.CONE, Kit.mat(Color("f2c14e"), 0.3, 0.8), Vector3(2.2, 7, 2.2), Vector3(14, 18.9, -16))
	Kit.part(st, Kit.SPH, Kit.neon(Color("ffd23a"), 3.0), Vector3.ONE * 0.6, Vector3(14, 22.6, -16))
	Chars.label(root, "РЕЧНОЙ ВОКЗАЛ", 130, Color(3.0, 2.6, 1.6), Vector3(14, 7.6, -11.9), Vector3.ZERO, 0.01, 10)
	Kit.part(st, Kit.BOX, f2, Vector3(26, 14, 10), Vector3(-18, 7, -19))
	Kit.part(st, Kit.BOX, f2, Vector3(16, 12, 10), Vector3(36, 6, -18))
	rects.append(Rect2(-40, -24, 80, 13))
	# a café kiosk and umbrellas
	var cafe := Node3D.new()
	cafe.position = Vector3(-2, 0, -9)
	st.add_child(cafe)
	Kit.part(cafe, Kit.BOX, Kit.mat(Color("f4f0e6"), 0.7), Vector3(3.2, 2.6, 2.2), Vector3(0, 1.3, 0))
	Kit.part(cafe, Kit.BOX, Kit.mat(Color("2a8a7a"), 0.6), Vector3(3.5, 0.5, 2.5), Vector3(0, 2.8, 0))
	Kit.part(cafe, Kit.BOX, Kit.mat(Color("ffcf7a"), 0.3, 0.0, Color("ffcf7a"), 1.2), Vector3(2.0, 1.0, 0.05), Vector3(0, 1.5, 1.11))
	Chars.label(root, "КОФЕ · КВАС", 80, Color(3.0, 2.6, 1.8), Vector3(-2, 2.8, -7.72), Vector3.ZERO, 0.007, 8)
	circles.append(Vector3(-2, -9, 1.8))
	for p in [Vector3(4, 0, -8), Vector3(8, 0, -8.5), Vector3(-7, 0, -8.2)]:
		Kit.part(st, Kit.CYL, Kit.mat(Color("3a3a40"), 0.5, 0.5), Vector3(0.08, 2.4, 0.08), p + Vector3(0, 1.2, 0))
		Kit.part(st, Kit.CONE, Kit.mat(Color("e8323c") if p.x > 0 else Color("f2b21c"), 0.7), Vector3(2.6, 0.7, 2.6), p + Vector3(0, 2.5, 0))
		Kit.part(st, Kit.CYL, Kit.mat(Color("f4f4f4"), 0.6), Vector3(0.9, 0.06, 0.9), p + Vector3(0, 0.75, 0))
		circles.append(Vector3(p.x, p.z, 0.7))
	# benches, lamps, trees
	for x in [-28.0, -6.0, 6.0, 22.0]:
		var b := Node3D.new()
		b.position = Vector3(x, 0, 5.2)
		st.add_child(b)
		Kit.part(b, Kit.BOX, Kit.mat(Color("3a8a5a"), 0.7), Vector3(2.2, 0.08, 0.5), Vector3(0, 0.5, 0))
		Kit.part(b, Kit.BOX, Kit.mat(Color("3a8a5a"), 0.7), Vector3(2.2, 0.5, 0.08), Vector3(0, 0.85, -0.25))
		rects.append(Rect2(x - 1.1, 4.9, 2.2, 0.6))
	for x in [-30.0, -22.0, -9.0, 0.0, 10.0, 20.0, 30.0]:
		_lamp(st, circles, Vector3(x, 0, 6.0))
	for p in [Vector3(-26, 0, -9), Vector3(26, 0, -9), Vector3(-12, 0, -9.5), Vector3(30, 0, -8)]:
		Chars.tree(st, p, 1.2, Color("4a8a3a"))
		circles.append(Vector3(p.x, p.z, 0.55))
	# the way back to the yard (east)
	var arch := Kit.mat(Color("2a5a3a"), 0.5, 0.4)
	for z in [-3.2, 3.2]:
		Kit.part(st, Kit.BOX, arch, Vector3(0.35, 4.2, 0.35), Vector3(33.6, 2.1, z))
		circles.append(Vector3(33.6, z, 0.3))
	Kit.part(st, Kit.BOX, arch, Vector3(0.3, 0.6, 6.8), Vector3(33.6, 4.2, 0))
	Chars.label(root, "ДВОР «БЕРЁЗКИ»", 90, Color(3.0, 2.2, 1.0), Vector3(33.4, 4.2, 0), Vector3(0, -PI / 2, 0), 0.0085, 10)
	Chars.ring(root, Vector3(32.2, 0.05, 0), 1.2, Color("55cdbe"), 0.08, 3.0)
	# boats on the river
	for b in [[Vector3(6, -0.7, 20), 0.3], [Vector3(-34, -0.7, 26), -0.5]]:
		var boat := Node3D.new()
		boat.position = b[0]
		boat.rotation.y = b[1]
		st.add_child(boat)
		Kit.part(boat, Kit.BOX, Kit.mat(Color("f4f4f4"), 0.6), Vector3(3.2, 1.0, 9), Vector3(0, 0.5, 0))
		Kit.part(boat, Kit.BOX, Kit.mat(Color("2a5ab8"), 0.6), Vector3(2.6, 1.4, 3.4), Vector3(0, 1.7, -1))
		Kit.part(boat, Kit.BOX, Kit.mat(Color("e8323c"), 0.6), Vector3(3.3, 0.3, 9.1), Vector3(0, 0.9, 0))

	Kit.bake_static(st)
	return {"root": root, "rects": rects, "circles": circles, "id": "embankment", "name": "Набережная", "bounds": BOUNDS,
		"map_rects": [Rect2(-34, -11, 68, 17.5), Rect2(BRIDGE_X - 3.2, 6.5, 6.4, 20)],
		"spawns": {"from_yard": [Vector3(30.0, 0, 0), -PI / 2], "start": [Vector3(30.0, 0, 0), -PI / 2], "respawn": [Vector3(28, 0, -2), -PI / 2]},
		"portals": [{"pos": Vector3(32.2, 0, 0), "r": 1.3, "to": "yard", "spawn": "from_embankment", "label": "Двор «Берёзки»"}],
		"npcs": [],
		"mobs": [["autoplay", Vector3(20, 0, -3), 10], ["autoplay", Vector3(12, 0, 3), 10], ["autoplay", Vector3(6, 0, 2), 10],
			["autoplay", Vector3(-4, 0, 2), 10], ["autoplay", Vector3(-24, 0, -3), 10], ["autoplay", Vector3(-28, 0, 1), 10],
			["gull", Vector3(19, 0, 1), 9], ["gull", Vector3(17, 0, -3), 10], ["gull", Vector3(2, 0, 3), 10], ["gull", Vector3(-9, 0, -7), 10],
			["gull", Vector3(-21, 0, -1), 10]]}
