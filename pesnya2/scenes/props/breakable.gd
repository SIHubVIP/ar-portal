class_name Breakable
extends StaticBody3D
## Мусор, который можно разнести: мешки, коробки, ящики с пивом. Стоит в группе enemies,
## поэтому по нему бьют удар и способности, но автоприцел выбирает его после живых врагов.

signal broken(b: Breakable)

var model := "boxes"
var hp := 12.0
var loot_table := "trash"
var is_prop := true
var _key := ""


static func spawn(world: Node, model_name: String, pos: Vector3, yaw := 0.0, key := "") -> Breakable:
	var b := Breakable.new()
	b.model = model_name
	b._key = key if key != "" else "break:%s:%d:%d" % [model_name, roundi(pos.x * 10), roundi(pos.z * 10)]
	b.position = pos
	b.rotation_degrees.y = yaw
	world.add_child(b)
	return b


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 1
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(1.2, 0.9, 1.0)
	shape.shape = bs
	shape.position.y = 0.45
	add_child(shape)
	if Props.place(self, model, Vector3.ZERO) == null:
		Kit.box(self, Vector3(0.8, 0.8, 0.8), Vector3(0, 0.4, 0), Color(0.6, 0.45, 0.3))


func is_alive() -> bool:
	return hp > 0.0


func stun(_seconds: float) -> void:
	pass


func take_hit(damage: float, _from: Vector3) -> void:
	if hp <= 0.0:
		return
	hp -= damage
	scale = Vector3(1.1, 0.85, 1.1)
	create_tween().tween_property(self, "scale", Vector3.ONE, 0.12)
	if hp <= 0.0:
		_break()


func _break() -> void:
	remove_from_group("enemies")
	collision_layer = 0
	var world := get_parent()
	for i in 6:
		var chunk := Kit.box(world, Vector3(0.22, 0.12, 0.2), global_position + Vector3(0, 0.4, 0),
				Color(0.55, 0.42, 0.28) if model == "boxes" else Color(0.08, 0.08, 0.09))
		var dir := Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
		var tw := chunk.create_tween()
		tw.tween_property(chunk, "position", chunk.position + dir * 1.3 + Vector3(0, 0.6, 0), 0.2)
		tw.tween_property(chunk, "position:y", 0.06, 0.25)
		tw.tween_interval(1.5)
		tw.tween_property(chunk, "scale", Vector3.ZERO, 0.4)
		tw.tween_callback(chunk.queue_free)
	if not GameState.granted.has(_key):
		var money := randi_range(2, 9)
		LootDrop.drop(world, global_position + Vector3(0, 0.5, 0), _key + ":babki", "", money)
		if randf() < 0.35:
			var item := GameState.roll_loot(loot_table, randf())
			if item != "":
				LootDrop.drop(world, global_position + Vector3(0, 0.5, 0), _key + ":item", item)
		GameState.granted[_key] = true
	broken.emit(self)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3(1.3, 0.05, 1.3), 0.15)
	tw.tween_callback(queue_free)
