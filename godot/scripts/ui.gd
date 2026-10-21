class_name GameUI
extends CanvasLayer
## All 2D interface: Aolovo splash, HUD, menus, popups, touch controls.

signal start_pressed
signal again_pressed
signal menu_pressed
signal resume_pressed
signal quit_pressed
signal pause_pressed
signal mute_pressed

var display_font: FontFile
var body_font: FontFile
var theme_main: Theme

var splash: Control
var hud: Control
var menu: Control
var over: Control
var pause_panel: Control
var pops: Control
var tip_label: Label

var lbl := {}
var needle: ColorRect
var tilt_bar: Control
var stick_base: Panel
var stick_knob: Panel
var jump_btn: Panel
var dash_btn: Panel
var dash_fill: Panel
var mute_btn: Button
var top_center: VBoxContainer
var top_right: VBoxContainer


func _ready() -> void:
	layer = 10
	display_font = load("res://fonts/RussoOne-Regular.ttf")
	body_font = load("res://fonts/Rubik.ttf")
	theme_main = _make_theme()
	_build_hud()
	_build_menu()
	_build_over()
	_build_pause()
	pops = Control.new()
	pops.set_anchors_preset(Control.PRESET_FULL_RECT)
	pops.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pops)
	_build_splash()


# ------------------------------------------------------------------ theme helpers
func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = body_font
	t.default_font_size = 22
	var gold := _box(Kit.GOLD, 40)
	gold.content_margin_left = 34
	gold.content_margin_right = 34
	gold.content_margin_top = 12
	gold.content_margin_bottom = 12
	gold.shadow_color = Color("b06a12")
	gold.shadow_offset = Vector2(0, 5)
	gold.shadow_size = 0
	var gold_p := gold.duplicate()
	gold_p.bg_color = Kit.GOLD.darkened(0.12)
	t.set_stylebox("normal", "Button", gold)
	t.set_stylebox("hover", "Button", gold)
	t.set_stylebox("pressed", "Button", gold_p)
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", Kit.NAVY)
	t.set_color("font_hover_color", "Button", Kit.NAVY)
	t.set_color("font_pressed_color", "Button", Kit.NAVY)
	t.set_font("font", "Button", display_font)
	t.set_font_size("font_size", "Button", 26)
	t.set_color("font_color", "Label", Kit.CREAM)
	return t


func _box(c: Color, radius := 18, border := 0, border_c := Color.WHITE) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(radius)
	if border > 0:
		sb.set_border_width_all(border)
		sb.border_color = border_c
	sb.anti_aliasing = true
	return sb


func _panel_style() -> StyleBoxFlat:
	var sb := _box(Color(Kit.NAVY, 0.82), 18)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb


func _label(text: String, size := 22, display := false, color := Kit.CREAM) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", display_font if display else body_font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _chip(caption: String, key: String, value_color := Kit.CREAM) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _panel_style())
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(v)
	v.add_child(_label(caption.to_upper(), 13, false, Color(Kit.CREAM, 0.7)))
	var val := _label("0", 26, true, value_color)
	v.add_child(val)
	lbl[key] = val
	return p


func _circle(radius: float, fill: Color, border: Color) -> Panel:
	var p := Panel.new()
	p.add_theme_stylebox_override("panel", _box(fill, int(radius), 3, border))
	p.size = Vector2(radius * 2, radius * 2)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


# ------------------------------------------------------------------ HUD
func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.theme = theme_main
	add_child(hud)
	hud.visible = false

	var tl := VBoxContainer.new()
	tl.position = Vector2(20, 14)
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(tl)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tl.add_child(row)
	row.add_child(_chip("Пробег", "dist"))
	row.add_child(_chip("Скорость", "spd"))
	tl.add_child(_chip("В банке", "bank", Kit.GOLD))

	var tc := VBoxContainer.new()
	top_center = tc
	tc.custom_minimum_size = Vector2(340, 0)
	tc.alignment = BoxContainer.ALIGNMENT_BEGIN
	tc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(tc)
	var tp := PanelContainer.new()
	tp.add_theme_stylebox_override("panel", _panel_style())
	tp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tc.add_child(tp)
	var trow := HBoxContainer.new()
	trow.alignment = BoxContainer.ALIGNMENT_CENTER
	trow.add_theme_constant_override("separation", 12)
	trow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tp.add_child(trow)
	trow.add_child(_label("БАШНЯ", 14, false, Color(Kit.CREAM, 0.7)))
	lbl["tcount"] = _label("0", 26, true)
	trow.add_child(lbl["tcount"])
	lbl["tmult"] = _label("×1", 26, true, Kit.GOLD)
	trow.add_child(lbl["tmult"])
	lbl["tval"] = _label("на кону 0", 15, false, Color(Kit.CREAM, 0.8))
	trow.add_child(lbl["tval"])
	# tilt bar
	tilt_bar = Control.new()
	tilt_bar.custom_minimum_size = Vector2(300, 14)
	tilt_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tc.add_child(tilt_bar)
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.14, 0.3, 0.7, 0.86, 1.0])
	g.colors = PackedColorArray([Color("ff5d7a"), Color("ffb04a"), Kit.TEAL, Kit.TEAL, Color("ffb04a"), Color("ff5d7a")])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 300
	gt.height = 14
	var tr := TextureRect.new()
	tr.texture = gt
	tr.size = Vector2(300, 14)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tilt_bar.add_child(tr)
	needle = ColorRect.new()
	needle.color = Kit.CREAM
	needle.size = Vector2(8, 22)
	needle.position = Vector2(146, -4)
	needle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tilt_bar.add_child(needle)
	lbl["combo"] = _label("", 30, true, Kit.TEAL)
	lbl["combo"].horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tc.add_child(lbl["combo"])
	lbl["abil"] = _label("", 15, false, Kit.GOLD)
	lbl["abil"].horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tc.add_child(lbl["abil"])

	var tr2 := VBoxContainer.new()
	top_right = tr2
	tr2.custom_minimum_size = Vector2(180, 0)
	tr2.alignment = BoxContainer.ALIGNMENT_BEGIN
	hud.add_child(tr2)
	var brow := HBoxContainer.new()
	brow.alignment = BoxContainer.ALIGNMENT_END
	tr2.add_child(brow)
	mute_btn = _small_button("♪")
	mute_btn.pressed.connect(func(): mute_pressed.emit())
	brow.add_child(mute_btn)
	var pb := _small_button("❚❚")
	pb.pressed.connect(func(): pause_pressed.emit())
	brow.add_child(pb)
	tr2.add_child(_chip("Ворота через", "gate"))

	tip_label = _label("", 20, false, Kit.CREAM)
	tip_label.size = Vector2(660, 0)
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var tip_sb := _box(Color(Kit.NAVY, 0.9), 14, 2, Kit.TEAL)
	tip_sb.content_margin_left = 16
	tip_sb.content_margin_right = 16
	tip_sb.content_margin_top = 8
	tip_sb.content_margin_bottom = 8
	tip_label.add_theme_stylebox_override("normal", tip_sb)
	tip_label.visible = false
	hud.add_child(tip_label)

	# touch controls (visual only; input is read in main.gd so multi-touch works)
	stick_base = _circle(66, Color(Kit.NAVY, 0.3), Color(Kit.CREAM, 0.6))
	hud.add_child(stick_base)
	stick_knob = _circle(28, Color(Kit.CREAM, 0.85), Kit.CREAM)
	hud.add_child(stick_knob)
	jump_btn = _circle(56, Color(Kit.GOLD, 0.22), Color(Kit.CREAM, 0.9))
	hud.add_child(jump_btn)
	var jl := _label("▲\nПрыжок", 16, true)
	jl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	jl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	jl.set_anchors_preset(Control.PRESET_FULL_RECT)
	jump_btn.add_child(jl)
	dash_btn = _circle(42, Color(Kit.NAVY, 0.35), Color(Kit.CREAM, 0.9))
	hud.add_child(dash_btn)
	dash_fill = _circle(42, Color(Kit.TEAL, 0.45), Color(0, 0, 0, 0))
	dash_btn.add_child(dash_fill)
	var dl := _label("»\nРывок", 13, true)
	dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dl.set_anchors_preset(Control.PRESET_FULL_RECT)
	dash_btn.add_child(dl)
	layout_controls()
	get_viewport().size_changed.connect(layout_controls)


func _small_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(54, 50)
	var sb := _box(Color(Kit.NAVY, 0.82), 14)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", _box(Color(Kit.TEAL, 0.6), 14))
	b.add_theme_color_override("font_color", Kit.CREAM)
	b.add_theme_color_override("font_hover_color", Kit.CREAM)
	b.add_theme_font_size_override("font_size", 20)
	return b


func layout_controls() -> void:
	var vs := get_viewport().get_visible_rect().size
	top_center.position = Vector2(vs.x / 2 - 170, 14)
	top_right.position = Vector2(vs.x - 200, 14)
	tip_label.position = Vector2(vs.x / 2 - 330, 160)
	stick_base.position = Vector2(46, vs.y - 46 - 132)
	stick_knob.position = stick_base.position + Vector2(66 - 28, 66 - 28)
	jump_btn.position = Vector2(vs.x - 30 - 112, vs.y - 26 - 112)
	dash_btn.position = Vector2(vs.x - 30 - 112 - 120, vs.y - 36 - 84)


func jump_center() -> Vector2:
	return jump_btn.position + Vector2(56, 56)


func dash_center() -> Vector2:
	return dash_btn.position + Vector2(42, 42)


func set_stick(active: bool, origin: Vector2, dx: float) -> void:
	if active:
		stick_base.position = origin - Vector2(66, 66)
		stick_base.modulate.a = 1.0
	else:
		layout_controls()
		stick_base.modulate.a = 0.55
	stick_knob.position = stick_base.position + Vector2(66 - 28 + dx, 66 - 28)


func set_beat(on: bool) -> void:
	var sb: StyleBoxFlat = jump_btn.get_theme_stylebox("panel")
	sb.border_color = Kit.TEAL if on else Color(Kit.CREAM, 0.9)
	sb.set_border_width_all(6 if on else 3)


func set_pressed(which: String, on: bool) -> void:
	var p := jump_btn if which == "jump" else dash_btn
	p.scale = Vector2(0.93, 0.93) if on else Vector2.ONE
	p.pivot_offset = p.size / 2


func set_hud(d: Dictionary) -> void:
	lbl.dist.text = "%d м" % d.dist
	lbl.spd.text = "%d км/ч" % d.spd
	lbl.bank.text = "★ %d" % d.bank
	lbl.tcount.text = str(d.tcount)
	lbl.tmult.text = "×%s" % str(snappedf(d.tmult, 0.01))
	lbl.tval.text = "на кону %d" % d.tval
	lbl.gate.text = d.gate
	needle.position.x = 146 + clampf(d.tilt, -1.0, 1.0) * 141
	lbl.combo.text = ("Комбо ×%d" % d.combo) if d.combo >= 2 else ""
	lbl.abil.text = d.abil
	dash_fill.scale = Vector2.ONE * clampf(d.dash_ready, 0.0, 1.0)
	dash_fill.pivot_offset = dash_fill.size / 2


func set_music_icon(on: bool) -> void:
	mute_btn.text = "♪" if on else "×"


# ------------------------------------------------------------------ popups & tips
func pop(text: String, kind: String, at: Vector2) -> void:
	var c := Kit.GOLD
	match kind:
		"bad": c = Color("ff5d7a")
		"neon": c = Kit.TEAL
		"bank": c = Color("2ed38f")
	var l := _label(text, 34 if kind == "bank" else 26, true, c)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("outline_size", 8)
	pops.add_child(l)
	l.reset_size()
	l.position = at - l.size / 2
	l.pivot_offset = l.size / 2
	l.scale = Vector2(1.3, 1.3)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "scale", Vector2.ONE, 0.25)
	tw.tween_property(l, "position:y", l.position.y - 80, 1.1)
	tw.tween_property(l, "modulate:a", 0.0, 1.1).set_delay(0.3)
	tw.chain().tween_callback(l.queue_free)


var _tip_tw: Tween
func tip(text: String, secs := 0.0) -> void:
	tip_label.text = text
	tip_label.visible = true
	if _tip_tw:
		_tip_tw.kill()
	if secs > 0:
		_tip_tw = create_tween()
		_tip_tw.tween_interval(secs)
		_tip_tw.tween_callback(func(): tip_label.visible = false)


func hide_tip() -> void:
	tip_label.visible = false


func flash(color: Color, strength := 0.5) -> void:
	var r := ColorRect.new()
	r.color = Color(color, strength)
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	var tw := create_tween()
	tw.tween_property(r, "color:a", 0.0, 0.4)
	tw.tween_callback(r.queue_free)


# ------------------------------------------------------------------ screens
func _screen() -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.theme = theme_main
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(Kit.NAVY, 0.55)
	c.add_child(bg)
	add_child(c)
	c.visible = false
	return c


func _card(parent: Control, width := 640.0) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(center)
	var p := PanelContainer.new()
	var sb := _box(Color(Kit.NAVY, 0.88), 26)
	sb.content_margin_left = 34
	sb.content_margin_right = 34
	sb.content_margin_top = 26
	sb.content_margin_bottom = 28
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(width, 0)
	center.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	p.add_child(v)
	return v


func _build_menu() -> void:
	menu = _screen()
	var v := _card(menu, 700)
	var logo := TextureRect.new()
	logo.texture = load("res://brand/logo_light.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	logo.custom_minimum_size = Vector2(220, 72)
	logo.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	v.add_child(logo)
	var title := _label("Башня на спине", 58, true, Kit.GOLD)
	v.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	v.add_child(row)
	lbl["wallet"] = _label("★ 0", 28, true, Kit.GOLD)
	row.add_child(lbl["wallet"])
	lbl["best"] = _label("", 17, false, Color(Kit.CREAM, 0.75))
	lbl["best"].size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(lbl["best"])
	var desc := _label("Рэпер-непоседа несётся по крышам и собирает всё подряд. Добыча растёт башней за спиной: чем выше, тем больше множитель и тем сильнее качает. Прыгай в бит и сдавай добычу в воротах.", 18)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(620, 0)
	v.add_child(desc)
	var b := Button.new()
	b.text = "Бежать"
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.pressed.connect(func(): start_pressed.emit())
	v.add_child(b)
	v.add_child(_label("Игра студии Aolovo · aolovo.ru · aolovo.com", 14, false, Color(Kit.CREAM, 0.6)))


func _build_over() -> void:
	over = _screen()
	var v := _card(over, 640)
	lbl["over_title"] = _label("Сорвался!", 50, true, Color("ff5d7a"))
	v.add_child(lbl["over_title"])
	lbl["over_text"] = _label("", 18)
	lbl["over_text"].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl["over_text"].custom_minimum_size = Vector2(560, 0)
	v.add_child(lbl["over_text"])
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 30)
	v.add_child(stats)
	for k in [["Заработано", "o_bank"], ["Пробег", "o_dist"], ["Всего звёзд", "o_wallet"], ["Рекорд", "o_best"]]:
		var col := VBoxContainer.new()
		col.add_child(_label(k[0].to_upper(), 13, false, Color(Kit.CREAM, 0.7)))
		var val := _label("0", 30, true, Kit.GOLD)
		col.add_child(val)
		lbl[k[1]] = val
		stats.add_child(col)
	lbl["o_new"] = _label("Новый рекорд!", 22, true, Kit.TEAL)
	v.add_child(lbl["o_new"])
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	v.add_child(row)
	var again := Button.new()
	again.text = "Ещё забег"
	again.pressed.connect(func(): again_pressed.emit())
	row.add_child(again)
	var m := Button.new()
	m.text = "В меню"
	_secondary(m)
	m.pressed.connect(func(): menu_pressed.emit())
	row.add_child(m)


func _build_pause() -> void:
	pause_panel = _screen()
	var v := _card(pause_panel, 520)
	v.add_child(_label("Пауза", 54, true, Kit.GOLD))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	v.add_child(row)
	var r := Button.new()
	r.text = "Продолжить"
	r.pressed.connect(func(): resume_pressed.emit())
	row.add_child(r)
	var q := Button.new()
	q.text = "Закончить"
	_secondary(q)
	q.pressed.connect(func(): quit_pressed.emit())
	row.add_child(q)


func _secondary(b: Button) -> void:
	var sb := _box(Color(0, 0, 0, 0), 40, 2, Kit.CREAM)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", _box(Color(Kit.CREAM, 0.15), 40, 2, Kit.CREAM))
	b.add_theme_color_override("font_color", Kit.CREAM)
	b.add_theme_color_override("font_hover_color", Kit.CREAM)
	b.add_theme_color_override("font_pressed_color", Kit.CREAM)
	b.add_theme_font_override("font", body_font)
	b.add_theme_font_size_override("font_size", 20)


func show_screen(name: String) -> void:
	menu.visible = name == "menu"
	over.visible = name == "over"
	pause_panel.visible = name == "pause"
	hud.visible = name == "play" or name == "pause"


func set_menu_stats(stars: int, best: int, best_dist: int) -> void:
	lbl.wallet.text = "★ %d" % stars
	lbl.best.text = ("Рекорд: ★ %d · %d м" % [best, best_dist]) if best > 0 else ""


func set_over(title: String, text: String, earned: int, dist: int, wallet: int, best: int, is_new: bool) -> void:
	lbl.over_title.text = title
	lbl.over_text.text = text
	lbl.o_bank.text = "+%d" % earned
	lbl.o_dist.text = "%d м" % dist
	lbl.o_wallet.text = "★ %d" % wallet
	lbl.o_best.text = "★ %d" % best
	lbl.o_new.visible = is_new


# ------------------------------------------------------------------ Aolovo splash
func _build_splash() -> void:
	splash = Control.new()
	splash.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(splash)
	var bg := ColorRect.new()
	bg.color = Color.WHITE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	splash.add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	splash.add_child(center)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 18)
	center.add_child(v)
	var logo := TextureRect.new()
	logo.texture = load("res://brand/logo.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(620, 204)
	v.add_child(logo)
	var sub := _label("П Р Е Д С Т А В Л Я Е Т", 18, false, Kit.NAVY)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	logo.modulate.a = 0.0
	logo.scale = Vector2(0.92, 0.92)
	logo.pivot_offset = Vector2(310, 102)
	sub.modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(logo, "modulate:a", 1.0, 0.7)
	tw.tween_property(logo, "scale", Vector2.ONE, 1.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(sub, "modulate:a", 1.0, 0.6).set_delay(0.7)
	tw.chain().tween_interval(1.0)
	tw.chain().tween_property(splash, "modulate:a", 0.0, 0.6)
	tw.chain().tween_callback(func(): splash.visible = false)
	splash.gui_input.connect(func(e):
		if e is InputEventScreenTouch and e.pressed:
			splash.visible = false)


func splash_visible() -> bool:
	return splash.visible
