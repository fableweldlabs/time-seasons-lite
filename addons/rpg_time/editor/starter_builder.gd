@tool
extends RefCounted
static func build(profile: FWTimeProfile, mode: String) -> Node:
	var clock := profile.make_clock()
	if clock == null: return null
	clock.name = "WorldTime"
	if mode == "clock": return clock
	var root: Node = Node2D.new() if mode == "2d" else Node3D.new()
	root.name = "TimeRig"
	root.add_child(clock)
	clock.owner = root
	var driver: Node
	if mode == "2d":
		driver = load("res://addons/rpg_time/paid/day_night_2d.gd").new()
	else:
		driver = load("res://addons/rpg_time/paid/day_night_3d.gd").new()
		var sun := DirectionalLight3D.new()
		sun.name = "Sun"
		sun.shadow_enabled = true
		root.add_child(sun)
		sun.owner = root
		var environment := WorldEnvironment.new()
		environment.name = "WorldEnvironment"
		environment.environment = Environment.new()
		environment.environment.background_mode = Environment.BG_COLOR
		environment.environment.background_color = Color("#243747")
		root.add_child(environment)
		environment.owner = root
		driver.sun_path = NodePath("../Sun")
		driver.environment_path = NodePath("../WorldEnvironment")
	driver.name = "DayNight"
	driver.clock_path = NodePath("../WorldTime")
	if profile.lighting != null: driver.lighting = profile.lighting
	root.add_child(driver)
	driver.owner = root
	var ui := CanvasLayer.new()
	ui.name = "ClockUI"
	root.add_child(ui)
	ui.owner = root
	var hud = load("res://addons/rpg_time/paid/clock_card.gd").new()
	hud.name = "Clock"
	hud.position = Vector2(24,24)
	hud.clock_path = NodePath("../../WorldTime")
	ui.add_child(hud)
	hud.owner = root
	var sleep = load("res://addons/rpg_time/paid/sleep_button.gd").new()
	sleep.name = "Sleep"
	sleep.text = "Sleep until 06:00"
	sleep.position = Vector2(24,240)
	sleep.clock_path = NodePath("../../WorldTime")
	ui.add_child(sleep)
	sleep.owner = root
	var bridge = load("res://addons/rpg_time/paid/event_bridge.gd").new()
	bridge.name = "TimeEvents"
	bridge.clock_path = NodePath("../WorldTime")
	root.add_child(bridge)
	bridge.owner = root
	if profile.condition("market") != null:
		var availability = load("res://addons/rpg_time/paid/seasonal_card.gd").new()
		availability.name = "SeasonalAvailability"
		availability.position = Vector2(24,310)
		availability.clock_path = NodePath("../../WorldTime")
		ui.add_child(availability)
		availability.owner = root
	return root


