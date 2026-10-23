extends Control
## Runnable integration example. All shop UI and behavior are tutorial code.
const ShopController = preload("res://tutorials/morning-shop/shop_controller.gd")
var clock: FWClock
var shop: Node
var time_label: Label
var date_label: Label
var period_label: Label
var sign_label: Label
var stage_label: Label
var log_label: Label
var ledger: Array[String] = []
var capture_mode := false

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	RenderingServer.set_default_clear_color(Color("19243e"))
	var profile := FWTimeProfile.new()
	profile.initial_minute = 27 * 1440 + 350 # Spring, day 28, 05:50.
	profile.speed = 60.0 # One game hour per real second.
	clock = profile.make_clock()
	assert(clock != null)
	add_child(clock) # Profile applies in the clock's _ready before binding.
	shop = ShopController.new()
	add_child(shop)
	_build_ui()
	shop.shop_state_changed.connect(_shop_changed)
	clock.time_changed.connect(func(_previous: int, _current: int): _refresh())
	clock.period_changed.connect(func(period: String): _log('period_changed("%s")' % period))
	clock.season_changed.connect(func(season: String): _log('season_changed("%s")' % season))
	shop.bind_clock(clock)
	_log("Connected period_changed; synchronized starting state.")
	_refresh()

func _label(text: String, position_value: Vector2, size_value: Vector2, font_size: int, color := Color("f4eff4")) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position_value
	label.size = size_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(label)
	return label

func _panel(position_value: Vector2, size_value: Vector2, color: Color) -> void:
	var panel := Panel.new()
	panel.position = position_value
	panel.size = size_value
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

func _button(text: String, x: float, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.position = Vector2(x, 618)
	button.size = Vector2(280, 48)
	button.add_theme_font_size_override("font_size", 21)
	button.pressed.connect(action)
	add_child(button)

func _build_ui() -> void:
	_label("FABLEWELD LABS   /   FREE LITE 1.3.3", Vector2(42, 22), Vector2(1190, 40), 23, Color("f48aa8"))
	_label("A clock signal can open your shop", Vector2(42, 65), Vector2(1190, 70), 42)
	stage_label = _label("1  SET UP: Create a clock, then connect period_changed", Vector2(42, 145), Vector2(1190, 70), 26)
	_panel(Vector2(42, 225), Vector2(536, 260), Color("253655"))
	_panel(Vector2(600, 225), Vector2(638, 260), Color("253655"))
	_label("LITE CLOCK", Vector2(64, 244), Vector2(480, 30), 20, Color("b6c4df"))
	time_label = _label("", Vector2(64, 282), Vector2(470, 88), 72)
	date_label = _label("", Vector2(64, 385), Vector2(480, 40), 25)
	period_label = _label("", Vector2(64, 435), Vector2(480, 35), 24, Color("f48aa8"))
	_label("EXAMPLE SHOP", Vector2(626, 244), Vector2(580, 30), 20, Color("b6c4df"))
	sign_label = _label("CLOSED", Vector2(626, 300), Vector2(580, 65), 55)
	_label("Open during Morning + Day\nDefault periods: 06:00 to 18:00", Vector2(626, 394), Vector2(580, 74), 24)
	log_label = _label("", Vector2(42, 505), Vector2(1190, 100), 21, Color("b6c4df"))
	_button("Pause / resume", 42, func(): clock.paused = not clock.paused)
	_button("Next morning", 342, func(): clock.skip_to(6))
	_button("Next evening", 642, func(): clock.skip_to(18))
	_button("Skip 1 day", 942, func(): clock.skip_days(1))
	_label("Tutorial UI + shop code shown here are separate examples, not built-in Lite features.", Vector2(42, 680), Vector2(1190, 30), 18, Color("b6c4df"))

func _shop_changed(is_open: bool) -> void:
	_log("Example shop: " + ("OPEN" if is_open else "CLOSED"))
	_refresh()

func _log(message: String) -> void:
	ledger.append(message)
	if ledger.size() > 3:
		ledger.pop_front()
	if is_instance_valid(log_label):
		log_label.text = "\n".join(ledger)

func _refresh() -> void:
	if not is_instance_valid(time_label):
		return
	var date := clock.date_at()
	time_label.text = "%02d:%02d" % [date.minute / 60, date.minute % 60]
	date_label.text = "%s  /  Day %d  /  Year %d" % [clock.season_at(), date.day, date.year]
	period_label.text = "Period: " + clock.period_at()
	sign_label.text = "OPEN" if shop.is_open else "CLOSED"
	sign_label.add_theme_color_override("font_color", Color("9ee6b5") if shop.is_open else Color("f48aa8"))

func begin_capture() -> void:
	capture_mode = true
	clock.set_process(false) # Deterministic clock API calls, independent of render speed.

func capture_step(frame: int) -> void:
	if frame == 16:
		stage_label.text = "2  MORNING: The real period signal opens our example shop"
		assert(clock.tick(1.0 / 6.0)) # 05:50 -> 06:00, at 60 minutes/sec.
	elif frame > 16 and frame < 48:
		assert(clock.tick(0.25))
	elif frame == 48:
		stage_label.text = "3  SKIP FORWARD: Evening closes the example shop"
		assert(clock.skip_to(18))
	elif frame == 68:
		stage_label.text = "4  SEASONS: Skip one day from Spring 28 to Summer 1"
		assert(clock.skip_days(1))
	elif frame == 80:
		stage_label.text = "5  TRY IT: Next morning opens the shop again"
		assert(clock.skip_to(6))
	_refresh()
