class_name DialogView
extends Control
## Окно разговора как на макете: портрет говорящего, табличка с именем, текстовое поле
## и до четырёх ответов-«таблеток» с цветной точкой тона. Ведёт граф DialogueRunner
## или простой список реплик. Пропуск проматывает только реплики: выбор всегда за игроком.

signal closed

const TONE_COLORS := {"green": Color(0.3, 0.9, 0.4), "orange": Color(1, 0.5, 0.15),
		"cyan": Color(0.2, 0.85, 1), "purple": Color(0.75, 0.3, 1), "plain": Color(0.75, 0.72, 0.65)}
const TONE_HINTS := {"green": "по-хорошему", "orange": "за бабки", "cyan": "по-умному", "purple": "по-рубински"}

var _portrait: Portrait
var _name: Label
var _text: Label
var _options: VBoxContainer
var _skip: Button
var _runner: DialogueRunner
var _lines: Array = []
var _on_event: Callable
var _on_done: Callable
var _typing: Tween
## События графа отдаются сцене после закрытия окна, чтобы сцена могла открыть следующий разговор.
var _pending: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(_on_tap)

	_portrait = Portrait.new()
	add_child(_portrait)
	_place(_portrait, Vector2(0, 1), Vector2(28, -420), Vector2(300, -24))

	var box := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.22, 0.17, 0.12, 0.93)
	sb.border_color = Color(0.85, 0.72, 0.5, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 26
	sb.content_margin_bottom = 14
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 8
	box.add_theme_stylebox_override("panel", sb)
	add_child(box)
	_place(box, Vector2(0, 1), Vector2(318, -420), Vector2(0, -258))
	box.anchor_right = 1.0
	box.offset_right = -24
	box.gui_input.connect(_on_tap)
	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_size_override("font_size", 25)
	_text.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86))
	_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(_text)

	_name = Label.new()
	_name.add_theme_font_size_override("font_size", 22)
	_name.add_theme_color_override("font_color", Color(1, 0.85, 0.55))
	var tag := StyleBoxFlat.new()
	tag.bg_color = Color(0.12, 0.09, 0.07, 0.98)
	tag.border_color = Color(0.85, 0.72, 0.5)
	tag.set_border_width_all(2)
	tag.set_corner_radius_all(8)
	tag.content_margin_left = 14
	tag.content_margin_right = 14
	tag.content_margin_top = 2
	tag.content_margin_bottom = 2
	_name.add_theme_stylebox_override("normal", tag)
	add_child(_name)
	_place(_name, Vector2(0, 1), Vector2(334, -438), Vector2(334, -404))

	_options = VBoxContainer.new()
	_options.add_theme_constant_override("separation", 7)
	add_child(_options)
	_place(_options, Vector2(0, 1), Vector2(318, -250), Vector2(0, -20))
	_options.anchor_right = 1.0
	_options.offset_right = -24

	_skip = Button.new()
	_skip.text = "Пропустить ▸▸"
	_skip.focus_mode = Control.FOCUS_NONE
	_skip.add_theme_font_size_override("font_size", 20)
	_skip.pressed.connect(skip)
	add_child(_skip)
	_place(_skip, Vector2(1, 1), Vector2(-220, -446), Vector2(-40, -404))
	var ks := StyleBoxFlat.new()
	ks.bg_color = Color(0.12, 0.09, 0.07, 0.98)
	ks.border_color = Color(0.85, 0.72, 0.5)
	ks.set_border_width_all(2)
	ks.set_corner_radius_all(8)
	for st in ["normal", "hover", "pressed"]:
		_skip.add_theme_stylebox_override(st, ks)


func _place(c: Control, anchor: Vector2, tl: Vector2, br: Vector2) -> void:
	c.anchor_left = anchor.x
	c.anchor_right = anchor.x
	c.anchor_top = anchor.y
	c.anchor_bottom = anchor.y
	c.offset_left = tl.x
	c.offset_top = tl.y
	c.offset_right = br.x
	c.offset_bottom = br.y


## Граф из data/dialogues.json. on_event(name) — сюжетные события для сцены.
func run(dialogue_id: String, on_event := Callable(), on_done := Callable()) -> void:
	_runner = DialogueRunner.new(dialogue_id)
	_lines = []
	_on_event = on_event
	_on_done = on_done
	visible = true
	_show_node()


## Простые реплики: [{speaker, text}], speaker — имя или id говорящего.
func play_lines(lines: Array, on_done := Callable()) -> void:
	_runner = null
	_lines = lines.duplicate()
	_on_event = Callable()
	_on_done = on_done
	visible = true
	_show_line()


## Произвольный выбор: options [{tone, text, cb, locked?, why?}].
func ask(speaker: String, text: String, options: Array) -> void:
	_runner = null
	_lines = []
	_on_event = Callable()
	_on_done = Callable()
	visible = true
	_say(speaker, text)
	_fill(options.map(func(o): return {"text": o.text, "tone": o.get("tone", "plain"), "locked": o.get("locked", false),
			"why": o.get("why", ""), "cb": func():
				_close()
				o.cb.call()}))


func _say(speaker_ref: String, text: String) -> void:
	var sp := _find_speaker(speaker_ref)
	_name.text = sp.name
	_name.reset_size()
	_portrait.set_spec(sp.get("portrait", {}))
	_text.text = text
	_text.visible_ratio = 0.0
	if _typing:
		_typing.kill()
	_typing = create_tween()
	_typing.tween_property(_text, "visible_ratio", 1.0, clampf(text.length() / 70.0, 0.25, 2.0))


static func _find_speaker(ref: String) -> Dictionary:
	if GameData.dialogues_speakers.has(ref):
		return GameData.dialogues_speakers[ref]
	for id in GameData.dialogues_speakers:
		if String(GameData.dialogues_speakers[id].name).to_lower() == ref.to_lower():
			return GameData.dialogues_speakers[id]
	return {"name": ref.capitalize(), "portrait": {"kind": "journal"}}


func _show_node() -> void:
	if _runner.finished():
		_close()
		return
	var n := _runner.node()
	_say(n.speaker, n.text)
	var opts := _runner.options()
	if opts.is_empty():
		_fill([{"text": "Дальше", "tone": "plain", "cb": _next_node}])
		return
	_fill(opts.map(func(o): return {"text": o.text, "tone": o.tone, "locked": o.locked, "why": o.why,
			"cb": func(): _pick(o.index)}))


func _next_node() -> void:
	_emit(_runner.advance())
	_show_node()


func _pick(i: int) -> void:
	_emit(_runner.choose(i))
	_show_node()


func _emit(events: Array) -> void:
	_pending.append_array(events)


func _show_line() -> void:
	if _lines.is_empty():
		_close()
		return
	var l: Dictionary = _lines.pop_front()
	_say(l.speaker, l.text)
	_fill([{"text": "Дальше", "tone": "plain", "cb": _show_line}])


func _fill(options: Array) -> void:
	for c in _options.get_children():
		_options.remove_child(c)
		c.queue_free()
	for o in options:
		_options.add_child(_pill(o))


func _pill(o: Dictionary) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size.y = 52
	var tone: String = o.tone
	var col: Color = TONE_COLORS.get(tone, TONE_COLORS.plain)
	for st in ["normal", "hover", "pressed", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.07, 0.07, 0.09, 0.94) if st != "pressed" else col.darkened(0.6)
		if st == "hover":
			sb.bg_color = Color(0.12, 0.11, 0.14, 0.96)
		sb.border_color = col.darkened(0.2) if st != "disabled" else Color(0.3, 0.3, 0.3)
		sb.set_border_width_all(1)
		sb.border_width_left = 5
		sb.set_corner_radius_all(16)
		b.add_theme_stylebox_override(st, sb)
	var h := HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 14)
	b.add_child(h)
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 18
	var dot := Label.new()
	dot.text = "●"
	dot.add_theme_font_size_override("font_size", 22)
	dot.add_theme_color_override("font_color", col if not o.get("locked", false) else Color(0.4, 0.4, 0.4))
	h.add_child(dot)
	var t := Label.new()
	t.text = o.text
	if o.get("locked", false):
		t.text += "   (%s)" % String(o.get("why", ""))
	t.add_theme_font_size_override("font_size", 22)
	t.add_theme_color_override("font_color", Color(0.95, 0.93, 0.88) if not o.get("locked", false) else Color(0.5, 0.5, 0.5))
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	for l in [dot, t]:
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(t)
	if TONE_HINTS.has(tone) and not o.get("locked", false):
		var hint := Label.new()
		hint.text = TONE_HINTS[tone]
		hint.add_theme_font_size_override("font_size", 15)
		hint.add_theme_color_override("font_color", col.darkened(0.15))
		hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(hint)
		var pad := Control.new()
		pad.custom_minimum_size.x = 8
		h.add_child(pad)
	b.disabled = o.get("locked", false)
	b.pressed.connect(func():
		if _typing and _typing.is_running():
			_typing.custom_step(10.0)
		o.cb.call())
	return b


## Тап по тексту дописывает реплику сразу.
func _on_tap(e: InputEvent) -> void:
	if (e is InputEventMouseButton or e is InputEventScreenTouch) and e.pressed and _typing and _typing.is_running():
		_typing.custom_step(10.0)


## Проматывает реплики до ближайшего выбора или до конца. Последствия реплик применяются.
func skip() -> void:
	if _runner:
		while not _runner.finished() and _runner.node().get("options", []).is_empty():
			_emit(_runner.advance())
		_show_node()
	elif not _lines.is_empty() or visible:
		_lines.clear()
		_close()


## Для автотеста: первый доступный ответ указанного тона (или первый доступный вообще).
func pick_tone(tone := "") -> bool:
	if _runner == null:
		return false
	for o in _runner.options():
		if not o.locked and (tone == "" or o.tone == tone):
			_pick(o.index)
			return true
	return false


func is_open() -> bool:
	return visible


func _close() -> void:
	if not visible:
		return
	visible = false
	_runner = null
	if _typing:
		_typing.kill()
	closed.emit()
	var events := _pending
	_pending = []
	var on_event := _on_event
	_on_event = Callable()
	for e in events:
		if on_event.is_valid():
			on_event.call(e)
	if _on_done.is_valid():
		var cb := _on_done
		_on_done = Callable()
		cb.call()
