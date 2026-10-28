extends Control
## Титульный экран: новая игра с выбором класса или продолжение сохранения.

var _menu: VBoxContainer
var _classes: HBoxContainer


func _ready() -> void:
	get_tree().paused = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.06, 0.1)
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 18)
	add_child(v)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var logo := TextureRect.new()
	logo.texture = load("res://assets/brand/logo_light.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(0, 110)
	v.add_child(logo)
	var title := _label(v, "ПЕСНЯ", 72, Color(0.95, 0.75, 0.2))
	title.add_theme_font_override("font", load("res://assets/fonts/RussoOne-Regular.ttf"))
	_label(v, "Пришельцы прибыли не в тот город", 26, Color(0.85, 0.85, 0.95))
	_label(v, "Вертикальный срез · версия %s · 18+" % ProjectSettings.get_setting("application/config/version"),
			16, Color(0.6, 0.6, 0.7))

	_menu = VBoxContainer.new()
	_menu.alignment = BoxContainer.ALIGNMENT_CENTER
	_menu.add_theme_constant_override("separation", 12)
	var center := CenterContainer.new()
	center.add_child(_menu)
	v.add_child(center)
	if SaveService.has_save():
		_button(_menu, "Продолжить", _continue)
	_button(_menu, "Новая игра", _show_classes)

	_classes = HBoxContainer.new()
	_classes.alignment = BoxContainer.ALIGNMENT_CENTER
	_classes.add_theme_constant_override("separation", 16)
	_classes.visible = false
	v.add_child(_classes)
	for c in GameData.classes:
		var card := VBoxContainer.new()
		card.custom_minimum_size = Vector2(360, 0)
		_classes.add_child(card)
		_button(card, c.name, func(): _new_game(c.id))
		var names: PackedStringArray = []
		for a in GameData.class_abilities(c.id):
			names.append("• %s (%s)" % [a.name, a.kind])
		var l := _label(card, "\n".join(names), 16, Color(0.8, 0.8, 0.85))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var errors := GameData.validate()
	if not errors.is_empty():
		_label(v, "Ошибка данных: %s" % ", ".join(errors), 16, Color(1, 0.4, 0.4))


func _label(parent: Node, text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


func _button(parent: Node, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(340, 64)
	b.add_theme_font_size_override("font_size", 28)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _show_classes() -> void:
	_menu.visible = false
	_classes.visible = true


func _new_game(class_id: String) -> void:
	GameState.reset(class_id)
	QuestService.reset()
	WorldRouter.go_to_world()


func _continue() -> void:
	if SaveService.load_game():
		var scene := GameState.world_scene if GameState.world_scene != "" else WorldRouter.WORLD
		get_tree().change_scene_to_file(scene)
