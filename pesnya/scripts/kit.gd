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


## «Новый облик» uses lighter primitives for character parts and mobs (half the triangles, same look at phone size).
static func set_lowpoly(on: bool) -> void:
	init()
	CYL.radial_segments = 12 if on else 20
	CYL.rings = 0 if on else 4
	SPH.radial_segments = 12 if on else 18
	SPH.rings = 7 if on else 10
	CAP.radial_segments = 12 if on else 14
	CAP.rings = 2 if on else 4
	CONE.radial_segments = 10 if on else 16
	CONE.rings = 0 if on else 4
	DISC.radial_segments = 16 if on else 28
	DISC.rings = 0 if on else 4


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
	var key := "neon|%s|%.2f" % [c.to_html(), energy]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	_mats[key] = m
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


# ------------------------------------------------------------------ batching (fewer draw calls on phones)
# Plain colour materials are baked into vertex colours and merged into one surface per roughness/metal bucket.
# Special materials (textures, emission, neon, transparency) stay as separate surfaces.
static var _vc_mats := {}


static func _vc_mat(r: float, m: float) -> StandardMaterial3D:
	var key := "%.1f|%.1f" % [r, m]
	if _vc_mats.has(key):
		return _vc_mats[key]
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.roughness = r
	mat.metallic = m
	_vc_mats[key] = mat
	return mat


static func _mergeable(mi: MeshInstance3D) -> bool:
	if mi.mesh == null or mi.transparency > 0.0 or not mi.visible or mi.skin != null:
		return false
	var m = mi.material_override
	if m is BaseMaterial3D:
		if m.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or m.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED:
			return false
	return mi.mesh is PrimitiveMesh or mi.mesh is ArrayMesh


static func _plain(m) -> bool:
	return m is StandardMaterial3D and m.albedo_texture == null and not m.emission_enabled \
		and m.shading_mode == BaseMaterial3D.SHADING_MODE_PER_PIXEL and not m.uv1_triplanar and not m.vertex_color_use_as_albedo


static func _acc_new() -> Dictionary:
	return {"v": PackedVector3Array(), "n": PackedVector3Array(), "c": PackedColorArray(), "i": PackedInt32Array()}


static func _acc_add(acc: Dictionary, mesh: Mesh, xf: Transform3D, col: Color) -> void:
	var nb := xf.basis.inverse().transposed()
	for s in range(mesh.get_surface_count()):
		var arr := mesh.surface_get_arrays(s)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var idx = arr[Mesh.ARRAY_INDEX]
		var base: int = acc.v.size()
		var vv: PackedVector3Array = acc.v
		var nn: PackedVector3Array = acc.n
		var cc: PackedColorArray = acc.c
		var ii: PackedInt32Array = acc.i
		for k in range(v.size()):
			vv.append(xf * v[k])
			nn.append((nb * n[k]).normalized())
			cc.append(col)
		if idx is PackedInt32Array and idx.size() > 0:
			for j in idx:
				ii.append(base + j)
		else:
			for j in range(v.size()):
				ii.append(base + j)
		acc.v = vv
		acc.n = nn
		acc.c = cc
		acc.i = ii


static func _add_part(groups: Dictionary, mi: MeshInstance3D, xf: Transform3D) -> void:
	var mat = mi.material_override
	if _plain(mat):
		var key := "vc|%.1f|%.1f" % [snappedf(mat.roughness, 0.1), snappedf(mat.metallic, 0.1)]
		if not groups.has(key):
			groups[key] = {"acc": _acc_new(), "mat": _vc_mat(snappedf(mat.roughness, 0.1), snappedf(mat.metallic, 0.1))}
		_acc_add(groups[key].acc, mi.mesh, xf, mat.albedo_color)
	else:
		if not groups.has(mat):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			groups[mat] = {"st": st, "mat": mat}
		for s in range(mi.mesh.get_surface_count()):
			groups[mat].st.append_from(mi.mesh, s, xf)


static func _flush(groups: Dictionary, parent: Node3D, name := "Baked") -> void:
	if groups.is_empty():
		return
	var am := ArrayMesh.new()
	for key in groups:
		var g: Dictionary = groups[key]
		if g.has("acc"):
			var a: Dictionary = g.acc
			if a.v.size() == 0:
				continue
			var arrays := []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = a.v
			arrays[Mesh.ARRAY_NORMAL] = a.n
			arrays[Mesh.ARRAY_COLOR] = a.c
			arrays[Mesh.ARRAY_INDEX] = a.i
			am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		else:
			g.st.commit(am)
		am.surface_set_material(am.get_surface_count() - 1, g.mat)
	var out := MeshInstance3D.new()
	out.name = name
	out.mesh = am
	parent.add_child(out)


## Merge the MeshInstance3D children of every node in the tree (keeps pivots animatable).
static func bake_tree(root: Node) -> void:
	for c in root.get_children():
		if not (c is MeshInstance3D) and c is Node3D:
			bake_tree(c)
	if not (root is Node3D):
		return
	var groups := {}
	var gone := []
	for c in root.get_children():
		if c is MeshInstance3D and c.get_child_count() == 0 and _mergeable(c):
			_add_part(groups, c, c.transform)
			gone.append(c)
	if gone.size() < 2:
		return
	for c in gone:
		root.remove_child(c)
		c.queue_free()
	_flush(groups, root)


## Flatten a fully static tree into chunked meshes.
static func bake_static(root: Node3D, chunk := 24.0) -> void:
	var chunks := {}
	var gone := []
	var stack: Array = [root]
	var base_inv := root.global_transform.affine_inverse()
	while stack.size():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if n is MeshInstance3D and n.get_child_count() == 0 and _mergeable(n):
			var t: Transform3D = base_inv * n.global_transform
			var key := Vector2i(int(floor(t.origin.x / chunk)), int(floor(t.origin.z / chunk)))
			if not chunks.has(key):
				chunks[key] = {}
			_add_part(chunks[key], n, t)
			gone.append(n)
	for n in gone:
		n.get_parent().remove_child(n)
		n.queue_free()
	for key in chunks:
		_flush(chunks[key], root, "Chunk_%d_%d" % [key.x, key.y])
