extends Node
var clock: FWClock
var readout: Label
func _ready() -> void:
	clock = FWClock.new()
	clock.minutes_per_second = 60
	add_child(clock)
	RenderingServer.set_default_clear_color(Color("#19243E"))
	var mark := TextureRect.new()
	var mark_image = preload("res://addons/rpg_time/core/brand.gd").texture().get_image()
	mark_image.resize(48,48,Image.INTERPOLATE_LANCZOS)
	mark.texture = ImageTexture.create_from_image(mark_image)
	mark.position = Vector2(24,24)
	mark.size = Vector2(48,48)
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(mark)
	readout = Label.new()
	readout.position = Vector2(24,88)
	readout.size = Vector2(580,230)
	readout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	readout.add_theme_color_override("font_color",Color("#F4EFF4"))
	readout.add_theme_font_size_override("font_size",20)
	add_child(readout)
	clock.time_changed.connect(func(_a,_b): refresh())
	clock.period_changed.connect(func(period): print("Period: ",period))
	clock.season_changed.connect(func(season): print("Season: ",season))
	refresh()
func refresh() -> void:
	var date := clock.date_at()
	readout.text = "Fableweld Labs · RPG Time & Seasons Lite\nYear %d · Month %d · Day %d · %02d:%02d\n%s · %s\nSignal example: 60 game minutes per second. Customize the clock in code or use the editor dock." % [date.year,date.month,date.day,date.minute/60,date.minute%60,clock.season_at(),clock.period_at()]