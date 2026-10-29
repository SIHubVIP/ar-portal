class_name MobTypes
extends RefCounted
## Десять уличных мобов манифеста «Погуляй» (mob_01 … mob_10). Имена — из манифеста,
## цифры — предложение для балансировки (в ТЗ их нет, D-039). Каждый тип отличается
## поведением, а не только цветом:
##   melee  — бьёт кругом вокруг себя;
##   ranged — держит дистанцию и кидает удар кругом под ноги герою, снаряд видно в полёте;
##   lunge  — рывок: круг под героем, в конце телеграфа моб прыгает в центр.

const PROFILES := {
	"mob_01": {"name": "Дрон-лайкомёт", "hp": 32.0, "speed": 3.4, "damage": 8.0, "kind": "ranged", "range": 8.0,
			"radius": 1.6, "telegraph": 0.9, "cd": 2.2, "fly": true, "xp": 14, "babki": 8, "look": "drone",
			"color": Color(0.85, 0.3, 0.55), "bark": "Лайк — это насилие с согласия!"},
	"mob_02": {"name": "Охранник клуба «Без слуха»", "hp": 95.0, "speed": 2.5, "damage": 17.0, "kind": "melee",
			"radius": 2.3, "telegraph": 1.1, "cd": 2.0, "xp": 30, "babki": 18, "look": "brute",
			"color": Color(0.12, 0.12, 0.14), "bark": "Фейс-контроль! Лицо не прошло."},
	"mob_03": {"name": "Гастрономический слизень", "hp": 55.0, "speed": 1.9, "damage": 9.0, "kind": "melee",
			"radius": 2.7, "telegraph": 1.0, "cd": 1.8, "xp": 16, "babki": 6, "look": "slime",
			"color": Color(0.55, 0.8, 0.25), "bark": "Буль. Сегодня в меню — ты."},
	"mob_04": {"name": "Патрульный цензор", "hp": 60.0, "speed": 2.9, "damage": 11.0, "kind": "ranged", "range": 7.0,
			"radius": 2.0, "telegraph": 1.0, "cd": 2.4, "xp": 22, "babki": 14, "look": "officer",
			"color": Color(0.25, 0.3, 0.55), "bark": "Это высказывание не согласовано!"},
	"mob_05": {"name": "Хлопающий мутант", "hp": 38.0, "speed": 4.4, "damage": 8.0, "kind": "melee",
			"radius": 1.8, "telegraph": 0.6, "cd": 1.3, "xp": 14, "babki": 7, "look": "mutant",
			"color": Color(0.85, 0.6, 0.5), "bark": "Браво! Браво! БРАВО!!!"},
	"mob_06": {"name": "Курьер пропусков", "hp": 34.0, "speed": 5.6, "damage": 12.0, "kind": "lunge", "range": 6.0,
			"radius": 1.7, "telegraph": 0.75, "cd": 2.0, "xp": 18, "babki": 12, "look": "courier",
			"color": Color(0.95, 0.6, 0.1), "bark": "Пропуск на выдох оформлен? Нет? Доставка!"},
	"mob_07": {"name": "Дрон осветитель", "hp": 28.0, "speed": 3.0, "damage": 10.0, "kind": "ranged", "range": 9.0,
			"radius": 3.0, "telegraph": 1.3, "cd": 2.8, "fly": true, "xp": 16, "babki": 9, "look": "lamp",
			"color": Color(1.0, 0.95, 0.6), "bark": "Улыбнитесь, вас освещают!"},
	"mob_08": {"name": "Пустоглазый бармен", "hp": 52.0, "speed": 3.0, "damage": 12.0, "kind": "ranged", "range": 7.5,
			"radius": 1.8, "telegraph": 0.9, "cd": 2.0, "xp": 20, "babki": 16, "look": "barman",
			"color": Color(0.9, 0.9, 0.88), "bark": "Тебе как обычно? Бутылкой?"},
	"mob_09": {"name": "Мутант-очередник", "hp": 44.0, "speed": 2.7, "damage": 9.0, "kind": "melee",
			"radius": 1.9, "telegraph": 0.85, "cd": 1.6, "xp": 15, "babki": 8, "look": "queuer",
			"color": Color(0.5, 0.45, 0.4), "bark": "Я тут с четверга стою! Без очереди не пущу!"},
	"mob_10": {"name": "Дорожный паразит", "hp": 24.0, "speed": 5.0, "damage": 6.0, "kind": "lunge", "range": 5.0,
			"radius": 1.4, "telegraph": 0.6, "cd": 1.9, "xp": 10, "babki": 5, "look": "crawler",
			"color": Color(0.55, 0.45, 0.35), "bark": "Хрррр… яма — мой дом."},
}


const HUMAN_BASE_Y := 0.85   # высота тела наземного моба (EnemyDrone._base_y)


static func profile(id: String) -> Dictionary:
	return PROFILES.get(id, {})


## Тело моба из простых фигур: силуэт читается с изометрической камеры.
static func build_body(body: Node3D, id: String) -> void:
	var p := profile(id)
	var c: Color = p.get("color", Color.WHITE)
	var skin := Color(0.82, 0.68, 0.58)
	match String(p.get("look", "")):
		"drone":
			Kit.sphere(body, 0.45, Vector3.ZERO, c)
			Kit.cylinder(body, 0.8, 0.07, Vector3.ZERO, Color(0.25, 0.25, 0.3))
			Kit.box(body, Vector3(0.5, 0.35, 0.05), Vector3(0, 0.35, 0.3), Color(1, 0.3, 0.6), 2.0)   # экран с сердечком
			Kit.sphere(body, 0.12, Vector3(0, 0, 0.4), Color(1, 0.15, 0.3), 3.0)
		"lamp":
			Kit.cylinder(body, 0.4, 0.5, Vector3.ZERO, Color(0.3, 0.3, 0.35), 0.0, 0.25)
			Kit.cylinder(body, 0.45, 0.06, Vector3(0, -0.28, 0), c, 3.0)
			Kit.cylinder(body, 0.9, 0.05, Vector3(0, 0.3, 0), Color(0.2, 0.2, 0.25))
		"brute":
			var l := _human(body, {"top": c, "bottom": c, "style": "bald", "height": 1.2, "width": 1.35,
					"skin": Color(0.75, 0.58, 0.46)})
			Kit.box(body, Vector3(0.3, 0.06, 0.04), _on(l, Vector3(0, 1.75, 0.13)), Color(0.02, 0.02, 0.02))   # очки
			Kit.box(body, Vector3(0.16, 0.05, 0.03), _on(l, Vector3(-0.1, 1.42, 0.13)), Color(0.9, 0.8, 0.2), 1.5)  # бейдж
		"slime":
			var s := Kit.sphere(body, 0.8, Vector3(0, -0.3, 0), Color(c, 0.85), 0.4)
			s.scale = Vector3(1.3, 0.7, 1.3)
			Kit.sphere(body, 0.14, Vector3(-0.25, 0.1, 0.65), Color.WHITE)
			Kit.sphere(body, 0.14, Vector3(0.25, 0.15, 0.6), Color.WHITE)
			Kit.cylinder(body, 0.12, 0.1, Vector3(0.1, 0.25, 0.1), Color(0.9, 0.85, 0.7))           # макаронина
		"officer":
			var l := _human(body, {"top": c, "bottom": c.darkened(0.4), "style": "short", "height": 1.05})
			Kit.cylinder(body, 0.17, 0.08, _on(l, Vector3(0, 1.86, 0)), c.darkened(0.3))                    # фуражка
			Kit.box(body, Vector3(0.24, 0.02, 0.1), _on(l, Vector3(0, 1.84, 0.12)), Color(0.05, 0.05, 0.05))   # козырёк
			Kit.box(body, Vector3(0.12, 0.08, 0.14), _on(l, Vector3(0.23, 1.3, 0.0)), Color(1, 0.1, 0.1), 2.0) # повязка «ЦЕНЗОР»
			Kit.cylinder(body, 0.1, 0.28, _on(l, Vector3(-0.26, 0.95, 0.15)), Color(0.9, 0.9, 0.9), 0.0, 0.05) \
					.rotation_degrees.x = 90.0                                                                  # мегафон
		"mutant":
			var l := _human(body, {"skin": c, "top": c.darkened(0.25), "bottom": c.darkened(0.5), "style": "bald",
					"height": 1.0, "width": 1.1})
			Kit.box(body, Vector3(0.2, 0.05, 0.03), _on(l, Vector3(0, 1.66, 0.12)), Color(0.9, 0.1, 0.1))     # рот до ушей
			for sx in [-1.0, 1.0]:
				Kit.sphere(body, 0.13, _on(l, Vector3(sx * 0.26, 0.9, 0.06)), c)                             # ладони-лопаты
		"courier":
			var l := _human(body, {"top": Color(0.2, 0.2, 0.22), "bottom": Color(0.15, 0.15, 0.17), "height": 0.98})
			Kit.box(body, Vector3(0.55, 0.55, 0.35), _on(l, Vector3(0, 1.25, -0.32)), c, 0.4)                 # короб
			Kit.cylinder(body, 0.15, 0.08, _on(l, Vector3(0, 1.86, 0)), c)                                  # кепка
		"barman":
			var l := _human(body, {"top": Color(0.1, 0.1, 0.1), "bottom": Color(0.1, 0.1, 0.1), "style": "short",
					"hair": Color(0.05, 0.05, 0.05), "skin": Color(0.72, 0.72, 0.76), "height": 1.08})
			Kit.box(body, Vector3(0.34, 0.6, 0.03), _on(l, Vector3(0, 1.0, 0.15)), c)                         # фартук
			for sx in [-1.0, 1.0]:
				Kit.sphere(body, 0.035, _on(l, Vector3(sx * 0.045, 1.75, 0.125)), Color(0, 0, 0))              # пустые глаза
			Kit.cylinder(body, 0.05, 0.3, _on(l, Vector3(-0.26, 0.95, 0.04)), Color(0.2, 0.6, 0.3), 0.6)     # бутылка
		"queuer":
			var l := _human(body, {"skin": c.lightened(0.3), "top": c, "bottom": c.darkened(0.4), "style": "bald",
					"height": 0.95})
			(body.get_node("Model") as Node3D).rotation_degrees.x = 18.0                                      # сутулый
			Kit.box(body, Vector3(0.22, 0.3, 0.02), _on(l, Vector3(-0.26, 1.0, 0.25)), Color(0.95, 0.95, 0.9))  # справка
		"crawler":
			# размером с крышку люка: ниже героя, но читается сверху
			var b := Kit.sphere(body, 0.7, Vector3(0, -0.45, 0), c)
			b.scale = Vector3(1.4, 0.55, 1.8)
			for i in 3:
				Kit.box(body, Vector3(2.3, 0.08, 0.1), Vector3(0, -0.6, -0.55 + i * 0.55), Color(0.15, 0.15, 0.15))
			Kit.sphere(body, 0.12, Vector3(-0.22, -0.2, 1.15), Color(1, 0.8, 0.1), 3.0)
			Kit.sphere(body, 0.12, Vector3(0.22, -0.2, 1.15), Color(1, 0.8, 0.1), 3.0)


## Человек из NpcModel внутри тела моба: тело висит на высоте BASE_Y, ноги — на земле.
static func _human(body: Node3D, look: Dictionary) -> Dictionary:
	var l := NpcModel.random_look(RandomNumberGenerator.new())
	l.merge({"skirt": false}, true)
	l.merge(look, true)
	var m := NpcModel.make(l)
	m.name = "Model"
	m.position.y = -HUMAN_BASE_Y
	body.add_child(m)
	return l


static func _on(l: Dictionary, p: Vector3) -> Vector3:
	return NpcModel.at(l, p) - Vector3(0, HUMAN_BASE_Y, 0)
