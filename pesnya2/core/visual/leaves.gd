class_name Leaves
extends Node3D
## Листопад вокруг героя (0.11): вместо дождя — тёплый осенний вечер концептов «Рубин».
## Листья медленно кружат и ложатся; одна система частиц ездит за героем, один вызов
## отрисовки. Цвет каждого листа — из градиента золото → медь.

const AREA := Vector3(30, 0, 24)
const HEIGHT := 11.0

var target: Node3D
var _leaves: GPUParticles3D


func _ready() -> void:
	name = "Leaves"
	set_meta("map_skip", true)
	var p := GPUParticles3D.new()
	p.amount = 40          # 0.23: было 90 — на телефоне читалось жёлтым мусором
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.local_coords = false
	p.position.y = HEIGHT
	p.visibility_aabb = AABB(Vector3(-AREA.x, -HEIGHT - 2.0, -AREA.z), Vector3(AREA.x * 2.0, HEIGHT * 2.0 + 4.0, AREA.z * 2.0))
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = Vector3(AREA.x / 2.0, 1.0, AREA.z / 2.0)
	m.direction = Vector3(0.5, -1, 0.2).normalized()
	m.spread = 25.0
	m.initial_velocity_min = 0.6
	m.initial_velocity_max = 1.2
	m.gravity = Vector3(0.35, -1.0, 0.1)
	m.turbulence_enabled = true
	m.turbulence_noise_strength = 1.4
	m.turbulence_noise_scale = 3.0
	m.turbulence_influence_min = 0.08
	m.turbulence_influence_max = 0.2
	m.angular_velocity_min = -180.0
	m.angular_velocity_max = 180.0
	m.angle_min = 0.0
	m.angle_max = 360.0
	m.scale_min = 0.7
	m.scale_max = 1.3
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	g.colors = PackedColorArray([Color(0.86, 0.66, 0.24), Color(0.8, 0.44, 0.16), Color(0.6, 0.24, 0.1)])
	var gt := GradientTexture1D.new()
	gt.gradient = g
	m.color_initial_ramp = gt
	p.process_material = m
	var q := QuadMesh.new()
	q.size = Vector2(0.26, 0.2)
	var mat := StandardMaterial3D.new()
	# форма листа, а не прямоугольник: квадраты на земле выглядели как конфетти
	mat.albedo_texture = leaf_texture()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.disable_receive_shadows = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	q.material = mat
	p.draw_pass_1 = q
	add_child(p)
	_leaves = p


## Лист-лодочка 32 × 32: заострённые концы, белый — цвет даёт частица.
static func leaf_texture() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in 32:
		for x in 32:
			var u := (x - 15.5) / 15.5
			var v := (y - 15.5) / 15.5
			# полуширина листа сужается к концам: 0.55 · (1 − u²)
			var half := 0.55 * (1.0 - u * u)
			var a := 1.0 if absf(v) < half and absf(u) < 0.98 else 0.0
			# прожилка темнее
			var shade := 0.82 if absf(v) < 0.06 and absf(u) < 0.8 else 1.0
			img.set_pixel(x, y, Color(shade, shade, shade, a))
	return ImageTexture.create_from_image(img)


func _process(_delta: float) -> void:
	if target != null and is_instance_valid(target):
		global_position = target.global_position * Vector3(1, 0, 1)
