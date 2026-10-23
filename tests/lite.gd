extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var model := FWAuthoring.new()
	check(not model.paid and model.problems().is_empty(),"Lite edition and validation")
	model.profile.speed = 42
	model.profile.periods.names[1] = "Dawn"
	check(model.save_profile("res://upgrade-proof/lite.tres").is_empty(),"Lite profile save")
	check(model.generate_scene("res://upgrade-proof/clock.tscn").is_empty(),"Lite scene generation")
	var clock = load("res://upgrade-proof/clock.tscn").instantiate()
	root.add_child(clock)
	check(clock.period_at(400) == "Dawn" and clock.minutes_per_second == 42,"Lite linked runtime")
	clock.paused = true
	check(clock.skip_days(112) and clock.date_at().year == 2,"Lite year rollover")
	clock.free()
	var dock = load("res://addons/rpg_time/editor/dock.gd").new()
	root.add_child(dock)
	await process_frame
	check(dock.tabs.get_tab_count() == 7 and dock.preview != null,"Lite dock initializes without Paid scripts")
	check(not dock.has_unapplied,"Lite fields initialized")
	dock.fields.period_name.text = "Midnight"
	dock.apply_period()
	check(dock.model.profile.periods.names[0] == "Midnight","Lite period authoring")
	var before: int = dock.model.profile.initial_minute
	dock.step_preview(60)
	check(dock.preview.total_minutes == before+60 and dock.model.profile.initial_minute == before,"Lite sandbox isolation")
	dock.queue_free()
	await process_frame
	print("LITE: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)