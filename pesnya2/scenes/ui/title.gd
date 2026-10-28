extends Control
## Титульный экран: новая игра с выбором класса или продолжение сохранения.

var _menu: VBoxContainer
var _classes: HBoxContainer
var _gender := "m"
var _class_id := "CLASS_1"
var _face: Portrait
var _class_info: Label
var _gender_buttons: Dictionary = {}
var _class_buttons: Dictionary = {}
var _logo: TextureRect

const CLASS_PITCH := {
	"CLASS_1": "Решает вопросы руками. Держит удар, держит очередь, держит обиду.",
	"CLASS_2": "Продаст пришельцу его же бластер. В рассрочку. С переплатой.",
	"CLASS_3": "Чинит роутеры словом и матом. Пришельцы для него — новый тариф.",
}


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
	_logo = logo
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

	# создание героя: пол, класс, портрет-превью
	_classes = HBoxContainer.new()
	_classes.alignment = BoxContainer.ALIGNMENT_CENTER
	_classes.add_theme_constant_override("separation", 28)
	_classes.visible = false
	v.add_child(_classes)
	_face = Portrait.new()
	_face.custom_minimum_size = Vector2(220, 270)
	_face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_classes.add_child(_face)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.custom_minimum_size.x = 560
	_classes.add_child(col)
	var gender_row := HBoxContainer.new()
	gender_row.add_theme_constant_override("separation", 10)
	col.add_child(gender_row)
	for g in [["m", "Мужчина"], ["f", "Женщина"]]:
		var b := _button(gender_row, g[1], func(): _pick_gender(g[0]))
		b.custom_minimum_size = Vector2(275, 56)
		b.toggle_mode = true
		_mark_toggle(b)
		_gender_buttons[g[0]] = b
	var class_row := HBoxContainer.new()
	class_row.add_theme_constant_override("separation", 10)
	col.add_child(class_row)
	for c in GameData.classes:
		var b := _button(class_row, c.name, func(): _pick_class(c.id))
		b.custom_minimum_size = Vector2(180, 56)
		b.add_theme_font_size_override("font_size", 20)
		b.toggle_mode = true
		_mark_toggle(b)
		_class_buttons[c.id] = b
	_class_info = _label(col, "", 18, Color(0.85, 0.85, 0.9))
	_class_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_class_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_class_info.custom_minimum_size = Vector2(560, 150)
	var start := _button(col, "Проснуться в Рубине ▸", func(): _new_game(_class_id))
	start.add_theme_color_override("font_color", Color(0.95, 0.75, 0.2))
	_refresh_creation()
	var errors := GameData.validate()
	if not errors.is_empty():
		_label(v, "Ошибка данных: %s" % ", ".join(errors), 16, Color(1, 0.4, 0.4))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--create="):    # скриншоты экрана создания: --create=f
			_show_classes()
			_pick_gender(arg.trim_prefix("--create="))


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


## Выбранная кнопка пола/класса — золотая рамка, чтобы выбор читался с первого взгляда.
static func _mark_toggle(b: Button) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.22, 0.16, 0.06)
	sb.border_color = Color(0.95, 0.75, 0.2)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(6)
	b.add_theme_stylebox_override("pressed", sb)
	b.add_theme_stylebox_override("hover_pressed", sb)
	b.add_theme_color_override("font_pressed_color", Color(1, 0.85, 0.35))
	b.add_theme_color_override("font_hover_pressed_color", Color(1, 0.85, 0.35))


func _show_classes() -> void:
	_menu.visible = false
	_logo.visible = false    # место под портрет героя
	_classes.visible = true


func _pick_gender(g: String) -> void:
	_gender = g
	_refresh_creation()


func _pick_class(id: String) -> void:
	_class_id = id
	_refresh_creation()


func _refresh_creation() -> void:
	for g in _gender_buttons:
		_gender_buttons[g].button_pressed = g == _gender
	for id in _class_buttons:
		_class_buttons[id].button_pressed = id == _class_id
	GameState.class_id = _class_id
	GameState.gender = _gender
	_face.set_spec({"kind": "hero"})
	var lines: PackedStringArray = [CLASS_PITCH.get(_class_id, ""), ""]
	var abl := GameData.class_abilities(_class_id)
	for i in abl.size():
		lines.append("%s  %s" % ["●" if i == 0 else "○", abl[i].name] + ("" if i == 0 else "  — с %d ур." % AbilityBook.unlock_level(i)))
	_class_info.text = "\n".join(lines)


func _new_game(class_id: String) -> void:
	GameState.reset(class_id)
	GameState.gender = _gender
	QuestService.reset()
	GameState.give_starter_kit()
	WorldRouter.go_to_world()


func _continue() -> void:
	if SaveService.load_game():
		var scene := GameState.world_scene if GameState.world_scene != "" else WorldRouter.WORLD
		get_tree().change_scene_to_file(scene)
