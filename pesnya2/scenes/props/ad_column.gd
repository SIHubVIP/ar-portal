class_name AdColumn
extends StaticBody3D
## Рекламная тумба на арене Люси (0.16): укрытие от атак босса. Каждый закрытый выстрел
## срывает плакат, третий валит тумбу — она разлетается на барабаны с настоящей физикой.
## После сброса боя тумба встаёт заново.

signal broken(c: AdColumn)

const RADIUS := 0.95
const HEIGHT := 3.4
const MAX_HP := 3
const POSTERS := [["ЛАЙК = НАЛОГ", Color(0.95, 0.25, 0.3)], ["СТРИМ ЗАПРЕЩЁН", Color(0.2, 0.55, 0.95)],
		["ЛЮСЯ: 0 ДИЗЛАЙКОВ", Color(0.98, 0.78, 0.2)], ["ОТПИШИСЬ СЕГОДНЯ", Color(0.55, 0.85, 0.35)],
		["РЕКЛАМА СПАСЕНИЯ", Color(0.85, 0.4, 0.95)], ["ГРОМКОСТЬ: НОЛЬ", Color(0.95, 0.55, 0.2)]]

var hp := MAX_HP
var seed_ := 0
var _visual: Node3D
var _panels: Array = []
var _shape: CollisionShape3D


func _ready() -> void:
	add_to_group("boss_cover")
	collision_layer = 1
	_shape = CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = RADIUS
	cs.height = HEIGHT
	_shape.shape = cs
	_shape.position.y = HEIGHT * 0.5
	add_child(_shape)
	_build()


func is_standing() -> bool:
	return hp > 0


func _build() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	_panels.clear()
	Kit.cylinder(_visual, RADIUS + 0.12, 0.35, Vector3(0, 0.17, 0), Color(0.3, 0.3, 0.32))
	Kit.cylinder(_visual, RADIUS, HEIGHT - 0.6, Vector3(0, HEIGHT * 0.5 - 0.05, 0), Color(0.86, 0.82, 0.72))
	Kit.cylinder(_visual, RADIUS + 0.1, 0.12, Vector3(0, HEIGHT - 0.3, 0), Color(0.18, 0.32, 0.25))
	Kit.cylinder(_visual, 0.25, 0.5, Vector3(0, HEIGHT - 0.05, 0), Color(0.18, 0.32, 0.25), 0.0, RADIUS + 0.1)
	Kit.sphere(_visual, 0.16, Vector3(0, HEIGHT + 0.25, 0), Color(1, 0.85, 0.5), 3.0)
	# четыре плаката по кругу; каждый закрытый выстрел срывает один
	for i in 4:
		var p: Array = POSTERS[(seed_ + i) % POSTERS.size()]
		var a := TAU * i / 4.0 + seed_ * 0.4
		var holder := Node3D.new()
		holder.position = Vector3(sin(a) * (RADIUS + 0.03), 1.55, cos(a) * (RADIUS + 0.03))
		holder.rotation.y = a
		_visual.add_child(holder)
		Kit.box(holder, Vector3(0.95, 1.5, 0.04), Vector3.ZERO, p[1], 0.35)
		var l := Kit.label(holder, String(p[0]).replace(" ", "\n"), Vector3(0, 0, 0.03), 26, Color(0.08, 0.06, 0.08), false)
		l.outline_size = 0
		_panels.append(holder)


## Удар по тумбе. from — откуда летело: туда же и падает.
func take_cover_hit(from: Vector3) -> void:
	if hp <= 0:
		return
	hp -= 1
	if not _panels.is_empty():
		var torn: Node3D = _panels.pop_back()
		var tw := torn.create_tween()
		tw.tween_property(torn, "position:y", 0.1, 0.5).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(torn, "rotation:x", 1.4, 0.5)
		tw.tween_interval(1.5)
		tw.tween_callback(torn.queue_free)
	AbilityFx.sparks(get_parent(), global_position + Vector3(0, 1.6, 0), Color(1, 0.85, 0.5), 6)
	var lean := (global_position - from) * Vector3(1, 0, 1)
	_visual.rotation = Vector3(lean.normalized().z, 0, -lean.normalized().x) * 0.06 * (MAX_HP - hp)
	if hp <= 0:
		_collapse(from)


func _collapse(from: Vector3) -> void:
	_shape.set_deferred("disabled", true)
	_visual.queue_free()
	_visual = null
	var away := ((global_position - from) * Vector3(1, 0, 1)).normalized()
	var world := get_parent() as Node3D
	# барабаны тумбы и крышка: настоящие тела, катятся и бьются друг о друга
	for i in 4:
		var drum := RigidBody3D.new()
		drum.mass = 8.0
		drum.collision_layer = 1
		drum.collision_mask = 1
		drum.set_meta("map_skip", true)
		var sh := CollisionShape3D.new()
		var cs := CylinderShape3D.new()
		cs.radius = RADIUS * 0.85
		cs.height = 0.7
		sh.shape = cs
		drum.add_child(sh)
		Kit.cylinder(drum, RADIUS * 0.85, 0.7, Vector3.ZERO, Color(0.86, 0.82, 0.72) if i < 3 else Color(0.18, 0.32, 0.25))
		drum.position = global_position + Vector3(0, 0.45 + i * 0.75, 0)
		world.add_child(drum)
		drum.apply_central_impulse((away * (3.0 + i * 1.5) + Vector3(randf_range(-1, 1), 1.0, randf_range(-1, 1))) * drum.mass)
		drum.apply_torque_impulse(Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * drum.mass * 2.0)
		var tw := drum.create_tween()
		tw.tween_interval(7.0)
		tw.tween_callback(func() -> void: drum.freeze = true)
		tw.tween_property(drum, "scale", Vector3(1, 0.01, 1), 0.6)
		tw.tween_callback(drum.queue_free)
	var dust := Kit.particles(world, global_position + Vector3(0, 1.0, 0), Color(0.75, 0.72, 0.65), 24, 1.2,
			Vector3(0, 2.5, 0), 1.2, 0.35, Vector3(1.0, 1.5, 1.0))
	dust.one_shot = true
	dust.explosiveness = 0.8
	get_tree().create_timer(2.0).timeout.connect(dust.queue_free)
	PhysProp.blast(get_tree(), global_position, 4.0, 6.0)
	Juice.shake(get_tree(), 0.1)
	broken.emit(self)


## Новый бой — тумба снова стоит целая.
func restore() -> void:
	if hp == MAX_HP and _visual != null:
		return
	hp = MAX_HP
	if _visual != null:
		_visual.queue_free()
	_shape.set_deferred("disabled", false)
	_build()


## Ближайшая целая тумба на отрезке from → to (выстрел упирается в неё) или null.
static func blocker(tree: SceneTree, from: Vector3, to: Vector3, margin := 0.25) -> AdColumn:
	var a := Vector2(from.x, from.z)
	var b := Vector2(to.x, to.z)
	var best: AdColumn = null
	var best_t := INF
	for n in tree.get_nodes_in_group("boss_cover"):
		var c := n as AdColumn
		if not c.is_standing():
			continue
		var p := Vector2(c.global_position.x, c.global_position.z)
		var ab := b - a
		var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		if t <= 0.0 or t >= 1.0:
			continue
		if p.distance_to(a + ab * t) <= RADIUS + margin and t < best_t:
			best_t = t
			best = c
	return best
