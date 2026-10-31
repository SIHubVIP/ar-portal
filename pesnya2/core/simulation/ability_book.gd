class_name AbilityBook
extends RefCounted
## Правила способностей без узлов сцены: откаты, эффект по типу из канона,
## черновые числа баланса. Сцена только спрашивает can_cast() и исполняет effect().

## Тип способности из ТЗ -> вид эффекта. Числа ниже — черновой баланс (editorial).
const EFFECTS := {
	"удар": {"effect": "strike", "damage": 26.0},
	"критический удар": {"effect": "strike", "damage": 40.0},
	"контрудар": {"effect": "strike", "damage": 30.0, "guard": 2.0},
	"выстрел": {"effect": "shot", "damage": 22.0},
	"энерголуч": {"effect": "shot", "damage": 24.0},
	"рывок": {"effect": "dash", "damage": 14.0},
	"уклонение": {"effect": "dash", "damage": 0.0},
	"короткий телепорт": {"effect": "dash", "damage": 0.0},
	"блок": {"effect": "guard", "duration": 4.0},
	"барьер": {"effect": "guard", "duration": 5.0},
	"таунт": {"effect": "stun", "duration": 3.0},
	"приманка": {"effect": "stun", "duration": 3.5},
	"контроль": {"effect": "stun", "duration": 3.0},
	"дебафф": {"effect": "stun", "duration": 2.5, "damage": 10.0},
	"удар по площади": {"effect": "area", "damage": 30.0},
	"залп": {"effect": "area", "damage": 28.0},
	"турель": {"effect": "turret", "damage": 8.0, "duration": 8.0},
	"усиление": {"effect": "buff", "duration": 8.0},
	"ультимейт": {"effect": "area", "damage": 80.0},
}

var abilities: Array = []
var _ready_at: Dictionary = {}


func _init(class_id: String) -> void:
	abilities = GameData.class_abilities(class_id)


## Способности открываются по одной: уровни из data/ability_flavor.json.
static func unlock_level(index: int) -> int:
	var levels: Array = GameData.ability_flavor.get("unlock_levels", [1, 2, 4, 7, 10, 14, 20])
	return int(levels[clampi(index, 0, levels.size() - 1)])


## Карточка способности для интерфейса: характеристики и описание.
static func describe(ability: Dictionary, level: int) -> Dictionary:
	var s: Dictionary = EFFECTS.get(ability.kind, {})
	var flavor: Dictionary = GameData.ability_flavor.get("abilities", {}).get(ability.id, {})
	var lines: PackedStringArray = []
	if s.has("damage"):
		lines.append("Урон %d" % roundi(scaled(float(s.damage), level, false)))
	if s.has("duration"):
		lines.append("Длится %.0f с" % float(s.duration))
	lines.append("Перезарядка %.0f с" % float(ability.cooldown_s))
	if float(ability.range_m) > 0.0:
		lines.append("Дальность %.1f м" % float(ability.range_m))
	return {"stats": " · ".join(lines), "text": flavor.get("text", ""), "shout": flavor.get("shout", "")}


func spec(ability: Dictionary) -> Dictionary:
	var s: Dictionary = EFFECTS.get(ability.kind, {"effect": "strike", "damage": 20.0}).duplicate()
	s.range = maxf(float(ability.range_m), 2.0)
	return s


func remaining(id: String, now: float) -> float:
	return maxf(0.0, float(_ready_at.get(id, 0.0)) - now)


func can_cast(id: String, now: float) -> bool:
	return remaining(id, now) <= 0.0


func cast(id: String, now: float) -> bool:
	if not can_cast(id, now):
		return false
	_ready_at[id] = now + float(GameData.ability_by_id[id].cooldown_s)
	return true


## Урон базовой атаки растёт с уровнем; бафф «усиление» умножает весь урон.
static func scaled(damage: float, level: int, buffed: bool) -> float:
	return damage * (1.0 + 0.06 * (level - 1)) * (1.5 if buffed else 1.0)
