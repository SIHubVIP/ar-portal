class_name GameData
## All tunable numbers and texts of «Песня» in one place.

const SAVE_PATH := "user://pesnya_save.json"
const SAVE_VERSION := 7

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
	"pakhan_cap": {"name": "Кепка Пахана", "rarity": 3, "slot": "head", "power": 25, "lvl": 5, "desc": "Легендарная. Голуби кланяются при виде."},
	# 0.3 — стройка Глушилки
	"lens": {"name": "Линза Тишинки", "rarity": 0, "slot": "", "power": 0, "desc": "В неё видно только тишину."},
	"foam": {"name": "Кусок поролона", "rarity": 0, "slot": "", "power": 0, "desc": "Им обита вся Глушилка. Мягко и скучно."},
	"helmet": {"name": "Каска прораба", "rarity": 1, "slot": "head", "power": 8, "desc": "Оранжевая. Защищает от кирпичей и плохих рифм."},
	"core": {"name": "Ядро Тишинки", "rarity": 1, "slot": "neck", "power": 9, "desc": "Гудит, если рядом кто-то не попадает в бит."},
	"rebar": {"name": "Арматура-метроном", "rarity": 2, "slot": "weapon", "power": 18, "desc": "Отбивает ритм сама. +18 к силе."},
	"vest": {"name": "Жилет сигнальный", "rarity": 2, "slot": "body", "power": 15, "desc": "Светится в темноте и на танцполе."},
	"megaphone": {"name": "Рупор Шумодава", "rarity": 3, "slot": "weapon", "power": 34, "lvl": 8, "desc": "Легендарный. Шептать в него запрещено."},
	# 0.4 — серверная Кощея
	"ears": {"name": "Уши робо-зайца", "rarity": 0, "slot": "", "power": 0, "desc": "Ловят Wi-Fi и сплетни."},
	"chip": {"name": "Микросхема тишины", "rarity": 0, "slot": "", "power": 0, "desc": "Отвечает за «ш-ш-ш». Больше не отвечает."},
	"duck": {"name": "Резиновая уточка", "rarity": 1, "slot": "neck", "power": 12, "desc": "Пищит в бит. ПИИ-ИК! Лучший отладчик."},
	"headset": {"name": "Корона-гарнитура", "rarity": 2, "slot": "head", "power": 22, "desc": "Серебряная. Звонки Кощею больше не приходят."},
	"turtleneck": {"name": "Водолазка технодиректора", "rarity": 2, "slot": "body", "power": 24, "desc": "Чёрная. Носишь — и хочется всё оптимизировать."},
	"gusli": {"name": "Гусли Кощея", "rarity": 3, "slot": "weapon", "power": 46, "lvl": 10, "desc": "Отобрал у соседа 500 лет назад. Теперь они звучат у тебя."},
	"flash": {"name": "Флешка «ПЕСНЯ_ФИНАЛ»", "rarity": 3, "slot": "neck", "power": 30, "lvl": 9, "desc": "Перепрошитое бессмертие. Внутри — только музыка."},
	# 0.5 — набережная и Змей Горыныч
	"gull_feather": {"name": "Перо чайки", "rarity": 0, "slot": "", "power": 0, "desc": "Пахнет рыбой и наглостью."},
	"cassette": {"name": "Кассета с джинглом", "rarity": 0, "slot": "", "power": 0, "desc": "Одна и та же песня. Тридцать раз подряд."},
	"keychain": {"name": "Колонка-брелок", "rarity": 1, "slot": "neck", "power": 14, "desc": "Маленькая, но басит."},
	"captain": {"name": "Фуражка капитана", "rarity": 2, "slot": "head", "power": 27, "desc": "Чайка носила её с гордостью. Теперь ты."},
	"phones": {"name": "Наушники Горыныча", "rarity": 3, "slot": "head", "power": 36, "lvl": 10, "desc": "Тройные. В каждом ухе — своя песня."},
	"jacket": {"name": "Чешуйчатая косуха", "rarity": 3, "slot": "body", "power": 40, "lvl": 10, "desc": "Сброшена Горынычем после линьки. Огнеупорная, стильная."},
	"golden_mic": {"name": "Микрофон «Золотой бит»", "rarity": 3, "slot": "weapon", "power": 54, "lvl": 10, "desc": "Награда двора. В него попадают даже те, кто не попадает в долю."},
	# 0.6 — награды новых соседей (уникальные: Люба их не скупает)
	"boots_pavlin": {"name": "Бутсы Павлина Футболиста", "rarity": 2, "slot": "feet", "power": 12, "lvl": 3, "stats": {"luck": 3}, "unique": true,
		"desc": "Для газона, но по асфальту тоже. Шипы не царапают даже паркет."},
	"apron": {"name": "Фартук чистюли", "rarity": 2, "slot": "body", "power": 13, "lvl": 4, "stats": {"hp": 4}, "unique": true,
		"desc": "Белоснежный. Грязь к нему не липнет — стесняется."},
	"goggles": {"name": "Лётные очки Шустрого Пилота", "rarity": 2, "slot": "head", "power": 15, "lvl": 5, "stats": {"speed": 3}, "unique": true,
		"desc": "С ними бит видно заранее. И кашу на взлёте."},
	"gamepad": {"name": "Геймпад-брелок Кента Организатора", "rarity": 2, "slot": "neck", "power": 16, "lvl": 6, "stats": {"rhythm": 3}, "unique": true,
		"desc": "Кнопки нажимаются в такт. Кент Организатор проверял — десять из десяти."},
	"climb_shoes": {"name": "Кеды скалолаза", "rarity": 2, "slot": "feet", "power": 18, "lvl": 7, "stats": {"speed": 4}, "unique": true,
		"desc": "Липкие подошвы. По стенам — почти. По лужам — точно."},
	"beret": {"name": "Берет Товарища Клюквы", "rarity": 2, "slot": "head", "power": 24, "lvl": 9, "stats": {"hp": 5}, "unique": true,
		"desc": "Клюквенного цвета. Носить с честью, снимать — с разрешения."},
	"comb": {"name": "Каменный гребень", "rarity": 2, "slot": "weapon", "power": 26, "lvl": 9, "stats": {"rhythm": 4}, "unique": true,
		"desc": "Гребень Щебня Не Атлета. Им и бороду, и врагов — строго в ритм."},
	"phone": {"name": "Смартфон Мистера Малого", "rarity": 2, "slot": "neck", "power": 26, "lvl": 11, "stats": {"vibe": 5}, "unique": true,
		"desc": "Трещина на экране — это не баг, это стиль. Вайб на максималках."},
	"ladle": {"name": "Половник Меткого Змея", "rarity": 3, "slot": "weapon", "power": 50, "lvl": 12, "stats": {"luck": 5}, "unique": true,
		"desc": "Мешает уху и бьёт в бит. Ссссильная вещь."},
	"mill_cap": {"name": "Картуз Молодого Мельника", "rarity": 2, "slot": "head", "power": 30, "lvl": 12, "stats": {"luck": 4}, "unique": true,
		"desc": "Пахнет хлебом и квасом. Голуби снимают кепки при встрече."},
	"compass": {"name": "Компас Мыслителя Зари", "rarity": 3, "slot": "neck", "power": 34, "lvl": 13, "stats": {"speed": 4}, "unique": true,
		"desc": "Показывает не на север, а туда, где интересно."},
	"lantern": {"name": "Свет Ярика-Фонарика", "rarity": 3, "slot": "weapon", "power": 58, "lvl": 14, "stats": {"rhythm": 4, "vibe": 6}, "unique": true,
		"desc": "Тёплая искра Жар-птицы. Мигает точно в бит."},
	# 0.7 — парк «Заря»
	"grass": {"name": "Клок газона", "rarity": 0, "slot": "", "power": 0, "desc": "Подстрижен смайликом. Павлин Футболист бы заплакал."},
	"wrapper": {"name": "Фантик", "rarity": 0, "slot": "", "power": 0, "desc": "Шуршит сам по себе. Пакет-призрак ушёл не до конца."},
	"spring": {"name": "Пружинка робо-утки", "rarity": 0, "slot": "", "power": 0, "desc": "Делает «кря» упругим."},
	"pixel": {"name": "Битый пиксель", "rarity": 0, "slot": "", "power": 0, "desc": "Остался от кружочка загрузки. Всё ещё грузится."},
	"panama": {"name": "Панама садовника", "rarity": 1, "slot": "head", "power": 30, "lvl": 14, "desc": "От солнца, от дождя и от газонокосилок."},
	"pruner": {"name": "Секатор «Ровный газон»", "rarity": 2, "slot": "weapon", "power": 60, "lvl": 16, "desc": "Стрижёт строго в бит. Павлин Футболист одобряет."},
	"bag_cape": {"name": "Дождевик из пакета", "rarity": 1, "slot": "body", "power": 30, "lvl": 14, "desc": "Шуршит при ходьбе. Зато сухо."},
	"rustle_hoodie": {"name": "Худи «Шшш»", "rarity": 2, "slot": "body", "power": 46, "lvl": 16, "desc": "Тихое снаружи, громкое внутри."},
	"quack_whistle": {"name": "Свисток-кряква", "rarity": 1, "slot": "neck", "power": 28, "lvl": 15, "desc": "Свистит, как утка. Утки в шоке."},
	"flippers": {"name": "Ласты робо-утки", "rarity": 2, "slot": "feet", "power": 44, "lvl": 16, "desc": "Хлоп-хлоп в такт. По асфальту — тоже."},
	"spinner": {"name": "Спиннер загрузки", "rarity": 1, "slot": "neck", "power": 30, "lvl": 15, "desc": "Крутится вечно. Как обновление."},
	"visor99": {"name": "Козырёк «99%»", "rarity": 2, "slot": "head", "power": 48, "lvl": 17, "desc": "Показывает, что почти готово. Всегда."},
	"wheel_mic": {"name": "Микрофон «Спица»", "rarity": 3, "slot": "weapon", "power": 78, "lvl": 18, "desc": "Спица Колеса Обновлений. Звенит в бит, как велосипедный звонок."},
	"cabin_helmet": {"name": "Шлем «Кабинка»", "rarity": 3, "slot": "head", "power": 62, "lvl": 18, "desc": "С окошками. Обзор — как с самого верха колеса."},
	"dawn_bomber": {"name": "Бомбер «Заря»", "rarity": 3, "slot": "body", "power": 66, "lvl": 18, "desc": "Розовый, как рассвет без подписки."},
	# 0.7 — награды соседей (уникальные)
	"boomerang": {"name": "Мяч-бумеранг", "rarity": 2, "slot": "weapon", "power": 64, "lvl": 16, "stats": {"vibe": 5}, "unique": true,
		"desc": "Пнёшь — вернётся. Как слава Павлина Футболиста."},
	"spray_gloves": {"name": "Перчатки-брызгалки", "rarity": 2, "slot": "weapon", "power": 62, "lvl": 15, "stats": {"rhythm": 4}, "unique": true,
		"desc": "Брызгают точно в такт. Чисто и ритмично."},
	"pilot_scarf": {"name": "Шарф Шустрого Пилота", "rarity": 2, "slot": "neck", "power": 46, "lvl": 17, "stats": {"speed": 5}, "unique": true,
		"desc": "Тот самый, что улетел. Вернулся сам — он верный."},
	"grapple": {"name": "Верёвка-кошка", "rarity": 2, "slot": "neck", "power": 48, "lvl": 18, "stats": {"speed": 6}, "unique": true,
		"desc": "С ней Джек Скалолаз повесил флаг на самую верхнюю кабинку. Страховка прилагается."},
	"rhythm_medal": {"name": "Медаль «За ритм»", "rarity": 2, "slot": "neck", "power": 46, "lvl": 17, "stats": {"rhythm": 5, "hp": 3}, "unique": true,
		"desc": "Вручена Товарищем Клюквой. Неофициально, но от души."},
	"ring_lamp": {"name": "Кольцевая лампа", "rarity": 2, "slot": "neck", "power": 44, "lvl": 16, "stats": {"vibe": 6}, "unique": true,
		"desc": "Со стрима Мистера Малого. Светит так, что Горыныч улыбнулся. Трижды."},
	# 0.7 — лавка Сингл Принца (за золотые синглы)
	"prince_jacket": {"name": "Пиджак Сингл Принца", "rarity": 3, "slot": "body", "power": 64, "lvl": 16, "stats": {"vibe": 6, "luck": 4}, "unique": true,
		"desc": "Фиолетовый бархат, золотые погоны. «Это не скидка — это ремикс цены»."},
	"single_shades": {"name": "Очки «Сингл»", "rarity": 3, "slot": "head", "power": 58, "lvl": 15, "stats": {"rhythm": 6}, "unique": true,
		"desc": "Тёмные в любое время суток. Бит сквозь них видно лучше."},
	"plunger": {"name": "Вантуз Вентилёва", "rarity": 3, "slot": "weapon", "power": 76, "lvl": 17, "stats": {"luck": 4}, "unique": true,
		"desc": "Удар в бит оглушает врага на 0,8 с. «Чпок — и тишина»."},
	"crown_tilt": {"name": "Корона набок", "rarity": 3, "slot": "head", "power": 66, "lvl": 18, "stats": {"luck": 8}, "unique": true,
		"desc": "Маленькая, золотая, всегда чуть набекрень. Как у Сингл Принца."},
	"earbud": {"name": "Один наушник", "rarity": 3, "slot": "neck", "power": 54, "lvl": 16, "stats": {"rhythm": 4, "vibe": 4}, "unique": true,
		"desc": "Второй — у Сингл Принца. Сингл же."},
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
	# 0.7 — парк «Заря»
	"mower": {"name": "Газонокосилка-бунтарь", "hp": [150.0, 36.0], "dmg": [10.0, 3.3], "xp": [52, 14], "scale": 1.0, "height": 1.8, "radius": 0.8,
		"speed": 3.2, "aggro": 9.0, "leash": 18.0, "atk": 2.6,
		"loot": [[0.04, "pruner"], [0.18, "panama"], [0.6, "grass"]], "res": [[0.5, "planks", 2, 3], [0.3, "wires", 1, 2]]},
	"bag": {"name": "Пакет-призрак", "hp": [100.0, 28.0], "dmg": [9.0, 3.1], "xp": [48, 14], "scale": 1.0, "height": 2.4, "radius": 0.6,
		"speed": 4.4, "aggro": 9.5, "leash": 18.0, "atk": 1.9,
		"loot": [[0.04, "rustle_hoodie"], [0.18, "bag_cape"], [0.6, "wrapper"]], "res": [[0.4, "planks", 1, 3]]},
	"duck": {"name": "Робо-утка", "hp": [130.0, 32.0], "dmg": [10.0, 3.4], "xp": [54, 15], "scale": 1.0, "height": 1.9, "radius": 0.7,
		"speed": 2.8, "aggro": 11.0, "leash": 17.0, "atk": 2.8,
		"loot": [[0.04, "flippers"], [0.18, "quack_whistle"], [0.6, "spring"]], "res": [[0.5, "wires", 2, 3]]},
	"loader": {"name": "Кружочек загрузки", "hp": [90.0, 26.0], "dmg": [12.0, 3.6], "xp": [56, 15], "scale": 1.0, "height": 2.0, "radius": 0.6,
		"speed": 5.4, "aggro": 10.0, "leash": 18.0, "atk": 1.8,
		"loot": [[0.04, "visor99"], [0.18, "spinner"], [0.6, "pixel"]], "res": [[0.5, "wires", 1, 3], [0.3, "cement", 1, 2]]},
	"wheel": {"name": "Колесо Обновлений", "hp": [32000.0, 0.0], "dmg": [36.0, 0.0], "xp": [1400, 0], "scale": 1.0, "height": 10.0, "radius": 2.8,
		"speed": 0.0, "aggro": 20.0, "leash": 99.0, "atk": 2.4, "loot": [], "res": [], "boss": true},
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
	"embankment": "набережную и Калинов мост", "park": "парк «Заря»"}
const MAPS := ["yard", "garages", "stroyka", "server", "embankment", "park"]

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


# ================================================================== 0.6: levels 1–70 and item stats
const MAX_LEVEL := 70
const STAT_NAMES := {"rhythm": "Ритм", "luck": "Удача", "hp": "Стойкость", "speed": "Скорость", "vibe": "Вайб"}
const STAT_ORDER := ["rhythm", "luck", "hp", "speed", "vibe"]
const SLOT_STAT := {"head": "rhythm", "neck": "luck", "body": "hp", "feet": "speed", "weapon": "vibe"}
const SLOT_STAT_VAL := [0, 4, 7, 11]
const SLOT_NAMES := {"head": "голова", "neck": "шея", "body": "тело", "feet": "ноги", "weapon": "в руках"}


## Experience needed to go from level l to l + 1: gentle up to 10, then a steep curve.
static func xp_for_level(l: int) -> int:
	var base := 80 + l * 60
	if l < 10:
		return base
	return int(base + 22.0 * pow(float(l - 9), 2.2))


## Required level of a piece of equipment (explicit "lvl" or derived from its power, 1–10 for the old items).
static func item_level(it: Dictionary) -> int:
	if it.has("lvl"):
		return int(it.lvl)
	return clampi(int(it.power) / 5 + 1, 1, 10)


## Secondary stats: one by slot and rarity + the item's own bonus.
static func item_stats(it: Dictionary) -> Dictionary:
	var out := {}
	if str(it.slot) == "":
		return out
	var main: String = SLOT_STAT[it.slot]
	var v: int = SLOT_STAT_VAL[clampi(int(it.rarity), 0, 3)]
	if v > 0:
		out[main] = v
	var extra: Dictionary = it.get("stats", {})
	for k in extra:
		out[k] = int(out.get(k, 0)) + int(extra[k])
	return out


static func stats_text(st: Dictionary) -> String:
	var p := []
	for k in STAT_ORDER:
		if int(st.get(k, 0)) > 0:
			p.append("%s +%d" % [STAT_NAMES[k], int(st[k])])
	return " · ".join(p)


# ================================================================== 0.7: boss remixes, golden singles, Сингл Принц, the city map
## Boss remixes: re-fight a defeated boss at its arena (the «РЕМИКС» console). Loot (golden singles) once a day per boss.
const REMIX := {
	"pakhan": {"title": "Голубиный рэп", "map": "yard", "pos": Vector3(0, 0, -24), "lvl": 7, "need": ["quest", 5], "console": Vector3(-8.5, 0, -26.8), "rot": 0.0,
		"twist": "Зовёт голубей трижды за бой и кидается перьями-сюрикенами", "where": "двор, у гаражей", "items": ["pakhan_cap", "mic"]},
	"shumodav": {"title": "Бетонный бас", "map": "stroyka", "pos": Vector3(-18.5, 0, 0), "lvl": 10, "need": ["quest3", 6], "console": Vector3(-12.0, 0, 6.5), "rot": PI,
		"twist": "Шёпот тишины теперь идёт с басовыми волнами — перепрыгивай рывком", "where": "стройка, площадка у Глушилки", "npc": "shumodav",
		"items": ["megaphone", "vest", "rebar"]},
	"koschei": {"title": "Бессмертие 1.1", "map": "server", "pos": Vector3(-20, 0, 0), "lvl": 12, "need": ["quest4", 8], "console": Vector3(-6.5, 0, -4.6), "rot": 0.0,
		"twist": "Две подписки сразу: рэп-баттл до 5 ударов в бит", "where": "серверная, у железного дуба", "items": ["gusli", "headset", "turtleneck"]},
	"gorynych": {"title": "Три куплета", "map": "embankment", "pos": Vector3(-23, 0, -1.5), "lvl": 12, "need": ["quest5", 7], "console": Vector3(-27.5, 0, 2.8), "rot": PI,
		"twist": "Рекламные паузы без перерыва — все три головы поют до конца", "where": "набережная, у Калинова моста", "npc": "gorynych",
		"items": ["phones", "jacket"]},
	"wheel": {"title": "Бесконечная загрузка", "map": "park", "pos": Vector3(22, 0, 13), "lvl": 18, "need": ["quest6", 6], "console": Vector3(14.6, 0, 18.4), "rot": PI * 0.75,
		"twist": "Кружочки загрузки без конца и кольцо жёлтых кругов", "where": "парк «Заря», у колеса", "items": ["wheel_mic", "cabin_helmet", "dawn_bomber"]},
}
const REMIX_ORDER := ["pakhan", "shumodav", "koschei", "gorynych", "wheel"]
## [name, hp ×, damage ×, level +, golden singles]
const REMIX_DIFF := [["Демо", 1.0, 1.0, 0, 1], ["Сингл", 1.45, 1.2, 1, 2], ["Альбом", 2.0, 1.45, 2, 3], ["Платина", 2.8, 1.75, 3, 5]]
const REMIX_HP := {"pakhan": 0.7, "shumodav": 0.9, "koschei": 1.0, "gorynych": 1.1, "wheel": 1.15}

## Сингл Принц appears for 3 minutes; random visits every 30–40 minutes of play (after the first meeting)
const PRINCE_TIME := 180.0
const PRINCE_EVERY := [1800.0, 2400.0]
const PRINCE_SHOP := {
	"metronome": {"name": "Метроном Сингл Принца", "price": 4, "kind": "buff", "desc": "10 минут окно бита шире на 30 мс. «Это не чит — это ремикс времени»."},
	"pass": {"name": "Пропуск в ремикс", "price": 2, "kind": "pass", "desc": "+1 бой с добычей, если сегодня с этого босса ты её уже забрал."},
	"royal_food": {"name": "Шаурма «Королевская» ×3", "price": 1, "kind": "food", "desc": "Лечит как обычная, но ешь её как принц."},
	"prince_jacket": {"price": 12, "kind": "item"},
	"single_shades": {"price": 10, "kind": "item"},
	"plunger": {"price": 16, "kind": "item"},
	"crown_tilt": {"price": 15, "kind": "item"},
	"earbud": {"price": 9, "kind": "item"},
}
const METRONOME_SECS := 600.0
const METRONOME_WIN := 0.03

## Aerotaxi of Pilot «Ложка» (side quest «Воздушный патруль»)
const TAXI_COST := 25

## The city map of Рубин (screen coordinates 0..1 inside the map area)
const CITY_DISTRICTS := [
	["Над городом и за порталом", Rect2(0.01, 0.0, 0.98, 0.11)],
	["Новостройки", Rect2(0.01, 0.14, 0.25, 0.37)],
	["Центр «Берёзки»", Rect2(0.28, 0.14, 0.34, 0.37)],
	["Промзона", Rect2(0.64, 0.14, 0.35, 0.37)],
	["Окраина «Частный сектор»", Rect2(0.01, 0.54, 0.25, 0.28)],
	["Река", Rect2(0.28, 0.54, 0.71, 0.28)],
	["За городом и под землёй", Rect2(0.01, 0.85, 0.98, 0.14)],
]
const CITY_PLACES := [
	{"id": "yard", "name": "Двор «Берёзки»", "p": Vector2(0.40, 0.36), "map": "yard"},
	{"id": "garages", "name": "ГК «Песня»", "p": Vector2(0.53, 0.23), "map": "garages"},
	{"id": "stroyka", "name": "Стройка Глушилки", "p": Vector2(0.73, 0.25), "map": "stroyka", "up": true},
	{"id": "server", "name": "Серверная Кощея", "p": Vector2(0.73, 0.43), "map": "server"},
	{"id": "embankment", "name": "Набережная", "p": Vector2(0.42, 0.62), "map": "embankment", "up": true},
	{"id": "park", "name": "Парк «Заря»", "p": Vector2(0.42, 0.76), "map": "park"},
	{"id": "cheb", "name": "Чебуречная", "p": Vector2(0.33, 0.22), "ver": "0.8", "about": "Недоеденный пельмень и санузел-загадка"},
	{"id": "laundry", "name": "Прачечная", "p": Vector2(0.49, 0.46), "ver": "0.8", "about": "Сериал «Отжим» снимают прямо у стиралок"},
	{"id": "tower", "name": "Телебашня", "p": Vector2(0.59, 0.37), "ver": "1.0", "about": "Финал Части 2: здесь споёт Жар-птица"},
	{"id": "dump", "name": "Помойка", "p": Vector2(0.87, 0.22), "ver": "0.9", "about": "Дед Утиль и Кеша продают идеи построек"},
	{"id": "market", "name": "Рынок электроники", "p": Vector2(0.89, 0.34), "ver": "0.10", "about": "Подпольный склад светочастиц"},
	{"id": "taxi", "name": "Таксопарк", "p": Vector2(0.88, 0.46), "ver": "1.1", "about": "Внедорожник «Носорог» у вокзала"},
	{"id": "parkour", "name": "Паркур Парк", "p": Vector2(0.07, 0.24), "ver": "0.11", "about": "Ищем профи, чтобы расписать детсад"},
	{"id": "kinder", "name": "Детсад «Бабочка»", "p": Vector2(0.18, 0.35), "ver": "0.11", "about": "Плюшевый мишка Потапыч и детская Олимпиада"},
	{"id": "police", "name": "Полиция", "p": Vector2(0.08, 0.46), "ver": "1.4", "about": "Иностранец-халявщик Мистер Завтра"},
	{"id": "airsales", "name": "«Золотой воздух»", "p": Vector2(0.07, 0.62), "ver": "1.2", "about": "Золотые банки с воздухом прошлого"},
	{"id": "major", "name": "Участок Мажора", "p": Vector2(0.19, 0.69), "ver": "1.3", "about": "«Здоровая медицина» Мажора-Альфонса"},
	{"id": "sanat", "name": "Санаторий", "p": Vector2(0.08, 0.77), "ver": "1.5", "about": "Поддельные часы «Секундомер-Люкс»"},
	{"id": "politics", "name": "Парк Политиков", "p": Vector2(0.72, 0.72), "ver": "1.7", "about": "Парковка машины времени и полёт в космос"},
	{"id": "airfield", "name": "Аэродром «Турник»", "p": Vector2(0.12, 0.92), "ver": "1.6", "about": "Прыжки с парашютом на краю Рубина"},
	{"id": "metro", "name": "Метро-2", "p": Vector2(0.52, 0.92), "ver": "1.1", "about": "Станция в каждом районе"},
	{"id": "cloud", "name": "Облако №9", "p": Vector2(0.30, 0.055), "ver": "0.8", "about": "Дом Бога Здорово"},
	{"id": "orbit", "name": "Орбита", "p": Vector2(0.62, 0.055), "ver": "1.8", "about": "«Вечные часы» Кощея"},
	{"id": "portal", "name": "Тридевятое царство", "p": Vector2(0.88, 0.055), "ver": "1.9", "about": "Лукоморье и Кощеево царство"},
]
const CITY_LINKS := [["yard", "garages"], ["garages", "stroyka"], ["stroyka", "server"], ["yard", "embankment"], ["embankment", "park"]]
const CITY_INFO := {
	"yard": ["Голуби, самокаты, пылесосы · ур. 2–6", "Баба Зина, Люба, Дядя Миша, Павлин Футболист, Невысокий Лис", "Здесь всё начинается"],
	"garages": ["Твой бокс №40, постройки и Вася · концерт", "Петрович, Шустрый Пилот, Кент Организатор, Джек Скалолаз", "Двор → арка «ГК Песня» у гаражей"],
	"stroyka": ["Тишинки и самокаты · ур. 6–8", "Товарищ Клюква, Щебень Не Атлет, Шумодав", "ГК → западные ворота (путёвка Петровича)"],
	"server": ["Робо-зайцы · ур. 9–10", "Мистер Малой", "Стройка → лифт-Шумодав на крышу Глушилки"],
	"embankment": ["Колонки-автоплеи и чайки · ур. 9–10", "Меткий Змей, Молодой Мельник, Мыслитель Зари, Ярик-Фонарик, Змей Горыныч", "Двор → южная калитка"],
	"park": ["Газонокосилки, пакеты, робо-утки, кружочки · ур. 14–18", "Охранник Подписочкин · Колесо Обновлений", "Набережная → Калинов мост"],
}
