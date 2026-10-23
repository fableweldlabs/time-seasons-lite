@tool
class_name FWClock
extends Node
## Shared Lite/Paid clock. Integer minutes, no operating-system clock dependency.
signal time_changed(previous: int, current: int)
signal period_changed(period: String)
signal season_changed(season: String)
@export_range(0.0, 3600.0) var minutes_per_second: float = 1.0
@export var paused: bool = false
@export var periods: FWPeriods = FWPeriods.new()
@export var profile: FWTimeProfile
var total_minutes: int = 480
signal advance_rejected(reason: String)

func _ready() -> void:
	if profile != null:
		apply_profile()

func apply_profile() -> void:
	if profile == null:
		return
	periods = profile.periods
	total_minutes = profile.initial_minute
	minutes_per_second = profile.speed
	paused = profile.start_paused
	_fraction = 0.0
var _fraction: float = 0.0
var _advancing: bool = false

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	tick(delta)

func tick(delta: float) -> bool:
	if paused:
		return true
	if not is_finite(delta) or delta < 0 or not is_finite(minutes_per_second) or minutes_per_second < 0 or minutes_per_second > 3600:
		advance_rejected.emit("Use a finite, nonnegative delta and speed between 0 and 3600.")
		return false
	var accumulated := _fraction + delta * minutes_per_second
	if not is_finite(accumulated) or accumulated > 5256000:
		advance_rejected.emit("Elapsed time exceeds the bounded skip limit. Advance in smaller steps.")
		return false
	var whole := int(accumulated)
	var prior_fraction := _fraction
	# Normalize before callbacks: serializing inside a signal must always be valid.
	_fraction = accumulated - whole
	if whole > 0 and not advance(whole):
		_fraction = prior_fraction
		advance_rejected.emit("Time did not advance. Check calendar, limits and event count.")
		return false
	return true
func set_day_length(seconds: float) -> bool:
	if not is_finite(seconds) or seconds < 0.4:
		return false
	minutes_per_second = 1440.0 / seconds
	return true

func year_days() -> int:
	return 112

func date_at(value: int = -1) -> Dictionary:
	var t := total_minutes if value < 0 else value
	var day_index := t / 1440
	return {"year": day_index / year_days() + 1, "month": (day_index % year_days()) / 28 + 1,
		"day": day_index % 28 + 1, "minute": t % 1440, "day_index": day_index}

func period_at(value: int = -1) -> String:
	var minute := (total_minutes if value < 0 else value) % 1440
	return periods.at(minute) if periods != null else "Invalid periods"
func season_at(value: int = -1) -> String:
	var t := total_minutes if value < 0 else value
	return ["Spring", "Summer", "Autumn", "Winter"][(t / 1440 % year_days()) * 4 / year_days()]

func advance(minutes: int) -> bool:
	# Bounded transaction; observers cannot recursively advance the same clock.
	if periods == null or not periods.valid() or total_minutes < 0 or minutes < 0 or minutes > 5256000 or _advancing or total_minutes > 1000000000 - minutes:
		return false
	if minutes == 0:
		return true
	_advancing = true
	var previous := total_minutes
	var old_period := period_at()
	var old_season := season_at()
	total_minutes += minutes
	_after_advance(previous, total_minutes)
	time_changed.emit(previous, total_minutes)
	if old_period != period_at():
		period_changed.emit(period_at())
	if old_season != season_at():
		season_changed.emit(season_at())
	_advancing = false
	return true

func _after_advance(_previous: int, _current: int) -> void:
	pass

func sleep_until(minute_of_day: int = 360) -> bool:
	if minute_of_day < 0 or minute_of_day >= 1440:
		return false
	var distance := posmod(minute_of_day - total_minutes % 1440, 1440)
	return advance(1440 if distance == 0 else distance)

func skip_days(days: int) -> bool:
	if days < 0 or days > 3650:
		return false
	return advance(days * 1440)
## Forward-only skip; preserves event delivery rather than silently rewinding state.
func skip_to(hour: int, minute: int = 0) -> bool:
	if hour < 0 or hour > 23 or minute < 0 or minute > 59: return false
	return sleep_until(hour * 60 + minute)
func advance_hours(hours: float) -> bool:
	if not is_finite(hours) or hours < 0 or hours * 60 > 5256000: return false
	return advance(roundi(hours * 60))
