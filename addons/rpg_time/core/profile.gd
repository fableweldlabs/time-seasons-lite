@tool
class_name FWTimeProfile
extends Resource
## Authoring data shared between the editor and the generated runtime clock.
@export var schema_version: int = 1
@export var initial_minute: int = 480
@export var speed: float = 1.0
@export var start_paused: bool = false
@export var periods: FWPeriods = FWPeriods.new()
@export var lighting: Resource
@export var calendar: Resource
@export var events: Array[Resource] = []
@export var conditions: Array[Resource] = []

func problems(paid: bool = true) -> PackedStringArray:
	var errors := PackedStringArray()
	if schema_version != 1:
		errors.append("Unsupported profile version. Use a matching add-on or migrate the profile.")
	if initial_minute < 0 or initial_minute > 1000000000:
		errors.append("Starting time must be between 0 and 1,000,000,000 minutes.")
	if not is_finite(speed) or speed < 0 or speed > 3600:
		errors.append("Speed must be between 0 and 3600 game minutes per second.")
	if periods == null:
		errors.append("Create day periods before saving.")
	else:
		errors.append_array(periods.problems())
	if not paid:
		if lighting != null or calendar != null or not events.is_empty() or not conditions.is_empty():
			errors.append("This profile uses Paid features. Open it in the Paid edition.")
		return errors
	if calendar == null or not calendar.has_method("valid") or not calendar.valid():
		errors.append("Calendar needs matching nonempty month/season names and lengths; season starts must increase from day 1 and fit inside the year.")
	if calendar != null and calendar.has_method("valid") and calendar.valid():
		for name in calendar.month_names:
			if name.strip_edges().is_empty():
				errors.append("Every month needs a name.")
		var seen_seasons: Dictionary = {}
		for name in calendar.season_names:
			if name.strip_edges().is_empty() or seen_seasons.has(name):
				errors.append("Season names must be nonempty and unique.")
			seen_seasons[name] = true
	if lighting != null and (not lighting.has_method("valid") or not lighting.valid()):
		errors.append("Lighting needs valid gradients, an energy curve and finite ambient levels.")
	var seen: Dictionary = {}
	for event in events:
		if event == null or not event.has_method("valid") or not event.valid():
			errors.append("Each event needs an ID, a nonnegative first time and a nonnegative interval.")
			continue
		if seen.has(event.event_id):
			errors.append("Event ID '%s' is duplicated. Give every event a unique ID." % event.event_id)
		seen[event.event_id] = true
	seen.clear()
	for condition in conditions:
		if condition == null or not condition.has_method("valid") or not condition.valid():
			errors.append("Each condition needs an ID, valid hours/weekdays and a finite weight between 0 and 1000.")
			continue
		if seen.has(condition.condition_id):
			errors.append("Condition ID '%s' is duplicated." % condition.condition_id)
		seen[condition.condition_id] = true
		for name in condition.periods:
			if periods != null and not name in periods.names:
				errors.append("Condition '%s' refers to missing period '%s'." % [condition.condition_id,name])
		for name in condition.seasons:
			if calendar != null and calendar.has_method("valid") and calendar.valid() and not name in calendar.season_names:
				errors.append("Condition '%s' refers to missing season '%s'." % [condition.condition_id,name])
	return errors

func make_clock() -> Node:
	var paid := calendar != null
	if not problems(paid).is_empty():
		return null
	var script_path := "res://addons/rpg_time/paid/world_clock.gd" if paid else "res://addons/rpg_time/core/clock.gd"
	if not ResourceLoader.exists(script_path):
		return null
	var clock = load(script_path).new()
	clock.profile = self
	clock.apply_profile()
	return clock

func condition(id: String) -> Resource:
	for entry in conditions:
		if entry != null and entry.get("condition_id") == id:
			return entry
	return null