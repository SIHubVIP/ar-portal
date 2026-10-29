class_name Juice
extends RefCounted
## Ощущение удара: тряска камеры и короткий стоп-кадр. Всё гаснет само.

static var _stop_until := 0


## Тряска изометрической камеры, amount — метры смещения в начале.
static func shake(tree: SceneTree, amount: float) -> void:
	var cam := tree.get_first_node_in_group("iso_camera")
	if cam and cam.has_method("shake"):
		cam.shake(amount)


## Стоп-кадр: время почти замирает на seconds реальных секунд. Повторный вызов продлевает.
static func hit_stop(tree: SceneTree, seconds := 0.06) -> void:
	_stop_until = maxi(_stop_until, Time.get_ticks_msec() + int(seconds * 1000.0))
	Engine.time_scale = 0.05
	tree.create_timer(seconds, true, false, true).timeout.connect(func() -> void:
		if Time.get_ticks_msec() >= _stop_until - 2:
			Engine.time_scale = 1.0)
