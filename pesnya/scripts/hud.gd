class_name Hud
extends Control
## Immediate-mode HUD (drawn every frame) + modal panels built from Controls.

const NAVY := Color("142a38")
const GOLD := Color("f5b55c")
const TEAL := Color("55cdbe")
const CREAM := Color("fff6ea")
const RED := Color("e83c46")
const GREEN := Color("46d278")
const PURPLE := Color("b06eff")
const PANEL := Color(0.055, 0.07, 0.13, 0.82)
const RARITY := [Color("e8e8e8"), Color("4aa0ff"), Color("b06eff"), Color("ffb52e")]
const RARITY_NAME := ["обычное", "редкое", "эпическое", "легендарное"]

var g  # main game
var fd: FontFile
var fb: FontFile
var floaters: Array = []
var toasts: Array = []
var big_text := ""
var big_sub := ""
var big_t := 0.0
var hurt := 0.0

# modal panels
var menu_panel: Control
var select_panel: Control
var dialog_panel: Control
var bag_panel: Control
var pause_panel: Control
var dead_panel: Control
var loading_panel: Control
var list_panel: Control
var list_title: Label
var list_sub: Label
var list_box: VBoxContainer
var list_close: Button
var menu_continue: Button
var menu_new: Button
var loading_title: Label
var dialog_name: Label
var dialog_text: Label
var dialog_opts: VBoxContainer
var bag_list: VBoxContainer
var bag_stats: Label
var race_btns := {}
var class_btns := {}
var combo_title: Label
var combo_text: Label
var pause_music: Button
var pause_quality: Button
var pause_offset: Label
var theme_main: Theme

const RACES := [["rapper", "Рэпер", true], ["punk", "Панк", true], ["goth", "Гот", false], ["gopnik", "Пацан", false], ["hipster", "Хипстер", false], ["granny", "Бабушка", false], ["it", "Айтишник", false]]
const CLASSES := [["cop", "Коп", true], ["medic", "Медик", true], ["guard", "Охранник", false], ["hacker", "Хакер", false], ["cook", "Повар", false], ["courier", "Курьер", false], ["dj", "Диджей", false]]
const COMBO := {
	"rapper_cop": ["Рэпер + Коп = «МС Патруль»", "Зачитывает права в рифму. Бьёт звуковой волной из микрофона-дубинки. В бит — крит ×2.3."],
	"rapper_medic": ["Рэпер + Медик = «Доктор Флоу»", "Лечит битом, бьёт гитарой-аптечкой. Пассивка рэпера: крит в бит ×2.3."],
	"punk_cop": ["Панк + Коп = «Сержант Ирокез»", "Ирокез не помещается под фуражку. Пассивка панка: +20% здоровья."],
	"punk_medic": ["Панк + Медик = «ПанкДоктор»", "Лечит аккордами, колет «панк-уколом». Пассивка панка: +20% здоровья."],
}


func setup(game) -> void:
	g = game
	fd = load("res://fonts/RussoOne-Regular.ttf")
	fb = load("res://fonts/Rubik.ttf")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme_main = _make_theme()
	theme = theme_main
	_build_menu()
	_build_select()
	_build_dialog()
	_build_bag()
	_build_pause()
	_build_dead()
	_build_loading()
	_build_list()


# ================================================================== theme & helpers
func _box(c: Color, r := 16, bw := 0, bc := Color.WHITE) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(r)
	s.set_border_width_all(bw)
	s.border_color = bc
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s


func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = fb
	t.default_font_size = 20
	t.set_stylebox("normal", "Button", _box(GOLD, 18))
	t.set_stylebox("hover", "Button", _box(GOLD.lightened(0.1), 18))
	t.set_stylebox("pressed", "Button", _box(GOLD.darkened(0.15), 18))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_stylebox("disabled", "Button", _box(Color(0.25, 0.27, 0.35, 0.9), 18))
	t.set_color("font_color", "Button", NAVY)
	t.set_color("font_hover_color", "Button", NAVY)
	t.set_color("font_pressed_color", "Button", NAVY)
	t.set_color("font_disabled_color", "Button", Color(0.65, 0.68, 0.75))
	t.set_font("font", "Button", fd)
	t.set_font_size("font_size", "Button", 20)
	t.set_color("font_color", "Label", CREAM)
	t.set_stylebox("panel", "PanelContainer", _box(PANEL, 22, 2, Color(1, 1, 1, 0.12)))
	return t


func _label(text: String, size := 20, display := false, color := CREAM) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	if display:
		l.add_theme_font_override("font", fd)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _btn(text: String, cb: Callable, w := 0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(w, 54)
	b.pressed.connect(func():
		g.play_sfx("ui")
		cb.call())
	return b


func _secondary(b: Button) -> Button:
	b.add_theme_stylebox_override("normal", _box(Color(1, 1, 1, 0.08), 18, 2, Color(1, 1, 1, 0.25)))
	b.add_theme_stylebox_override("hover", _box(Color(1, 1, 1, 0.14), 18, 2, Color(1, 1, 1, 0.3)))
	b.add_theme_stylebox_override("pressed", _box(Color(1, 1, 1, 0.2), 18, 2, Color(1, 1, 1, 0.3)))
	b.add_theme_color_override("font_color", CREAM)
	b.add_theme_color_override("font_hover_color", CREAM)
	b.add_theme_color_override("font_pressed_color", CREAM)
	return b


func _modal() -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	c.visible = false
	add_child(c)
	return c


func _center_card(parent: Control, w := 560) -> VBoxContainer:
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(cc)
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(w, 0)
	cc.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	pc.add_child(v)
	return v


# ================================================================== modal panels
func _build_menu() -> void:
	menu_panel = _modal()
	menu_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pc := PanelContainer.new()
	pc.position = Vector2(36, 40)
	pc.custom_minimum_size = Vector2(580, 0)
	menu_panel.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	pc.add_child(v)
	var logo := TextureRect.new()
	logo.texture = load("res://brand/logo_light.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	logo.custom_minimum_size = Vector2(220, 60)
	v.add_child(logo)
	v.add_child(_label("ПЕСНЯ ♪", 76, true, GOLD))
	var sub := _label("Офлайн-версия 0.4 · новое: серверная Кощея", 22, false, CREAM)
	sub.custom_minimum_size = Vector2(520, 0)
	v.add_child(sub)
	var d := _label("Бей в бит — урон ×2. Голуби, свой гараж, стройка Глушилки с Шумодавом, а теперь — серверная Кощея и рэп-баттл за музыку города.", 18, false, Color(0.75, 0.8, 0.88))
	d.custom_minimum_size = Vector2(520, 0)
	v.add_child(d)
	menu_continue = _btn("ПРОДОЛЖИТЬ", func(): g.continue_game(), 260)
	v.add_child(menu_continue)
	menu_new = _btn("НОВЫЙ ГЕРОЙ", func(): g.open_select(), 260)
	v.add_child(menu_new)
	v.add_child(_label("Игра студии Aolovo · aolovo.com", 15, false, Color(0.6, 0.66, 0.75)))


func _build_select() -> void:
	select_panel = _modal()
	select_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := _label("СОЗДАНИЕ ГЕРОЯ", 34, true, GOLD)
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(-300, 14)
	title.size = Vector2(600, 50)
	select_panel.add_child(title)
	for side in [0, 1]:
		var pc := PanelContainer.new()
		pc.position = Vector2(16, 70) if side == 0 else Vector2(0, 70)
		if side == 1:
			pc.set_anchors_preset(Control.PRESET_TOP_RIGHT)
			pc.position = Vector2(-216, 70)
		pc.custom_minimum_size = Vector2(200, 0)
		select_panel.add_child(pc)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 6)
		pc.add_child(v)
		v.add_child(_label("РАСА" if side == 0 else "КЛАСС", 20, true, TEAL))
		for e in (RACES if side == 0 else CLASSES):
			var id: String = e[0]
			var b := Button.new()
			b.text = e[1] if e[2] else e[1] + " · скоро"
			b.disabled = not e[2]
			b.custom_minimum_size = Vector2(168, 42)
			b.add_theme_font_size_override("font_size", 17)
			if side == 0:
				b.pressed.connect(func(): g.play_sfx("ui"); g.set_combo(id, g.cls))
				race_btns[id] = b
			else:
				b.pressed.connect(func(): g.play_sfx("ui"); g.set_combo(g.race, id))
				class_btns[id] = b
			v.add_child(b)
	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	card.position = Vector2(-330, -170)
	card.custom_minimum_size = Vector2(660, 150)
	select_panel.add_child(card)
	var v2 := VBoxContainer.new()
	v2.add_theme_constant_override("separation", 6)
	card.add_child(v2)
	combo_title = _label("", 24, true, GOLD)
	combo_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v2.add_child(combo_title)
	combo_text = _label("", 17)
	combo_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v2.add_child(combo_text)
	var start := _btn("НАЧАТЬ ПЕСНЮ", func(): g.start_game(), 300)
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v2.add_child(start)


func refresh_select() -> void:
	for id in race_btns:
		var b: Button = race_btns[id]
		if b.disabled:
			continue
		if id == g.race:
			b.add_theme_stylebox_override("normal", _box(GOLD, 14, 3, CREAM))
		else:
			_secondary(b)
	for id in class_btns:
		var b: Button = class_btns[id]
		if b.disabled:
			continue
		if id == g.cls:
			b.add_theme_stylebox_override("normal", _box(GOLD, 14, 3, CREAM))
			b.add_theme_color_override("font_color", NAVY)
		else:
			_secondary(b)
	for id in race_btns:
		if id == g.race and not race_btns[id].disabled:
			race_btns[id].add_theme_color_override("font_color", NAVY)
	var c: Array = COMBO[g.race + "_" + g.cls]
	combo_title.text = c[0]
	combo_text.text = c[1]


func _build_dialog() -> void:
	dialog_panel = _modal()
	var pc := PanelContainer.new()
	pc.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	pc.position = Vector2(-380, -250)
	pc.custom_minimum_size = Vector2(760, 220)
	pc.add_theme_stylebox_override("panel", _box(PANEL, 22, 3, GOLD))
	dialog_panel.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	pc.add_child(v)
	dialog_name = _label("", 24, true, GOLD)
	v.add_child(dialog_name)
	dialog_text = _label("", 21)
	dialog_text.custom_minimum_size = Vector2(720, 0)
	v.add_child(dialog_text)
	dialog_opts = VBoxContainer.new()
	dialog_opts.add_theme_constant_override("separation", 8)
	v.add_child(dialog_opts)


func show_dialog(who: String, text: String, opts: Array) -> void:
	dialog_name.text = who
	dialog_text.text = text
	for c in dialog_opts.get_children():
		c.queue_free()
	for o in opts:
		var cb: Callable = o[1]
		dialog_opts.add_child(_btn(o[0], cb))
	dialog_panel.visible = true


func hide_dialog() -> void:
	dialog_panel.visible = false


func _build_bag() -> void:
	bag_panel = _modal()
	var v := _center_card(bag_panel, 620)
	v.add_child(_label("СУМКА", 30, true, GOLD))
	bag_stats = _label("", 18, false, Color(0.8, 0.85, 0.92))
	v.add_child(bag_stats)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(580, 300)
	v.add_child(sc)
	bag_list = VBoxContainer.new()
	bag_list.add_theme_constant_override("separation", 6)
	bag_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(bag_list)
	v.add_child(_btn("ЗАКРЫТЬ", func(): g.close_bag()))


func show_bag() -> void:
	for c in bag_list.get_children():
		c.queue_free()
	bag_stats.text = "Уровень %d · Сила %d · Здоровье %d · Монеты %d · Шаурма %d\n%s" % [g.level, g.power, int(g.hp_max), g.coins, g.food, g.res_line()]
	if g.inventory.is_empty():
		bag_list.add_child(_label("Пока пусто. Добыча падает с голубей — подходи к светящимся столбам.", 18))
	var sorted: Array = g.inventory.duplicate()
	sorted.sort_custom(func(a, b): return a.rarity > b.rarity)
	for it in sorted:
		var on: bool = is_same(g.equipped.get(it.slot, null), it)
		var l := _label("%s%s  ·  %s%s" % ["✓ " if on else "", it.name, RARITY_NAME[it.rarity], ("  ·  +%d силы" % it.power) if it.power > 0 else ""], 19, false, RARITY[it.rarity])
		bag_list.add_child(l)
		var d := _label(it.desc, 15, false, Color(0.7, 0.75, 0.82))
		bag_list.add_child(d)
	bag_panel.visible = true


func _build_pause() -> void:
	pause_panel = _modal()
	var v := _center_card(pause_panel, 520)
	v.add_child(_label("ПАУЗА", 32, true, GOLD))
	v.add_child(_btn("ПРОДОЛЖИТЬ", func(): g.toggle_pause()))
	pause_music = _secondary(_btn("", func(): g.set_music(not g.music_on); refresh_pause()))
	v.add_child(pause_music)
	pause_quality = _secondary(_btn("", func(): g.set_quality(1 - g.quality); refresh_pause()))
	v.add_child(pause_quality)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	v.add_child(h)
	h.add_child(_secondary(_btn("−", func(): g.beat_offset -= 0.02; refresh_pause(), 70)))
	pause_offset = _label("", 18)
	pause_offset.custom_minimum_size = Vector2(300, 0)
	pause_offset.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_child(pause_offset)
	h.add_child(_secondary(_btn("+", func(): g.beat_offset += 0.02; refresh_pause(), 70)))
	v.add_child(_label("Если удары «не попадают» в бит (часто с Bluetooth-наушниками) — двигай сдвиг, пока кольцо не совпадёт со звуком.", 15, false, Color(0.7, 0.75, 0.82)))
	v.add_child(_secondary(_btn("ВЫЙТИ В МЕНЮ", func(): g.to_menu())))


func refresh_pause() -> void:
	pause_music.text = "Музыка: " + ("вкл" if g.music_on else "выкл")
	pause_quality.text = "Графика: " + ("Красиво" if g.quality == 1 else "Быстро (без теней)")
	pause_offset.text = "Сдвиг бита: %+d мс" % int(round(g.beat_offset * 1000))


func _build_dead() -> void:
	dead_panel = _modal()
	var r := ColorRect.new()
	r.color = Color(0.3, 0.0, 0.05, 0.45)
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	dead_panel.add_child(r)
	var v := _center_card(dead_panel, 520)
	v.add_child(_label("Голуби победили…", 30, true, Color("ff8a8a")))
	v.add_child(_label("Баба Зина уже несёт валерьянку. Возвращаемся через пару секунд.", 19))


func _build_loading() -> void:
	loading_panel = _modal()
	var r := ColorRect.new()
	r.color = Color("142a38")
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	loading_panel.add_child(r)
	var v := _center_card(loading_panel, 480)
	loading_title = _label("Загружаем двор «Берёзки»…", 26, true, GOLD)
	v.add_child(loading_title)
	v.add_child(_label("Совет: жми атаку, когда золотое кольцо сжимается до кнопки. Это бит.", 18))


# ================================================================== layout of touch buttons
func btn_pos(name: String) -> Vector2:
	var s := size
	match name:
		"attack": return Vector2(s.x - 128, s.y - 122)
		"s1": return Vector2(s.x - 272, s.y - 78)
		"s2": return Vector2(s.x - 262, s.y - 205)
		"s3": return Vector2(s.x - 140, s.y - 268)
		"ult": return Vector2(s.x - 400, s.y - 96)
		"talk": return Vector2(s.x - 405, s.y - 240)
		"food": return Vector2(s.x - 262, s.y - 330)
		"pause": return Vector2(s.x - 214, 40)
		"bag": return Vector2(s.x - 214, 104)
		"mount": return Vector2(s.x - 214, 170)
	return Vector2(-999, -999)


func btn_radius(name: String) -> float:
	match name:
		"attack": return 68.0
		"pause", "bag", "mount": return 28.0
		"ult", "talk": return 48.0
		"food": return 36.0
	return 44.0


func button_at(p: Vector2) -> String:
	var names := ["attack", "s1", "s2", "s3", "pause", "bag", "food"]
	if g.vibe >= 100.0:
		names.append("ult")
	if g.interact_label() != "":
		names.append("talk")
	if g.mount_owned:
		names.append("mount")
	for n in names:
		if p.distance_to(btn_pos(n)) < btn_radius(n) + 10:
			return n
	return ""


# ================================================================== per-frame effects
func float_text(world_pos: Vector3, text: String, col: Color, size := 30, rise := 60.0) -> void:
	floaters.append({"p": world_pos, "text": text, "col": col, "size": size, "t": 0.0, "life": 1.1, "rise": rise, "dx": randf_range(-20, 20)})


func toast(text: String, col := CREAM) -> void:
	toasts.append({"text": text, "col": col, "t": 0.0})
	if toasts.size() > 4:
		toasts.pop_front()


func big(text: String, sub := "", secs := 2.5) -> void:
	big_text = text
	big_sub = sub
	big_t = secs


func _process(delta: float) -> void:
	for f in floaters:
		f.t += delta
	floaters = floaters.filter(func(f): return f.t < f.life)
	for t in toasts:
		t.t += delta
	toasts = toasts.filter(func(t): return t.t < 3.2)
	big_t = maxf(0.0, big_t - delta)
	hurt = maxf(0.0, hurt - delta * 1.6)
	queue_redraw()


# ================================================================== drawing
func _txt(p: Vector2, s: String, size: int, col: Color, display := false, align := HORIZONTAL_ALIGNMENT_LEFT, w := -1.0, outline := 0) -> void:
	var f := fd if display else fb
	var pp := p
	if align == HORIZONTAL_ALIGNMENT_CENTER and w < 0:
		var tw := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		pp.x -= tw / 2
		align = HORIZONTAL_ALIGNMENT_LEFT
	elif align == HORIZONTAL_ALIGNMENT_RIGHT and w < 0:
		var tw2 := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		pp.x -= tw2
		align = HORIZONTAL_ALIGNMENT_LEFT
	if outline > 0:
		draw_string_outline(f, pp, s, align, w, size, outline, Color(0, 0, 0, 0.85))
	else:
		draw_string(f, pp + Vector2(1.5, 1.5), s, align, w, size, Color(0, 0, 0, 0.5))
	draw_string(f, pp, s, align, w, size, col)


func _rrect(r: Rect2, col: Color, rad := 12) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(rad)
	draw_style_box(sb, r)


func _bar(r: Rect2, frac: float, col: Color, label := "") -> void:
	_rrect(r, Color(0, 0, 0, 0.55), int(r.size.y / 2))
	if frac > 0.0:
		_rrect(Rect2(r.position, Vector2(maxf(r.size.y, r.size.x * clampf(frac, 0, 1)), r.size.y)), col, int(r.size.y / 2))
		_rrect(Rect2(r.position + Vector2(3, 2), Vector2(maxf(0, r.size.x * clampf(frac, 0, 1) - 6), r.size.y * 0.35)), Color(1, 1, 1, 0.22), int(r.size.y / 4))
	if label != "":
		_txt(Vector2(r.position.x + r.size.x / 2, r.position.y + r.size.y * 0.78), label, int(r.size.y * 0.72), CREAM, false, HORIZONTAL_ALIGNMENT_CENTER)


func _icon(kind: String, c: Vector2, s: float, col: Color) -> void:
	var k := s / 40.0
	match kind:
		"mic":
			draw_circle(c + Vector2(0, -10 * k), 11 * k, col)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-6, 0) * k, c + Vector2(6, 0) * k, c + Vector2(3, 20) * k, c + Vector2(-3, 20) * k]), col)
		"cuffs":
			draw_arc(c + Vector2(-9, 4) * k, 8 * k, 0, TAU, 20, col, 4 * k)
			draw_arc(c + Vector2(9, 4) * k, 8 * k, 0, TAU, 20, col, 4 * k)
			draw_line(c + Vector2(-3, -6) * k, c + Vector2(3, -6) * k, col, 4 * k)
		"siren":
			draw_arc(c + Vector2(0, 4) * k, 11 * k, PI, TAU, 16, col, 12 * k)
			draw_rect(Rect2(c + Vector2(-14, 4) * k, Vector2(28, 6) * k), col)
			for a in [-0.5, -1.57, -2.64]:
				draw_line(c + Vector2(cos(a), sin(a)) * 16 * k + Vector2(0, 2) * k, c + Vector2(cos(a), sin(a)) * 22 * k + Vector2(0, 2) * k, col, 3 * k)
		"dash":
			for i in range(3):
				var o := Vector2(-12 + i * 9, 0) * k
				draw_polyline(PackedVector2Array([c + o + Vector2(-5, -10) * k, c + o + Vector2(5, 0) * k, c + o + Vector2(-5, 10) * k]), col, 4 * k)
		"heal":
			draw_rect(Rect2(c + Vector2(-4, -14) * k, Vector2(8, 28) * k), col)
			draw_rect(Rect2(c + Vector2(-14, -4) * k, Vector2(28, 8) * k), col)
		"needle":
			draw_line(c + Vector2(-14, 14) * k, c + Vector2(10, -10) * k, col, 7 * k)
			draw_line(c + Vector2(10, -10) * k, c + Vector2(17, -17) * k, col, 2 * k)
			draw_line(c + Vector2(-17, 7) * k, c + Vector2(-7, 17) * k, col, 3 * k)
		"note":
			draw_circle(c + Vector2(-6, 8) * k, 7 * k, col)
			draw_line(c + Vector2(0, 8) * k, c + Vector2(0, -14) * k, col, 3.5 * k)
			draw_line(c + Vector2(0, -14) * k, c + Vector2(10, -8) * k, col, 3.5 * k)
		"guitar":
			draw_circle(c + Vector2(-4, 6) * k, 10 * k, col)
			draw_line(c + Vector2(-2, 2) * k, c + Vector2(14, -16) * k, col, 4 * k)
		"bag":
			_rrect(Rect2(c + Vector2(-12, -6) * k, Vector2(24, 20) * k), col, 4)
			draw_arc(c + Vector2(0, -6) * k, 7 * k, PI, TAU, 12, col, 3 * k)
		"pause":
			draw_rect(Rect2(c + Vector2(-9, -11) * k, Vector2(6, 22) * k), col)
			draw_rect(Rect2(c + Vector2(3, -11) * k, Vector2(6, 22) * k), col)
		"hut":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-13, -2) * k, c + Vector2(0, -15) * k, c + Vector2(13, -2) * k]), col)
			draw_rect(Rect2(c + Vector2(-10, -2) * k, Vector2(20, 11) * k), col)
			draw_line(c + Vector2(-5, 9) * k, c + Vector2(-8, 17) * k, col, 3 * k)
			draw_line(c + Vector2(5, 9) * k, c + Vector2(8, 17) * k, col, 3 * k)
		"talk":
			_rrect(Rect2(c + Vector2(-16, -14) * k, Vector2(32, 22) * k), col, 6)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-8, 8) * k, c + Vector2(0, 8) * k, c + Vector2(-10, 17) * k]), col)


func _skill_button(name: String, icon: String, label: String) -> void:
	var c := btn_pos(name)
	var r := btn_radius(name)
	draw_circle(c, r, Color(0.12, 0.1, 0.2, 0.86))
	draw_arc(c, r, 0, TAU, 48, Color(1, 1, 1, 0.45), 3)
	_icon(icon, c + Vector2(0, -4), r * 0.85, CREAM)
	var cdv: float = g.cd.get(name, 0.0)
	var cdm: float = g.cd_max.get(name, 1.0)
	if cdv > 0.0:
		var pts := PackedVector2Array([c])
		var a0 := -PI / 2
		var a1 := a0 + TAU * (cdv / cdm)
		for i in range(25):
			var a := lerpf(a0, a1, i / 24.0)
			pts.append(c + Vector2(cos(a), sin(a)) * r)
		draw_colored_polygon(pts, Color(0, 0, 0, 0.6))
		_txt(c + Vector2(0, 12), str(int(ceil(cdv))), 30, CREAM, true, HORIZONTAL_ALIGNMENT_CENTER)
	if g.silence_t > 0.0:
		draw_circle(c, r, Color(0.55, 0.6, 0.7, 0.55))
		_txt(c + Vector2(0, 7), "ТИШЬ", 15, Color("eef2ff"), true, HORIZONTAL_ALIGNMENT_CENTER, -1, 3)
	_txt(c + Vector2(0, r + 18), label, 14, Color(0.9, 0.92, 0.98), false, HORIZONTAL_ALIGNMENT_CENTER, -1, 3)


func _draw() -> void:
	if g == null or not g.in_world():
		return
	var s := size
	var cam: Camera3D = g.cam

	# hurt vignette
	if hurt > 0.0:
		for i in range(6):
			var a := hurt * 0.12 * (6 - i) / 6.0
			draw_rect(Rect2(0, 0, s.x, 24 + i * 10), Color(0.9, 0.05, 0.1, a * 0.4))
			draw_rect(Rect2(0, s.y - 24 - i * 10, s.x, 24 + i * 10), Color(0.9, 0.05, 0.1, a * 0.4))

	# nameplates (mobs, npc, loot)
	for m in g.mobs:
		if not m.alive:
			continue
		var hp3: Vector3 = m.pos + Vector3(0, m.height + 0.4, 0)
		if cam.is_position_behind(hp3) or hp3.distance_to(cam.global_position) > 32:
			continue
		var sp := cam.unproject_position(hp3)
		var is_t: bool = is_same(m, g.target)
		var col := Color("ff7070") if m.boss else (Color("ffb0a0") if not is_t else Color("ffe0a0"))
		_txt(sp + Vector2(0, -18), "%d  %s" % [m.lvl, m.name], 17 if not m.boss else 21, col, true, HORIZONTAL_ALIGNMENT_CENTER, -1, 4)
		var bw := 110.0 if not m.boss else 180.0
		_bar(Rect2(sp.x - bw / 2, sp.y - 10, bw, 11), m.hp / m.hp_max, Color("e8424c"))
		if m.stun > 0.0:
			_txt(sp + Vector2(0, -42), "ОГЛУШЁН", 15, Color("ffe066"), false, HORIZONTAL_ALIGNMENT_CENTER, -1, 3)
	for n in g.npcs:
		var npc_p: Vector3 = n.pos + Vector3(0, n.get("h", 2.2), 0)
		if cam.is_position_behind(npc_p) or npc_p.distance_to(cam.global_position) > 40:
			continue
		var sp2 := cam.unproject_position(npc_p)
		_txt(sp2, n.name, 18, Color("ffe6a0"), true, HORIZONTAL_ALIGNMENT_CENTER, -1, 4)
		_txt(sp2 + Vector2(0, 18), n.role, 13, Color(0.85, 0.9, 1.0), false, HORIZONTAL_ALIGNMENT_CENTER, -1, 3)
		var mk: String = g.npc_marker(n.id)
		if mk != "":
			var bounce := sin(g.time * 5.0) * 5.0
			_txt(sp2 + Vector2(0, -24 + bounce), mk, 46, GOLD, true, HORIZONTAL_ALIGNMENT_CENTER, -1, 6)
	for e in g.world_labels():
		var lp2: Vector3 = e[0]
		if cam.is_position_behind(lp2) or lp2.distance_to(cam.global_position) > 30:
			continue
		var sp5 := cam.unproject_position(lp2)
		var bounce2 := sin(g.time * 5.0) * 4.0
		_txt(sp5 + Vector2(0, bounce2), e[1], e[2], e[3], true, HORIZONTAL_ALIGNMENT_CENTER, -1, 5)
	for l in g.loots:
		var lp: Vector3 = l.pos + Vector3(0, 1.3, 0)
		if cam.is_position_behind(lp) or lp.distance_to(cam.global_position) > 26:
			continue
		var sp3 := cam.unproject_position(lp)
		_txt(sp3, l.item.name, 15, RARITY[l.item.rarity], false, HORIZONTAL_ALIGNMENT_CENTER, -1, 3)

	# floating texts
	for f in floaters:
		var p3: Vector3 = f.p
		if cam.is_position_behind(p3):
			continue
		var sp4 := cam.unproject_position(p3) + Vector2(f.dx * f.t, -f.rise * f.t)
		var a := 1.0 - clampf((f.t - 0.6) / 0.5, 0, 1)
		var sc := 1.0 + maxf(0, 0.25 - f.t) * 2.0
		_txt(sp4, f.text, int(f.size * sc), Color(f.col, a), true, HORIZONTAL_ALIGNMENT_CENTER, -1, 5)

	# player frame
	_rrect(Rect2(14, 12, 360, 104), PANEL, 22)
	var pc := Vector2(64, 64)
	draw_circle(pc, 46, GOLD)
	if g.portrait:
		var tex: Texture2D = g.portrait
		draw_texture_rect(tex, Rect2(pc - Vector2(42, 42), Vector2(84, 84)), false)
	else:
		draw_circle(pc, 42, NAVY)
	draw_circle(pc + Vector2(32, 34), 17, GOLD)
	_txt(pc + Vector2(32, 41), str(g.level), 18, NAVY, true, HORIZONTAL_ALIGNMENT_CENTER)
	_txt(Vector2(122, 40), g.hero_name, 22, CREAM, true)
	_txt(Vector2(124, 60), g.combo_label(), 14, Color(0.78, 0.84, 0.92))
	_bar(Rect2(122, 68, 236, 20), g.hp / g.hp_max, Color("3fc86e"), "%d / %d" % [int(g.hp), int(g.hp_max)])
	_bar(Rect2(122, 93, 236, 14), g.vibe / 100.0, PURPLE if g.vibe < 100 else GOLD, "Вайб %d" % int(g.vibe) if g.vibe < 100 else "ХИТ ГОТОВ!")
	var sy := 140.0
	if g.buff_t > 0.0:
		_txt(Vector2(24, sy), "Панк-укол: урон ×1.6 · %d c" % int(ceil(g.buff_t)), 15, GREEN, false, HORIZONTAL_ALIGNMENT_LEFT, -1, 3)
		sy += 22
	if g.group_t > 0.0:
		_txt(Vector2(24, sy), "Песня группы: урон ×1.4 · %d c" % int(ceil(g.group_t)), 15, TEAL, false, HORIZONTAL_ALIGNMENT_LEFT, -1, 3)
		sy += 22
	if g.silence_t > 0.0:
		_txt(Vector2(24, sy), "ТИШИНА · навыки молчат %d c — ударь в бит!" % int(ceil(g.silence_t)), 15, Color("dfe6ff"), false, HORIZONTAL_ALIGNMENT_LEFT, -1, 3)
		sy += 22
	if g.mounted:
		_txt(Vector2(24, sy), "Верхом на Избушке · атака — спешиться", 15, GOLD, false, HORIZONTAL_ALIGNMENT_LEFT, -1, 3)

	# target frame
	var t = g.target
	if t != null and t.alive:
		var tw := 420.0
		var tx := (s.x - tw) / 2
		_rrect(Rect2(tx, 12, tw, 74), PANEL, 18)
		draw_circle(Vector2(tx + 38, 49), 26, Color(0.45, 0.12, 0.16) if t.boss else Color(0.25, 0.25, 0.32))
		_txt(Vector2(tx + 38, 57), str(t.lvl), 20, CREAM, true, HORIZONTAL_ALIGNMENT_CENTER)
		_txt(Vector2(tx + 76, 38), t.name, 20, Color("ff9a9a") if t.boss else CREAM, true)
		_bar(Rect2(tx + 76, 50, tw - 94, 20), t.hp / t.hp_max, Color("e8424c"), "%d%%" % int(ceil(100.0 * t.hp / t.hp_max)))
		if t.kind == "koschei":
			var dots := ""
			for i in range(3):
				dots += "●" if i < int(t.rap) else "○"
			var st2: String = ("ПОДПИСКА: урон −92% · рэп-баттл " + dots) if t.shield else ("Подписка отменена: %d с — бей!" % int(ceil(t.shield_t)))
			_rrect(Rect2(tx, 90, tw, 30), PANEL, 12)
			_txt(Vector2(s.x / 2, 112), st2, 17, Color("dfe6ff") if t.shield else GOLD, true, HORIZONTAL_ALIGNMENT_CENTER)

	# minimap
	var mc := Vector2(s.x - 92, 92)
	var mr := 76.0
	draw_circle(mc, mr + 5, Color(0.05, 0.07, 0.13, 0.9))
	draw_circle(mc, mr, Color("3c5a40"))
	var sc2 := mr / 26.0
	var pp: Vector3 = g.pos
	var to_map := func(w: Vector3) -> Vector2: return mc + Vector2(w.x - pp.x, w.z - pp.z) * sc2
	for r in g.world.map_rects:
		var a2: Vector2 = to_map.call(Vector3(r.position.x, 0, r.position.y))
		var b2: Vector2 = to_map.call(Vector3(r.end.x, 0, r.end.y))
		var rr := Rect2(a2, b2 - a2).intersection(Rect2(mc - Vector2(mr, mr) * 0.72, Vector2(mr, mr) * 1.44))
		if rr.size.x > 0 and rr.size.y > 0:
			draw_rect(rr, Color("6a6a72"))
	for m in g.mobs:
		if m.alive:
			var d2: Vector2 = to_map.call(m.pos)
			if d2.distance_to(mc) < mr - 5:
				draw_circle(d2, 6 if m.boss else 4, Color("ff4a4a"))
	for n in g.npcs:
		var nz: Vector2 = to_map.call(n.pos)
		if nz.distance_to(mc) < mr - 5:
			draw_circle(nz, 5, GOLD)
	for pt in g.world.portals:
		var pz: Vector2 = to_map.call(pt.pos)
		if pz.distance_to(mc) < mr - 5:
			draw_circle(pz, 6, TEAL)
	for l in g.loots:
		var lz: Vector2 = to_map.call(l.pos)
		if lz.distance_to(mc) < mr - 5:
			draw_circle(lz, 3, RARITY[l.item.rarity])
	var fa: float = g.facing
	var fwd := Vector2(sin(fa), cos(fa))
	var rt := Vector2(fwd.y, -fwd.x)
	draw_colored_polygon(PackedVector2Array([mc + fwd * 11, mc - fwd * 7 + rt * 7, mc - fwd * 3, mc - fwd * 7 - rt * 7]), GOLD)
	draw_arc(mc, mr, 0, TAU, 64, GOLD, 2.5)
	_rrect(Rect2(mc.x - 92, mc.y + mr + 10, 168, 30), PANEL, 12)
	_txt(Vector2(mc.x - 8, mc.y + mr + 31), g.world.name, 15, CREAM, false, HORIZONTAL_ALIGNMENT_CENTER)
	# coins
	_rrect(Rect2(s.x - 470, 18, 150, 40), PANEL, 20)
	draw_circle(Vector2(s.x - 448, 38), 13, GOLD)
	_txt(Vector2(s.x - 448, 44), "A", 15, Color("7a4a14"), true, HORIZONTAL_ALIGNMENT_CENTER)
	_txt(Vector2(s.x - 428, 46), str(g.coins), 20, CREAM, true)
	# pause & bag
	for nm in ["pause", "bag"]:
		var bc := btn_pos(nm)
		draw_circle(bc, 28, Color(0.06, 0.08, 0.14, 0.85))
		draw_arc(bc, 28, 0, TAU, 32, Color(1, 1, 1, 0.3), 2)
		_icon(nm, bc, 28, CREAM)
	if g.mount_owned:
		var mc2 := btn_pos("mount")
		draw_circle(mc2, 28, Color(0.95, 0.75, 0.3, 0.95) if g.mounted else Color(0.06, 0.08, 0.14, 0.85))
		draw_arc(mc2, 28, 0, TAU, 32, TEAL, 2.5)
		_icon("hut", mc2, 28, NAVY if g.mounted else CREAM)

	# quest tracker
	var ql: Array = g.quest_lines()
	if ql.size() > 0:
		var qx := s.x - 360
		var qy := 214.0
		var qh := 46 + 28 * (ql.size() - 1)
		_rrect(Rect2(qx, qy, 340, qh), Color(0.04, 0.05, 0.1, 0.62), 14)
		_rrect(Rect2(qx, qy, 6, qh), GOLD, 3)
		_txt(Vector2(qx + 18, qy + 28), ql[0], 18, GOLD, true)
		for i in range(1, ql.size()):
			_txt(Vector2(qx + 18, qy + 28 + i * 28), ql[i], 16, CREAM)

	# joystick
	if g.joy_idx != -1:
		var o: Vector2 = g.joy_origin
		draw_circle(o, 96, Color(1, 1, 1, 0.1))
		draw_arc(o, 96, 0, TAU, 48, Color(1, 1, 1, 0.35), 3)
		draw_circle(o + g.joy_vec * 60.0, 40, Color(1, 1, 1, 0.45))
	else:
		var o2 := Vector2(170, s.y - 160)
		draw_arc(o2, 96, 0, TAU, 48, Color(1, 1, 1, 0.16), 3)
		draw_circle(o2, 40, Color(1, 1, 1, 0.12))

	# skill buttons with the beat ring on attack
	var ph: float = g.beat_phase()
	var near := minf(ph, 1.0 - ph)
	var ac := btn_pos("attack")
	var ring_r := 72.0 + 60.0 * (1.0 - ph)
	draw_arc(ac, ring_r, 0, TAU, 64, Color(GOLD, 0.25 + 0.6 * ph), 4)
	if near * g.beat_len < g.beat_win:
		draw_circle(ac, 82, Color(GOLD, 0.25))
	draw_circle(ac, 68, Color(0.13, 0.1, 0.22, 0.92))
	draw_arc(ac, 68, 0, TAU, 64, GOLD, 5)
	_icon("mic" if g.cls == "cop" else "guitar", ac + Vector2(0, -6), 64, GOLD)
	_txt(ac + Vector2(0, 48), "В БИТ!" if near * g.beat_len < g.beat_win else "атака", 15, GOLD if near * g.beat_len < g.beat_win else CREAM, true, HORIZONTAL_ALIGNMENT_CENTER)
	var sk: Array = g.skill_info()
	_skill_button("s1", sk[0][0], sk[0][1])
	_skill_button("s2", sk[1][0], sk[1][1])
	_skill_button("s3", sk[2][0], sk[2][1])
	if g.vibe >= 100.0:
		var uc := btn_pos("ult")
		var pulse := 1.0 + 0.08 * sin(g.time * 8.0)
		draw_circle(uc, 58 * pulse, Color(GOLD, 0.3))
		draw_circle(uc, 48, GOLD)
		_txt(uc + Vector2(0, 9), "ХИТ!", 24, NAVY, true, HORIZONTAL_ALIGNMENT_CENTER)
	var il: String = g.interact_label()
	if il != "":
		var tc := btn_pos("talk")
		draw_circle(tc, 52 + 3 * sin(g.time * 4.0), Color(0.95, 0.75, 0.3, 0.3))
		draw_circle(tc, 48, Color(0.95, 0.75, 0.3, 0.95))
		_icon("talk", tc + Vector2(0, -8), 36, NAVY)
		_txt(tc + Vector2(0, 26), il, 13, NAVY, true, HORIZONTAL_ALIGNMENT_CENTER)
	var fc := btn_pos("food")
	draw_circle(fc, 36, Color(0.12, 0.1, 0.2, 0.86))
	draw_arc(fc, 36, 0, TAU, 40, Color(1, 0.7, 0.35, 0.6), 3)
	_rrect(Rect2(fc + Vector2(-16, -10), Vector2(32, 18)), Color("e8b060"), 8)
	draw_line(fc + Vector2(-12, -2), fc + Vector2(12, -2), Color("7a3a1a"), 2)
	_txt(fc + Vector2(0, 26), "×%d" % g.food, 14, CREAM, true, HORIZONTAL_ALIGNMENT_CENTER, -1, 3)
	if g.cd.get("food", 0.0) > 0.0:
		draw_circle(fc, 36, Color(0, 0, 0, 0.55))
		_txt(fc + Vector2(0, 9), str(int(ceil(g.cd.food))), 24, CREAM, true, HORIZONTAL_ALIGNMENT_CENTER)

	# rap-code door prompt
	if g.lock_active:
		var lw := 440.0
		var lx := (s.x - lw) / 2
		_rrect(Rect2(lx, s.y - 112, lw, 52), Color(0.1, 0.06, 0.02, 0.85), 18)
		var hits := ""
		for i in range(GameData.RAP_LOCK):
			hits += "● " if i < g.lock_hits else "○ "
		_txt(Vector2(s.x / 2, s.y - 92), "РЭП-КОД  " + hits, 20, GOLD, true, HORIZONTAL_ALIGNMENT_CENTER)
		_txt(Vector2(s.x / 2, s.y - 70), "атакуй точно в бит — дверь слушает рифму", 14, CREAM, false, HORIZONTAL_ALIGNMENT_CENTER)

	# beat track
	var bw2 := 440.0
	var bx := (s.x - bw2) / 2
	var by := s.y - 40
	_rrect(Rect2(bx, by - 20, bw2, 40), Color(0.04, 0.05, 0.1, 0.7), 20)
	var hit_x := bx + 70
	draw_rect(Rect2(hit_x - 3, by - 17, 6, 34), GOLD)
	for i in range(6):
		var nx := hit_x + (i + 1.0 - ph) * 58.0
		if nx < bw2 + bx - 16:
			var bc2 := Color("ff5d7a") if (g.beat_index() + i + 1) % 4 == 0 else TEAL
			draw_circle(Vector2(nx, by), 10, bc2)
	_txt(Vector2(bx + 22, by + 8), "♪", 22, GOLD, false)
	if g.combo > 1:
		_txt(Vector2(bx + bw2 - 18, by + 7), "Комбо ×%d" % g.combo, 17, GOLD, true, HORIZONTAL_ALIGNMENT_RIGHT)

	# xp bar
	draw_rect(Rect2(0, s.y - 7, s.x, 7), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(0, s.y - 7, s.x * g.xp / float(g.xp_next()), 7), Color(0.47, 0.35, 1.0))

	# toasts and big messages
	for i in range(toasts.size()):
		var tt: Dictionary = toasts[i]
		var a3 := clampf(3.2 - tt.t, 0, 1)
		_txt(Vector2(s.x / 2, 128 + i * 30), tt.text, 19, Color(tt.col, a3), true, HORIZONTAL_ALIGNMENT_CENTER, -1, 4)
	if big_t > 0.0:
		var a4 := clampf(big_t * 2.0, 0, 1)
		_txt(Vector2(s.x / 2, s.y * 0.36), big_text, 46, Color(GOLD, a4), true, HORIZONTAL_ALIGNMENT_CENTER, -1, 7)
		if big_sub != "":
			_txt(Vector2(s.x / 2, s.y * 0.36 + 42), big_sub, 22, Color(CREAM, a4), true, HORIZONTAL_ALIGNMENT_CENTER, -1, 5)
	# fps (test build)
	_txt(Vector2(18, s.y - 18), "%d FPS · сборка теста" % Engine.get_frames_per_second(), 13, Color(1, 1, 1, 0.55))


# ================================================================== generic list panel (shop, base, robot, dailies)
func _build_list() -> void:
	list_panel = _modal()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.35)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	list_panel.add_child(dim)
	var v := _center_card(list_panel, 680)
	list_title = _label("", 28, true, GOLD)
	v.add_child(list_title)
	list_sub = _label("", 17, false, Color(0.8, 0.85, 0.92))
	list_sub.custom_minimum_size = Vector2(640, 0)
	v.add_child(list_sub)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(640, 330)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	list_box = VBoxContainer.new()
	list_box.add_theme_constant_override("separation", 8)
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list_box)
	list_close = _secondary(_btn("ЗАКРЫТЬ", func(): g.close_list()))
	v.add_child(list_close)


## rows: Array of {text, sub, btn, cb, enabled, color}
func show_list(title: String, sub: String, rows: Array) -> void:
	list_title.text = title
	list_sub.text = sub
	for c in list_box.get_children():
		c.queue_free()
	for r in rows:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var tv := VBoxContainer.new()
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var t := _label(r.get("text", ""), 19, true, r.get("color", CREAM))
		tv.add_child(t)
		if r.get("sub", "") != "":
			tv.add_child(_label(r.sub, 15, false, Color(0.72, 0.78, 0.86)))
		row.add_child(tv)
		if r.has("btn"):
			var cb: Callable = r.cb
			var b := _btn(r.btn, cb, 170)
			b.disabled = not r.get("enabled", true)
			b.add_theme_font_size_override("font_size", 16)
			row.add_child(b)
		list_box.add_child(row)
		var sep := ColorRect.new()
		sep.color = Color(1, 1, 1, 0.08)
		sep.custom_minimum_size = Vector2(0, 1)
		list_box.add_child(sep)
	list_panel.visible = true
