class_name HealthBar3D
extends Node3D
## Компактная полоска здоровья над врагом (как в Torchlight): видна, только когда враг ранен.

const WIDTH := 1.1
const HEIGHT := 0.11

var _fill: MeshInstance3D
var _back: MeshInstance3D


func _ready() -> void:
	_back = _quad(Vector2(WIDTH + 0.06, HEIGHT + 0.06), Color(0, 0, 0, 0.75), 0)
	_fill = _quad(Vector2(WIDTH, HEIGHT), Color(0.95, 0.2, 0.15), 1)
	visible = false


func _quad(size: Vector2, color: Color, priority: int) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = size
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.no_depth_test = true
	m.render_priority = priority
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


func set_ratio(r: float) -> void:
	r = clampf(r, 0.0, 1.0)
	visible = r < 1.0 and r > 0.0
	(_fill.mesh as QuadMesh).size.x = WIDTH * r
	# квад центрирован: сдвигаем в экранных осях через смещение центра по X билборда
	(_fill.mesh as QuadMesh).center_offset = Vector3(-WIDTH * (1.0 - r) / 2.0, 0, 0)
