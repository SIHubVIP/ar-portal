class_name GameData
## All tunable numbers and texts of «Песня» in one place.

const SAVE_PATH := "user://pesnya_save.json"
const SAVE_VERSION := 5

const ITEMS := {
	"seeds": {"name": "Семки", "rarity": 0, "slot": "", "power": 0, "desc": "Голубиная валюта. Баба Зина говорит, полезные."},
	"feather": {"name": "Пёрышко", "rarity": 0, "slot": "", "power": 0, "desc": "Мягкое. Можно щекотать врагов (нельзя)."},
	"crumbs": {"name": "Крошки батона", "rarity": 0, "slot": "", "power": 0, "desc": "Остатки голубиной роскоши."},
	"bolt": {"name": "Гайка от самоката", "rarity": 0, "slot": "", "power": 0, "desc": "Самокат без неё скрипит. Теперь скрипишь ты."},
	"dust": {"name": "Мешочек пыли", "rarity": 0, "slot": "", "power": 0, "desc": "Пылесос копил его годами."},
	"cap": {"name": "Кепка вымогателя", "rarity": 1, "slot": "head", "power": 4, "desc": "Восьмиклинка. +4 к силе и к понтам."},
	"chain": {"name": "Цепочка голубя", "rarity": 1, "slot": "neck", "power": 4, "desc": "Тонкая, но своя."},
	"sneaker": {"name": "Кроссовок-беглец", "rarity": 1, "slot": "feet", "power": 5, "desc": "Второй где-то во дворе."},
	"bell": {"name": "Звонок самоката", "rarity": 1, "slot": "neck", "power": 6, "desc": "Дзынь! Враги оборачиваются."},
	"filter": {"name": "Фильтр-нагрудник", "rarity": 1, "slot": "body", "power": 7, "desc": "Защищает от пыли и критики."},
	"mic": {"name": "Микрофон «Голубиный»", "rarity": 2, "slot": "weapon", "power": 12, "desc": "Воркует в бит. +12 к силе."},
	"turbo": {"name": "Турбо-кеды", "rarity": 2, "slot": "feet", "power": 11, "desc": "Сняты с самого быстрого самоката двора."},
	"hose": {"name": "Шланг-скакалка", "rarity": 2, "slot": "weapon", "power": 14, "desc": "Им можно и прыгать, и бить в такт."},
	"luck": {"name": "Перо удачи", "rarity": 2, "slot": "neck", "power": 10, "desc": "То самое перо, о котором шепчет весь двор."},
	"pakhan_cap": {"name": "Кепка Пахана", "rarity": 3, "slot": "head", "power": 25, "desc": "Легендарная. Голуби кланяются при виде."},
	# 0.3 — стройка Глушилки
	"lens": {"name": "Линза Тишинки", "rarity": 0, "slot": "", "power": 0, "desc": "В неё видно только тишину."},
	"foam": {"name": "Кусок поролона", "rarity": 0, "slot": "", "power": 0, "desc": "Им обита вся Глушилка. Мягко и скучно."},
	"helmet": {"name": "Каска прораба", "rarity": 1, "slot": "head", "power": 8, "desc": "Оранжевая. Защищает от кирпичей и плохих рифм."},
	"core": {"name": "Ядро Тишинки", "rarity": 1, "slot": "neck", "power": 9, "desc": "Гудит, если рядом кто-то не попадает в бит."},
	"rebar": {"name": "Арматура-метроном", "rarity": 2, "slot": "weapon", "power": 18, "desc": "Отбивает ритм сама. +18 к силе."},
	"vest": {"name": "Жилет сигнальный", "rarity": 2, "slot": "body", "power": 15, "desc": "Светится в темноте и на танцполе."},
	"megaphone": {"name": "Рупор Шумодава", "rarity": 3, "slot": "weapon", "power": 34, "desc": "Легендарный. Шептать в него запрещено."},
	# 0.4 — серверная Кощея
	"ears": {"name": "Уши робо-зайца", "rarity": 0, "slot": "", "power": 0, "desc": "Ловят Wi-Fi и сплетни."},
	"chip": {"name": "Микросхема тишины", "rarity": 0, "slot": "", "power": 0, "desc": "Отвечает за «ш-ш-ш». Больше не отвечает."},
	"duck": {"name": "Резиновая уточка", "rarity": 1, "slot": "neck", "power": 12, "desc": "Пищит в бит. ПИИ-ИК! Лучший отладчик."},
	"headset": {"name": "Корона-гарнитура", "rarity": 2, "slot": "head", "power": 22, "desc": "Серебряная. Звонки Кощею больше не приходят."},
	"turtleneck": {"name": "Водолазка технодиректора", "rarity": 2, "slot": "body", "power": 24, "desc": "Чёрная. Носишь — и хочется всё оптимизировать."},
	"gusli": {"name": "Гусли Кощея", "rarity": 3, "slot": "weapon", "power": 46, "desc": "Отобрал у соседа 500 лет назад. Теперь они звучат у тебя."},
	"flash": {"name": "Флешка «ПЕСНЯ_ФИНАЛ»", "rarity": 3, "slot": "neck", "power": 30, "desc": "Перепрошитое бессмертие. Внутри — только музыка."},
	# 0.5 — набережная и Змей Горыныч
	"gull_feather": {"name": "Перо чайки", "rarity": 0, "slot": "", "power": 0, "desc": "Пахнет рыбой и наглостью."},
	"cassette": {"name": "Кассета с джинглом", "rarity": 0, "slot": "", "power": 0, "desc": "Одна и та же песня. Тридцать раз подряд."},
	"keychain": {"name": "Колонка-брелок", "rarity": 1, "slot": "neck", "power": 14, "desc": "Маленькая, но басит."},
	"captain": {"name": "Фуражка капитана", "rarity": 2, "slot": "head", "power": 27, "desc": "Чайка носила её с гордостью. Теперь ты."},
	"phones": {"name": "Наушники Горыныча", "rarity": 3, "slot": "head", "power": 36, "desc": "Тройные. В каждом ухе — своя песня."},
	"jacket": {"name": "Чешуйчатая косуха", "rarity": 3, "slot": "body", "power": 40, "desc": "Сброшена Горынычем после линьки. Огнеупорная, стильная."},
	"golden_mic": {"name": "Микрофон «Золотой бит»", "rarity": 3, "slot": "weapon", "power": 54, "desc": "Награда двора. В него попадают даже те, кто не попадает в долю."},
}

const SELL_PRICE := [5, 20, 60, 0]

const MOBS := {
	"pigeon": {"name": "Голубь-вымогатель", "hp": [70.0, 32.0], "dmg": [5.0, 3.0], "xp": [24, 9], "scale": 0.72, "height": 3.0, "radius": 1.1,
		"speed": 4.4, "aggro": 7.0, "leash": 15.0, "atk": 1.5,
		"loot": [[0.05, "mic"], [0.22, "cap|chain|sneaker"], [0.7, "seeds|feather|crumbs"]], "res": []},
	"scooter": {"name": "Самокат-беглец", "hp": [45.0, 18.0], "dmg": [7.0, 3.0], "xp": [22, 8], "scale": 1.0, "height": 1.7, "radius": 0.6,
		"speed": 3.4, "aggro": 9.0, "leash": 18.0, "atk": 2.4,
		"loot": [[0.05, "turbo"], [0.2, "bell|sneaker"], [0.6, "bolt"]], "res": [[0.75, "wires", 1, 2]]},
	"vacuum": {"name": "Злой пылесос", "hp": [130.0, 40.0], "dmg": [7.0, 3.0], "xp": [36, 12], "scale": 1.0, "height": 1.6, "radius": 0.85,
		"speed": 2.3, "aggro": 6.5, "leash": 14.0, "atk": 1.8,
		"loot": [[0.06, "hose"], [0.22, "filter"], [0.6, "dust"]], "res": [[0.5, "cement", 1, 2], [0.6, "brick", 2, 3]]},
	"pakhan": {"name": "Голубиный Пахан", "hp": [1500.0, 0.0], "dmg": [26.0, 0.0], "xp": [420, 0], "scale": 1.25, "height": 3.0, "radius": 1.1,
		"speed": 3.6, "aggro": 12.0, "leash": 22.0, "atk": 1.8, "loot": [], "res": [], "boss": true},
	"drone": {"name": "Тишинка", "hp": [55.0, 24.0], "dmg": [6.0, 2.6], "xp": [30, 10], "scale": 1.0, "height": 2.7, "radius": 0.6,
		"speed": 3.4, "aggro": 10.0, "leash": 17.0, "atk": 2.6,
		"loot": [[0.04, "rebar|vest"], [0.18, "helmet|core"], [0.6, "lens|foam"]], "res": [[0.6, "wires", 1, 3], [0.3, "cement", 1, 2]]},
	"hare": {"name": "Робо-заяц", "hp": [95.0, 30.0], "dmg": [9.0, 3.2], "xp": [40, 12], "scale": 1.0, "height": 2.3, "radius": 0.6,
		"speed": 5.0, "aggro": 8.0, "leash": 16.0, "atk": 2.2,
		"loot": [[0.04, "headset|turtleneck"], [0.2, "duck|core"], [0.6, "ears|chip"]], "res": [[0.5, "wires", 2, 3]]},
	"safe_hare": {"name": "Заяц-сейф", "hp": [4000.0, 0.0], "dmg": [18.0, 0.0], "xp": [300, 0], "scale": 1.7, "height": 2.3, "radius": 0.7,
		"speed": 4.6, "aggro": 30.0, "leash": 60.0, "atk": 1.6, "loot": [], "res": [], "boss": true},
	"koschei": {"name": "Кощей Бессмертный", "hp": [11000.0, 0.0], "dmg": [30.0, 0.0], "xp": [900, 0], "scale": 1.0, "height": 3.0, "radius": 0.8,
		"speed": 3.0, "aggro": 30.0, "leash": 60.0, "atk": 1.8, "loot": [], "res": [], "boss": true},
	"gull": {"name": "Чайка-перекупщица", "hp": [110.0, 32.0], "dmg": [10.0, 3.4], "xp": [44, 13], "scale": 0.62, "height": 2.7, "radius": 0.9,
		"speed": 5.6, "aggro": 8.0, "leash": 16.0, "atk": 1.4,
		"loot": [[0.04, "captain"], [0.2, "keychain"], [0.6, "gull_feather|cassette"]], "res": [[0.4, "planks", 2, 4]]},
	"autoplay": {"name": "Колонка-автоплей", "hp": [180.0, 40.0], "dmg": [14.0, 3.0], "xp": [50, 14], "scale": 1.0, "height": 2.4, "radius": 0.8,
		"speed": 0.0, "aggro": 11.0, "leash": 99.0, "atk": 3.2,
		"loot": [[0.05, "captain"], [0.22, "keychain"], [0.6, "cassette"]], "res": [[0.6, "wires", 2, 4]]},
	"gorynych": {"name": "Змей Горыныч", "hp": [16000.0, 0.0], "dmg": [34.0, 0.0], "xp": [1000, 0], "scale": 1.0, "height": 6.4, "radius": 2.4,
		"speed": 2.4, "aggro": 16.0, "leash": 40.0, "atk": 2.2, "loot": [], "res": [], "boss": true},
	"shumodav": {"name": "Шумодав", "hp": [6500.0, 0.0], "dmg": [34.0, 0.0], "xp": [700, 0], "scale": 0.62, "height": 7.6, "radius": 2.6,
		"speed": 2.6, "aggro": 14.0, "leash": 30.0, "atk": 2.2, "loot": [], "res": [], "boss": true},
}

const RES_NAMES := {"brick": "Кирпич", "cement": "Цемент", "planks": "Доски", "wires": "Провода"}
const RES_ORDER := ["brick", "cement", "planks", "wires"]

# Buildings at the base. cost[level-1] = [coins, {res}]; effect[level-1] = value
const BUILDINGS := {
	"grill": {"name": "Мангал", "desc": "Жарит шаурму сам. Шаурма лечит 40% здоровья (кнопка еды в бою).",
		"cost": [[60, {"planks": 6, "brick": 4}], [200, {"planks": 12, "brick": 10, "wires": 2}], [500, {"planks": 20, "brick": 20, "cement": 6, "wires": 6}]],
		"period": [600, 420, 300], "cap": 5, "fx": "шаурма раз в %d мин"},
	"garden": {"name": "Огород", "desc": "Растит урожай, Люба покупает его за монеты.",
		"cost": [[50, {"planks": 8}], [180, {"planks": 14, "wires": 4}], [450, {"planks": 20, "cement": 8, "wires": 8}]],
		"period": [600, 600, 600], "coins": [25, 50, 90], "cap": 6, "fx": "+%d монет раз в 10 мин"},
	"gym": {"name": "Гаражный спортзал", "desc": "Качалка из покрышек и гантелей. Больше здоровья.",
		"cost": [[80, {"brick": 6, "wires": 2}], [250, {"brick": 14, "cement": 4, "wires": 4}], [600, {"brick": 24, "cement": 10, "wires": 8}]],
		"value": [0.08, 0.16, 0.25], "fx": "+%d%% к здоровью"},
	"stage": {"name": "Сцена", "desc": "Репетиции на публику. Вайб копится быстрее — ХИТ! чаще.",
		"cost": [[100, {"planks": 10, "wires": 4}], [300, {"planks": 16, "wires": 10}], [700, {"planks": 24, "cement": 6, "wires": 16}]],
		"value": [0.2, 0.4, 0.6], "fx": "+%d%% к вайбу"},
	"studio": {"name": "Студия", "desc": "Звукозапись в гараже. Твои удары звучат мощнее.",
		"cost": [[150, {"brick": 8, "cement": 4, "wires": 6}], [400, {"brick": 16, "cement": 8, "wires": 12}], [900, {"brick": 26, "cement": 14, "wires": 20}]],
		"value": [0.05, 0.1, 0.15], "fx": "+%d%% к урону"},
	"solar": {"name": "Солнечные панели", "desc": "Питают Васю. Он возвращается быстрее.",
		"cost": [[120, {"wires": 8, "brick": 4}], [300, {"wires": 14, "cement": 4}], [650, {"wires": 22, "cement": 10}]],
		"value": [0.15, 0.3, 0.45], "fx": "Вася быстрее на %d%%"},
}
const BUILD_ORDER := ["grill", "garden", "gym", "stage", "studio", "solar"]

# Robot errands: seconds, coin cost, reward
const ERRANDS := {
	"ezhik": {"name": "Гипермаркет «Ёжик»", "time": 180, "cost": 40, "res": {"planks": 6, "wires": 3}, "food": 1,
		"note": "Доски, провода и шаурма навынос"},
	"stroy": {"name": "Стройрынок", "time": 480, "cost": 100, "res": {"brick": 10, "cement": 5, "planks": 4}, "food": 0,
		"note": "Кирпич, цемент, доски"},
	"dump": {"name": "Свалка (бесплатно)", "time": 720, "cost": 0, "res": {"brick": 4, "planks": 4, "wires": 5}, "food": 0,
		"note": "Всего понемногу + шанс редкой вещи"},
}
const ERRAND_ORDER := ["ezhik", "stroy", "dump"]

const SHOP := [
	["food", "Шаурма", 30, 1, "Лечит 40% здоровья. Фирменная, с хрустом."],
	["planks", "Доски ×5", 60, 5, "Для мангала, огорода, сцены"],
	["brick", "Кирпич ×5", 70, 5, "Для спортзала и студии"],
	["wires", "Провода ×3", 60, 3, "Для студии и панелей"],
	["cement", "Цемент ×3", 70, 3, "Для улучшений"],
]

const DAILIES := [
	["pigeon", "Разогнать голубей", 8, 60, {"planks": 4}],
	["scooter", "Поймать самокаты", 3, 70, {"wires": 3}],
	["vacuum", "Выключить пылесосы", 2, 80, {"cement": 2, "brick": 4}],
]

# Map names (loading screen, minimap)
const MAP_NAMES := {"yard": "двор «Берёзки»", "garages": "ГК «Песня»", "stroyka": "стройку Глушилки", "server": "серверную Кощея",
	"embankment": "набережную и Калинов мост"}

# Quest 3 «Флешка Кощея»
const Q3_DRONES := 8
const MOUNT_SPEED := 11.0

# Quest 4 «Перепрошивка»
const Q4_HARES := 6
const RAP_LOCK := 4
const RAP_LINES := ["Тишина — не продукт,", "бит — не по подписке,", "открывай, железный друг,", "я пришёл без записки!"]

# 0.5: concert in ГК «Песня» and quest 5 «Бэкап Горыныча»
const Q5_SPEAKERS := 6
# note pattern in beats from the start (halves are off-beats); 48 beats ≈ 30 s at 96 BPM
const CONCERT_NOTES := [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10.5, 11, 12, 13, 14, 15, 16, 16.5, 17, 18, 19, 20, 21, 22, 22.5, 23,
	24, 25, 26, 27, 28, 28.5, 29, 29.5, 30, 32, 33, 34, 34.5, 35, 36, 37, 38, 38.5, 39, 40, 41, 42, 43, 44, 44.5, 45, 46, 47]
const CONCERT_LINES := ["Это песня, песня, песня во дворе,", "от балкона до гаража — в одной игре!", "Если стало тихо — не беда, не грусти:",
	"хлопни раз, хлопни два — и бит запусти!"]
