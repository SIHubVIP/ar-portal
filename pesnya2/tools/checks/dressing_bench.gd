extends Node3D
## Замер (0.10): сколько стоит обставить участок района — улицы и фасады. Шаг участка
## в игре идёт кусками по 3 мс, но один кусок не должен быть тяжелее ~10 мс.
## godot --headless --path . res://tools/checks/dressing_bench.tscn


func _ready() -> void:
	var segs := District.road_segments()
	var tw := Time.get_ticks_usec()
	DistrictDressing.warm()
	print("BENCH warm %d us (на старте, под заставкой)" % (Time.get_ticks_usec() - tw))
	for plan in [Vector2(640, 2420), Vector2(1220, 1220), Vector2(1500, 1700)]:
		var c := District.chunk_of(plan)
		var root := Node3D.new()
		add_child(root)
		var b := DistrictDressing.Batch.new()
		var t0 := Time.get_ticks_usec()
		DistrictDressing.streets(root, c, segs, b)
		var t_streets := Time.get_ticks_usec() - t0
		var rng := RandomNumberGenerator.new()
		var worst := 0
		var n := 0
		for h in District.houses():
			if District.chunk_rect(c).has_point(h.get_center()):
				var t1 := Time.get_ticks_usec()
				DistrictDressing.facades(root, h, 18.0, segs, b, rng)
				worst = maxi(worst, Time.get_ticks_usec() - t1)
				n += 1
		var worst_job := 0
		var jobs := 0
		while not b.jobs.is_empty():
			var job: Callable = b.jobs.pop_front()
			var tj := Time.get_ticks_usec()
			job.call()
			var dt := Time.get_ticks_usec() - tj
			if dt > 4000:
				print("BENCH   slow job %s %d us" % [job.get_method(), dt])
			worst_job = maxi(worst_job, dt)
			jobs += 1
		print("BENCH   jobs=%d worst_job=%d us" % [jobs, worst_job])
		var t2 := Time.get_ticks_usec()
		DistrictDressing.flush(root, c, b)
		var counts := []
		for k in b.items:
			counts.append("%s=%d" % [k, b.items[k].size()])
		print("BENCH chunk %s streets=%d us houses=%d worst_house=%d us flush=%d us signs=%d lamps=%d" % [
				c, t_streets, n, worst, Time.get_ticks_usec() - t2, root.find_children("*", "Signboard", true, false).size(),
				b.lamps.size()])
		print("BENCH   ", ", ".join(counts))
	get_tree().quit()
