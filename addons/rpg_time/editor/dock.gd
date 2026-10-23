@tool
extends VBoxContainer
signal connect_scene_requested(mode: String)
## A focused editor workflow. All simulation is an isolated, disposable clock.
var model := FWAuthoring.new()
var section_picker: OptionButton
var tabs: TabContainer
var status: Label
var validation: Label
var heading: Label
var fields: Dictionary = {}
var lists: Dictionary = {}
var selected := {"month": 0, "season": 0, "period": 0, "event": 0, "rule": 0}
var preview: Node
var preview_running := false
var preview_output: Label
var preview_log: Array[String] = []
var season_checks: Dictionary = {}
var period_checks: Dictionary = {}
var weekday_checks: Array[CheckBox] = []
var rule_seasons: VBoxContainer
var rule_periods: VBoxContainer
var rule_days: HFlowContainer
var confirmation: ConfirmationDialog
var pending: Callable
var has_unapplied := false
var filling := false
var last_tab := 0
func mark_unapplied(_value: Variant = null) -> void:
	if not filling:
		has_unapplied = true
		status.text = "Draft fields changed. Click Apply in this tab, or Revert fields."

func _ready() -> void:
	custom_minimum_size = Vector2(300, 320)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",8)
	var brand_row := row(self)
	var brand_icon := TextureRect.new()
	brand_icon.name = "BrandMark"
	brand_icon.texture = preload("res://addons/rpg_time/core/brand.gd").texture()
	brand_icon.custom_minimum_size = Vector2(28,28)
	brand_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	brand_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	brand_row.add_child(brand_icon)
	heading = label(brand_row,"FABLEWELD LABS · WORLD TIME")
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_theme_color_override("font_color",Color("#EF8B9D"))
	heading.add_theme_font_size_override("font_size",19)
	var subtitle := label(self,"1. Configure   2. Save profile   3. Create clock scene")
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var history_row := row(self)
	button(history_row,"Undo",model.undo)
	button(history_row,"Redo",model.redo)
	button(history_row,"Revert fields",func():
		has_unapplied = false
		fill_forms()
		show_message("Fields restored from the profile."))
	status = label(self,"Start with a profile, then preview it before integration.")
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	section_picker = OptionButton.new()
	for section in ["Setup","Calendar","Periods","Events","Rules","Lighting","Preview"]: section_picker.add_item(section)
	section_picker.tooltip_text = "Go directly to any section, even in a narrow dock"
	add_child(section_picker)
	section_picker.item_selected.connect(func(index): tabs.current_tab = index)
	tabs = TabContainer.new()
	tabs.tab_changed.connect(func(index):
		if has_unapplied:
			tabs.set_deferred("current_tab",last_tab)
			show_message("Apply or Revert fields before changing tabs.")
		else:
			last_tab = index
		section_picker.select(last_tab))
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(tabs)
	setup_tab()
	calendar_tab()
	periods_tab()
	events_tab()
	rules_tab()
	lighting_tab()
	preview_tab()
	validation = label(self,"")
	validation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	confirmation = ConfirmationDialog.new()
	confirmation.dialog_text = "Discard unsaved profile changes?"
	confirmation.confirmed.connect(func(): if pending.is_valid(): pending.call())
	add_child(confirmation)
	model.changed.connect(refresh)
	refresh()

func label(parent: Node, value: String) -> Label:
	var control := Label.new()
	control.text = value
	control.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(control)
	return control

func row(parent: Node) -> HFlowContainer:
	var control := HFlowContainer.new()
	parent.add_child(control)
	return control

func button(parent: Node, text: String, action: Callable) -> Button:
	var control := Button.new()
	control.text = text
	style_button(control)
	control.pressed.connect(func():
		if has_unapplied and text in ["Undo","Redo","Add","Remove","↑","↓"]:
			show_message("Apply or Revert fields before this action.")
			return
		action.call())
	parent.add_child(control)
	return control

func page(title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation",8)
	scroll.add_child(box)
	return box

func text_field(parent: Node, key: String, caption: String) -> LineEdit:
	label(parent,caption)
	var control := LineEdit.new()
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(control)
	fields[key] = control
	if not key.ends_with("_path") and not key.begins_with("preview_"):
		control.text_changed.connect(mark_unapplied)
	return control

func number(parent: Node, key: String, caption: String, maximum: float, minimum: float = 0, step: float = 1) -> SpinBox:
	label(parent,caption)
	var control := SpinBox.new()
	control.min_value = minimum
	control.max_value = maximum
	control.step = step
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(control)
	fields[key] = control
	if not key.ends_with("_path") and not key.begins_with("preview_"):
		control.value_changed.connect(mark_unapplied)
	return control

func item_list(parent: Node, key: String) -> ItemList:
	var control := ItemList.new()
	control.custom_minimum_size.y = 100
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.item_selected.connect(func(index):
		if has_unapplied:
			control.select(selected[key])
			show_message("Apply or Revert fields before selecting another item.")
			return
		selected[key] = index
		fill_forms())
	parent.add_child(control)
	lists[key] = control
	return control

func explain(parent: Node, value: String) -> void:
	var text := label(parent,value)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func ask_discard(action: Callable) -> void:
	if model.dirty or has_unapplied:
		pending = action
		confirmation.popup_centered()
	else:
		action.call()

func setup_tab() -> void:
	var box := page("Setup")
	explain(box,"Start with four 28-day months. Paid also offers a familiar 365-day template without leap years. Nothing is added to your open scene automatically.")
	var presets := row(box)
	button(presets,"New default",func(): ask_discard(func(): model.new_profile()))
	if model.paid:
		button(presets,"365-day template",func(): ask_discard(func(): model.new_profile(true)))
		button(box,"Start with seasonal shop rules",func(): ask_discard(func(): model.seasonal_template()))
	text_field(box,"profile_path","Profile file (res://… .tres)").text = "res://time_seasons/world.tres"
	var files := row(box)
	button(files,"Save profile",save_profile)
	button(files,"Load profile",func(): ask_discard(load_profile))
	button(files,"Browse",browse_profile)
	number(box,"initial_day","Starting day (1 = first day)",694445,1)
	number(box,"initial_hour","Starting hour (0–23)",23)
	number(box,"initial_minute","Starting minute (0–59)",59)
	number(box,"speed","Real seconds per game day (0 = stopped)",1000000000,0,0.1)
	var pause := CheckBox.new()
	pause.text = "Start paused"
	box.add_child(pause)
	fields.paused = pause
	pause.toggled.connect(mark_unapplied)
	button(box,"Apply starting time & speed",apply_start)
	text_field(box,"scene_path","Clock scene to create (res://… .tscn)").text = "res://time_seasons/world_clock.tscn"
	button(box,"Create clock scene",generate_scene)
	if model.paid:
		button(box,"Create 2D lighting + clock rig",func(): generate_rig("2d"))
		button(box,"Create 3D lighting + clock rig",func(): generate_rig("3d"))
		button(box,"Connect current scene · 2D",func(): connect_scene_requested.emit("2d"))
		button(box,"Connect current scene · 3D",func(): connect_scene_requested.emit("3d"))
		explain(box,"Rigs include a linked clock, lighting, HUD and sleep button. Choose a new output filename for each rig. Use only one CanvasModulate per 2D canvas and one intended world environment; avoid adding a second rig to an already wired scene.")
	explain(box,"Then drag the generated scene from FileSystem into your world scene, or add it as your own autoload. Keep one authoritative clock per world. Generated scenes leave your world unchanged. Connect current scene adds an undoable driver using your existing lighting; no autoload or input-map changes.")
	explain(box,"Draft fields take effect only when you click Apply. Undo/Redo applies to this profile, up to 50 edits. Load only Resources from projects you trust.")

func calendar_tab() -> void:
	var box := page("Calendar")
	if not model.paid:
		explain(box,"Lite uses four 28-day months and Spring/Summer/Autumn/Winter. Custom calendar and season authoring is included in Paid.")
		return
	text_field(box,"calendar_id","Calendar ID (stable across compatible saves)")
	text_field(box,"week_names","Weekday names (comma-separated, starting at Day 1)")
	text_field(box,"event_days","Event days (day: label, comma-separated; for example 1: Founders Day)")
	button(box,"Apply calendar changes",apply_calendar_form)
	label(box,"Months — in year order")
	item_list(box,"month")
	text_field(box,"month_name","Month name")
	number(box,"month_days","Days in month",366,1)
	var actions := row(box)
	button(actions,"Apply",apply_month)
	button(actions,"Add",func():
		model.edit(func(p):
			p.calendar.month_names.append("Month %d" % (p.calendar.month_names.size()+1))
			p.calendar.month_days.append(28))
		selected.month = model.profile.calendar.month_names.size()-1
		refresh())
	button(actions,"Remove",func(): remove_entry("month"))
	button(actions,"↑",func(): move_month(-1))
	button(actions,"↓",func(): move_month(1))
	label(box,"Seasons — first starts on day 1")
	item_list(box,"season")
	text_field(box,"season_name","Season name (unique)")
	number(box,"season_day","First day of season (1-based day of year)",3660,1)
	actions = row(box)
	button(actions,"Apply",apply_season)
	button(actions,"Add",func():
		model.edit(func(p):
			p.calendar.season_names.append("Season %d" % (p.calendar.season_names.size()+1))
			p.calendar.season_starts.append(p.calendar.season_starts[-1]+1 if not p.calendar.season_starts.is_empty() else 0))
		selected.season = model.profile.calendar.season_names.size()-1
		refresh())
	button(actions,"Remove",func(): remove_entry("season"))
	explain(box,"Invalid drafts are retained for correction. Validation explains what blocks Save and Preview. Renaming a season also requires updating any condition that uses its old name.")

func periods_tab() -> void:
	var box := page("Periods")
	explain(box,"Periods cover the whole day. The first starts at 00:00; later starts increase. A repeated name, such as Night before and after midnight, is allowed.")
	item_list(box,"period")
	text_field(box,"period_name","Period name")
	number(box,"period_hour","Starts at hour",23)
	number(box,"period_minute","Starts at minute",59)
	var actions := row(box)
	button(actions,"Apply",apply_period)
	button(actions,"Add",func():
		model.edit(func(p):
			p.periods.names.append("New period")
			p.periods.starts.append(mini(1439,p.periods.starts[-1]+60) if not p.periods.starts.is_empty() else 0))
		selected.period = model.profile.periods.names.size()-1
		refresh())
	button(actions,"Remove",func(): remove_entry("period"))
	explain(box,"Changing period names can invalidate conditions that refer to them. Preview uses the exact same period data as your runtime clock.")

func events_tab() -> void:
	var box := page("Events")
	if not model.paid:
		explain(box,"Paid adds scheduled events, including delivery of every occurrence crossed during sleep or time skips.")
		return
	explain(box,"Events recur on absolute game minutes. Day 1 starts at midnight; a first event earlier than the starting time is already in the past.")
	item_list(box,"event")
	text_field(box,"event_id","Event ID (unique, for your signal handler)")
	number(box,"event_day","First occurrence: day",694445,1)
	number(box,"event_hour","Hour",23)
	number(box,"event_minute","Minute",59)
	label(box,"Repeats")
	var repeat := OptionButton.new()
	for name in ["Once","Daily","Weekly","Custom interval"]:
		repeat.add_item(name)
	box.add_child(repeat)
	fields.repeat = repeat
	repeat.item_selected.connect(mark_unapplied)
	number(box,"event_interval","Custom interval in game minutes",5256000,1)
	var actions := row(box)
	button(actions,"Apply",apply_event)
	button(actions,"Add",func():
		model.edit(func(p):
			var event = load("res://addons/rpg_time/paid/event.gd").new()
			event.event_id = "event_%d" % (p.events.size()+1)
			p.events.append(event))
		selected.event = model.profile.events.size()-1
		refresh())
	button(actions,"Remove",func(): remove_entry("event"))
	explain(box,"Connect scheduled_event(id, occurrence_minute). Events are sorted chronologically. A skip above 10,000 occurrences is rejected; use smaller steps. Monthly/date-relative recurrence is not included.")

func rules_tab() -> void:
	var box := page("Rules")
	if not model.paid:
		explain(box,"Paid adds shared opening schedules and encounter availability/weight conditions.")
		return
	explain(box,"Use the same condition type for a shop, NPC interaction, or encounter. Empty season/period/day selections mean any. All selected filter groups must match.")
	item_list(box,"rule")
	text_field(box,"rule_id","Condition ID (unique)")
	text_field(box,"rule_owner","Owner ID (optional; conflicts within the same owner)")
	text_field(box,"rule_group","Exclusive group (optional; overrides owner)")
	number(box,"opens_hour","Opens: hour (inclusive)",23)
	number(box,"opens_minute","Opens: minute",59)
	number(box,"closes_hour","Closes: hour (exclusive)",23)
	number(box,"closes_minute","Closes: minute",59)
	explain(box,"Equal opening and closing time means all day. Closing earlier than opening spans midnight. Weekday/season checks use the current day after midnight.")
	number(box,"weight","Encounter weight (0 excludes)",1000,0,0.1)
	number(box,"week_length","Days per week",32,1)
	label(box,"Available days (Day 1 is absolute day zero)")
	rule_days = HFlowContainer.new()
	box.add_child(rule_days)
	button(box,"Refresh day choices",refresh_weekdays)
	label(box,"Seasons")
	rule_seasons = VBoxContainer.new()
	box.add_child(rule_seasons)
	label(box,"Periods")
	rule_periods = VBoxContainer.new()
	box.add_child(rule_periods)
	var actions := row(box)
	button(actions,"Apply",apply_rule)
	button(actions,"Add",func():
		model.edit(func(p):
			var rule = load("res://addons/rpg_time/paid/condition.gd").new()
			rule.condition_id = "condition_%d" % (p.conditions.size()+1)
			p.conditions.append(rule))
		selected.rule = model.profile.conditions.size()-1
		refresh())
	button(actions,"Remove",func(): remove_entry("rule"))

func lighting_tab() -> void:
	var box := page("Lighting")
	if not model.paid:
		explain(box,"Paid includes basic 2D canvas tint and 3D sun/ambient drivers, linked to the same clock. No weather or advanced rendering.")
		return
	explain(box,"Simple stylized day/night defaults. Apply rebuilds the standard seven-key tint palette. Full custom gradients and the sun-energy curve are available on the profile in the Inspector; edit there instead to preserve custom keys.")
	for pair in [["night_color","Night tint"],["day_color","Day tint"]]:
		label(box,pair[1])
		var picker := ColorPickerButton.new()
		picker.custom_minimum_size.y = 32
		picker.color_changed.connect(mark_unapplied)
		box.add_child(picker)
		fields[pair[0]] = picker
	number(box,"night_ambient","Night ambient brightness (3D)",2,0,0.05)
	number(box,"day_ambient","Day ambient brightness (3D)",2,0,0.05)
	button(box,"Apply lighting",func():
		var night: Color = fields.night_color.color
		var day: Color = fields.day_color.color
		var night_level: float = fields.night_ambient.value
		var day_level: float = fields.day_ambient.value
		model.edit(func(p):
			var gradient := Gradient.new()
			gradient.offsets = PackedFloat32Array([0,0.2,0.25,0.5,0.75,0.8,1])
			gradient.colors = PackedColorArray([night,night,Color("#e6ad83"),day,Color("#e5a078"),night,night])
			p.lighting.canvas_tint = gradient
			p.lighting.night_ambient = night_level
			p.lighting.day_ambient = day_level))
	explain(box,"Save the profile, then create a 2D/3D rig on Setup. Existing scenes: attach the driver, assign clock_path and sun/environment paths as appropriate. Drivers refresh after load. 3D ambient edits use a private runtime Environment copy.")
	explain(box,"Keep your HUD on a separate CanvasLayer so world lighting does not dim interface text.")
func preview_tab() -> void:
	var box := page("Preview")
	explain(box,"Sandbox only. This does not alter your project profile, runtime clock, or saves. Editing the profile resets the sandbox. No game/editor window is launched.")
	var actions := row(box)
	button(actions,"Reset",reset_preview)
	button(actions,"Play / Pause",func():
		if preview != null:
			preview_running = not preview_running
			preview.paused = not preview_running)
	actions = row(box)
	button(actions,"+1 hour",func(): step_preview(60))
	button(actions,"+1 day",func(): step_preview(1440))
	button(actions,"Sleep to 06:00",func():
		if preview != null:
			if not preview.sleep_until(360): show_message("Sleep rejected; check limits/event count.")
			update_preview())
	number(box,"preview_day","Jump forward to day",694445,1)
	number(box,"preview_hour","Hour",23)
	number(box,"preview_minute","Minute",59)
	button(box,"Jump forward",func():
		if preview != null:
			var target := (int(fields.preview_day.value)-1)*1440 + int(fields.preview_hour.value)*60 + int(fields.preview_minute.value)
			step_preview(target-preview.total_minutes))
	preview_output = label(box,"")
	preview_output.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explain(box,"Period/season signals report final state only. Event log shows the latest eight crossed occurrences. ")

func selected_index(key: String, count: int) -> int:
	return clampi(selected[key],0,maxi(0,count-1))

func refresh() -> void:
	has_unapplied = false
	heading.text = "FABLEWELD LABS · %s%s" % ["Paid" if model.paid else "Lite"," · Unsaved changes" if model.dirty else " · Saved"]
	var errors := model.problems()
	validation.text = "Ready to save and preview." if errors.is_empty() else "Needs attention:\n• " + "\n• ".join(errors)
	validation.modulate = Color("#9bdfaa") if errors.is_empty() else Color("#ffcc80")
	var p := model.profile
	lists.period.clear()
	for i in range(p.periods.names.size()):
		var minute: int = p.periods.starts[i] if i < p.periods.starts.size() else 0
		lists.period.add_item("%02d:%02d  %s" % [minute/60,minute%60,p.periods.names[i]])
	if model.paid:
		lists.month.clear()
		for i in range(p.calendar.month_names.size()):
			lists.month.add_item("%s · %d days" % [p.calendar.month_names[i],p.calendar.month_days[i]])
		lists.season.clear()
		for i in range(p.calendar.season_names.size()):
			lists.season.add_item("%s · day %d" % [p.calendar.season_names[i],p.calendar.season_starts[i]+1])
		lists.event.clear()
		for event in p.events:
			lists.event.add_item("%s · day %d, %02d:%02d" % [event.event_id,event.first_minute/1440+1,event.first_minute%1440/60,event.first_minute%60])
		lists.rule.clear()
		for rule in p.conditions:
			lists.rule.add_item(rule.condition_id)
	for key in lists:
		if lists[key].item_count > 0:
			selected[key] = selected_index(key,lists[key].item_count)
			lists[key].select(selected[key])
	fill_forms()
	reset_preview()

func fill_forms() -> void:
	filling = true
	var p := model.profile
	fields.initial_day.value = p.initial_minute/1440+1
	fields.initial_hour.value = p.initial_minute%1440/60
	fields.initial_minute.value = p.initial_minute%60
	fields.speed.value = 0 if p.speed == 0 else 1440.0/p.speed
	fields.paused.button_pressed = p.start_paused
	if not p.periods.names.is_empty():
		var i := selected_index("period",p.periods.names.size())
		fields.period_name.text = p.periods.names[i]
		var minute: int = p.periods.starts[i] if i < p.periods.starts.size() else 0
		fields.period_hour.value = minute/60
		fields.period_minute.value = minute%60
	if not model.paid:
		filling = false
		return
	if p.lighting != null:
		fields.night_color.color = p.lighting.canvas_tint.sample(0)
		fields.day_color.color = p.lighting.canvas_tint.sample(0.5)
		fields.night_ambient.value = p.lighting.night_ambient
		fields.day_ambient.value = p.lighting.day_ambient
	fields.calendar_id.text = p.calendar.calendar_id
	fields.week_names.text = ", ".join(p.calendar.week_day_names)
	var calendar_events := PackedStringArray()
	for i in range(p.calendar.event_day_indices.size()):
		calendar_events.append("%d: %s" % [p.calendar.event_day_indices[i] + 1, p.calendar.event_day_names[i]])
	fields.event_days.text = ", ".join(calendar_events)
	if not p.calendar.month_names.is_empty():
		var i := selected_index("month",p.calendar.month_names.size())
		fields.month_name.text = p.calendar.month_names[i]
		fields.month_days.value = p.calendar.month_days[i]
	if not p.calendar.season_names.is_empty():
		var i := selected_index("season",p.calendar.season_names.size())
		fields.season_name.text = p.calendar.season_names[i]
		fields.season_day.value = p.calendar.season_starts[i]+1
	if not p.events.is_empty():
		var event = p.events[selected_index("event",p.events.size())]
		fields.event_id.text = event.event_id
		fields.event_day.value = event.first_minute/1440+1
		fields.event_hour.value = event.first_minute%1440/60
		fields.event_minute.value = event.first_minute%60
		fields.repeat.select(0 if event.interval_minutes == 0 else 1 if event.interval_minutes == 1440 else 2 if event.interval_minutes == 10080 else 3)
		fields.event_interval.value = maxi(1,event.interval_minutes)
	if not p.conditions.is_empty():
		var rule = p.conditions[selected_index("rule",p.conditions.size())]
		fields.rule_id.text = rule.condition_id
		fields.rule_owner.text = rule.owner_id
		fields.rule_group.text = rule.exclusive_group
		fields.opens_hour.value = rule.opens/60
		fields.opens_minute.value = rule.opens%60
		fields.closes_hour.value = rule.closes/60
		fields.closes_minute.value = rule.closes%60
		fields.week_length.value = rule.week_length
		fields.weight.value = rule.encounter_weight
	fill_filters()
	filling = false

func clear_children(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func fill_filters() -> void:
	if not model.paid:
		return
	clear_children(rule_seasons)
	clear_children(rule_periods)
	season_checks.clear()
	period_checks.clear()
	var rule = null if model.profile.conditions.is_empty() else model.profile.conditions[selected_index("rule",model.profile.conditions.size())]
	for name in model.profile.calendar.season_names:
		if season_checks.has(name):
			continue
		var check := CheckBox.new()
		check.toggled.connect(mark_unapplied)
		check.text = name
		check.button_pressed = rule != null and name in rule.seasons
		rule_seasons.add_child(check)
		season_checks[name] = check
	for name in model.profile.periods.names:
		if period_checks.has(name):
			continue
		var check := CheckBox.new()
		check.toggled.connect(mark_unapplied)
		check.text = name
		check.button_pressed = rule != null and name in rule.periods
		rule_periods.add_child(check)
		period_checks[name] = check
	refresh_weekdays()

func refresh_weekdays() -> void:
	clear_children(rule_days)
	weekday_checks.clear()
	var rule = null if model.profile.conditions.is_empty() else model.profile.conditions[selected_index("rule",model.profile.conditions.size())]
	for i in range(int(fields.week_length.value)):
		var check := CheckBox.new()
		check.toggled.connect(mark_unapplied)
		check.text = "Day %d" % (i+1)
		check.button_pressed = rule != null and i in rule.weekdays
		rule_days.add_child(check)
		weekday_checks.append(check)

func apply_start() -> void:
	var minute := (int(fields.initial_day.value)-1)*1440+int(fields.initial_hour.value)*60+int(fields.initial_minute.value)
	var seconds: float = fields.speed.value
	if seconds > 0 and seconds < 0.4:
		show_message("Day length must be 0 (stopped) or at least 0.4 real seconds.")
		return
	var speed: float = 0 if seconds == 0 else 1440.0/seconds
	var paused: bool = fields.paused.button_pressed
	model.edit(func(p):
		p.initial_minute = minute
		p.speed = speed
		p.start_paused = paused)

func apply_calendar_form() -> void:
	var month := selected_index("month",model.profile.calendar.month_names.size())
	var season := selected_index("season",model.profile.calendar.season_names.size())
	var id: String = fields.calendar_id.text.strip_edges()
	var month_name: String = fields.month_name.text.strip_edges()
	var days := int(fields.month_days.value)
	var season_name: String = fields.season_name.text.strip_edges()
	var day := int(fields.season_day.value)-1
	var week_names := PackedStringArray()
	for item in fields.week_names.text.split(",",false):
		week_names.append(item.strip_edges())
	var blank_weekday := week_names.is_empty()
	for weekday in week_names:
		if weekday.is_empty():
			blank_weekday = true
	if blank_weekday:
		show_message("Enter one or more weekday names, separated by commas.")
		return
	var event_names := PackedStringArray()
	var event_indices := PackedInt32Array()
	for item in fields.event_days.text.split(",",false):
		var pair: PackedStringArray = item.split(":",true,1)
		if pair.size() != 2 or not pair[0].strip_edges().is_valid_int() or pair[1].strip_edges().is_empty():
			show_message("Event days use day: label, separated by commas.")
			return
		event_indices.append(pair[0].strip_edges().to_int() - 1)
		event_names.append(pair[1].strip_edges())
	model.edit(func(p):
		p.calendar.calendar_id = id
		p.calendar.week_day_names = week_names
		p.calendar.event_day_names = event_names
		p.calendar.event_day_indices = event_indices
		if not p.calendar.month_names.is_empty():
			p.calendar.month_names[month] = month_name
			p.calendar.month_days[month] = days
		if not p.calendar.season_names.is_empty():
			p.calendar.season_names[season] = season_name
			p.calendar.season_starts[season] = day)

func apply_month() -> void:
	apply_calendar_form()
func apply_season() -> void:
	apply_calendar_form()
func apply_period() -> void:
	if model.profile.periods.names.is_empty(): return
	var i := selected_index("period",model.profile.periods.names.size())
	var name: String = fields.period_name.text.strip_edges()
	var minute := int(fields.period_hour.value)*60+int(fields.period_minute.value)
	model.edit(func(p):
		p.periods.names[i] = name
		p.periods.starts[i] = minute)

func apply_event() -> void:
	if model.profile.events.is_empty(): return
	var i := selected_index("event",model.profile.events.size())
	var id: String = fields.event_id.text.strip_edges()
	var minute := (int(fields.event_day.value)-1)*1440+int(fields.event_hour.value)*60+int(fields.event_minute.value)
	var interval: int = [0,1440,10080,int(fields.event_interval.value)][fields.repeat.selected]
	model.edit(func(p):
		p.events[i].event_id = id
		p.events[i].first_minute = minute
		p.events[i].interval_minutes = interval)

func apply_rule() -> void:
	if model.profile.conditions.is_empty(): return
	var i := selected_index("rule",model.profile.conditions.size())
	var id: String = fields.rule_id.text.strip_edges()
	var owner: String = fields.rule_owner.text.strip_edges()
	var group: String = fields.rule_group.text.strip_edges()
	var opens := int(fields.opens_hour.value)*60+int(fields.opens_minute.value)
	var closes := int(fields.closes_hour.value)*60+int(fields.closes_minute.value)
	var length := int(fields.week_length.value)
	var weight: float = fields.weight.value
	var seasons := PackedStringArray()
	var periods := PackedStringArray()
	var days := PackedInt32Array()
	for name in season_checks:
		if season_checks[name].button_pressed: seasons.append(name)
	for name in period_checks:
		if period_checks[name].button_pressed: periods.append(name)
	for day in range(weekday_checks.size()):
		if weekday_checks[day].button_pressed: days.append(day)
	model.edit(func(p):
		var rule = p.conditions[i]
		rule.condition_id = id
		rule.owner_id = owner
		rule.exclusive_group = group
		rule.opens = opens
		rule.closes = closes
		rule.week_length = length
		rule.encounter_weight = weight
		rule.seasons = seasons
		rule.periods = periods
		rule.weekdays = days)

func remove_entry(key: String) -> void:
	var p := model.profile
	var size: int = p.calendar.month_names.size() if key == "month" else p.calendar.season_names.size() if key == "season" else p.periods.names.size() if key == "period" else p.events.size() if key == "event" else p.conditions.size()
	if size == 0: return
	var i := selected_index(key,size)
	model.edit(func(value):
		match key:
			"month":
				value.calendar.month_names.remove_at(i)
				value.calendar.month_days.remove_at(i)
			"season":
				value.calendar.season_names.remove_at(i)
				value.calendar.season_starts.remove_at(i)
			"period":
				value.periods.names.remove_at(i)
				value.periods.starts.remove_at(i)
			"event": value.events.remove_at(i)
			"rule": value.conditions.remove_at(i)
	)

func move_month(direction: int) -> void:
	var i := selected_index("month",model.profile.calendar.month_names.size())
	var target := i+direction
	if target < 0 or target >= model.profile.calendar.month_names.size(): return
	model.edit(func(p):
		var name = p.calendar.month_names[i]
		var days = p.calendar.month_days[i]
		p.calendar.month_names[i] = p.calendar.month_names[target]
		p.calendar.month_days[i] = p.calendar.month_days[target]
		p.calendar.month_names[target] = name
		p.calendar.month_days[target] = days)
	selected.month = target
	refresh()

func show_message(message: String) -> void:
	status.text = message

func save_profile() -> void:
	if has_unapplied:
		show_message("Apply or Revert fields before saving.")
		return
	var error := model.save_profile(fields.profile_path.text.strip_edges())
	show_message("Profile saved. Create the clock scene next." if error.is_empty() else error)

func load_profile() -> void:
	var error := model.load_profile(fields.profile_path.text.strip_edges())
	show_message("Profile loaded." if error.is_empty() else error)

func browse_profile() -> void:
	var dialog := FileDialog.new()
	dialog.access = FileDialog.ACCESS_RESOURCES
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.filters = ["*.tres ; Fableweld time profile"]
	dialog.file_selected.connect(func(path):
		fields.profile_path.text = path
		ask_discard(load_profile))
	dialog.close_requested.connect(dialog.queue_free)
	dialog.file_selected.connect(func(_path): dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered(Vector2i(700,450))

func generate_rig(mode: String) -> void:
	if has_unapplied:
		show_message("Apply or Revert fields before generating.")
		return
	var error := model.generate_scene(fields.scene_path.text.strip_edges(),mode)
	show_message("Rig created. Drag it into your world; see Quick Start for existing lighting." if error.is_empty() else error)
	if error.is_empty() and Engine.is_editor_hint(): EditorInterface.get_resource_filesystem().scan()

func generate_scene() -> void:
	if has_unapplied:
		show_message("Apply or Revert fields before generating.")
		return
	var error := model.generate_scene(fields.scene_path.text.strip_edges())
	show_message("Clock scene created. Drag it into your world scene from FileSystem." if error.is_empty() else error)
	if error.is_empty() and Engine.is_editor_hint():
		EditorInterface.get_resource_filesystem().scan()

func reset_preview() -> void:
	preview_running = false
	preview_log.clear()
	if is_instance_valid(preview):
		remove_child(preview)
		preview.free()
	preview = null
	if model.problems().is_empty():
		preview = model.copy(model.profile).make_clock()
		if preview != null:
			add_child(preview)
			preview.set_process(false)
			preview.paused = true
			if preview.has_signal("scheduled_event"):
				preview.scheduled_event.connect(func(id,minute):
					preview_log.append("%s · absolute minute %d" % [id,minute])
					if preview_log.size() > 8: preview_log.pop_front())
	update_preview()

func step_preview(minutes: int) -> void:
	if preview == null:
		show_message("Fix profile validation before previewing.")
		return
	if not preview.advance(minutes):
		show_message("Skip rejected: move forward within time/event limits, or reset the sandbox.")
	update_preview()

func update_preview() -> void:
	if preview_output == null: return
	if preview == null:
		preview_output.text = "Preview unavailable until validation passes."
		return
	var date: Dictionary = preview.date_at()
	var text := "Year %d · Month %d · Day %d\n%02d:%02d · %s · %s\n%s" % [date.year,date.month,date.day,date.minute/60,date.minute%60,preview.season_at(),preview.period_at(),"Playing" if preview_running else "Paused"]
	for rule in model.profile.conditions:
		text += "\n%s: %s · weight %.2f" % [rule.condition_id,"available" if rule.allows(preview) else "closed / unavailable",rule.weight(preview)]
	if model.paid:
		var inspector = load("res://addons/rpg_time/paid/schedule_inspector.gd")
		if inspector != null:
			var inspection: Dictionary = inspector.preview(preview,model.profile.conditions,preview.total_minutes,1440,60)
			if not inspection.get("valid", false):
				text += "\n\nSchedule diagnostic unavailable: " + str(inspection.get("error", "Unknown limit."))
			elif not inspection.conflicts.is_empty():
				text += "\n\nDeclared schedule conflicts in next day:"
				for conflict in inspection.conflicts:
					text += "\n%02d:%02d · %s (%s)" % [conflict.minute % 1440 / 60,conflict.minute % 60,", ".join(conflict.condition_ids),conflict.conflict_key]
			elif not inspection.sampled_overlaps.is_empty():
				text += "\n\nSampled overlaps in next day (no shared owner/group):"
				for overlap in inspection.sampled_overlaps:
					text += "\n%02d:%02d · %s" % [overlap.minute % 1440 / 60,overlap.minute % 60,", ".join(overlap.condition_ids)]
	preview_output.text = text + "\n\nRecent events:\n" + "\n".join(preview_log)

func _process(delta: float) -> void:
	if preview_running and is_instance_valid(preview):
		if not preview.tick(delta):
			preview_running = false
			preview.paused = true
			show_message("Preview paused: elapsed time or event limit rejected. Try a smaller skip.")
		update_preview()

func _exit_tree() -> void:
	preview_running = false


func style_button(control: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#26365D")
	normal.border_color = Color("#526988")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(7)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 9
	normal.content_margin_bottom = 9
	var hover := normal.duplicate()
	hover.bg_color = Color("#354970")
	var focus := normal.duplicate()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("#EF8B9D")
	focus.set_border_width_all(2)
	control.add_theme_stylebox_override("normal",normal)
	control.add_theme_stylebox_override("hover",hover)
	control.add_theme_stylebox_override("focus",focus)
	control.add_theme_color_override("font_color",Color("#F4EFF4"))

