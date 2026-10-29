class_name Rain
extends Node3D
## Дождь вокруг героя (0.10): эталон мокрый — струи в свете фонарей и брызги на асфальте.
## Две системы частиц ездят за героем; капли не считают столкновений (дёшево), брызги
## появляются на уровне земли сами по себе. Два вызова отрисовки на весь дождь.

const AREA := Vector3(34, 0, 26)
const HEIGHT := 14.0

var target: Node3D
var _drops: GPUParticles3D
var _splash: GPUParticles3D


func _ready() -> void:
	name = "Rain"
	set_meta("map_skip", true)
	_drops = _system(420, 0.75, Vector3(AREA.x / 2.0, 0.5, AREA.z / 2.0), Vector3(0.6, -1, 0.2), 19.0, _streak())
	_drops.position.y = HEIGHT
	_splash = _system(140, 0.28, Vector3(AREA.x / 2.0, 0.02, AREA.z / 2.0), Vector3(0, 1, 0), 1.6, _ring())
	_splash.position.y = 0.06
	(_splash.process_material as ParticleProcessMaterial).gravity = Vector3(0, -6, 0)
	(_splash.process_material as ParticleProcessMaterial).spread = 50.0


func _process(_delta: float) -> void:
	if target != null and is_instance_valid(target):
		global_position = target.global_position * Vector3(1, 0, 1)


func _system(amount: int, life: float, box: Vector3, dir: Vector3, speed: float, mesh: Mesh) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.preprocess = life
	p.local_coords = false
	p.visibility_aabb = AABB(Vector3(-AREA.x, -HEIGHT - 2.0, -AREA.z), Vector3(AREA.x * 2.0, HEIGHT * 2.0 + 4.0, AREA.z * 2.0))
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = box
	m.direction = dir.normalized()
	m.spread = 2.0
	m.initial_velocity_min = speed * 0.85
	m.initial_velocity_max = speed * 1.1
	m.gravity = Vector3.ZERO
	m.particle_flag_align_y = true
	m.scale_min = 0.7
	m.scale_max = 1.2
	p.process_material = m
	p.draw_pass_1 = mesh
	add_child(p)
	return p


## Струя: тонкая вертикальная полоска, вытянутая по скорости (align_y).
static func _streak() -> Mesh:
	var q := QuadMesh.new()
	q.size = Vector2(0.025, 0.7)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(0.55, 0.62, 0.75, 0.55)
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	mat.billboard_keep_scale = true
	mat.disable_receive_shadows = true
	q.material = mat
	return q


## Брызги: маленькое светлое пятнышко у земли.
static func _ring() -> Mesh:
	var q := QuadMesh.new()
	q.size = Vector2(0.12, 0.12)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(0.6, 0.66, 0.78, 0.6)
	mat.albedo_texture = Signboard._halo_texture()
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.disable_receive_shadows = true
	q.material = mat
	return q
