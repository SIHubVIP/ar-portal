extends Node
## Квестовый движок 127 заданий. Чистые правила: без узлов сцены и без UI.
## Состояния по ТЗ (раздел 11). Награда за квест выдаётся один раз по ключу quest:<id>:reward.

const LOCKED := "LOCKED"
const AVAILABLE := "AVAILABLE"
const ACTIVE := "ACTIVE"
const OBJECTIVE_DONE := "OBJECTIVE_DONE"
const TURN_IN_READY := "TURN_IN_READY"
const COMPLETED := "COMPLETED"
const FAILED_RECOVERABLE := "FAILED_RECOVERABLE"

## quest_id -> {state, stage, progress, checkpoint, choice}
var records: Dictionary = {}
## Отслеживаемое задание (0.21): последнее принятое или продвинутое. По нему ведут стрелка и трекер.
var tracked := ""


func _ready() -> void:
	reset()


func reset() -> void:
	records.clear()
	tracked = ""
	for q in GameData.quests:
		records[q.id] = {"state": LOCKED, "stage": 0, "progress": 0, "checkpoint": 0, "choice": ""}
	refresh_availability()


func state_of(id: String) -> String:
	return records.get(id, {}).get("state", LOCKED)


## Уровень в карточках — рекомендация, а не замок (docs/decisions.log, D-004).
func refresh_availability() -> void:
	for q in GameData.quests:
		var r: Dictionary = records[q.id]
		if r.state != LOCKED:
			continue
		var ok := true
		for dep in q.requires:
			if state_of(dep) != COMPLETED:
				ok = false
				break
		if ok:
			_set_state(q.id, AVAILABLE)


func accept(id: String) -> bool:
	if state_of(id) != AVAILABLE:
		return false
	var r: Dictionary = records[id]
	r.stage = 0
	r.progress = 0
	r.checkpoint = 0
	_set_state(id, ACTIVE)
	tracked = id
	EventBus.quest_stage_changed.emit(id, 0)
	return true


func current_stage(id: String) -> Dictionary:
	var r: Dictionary = records.get(id, {})
	var stages: Array = GameData.quest(id).get("stages", [])
	if r.is_empty() or r.state != ACTIVE or r.stage >= stages.size():
		return {}
	return stages[r.stage]


func is_on_stage(id: String, stage_id: String) -> bool:
	return current_stage(id).get("id", "") == stage_id


## Засчитать прогресс этапа. Повторный вызов для уже пройденного этапа ничего не делает.
func advance(id: String, stage_id: String, amount := 1) -> bool:
	var st := current_stage(id)
	if st.is_empty() or st.id != stage_id or st.type == "choice":
		return false
	var r: Dictionary = records[id]
	r.progress = mini(int(r.progress) + amount, int(st.target))
	if r.progress >= int(st.target):
		_next_stage(id)
	return true


## Выбор A/B на этапе типа choice. Ставит канонический флаг из карточки.
func choose(id: String, key: String) -> bool:
	var st := current_stage(id)
	var q := GameData.quest(id)
	if st.is_empty() or st.type != "choice" or not q.choices.has(key):
		return false
	var r: Dictionary = records[id]
	r.choice = key
	GameState.set_flag(q.choices[key].flag)
	_next_stage(id)
	return true


func turn_in(id: String) -> bool:
	if state_of(id) != TURN_IN_READY:
		return false
	var q := GameData.quest(id)
	var reward: Dictionary = q.reward.duplicate()
	GameState.grant("quest:%s:reward" % id, "Задание %s «%s»" % [id, q.title], reward)
	_set_state(id, COMPLETED)
	refresh_availability()
	return true


## Провал без потери прогресса: откат к последней контрольной точке.
func fail_recoverable(id: String) -> void:
	if state_of(id) == ACTIVE:
		_set_state(id, FAILED_RECOVERABLE)


func retry(id: String) -> bool:
	if state_of(id) != FAILED_RECOVERABLE:
		return false
	var r: Dictionary = records[id]
	r.stage = r.checkpoint
	r.progress = 0
	_set_state(id, ACTIVE)
	EventBus.quest_stage_changed.emit(id, r.stage)
	return true


func active_quests() -> Array:
	return GameData.quests.filter(func(q): return state_of(q.id) in [ACTIVE, TURN_IN_READY, FAILED_RECOVERABLE])


## Задание для трекера: отслеживаемое, если оно ещё в работе, иначе первое активное.
func tracked_quest() -> Dictionary:
	if tracked != "" and state_of(tracked) in [ACTIVE, TURN_IN_READY, FAILED_RECOVERABLE]:
		return GameData.quest(tracked)
	var act := active_quests()
	return act[0] if not act.is_empty() else {}


func _next_stage(id: String) -> void:
	var r: Dictionary = records[id]
	var stages: Array = GameData.quest(id).stages
	r.stage += 1
	r.progress = 0
	if r.stage >= stages.size():
		_set_state(id, OBJECTIVE_DONE)
		_set_state(id, TURN_IN_READY)
		return
	if stages[r.stage].checkpoint:
		r.checkpoint = r.stage
	tracked = id
	EventBus.quest_stage_changed.emit(id, r.stage)


func _set_state(id: String, state: String) -> void:
	records[id].state = state
	EventBus.quest_state_changed.emit(id, state)


func to_dict() -> Dictionary:
	var out := {}
	for id in records:
		var r: Dictionary = records[id]
		if r.state != LOCKED and r.state != AVAILABLE:
			out[id] = r.duplicate()
	return out


func from_dict(d: Dictionary) -> void:
	reset()
	for id in d:
		if not records.has(id):
			push_warning("QuestService: неизвестный квест в сохранении %s" % id)
			continue
		var r: Dictionary = d[id]
		records[id] = {"state": r.get("state", LOCKED), "stage": int(r.get("stage", 0)),
				"progress": int(r.get("progress", 0)), "checkpoint": int(r.get("checkpoint", 0)),
				"choice": r.get("choice", "")}
	refresh_availability()
