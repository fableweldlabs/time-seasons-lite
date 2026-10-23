@tool
class_name FWAuthoring
extends RefCounted
signal changed
var paid: bool = ResourceLoader.exists("res://addons/rpg_time/paid/world_clock.gd")
var profile: FWTimeProfile
var source_path: String = ""
var dirty: bool = false
var history: Array[FWTimeProfile] = []
var position: int = -1

func _init() -> void:
	new_profile()

func copy(value: FWTimeProfile) -> FWTimeProfile:
	var result := FWTimeProfile.new()
	result.schema_version = value.schema_version
	result.initial_minute = value.initial_minute
	result.speed = value.speed
	result.start_paused = value.start_paused
	result.periods = value.periods.duplicate() if value.periods != null else null
	result.lighting = value.lighting.duplicate(true) if value.lighting != null else null
	result.calendar = value.calendar.duplicate() if value.calendar != null else null
	if result.periods != null:
		result.periods.names = value.periods.names.duplicate()
		result.periods.starts = value.periods.starts.duplicate()
	if result.calendar != null:
		result.calendar.month_names = value.calendar.month_names.duplicate()
		result.calendar.month_days = value.calendar.month_days.duplicate()
		result.calendar.season_names = value.calendar.season_names.duplicate()
		result.calendar.season_starts = value.calendar.season_starts.duplicate()
		result.calendar.week_day_names = value.calendar.week_day_names.duplicate()
		result.calendar.event_day_names = value.calendar.event_day_names.duplicate()
		result.calendar.event_day_indices = value.calendar.event_day_indices.duplicate()
	for event in value.events:
		result.events.append(event.duplicate() if event != null else null)
	for condition in value.conditions:
		var copied = condition.duplicate() if condition != null else null
		if copied != null:
			copied.periods = condition.periods.duplicate()
			copied.seasons = condition.seasons.duplicate()
			copied.weekdays = condition.weekdays.duplicate()
		result.conditions.append(copied)
	return result

func new_profile(earth: bool = false) -> void:
	profile = FWTimeProfile.new()
	if paid:
		profile.lighting = load("res://addons/rpg_time/paid/light_profile.gd").new()
		profile.calendar = load("res://addons/rpg_time/paid/calendar.gd").new()
		if earth:
			profile.calendar.calendar_id = "non-leap-365-v1"
			profile.calendar.month_names = ["January","February","March","April","May","June","July","August","September","October","November","December"]
			profile.calendar.month_days = [31,28,31,30,31,30,31,31,30,31,30,31]
			profile.calendar.season_starts = [0,90,181,273]
	source_path = ""
	dirty = true
	history.clear()
	position = -1
	remember()

func remember() -> void:
	history.resize(position + 1)
	history.append(copy(profile))
	if history.size() > 50:
		history.pop_front()
	position = history.size() - 1
	changed.emit()

func edit(operation: Callable) -> void:
	var next := copy(profile)
	operation.call(next)
	profile = next
	dirty = true
	remember()

func undo() -> void:
	if position > 0:
		position -= 1
		profile = copy(history[position])
		dirty = true
		changed.emit()

func redo() -> void:
	if position + 1 < history.size():
		position += 1
		profile = copy(history[position])
		dirty = true
		changed.emit()

func problems() -> PackedStringArray:
	return profile.problems(paid)

func allowed_path(path: String, extension: String) -> bool:
	return not ".." in path.split("/") and not "." in path.split("/") and not path.contains("\\") and path.begins_with("res://") and path == path.simplify_path() and not path.begins_with("res://addons/") and path.get_extension() == extension

func save_profile(path: String) -> String:
	if not allowed_path(path,"tres"):
		return "Use a res:// path outside addons, ending in .tres."
	if not problems().is_empty():
		return "Fix the validation messages before saving."
	if FileAccess.file_exists(path) and path != source_path:
		return "That file already exists. Load it first, or choose a new profile path."
	var error := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if error != OK:
		return "Could not create the profile folder: %s." % error_string(error)
	error = ResourceSaver.save(profile,path)
	if error != OK:
		return "Could not save the profile: %s." % error_string(error)
	profile.take_over_path(path)
	source_path = path
	dirty = false
	changed.emit()
	return ""

func load_profile(path: String) -> String:
	if not allowed_path(path,"tres") or not FileAccess.file_exists(path):
		return "Choose an existing .tres profile inside this trusted project, outside addons."
	var resource := ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE_DEEP)
	if not resource is FWTimeProfile:
		return "This file is not a Fableweld time profile."
	var upgraded := false
	if paid and resource.calendar == null and resource.events.is_empty() and resource.conditions.is_empty():
		resource = copy(resource)
		resource.calendar = load("res://addons/rpg_time/paid/calendar.gd").new()
		resource.lighting = load("res://addons/rpg_time/paid/light_profile.gd").new()
		upgraded = true
	var issues: PackedStringArray = resource.problems(paid)
	if not issues.is_empty():
		return "Profile rejected: " + "\n".join(issues)
	profile = copy(resource)
	source_path = path
	dirty = upgraded
	history.clear()
	position = -1
	remember()
	return ""

func generate_scene(path: String, mode: String = "clock") -> String:
	if dirty or source_path.is_empty():
		return "Save the profile before creating a linked clock scene."
	if not problems().is_empty() or not allowed_path(path,"tscn"):
		return "Fix validation and choose a res:// .tscn path outside addons."
	if FileAccess.file_exists(path):
		var existing := ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE)
		if not existing is PackedScene:
			return "The destination exists and is not a generated clock scene."
		var node: Node = existing.instantiate()
		var ours: bool = node.get_meta("fableweld_generated",false)
		node.free()
		if not ours:
			return "The destination is not owned by this tool. Choose another path."
	if not mode in ["clock","2d","3d"] or (mode != "clock" and not paid):
		return "Choose clock, 2d or 3d setup in the Paid edition."
	var saved_profile := ResourceLoader.load(source_path,"",ResourceLoader.CACHE_MODE_IGNORE_DEEP) as FWTimeProfile
	if saved_profile == null:
		return "Saved profile could not be reopened. Save again before generating."
	var clock: Node = preload("res://addons/rpg_time/editor/starter_builder.gd").build(saved_profile,mode)
	if clock == null:
		return "Could not build the clock. Check installed edition and profile."
	clock.name = "WorldTime" if mode == "clock" else "TimeRig"
	clock.set_meta("fableweld_generated",true)
	var scene := PackedScene.new()
	var result := scene.pack(clock)
	clock.free()
	if result != OK:
		return "Could not pack the clock scene."
	result = DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if result == OK:
		result = ResourceSaver.save(scene,path)
	return "" if result == OK else "Could not save scene: %s." % error_string(result)
func seasonal_template() -> void:
	if not paid: return
	new_profile()
	edit(func(p):
		var shop = load("res://addons/rpg_time/paid/condition.gd").new()
		shop.condition_id = "market"
		shop.seasons = PackedStringArray(["Spring","Summer"])
		shop.opens = 540
		shop.closes = 1020
		var encounter = load("res://addons/rpg_time/paid/condition.gd").new()
		encounter.condition_id = "winter_night"
		encounter.seasons = PackedStringArray(["Winter"])
		encounter.periods = PackedStringArray(["Night"])
		encounter.encounter_weight = 3
		p.conditions.clear()
		p.conditions.append(shop)
		p.conditions.append(encounter))
