@tool
extends VBoxContainer
signal connect_scene_requested(mode: String)
const L = preload("res://addons/rpg_time/editor/localization.gd")
var language_picker: OptionButton
const UI = preload("res://addons/rpg_time/editor/polish.gd")
const FACE = preload("res://addons/rpg_time/editor/clock_face.gd")
var model := FWAuthoring.new()
var fields: Dictionary = {}
var tabs: TabContainer
var section_picker: OptionButton
var status: Label
var saved_label: Label
var validation: Label
var clock_label: Label
var date_label: Label
var period_label: Label
var dial: Control
var preview: Node
var preview_running := false
var has_unapplied := false
var filling := false
var selected_period := 0
var period_picker: OptionButton
var confirmation: ConfirmationDialog
var pending: Callable
var play_button: Button
var create_button: Button
var period_rows: VBoxContainer
var details: VBoxContainer

func _ready() -> void:
	if Engine.is_editor_hint():
		L.set_locale(str(EditorInterface.get_editor_settings().get_project_metadata("fableweld_time","language","en")),false)
	custom_minimum_size = Vector2(290,320)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	theme = UI.theme()
	var head := HBoxContainer.new()
	add_child(head)
	var mark := TextureRect.new()
	mark.texture = preload("res://addons/rpg_time/core/brand.gd").texture()
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.custom_minimum_size = Vector2(38,38)
	head.add_child(mark)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(words)
	UI.text(words,"Time & Seasons",21)
	UI.text(words,"F A B L E W E L D   L A B S",10,UI.ROSE)
	var language_row := HBoxContainer.new()
	add_child(language_row)
	UI.text(language_row,"Language",13,UI.MUTED)
	language_picker = OptionButton.new()
	language_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for title in L.NAMES: language_picker.add_item(title)
	language_picker.select(L.CODES.find(L.locale()))
	language_picker.tooltip_text = L.t("Language applies to this addon only. Your saved names and game language stay unchanged.")
	language_row.add_child(language_picker)
	language_picker.item_selected.connect(change_language)
	saved_label = UI.text(self,"New world · not saved yet",12,UI.MUTED)
	section_picker = OptionButton.new()
	for title in ["1  Set up your world","2  Shape the day","3  Try your clock"]: section_picker.add_item(L.t(title))
	section_picker.custom_minimum_size.y = 42
	add_child(section_picker)
	tabs = TabContainer.new()
	tabs.tabs_visible = false
	tabs.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(tabs)
	section_picker.item_selected.connect(func(index):
		if has_unapplied:
			section_picker.select(tabs.current_tab)
			show_message("Apply your changes, or choose Revert edits before moving on.")
			return
		tabs.current_tab = index)
	setup_page()
	period_page()
	preview_page()
	status = UI.text(self,"Ready when you are.",13,UI.MUTED)
	validation = UI.text(self,"",12,Color("#F6C991"))
	confirmation = ConfirmationDialog.new()
	confirmation.title = L.t("Start again?")
	confirmation.dialog_text = L.t("Your unsaved changes will be lost. Saved files will stay where they are.")
	confirmation.confirmed.connect(func():
		if pending.is_valid(): pending.call())
	add_child(confirmation)
	for dynamic_label in [saved_label,clock_label,date_label,period_label,validation]:
		if dynamic_label.has_meta("fw_source_text"): dynamic_label.remove_meta("fw_source_text")
	model.changed.connect(refresh)
	refresh()

func page(title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	return box

func flow(parent: Node) -> HFlowContainer:
	var row := HFlowContainer.new()
	parent.add_child(row)
	return row

func number(parent: Node, key: String, caption: String, maximum: float, minimum: float = 0, step: float = 1) -> SpinBox:
	UI.text(parent,caption,13,UI.MUTED)
	var field := SpinBox.new()
	field.min_value = minimum
	field.max_value = maximum
	field.step = step
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.custom_minimum_size.y = 36
	parent.add_child(field)
	fields[key] = field
	field.value_changed.connect(mark_unapplied)
	return field

func path_field(parent: Node, key: String, caption: String, value: String) -> void:
	UI.text(parent,caption,12,UI.MUTED)
	var edit := LineEdit.new()
	edit.text = value
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.custom_minimum_size.y = 36
	parent.add_child(edit)
	fields[key] = edit

func setup_page() -> void:
	var box := page("Your world")
	var intro := UI.card(box,"Make time feel alive","A gentle morning. A changing season. Start with a clock that fits your world.")
	UI.text(intro,"Four seasons · 28 days each",13,UI.ROSE)
	var start := UI.card(box,"Choose a beginning")
	number(start,"initial_day","Starting day",694445,1)
	var times := HBoxContainer.new()
	start.add_child(times)
	for pair in [["initial_hour","Hour",23],["initial_minute","Minute",59]]:
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		times.add_child(col)
		number(col,pair[0],pair[1],pair[2])
	number(start,"speed","Real seconds in one game day",1000000000,0,0.1)
	UI.text(start,"For example, 600 makes a day last 10 minutes. Use 0 to keep time still.",12,UI.MUTED)
	var paused := CheckBox.new()
	L.bind_text(paused,"Start with the clock paused")
	start.add_child(paused)
	fields.paused = paused
	paused.toggled.connect(mark_unapplied)
	UI.button(start,"Apply these settings",apply_start)
	var install := UI.card(box,"Bring it into your game","Save your settings, then create a clock you can drag into your world scene.")
	UI.button(install,"Save world settings…",choose_save,true)
	create_button = UI.button(install,"Create my clock…",choose_scene)
	UI.button(install,"Open saved settings…",choose_load)
	UI.button(box,"File locations & history",func(): details.visible = not details.visible)
	details = VBoxContainer.new()
	details.visible = false
	box.add_child(details)
	path_field(details,"profile_path","Settings file","res://time_seasons/world.tres")
	path_field(details,"scene_path","Clock scene","res://time_seasons/world_clock.tscn")
	var actions := flow(details)
	UI.button(actions,"Undo",func():
		if guard(): model.undo())
	UI.button(actions,"Redo",func():
		if guard(): model.redo())
	UI.button(actions,"New world",func(): ask_discard(func(): model.new_profile()))
	UI.button(actions,"Revert edits",refresh)
	UI.text(details,"Keep your settings and generated scenes outside the add-on folder so updates leave them safe.",12,UI.MUTED)

func period_page() -> void:
	var box := page("Day rhythm")
	var overview := UI.card(box,"Find your daily rhythm","Choose when morning begins and when the world settles into night.")
	period_rows = VBoxContainer.new()
	overview.add_child(period_rows)
	var edit := UI.card(box,"Adjust a part of the day")
	period_picker = OptionButton.new()
	period_picker.custom_minimum_size.y = 38
	edit.add_child(period_picker)
	period_picker.item_selected.connect(func(index):
		if not guard():
			period_picker.select(selected_period)
			return
		selected_period = index
		fill_period())
	UI.text(edit,"Name",13,UI.MUTED)
	var name_field := LineEdit.new()
	name_field.custom_minimum_size.y = 36
	edit.add_child(name_field)
	fields.period_name = name_field
	name_field.text_changed.connect(mark_unapplied)
	number(edit,"period_hour","Begins at hour",23)
	number(edit,"period_minute","Minute",59)
	var actions := flow(edit)
	UI.button(actions,"Apply change",apply_period,true)
	UI.button(actions,"Add a period",add_period)
	UI.button(actions,"Remove",remove_period)
	UI.button(edit,"Revert edits",refresh)
	UI.text(edit,"The first part begins at midnight. Each start comes after the previous one. Night may appear at both ends of the day.",12,UI.MUTED)

func preview_page() -> void:
	var box := page("Your clock")
	var card := UI.card(box,"A little time to explore","This is a safe preview. Your saved world stays untouched.")
	period_label = UI.text(card,"Morning",15,UI.ROSE)
	period_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dial = FACE.new()
	card.add_child(dial)
	clock_label = UI.text(card,"08:00",42)
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	date_label = UI.text(card,"Spring · Day 1 · Year 1",14,UI.MUTED)
	date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	play_button = UI.button(card,"Play preview",toggle_preview,true)
	var actions := flow(card)
	UI.button(actions,"One hour later",func(): step_preview(60))
	UI.button(actions,"Next morning",func():
		if preview != null:
			preview.sleep_until(360)
			update_preview())
	UI.button(actions,"Next day",func(): step_preview(1440))
	UI.button(actions,"Next season",next_season)
	UI.button(card,"Back to your starting time",reset_preview)
	UI.text(box,"Want your game to react? The optional Lumen Vale example project shows how a clock can change a shop sign. Download it separately from our website; it is not required to use this addon.",13,UI.MUTED)

func next_season() -> void:
	if preview != null: step_preview((28-int(preview.total_minutes/1440)%28)*1440)

func mark_unapplied(_value: Variant = null) -> void:
	if filling: return
	has_unapplied = true
	if status != null: show_message("You've made changes. Apply them, or choose Revert edits.")

func guard() -> bool:
	if has_unapplied:
		show_message("Apply your changes first, or choose Revert edits.")
		return false
	return true

func ask_discard(action: Callable) -> void:
	if model.dirty or has_unapplied:
		pending = action
		confirmation.popup_centered()
	else: action.call()

func apply_start() -> void:
	var seconds: float = fields.speed.value
	if seconds > 0 and seconds < 0.4:
		show_message("Choose at least 0.4 seconds for a day, or 0 to stop the clock.")
		return
	var minute := (int(fields.initial_day.value)-1)*1440+int(fields.initial_hour.value)*60+int(fields.initial_minute.value)
	var paused: bool = fields.paused.button_pressed
	model.edit(func(p):
		p.initial_minute = minute
		p.speed = 0.0 if seconds == 0 else 1440.0/seconds
		p.start_paused = paused)
	show_message("Starting time updated. Save when you're ready.")

func apply_period() -> void:
	var draft := FWPeriods.new()
	draft.names = model.profile.periods.names.duplicate()
	draft.starts = model.profile.periods.starts.duplicate()
	draft.names[selected_period] = fields.period_name.text.strip_edges()
	draft.starts[selected_period] = int(fields.period_hour.value)*60+int(fields.period_minute.value)
	var issues := draft.problems()
	if not issues.is_empty():
		show_message("Please check this change: " + " ".join(issues))
		return
	model.edit(func(p): p.periods = draft)
	show_message("Day rhythm updated.")

func add_period() -> void:
	if not guard(): return
	var last: int = model.profile.periods.starts[-1]
	if last >= 1439:
		show_message("Move the last period earlier to make space for another.")
		return
	selected_period = model.profile.periods.names.size()
	model.edit(func(p):
		p.periods.names.append("Late night")
		p.periods.starts.append(mini(1439,last+30)))

func remove_period() -> void:
	if not guard(): return
	if selected_period == 0:
		show_message("Keep the midnight period so every moment of the day is covered.")
		return
	var index := selected_period
	selected_period -= 1
	model.edit(func(p):
		p.periods.names.remove_at(index)
		p.periods.starts.remove_at(index))

func fill_period() -> void:
	filling = true
	selected_period = clampi(selected_period,0,model.profile.periods.names.size()-1)
	fields.period_name.text = model.profile.periods.names[selected_period]
	fields.period_hour.value = model.profile.periods.starts[selected_period]/60
	fields.period_minute.value = model.profile.periods.starts[selected_period]%60
	period_picker.select(selected_period)
	filling = false

func refresh() -> void:
	filling = true
	has_unapplied = false
	var p := model.profile
	fields.initial_day.value = p.initial_minute/1440+1
	fields.initial_hour.value = p.initial_minute%1440/60
	fields.initial_minute.value = p.initial_minute%60
	fields.speed.value = 0 if p.speed == 0 else 1440.0/p.speed
	fields.paused.button_pressed = p.start_paused
	for child in period_rows.get_children():
		period_rows.remove_child(child)
		child.queue_free()
	period_picker.clear()
	for i in range(p.periods.names.size()):
		var minute: int = p.periods.starts[i]
		var caption := "%02d:%02d   %s" % [minute/60,minute%60,p.periods.names[i]]
		period_picker.add_item(caption)
		UI.text(period_rows,caption,14,UI.MUTED)
	fill_period()
	var issues := model.problems()
	validation.text = "" if issues.is_empty() else L.t("Please check: ") + " ".join(Array(issues).map(L.message))
	saved_label.text = (L.t("Unsaved world") if model.source_path.is_empty() else model.source_path.get_file().get_basename().capitalize()) + (L.t(" · changes to save") if model.dirty else L.t(" · saved"))
	create_button.disabled = model.dirty or model.source_path.is_empty() or not issues.is_empty()
	create_button.tooltip_text = L.t("Save your world settings first") if create_button.disabled else L.t("Choose where your new clock scene will live")
	filling = false
	reset_preview()

func show_message(message: String) -> void:
	if status != null:
		status.set_meta("fw_source_text",message)
		status.text = L.message(message)

func chooser(mode: FileDialog.FileMode, filter: String, path: String, action: Callable) -> void:
	var dialog := FileDialog.new()
	dialog.file_mode = mode
	dialog.access = FileDialog.ACCESS_RESOURCES
	var parts := filter.split(" ; ")
	dialog.filters = PackedStringArray([parts[0] + " ; " + L.t(parts[1])])
	dialog.current_path = path
	dialog.title = L.t("Choose a place in your project")
	dialog.file_selected.connect(func(value):
		action.call(value)
		dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered(Vector2i(720,480))

func choose_save() -> void:
	if not guard(): return
	chooser(FileDialog.FILE_MODE_SAVE_FILE,"*.tres ; World settings",fields.profile_path.text,func(path):
		fields.profile_path.text = path
		save_profile())

func choose_load() -> void:
	ask_discard(func(): chooser(FileDialog.FILE_MODE_OPEN_FILE,"*.tres ; World settings",fields.profile_path.text,func(path):
		fields.profile_path.text = path
		load_profile()))

func choose_scene() -> void:
	if not guard(): return
	chooser(FileDialog.FILE_MODE_SAVE_FILE,"*.tscn ; Clock scene",fields.scene_path.text,func(path):
		fields.scene_path.text = path
		generate_scene())

func save_profile() -> void:
	if not guard(): return
	var error := model.save_profile(fields.profile_path.text.strip_edges())
	show_message("World settings saved. Next, create your clock." if error.is_empty() else error)
	scan_files(error)

func load_profile() -> void:
	var error := model.load_profile(fields.profile_path.text.strip_edges())
	show_message("Your world settings are open." if error.is_empty() else error)

func generate_scene() -> void:
	if not guard(): return
	var error := model.generate_scene(fields.scene_path.text.strip_edges())
	show_message("Your clock is ready. Drag it from FileSystem into your world scene." if error.is_empty() else error)
	scan_files(error)

func scan_files(error: String) -> void:
	if error.is_empty() and Engine.is_editor_hint(): EditorInterface.get_resource_filesystem().scan()

func reset_preview() -> void:
	preview_running = false
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
	update_preview()

func toggle_preview() -> void:
	if preview == null: return
	preview_running = not preview_running
	preview.paused = not preview_running
	update_preview()

func step_preview(minutes: int) -> void:
	if preview == null or not preview.advance(minutes): show_message("Try a smaller jump, or return to your starting time.")
	update_preview()

func update_preview() -> void:
	if clock_label == null or preview == null: return
	var date: Dictionary = preview.date_at()
	clock_label.text = "%02d:%02d" % [date.minute/60,date.minute%60]
	date_label.text = L.t("%s · Day %d · Year %d") % [L.t(preview.season_at()),date.day,date.year]
	period_label.text = preview.period_at()
	dial.minute = date.minute
	play_button.set_meta("fw_source_text","Pause preview" if preview_running else "Play preview")
	play_button.text = L.t("Pause preview" if preview_running else "Play preview")

func _process(delta: float) -> void:
	if preview_running and is_instance_valid(preview):
		if not preview.tick(delta):
			preview_running = false
			preview.paused = true
			show_message("The preview reached its safe limit. Return to your starting time to continue.")
		update_preview()

func change_language(index: int) -> void:
	if index < 0 or index >= L.CODES.size(): return
	language_picker.select(index)
	L.set_locale(L.CODES[index])
	if Engine.is_editor_hint(): EditorInterface.get_editor_settings().set_project_metadata("fableweld_time","language",L.CODES[index])
	L.apply(self)
	for i in range(3):
		section_picker.set_item_text(i,L.t(["1  Set up your world","2  Shape the day","3  Try your clock"][i]))
	confirmation.title = L.t("Start again?")
	confirmation.dialog_text = L.t("Your unsaved changes will be lost. Saved files will stay where they are.")
	language_picker.tooltip_text = L.t("Language applies to this addon only. Your saved names and game language stay unchanged.")
	saved_label.text = (L.t("Unsaved world") if model.source_path.is_empty() else model.source_path.get_file().get_basename().capitalize()) + (L.t(" · changes to save") if model.dirty else L.t(" · saved"))
	create_button.tooltip_text = L.t("Save your world settings first") if create_button.disabled else L.t("Choose where your new clock scene will live")
	update_preview()
