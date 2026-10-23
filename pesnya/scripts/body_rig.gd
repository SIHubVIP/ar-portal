class_name BodyRig
extends Skeleton3D
## «Новый облик»: the skinned body follows the old animation pivots (body, head, arms, legs).
## Elbows and knees are not animated by the game code — they bend here from the arm / leg swing.

var piv: Array = []   # [body, head, arm_a, elbow_a, arm_b, elbow_b, leg_a, knee_a, leg_b, knee_b]
var hold := {}        # pivot index → fixed x-rotation (sitting, carrying), overrides the automatic bend


func _ready() -> void:
	process_priority = 50


func _process(_dt: float) -> void:
	if piv.size() < 10 or not is_visible_in_tree():
		return
	for k in [2, 4]:
		var arm: Node3D = piv[k]
		if not is_instance_valid(arm):
			return
		var f := -arm.rotation.x
		var bend := 0.2 + 0.55 * clampf(f, 0.0, 0.9)
		if f > 1.0:
			bend = lerpf(bend, 0.06, clampf((f - 1.0) / 0.6, 0.0, 1.0))
		bend += 0.25 * clampf(absf(arm.rotation.z) - 0.6, 0.0, 1.0)
		piv[k + 1].rotation.x = hold.get(k + 1, -bend)
	for k in [6, 8]:
		var leg: Node3D = piv[k]
		piv[k + 1].rotation.x = hold.get(k + 1, 0.05 + 0.95 * clampf(leg.rotation.x, 0.0, 0.85))
	for i in range(10):
		var n: Node3D = piv[i]
		set_bone_pose_position(i, n.position)
		set_bone_pose_rotation(i, n.quaternion)
		set_bone_pose_scale(i, n.scale)
