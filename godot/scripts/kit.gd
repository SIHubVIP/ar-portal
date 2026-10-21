class_name Kit
## Shared meshes, materials and procedural textures.

const NAVY := Color("142a38")
const GOLD := Color("f5b55c")
const TEAL := Color("55cdbe")
const CREAM := Color("fff6ea")

static var BOX: BoxMesh
static var CYL: CylinderMesh
static var SPH: SphereMesh
static var CAP: CapsuleMesh
static var CONE: CylinderMesh
static var DISC: CylinderMesh
static var _mats := {}
static var _ready := false


static func init() -> void:
	if _ready:
		return
	_ready = true
	BOX = BoxMesh.new()
	CYL = CylinderMesh.new()
	CYL.top_radius = 0.5
	CYL.bottom_radius = 0.5
	CYL.height = 1.0
	CYL.radial_segments = 20
	SPH = SphereMesh.new()
	SPH.radius = 0.5
	SPH.height = 1.0
	SPH.radial_segments = 18
	SPH.rings = 10
	CAP = CapsuleMesh.new()
	CAP.radius = 0.25
	CAP.height = 1.0
	CAP.radial_segments = 14
	CAP.rings = 4
	CONE = CylinderMesh.new()
	CONE.top_radius = 0.0
	CONE.bottom_radius = 0.5
	CONE.height = 1.0
	CONE.radial_segments = 16
	DISC = CylinderMesh.new()
	DISC.top_radius = 0.5
	DISC.bottom_radius = 0.5
	DISC.height = 0.02
	DISC.radial_segments = 28


## Physically based material, cached by its parameters.
static func mat(c: Color, rough := 0.65, metal := 0.0, emis := Color.BLACK, emis_e := 0.0) -> StandardMaterial3D:
	var key := "%s|%.2f|%.2f|%s|%.2f" % [c.to_html(), rough, metal, emis.to_html(), emis_e]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	if emis_e > 0.0:
		m.emission_enabled = true
		m.emission = emis
		m.emission_energy_multiplier = emis_e
	_mats[key] = m
	return m


static func neon(c: Color, energy := 3.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c * energy
	return m


static func glow_material(c: Color, alpha := 0.7) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.no_depth_test = false
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	m.albedo_texture = radial_texture()
	return m


static var _radial: Texture2D
static func radial_texture() -> Texture2D:
	if _radial:
		return _radial
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.3, Color(1, 1, 1, 0.45))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(0.5, 0.0)
	t.width = 128
	t.height = 128
	_radial = t
	return t


static func part(parent: Node3D, mesh: Mesh, m: Material, size: Vector3, pos := Vector3.ZERO, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.scale = size
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi


static func torus(parent: Node3D, m: Material, inner: float, outer: float, pos := Vector3.ZERO, rot := Vector3.ZERO) -> MeshInstance3D:
	var t := TorusMesh.new()
	t.inner_radius = inner
	t.outer_radius = outer
	t.rings = 24
	t.ring_segments = 10
	var mi := MeshInstance3D.new()
	mi.mesh = t
	mi.material_override = m
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi


## Building facade: dark wall with a grid of windows; lit windows glow at dusk.
static func facade_material(base: Color, lit: float, seed: int) -> StandardMaterial3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var w := 256
	var h := 256
	var col := Image.create(w, h, false, Image.FORMAT_RGB8)
	var em := Image.create(w, h, false, Image.FORMAT_RGB8)
	col.fill(base)
	em.fill(Color.BLACK)
	# subtle wall noise
	for yy in range(h):
		var band := 0.0
		if yy % 32 >= 28:
			band = -0.12  # floor slab line
		for xx in range(w):
			col.set_pixel(xx, yy, base.lightened(rng.randf_range(-0.025, 0.025) + band) if band == 0.0 else base.darkened(-band))
	var glass := Color("1b2436").lerp(base, 0.15)
	var warm := [Color("ffd08a"), Color("ffb867"), Color("fff0c8")]
	var cool := [Color("9fe8ff"), Color("b6a8ff")]
	var y := 6
	while y < h - 20:
		var x := 6
		var row_lit := lit * rng.randf_range(0.4, 1.4)
		while x < w - 12:
			var on := rng.randf() < row_lit
			var wc: Color = warm[rng.randi() % 3] if rng.randf() < 0.8 else cool[rng.randi() % 2]
			wc = wc.darkened(rng.randf_range(0.0, 0.35))
			for yy in range(20):
				for xx in range(12):
					var edge := xx == 0 or yy == 0 or xx == 11 or yy == 19
					var mid := xx == 6 or yy == 9
					var c: Color
					if edge:
						c = base.darkened(0.35)
					elif mid:
						c = base.darkened(0.2)
					elif on:
						c = wc.lerp(Color.WHITE, 0.1 if yy < 9 else 0.0)
					else:
						c = glass.lightened(0.18 * (1.0 - yy / 20.0))
					col.set_pixel(x + xx, y + yy, c)
					if on and not edge and not mid:
						em.set_pixel(x + xx, y + yy, wc * (0.8 if yy > 13 else 1.0))
			x += 20
		y += 32
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(col)
	m.emission_enabled = true
	m.emission_texture = ImageTexture.create_from_image(em)
	m.emission_energy_multiplier = 2.2
	m.roughness = 0.8
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(0.12, 0.12, 0.12)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return m


static func tile_material(base: Color, line: Color) -> StandardMaterial3D:
	var s := 128
	var img := Image.create(s, s, false, Image.FORMAT_RGB8)
	img.fill(base)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(base.r * 1000)
	for y in range(s):
		for x in range(s):
			var c := base
			if x % 32 < 2 or y % 32 < 2:
				c = line
			else:
				c = base.lightened(rng.randf_range(-0.04, 0.04))
			img.set_pixel(x, y, c)
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.roughness = 0.9
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(0.5, 0.5, 0.5)
	return m
