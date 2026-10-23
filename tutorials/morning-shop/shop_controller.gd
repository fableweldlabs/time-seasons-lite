extends Node
## Tutorial code, not a built-in Lite shop or scheduler.
signal shop_state_changed(is_open: bool)
var clock: FWClock
var is_open := false

func bind_clock(value: FWClock) -> void:
	if is_instance_valid(clock) and clock.period_changed.is_connected(_on_period_changed):
		clock.period_changed.disconnect(_on_period_changed)
	clock = value
	if is_instance_valid(clock):
		clock.period_changed.connect(_on_period_changed)
		_on_period_changed(clock.period_at())
	else:
		_set_open(false)

func _on_period_changed(period: String) -> void:
	# Default periods: Morning 06:00, Day 12:00, Evening 18:00.
	_set_open(period in ["Morning", "Day"])

func _set_open(value: bool) -> void:
	if value == is_open:
		return
	is_open = value
	shop_state_changed.emit(is_open)
