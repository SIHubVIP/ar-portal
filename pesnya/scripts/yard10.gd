class_name Yard10
## «Новый облик» (1.0 pilot): двор «Берёзки» — twice the area, panel houses with entrances and balconies,
## birches, a hockey box, parking, the trash pen, drying lines, the lawn. The old landmarks keep their coordinates
## (benches, kiosk, playground, sandbox, garages, the boss spot), so every quest works in both looks.

const BOUNDS := Rect2(-32.5, -29.0, 65.0, 59.8)
const FH := 2.8        # floor height of a panel house
const BASE := 0.9      # plinth height

static var _tex := {}
static var _mats := {}
# low-poly primitives for the props (the default Kit ones are made for close-up characters)
static var CYL: CylinderMesh
static var SPH: SphereMesh
static var DISC: CylinderMesh
static var _tori := {}


static func _prims() -> void:
	if CYL != null:
		return
	CYL = CylinderMesh.new()
	CYL.top_radius = 0.5
	CYL.bottom_radius = 0.5
	CYL.height = 1.0
	CYL.radial_segments = 10
	CYL.rings = 0
	SPH = SphereMesh.new()
	SPH.radius = 0.5
	SPH.height = 1.0
	SPH.radial_segments = 10
	SPH.rings = 6
	DISC = CylinderMesh.new()
	DISC.top_radius = 0.5
	DISC.bottom_radius = 0.5
	DISC.height = 0.02
	DISC.radial_segments = 14
	DISC.rings = 0


static func _torus(p: Node3D, m: Material, inner: float, outer: float, pos := Vector3.ZERO, rot := Vector3.ZERO) -> MeshInstance3D:
	var key := "%.3f|%.3f" % [inner, outer]
	if not _tori.has(key):
		var t := TorusMesh.new()
		t.inner_radius = inner
		t.outer_radius = outer
		t.rings = 14
		t.ring_segments = 6
		_tori[key] = t
	var mi := MeshInstance3D.new()
	mi.mesh = _tori[key]
	mi.material_override = m
	mi.position = pos
	mi.rotation = rot
	p.add_child(mi)
	return mi


# ================================================================== materials
static func tex(n: String) -> Texture2D:
	if _tex.has(n):
		return _tex[n]
	var t: Texture2D = load("res://textures/%s.png" % n)
	var out: Texture2D = t
	if t != null:
		var img := t.get_image()
		if img != null:
			if img.is_compressed():
				img.decompress()
			if not img.has_mipmaps():
				img.generate_mipmaps()
			out = ImageTexture.create_from_image(img)
	_tex[n] = out
	return out


## World-triplanar textured material: `scale` = repeats per metre.
static func tmat(n: String, scale: float, rough := 0.9, tint := Color.WHITE) -> StandardMaterial3D:
	var key := "t|%s|%.3f|%.2f|%s" % [n, scale, rough, tint.to_html()]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex(n)
	m.albedo_color = tint
	m.roughness = rough
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * scale
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_mats[key] = m
	return m


static func facade_mat() -> StandardMaterial3D:
	if _mats.has("facade"):
		return _mats.facade
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex("t_facade")
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.roughness = 0.85
	m.emission_enabled = true
	m.emission_texture = tex("t_facade_em")
	m.emission_energy_multiplier = 0.6
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_mats.facade = m
	return m


static func garage_mat() -> StandardMaterial3D:
	if _mats.has("garage"):
		return _mats.garage
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex("t_garage")
	m.roughness = 0.7
	m.metallic = 0.25
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_mats.garage = m
	return m


static func bark_mat() -> StandardMaterial3D:
	if _mats.has("bark"):
		return _mats.bark
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex("t_bark")
	m.roughness = 0.85
	m.uv1_scale = Vector3(1.0, 3.0, 1.0)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_mats.bark = m
	return m


static func glass_mat() -> StandardMaterial3D:
	if _mats.has("glass"):
		return _mats.glass
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("3a4a5c")
	m.metallic = 0.6
	m.roughness = 0.12
	_mats.glass = m
	return m


const WIND_SHADER := """
shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;
global uniform vec3 player_pos;
uniform float sway = 0.08;
uniform float base_y = 2.0;
uniform float span = 6.0;
uniform float cloth = 0.0;
uniform float see_through = 1.0;
varying vec3 wpos;
void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float h = clamp((wp.y - base_y) / span, 0.0, 1.0);
	if (cloth > 0.5) { h = UV.y; }
	float t = TIME * (1.3 + cloth * 1.6) + wp.x * 0.35 + wp.z * 0.27;
	VERTEX.x += (sin(t) + 0.4 * sin(t * 2.3)) * sway * h;
	VERTEX.z += cos(t * 0.8) * sway * 0.6 * h;
	wpos = wp;
}
void fragment() {
	if (see_through > 0.5) {
		// leaves between the camera and the hero dissolve (screen-door), so trees never hide the fight
		vec3 cp = CAMERA_POSITION_WORLD;
		vec3 pp = player_pos + vec3(0.0, 1.2, 0.0);
		vec3 ab = pp - cp;
		float t = clamp(dot(wpos - cp, ab) / max(dot(ab, ab), 0.001), 0.0, 1.0);
		float d = length(wpos - (cp + ab * t));
		float fade = (t < 0.96) ? smoothstep(1.0, 2.8, d) : 1.0;
		fade = min(fade, smoothstep(1.2, 3.5, -VERTEX.z));
		float n = fract(52.9829189 * fract(dot(FRAGCOORD.xy, vec2(0.06711056, 0.00583715))));
		if (fade < 0.999 && fade < n) { discard; }
	}
	vec3 c = pow(COLOR.rgb, vec3(2.2));
	ALBEDO = c;
	ROUGHNESS = 0.92;
	SPECULAR = 0.15;
	BACKLIGHT = c * 0.35;
}
"""


static var _globals_done := false


static func _globals() -> void:
	if _globals_done:
		return
	_globals_done = true
	RenderingServer.global_shader_parameter_add(&"player_pos", RenderingServer.GLOBAL_VAR_TYPE_VEC3, Vector3.ZERO)


static func wind_mat(cloth := false) -> ShaderMaterial:
	var key := "wind|%s" % cloth
	if _mats.has(key):
		return _mats[key]
	_globals()
	var sh := Shader.new()
	var code := WIND_SHADER
	if cloth:
		code = code.replace("render_mode diffuse_lambert", "render_mode cull_disabled, diffuse_lambert")
	sh.code = code
	var m := ShaderMaterial.new()
	m.shader = sh
	if cloth:
		m.set_shader_parameter("cloth", 1.0)
		m.set_shader_parameter("sway", 0.12)
		m.set_shader_parameter("see_through", 0.0)
	_mats[key] = m
	return m


const SKY_SHADER := """
shader_type sky;
uniform vec3 top_col : source_color = vec3(0.24, 0.44, 0.80);
uniform vec3 hor_col : source_color = vec3(1.0, 0.82, 0.66);
uniform vec3 gnd_col : source_color = vec3(0.36, 0.34, 0.38);
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) { v += a * vnoise(p); p *= 2.03; a *= 0.5; }
	return v;
}
void sky() {
	vec3 d = EYEDIR;
	float h = d.y;
	vec3 col = mix(hor_col, top_col, pow(clamp(h, 0.0, 1.0), 0.5));
	if (h < 0.0) { col = mix(hor_col, gnd_col, clamp(-h * 5.0, 0.0, 1.0)); }
	if (h > 0.01) {
		vec2 uv = d.xz / (h + 0.15) * 1.6;
		float cl = smoothstep(0.5, 0.78, fbm(uv + vec2(3.7, 1.3)));
		float sh = fbm(uv * 1.9 + vec2(5.1, 2.2));
		vec3 cc = mix(vec3(1.0, 0.98, 0.95), vec3(0.74, 0.77, 0.86), sh * 0.8);
		col = mix(col, cc, cl * smoothstep(0.01, 0.22, h) * 0.92);
	}
	if (LIGHT0_ENABLED) {
		float sd = max(dot(d, LIGHT0_DIRECTION), 0.0);
		col += LIGHT0_COLOR * (pow(sd, 900.0) * 8.0 + pow(sd, 12.0) * 0.22);
	}
	COLOR = col;
}
"""


static func yard_sky() -> ShaderMaterial:
	if _mats.has("sky"):
		return _mats.sky
	var sh := Shader.new()
	sh.code = SKY_SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	_mats.sky = m
	return m


static func c(hexs: String, rough := 0.7, metal := 0.0) -> StandardMaterial3D:
	return Kit.mat(Color(hexs), rough, metal)


static func _b(p: Node3D, size: Vector3, pos: Vector3, m: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	return Kit.part(p, Kit.BOX, m, size, pos, rot)


static func _cyl(p: Node3D, d: float, h: float, pos: Vector3, m: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	_prims()
	return Kit.part(p, CYL, m, Vector3(d, h, d), pos, rot)


# ================================================================== procedural meshes
## A soft foliage blob: displaced sphere, vertex colours dark at the bottom → light at the top, normals point outwards.
static func blob(r: float, seed: int, top: Color, bottom: Color, squash := 1.0) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := 8
	var segs := 12
	var pts := []
	var ph := rng.randf() * TAU
	for i in range(rings + 1):
		var row := []
		var v := float(i) / rings
		var th := v * PI
		for j in range(segs + 1):
			var u := float(j % segs) / segs
			var ang := u * TAU
			var dir := Vector3(sin(th) * cos(ang), cos(th), sin(th) * sin(ang))
			var bump := 1.0 + 0.16 * sin(ang * 3.0 + ph) * sin(th * 2.0) + 0.1 * sin(ang * 5.0 + th * 3.0 + ph * 2.0)
			var p := dir * r * bump
			p.y *= squash
			var t := clampf(0.5 + dir.y * 0.6, 0.0, 1.0)
			var col := bottom.lerp(top, t)
			col = col.lightened(rng.randf_range(-0.015, 0.025))
			row.append([p, dir, col])
		pts.append(row)
	for i in range(rings):
		for j in range(segs):
			var a = pts[i][j]
			var b = pts[i][j + 1]
			var cc = pts[i + 1][j + 1]
			var d = pts[i + 1][j]
			for e in [a, cc, b, a, d, cc]:
				st.set_color(e[2])
				st.set_normal(e[1])
				st.add_vertex(e[0])
	return st.commit()


## Quad helper: p0 = bottom-left, ux / uy edges; uv = Rect2 in the texture.
static func _quad(st: SurfaceTool, p0: Vector3, ux: Vector3, uy: Vector3, uv: Rect2, col: Color) -> void:
	var n := uy.cross(ux).normalized()
	var bl := p0
	var br := p0 + ux
	var tl := p0 + uy
	var tr := p0 + ux + uy
	var u0 := uv.position.x
	var v0 := uv.position.y
	var u1 := uv.end.x
	var v1 := uv.end.y
	var verts := [[bl, Vector2(u0, v1)], [tl, Vector2(u0, v0)], [tr, Vector2(u1, v0)], [bl, Vector2(u0, v1)], [tr, Vector2(u1, v0)], [br, Vector2(u1, v1)]]
	for e in verts:
		st.set_color(col)
		st.set_normal(n)
		st.set_uv(e[1])
		st.add_vertex(e[0])


static func _cell(cx: int, cy: int) -> Rect2:
	var k := 1.0 / 8.0
	var e := 0.6 / 1024.0
	return Rect2(cx * k + e, cy * k + e, k - 2 * e, k - 2 * e)


## Adds a rect (local, in the node's XZ) to the world colliders, rotated by the node's yaw (multiples of 90°).
static func _rect_world(rects: Array, node: Node3D, r: Rect2) -> void:
	var xf := node.transform
	var a := xf * Vector3(r.position.x, 0, r.position.y)
	var b := xf * Vector3(r.end.x, 0, r.end.y)
	rects.append(Rect2(minf(a.x, b.x), minf(a.z, b.z), absf(b.x - a.x), absf(b.z - a.z)))


# ================================================================== panel house
## Front faces +Z in local space; the body spans x ∈ [-L/2, L/2], z ∈ [-depth, 0].
static func panel_house(st: Node3D, rects: Array, at: Vector3, rot_y: float, length: float, floors: int, entrances: Array,
		seed: int, tint: Color, accent: Color, depth := 12.0, detail := true, seats: Array = []) -> Node3D:
	var h := Node3D.new()
	h.position = at
	h.rotation.y = rot_y
	st.add_child(h)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var n := maxi(1, int(round(length / 3.2)))
	var bw := length / n
	var top := BASE + floors * FH
	var L2 := length / 2.0
	# plinth, roof, parapet
	_b(h, Vector3(length + 0.12, BASE, depth + 0.12), Vector3(0, BASE / 2, -depth / 2), tmat("t_concrete", 0.5, 0.95, Color(0.72, 0.7, 0.68)))
	_b(h, Vector3(length, 0.3, depth), Vector3(0, top + 0.15, -depth / 2), tmat("t_roof", 0.4, 0.95))
	var par := Kit.mat(tint.darkened(0.12), 0.9)
	_b(h, Vector3(length + 0.2, 0.55, 0.25), Vector3(0, top + 0.27, 0.0), par)
	_b(h, Vector3(length + 0.2, 0.55, 0.25), Vector3(0, top + 0.27, -depth), par)
	for s in [-1, 1]:
		_b(h, Vector3(0.25, 0.55, depth), Vector3(s * (L2 + 0.0), top + 0.27, -depth / 2), par)
	# facades
	var sf := SurfaceTool.new()
	sf.begin(Mesh.PRIMITIVE_TRIANGLES)
	var balcony_cols := []
	for b in range(n):
		if not (b in entrances) and rng.randf() < 0.5:
			balcony_cols.append(b)
	for f in range(floors):
		var y := BASE + f * FH
		for b in range(n):
			var x := -L2 + b * bw
			var cell: Rect2
			if b in entrances:
				cell = _cell(5 + (seed % 2), 7) if f == 0 else _cell(3 + f % 2, 7)
			else:
				cell = _cell(rng.randi() % 8, rng.randi() % 7)
			_quad(sf, Vector3(x, y, 0), Vector3(bw, 0, 0), Vector3(0, FH, 0), cell, tint)
			# back
			_quad(sf, Vector3(-x, y, -depth), Vector3(-bw, 0, 0), Vector3(0, FH, 0), _cell(rng.randi() % 8, rng.randi() % 7), tint.darkened(0.06))
		# gable ends: blank panels
		var nd := int(round(depth / 3.0))
		var dw := depth / nd
		for k in range(nd):
			_quad(sf, Vector3(L2, y, -k * dw), Vector3(0, 0, -dw), Vector3(0, FH, 0), _cell(k % 3, 7), tint.darkened(0.03))
			_quad(sf, Vector3(-L2, y, -depth + k * dw), Vector3(0, 0, dw), Vector3(0, FH, 0), _cell((k + 1) % 3, 7), tint.darkened(0.03))
	var fm := MeshInstance3D.new()
	fm.mesh = sf.commit()
	fm.material_override = facade_mat()
	h.add_child(fm)
	# balconies (stacks), some glazed
	var bal := Kit.mat(accent, 0.8)
	var slab := Kit.mat(Color("b8b2a8"), 0.95)
	var white := Kit.mat(Color("eeeeea"), 0.6)
	if not detail:
		balcony_cols = []
	for b in balcony_cols:
		var x: float = -L2 + (b + 0.5) * bw
		var glazed := rng.randf() < 0.4
		for f in range(1, floors):
			var y := BASE + f * FH
			var w := bw - 0.55
			_b(h, Vector3(w + 0.1, 0.12, 1.05), Vector3(x, y - 0.06, 0.52), slab)
			_b(h, Vector3(w, 1.0, 0.07), Vector3(x, y + 0.5, 1.02), bal)
			for s in [-1, 1]:
				_b(h, Vector3(0.07, 1.0, 1.0), Vector3(x + s * w / 2, y + 0.5, 0.52), bal)
			if glazed or rng.randf() < 0.15:
				_b(h, Vector3(w, 1.3, 0.04), Vector3(x, y + 1.68, 1.02), glass_mat())
				for k in range(4):
					_b(h, Vector3(0.05, 1.3, 0.06), Vector3(x - w / 2 + k * w / 3, y + 1.68, 1.03), white)
				_b(h, Vector3(w, 0.06, 0.08), Vector3(x, y + 2.35, 1.03), white)
				_b(h, Vector3(w, 0.06, 1.0), Vector3(x, y + 2.38, 0.52), white)
			elif rng.randf() < 0.3:
				# something stored on the balcony
				_b(h, Vector3(0.5, 0.45, 0.4), Vector3(x + rng.randf_range(-0.6, 0.6), y + 0.24, 0.5), Kit.mat(Color("8a7a5a").lightened(rng.randf() * 0.3), 0.9))
	# entrances: porch, steps, canopy, lamp, bench, bin
	var concrete := tmat("t_concrete", 0.5, 0.95)
	var door_lamp := Kit.mat(Color("fff2c8"), 0.3, 0.0, Color("ffe8a8"), 2.4)
	for b in (entrances if detail else []):
		var x: float = -L2 + (b + 0.5) * bw
		_b(h, Vector3(2.9, BASE, 1.9), Vector3(x, BASE / 2, 0.95), concrete)
		_b(h, Vector3(2.9, BASE * 0.66, 0.4), Vector3(x, BASE * 0.33, 2.1), concrete)
		_b(h, Vector3(2.9, BASE * 0.33, 0.4), Vector3(x, BASE * 0.165, 2.5), concrete)
		_b(h, Vector3(3.3, 0.16, 2.2), Vector3(x, BASE + 2.55, 1.1), Kit.mat(Color("c8c2b8"), 0.9))
		_b(h, Vector3(0.3, 0.06, 0.16), Vector3(x, BASE + 2.44, 0.4), door_lamp)
		for s in [-1, 1]:
			_b(h, Vector3(0.06, 1.0, 1.9), Vector3(x + s * 1.42, BASE + 0.5, 0.95), Kit.mat(Color("3a4a3a"), 0.6, 0.4))
		_rect_world(rects, h, Rect2(x - 1.5, 0.0, 3.0, 2.75))
		# bench and a bin next to the porch
		var bx: float = x + (2.6 if (b + seed) % 2 == 0 else -2.6)
		bench(h, Vector3(bx, 0, 1.3), 0.0, rects)
		seats.append([h.transform * Vector3(bx, 0, 1.26), rot_y])
		_cyl(h, 0.42, 0.62, Vector3(bx + 1.3, 0.31, 1.0), Kit.mat(Color("3a5a3a"), 0.6, 0.3))
	# drainpipes at the corners
	var pipe := Kit.mat(Color("8a8a88"), 0.5, 0.5)
	for s in [-1, 1]:
		_cyl(h, 0.13, top, Vector3(s * (L2 - 0.25), top / 2, 0.1), pipe)
	# AC units and satellite dishes on random windows
	if not detail:
		_rect_world(rects, h, Rect2(-L2, -depth, length, depth))
		return h
	for k in range(int(n * floors * 0.08) + 1):
		var b := rng.randi() % n
		if b in entrances:
			continue
		var f := 1 + rng.randi() % maxi(1, floors - 1)
		var x := -L2 + (b + 0.5) * bw + 0.95
		_b(h, Vector3(0.7, 0.48, 0.32), Vector3(x, BASE + f * FH + 0.5, 0.17), white)
	for k in range(3):
		var b := rng.randi() % n
		var f := 1 + rng.randi() % maxi(1, floors - 1)
		var x := -L2 + (b + 0.5) * bw - 1.1
		Kit.part(h, DISC, Kit.mat(Color("d8d8d4"), 0.4, 0.2), Vector3(0.6, 1.0, 0.6), Vector3(x, BASE + f * FH + 1.8, 0.35), Vector3(PI / 2 - 0.5, 0, 0))
	# roof: lift huts over the entrances, vents, antennas
	for b in entrances:
		var x: float = -L2 + (b + 0.5) * bw
		_b(h, Vector3(3.2, 2.2, 3.4), Vector3(x, top + 1.1, -depth / 2), Kit.mat(tint.darkened(0.15), 0.9))
		_b(h, Vector3(3.5, 0.2, 3.7), Vector3(x, top + 2.25, -depth / 2), Kit.mat(Color("5a5658"), 0.9))
	var metal := Kit.mat(Color("6a6a6c"), 0.4, 0.6)
	for k in range(maxi(2, n / 3)):
		var x := rng.randf_range(-L2 + 1.5, L2 - 1.5)
		var z := rng.randf_range(-depth + 2, -2)
		_cyl(h, 0.05, 2.6, Vector3(x, top + 1.3, z), metal)
		for j in range(3):
			_b(h, Vector3(1.2 - j * 0.3, 0.04, 0.04), Vector3(x, top + 2.0 + j * 0.25, z), metal, Vector3(0, rng.randf() * PI, 0))
		_b(h, Vector3(0.8, 0.9, 0.8), Vector3(x + 2.0, top + 0.45, z), Kit.mat(tint.darkened(0.2), 0.9))
	_rect_world(rects, h, Rect2(-L2, -depth, length, depth))
	return h


# ================================================================== props
static func bench(p: Node3D, at: Vector3, rot: float, rects: Array = [], col := Color("3a7a5a")) -> Node3D:
	var b := Node3D.new()
	b.position = at
	b.rotation.y = rot
	p.add_child(b)
	var wood := tmat("t_wood", 1.2, 0.85, col.lightened(0.35))
	var iron := Kit.mat(Color("2a2a2e"), 0.5, 0.5)
	for k in range(3):
		_b(b, Vector3(1.9, 0.05, 0.13), Vector3(0, 0.48, -0.17 + k * 0.15), wood)
	for k in range(2):
		_b(b, Vector3(1.9, 0.12, 0.04), Vector3(0, 0.68 + k * 0.16, -0.27), wood, Vector3(-0.15, 0, 0))
	for s in [-1, 1]:
		_b(b, Vector3(0.06, 0.48, 0.42), Vector3(s * 0.8, 0.24, -0.06), iron)
		_b(b, Vector3(0.05, 0.5, 0.05), Vector3(s * 0.8, 0.7, -0.28), iron, Vector3(-0.15, 0, 0))
	if rects is Array and p is Node3D:
		var xf := p.global_transform if p.is_inside_tree() else p.transform
		var w := xf * b.transform
		var a := w * Vector3(-1.0, 0, -0.35)
		var e := w * Vector3(1.0, 0, 0.25)
		rects.append(Rect2(minf(a.x, e.x), minf(a.z, e.z), absf(e.x - a.x), absf(e.z - a.z)))
	return b


static func birch(p: Node3D, at: Vector3, s: float, seed: int, circles: Array) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var t := Node3D.new()
	t.position = at
	t.rotation.y = rng.randf() * TAU
	p.add_child(t)
	var h := 8.6 * s
	var lean := Vector3(rng.randf_range(-0.06, 0.06), 0, rng.randf_range(-0.06, 0.06))
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.07 * s
	trunk.bottom_radius = 0.17 * s
	trunk.height = h
	trunk.radial_segments = 9
	trunk.rings = 1
	var tm := MeshInstance3D.new()
	tm.mesh = trunk
	tm.material_override = bark_mat()
	tm.position = Vector3(0, h / 2, 0)
	tm.rotation = lean
	t.add_child(tm)
	var top := Vector3(0, h, 0).rotated(Vector3.RIGHT, lean.x).rotated(Vector3.BACK, lean.z)
	# a few branches
	var br := Kit.mat(Color("5a4a40"), 0.9)
	for k in range(4):
		var y := h * rng.randf_range(0.45, 0.85)
		var a := rng.randf() * TAU
		_cyl(t, 0.06 * s, 1.6 * s, Vector3(cos(a) * 0.5, y + 0.4, sin(a) * 0.5), br, Vector3(cos(a) * 0.9, 0, sin(a) * 0.9).rotated(Vector3.UP, PI / 2))
	# hanging crown: several soft blobs
	var leaf_top := Color("b4d468").lerp(Color("e0c850"), rng.randf() * 0.3)
	var leaf_bot := Color("5a8a3a")
	for k in range(6):
		var a := k * 1.05 + rng.randf()
		var rr := rng.randf_range(0.5, 1.1) * s
		var off := Vector3(cos(a) * rr, h * rng.randf_range(0.66, 0.97), sin(a) * rr)
		var bm := MeshInstance3D.new()
		bm.mesh = blob(rng.randf_range(0.85, 1.25) * s, seed * 7 + k, leaf_top, leaf_bot, 1.35)
		bm.material_override = wind_mat()
		bm.position = off + Vector3(top.x, 0, top.z) * (off.y / h)
		t.add_child(bm)
	circles.append(Vector3(at.x, at.z, 0.3))


static func round_tree(p: Node3D, at: Vector3, s: float, seed: int, circles: Array, autumn := 0.0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var t := Node3D.new()
	t.position = at
	p.add_child(t)
	var h := 3.8 * s
	_cyl(t, 0.32 * s, h, Vector3(0, h / 2, 0), Kit.mat(Color("5a4636"), 0.95))
	var top := Color("8ab858").lerp(Color("e8b048"), autumn)
	var bot := Color("4a7a34").lerp(Color("9a6a30"), autumn)
	for k in range(5):
		var a := k * 1.3 + rng.randf()
		var off := Vector3(cos(a) * 1.1 * s, h + rng.randf_range(0.6, 1.8) * s, sin(a) * 1.1 * s)
		if k == 0:
			off = Vector3(0, h + 1.9 * s, 0)
		var bm := MeshInstance3D.new()
		bm.mesh = blob(rng.randf_range(1.3, 1.8) * s, seed * 11 + k, top, bot, 0.9)
		bm.material_override = wind_mat()
		bm.position = off
		t.add_child(bm)
	circles.append(Vector3(at.x, at.z, 0.4))


static func bush(p: Node3D, at: Vector3, s: float, seed: int, flowers := Color(0, 0, 0, 0)) -> void:
	var bm := MeshInstance3D.new()
	bm.mesh = blob(0.75 * s, seed, Color("6a9a42"), Color("2e5a26"), 0.75)
	bm.material_override = wind_mat()
	bm.position = at + Vector3(0, 0.45 * s, 0)
	p.add_child(bm)
	if flowers.a > 0.0:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		for k in range(6):
			var a := rng.randf() * TAU
			Kit.part(p, SPH, Kit.mat(flowers, 0.6), Vector3.ONE * 0.16, at + Vector3(cos(a) * 0.55 * s, 0.75 * s + rng.randf() * 0.2, sin(a) * 0.55 * s))


static func lamp(p: Node3D, at: Vector3, dir: float) -> void:
	var post := Kit.mat(Color("3a3e44"), 0.45, 0.6)
	_cyl(p, 0.16, 5.6, at + Vector3(0, 2.8, 0), post)
	_cyl(p, 0.26, 0.5, at + Vector3(0, 0.25, 0), post)
	var arm := Vector3(cos(dir), 0, sin(dir))
	_b(p, Vector3(1.3, 0.1, 0.12), at + Vector3(0, 5.55, 0) + arm * 0.6, post, Vector3(0, -dir, 0))
	_b(p, Vector3(0.62, 0.12, 0.3), at + Vector3(0, 5.5, 0) + arm * 1.2, post, Vector3(0, -dir, 0))
	_b(p, Vector3(0.5, 0.04, 0.22), at + Vector3(0, 5.43, 0) + arm * 1.2, Kit.neon(Color("fff0d0"), 1.6), Vector3(0, -dir, 0))


static func car(p: Node3D, at: Vector3, rot: float, col: Color, kind: int, rects: Array) -> void:
	var cn := Node3D.new()
	cn.position = at
	cn.rotation.y = rot
	p.add_child(cn)
	var paint := Kit.mat(col, 0.35, 0.3)
	var dark := Kit.mat(Color("1a1c20"), 0.6)
	var chrome := Kit.mat(Color("c8ccd0"), 0.2, 0.9)
	var glass := glass_mat()
	var L := 4.1 if kind != 2 else 3.8
	var W := 1.68
	# lower body
	_b(cn, Vector3(W, 0.62, L), Vector3(0, 0.62, 0), paint)
	_b(cn, Vector3(W + 0.04, 0.12, L + 0.06), Vector3(0, 0.38, 0), dark)
	match kind:
		0:   # sedan (the classic «семёрка» silhouette)
			_b(cn, Vector3(W - 0.12, 0.62, 2.0), Vector3(0, 1.2, -0.2), paint)
			_b(cn, Vector3(W - 0.08, 0.5, 1.96), Vector3(0, 1.2, -0.2), glass)
		1:   # hatchback
			_b(cn, Vector3(W - 0.1, 0.66, 2.4), Vector3(0, 1.22, -0.55), paint)
			_b(cn, Vector3(W - 0.06, 0.52, 2.36), Vector3(0, 1.22, -0.55), glass)
		2:   # «Нива»: tall and short
			_b(cn, Vector3(W - 0.1, 0.72, 2.2), Vector3(0, 1.3, -0.45), paint)
			_b(cn, Vector3(W - 0.06, 0.56, 2.16), Vector3(0, 1.3, -0.45), glass)
	# lights, bumpers, plates
	for s in [-1, 1]:
		_b(cn, Vector3(0.36, 0.14, 0.04), Vector3(s * 0.56, 0.74, L / 2 + 0.01), Kit.mat(Color("fff6e0"), 0.2, 0.0, Color("fff2d0"), 0.6))
		_b(cn, Vector3(0.32, 0.12, 0.04), Vector3(s * 0.58, 0.74, -L / 2 - 0.01), Kit.mat(Color("c02020"), 0.3, 0.0, Color("ff2020"), 0.4))
	_b(cn, Vector3(W, 0.12, 0.08), Vector3(0, 0.45, L / 2 + 0.02), chrome)
	_b(cn, Vector3(W, 0.12, 0.08), Vector3(0, 0.45, -L / 2 - 0.02), chrome)
	_b(cn, Vector3(0.52, 0.12, 0.02), Vector3(0, 0.55, -L / 2 - 0.07), Kit.mat(Color("f4f4f0"), 0.5))
	# wheels
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			_cyl(cn, 0.62, 0.22, Vector3(sx * (W / 2 - 0.02), 0.31, sz * (L / 2 - 0.75)), dark, Vector3(0, 0, PI / 2))
			_cyl(cn, 0.32, 0.24, Vector3(sx * (W / 2 - 0.01), 0.31, sz * (L / 2 - 0.75)), chrome, Vector3(0, 0, PI / 2))
	_rect_world(rects, cn, Rect2(-W / 2, -L / 2, W, L))


static func ground(st: Node3D, r: Rect2, m: Material, y := 0.0, h := 0.04) -> void:
	# a flat quad with world-space UVs (the material's uv1_scale sets the tiling); h is ignored
	var sf := SurfaceTool.new()
	sf.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sc := 1.0
	if m is StandardMaterial3D:
		sc = m.get_meta("tile", 1.0)
	var uv := Rect2(r.position.x * sc, r.position.y * sc, r.size.x * sc, r.size.y * sc)
	var pts := [[Vector3(r.position.x, y, r.end.y), Vector2(uv.position.x, uv.end.y)], [Vector3(r.position.x, y, r.position.y), Vector2(uv.position.x, uv.position.y)],
		[Vector3(r.end.x, y, r.position.y), Vector2(uv.end.x, uv.position.y)], [Vector3(r.end.x, y, r.end.y), Vector2(uv.end.x, uv.end.y)]]
	for i in [0, 1, 2, 0, 2, 3]:
		sf.set_normal(Vector3.UP)
		sf.set_uv(pts[i][1])
		sf.add_vertex(pts[i][0])
	var mi := MeshInstance3D.new()
	mi.mesh = sf.commit()
	mi.material_override = m
	st.add_child(mi)


## UV-mapped (not triplanar) material for flat ground quads: `scale` = repeats per metre.
static func gmat(n: String, scale: float, rough := 0.9, tint := Color.WHITE) -> StandardMaterial3D:
	var key := "g|%s|%.3f|%.2f|%s" % [n, scale, rough, tint.to_html()]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex(n)
	m.albedo_color = tint
	m.roughness = rough
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.set_meta("tile", scale)
	_mats[key] = m
	return m


static func curb_rect(st: Node3D, r: Rect2, sides := "nsew") -> void:
	var m := tmat("t_concrete", 0.8, 0.9, Color(0.85, 0.84, 0.82))
	if "n" in sides:
		_b(st, Vector3(r.size.x, 0.1, 0.18), Vector3(r.get_center().x, 0.04, r.position.y), m)
	if "s" in sides:
		_b(st, Vector3(r.size.x, 0.1, 0.18), Vector3(r.get_center().x, 0.04, r.end.y), m)
	if "w" in sides:
		_b(st, Vector3(0.18, 0.1, r.size.y), Vector3(r.position.x, 0.04, r.get_center().y), m)
	if "e" in sides:
		_b(st, Vector3(0.18, 0.1, r.size.y), Vector3(r.end.x, 0.04, r.get_center().y), m)


## Low arched lawn fence (the classic green «дуги»).
static func lawn_fence(st: Node3D, a: Vector3, b: Vector3) -> void:
	var m := Kit.mat(Color("2f6a3a"), 0.5, 0.3)
	var d := b - a
	var L := d.length()
	var n := maxi(1, int(L / 0.9))
	var yaw := atan2(d.x, d.z)
	for k in range(n):
		var p := a + d * ((k + 0.5) / n)
		_torus(st, m, 0.36, 0.4, p + Vector3(0, 0.0, 0), Vector3(PI / 2, yaw + PI / 2, 0)).scale = Vector3(1.0, 1.0, 1.0)


# ================================================================== life in the yard (no gameplay: passers-by, kids, a dog, a cat)
static func _person(o: Dictionary) -> Dictionary:
	var h := Chars.human(o)
	return h


static func dog(col: Color) -> Dictionary:
	var r := Node3D.new()
	var fur := Kit.mat(col, 0.9)
	var dark := Kit.mat(col.darkened(0.45), 0.9)
	var body := Node3D.new()
	r.add_child(body)
	Kit.part(body, SPH, fur, Vector3(0.36, 0.34, 0.8), Vector3(0, 0.42, 0))
	var head := Node3D.new()
	head.position = Vector3(0, 0.62, 0.42)
	body.add_child(head)
	Kit.part(head, SPH, fur, Vector3(0.3, 0.28, 0.32))
	Kit.part(head, SPH, fur, Vector3(0.18, 0.15, 0.22), Vector3(0, -0.05, 0.17))
	Kit.part(head, SPH, Kit.mat(Color("1a1414"), 0.3), Vector3.ONE * 0.07, Vector3(0, -0.02, 0.29))
	for sx in [-1, 1]:
		Kit.part(head, SPH, dark, Vector3(0.09, 0.2, 0.06), Vector3(sx * 0.13, 0.08, -0.02), Vector3(0, 0, sx * 0.5))
		Kit.part(head, SPH, Kit.mat(Color("1a1414"), 0.3), Vector3.ONE * 0.05, Vector3(sx * 0.07, 0.05, 0.14))
	var legs := []
	for k in range(4):
		var lp := Node3D.new()
		lp.position = Vector3((-1 if k % 2 == 0 else 1) * 0.11, 0.36, 0.26 if k < 2 else -0.26)
		body.add_child(lp)
		_cyl(lp, 0.1, 0.34, Vector3(0, -0.17, 0), fur)
		legs.append(lp)
	var tail := Node3D.new()
	tail.position = Vector3(0, 0.5, -0.38)
	body.add_child(tail)
	_cyl(tail, 0.06, 0.32, Vector3(0, 0.14, -0.04), fur, Vector3(-0.5, 0, 0))
	return {"root": r, "body": body, "head": head, "legs": legs, "tail": tail}


static func cat(col: Color) -> Dictionary:
	var r := Node3D.new()
	var fur := Kit.mat(col, 0.9)
	Kit.part(r, SPH, fur, Vector3(0.26, 0.3, 0.42), Vector3(0, 0.16, 0))
	Kit.part(r, SPH, fur, Vector3(0.22, 0.2, 0.2), Vector3(0, 0.36, 0.16))
	for sx in [-1, 1]:
		Kit.part(r, SPH, fur, Vector3(0.06, 0.1, 0.05), Vector3(sx * 0.07, 0.47, 0.15))
		Kit.part(r, SPH, Kit.mat(Color("c8e84a"), 0.2), Vector3.ONE * 0.04, Vector3(sx * 0.05, 0.38, 0.25))
	var tail := Node3D.new()
	tail.position = Vector3(0, 0.12, -0.2)
	r.add_child(tail)
	_cyl(tail, 0.05, 0.4, Vector3(0.08, 0.0, -0.18), fur, Vector3(0, 0, 1.3))
	return {"root": r, "tail": tail}


static func stroller() -> Node3D:
	var r := Node3D.new()
	var c := Kit.mat(Color("5a7ab8"), 0.7)
	var dark := Kit.mat(Color("22232a"), 0.6)
	_b(r, Vector3(0.5, 0.36, 0.8), Vector3(0, 0.62, 0), c)
	Kit.part(r, SPH, c, Vector3(0.52, 0.5, 0.5), Vector3(0, 0.82, -0.22))
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			_cyl(r, 0.26, 0.05, Vector3(sx * 0.24, 0.14, sz * 0.3), dark, Vector3(0, 0, PI / 2))
		_cyl(r, 0.035, 0.6, Vector3(sx * 0.22, 0.9, -0.52), dark, Vector3(0.6, 0, 0))
	_cyl(r, 0.04, 0.5, Vector3(0, 1.14, -0.7), dark, Vector3(0, 0, PI / 2))
	return r


## Builds the extras; returns a list of actors for update_ambient().
static func ambient(root: Node3D, seats: Array) -> Array:
	var out := []
	var walkers := [
		# woman with a stroller along the west houses
		[{"top": Color("c86a8a"), "pants": Color("3a3a52"), "shoes": Color("f4f0ea"), "hair": "bun", "hair_color": Color("6a3a22"), "skin": Color("f0c4a4")},
			[Vector3(-30.9, 0, -17.0), Vector3(-30.9, 0, 21.0)], 1.25, "stroller"],
		# a man with a dog along the south walk
		[{"top": Color("4a6a4a"), "pants": Color("2a3240"), "shoes": Color("3a2a22"), "hair": "beanie", "hair_color": Color("8a2a2a"), "width": 1.08},
			[Vector3(-30.0, 0, 28.6), Vector3(30.0, 0, 28.6)], 1.15, "dog"],
		# a student with headphones crossing the yard
		[{"top": Color("e8e4dc"), "pants": Color("3a5a8a"), "shoes": Color("e84a4a"), "hair": "short", "hair_color": Color("1a1412")},
			[Vector3(2.6, 0, -19.0), Vector3(2.6, 0, 22.0), Vector3(-2.6, 0, 22.0), Vector3(-2.6, 0, -19.0)], 1.5, ""],
	]
	for w in walkers:
		var h := _person(w[0])
		root.add_child(h.root)
		Kit.bake_tree(h.root)
		var a := {"kind": "walk", "h": h, "path": w[1], "seg": 0, "t": 0.0, "speed": w[2], "phase": randf() * 6.0}
		if w[3] == "stroller":
			var sr := stroller()
			h.root.add_child(sr)
			sr.position = Vector3(0, 0, 0.85)
			Kit.bake_tree(sr)
			a["carry"] = true
		elif w[3] == "dog":
			var d := dog(Color("c8a070"))
			root.add_child(d.root)
			Kit.bake_tree(d.root)
			a["dog"] = d
		h.root.position = w[1][0]
		out.append(a)
	# kids playing football in the hockey box
	for k in range(2):
		var h := _person({"top": [Color("e8423c"), Color("3a8ad8")][k], "pants": Color("2a2a36"), "shoes": Color("f4f4f0"),
			"hair": ["cap_back", "short"][k], "hair_color": [Color("2a5ad8"), Color("8a5a2a")][k], "scale": Vector3.ONE * 0.72})
		root.add_child(h.root)
		Kit.bake_tree(h.root)
		out.append({"kind": "kick", "h": h, "side": k, "phase": k * PI})
	var ball := MeshInstance3D.new()
	ball.mesh = SPH
	ball.scale = Vector3.ONE * 0.24
	ball.material_override = Kit.mat(Color("f4f4f0"), 0.4)
	root.add_child(ball)
	out.append({"kind": "ball", "node": ball})
	# a granny resting on the bench by the W1 entrance, knitting
	var g := _person({"top": Color("8a6a9a"), "pants": Color("5a4a3a"), "shoes": Color("3a2a22"), "hair": "headscarf", "scarf": Color("3a8a6a"),
		"skirt": true, "skirt_color": Color("4a3a5a"), "width": 1.2, "scale": Vector3(1.0, 0.88, 1.0), "skin": Color("eab79a")})
	root.add_child(g.root)
	Kit.bake_tree(g.root)
	var seat: Array = seats[0] if seats.size() > 0 else [Vector3(-33.1, 0, -1.6), PI / 2]
	out.append({"kind": "sit", "h": g, "pos": seat[0], "rot": seat[1]})
	# a man looking under the bonnet of his «Жигули»
	var m := _person({"top": Color("f4f4f0"), "pants": Color("2a3a5a"), "shoes": Color("2a2a2a"), "hair": "none", "width": 1.15})
	root.add_child(m.root)
	Kit.bake_tree(m.root)
	out.append({"kind": "fix", "h": m, "pos": Vector3(-25.7, 0, 14.4), "rot": -PI / 2})
	# a ginger cat on the garage roof and a black one by the bins
	for c in [[Color("e8903a"), Vector3(-20.0, 2.95, -32.0), 0.6], [Color("2a2a2e"), Vector3(-25.6, 0, -16.4), -2.4]]:
		var ct := cat(c[0])
		root.add_child(ct.root)
		ct.root.position = c[1]
		ct.root.rotation.y = c[2]
		Kit.bake_tree(ct.root)
		out.append({"kind": "cat", "c": ct, "phase": randf() * 6.0})
	return out


static func update_ambient(list: Array, dt: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var kick_pos := []
	for a in list:
		match a.kind:
			"walk":
				var h: Dictionary = a.h
				var path: Array = a.path
				var p0: Vector3 = path[a.seg]
				var p1: Vector3 = path[(a.seg + 1) % path.size()]
				var L := maxf(0.01, p0.distance_to(p1))
				a.t += dt * a.speed / L
				if a.t >= 1.0:
					a.t = 0.0
					a.seg = (a.seg + 1) % path.size()
					if path.size() == 2:
						# walk back the same way
						path.reverse()
						a.seg = 0
				var p := p0.lerp(p1, a.t)
				var dir := (p1 - p0).normalized()
				h.root.position = p
				h.root.rotation.y = atan2(dir.x, dir.z)
				a.phase += dt * a.speed * 4.2
				var sw := sin(a.phase) * 0.55
				h.legs[0].rotation.x = sw
				h.legs[1].rotation.x = -sw
				if a.get("carry", false):
					h.arms[0].rotation.x = -0.9
					h.arms[1].rotation.x = -0.9
				else:
					h.arms[0].rotation.x = -sw * 0.7
					h.arms[1].rotation.x = sw * 0.7
				h.body.position.y = absf(cos(a.phase)) * 0.05
				if a.has("dog"):
					var d: Dictionary = a.dog
					var side := Vector3(dir.z, 0, -dir.x) * 0.9
					d.root.position = p + dir * 1.1 + side
					d.root.rotation.y = atan2(dir.x, dir.z)
					var ds := sin(a.phase * 1.6) * 0.6
					for i in range(4):
						d.legs[i].rotation.x = ds if i % 3 == 0 else -ds
					d.tail.rotation.z = sin(t * 9.0) * 0.6
			"kick":
				var h: Dictionary = a.h
				var z: float = -4.2 + (-1.0 if a.side == 0 else 1.0) * (2.6 + sin(t * 0.9 + a.phase) * 1.2)
				var x: float = -25.6 + sin(t * 1.3 + a.phase) * 2.2
				var np := Vector3(x, 0, z)
				var v: Vector3 = np - h.root.position
				h.root.position = np
				h.root.rotation.y = PI if a.side == 1 else 0.0
				var run := clampf(v.length() / maxf(dt, 0.001) / 3.0, 0.2, 1.0)
				var ph: float = t * 9.0 + a.phase
				h.legs[0].rotation.x = sin(ph) * 0.8 * run
				h.legs[1].rotation.x = -sin(ph) * 0.8 * run
				h.arms[0].rotation.x = -sin(ph) * 0.6 * run
				h.arms[1].rotation.x = sin(ph) * 0.6 * run
				kick_pos.append(np)
			"ball":
				if kick_pos.size() == 2:
					var k := 0.5 + 0.5 * sin(t * 1.1)
					var bp: Vector3 = kick_pos[0].lerp(kick_pos[1], k)
					a.node.position = bp + Vector3(0, 0.12 + absf(sin(t * 3.3)) * 0.5, 0.0)
					a.node.rotation.x = t * 6.0
			"sit":
				var h: Dictionary = a.h
				h.root.position = a.pos + Vector3(0, -0.14, 0)
				h.root.rotation.y = a.rot
				h.legs[0].rotation.x = -1.45
				h.legs[1].rotation.x = -1.45
				h.arms[0].rotation.x = -0.75 + sin(t * 4.0) * 0.08
				h.arms[1].rotation.x = -0.75 - sin(t * 4.0) * 0.08
				h.head.rotation.x = 0.25
				if h.has("skeleton"):
					h.skeleton.hold = {7: 1.5, 9: 1.5, 3: -1.0, 5: -1.0}
			"fix":
				var h: Dictionary = a.h
				h.root.position = a.pos
				h.root.rotation.y = a.rot
				h.body.rotation.x = 0.75
				h.legs[0].rotation.x = -0.6
				h.legs[1].rotation.x = -0.6
				h.arms[0].rotation.x = -1.2 + sin(t * 5.0) * 0.2
				h.arms[1].rotation.x = -1.0 - sin(t * 3.0) * 0.25
				h.head.rotation.x = 0.2 + sin(t * 0.7) * 0.1
			"cat":
				a.c.tail.rotation.y = sin(t * 2.0 + a.phase) * 0.5


# ================================================================== the yard
static func build(parent: Node3D) -> Dictionary:
	_prims()
	var root := Node3D.new()
	root.name = "World"
	parent.add_child(root)
	var st := Node3D.new()
	st.name = "Static"
	root.add_child(st)
	var rects: Array = []
	var circles: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026

	# ---------------------------------------------------------- ground (own node: baked apart and casts no shadows)
	var gr := Node3D.new()
	gr.name = "Ground"
	root.add_child(gr)
	var st_props := st
	st = gr
	ground(st, Rect2(-120, -120, 240, 240), gmat("t_grass", 0.2, 0.95), -0.02)
	var asphalt := gmat("t_asphalt", 0.25, 0.92, Color(0.84, 0.83, 0.88))
	var tiles := gmat("t_tiles", 0.5, 0.9, Color(0.93, 0.92, 0.92))
	var roads := [Rect2(-32.5, -27.6, 65.0, 7.0), Rect2(-3.5, -20.6, 7.0, 44.1), Rect2(-46.0, 23.5, 92.0, 6.0),
		Rect2(-31.4, 13.0, 6.0, 10.5), Rect2(-31.0, -19.5, 7.0, 5.0)]
	for r in roads:
		ground(st, r, asphalt, 0.0)
	# parking pockets along the south drive
	for r in [Rect2(-18.5, 19.4, 11.0, 4.1), Rect2(7.5, 19.4, 11.0, 4.1)]:
		ground(st, r, asphalt, 0.0)
		for k in range(5):
			_b(st, Vector3(0.08, 0.01, 3.8), Vector3(r.position.x + 0.3 + k * 2.6, 0.005, r.get_center().y), Kit.mat(Color("e8e6de"), 0.6))
	var walks := [Rect2(-6.0, -20.6, 2.5, 42.2), Rect2(3.5, -20.6, 2.5, 42.2), Rect2(-34.0, -20.6, 2.6, 44.1), Rect2(31.4, -20.6, 2.6, 44.1),
		Rect2(-46.0, 29.5, 92.0, 2.7), Rect2(-31.4, 6.5, 25.4, 5.0), Rect2(6.0, -0.5, 25.4, 5.0), Rect2(-19.0, -5.0, 13.0, 2.2)]
	for r in walks:
		ground(st, r, tiles, 0.006)
	st = st_props
	for r in [Rect2(-3.5, -20.6, 7.0, 44.1)]:
		curb_rect(st, r, "we")
	curb_rect(st, Rect2(-32.5, -27.6, 65.0, 7.0), "s")
	curb_rect(st, Rect2(-46.0, 23.5, 92.0, 6.0), "n")
	# hopscotch on the east walk
	for k in range(6):
		_b(st, Vector3(0.9, 0.012, 0.05), Vector3(4.75, 0.04, 2 - k * 0.9), Kit.mat(Color("f4f0e6"), 0.9))
	for k in range(4):
		_b(st, Vector3(0.7, 0.012, 0.7), Vector3(4.75, 0.035, 1.55 - k * 0.9), Kit.mat(Color("ff7aa8"), 0.9))
	# manholes and puddles
	for p in [Vector3(0.8, 0, -8.0), Vector3(-1.2, 0, 12.0), Vector3(18.0, 0, -24.0), Vector3(-20.0, 0, 26.5)]:
		Kit.part(st, DISC, Kit.mat(Color("3a3836"), 0.5, 0.6), Vector3(0.8, 1.0, 0.8), p + Vector3(0, 0.012, 0))
	for p in [Vector3(-1.8, 0, -14.0), Vector3(1.4, 0, 6.5), Vector3(-12.0, 0, 26.0), Vector3(14.0, 0, -23.0)]:
		Kit.part(st, DISC, Kit.mat(Color("2a3442"), 0.04, 0.3), Vector3(rng.randf_range(1.2, 2.2), 1.0, rng.randf_range(0.8, 1.4)), p + Vector3(0, 0.011, 0))

	# ---------------------------------------------------------- panel houses around the yard
	var seats := []
	var beige := Color("efe4cf")
	var cream := Color("f2ecd9")
	var blue := Color("dfe6ea")
	var pink := Color("f0ddd2")
	panel_house(st, rects, Vector3(-34.4, 0, -12.5), PI / 2, 33.0, 5, [2, 7], 11, beige, Color("7aa0c8"), 12.0, true, seats)      # W1, front faces +X
	panel_house(st, rects, Vector3(-34.4, 0, 28.0), PI / 2, 29.0, 5, [3, 6], 12, blue, Color("c8786a"))       # W2
	panel_house(st, rects, Vector3(34.4, 0, -16.5), -PI / 2, 25.0, 5, [2, 5], 13, pink, Color("8ab08a"))      # E1
	panel_house(st, rects, Vector3(34.4, 0, 22.0), -PI / 2, 29.0, 5, [2, 6], 14, cream, Color("7aa0c8"))      # E2
	panel_house(st, rects, Vector3(-25.0, 0, 32.6), PI, 38.0, 5, [3, 8], 15, cream, Color("d0a060"))           # S1
	panel_house(st, rects, Vector3(25.0, 0, 32.6), PI, 38.0, 5, [3, 8], 16, beige, Color("7aa0c8"))            # S2
	# the tall ones behind the garages and around
	panel_house(st, rects, Vector3(-24.0, 0, -42.0), 0.0, 38.0, 9, [3, 8], 17, blue, Color("c8786a"), 12.0, false)
	panel_house(st, rects, Vector3(22.0, 0, -44.0), 0.0, 35.0, 9, [2, 7], 18, beige, Color("8ab08a"), 12.0, false)
	panel_house(st, rects, Vector3(4.0, 0, -78.0), 0.0, 54.0, 16, [4, 12], 19, cream, Color("7aa0c8"), 12.0, false)
	panel_house(st, rects, Vector3(-64.0, 0, 6.0), PI / 2, 42.0, 12, [3, 9], 20, pink, Color("c8786a"), 12.0, false)
	panel_house(st, rects, Vector3(66.0, 0, 2.0), -PI / 2, 46.0, 12, [3, 10], 21, blue, Color("d0a060"), 12.0, false)
	panel_house(st, rects, Vector3(0.0, 0, 72.0), PI, 60.0, 14, [4, 14], 22, beige, Color("8ab08a"), 12.0, false)

	# ---------------------------------------------------------- garage rows (north edge)
	var gm := garage_mat()
	var gbody := tmat("t_concrete", 0.5, 0.95, Color(0.86, 0.84, 0.8))
	var gx := -32.3
	var gi := 0
	while gx < 32.4:
		if gx > 11.9 and gx < 18.6:
			gx = 18.6
			continue
		var g := Node3D.new()
		g.position = Vector3(gx + 1.7, 0, -30.0)
		st.add_child(g)
		_b(g, Vector3(3.4, 2.8, 6), Vector3(0, 1.4, -3), gbody)
		_b(g, Vector3(3.6, 0.18, 6.4), Vector3(0, 2.86, -3), tmat("t_roof", 0.5, 0.95))
		var sf := SurfaceTool.new()
		sf.begin(Mesh.PRIMITIVE_TRIANGLES)
		var v := gi % 4
		_quad(sf, Vector3(-1.4, 0.0, 0.03), Vector3(2.8, 0, 0), Vector3(0, 2.3, 0), Rect2((v % 2) * 0.5, (v / 2) * 0.5, 0.5, 0.5), Color.WHITE)
		var dm := MeshInstance3D.new()
		dm.mesh = sf.commit()
		dm.material_override = gm
		g.add_child(dm)
		gx += 3.4
		gi += 1
	rects.append(Rect2(-32.5, -36.0, 44.5, 6.2))
	rects.append(Rect2(18.6, -36.0, 14.0, 6.2))
	Chars.label(root, "ГАРАЖИ", 120, Color(1.8, 1.6, 1.2), Vector3(-3, 3.6, -29.9), Vector3.ZERO, 0.01, 10)
	var arch := Kit.mat(Color("2a5a3a"), 0.5, 0.4)
	for x in [13.2, 18.0]:
		_b(st, Vector3(0.35, 4.2, 0.35), Vector3(x, 2.1, -29.6), arch)
		circles.append(Vector3(x, -29.6, 0.3))
	_b(st, Vector3(5.2, 0.6, 0.3), Vector3(15.6, 4.2, -29.6), arch)
	Chars.label(root, "ГК «ПЕСНЯ»", 90, Color(3.0, 2.2, 1.0), Vector3(15.6, 4.2, -29.4), Vector3.ZERO, 0.0085, 10)
	Chars.label(root, "проход к гаражам ↑", 60, Color(1.6, 1.6, 1.6), Vector3(15.6, 3.5, -29.4), Vector3.ZERO, 0.007, 8)
	Chars.ring(root, Vector3(15.6, 0.05, -28.4), 1.2, Color("55cdbe"), 0.08, 3.0)
	ground(st, Rect2(13.3, -36.0, 4.6, 8.0), asphalt, 0.0)

	# ---------------------------------------------------------- playground (same spots as before)
	var red := Kit.mat(Color("d8423c"), 0.5, 0.2)
	var yel := Kit.mat(Color("f2b21c"), 0.5)
	var blu := Kit.mat(Color("3a7ac8"), 0.5, 0.2)
	var grn := Kit.mat(Color("3aa85a"), 0.5)
	ground(st, Rect2(7.0, -12.5, 9.5, 10.0), gmat("t_rubber", 0.5, 0.95), 0.008)
	curb_rect(st, Rect2(7.0, -12.5, 9.5, 10.0))
	# swings
	for x in [8.5, 11.5]:
		for z in [-4.0, -5.4]:
			_cyl(st, 0.12, 2.6, Vector3(x, 1.3, z), red, Vector3(0.18 * (1 if z < -4.5 else -1), 0, 0))
	_cyl(st, 0.12, 3.2, Vector3(10, 2.55, -4.7), red, Vector3(0, 0, PI / 2))
	for x in [9.4, 10.6]:
		for dx in [-0.2, 0.2]:
			_b(st, Vector3(0.02, 1.8, 0.02), Vector3(x + dx, 1.6, -4.7), Kit.mat(Color("8a8a8e"), 0.4, 0.7))
		_b(st, Vector3(0.6, 0.06, 0.3), Vector3(x, 0.7, -4.7), yel)
	for x in [8.5, 11.5]:
		circles.append(Vector3(x, -4.7, 0.5))
	# slide: tower + ladder + chute
	_b(st, Vector3(1.4, 0.1, 1.4), Vector3(11, 1.5, -10), tmat("t_wood", 1.0, 0.8))
	for sx in [-0.65, 0.65]:
		for sz in [-0.65, 0.65]:
			_cyl(st, 0.1, 2.6, Vector3(11 + sx, 1.3, -10 + sz), blu)
	_b(st, Vector3(1.5, 0.12, 1.5), Vector3(11, 2.6, -10), red)
	_b(st, Vector3(1.6, 0.6, 1.6), Vector3(11, 2.95, -10), Kit.mat(Color("f2b21c"), 0.5), Vector3(0, PI / 4, 0))
	_b(st, Vector3(0.9, 0.06, 3.3), Vector3(11, 0.85, -7.9), yel, Vector3(-0.47, 0, 0))
	for s in [-1, 1]:
		_b(st, Vector3(0.06, 0.2, 3.3), Vector3(11 + s * 0.45, 0.95, -7.9), Kit.mat(Color("e09a10"), 0.5), Vector3(-0.47, 0, 0))
	for k in range(5):
		_b(st, Vector3(0.7, 0.05, 0.12), Vector3(11, 0.3 + k * 0.28, -11.0 - k * 0.12), blu)
	rects.append(Rect2(10.3, -10.7, 1.4, 1.4))
	# carousel and a spring rocker
	_cyl(st, 2.0, 0.12, Vector3(14.4, 0.25, -6.8), red)
	_cyl(st, 0.12, 1.0, Vector3(14.4, 0.7, -6.8), Kit.mat(Color("8a8a8e"), 0.4, 0.7))
	for k in range(4):
		var a := k * PI / 2
		_b(st, Vector3(1.8, 0.05, 0.05), Vector3(14.4, 1.0, -6.8), yel, Vector3(0, a, 0))
	circles.append(Vector3(14.4, -6.8, 1.0))
	_cyl(st, 0.1, 0.5, Vector3(8.4, 0.25, -10.8), Kit.mat(Color("6a6a6e"), 0.4, 0.7))
	_b(st, Vector3(0.3, 0.4, 0.9), Vector3(8.4, 0.7, -10.8), grn)
	Kit.part(st, SPH, grn, Vector3(0.36, 0.4, 0.4), Vector3(8.4, 1.05, -10.42))
	# sandbox with the mushroom
	_b(st, Vector3(3.2, 0.3, 3.2), Vector3(13.5, 0.15, 2), tmat("t_wood", 1.0, 0.85, Color(0.85, 0.55, 0.35)))
	_b(st, Vector3(2.8, 0.31, 2.8), Vector3(13.5, 0.16, 2), tmat("t_sand", 0.6, 1.0))
	_cyl(st, 0.14, 2.2, Vector3(15.6, 1.1, 3.8), Kit.mat(Color("f4f0e6"), 0.6))
	var cone := CylinderMesh.new()
	cone.top_radius = 0.05
	cone.bottom_radius = 1.0
	cone.height = 0.7
	cone.rings = 0
	cone.radial_segments = 12
	Kit.part(st, cone, red, Vector3.ONE, Vector3(15.6, 2.4, 3.8))
	for k in range(7):
		var a := k * 0.9
		Kit.part(st, SPH, Kit.mat(Color("f4f0e6"), 0.6), Vector3.ONE * 0.16, Vector3(15.6 + cos(a) * 0.6, 2.32, 3.8 + sin(a) * 0.6))
	circles.append(Vector3(15.6, 3.8, 0.25))
	# a bucket and a spade left in the sand
	_cyl(st, 0.2, 0.2, Vector3(13.0, 0.42, 1.6), Kit.mat(Color("2a8ad8"), 0.5))

	# ---------------------------------------------------------- benches and the kiosk (old spots)
	for z in [-2.0, -8.0]:
		bench(st, Vector3(-6.9, 0, z), PI / 2, rects)
	var k := Node3D.new()
	k.position = Vector3(-11, 0, -15)
	k.rotation.y = 0.5
	st.add_child(k)
	_b(k, Vector3(3, 2.6, 2.4), Vector3(0, 1.3, 0), Kit.mat(Color("ece4d4"), 0.6))
	_b(k, Vector3(3.3, 0.5, 2.7), Vector3(0, 2.8, 0), Kit.mat(Color("d8423c"), 0.5))
	_b(k, Vector3(1.8, 1.0, 0.05), Vector3(0, 1.5, 1.21), Kit.mat(Color("ffcf7a"), 0.3, 0.0, Color("ffcf7a"), 1.2))
	_b(k, Vector3(3.3, 0.08, 0.6), Vector3(0, 1.0, 1.45), Kit.mat(Color("b8b0a0"), 0.6))
	var kl := Chars.label(root, "ШАУРМА", 90, Color(4, 3.5, 2.6), Vector3.ZERO, Vector3.ZERO, 0.007, 10)
	kl.position = k.position + Vector3(sin(0.5), 0, cos(0.5)) * 1.37 + Vector3(0, 2.8, 0)
	kl.rotation.y = 0.5
	circles.append(Vector3(-11, -15, 1.9))
	# carpet-beating rack and a notice board by the benches
	var iron := Kit.mat(Color("4a5a6a"), 0.5, 0.5)
	for s in [-1, 1]:
		_cyl(st, 0.08, 2.2, Vector3(-12.0 + s * 1.2, 1.1, -1.5), iron)
	_cyl(st, 0.07, 2.5, Vector3(-12.0, 1.9, -1.5), iron, Vector3(0, 0, PI / 2))
	_b(st, Vector3(2.3, 0.02, 1.1), Vector3(-12.0, 1.35, -1.5), Kit.mat(Color("a83a3a"), 0.95), Vector3(PI / 2, 0, 0))
	circles.append(Vector3(-13.2, -1.5, 0.2))
	circles.append(Vector3(-10.8, -1.5, 0.2))
	_b(st, Vector3(1.4, 1.0, 0.08), Vector3(-7.4, 1.4, -11.5), Kit.mat(Color("6a4a32"), 0.8), Vector3(0, PI / 2, 0))
	for j in range(5):
		_b(st, Vector3(0.22, 0.28, 0.01), Vector3(-7.35, 1.2 + (j % 2) * 0.32, -11.9 + j * 0.2), Kit.mat(Color("f4f2ea").darkened(j * 0.04), 0.9), Vector3(0, PI / 2, rng.randf_range(-0.1, 0.1)))
	_cyl(st, 0.08, 1.6, Vector3(-7.4, 0.8, -12.1), iron)
	_cyl(st, 0.08, 1.6, Vector3(-7.4, 0.8, -10.9), iron)

	# ---------------------------------------------------------- lamps
	for z in [6.0, -6.0, -18.0, 18.0]:
		lamp(st, Vector3(-6.4, 0, z), 0.0)
		lamp(st, Vector3(6.4, 0, z), PI)
		circles.append(Vector3(-6.4, z, 0.25))
		circles.append(Vector3(6.4, z, 0.25))
	for x in [-24.0, -12.0, 12.0, 24.0]:
		lamp(st, Vector3(x, 0, -19.9), PI / 2 * -1.0)
		circles.append(Vector3(x, -19.9, 0.25))

	# ---------------------------------------------------------- west: trash pen, hockey box, gate, parking, «ракушки»
	var pen := tmat("t_concrete", 0.5, 0.95, Color(0.8, 0.78, 0.75))
	_b(st, Vector3(7.0, 1.6, 0.15), Vector3(-27.5, 0.8, -19.5), pen)
	_b(st, Vector3(0.15, 1.6, 5.0), Vector3(-31.0, 0.8, -17.0), pen)
	var cont := Kit.mat(Color("2f6a3a"), 0.55, 0.3)
	for j in range(4):
		var cx := -29.6 + j * 1.6
		_b(st, Vector3(1.3, 1.25, 1.1), Vector3(cx, 0.75, -18.4), cont if j != 2 else Kit.mat(Color("2a5a8a"), 0.55, 0.3))
		_b(st, Vector3(1.36, 0.1, 1.16), Vector3(cx, 1.42, -18.45), Kit.mat(Color("2a2a2a"), 0.6), Vector3(-0.08, 0, 0))
		for s in [-1, 1]:
			_cyl(st, 0.16, 0.06, Vector3(cx + s * 0.45, 0.1, -17.9), Kit.mat(Color("1a1a1a")), Vector3(PI / 2, 0, 0))
	rects.append(Rect2(-30.4, -19.1, 6.4, 1.4))
	for j in range(5):
		Kit.part(st, SPH, Kit.mat(Color("1a1a1e").lightened(j * 0.05), 0.4), Vector3(0.55, 0.5, 0.5), Vector3(-25.0 + j * 0.35, 0.25, -17.3 + (j % 2) * 0.4))
	# the old sofa left by the bins
	var sofa := Kit.mat(Color("7a4a5a"), 0.95)
	_b(st, Vector3(1.9, 0.45, 0.85), Vector3(-26.6, 0.3, -15.6), sofa, Vector3(0, 0.2, 0))
	_b(st, Vector3(1.9, 0.7, 0.25), Vector3(-26.68, 0.75, -15.98), sofa, Vector3(0, 0.2, 0))
	circles.append(Vector3(-26.6, -15.6, 0.9))
	# hockey box
	var box := Rect2(-30.6, -12.4, 10.0, 16.4)
	ground(st, box, gmat("t_asphalt", 0.25, 0.92, Color(0.82, 0.86, 0.9)), 0.006)
	var board := tmat("t_wood", 0.8, 0.85, Color(0.9, 0.95, 1.0))
	var boardc := Kit.mat(Color("2a6ab8"), 0.6)
	var bx0 := box.position.x
	var bz0 := box.position.y
	_b(st, Vector3(box.size.x, 1.1, 0.12), Vector3(box.get_center().x, 0.55, bz0), board)
	_b(st, Vector3(box.size.x, 1.1, 0.12), Vector3(box.get_center().x, 0.55, box.end.y), board)
	_b(st, Vector3(0.12, 1.1, box.size.y), Vector3(bx0, 0.55, box.get_center().y), board)
	_b(st, Vector3(0.12, 1.1, 6.6), Vector3(box.end.x, 0.55, bz0 + 3.3), board)
	_b(st, Vector3(0.12, 1.1, 6.6), Vector3(box.end.x, 0.55, box.end.y - 3.3), board)
	_b(st, Vector3(box.size.x, 0.16, 0.14), Vector3(box.get_center().x, 1.12, bz0), boardc)
	_b(st, Vector3(box.size.x, 0.16, 0.14), Vector3(box.get_center().x, 1.12, box.end.y), boardc)
	_b(st, Vector3(0.14, 0.16, box.size.y), Vector3(bx0, 1.12, box.get_center().y), boardc)
	rects.append(Rect2(bx0 - 0.1, bz0 - 0.1, box.size.x + 0.2, 0.25))
	rects.append(Rect2(bx0 - 0.1, box.end.y - 0.15, box.size.x + 0.2, 0.25))
	rects.append(Rect2(bx0 - 0.15, bz0, 0.25, box.size.y))
	rects.append(Rect2(box.end.x - 0.12, bz0, 0.25, 6.6))
	rects.append(Rect2(box.end.x - 0.12, box.end.y - 6.6, 0.25, 6.6))
	for z in [bz0 + 1.2, box.end.y - 1.2]:
		var goal := Node3D.new()
		goal.position = Vector3(box.get_center().x, 0, z)
		goal.rotation.y = 0.0 if z < 0 else PI
		st.add_child(goal)
		var gw := Kit.mat(Color("e83a3a"), 0.5, 0.3)
		for s in [-1, 1]:
			_cyl(goal, 0.08, 1.2, Vector3(s * 0.9, 0.6, 0), gw)
		_cyl(goal, 0.08, 1.9, Vector3(0, 1.2, 0), gw, Vector3(0, 0, PI / 2))
		_b(goal, Vector3(1.8, 1.1, 0.02), Vector3(0, 0.6, -0.5), Kit.mat(Color("e8e8e8"), 0.9), Vector3(0.4, 0, 0))
	for j in range(3):
		_b(st, Vector3(box.size.x - 0.4, 0.008, 0.08), Vector3(box.get_center().x, 0.035, bz0 + box.size.y * (j + 1) / 4.0), Kit.mat(Color("d83a3a") if j == 1 else Color("3a6ad8"), 0.7))
	# west gate: a passage to the tram stop between the houses
	var tram := Node3D.new()
	tram.position = Vector3(-40.0, 0, 9.0)
	st.add_child(tram)
	ground(tram, Rect2(-8.0, -4.5, 16.0, 9.0), asphalt, 0.0)
	for s in [-1, 1]:
		_b(tram, Vector3(0.12, 0.06, 9.0), Vector3(-2.0 + s * 0.75, 0.03, 0), Kit.mat(Color("8a8a8e"), 0.3, 0.9))
	_cyl(tram, 0.12, 3.0, Vector3(3.6, 1.5, -3.0), Kit.mat(Color("3a3e44"), 0.5, 0.5))
	_b(tram, Vector3(0.7, 0.7, 0.06), Vector3(3.6, 2.7, -2.96), Kit.mat(Color("f4f2ea"), 0.5))
	_b(tram, Vector3(0.5, 0.5, 0.07), Vector3(3.6, 2.7, -2.92), Kit.mat(Color("d8423c"), 0.5))
	# parking along the west house
	var cars := [Color("e8e4dc"), Color("8a2a2a"), Color("3a5a8a"), Color("c8b890"), Color("2a5a3a"), Color("6a6a70"), Color("e8a83a")]
	var ci := 0
	for z in [14.4, 17.2, 20.0, 22.6]:
		car(st, Vector3(-28.4, 0, z), PI / 2 if ci % 2 == 0 else -PI / 2, cars[ci % cars.size()], ci % 3, rects)
		ci += 1
	for r in [Rect2(-18.5, 19.4, 11.0, 4.1), Rect2(7.5, 19.4, 11.0, 4.1)]:
		for j in range(4):
			if rng.randf() < 0.75:
				car(st, Vector3(r.position.x + 1.6 + j * 2.6, 0, r.get_center().y), PI if (j + ci) % 2 == 0 else 0.0, cars[ci % cars.size()], (ci + j) % 3, rects)
				ci += 1
	# «ракушки»: shell garages by the parking
	var shell := Kit.mat(Color("8a9aa0"), 0.45, 0.6)
	for j in range(3):
		var sz := 14.5 + j * 2.9
		var sh := Node3D.new()
		sh.position = Vector3(-22.6, 0, sz)
		st.add_child(sh)
		var half := CylinderMesh.new()
		half.top_radius = 1.25
		half.bottom_radius = 1.25
		half.height = 4.6
		half.radial_segments = 12
		half.rings = 0
		Kit.part(sh, half, shell if j != 1 else Kit.mat(Color("6a8a6a"), 0.45, 0.6), Vector3(1.0, 1.0, 1.0), Vector3(0, 0.55, 0), Vector3(0, 0, PI / 2))
		_b(sh, Vector3(4.7, 0.6, 2.6), Vector3(0, 0.3 - 0.3, 0), Kit.mat(Color("5a5a5e"), 0.9))
		rects.append(Rect2(-25.0, sz - 1.3, 4.8, 2.6))

	# ---------------------------------------------------------- east: drying lines, flower beds with tyre swans, the lawn
	var pole := Kit.mat(Color("6a7a8a"), 0.45, 0.5)
	var cloth_cols := [Color("f4f4f0"), Color("e86a8a"), Color("6ab0e8"), Color("f2d24a"), Color("8ad86a"), Color("f4f4f0"), Color("e8e0f8")]
	for zp in [-18.5, -11.5]:
		for xp in [21.5, 29.5]:
			_cyl(st, 0.1, 2.4, Vector3(xp, 1.2, zp), pole)
			_cyl(st, 0.08, 1.8, Vector3(xp, 2.3, zp), pole, Vector3(PI / 2, 0, 0))
			circles.append(Vector3(xp, zp, 0.2))
	var cloth := SurfaceTool.new()
	cloth.begin(Mesh.PRIMITIVE_TRIANGLES)
	for line in range(4):
		var zl := -18.5 + 7.0 * (line / 2) + (-0.7 if line % 2 == 0 else 0.7)
		var zz := zl if line < 2 else zl
		_b(st, Vector3(8.0, 0.02, 0.02), Vector3(25.5, 2.26, zz), Kit.mat(Color("d8d4c8"), 0.8))
		var x := 22.0
		while x < 29.0:
			var w := rng.randf_range(0.5, 1.4)
			var hh := rng.randf_range(0.5, 1.2)
			var col: Color = cloth_cols[rng.randi() % cloth_cols.size()]
			_quad(cloth, Vector3(x, 2.25 - hh, zz), Vector3(w, 0, 0), Vector3(0, hh, 0), Rect2(0, 1, 1, -1), col)
			x += w + rng.randf_range(0.15, 0.5)
	var clm := MeshInstance3D.new()
	clm.mesh = cloth.commit()
	clm.material_override = wind_mat(true)
	st.add_child(clm)
	# flower beds with tyres along the east house
	var tyre := Kit.mat(Color("f4f4f0"), 0.7)
	for j in range(6):
		var tz := -9.0 + j * 1.2
		_torus(st, Kit.mat([Color("f4f4f0"), Color("3a8ad8"), Color("f2c21c")][j % 3], 0.7), 0.32, 0.5, Vector3(29.0, 0.12, tz), Vector3(0, 0, 0))
		Kit.part(st, SPH, Kit.mat([Color("e83a5a"), Color("f2e24a"), Color("c85ae8")][j % 3], 0.7), Vector3(0.5, 0.3, 0.5), Vector3(29.0, 0.2, tz))
	# two tyre swans
	for j in range(2):
		var sw := Node3D.new()
		sw.position = Vector3(27.6, 0, -8.0 + j * 4.0)
		sw.rotation.y = PI / 2 + j * PI
		st.add_child(sw)
		Kit.part(sw, SPH, tyre, Vector3(0.9, 0.5, 0.6), Vector3(0, 0.3, 0))
		_cyl(sw, 0.12, 0.8, Vector3(0, 0.75, 0.32), tyre, Vector3(0.35, 0, 0))
		Kit.part(sw, SPH, tyre, Vector3(0.2, 0.18, 0.28), Vector3(0, 1.15, 0.45))
		Kit.part(sw, SPH, Kit.mat(Color("f28a1c"), 0.6), Vector3(0.08, 0.08, 0.16), Vector3(0, 1.13, 0.62))
		circles.append(Vector3(sw.position.x, sw.position.z, 0.5))
	rects.append(Rect2(28.4, -9.6, 1.2, 7.2))
	# lawn with mini goals (Павлин's pride) and the low arched fence
	for z in [8.6, 21.4]:
		var goal := Node3D.new()
		goal.position = Vector3(25.5, 0, z)
		goal.rotation.y = 0.0 if z > 15 else PI
		st.add_child(goal)
		var gw := Kit.mat(Color("f4f4f0"), 0.5, 0.2)
		for s in [-1, 1]:
			_cyl(goal, 0.08, 1.4, Vector3(s * 1.4, 0.7, 0), gw)
		_cyl(goal, 0.08, 2.9, Vector3(0, 1.4, 0), gw, Vector3(0, 0, PI / 2))
		_b(goal, Vector3(2.8, 1.3, 0.02), Vector3(0, 0.66, 0.55), Kit.mat(Color("d8d8d8"), 0.9), Vector3(-0.35, 0, 0))
		circles.append(Vector3(25.5 - 1.4, z, 0.15))
		circles.append(Vector3(25.5 + 1.4, z, 0.15))
	Kit.part(st, SPH, Kit.mat(Color("f4f4f0"), 0.4), Vector3.ONE * 0.24, Vector3(24.0, 0.12, 15.6))
	_b(st, Vector3(0.08, 0.006, 11.6), Vector3(25.5, 0.004, 15.0), Kit.mat(Color("f4f4f0"), 0.8), Vector3(0, PI / 2, 0))
	for seg in [[Vector3(19.6, 0, 7.4), Vector3(19.6, 0, 13.0)], [Vector3(19.6, 0, 17.0), Vector3(19.6, 0, 22.6)], [Vector3(19.6, 0, 22.6), Vector3(31.0, 0, 22.6)],
			[Vector3(19.6, 0, 7.4), Vector3(23.0, 0, 7.4)], [Vector3(28.0, 0, 7.4), Vector3(31.0, 0, 7.4)]]:
		lawn_fence(st, seg[0], seg[1])

	# ---------------------------------------------------------- south: workout bars, the passage to the river
	var bars := Kit.mat(Color("3a6a9a"), 0.45, 0.5)
	for j in range(3):
		var bx := -16.5 + j * 2.4
		var hgt := 1.6 + j * 0.45
		for s in [-1, 1]:
			_cyl(st, 0.1, hgt, Vector3(bx + s * 0.6, hgt / 2, 15.2), bars)
			circles.append(Vector3(bx + s * 0.6, 15.2, 0.12))
		_cyl(st, 0.05, 1.3, Vector3(bx, hgt, 15.2), Kit.mat(Color("c8c8cc"), 0.3, 0.8), Vector3(0, 0, PI / 2))
	_b(st, Vector3(1.2, 0.5, 2.6), Vector3(-9.6, 0.25, 15.4), tmat("t_wood", 1.0, 0.85))
	ground(st, Rect2(-18.0, 13.6, 10.0, 3.6), gmat("t_rubber", 0.5, 0.95, Color(0.6, 0.8, 0.65)), 0.008)

	# ---------------------------------------------------------- greenery: birches (the yard's name), round trees, bushes
	var bpos := [Vector3(-9, 0, -4), Vector3(9, 0, -16), Vector3(-9.5, 0, 4), Vector3(9.5, 0, 6), Vector3(-14, 0, -22),
		Vector3(15, 0, -11), Vector3(-16, 0, -9), Vector3(16, 0, 12), Vector3(-16, 0, 13), Vector3(11, 0, -25), Vector3(-3, 0, -26)]
	for i in range(bpos.size()):
		var p: Vector3 = bpos[i]
		if i % 3 == 2:
			round_tree(st, p, rng.randf_range(0.9, 1.15), 100 + i, circles, 0.25 if i == 5 else 0.0)
		else:
			birch(st, p, rng.randf_range(0.95, 1.2), 100 + i, circles)
	var extra := [Vector3(-19.0, 0, -6.0), Vector3(-19.0, 0, 1.0), Vector3(-24.0, 0, 8.0), Vector3(-19.5, 0, 22.0), Vector3(-8.0, 0, 21.0),
		Vector3(8.0, 0, 18.0), Vector3(19.0, 0, 4.0), Vector3(20.5, 0, -6.0), Vector3(31.0, 0, -14.0), Vector3(30.5, 0, 12.0), Vector3(30.5, 0, 25.5),
		Vector3(-30.6, 0, 6.0), Vector3(-30.0, 0, -23.0), Vector3(25.0, 0, -24.5), Vector3(-19.0, 0, -17.0), Vector3(19.2, 0, -16.0)]
	for i in range(extra.size()):
		var p: Vector3 = extra[i]
		if i % 4 == 1:
			round_tree(st, p, rng.randf_range(0.95, 1.25), 200 + i, circles, 0.4 if i == 9 else 0.0)
		else:
			birch(st, p, rng.randf_range(1.0, 1.3), 200 + i, circles)
	var bushes := [Vector3(-33.0, 0, -2.0), Vector3(-33.0, 0, 2.0), Vector3(-33.0, 0, 17.0), Vector3(33.0, 0, -22.0), Vector3(33.0, 0, 14.0),
		Vector3(-7.4, 0, 2.4), Vector3(-7.4, 0, -14.2), Vector3(7.2, 0, 10.5), Vector3(7.2, 0, -16.0), Vector3(-20.0, 0, 18.0), Vector3(18.6, 0, 18.0),
		Vector3(-12.0, 0, 21.0), Vector3(12.0, 0, 21.6), Vector3(33.0, 0, 6.0), Vector3(-33.0, 0, -15.0)]
	for i in range(bushes.size()):
		var p: Vector3 = bushes[i]
		bush(st, p, rng.randf_range(0.9, 1.3), 300 + i, [Color("e86aa8"), Color(0, 0, 0, 0), Color("f4f0e0")][i % 3])
		circles.append(Vector3(p.x, p.z, 0.6))

	Kit.bake_static(st, 32.0)
	Kit.bake_static(gr, 64.0)
	var life := ambient(root, seats)
	for ch in gr.get_children():
		if ch is GeometryInstance3D:
			ch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return {"root": root, "ambient": life, "rects": rects, "circles": circles, "id": "yard", "name": "Двор «Берёзки»", "bounds": BOUNDS,
		"map_rects": [Rect2(-6, -31, 12, 54), Rect2(-32.5, -27.6, 65, 7), Rect2(13.5, -36, 4.2, 8), Rect2(-32.5, 23.5, 65, 6),
			Rect2(-31.4, 6.5, 25.4, 5), Rect2(6, -0.5, 25.4, 5), Rect2(-31.4, 13, 6, 10.5)],
		"spawns": {"start": [Vector3(0, 0, 12), PI], "from_garages": [Vector3(15.6, 0, -25.6), 0.0], "respawn": [Vector3(-3.6, 0, -4.2), PI / 2],
			"from_embankment": [World.gate("river") + Vector3(0, 0, -2.6), PI]},
		"portals": [{"pos": Vector3(15.6, 0, -28.4), "r": 1.3, "to": "garages", "spawn": "from_yard", "label": "ГК «Песня»"}],
		"npcs": [{"id": "zina", "pos": Vector3(-5.9, 0, -5.0), "rot": PI / 2}, {"id": "misha", "pos": Vector3(4.6, 0, 13.6), "rot": PI + 0.4},
			{"id": "lyuba", "pos": Vector3(-9.7, 0, -13.1), "rot": 0.5}],
		"mobs": [["pigeon", Vector3(3, 0, -6), 2], ["pigeon", Vector3(-2, 0, -11), 3], ["pigeon", Vector3(6, 0, -14), 4], ["pigeon", Vector3(-7, 0, -21), 2],
			["pigeon", Vector3(2, 0, -19), 3], ["pigeon", Vector3(-13, 0, 3), 4], ["pigeon", Vector3(11, 0, 6.5), 2],
			["scooter", Vector3(2, 0, 0), 3], ["scooter", Vector3(-3, 0, -22), 4], ["scooter", Vector3(9, 0, 3), 5],
			["vacuum", Vector3(-15, 0, -21), 5], ["vacuum", Vector3(15, 0, -6), 6],
			# the new corners of the bigger yard
			["pigeon", Vector3(-24.5, 0, -14.0), 3], ["pigeon", Vector3(-22.0, 0, -16.5), 4], ["pigeon", Vector3(24.0, 0, 13.0), 3],
			["pigeon", Vector3(22.0, 0, -14.5), 2], ["scooter", Vector3(-12.0, 0, 26.0), 4], ["scooter", Vector3(14.0, 0, 26.5), 5],
			["vacuum", Vector3(-26.0, 0, -4.0), 6], ["vacuum", Vector3(26.0, 0, 1.5), 5]]}
