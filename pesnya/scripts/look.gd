class_name Look
## «Новый облик» (1.0 pilot): smooth skinned character bodies.
## The meshes are sculpted offline (signed distance fields → marching cubes → decimation, see docs/1.0)
## and stored in models/body_*.bin; colours and width are applied here per character.

const BONES := ["body", "head", "arm_a", "elbow_a", "arm_b", "elbow_b", "leg_a", "knee_a", "leg_b", "knee_b"]
const PARENT := [-1, 0, 0, 2, 0, 4, 0, 6, 0, 8]
# region ids written by the generator
enum {SKIN, TOP, SLEEVE, TRIM, DETAIL, PANTS, PANTS_TRIM, SHOE, SOLE, LACE, SKIRT, CUFF}

static var _data := {}
static var _mat: StandardMaterial3D
static var _mesh_cache := {}


static func _load(variant: String) -> Dictionary:
	if _data.has(variant):
		return _data[variant]
	var f := FileAccess.open("res://models/body_%s.bin" % variant, FileAccess.READ)
	if f == null:
		push_error("body mesh missing: " + variant)
		_data[variant] = {}
		return {}
	var magic := f.get_buffer(4).get_string_from_ascii()
	if magic != "PSB1":
		_data[variant] = {}
		return {}
	var nv := f.get_32()
	var nt := f.get_32()
	var d := {}
	d.v = f.get_buffer(nv * 12).to_float32_array()
	d.n = f.get_buffer(nv * 12).to_float32_array()
	d.region = f.get_buffer(nv * 4).to_int32_array()
	d.chain = f.get_buffer(nv * 4).to_int32_array()
	d.bones = f.get_buffer(nv * 16).to_int32_array()
	d.weights = f.get_buffer(nv * 16).to_float32_array()
	d.idx = f.get_buffer(nt * 12).to_int32_array()
	d.nv = nv
	_data[variant] = d
	return d


static func material() -> StandardMaterial3D:
	if _mat == null:
		_mat = StandardMaterial3D.new()
		_mat.vertex_color_use_as_albedo = true
		_mat.vertex_color_is_srgb = true
		_mat.roughness = 0.8
		_mat.rim_enabled = true
		_mat.rim = 0.12
		_mat.rim_tint = 0.4
	return _mat


static func palette(o: Dictionary) -> Array:
	var skin: Color = o.get("skin", Color("e9b48a"))
	var top: Color = o.get("top", Color("f5b55c"))
	var pants: Color = o.get("pants", Color("142a38"))
	var shoes: Color = o.get("shoes", Color("f4f1ea"))
	var torso := top
	if o.has("vest"):
		torso = o.vest
	var sole := Color("2a2b33") if shoes.get_luminance() > 0.55 else Color("dcd8cf")
	var pal := []
	pal.resize(12)
	pal[SKIN] = skin
	pal[TOP] = torso
	pal[SLEEVE] = top
	pal[TRIM] = torso.darkened(0.25)
	pal[DETAIL] = torso.darkened(0.12)
	pal[PANTS] = pants
	pal[PANTS_TRIM] = pants.darkened(0.22)
	pal[SHOE] = shoes
	pal[SOLE] = sole
	pal[LACE] = shoes.darkened(0.3)
	pal[SKIRT] = o.get("skirt_color", Color("6a3b52"))
	pal[CUFF] = top.darkened(0.2)
	return pal


## Builds (or reuses) the coloured, width-adjusted mesh.
static func body_mesh(o: Dictionary, w: float) -> ArrayMesh:
	var variant := "skirt" if o.get("skirt", false) else "pants"
	var pal := palette(o)
	var key := "%s|%.3f|%s" % [variant, w, ",".join(pal.map(func(c): return c.to_html()))]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var d := _load(variant)
	if d.is_empty():
		return null
	var nv: int = d.nv
	var src: PackedFloat32Array = d.v
	var nsrc: PackedFloat32Array = d.n
	var reg: PackedInt32Array = d.region
	var ch: PackedInt32Array = d.chain
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	v.resize(nv)
	n.resize(nv)
	c.resize(nv)
	var dx_arm := 0.45 * (w - 1.0)
	var dx_leg := 0.17 * (w - 1.0)
	for i in range(nv):
		var p := Vector3(src[i * 3], src[i * 3 + 1], src[i * 3 + 2])
		var nn := Vector3(nsrc[i * 3], nsrc[i * 3 + 1], nsrc[i * 3 + 2])
		match ch[i]:
			0:
				if p.y < 1.3:
					var k := lerpf(w, 1.0, clampf((p.y - 1.15) / 0.15, 0.0, 1.0))
					p.x *= k
					p.z *= lerpf(1.0, k, 0.8)
			1:
				p.x -= dx_arm
			2:
				p.x += dx_arm
			3:
				p.x -= dx_leg
			4:
				p.x += dx_leg
		v[i] = p
		n[i] = nn
		c[i] = pal[reg[i]]
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = v
	arrays[Mesh.ARRAY_NORMAL] = n
	arrays[Mesh.ARRAY_COLOR] = c
	arrays[Mesh.ARRAY_BONES] = d.bones
	arrays[Mesh.ARRAY_WEIGHTS] = d.weights
	arrays[Mesh.ARRAY_INDEX] = d.idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	am.surface_set_material(0, material())
	_mesh_cache[key] = am
	return am


## Rest positions of the pivots (same as Chars.human with the new elbow / knee nodes).
static func rest_positions(w: float) -> Array:
	return [Vector3.ZERO, Vector3(0, 1.6, 0),
		Vector3(-0.45 * w, 1.2, 0), Vector3(0, -0.28, 0), Vector3(0.45 * w, 1.2, 0), Vector3(0, -0.28, 0),
		Vector3(-0.17 * w, 0.62, 0), Vector3(0, -0.26, 0), Vector3(0.17 * w, 0.62, 0), Vector3(0, -0.26, 0)]


## Adds the skinned body to a human built by Chars.human (new look). h needs elbows / knees.
static func attach(h: Dictionary, o: Dictionary, w: float) -> void:
	var am := body_mesh(o, w)
	if am == null:
		return
	var sk := BodyRig.new()
	sk.name = "BodySkeleton"
	var rest := rest_positions(w)
	var glob := []
	for i in range(BONES.size()):
		sk.add_bone(BONES[i])
		if PARENT[i] >= 0:
			sk.set_bone_parent(i, PARENT[i])
		sk.set_bone_rest(i, Transform3D(Basis(), rest[i]))
		var g := Transform3D(Basis(), rest[i])
		if PARENT[i] >= 0:
			g = glob[PARENT[i]] * g
		glob.append(g)
	sk.reset_bone_poses()
	var skin := Skin.new()
	for i in range(BONES.size()):
		skin.add_named_bind(BONES[i], glob[i].affine_inverse())
	h.root.add_child(sk)
	var mi := MeshInstance3D.new()
	mi.name = "Body"
	mi.mesh = am
	mi.skin = skin
	mi.extra_cull_margin = 1.0
	sk.add_child(mi)
	mi.skeleton = NodePath("..")
	sk.piv = [h.body, h.head, h.arms[0], h.elbows[0], h.arms[1], h.elbows[1], h.legs[0], h.knees[0], h.legs[1], h.knees[1]]
	h["skeleton"] = sk
	h["body_mesh"] = mi
