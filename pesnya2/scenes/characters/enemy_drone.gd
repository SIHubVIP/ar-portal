class_name EnemyDrone
extends CharacterBody3D
## «Сборщик обязательной благодарности» — патрульный дрон оккупации.
## Каждая атака сначала телеграфирует круг на земле, из него можно уйти.

signal defeated(drone: EnemyDrone)

@export var display_name := "Сборщик благодарности"
@export var max_hp := 40.0
@export var speed := 3.2
@export var aggro_radius := 9.0
@export var attack_radius := 1.8
@export var attack_damage := 10.0
@export var telegraph_time := 0.9
@export var loot_babki := 12

var hp := 40.0
var home := Vector3.ZERO
var _stun_left := 0.0
var _attack_cd := 0.0
var _telegraph: MeshInstance3D
var _telegraph_left := 0.0
var _body: Node3D
var _bar: Label3D
var _t := 0.0


func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp
	home = global_position
	collision_layer = 4
	collision_mask = 1
	var shape := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = 0.6
	shape.shape = s
	shape.position.y = 1.2
	add_child(shape)
	_body = Node3D.new()
	_body.position.y = 1.2
	add_child(_body)
	Kit.sphere(_body, 0.5, Vector3.ZERO, Color(0.75, 0.78, 0.82))
	Kit.cylinder(_body, 0.85, 0.08, Vector3(0, 0, 0), Color(0.3, 0.3, 0.35))
	Kit.sphere(_body, 0.16, Vector3(0, 0.05, 0.42), Color(1, 0.15, 0.3), 3.0)
	Kit.box(_body, Vector3(0.6, 0.12, 0.02), Vector3(0, 0.3, 0.45), Color(0.1, 0.9, 0.5), 1.5)
	_bar = Kit.label(self, "", Vector3(0, 2.4, 0), 40, Color(1, 0.85, 0.85))
	_update_bar()


func is_alive() -> bool:
	return hp > 0.0


func stun(seconds: float) -> void:
	_stun_left = maxf(_stun_left, seconds)
	_cancel_telegraph()


func take_hit(damage: float, from: Vector3) -> void:
	if not is_alive():
		return
	hp -= damage
	var push := (global_position - from) * Vector3(1, 0, 1)
	if push.length() > 0.01:
		global_position += push.normalized() * 0.4
	_body.scale = Vector3(1.25, 0.8, 1.25)
	create_tween().tween_property(_body, "scale", Vector3.ONE, 0.15)
	_update_bar()
	if hp <= 0.0:
		_die()


func _die() -> void:
	_cancel_telegraph()
	remove_from_group("enemies")
	defeated.emit(self)
	var tw := create_tween()
	tw.tween_property(_body, "position:y", 0.2, 0.3)
	tw.parallel().tween_property(_body, "scale", Vector3(1.4, 0.2, 1.4), 0.3)
	tw.tween_callback(queue_free)


func _physics_process(delta: float) -> void:
	_t += delta
	if not is_alive():
		return
	_body.position.y = 1.2 + sin(_t * 3.0) * 0.08
	_body.rotation.y += delta * 0.5
	if _stun_left > 0.0:
		_stun_left -= delta
		_body.rotation.z = sin(_t * 20.0) * 0.3
		return
	_body.rotation.z = 0.0
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null or GameState.hp <= 0.0:
		return
	if _telegraph_left > 0.0:
		_telegraph_left -= delta
		if _telegraph_left <= 0.0:
			_resolve_attack(player)
		return
	_attack_cd -= delta
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	var target := home
	if to_player.length() < aggro_radius and player.controls_enabled:
		target = player.global_position
		if to_player.length() <= attack_radius and _attack_cd <= 0.0:
			_start_telegraph()
			return
	var dir := target - global_position
	dir.y = 0.0
	var stop := attack_radius * 0.6 if target != home else 0.8
	if dir.length() > stop:
		velocity = dir.normalized() * speed
		look_at(global_position + dir, Vector3.UP)
		_body.rotation.y = 0.0
	else:
		velocity = Vector3.ZERO
	move_and_slide()


func _start_telegraph() -> void:
	_telegraph_left = telegraph_time
	_telegraph = Kit.cylinder(get_parent(), attack_radius, 0.04, global_position + Vector3(0, 0.07, 0),
			Color(1, 0.15, 0.1, 0.45))
	_telegraph.material_override = Kit.mat(Color(1, 0.15, 0.1, 0.45), 1.5)
	_telegraph.scale = Vector3(0.2, 1, 0.2)
	_telegraph.create_tween().tween_property(_telegraph, "scale", Vector3.ONE, telegraph_time)


func _resolve_attack(player: Player) -> void:
	var center := _telegraph.global_position if _telegraph else global_position
	_cancel_telegraph()
	_attack_cd = 1.6
	Kit.ring(get_parent(), center, attack_radius, Color(1, 0.3, 0.1), 0.2)
	if (player.global_position * Vector3(1, 0, 1)).distance_to(center * Vector3(1, 0, 1)) <= attack_radius:
		player.take_hit(attack_damage)


func _cancel_telegraph() -> void:
	_telegraph_left = 0.0
	if is_instance_valid(_telegraph):
		_telegraph.queue_free()
	_telegraph = null


func _update_bar() -> void:
	var filled := int(ceil(10.0 * maxf(hp, 0.0) / max_hp))
	_bar.text = "%s\n%s" % [display_name, "▮".repeat(filled) + "▯".repeat(10 - filled)]
