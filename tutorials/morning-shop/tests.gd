extends SceneTree
const ShopController = preload("res://tutorials/morning-shop/shop_controller.gd")
var checks := 0
func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		push_error(description)
		quit(1)
		assert(false, description)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var clock := FWClock.new()
	clock.paused = true
	clock.total_minutes = 350
	root.add_child(clock)
	var shop := ShopController.new()
	root.add_child(shop)
	shop.bind_clock(clock)
	check(not shop.is_open, "Starts closed before Morning")
	check(clock.advance(10) and shop.is_open, "Morning signal opens the shop at 06:00")
	check(clock.advance(360) and shop.is_open, "Day signal leaves the shop open")
	check(clock.skip_to(18) and not shop.is_open, "Evening closes the shop")
	check(clock.skip_to(6) and shop.is_open, "Next Morning reopens the shop")
	check(clock.skip_days(1) and shop.is_open, "A same-period day skip preserves correct open state")
	var replacement := FWClock.new()
	replacement.paused = true
	replacement.total_minutes = 780
	root.add_child(replacement)
	shop.bind_clock(replacement)
	check(shop.is_open, "Binding during Day synchronizes immediately")
	check(clock.skip_to(18) and shop.is_open, "Old clock disconnected on rebind")
	check(replacement.skip_to(22) and not shop.is_open, "New clock still controls shop")
	check(replacement.skip_days(1) and not shop.is_open, "Night-to-Night skip stays closed")
	shop.bind_clock(null)
	check(not shop.is_open, "Unbinding closes the shop")
	print("MORNING_SHOP: %d checks, 0 failures" % checks)
	quit()
