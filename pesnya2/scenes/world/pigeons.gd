class_name Pigeons
extends MultiMeshInstance3D
## Голуби (0.10): стайки клюют что-то на тротуаре и во дворе, а когда герой подходит
## ближе SCARE_M — вспархивают и улетают. Все птицы — один MultiMesh (один вызов отрисовки),
## стайка, улетевшая далеко, садится заново где-нибудь рядом с героем.

const FLOCKS := 3
const PER_FLOCK := 6
const SCARE_M := 4.5
const NEAR_M := 9.0
const FAR_M := 22.0

var player: Node3D
var _flocks: Array = []        # {center, birds: [{off, phase, fly}], flying, t}
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	name = "Pigeons"
	set_meta("map_skip", true)
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_rng.randomize()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _bird_mesh()
	mm.instance_count = FLOCKS * PER_FLOCK
	multimesh = mm
	var mat := ShaderMaterial.new()
	mat.shader = Signboard.PLAIN_SHADER
	mat.set_shader_parameter("roughness_value", 0.8)
	material_override = mat
	for i in FLOCKS:
		var birds: Array = []
		for j in PER_FLOCK:
			birds.append({"off": Vector3(_rng.randf_range(-1.6, 1.6), 0, _rng.randf_range(-1.6, 1.6)),
					"phase": _rng.randf() * TAU, "yaw": _rng.randf() * TAU, "fly": Vector3.ZERO})
		_flocks.append({"center": Vector3.INF, "birds": birds, "flying": false, "t": 0.0})


func _physics_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var hero := player.global_position
	var i := 0
	for f in _flocks:
		if f.center == Vector3.INF or (not f.flying and (f.center - hero).length() > FAR_M * 1.6) or \
				(f.flying and f.t > 3.0):
			_land(f, hero)
		if not f.flying and (f.center - hero).length() < SCARE_M:
			f.flying = true
			f.t = 0.0
			var away: Vector3 = ((f.center - hero) * Vector3(1, 0, 1)).normalized()
			for b in f.birds:
				b.fly = (away + Vector3(_rng.randf_range(-0.5, 0.5), 0, _rng.randf_range(-0.5, 0.5))).normalized()
		f.t += delta
		for b in f.birds:
			var pos: Vector3 = f.center + b.off
			var basis := Basis(Vector3.UP, b.yaw)
			if f.flying:
				var k: float = f.t
				pos += b.fly * (k * 7.0) + Vector3(0, k * 3.5 + sin(k * 9.0 + b.phase) * 0.1, 0)
				basis = Basis(Vector3.UP, atan2(b.fly.x, b.fly.z)) * Basis(Vector3.RIGHT, -0.4)
				basis = basis.scaled(Vector3(1.0 + 0.6 * absf(sin(k * 22.0 + b.phase)), 1, 1))   # машет крыльями
			else:
				# клюёт: голова вниз-вверх, иногда поворачивается
				var peck := maxf(0.0, sin(f.t * 5.0 + b.phase))
				basis = basis * Basis(Vector3.RIGHT, peck * 0.6)
				if sin(f.t * 0.7 + b.phase) > 0.98:
					b.yaw += delta * 3.0
			multimesh.set_instance_transform(i, Transform3D(basis, pos))
			i += 1


## Стайка садится на свободное место в NEAR_M…FAR_M от героя.
func _land(f: Dictionary, hero: Vector3) -> void:
	for attempt in 10:
		var a := _rng.randf() * TAU
		var r := _rng.randf_range(NEAR_M, FAR_M)
		var p := hero + Vector3(cos(a) * r, 0, sin(a) * r)
		var plan := District.to_plan(p)
		if District.walkable(plan) or District.start_area().has_point(plan):
			f.center = Vector3(p.x, 0.0, p.z)
			f.flying = false
			f.t = _rng.randf() * 3.0
			return
	f.center = Vector3.INF


## Голубь: серое тельце, тёмная голова, светлое крыло — одна сетка с цветами вершин.
static func _bird_mesh() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_blob(st, Vector3(0, 0.13, 0), Vector3(0.11, 0.09, 0.17), Color(0.5, 0.52, 0.58))
	_blob(st, Vector3(0, 0.22, 0.12), Vector3(0.06, 0.06, 0.06), Color(0.28, 0.3, 0.36))
	_blob(st, Vector3(0, 0.21, 0.18), Vector3(0.015, 0.015, 0.03), Color(0.85, 0.6, 0.3))
	_blob(st, Vector3(0, 0.15, -0.15), Vector3(0.06, 0.025, 0.08), Color(0.35, 0.37, 0.42))
	for sx: float in [-1.0, 1.0]:
		_blob(st, Vector3(sx * 0.09, 0.15, -0.01), Vector3(0.03, 0.05, 0.13), Color(0.66, 0.68, 0.72))
	return st.commit()


static func _blob(st: SurfaceTool, c: Vector3, r: Vector3, col: Color) -> void:
	var sph := SphereMesh.new()
	sph.radial_segments = 8
	sph.rings = 4
	sph.radius = 1.0
	sph.height = 2.0
	var arr := sph.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var nrm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	for idx in (arr[Mesh.ARRAY_INDEX] as PackedInt32Array):
		st.set_color(col)
		st.set_normal(nrm[idx])
		st.add_vertex(c + v[idx] * r)
