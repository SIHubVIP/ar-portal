class_name Surfaces
extends RefCounted
## Материалы эталона парковки: мокрая брусчатка и кирпич из assets/textures
## (tools/textures/make_textures.py). Мировые трипланарные координаты: одна текстура — 2 × 2 м,
## швы не зависят от размера коробки. Модели Blender с материалом «brick» перекрашиваются тут же.

const TILE_M := 2.0

static var _cache: Dictionary = {}
const GROUND_SHADER := preload("res://assets/shaders/ground.gdshader")


static func cobble() -> StandardMaterial3D:
	return _material("cobble", 1.0)


static func brick() -> StandardMaterial3D:
	return _material("brick", 1.0)


## Район (0.10): мокрый асфальт, плитка тротуаров, земля дворов. tint — оттенок поверх
## текстуры (дорога темнее проезда во дворе), у каждого оттенка свой материал в кэше.
static func asphalt(tint := Color.WHITE) -> StandardMaterial3D:
	return _material("asphalt", 1.0, 4.0, tint)


static func slabs(tint := Color.WHITE) -> StandardMaterial3D:
	return _material("slabs", 1.0, 2.0, tint)


static func dirt(tint := Color.WHITE) -> StandardMaterial3D:
	return _material("dirt", 1.0, 4.0, tint)


static func _material(name: String, normal_scale: float, tile := TILE_M, tint := Color.WHITE) -> StandardMaterial3D:
	var key := "%s|%s" % [name, tint.to_html()]
	if _cache.has(key):
		return _cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://assets/textures/%s_albedo.png" % name)
	m.normal_enabled = true
	m.normal_texture = load("res://assets/textures/%s_normal.png" % name)
	m.normal_scale = normal_scale
	# 0.12: сухой осенний вечер — ровная матовая поверхность; карта шероховатости (мокрые
	# пятна из 0.10) давала россыпь бликов на плитке рынка и площади
	m.metallic_specular = 0.2
	m.roughness = 0.95
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / tile
	m.albedo_color = tint
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_cache[key] = m
	return m


## Земля района без повторов (0.16, assets/shaders/ground.gdshader): только для плоских
## поверхностей — газона кварталов, дорог и дорожек. patch — цвет проплешин, amount — их сила.
static func ground(name: String, tile: float, tint := Color.WHITE, patch := Color.WHITE, amount := 0.0) -> ShaderMaterial:
	var key := "ground:%s|%s|%s|%s" % [name, tint.to_html(), patch.to_html(), amount]
	if _cache.has(key):
		return _cache[key]
	var m := ShaderMaterial.new()
	m.shader = GROUND_SHADER
	m.set_shader_parameter("albedo_tex", load("res://assets/textures/%s_albedo.png" % name))
	m.set_shader_parameter("normal_tex", load("res://assets/textures/%s_normal.png" % name))
	m.set_shader_parameter("tint", tint)
	m.set_shader_parameter("tile", tile)
	m.set_shader_parameter("patch_color", patch)
	m.set_shader_parameter("patch_amount", amount)
	_cache[key] = m
	return m


## Меняет в модели материалы с именем brick на кирпич с текстурой.
static func retexture(root: Node) -> void:
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(i)
			if mat and mat.resource_name == "brick":
				mi.set_surface_override_material(i, brick())


## Все меши под узлом — в кирпич (торцы домов, собранные из коробок).
static func brick_all(root: Node) -> void:
	for n in root.find_children("*", "MeshInstance3D", true, false):
		(n as MeshInstance3D).material_override = brick()
