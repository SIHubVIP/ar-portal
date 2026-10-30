class_name Signboard
extends Node3D
## Вывески как на эталоне (0.10): не надпись в воздухе, а предмет на стене.
##   lightbox — световой короб: металлическая рамка, светящееся молочное поле, тёмные буквы;
##   neon     — неон на тёмной подложке: светящиеся буквы с ореолом, трубка по краю, отсвет на стене;
##   letters  — объёмные неоновые буквы прямо на стене (как «РЫНОК СЫТЫЙ КОНЕЦ»);
##   board    — крашеный щит в деревянной рамке, по желанию с лампой на кронштейне;
##   poster   — бумажный плакат, чуть косо приклеенный;
##   chalk    — грифельная доска, буквы мелом;
##   graffiti — надпись баллончиком прямо по стене.
## Лицо вывески смотрит в +Z узла. Размер считается по тексту: высота строки — height_m.

const FONT_BLOCK := preload("res://assets/fonts/Oswald-SemiBold.ttf")
const FONT_NEON := preload("res://assets/fonts/RussoOne-Regular.ttf")
const FONT_HAND := preload("res://assets/fonts/Neucha-Regular.ttf")
const FONT_SCRIPT := preload("res://assets/fonts/MarckScript-Regular.ttf")
const PX := 0.01
const STYLES := ["lightbox", "neon", "letters", "board", "poster", "chalk", "graffiti"]

var style := "lightbox"
var text_size := Vector2.ZERO      # метры: ширина и высота текста
var panel_size := Vector2.ZERO     # метры: щит целиком (для раскладки на фасаде)
var text_node: Label3D
var _solids: Array = []        # [размер, центр, цвет, свечение] — все коробки вывески одной сеткой

const PLAIN_SHADER := preload("res://assets/shaders/plain_color.gdshader")
static var _mats: Dictionary = {}
static var _plain: ShaderMaterial
static var _halo_tex: Texture2D


## opts: bg (цвет поля/щита), ink (цвет букв на коробе), font ("block"|"neon"|"hand"|"script"),
## flicker (bool), lamp (bool, для board), icon ("ufo"), far (м, дальность видимости), tilt (град),
## lean (град): короб наклонён лицом к небу — сверху, с камеры игры, его видно, а не ребро.
static func make(parent: Node, text: String, kind: String, color: Color, pos: Vector3, yaw_deg: float,
		height_m := 0.5, opts := {}) -> Signboard:
	var s := Signboard.new()
	s.style = kind
	s.position = pos
	s.rotation_degrees.y = yaw_deg
	s.rotation_degrees.x = -float(opts.get("lean", 0.0))
	parent.add_child(s)
	s._build(text, color, height_m, opts)
	return s


func _build(text: String, color: Color, height_m: float, opts: Dictionary) -> void:
	var font := _font(String(opts.get("font", _default_font(style))))
	var font_size := maxi(8, int(height_m / PX / 1.2))
	text_size = font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size) * PX
	var w := text_size.x
	var h := text_size.y
	var far := float(opts.get("far", 0.0))
	match style:
		"lightbox":
			var bg: Color = opts.get("bg", Color(1.0, 0.93, 0.78))
			panel_size = Vector2(w + 0.4, h + 0.3)
			_box(Vector3(panel_size.x, panel_size.y, 0.28), Vector3(0, 0, 0.14), _solid(Color(0.09, 0.09, 0.1), 0.0, 0.45))
			_box(Vector3(panel_size.x - 0.12, panel_size.y - 0.12, 0.02), Vector3(0, 0, 0.29), _solid(bg, 1.4, 0.6))
			# потёки ржавчины под коробом: он висит давно
			_box(Vector3(panel_size.x * 0.7, 0.05, 0.02), Vector3(0, -panel_size.y / 2.0 + 0.02, 0.29),
					_solid(Color(0.25, 0.16, 0.1), 0.0, 0.9))
			text_node = _label(text, font, font_size, opts.get("ink", Color(0.12, 0.07, 0.05)), 0.305)
			_halo(Vector2(panel_size.x + 1.4, panel_size.y + 1.2), bg, 0.35)
		"neon", "letters":
			panel_size = Vector2(w + 0.5, h + 0.35)
			if style == "neon":
				_box(Vector3(panel_size.x, panel_size.y, 0.06), Vector3(0, 0, 0.03), _solid(Color(0.05, 0.045, 0.06), 0.0, 0.35))
				_tube_frame(panel_size - Vector2(0.14, 0.14), 0.075, color)
			# мягкое свечение вокруг букв — второй слой текста с широкой полупрозрачной обводкой
			var glow := _label(text, font, font_size, Color(color, 0.0), 0.07)
			glow.outline_size = int(font_size * 0.35)
			glow.outline_modulate = Color(color, 0.35)
			glow.alpha_cut = Label3D.ALPHA_CUT_DISABLED
			text_node = _label(text, font, font_size, Color(color.r * 1.8, color.g * 1.8, color.b * 1.8), 0.08)
			text_node.outline_size = maxi(2, int(font_size * 0.06))
			text_node.outline_modulate = Color(1, 1, 1, 0.9)
			_halo(Vector2(panel_size.x + 2.2, panel_size.y + 1.8), color, 0.55)
			if opts.get("icon", "") == "ufo":
				_ufo_icon(Vector3(-panel_size.x / 2.0 - h * 0.45, 0, 0.12), h * 0.9, color)
			if opts.get("flicker", false):
				_flicker(text_node)
		"board":
			var bg: Color = opts.get("bg", Color(0.92, 0.8, 0.25))
			panel_size = Vector2(w + 0.4, h + 0.3)
			_box(Vector3(panel_size.x, panel_size.y, 0.06), Vector3(0, 0, 0.03), _solid(bg, 0.0, 0.85))
			_frame(panel_size, 0.07, 0.08, _solid(Color(0.3, 0.2, 0.12), 0.0, 0.9))
			text_node = _label(text, font, font_size, color, 0.065)
			if opts.get("lamp", false):
				_lamp(panel_size)
		"poster":
			var bg: Color = opts.get("bg", Color(0.93, 0.9, 0.82))
			panel_size = Vector2(w + 0.3, h + 0.3)
			_box(Vector3(panel_size.x, panel_size.y, 0.01), Vector3(0, 0, 0.01), _solid(bg, 0.0, 0.95))
			text_node = _label(text, font, font_size, color, 0.017)
			rotation_degrees.z = float(opts.get("tilt", randf_range(-4.0, 4.0)))
		"chalk":
			panel_size = Vector2(w + 0.35, h + 0.3)
			_box(Vector3(panel_size.x, panel_size.y, 0.04), Vector3(0, 0, 0.02), _solid(Color(0.1, 0.13, 0.12), 0.0, 0.95))
			_frame(panel_size, 0.06, 0.06, _solid(Color(0.42, 0.28, 0.16), 0.0, 0.9))
			text_node = _label(text, font, font_size, color, 0.045)
		"graffiti":
			panel_size = Vector2(w, h)
			text_node = _label(text, font, font_size, color, 0.02)
			text_node.outline_size = maxi(4, int(font_size * 0.12))
			text_node.outline_modulate = Color(0.05, 0.04, 0.05, 0.85)
			rotation_degrees.z = float(opts.get("tilt", randf_range(-6.0, 6.0)))
	_bake()
	# вывеска плоская: тень от неё не видна, а проход теней удваивает вызовы отрисовки
	for gi in find_children("*", "GeometryInstance3D", true, false):
		(gi as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if far > 0.0:
			(gi as GeometryInstance3D).visibility_range_end = far


static func _default_font(kind: String) -> String:
	match kind:
		"neon", "letters":
			return "neon"
		"chalk", "graffiti":
			return "hand"
	return "block"


static func _font(name_: String) -> Font:
	match name_:
		"neon":
			return FONT_NEON
		"hand":
			return FONT_HAND
		"script":
			return FONT_SCRIPT
	return FONT_BLOCK


func _label(text: String, font: Font, font_size: int, color: Color, z: float) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = font
	l.font_size = font_size
	l.pixel_size = PX
	l.modulate = color
	l.outline_size = 0
	l.double_sided = false
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	l.position.z = z
	l.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(l)
	return l


## Коробка вывески: копится в _solids, в конце _build все коробки — одна сетка (_bake).
func _box(size: Vector3, pos: Vector3, m: StandardMaterial3D, tilt_x := 0.0) -> void:
	var glow := m.emission_energy_multiplier if m.emission_enabled else 0.0
	_solids.append([size, pos, m.albedo_color, glow, tilt_x])


func _bake() -> void:
	if _solids.is_empty():
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var unit := _unit_box()
	var arrays := unit.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for b in _solids:
		var xf := Transform3D(Basis(Vector3.RIGHT, b[4]).scaled(b[0]), b[1])
		var c: Color = b[2]
		c.a = 1.0 - clampf(float(b[3]) / 4.0, 0.0, 1.0)
		for i in idx:
			st.set_color(c)
			st.set_normal((xf.basis * norms[i]).normalized())
			st.add_vertex(xf * verts[i])
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	if _plain == null:
		_plain = ShaderMaterial.new()
		_plain.shader = PLAIN_SHADER
		_plain.set_shader_parameter("roughness_value", 0.55)
	mi.material_override = _plain
	add_child(mi)


func _frame(size: Vector2, thick: float, depth: float, m: Material) -> void:
	for e in [[Vector3(size.x + thick, thick, depth), Vector3(0, size.y / 2.0, depth / 2.0)],
			[Vector3(size.x + thick, thick, depth), Vector3(0, -size.y / 2.0, depth / 2.0)],
			[Vector3(thick, size.y, depth), Vector3(size.x / 2.0, 0, depth / 2.0)],
			[Vector3(thick, size.y, depth), Vector3(-size.x / 2.0, 0, depth / 2.0)]]:
		_box(e[0], e[1], m)


## Неоновая трубка по краю подложки.
func _tube_frame(size: Vector2, z: float, color: Color) -> void:
	var m := _solid(color, 3.5, 0.3)
	for e in [[Vector3(size.x, 0.035, 0.035), Vector3(0, size.y / 2.0, z)], [Vector3(size.x, 0.035, 0.035), Vector3(0, -size.y / 2.0, z)],
			[Vector3(0.035, size.y, 0.035), Vector3(size.x / 2.0, 0, z)], [Vector3(0.035, size.y, 0.035), Vector3(-size.x / 2.0, 0, z)]]:
		_box(e[0], e[1], m)


## Лампа на кронштейне над щитом и конус её света на щите.
func _lamp(size: Vector2) -> void:
	var metal := _solid(Color(0.12, 0.12, 0.13), 0.0, 0.5)
	for sx: float in [-0.3, 0.3]:
		var x := size.x * sx
		_box(Vector3(0.03, 0.03, 0.45), Vector3(x, size.y / 2.0 + 0.12, 0.22), metal)
		_box(Vector3(0.18, 0.08, 0.14), Vector3(x, size.y / 2.0 + 0.1, 0.45), metal, deg_to_rad(-25.0))
		_box(Vector3(0.12, 0.03, 0.08), Vector3(x, size.y / 2.0 + 0.055, 0.45), _solid(Color(1, 0.85, 0.55), 4.0, 0.3))
	_halo(Vector2(size.x * 1.15, size.y * 1.3), Color(1, 0.8, 0.5), 0.45, Vector3(0, 0.1, 0.075))


func _ufo_icon(pos: Vector3, size_m: float, color: Color) -> void:
	var m := _solid(color, 3.0, 0.3)
	var disc := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.5
	sph.height = 1.0
	sph.radial_segments = 16
	sph.rings = 6
	disc.mesh = sph
	disc.material_override = m
	disc.scale = Vector3(size_m, size_m * 0.22, size_m * 0.3)
	disc.position = pos
	add_child(disc)
	var dome := MeshInstance3D.new()
	dome.mesh = sph
	dome.material_override = _solid(Color(0.6, 1.0, 0.9), 2.0, 0.2)
	dome.scale = Vector3(size_m * 0.45, size_m * 0.4, size_m * 0.2)
	dome.position = pos + Vector3(0, size_m * 0.13, 0)
	add_child(dome)


## Отсвет на стене: мягкое пятно цвета вывески (без источника света — дёшево).
func _halo(size: Vector2, color: Color, strength: float, pos := Vector3(0, 0, 0.01)) -> void:
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = size
	q.mesh = qm
	q.position = pos
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var key := "halo|%s|%s" % [color.to_html(), strength]
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.disable_fog = true
		m.albedo_color = Color(color.r * strength, color.g * strength, color.b * strength, 1.0)
		m.albedo_texture = _halo_texture()
		m.disable_receive_shadows = true
		_mats[key] = m
	q.material_override = _mats[key]
	add_child(q)


func _flicker(n: Label3D) -> void:
	var base := n.modulate
	var tw := n.create_tween().set_loops()
	tw.tween_interval(randf_range(2.5, 6.0))
	tw.tween_property(n, "modulate", base * Color(0.3, 0.3, 0.3, 1), 0.04)
	tw.tween_property(n, "modulate", base, 0.05)
	tw.tween_property(n, "modulate", base * Color(0.5, 0.5, 0.5, 1), 0.07)
	tw.tween_property(n, "modulate", base, 0.04)


static func _solid(color: Color, emission: float, roughness: float) -> StandardMaterial3D:
	var key := "s|%s|%s|%s" % [color.to_html(), emission, roughness]
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = roughness
		if emission > 0.0:
			m.emission_enabled = true
			m.emission = color
			m.emission_energy_multiplier = emission
		_mats[key] = m
	return _mats[key]


static var _unit: BoxMesh


static func _unit_box() -> BoxMesh:
	if _unit == null:
		_unit = BoxMesh.new()
	return _unit


static func _halo_texture() -> Texture2D:
	if _halo_tex == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(0.35, 0.35, 0.35, 1), Color(0, 0, 0, 1)])
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 64
		t.height = 64
		_halo_tex = t
	return _halo_tex
