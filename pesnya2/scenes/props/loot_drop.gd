class_name LootDrop
extends Node3D
## Добыча на земле, как в Torchlight: вылетает из врага или ящика, светится лучом цвета
## редкости, подписана и подбирается, когда герой проходит рядом. Бабки — кучкой монет.

const PICK_RADIUS := 1.4
const BEAM := {"common": Color(0.95, 0.95, 0.9), "uncommon": Color(0.35, 1, 0.45), "rare": Color(0.35, 0.65, 1),
		"epic": Color(0.85, 0.4, 1), "babki": Color(1, 0.8, 0.2)}

var item_id := ""
var babki := 0
var _key := ""
var _ready_at := 0.0
var _t := 0.0


## Бросает добычу из точки from в случайную сторону. key — ключ однократного начисления.
static func drop(world: Node, from: Vector3, key: String, item := "", money := 0) -> LootDrop:
	var d := LootDrop.new()
	d.item_id = item
	d.babki = money
	d._key = key
	world.add_child(d)
	var to := from + Vector3(randf_range(-1.6, 1.6), 0, randf_range(-1.6, 1.6))
	to.y = 0.0
	d.global_position = from
	var tw := d.create_tween()
	tw.tween_property(d, "global_position:x", to.x, 0.45)
	tw.parallel().tween_property(d, "global_position:z", to.z, 0.45)
	tw.parallel().tween_property(d, "global_position:y", from.y + 1.2, 0.2).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(d, "global_position:y", 0.0, 0.25).set_ease(Tween.EASE_IN)
	return d


func _ready() -> void:
	add_to_group("loot")
	_ready_at = 0.6
	var rarity: String = "babki" if item_id == "" else GameData.item_by_id.get(item_id, {}).get("rarity", "common")
	var col: Color = BEAM.get(rarity, Color.WHITE)
	if item_id == "":
		for i in mini(6, 2 + babki / 8):
			Kit.cylinder(self, 0.12, 0.04, Vector3(randf_range(-0.15, 0.15), 0.03 + i * 0.045, randf_range(-0.15, 0.15)),
					Color(1, 0.8, 0.2), 0.8)
	else:
		Kit.box(self, Vector3(0.35, 0.22, 0.35), Vector3(0, 0.15, 0), col.darkened(0.3), 0.6)
	var beam := Kit.cylinder(self, 0.08 if item_id == "" else 0.14, 2.6, Vector3(0, 1.3, 0), Color(col, 0.35), 2.0)
	beam.material_override = Kit.mat(Color(col, 0.35), 2.0)
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var text := "%d бабок" % babki if item_id == "" else GameData.item_name(item_id)
	var l := Kit.label(self, text, Vector3(0, 0.75, 0), 30, col.lightened(0.3))
	l.no_depth_test = true


func _physics_process(delta: float) -> void:
	_t += delta
	if _t < _ready_at:
		return
	var p := get_tree().get_first_node_in_group("player") as Node3D
	if p and (p.global_position * Vector3(1, 0, 1)).distance_to(global_position * Vector3(1, 0, 1)) < PICK_RADIUS:
		pick()


func pick() -> void:
	var delta := {}
	if babki > 0:
		delta.babki = babki
	if item_id != "":
		delta.items = {item_id: 1}
	GameState.grant(_key, "Добыча", delta)
	AbilityFx.pop(get_parent(), global_position + Vector3(0, 1.4, 0),
			"+%d" % babki if item_id == "" else GameData.item_name(item_id), Color(1, 0.85, 0.3), 36)
	queue_free()
