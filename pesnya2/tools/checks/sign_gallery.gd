extends Node3D
## Витрина вывесок (0.10): все стили Signboard на тёмной кирпичной стене, ночь.
## godot --path . res://tools/checks/sign_gallery.tscn -- --shot=user://signs.png


func _ready() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.03, 0.03, 0.06)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.25, 0.22, 0.3)
	env.environment.glow_enabled = true
	env.environment.glow_intensity = 0.9
	env.environment.glow_bloom = 0.03
	env.environment.glow_hdr_threshold = 0.9
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(env)
	var wall := Kit.box(self, Vector3(24, 9, 0.4), Vector3(0, 4.5, -0.2), Color(0.45, 0.28, 0.22))
	Surfaces.brick_all(wall)
	Kit.box(self, Vector3(24, 0.1, 8), Vector3(0, -0.05, 4), Color(0.18, 0.18, 0.2))
	Signboard.make(self, "ПАРКОВКА ПЛАТНАЯ.\nСОН ТОЖЕ.", "lightbox", Color.WHITE, Vector3(-7, 6.3, 0), 0, 0.55)
	Signboard.make(self, "НЛО\nНАПРОКАТ", "neon", Color(1.0, 0.3, 0.85), Vector3(0, 6.3, 0), 0, 0.6, {"icon": "ufo"})
	Signboard.make(self, "РЫНОК\nСЫТЫЙ КОНЕЦ", "letters", Color(1.0, 0.25, 0.2), Vector3(7, 6.6, 0), 0, 0.75)
	Signboard.make(self, "ТАКСИ", "board", Color(0.1, 0.08, 0.05), Vector3(-8, 3.0, 0), 0, 0.6, {"lamp": true})
	Signboard.make(self, "БОЛЬШЕ\nЧЕМ\nЛЮДИ", "poster", Color(0.75, 0.1, 0.08), Vector3(-3.5, 2.6, 0), 0, 0.4)
	Signboard.make(self, "СВЕЖЕЕ\nДЕШЕВЛЕ,\nЧЕМ ЗАВТРА", "chalk", Color(0.95, 0.95, 0.9), Vector3(0, 2.4, 0), 0, 0.3)
	Signboard.make(self, "ГЛ'ОРП — ЛОХ", "graffiti", Color(0.3, 1, 0.85), Vector3(4.5, 1.6, 0), 0, 0.6)
	Signboard.make(self, "Аптека «Здоровье по подписке»", "lightbox", Color.WHITE, Vector3(7.5, 3.4, 0), 0, 0.35,
			{"bg": Color(0.3, 0.85, 0.45), "ink": Color(1, 1, 1)})
	var key := OmniLight3D.new()
	key.position = Vector3(0, 3, 5)
	key.omni_range = 14
	key.light_energy = 0.6
	add_child(key)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 4.2, 13)
	cam.fov = 60
	add_child(cam)
	cam.look_at(Vector3(0, 4.2, 0), Vector3.UP)
