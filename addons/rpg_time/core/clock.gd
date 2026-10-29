@tool
class_name FWClock
extends Node
## Shared Lite/Paid clock. Integer microsecond timeline with minute calendar boundaries.
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
	_tick_remainder = 0.0
const MICROSECONDS_PER_MINUTE: int = 60000000
signal microseconds_changed(previous: int, current: int)
var _subminute_us: int = 0
var _tick_remainder: float = 0.0
var _micro_advancing := false
var _fraction: float:
	get: return float(_subminute_us) / MICROSECONDS_PER_MINUTE
	set(value): _subminute_us = clampi(roundi(value * MICROSECONDS_PER_MINUTE), 0, MICROSECONDS_PER_MINUTE - 1)

func total_microseconds() -> int:
	return total_minutes * MICROSECONDS_PER_MINUTE + _subminute_us

## Integer-only input path. Minute signals retain their existing boundary semantics.
func advance_microseconds(amount: int) -> bool:
	if _advancing or _micro_advancing or amount < 0 or amount > 5256000 * MICROSECONDS_PER_MINUTE:
		return false
	if not advance(0): return false
	var previous := total_microseconds()
	var whole := amount / MICROSECONDS_PER_MINUTE
	var remainder := _subminute_us + amount % MICROSECONDS_PER_MINUTE
	whole += remainder / MICROSECONDS_PER_MINUTE
	remainder %= MICROSECONDS_PER_MINUTE
	if total_minutes > 1000000000 - whole or (total_minutes + whole == 1000000000 and remainder > 0):
		return false
	var old_subminute := _subminute_us
	_micro_advancing = true
	_subminute_us = remainder
	if not advance(whole):
		_subminute_us = old_subminute
		_micro_advancing = false
		return false
	if amount > 0:
		_advancing = true
		microseconds_changed.emit(previous, total_microseconds())
		_advancing = false
	_micro_advancing = false
	return true

## Friendly game-seconds seam; rounds once. Use integers for reproducible timelines.
func advance_seconds(seconds: float) -> bool:
	if not is_finite(seconds) or seconds < 0 or seconds > 5256000.0 * 60.0: return false
	return advance_microseconds(roundi(seconds * 1000000.0))

var _advancing: bool = false

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	tick(delta)

func tick(delta: float) -> bool:
	if _advancing or _micro_advancing: return false
	if paused: return true
	if not is_finite(delta) or delta < 0 or not is_finite(minutes_per_second) or minutes_per_second < 0 or minutes_per_second > 3600:
		advance_rejected.emit("Use a finite, nonnegative delta and speed between 0 and 3600.")
		return false
	var elapsed := _tick_remainder + delta * minutes_per_second * MICROSECONDS_PER_MINUTE
	if not is_finite(elapsed) or elapsed > 5256000.0 * MICROSECONDS_PER_MINUTE:
		advance_rejected.emit("Elapsed time exceeds the bounded skip limit. Advance in smaller steps.")
		return false
	var whole := int(elapsed)
	var prior_remainder := _tick_remainder
	_tick_remainder = elapsed - whole
	if not advance_microseconds(whole):
		_tick_remainder = prior_remainder
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
	if total_minutes + minutes == 1000000000 and _subminute_us > 0: return false
	if minutes == 0:
		return true
	_advancing = true
	var previous_microseconds := total_microseconds()
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
	if not _micro_advancing: microseconds_changed.emit(previous_microseconds, total_microseconds())
	_advancing = false
	return true

func _after_advance(_previous: int, _current: int) -> void:
	pass

func sleep_until(minute_of_day: int = 360) -> bool:
	if minute_of_day < 0 or minute_of_day >= 1440:
		return false
	var distance := posmod(minute_of_day - total_minutes % 1440, 1440)
	return advance_microseconds((1440 if distance == 0 else distance) * MICROSECONDS_PER_MINUTE - _subminute_us)

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
	return advance_seconds(hours * 3600.0)
