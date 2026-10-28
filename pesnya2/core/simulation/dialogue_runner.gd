class_name DialogueRunner
extends RefCounted
## Правила диалогов без интерфейса: узлы из data/dialogues.json, условия ответов и последствия.
## Четыре тона ответа постоянны во всей игре, игрок учит их как язык:
## green — по-хорошему, orange — за бабки, cyan — по-умному, purple — по-рубински.
## Последствия начисляются через GameState.grant с ключом ответа и не повторяются.

const TONES := ["green", "orange", "cyan", "purple", "plain"]
const END := "end"

var dialogue_id := ""
var node_id := ""


func _init(id: String) -> void:
	dialogue_id = id
	node_id = String(GameData.dialogues.get(id, {}).get("start", END))


static func speaker(id: String) -> Dictionary:
	return GameData.dialogues_speakers.get(id, {"name": id, "portrait": {}})


func node() -> Dictionary:
	return GameData.dialogues.get(dialogue_id, {}).get("nodes", {}).get(node_id, {})


func finished() -> bool:
	return node_id == END or node().is_empty()


## Ответы текущего узла с пометкой, доступны ли они сейчас и почему нет.
func options() -> Array:
	var out: Array = []
	var opts: Array = node().get("options", [])
	for i in opts.size():
		var o: Dictionary = opts[i]
		var why := blocked_reason(o.get("requires", {}))
		out.append({"index": i, "text": o.text, "tone": o.get("tone", "plain"), "locked": why != "", "why": why})
	return out


static func blocked_reason(req: Dictionary) -> String:
	if req.has("babki") and GameState.babki < int(req.babki):
		return "нужно %d бабок" % int(req.babki)
	if req.has("kukukha") and GameState.kukukha < int(req.kukukha):
		return "кукуха %d+: пока недостаточно отмороженный" % int(req.kukukha)
	if req.has("level") and GameState.level < int(req.level):
		return "с %d уровня" % int(req.level)
	if req.has("item") and GameState.item_count(req.item) == 0:
		return "нужен предмет: %s" % GameData.item_name(req.item)
	if req.has("flag") and not GameState.has_flag(req.flag):
		return "ещё рано"
	if req.has("not_flag") and GameState.has_flag(req.not_flag):
		return "уже было"
	if req.has("stage") and not QuestService.is_on_stage(quest_of(req.stage), req.stage):
		return "не сейчас"
	return ""


## MAIN_001_S02 -> MAIN_001
static func quest_of(stage_id: String) -> String:
	return stage_id.substr(0, stage_id.rfind("_S"))


## Узел без ответов идёт дальше по next. Возвращает события для сцены (поле event).
func advance() -> Array:
	var events: Array = []
	_apply(node().get("effects", {}), "dlg:%s:%s" % [dialogue_id, node_id], events)
	node_id = String(node().get("next", END))
	return events


## Выбор ответа. Недоступный ответ не выбирается.
func choose(index: int) -> Array:
	var opts: Array = node().get("options", [])
	if index < 0 or index >= opts.size():
		return []
	var o: Dictionary = opts[index]
	if blocked_reason(o.get("requires", {})) != "":
		return []
	var events: Array = []
	var key := "dlg:%s:%s:%d" % [dialogue_id, node_id, index]
	if not GameState.granted.has(key):
		GameState.add_tone(o.get("tone", "plain"))
	_apply(o.get("effects", {}), key, events)
	node_id = String(o.get("next", END))
	return events


static func _apply(fx: Dictionary, key: String, events: Array) -> void:
	if fx.is_empty():
		return
	var delta := {}
	for k in ["babki", "reputation", "kukukha", "xp", "items"]:
		if fx.has(k):
			delta[k] = fx[k]
	var first := GameState.grant(key, fx.get("reason", "Разговор"), delta)
	if not first and fx.get("once", true):
		if fx.has("event") and fx.get("event_always", false):
			events.append(fx.event)
		return
	if fx.has("take"):
		for id in fx.take:
			GameState.remove_item(id, int(fx.take[id]))
	if fx.has("flag"):
		GameState.set_flag(fx.flag)
	if fx.has("advance"):
		QuestService.advance(quest_of(fx.advance), fx.advance)
	if fx.has("event"):
		events.append(fx.event)


## Проверка графов: ссылки, тоны, число ответов, достижимость. Пустой массив — всё цело.
static func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	for sid in GameData.dialogues_speakers:
		if not GameData.dialogues_speakers[sid].has("name"):
			errors.append("говорящий %s без имени" % sid)
	for id in GameData.dialogues:
		var d: Dictionary = GameData.dialogues[id]
		var nodes: Dictionary = d.get("nodes", {})
		if not nodes.has(d.get("start", "")):
			errors.append("%s: нет стартового узла" % id)
			continue
		var seen := {}
		var stack: Array = [d.start]
		while not stack.is_empty():
			var nid: String = stack.pop_back()
			if nid == END or seen.has(nid):
				continue
			seen[nid] = true
			if not nodes.has(nid):
				errors.append("%s: ссылка на неизвестный узел %s" % [id, nid])
				continue
			var n: Dictionary = nodes[nid]
			if not GameData.dialogues_speakers.has(n.get("speaker", "")):
				errors.append("%s/%s: неизвестный говорящий %s" % [id, nid, n.get("speaker", "")])
			var opts: Array = n.get("options", [])
			if opts.size() > 4:
				errors.append("%s/%s: больше 4 ответов" % [id, nid])
			if opts.is_empty():
				stack.append(n.get("next", END))
			for o in opts:
				if not TONES.has(o.get("tone", "plain")):
					errors.append("%s/%s: неизвестный тон %s" % [id, nid, o.get("tone")])
				stack.append(o.get("next", END))
				for item in o.get("effects", {}).get("items", {}):
					if not GameData.item_by_id.has(item):
						errors.append("%s/%s: неизвестный предмет %s" % [id, nid, item])
		for nid in nodes:
			if not seen.has(nid):
				errors.append("%s: недостижимый узел %s" % [id, nid])
	return errors
