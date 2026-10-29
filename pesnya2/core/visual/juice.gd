class_name Juice
extends RefCounted
## Ощущение удара: лёгкая тряска камеры, гаснет сама. Стоп-кадр и взрывы убраны по просьбе владельца (D-043).

## Тряска изометрической камеры, amount — метры смещения в начале.
static func shake(tree: SceneTree, amount: float) -> void:
	var cam := tree.get_first_node_in_group("iso_camera")
	if cam and cam.has_method("shake"):
		cam.shake(amount)

