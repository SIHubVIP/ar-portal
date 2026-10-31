class_name UiSkin
extends RefCounted
## Единый мультяшный стиль интерфейса (0.20, D-062): тёмно-сливовые панели с кремовым кантом
## и тенью, толстые кнопки «с бортиком», рисованные значки из assets/ui (tools/ui/make_ui_icons.py).
## Тема ставится на корневое окно один раз (WorldRouter), панели берут готовые рамки отсюда.

const INK := Color(0.17, 0.12, 0.2)              # фон панелей
const INK_LIGHT := Color(0.26, 0.2, 0.31)        # карточки на панели
const CREAM := Color(1.0, 0.93, 0.78)            # кант и светлый текст
const TEXT := Color(1.0, 0.96, 0.88)
const TEXT_DIM := Color(0.8, 0.74, 0.7)
const GOLD := Color(1.0, 0.79, 0.24)
const GOLD_DARK := Color(0.72, 0.44, 0.1)
const BROWN := Color(0.23, 0.14, 0.08)           # текст на жёлтой кнопке
const RED := Color(1.0, 0.36, 0.3)
const GREEN := Color(0.45, 0.85, 0.42)
const BLUE := Color(0.44, 0.83, 1.0)
const OUTLINE := Color(0.1, 0.06, 0.08)
const TITLE_FONT := "res://assets/fonts/RussoOne-Regular.ttf"
const ICON_DIR := "res://assets/ui/%s.png"

static var _theme: Theme
static var _icons: Dictionary = {}


static func icon(name: String) -> Texture2D:
	if not _icons.has(name):
		var path := ICON_DIR % name
		_icons[name] = load(path) if ResourceLoader.exists(path) else null
	return _icons[name]


static func title_font() -> Font:
	return load(TITLE_FONT)


## Большая панель окна: сумка, задания, карта, пауза.
static func panel(margin := 18.0, alpha := 0.97) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(INK, alpha)
	sb.border_color = CREAM
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(22)
	sb.set_content_margin_all(margin)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 6)
	sb.anti_aliasing = true
	return sb


## Карточка внутри панели или плашка поверх мира (задание, тост).
static func card(accent := GOLD, alpha := 0.9, margin := 12.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(INK_LIGHT, alpha)
	# цветная полоса слева — тип задания или редкость; остальной кант тёмный
	sb.border_color = accent.darkened(0.1) if accent.a > 0.0 else Color(OUTLINE, 0.85)
	sb.set_border_width_all(0)
	sb.border_width_left = 8
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(margin)
	sb.content_margin_left = margin + 6
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 3)
	sb.anti_aliasing = true
	return sb


## Кнопка «с бортиком»: снизу толще и темнее, при нажатии бортик уходит вверх.
static func button_box(color: Color, state := "normal", radius := 16) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	if state == "hover":
		sb.bg_color = color.lightened(0.12)
	elif state == "pressed":
		sb.bg_color = color.darkened(0.08)
	elif state == "disabled":
		sb.bg_color = color.lerp(Color(0.4, 0.38, 0.42), 0.7)
	sb.border_color = OUTLINE
	sb.set_border_width_all(3)
	sb.border_width_bottom = 3 if state == "pressed" else 8
	sb.border_width_top = 6 if state == "pressed" else 3
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	sb.anti_aliasing = true
	return sb


## Покрасить одну кнопку: основная — жёлтая, вторичная — сливовая со светлым текстом.
static func style_button(b: Button, color := GOLD, dark_text := true, radius := 16) -> void:
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, button_box(color, st, radius))
	b.add_theme_stylebox_override("hover_pressed", button_box(color, "pressed", radius))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var fc := BROWN if dark_text else TEXT
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(k, fc)
	b.add_theme_constant_override("outline_size", 0)


## Вкладка: выбранная — жёлтая, остальные — тёмные.
static func style_tab(b: Button, selected: bool) -> void:
	style_button(b, GOLD if selected else INK_LIGHT, selected, 14)


## Круглая кнопка-значок (сумка, задания, меню, закрыть).
static func icon_button(name: String, size := 64.0, color := INK_LIGHT) -> Button:
	var b := Button.new()
	b.icon = icon(name)
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.custom_minimum_size = Vector2(size, size)
	b.focus_mode = Control.FOCUS_NONE
	if color.a == 0.0:
		# голый значок без подложки — у значка свой контур
		for st in ["normal", "hover", "pressed", "disabled", "hover_pressed", "focus"]:
			b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
		return b
	for st in ["normal", "hover", "pressed", "disabled"]:
		var sb := button_box(color, st, int(size / 2))
		sb.set_content_margin_all(size * 0.12)
		sb.content_margin_bottom = size * 0.12 + (2 if st != "pressed" else 0)
		b.add_theme_stylebox_override(st, sb)
	var hp := button_box(color, "pressed", int(size / 2))
	hp.set_content_margin_all(size * 0.12)
	b.add_theme_stylebox_override("hover_pressed", hp)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b


## Заголовок окна шрифтом вывесок.
static func title(parent: Node, text: String, fs := 30, color := GOLD) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", title_font())
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", OUTLINE)
	l.add_theme_constant_override("outline_size", 8)
	parent.add_child(l)
	return l


## Полоса здоровья, опыта, босса: толстый контур, светлый блик сверху.
static func bar_boxes(color: Color) -> Array[StyleBoxFlat]:
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(10)
	fill.border_color = color.lightened(0.35)
	fill.border_width_top = 3
	fill.anti_aliasing = true
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(OUTLINE, 0.8)
	bg.border_color = OUTLINE
	bg.set_border_width_all(3)
	bg.set_corner_radius_all(12)
	bg.set_expand_margin_all(3)
	bg.anti_aliasing = true
	return [fill, bg]


static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font = load("res://assets/fonts/Rubik.ttf")
	t.default_font_size = 20
	# кнопки по умолчанию — жёлтые с бортиком
	for st in ["normal", "hover", "pressed", "disabled"]:
		t.set_stylebox(st, "Button", button_box(GOLD, st))
	t.set_stylebox("hover_pressed", "Button", button_box(GOLD, "pressed"))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		t.set_color(k, "Button", BROWN)
	t.set_color("font_disabled_color", "Button", Color(BROWN, 0.5))
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_outline_color", "Label", OUTLINE)
	t.set_stylebox("panel", "PanelContainer", panel())
	t.set_stylebox("panel", "Panel", panel())
	# толстые круглые полосы прокрутки — пальцем попадать легко
	var grab := StyleBoxFlat.new()
	grab.bg_color = Color(CREAM, 0.55)
	grab.set_corner_radius_all(6)
	grab.content_margin_left = 6
	grab.content_margin_right = 6
	var grab_hi := grab.duplicate()
	grab_hi.bg_color = CREAM
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0, 0, 0, 0.25)
	track.set_corner_radius_all(6)
	track.content_margin_left = 6
	track.content_margin_right = 6
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", grab_hi)
	t.set_stylebox("grabber_pressed", "VScrollBar", grab_hi)
	t.set_stylebox("scroll", "VScrollBar", track)
	var boxes := bar_boxes(GOLD)
	t.set_stylebox("fill", "ProgressBar", boxes[0])
	t.set_stylebox("background", "ProgressBar", boxes[1])
	t.set_color("font_color", "RichTextLabel", TEXT)
	t.set_color("default_color", "RichTextLabel", TEXT)
	_theme = t
	return t
