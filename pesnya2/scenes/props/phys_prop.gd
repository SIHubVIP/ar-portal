class_name PhysProp
extends RigidBody3D
## Уличная мелочь с настоящей физикой (0.10): урна, конус, коробка, покрышка. Герой
## расталкивает их на ходу, удар и способности разбрасывают всё, что рядом. Спят, пока их
## не тронули: в покое физика почти ничего не стоит.

const KINDS := {
	"bin": {"mass": 6.0, "size": Vector3(0.6, 0.9, 0.6)},
	"cone": {"mass": 1.5, "size": Vector3(0.45, 0.7, 0.45)},
	"box": {"mass": 2.0, "size": Vector3(0.6, 0.5, 0.5)},
	"tire": {"mass": 4.0, "size": Vector3(0.8, 0.3, 0.8)},
}

var kind := "box"

static var _meshes: Dictionary = {}
static var _phys: PhysicsMaterial


static func make(kind_: String, pos: Vector3, yaw := 0.0) -> PhysProp:
	var p := PhysProp.new()
	p.kind = kind_ if KINDS.has(kind_) else "box"
	p.position = pos
	p.rotation.y = yaw
	return p


## Разбрасывает предметы вокруг точки удара: сила гаснет к краю радиуса, чуть вверх.
static func blast(tree: SceneTree, at: Vector3, radius: float, force: float) -> int:
	var n := 0
	for b in tree.get_nodes_in_group("phys_props"):
		var p := b as PhysProp
		var d := (p.global_position - at) * Vector3(1, 0, 1)
		if d.length() < radius:
			var k := 1.0 - d.length() / radius
			var dir := d.normalized() if d.length() > 0.05 else Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
			p.sleeping = false
			p.apply_central_impulse((dir + Vector3(0, 0.6, 0)) * force * k * p.mass)
			p.apply_torque_impulse(Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * p.mass * 0.4)
			n += 1
	return n


func _ready() -> void:
	add_to_group("phys_props")
	set_meta("map_skip", true)
	var info: Dictionary = KINDS[kind]
	mass = info.mass
	collision_layer = 1
	collision_mask = 1
	can_sleep = true
	sleeping = true
	linear_damp = 0.6
	angular_damp = 1.2
	if _phys == null:
		_phys = PhysicsMaterial.new()
		_phys.friction = 0.8
		_phys.bounce = 0.25
	physics_material_override = _phys
	var size: Vector3 = info.size
	var shape := CollisionShape3D.new()
	match kind:
		"bin", "cone", "tire":
			var cs := CylinderShape3D.new()
			cs.radius = size.x / 2.0
			cs.height = size.y
			shape.shape = cs
		_:
			var bs := BoxShape3D.new()
			bs.size = size
			shape.shape = bs
	shape.position.y = size.y / 2.0
	add_child(shape)
	for part in _parts(kind):
		var mi := MeshInstance3D.new()
		mi.mesh = part[0]
		mi.material_override = part[1]
		mi.position = part[2]
		add_child(mi)


## Сетки и материалы предмета, общие на все экземпляры.
static func _parts(k: String) -> Array:
	if _meshes.has(k):
		return _meshes[k]
	var out: Array = []
	match k:
		"bin":
			var body := CylinderMesh.new()
			body.top_radius = 0.3
			body.bottom_radius = 0.26
			body.height = 0.85
			body.radial_segments = 12
			out.append([body, Kit.mat(Color(0.22, 0.32, 0.26), 0.0, 0.5), Vector3(0, 0.425, 0)])
			var lid := CylinderMesh.new()
			lid.top_radius = 0.22
			lid.bottom_radius = 0.32
			lid.height = 0.08
			lid.radial_segments = 12
			out.append([lid, Kit.mat(Color(0.15, 0.17, 0.16), 0.0, 0.4), Vector3(0, 0.89, 0)])
		"cone":
			var cone := CylinderMesh.new()
			cone.top_radius = 0.03
			cone.bottom_radius = 0.2
			cone.height = 0.66
			cone.radial_segments = 10
			out.append([cone, Kit.mat(Color(1.0, 0.42, 0.08), 0.3, 0.5), Vector3(0, 0.35, 0)])
			var stripe := CylinderMesh.new()
			stripe.top_radius = 0.09
			stripe.bottom_radius = 0.12
			stripe.height = 0.1
			stripe.radial_segments = 10
			out.append([stripe, Kit.mat(Color(0.95, 0.95, 0.95), 0.6, 0.4), Vector3(0, 0.42, 0)])
			var base := BoxMesh.new()
			base.size = Vector3(0.45, 0.04, 0.45)
			out.append([base, Kit.mat(Color(0.1, 0.1, 0.1)), Vector3(0, 0.02, 0)])
		"tire":
			var tor := TorusMesh.new()
			tor.inner_radius = 0.2
			tor.outer_radius = 0.4
			tor.rings = 14
			tor.ring_segments = 8
			out.append([tor, Kit.mat(Color(0.08, 0.08, 0.09), 0.0, 0.7), Vector3(0, 0.15, 0)])
		_:
			var box := BoxMesh.new()
			box.size = Vector3(0.6, 0.5, 0.5)
			out.append([box, Kit.mat(Color(0.6, 0.45, 0.28), 0.0, 0.9), Vector3(0, 0.25, 0)])
			var tape := BoxMesh.new()
			tape.size = Vector3(0.62, 0.02, 0.1)
			out.append([tape, Kit.mat(Color(0.8, 0.7, 0.45), 0.0, 0.5), Vector3(0, 0.505, 0)])
	_meshes[k] = out
	return out
