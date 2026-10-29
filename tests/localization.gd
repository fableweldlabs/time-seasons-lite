extends SceneTree
const L = preload("res://addons/rpg_time/editor/localization.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game_locale := TranslationServer.get_locale()
	L.set_locale("en",false)
	var dock = load("res://addons/rpg_time/editor/dock.gd").new()
	root.add_child(dock)
	await process_frame
	dock.fields.initial_hour.value = 17
	dock.fields.period_name.text = "My custom morning 朝"
	var profile_before := var_to_str(dock.model.profile.periods.names)
	var initial_before: int = dock.model.profile.initial_minute
	var preview_before: float = dock.preview.total_minutes
	var children_before: int = dock.get_child_count()
	var catalog_keys: Array = []
	for index in range(1,L.CODES.size()):
		dock.change_language(index)
		check(L.selected == L.CODES[index],"requested locale selected")
		check(L.catalog.size() >= 100,"complete core UI dictionary loaded")
		if catalog_keys.is_empty(): catalog_keys = L.catalog.keys()
		check(L.catalog.keys() == catalog_keys,"all language catalogs have identical keys")
		check(dock.create_button.text == L.t("Create my clock…") and dock.create_button.text != "Create my clock…","primary action translated")
		check(dock.section_picker.get_item_text(0) == L.t("1  Set up your world"),"navigation translated")
		check(dock.has_unapplied and dock.fields.initial_hour.value == 17 and dock.fields.period_name.text == "My custom morning 朝","switch preserves unapplied user input")
		check(var_to_str(dock.model.profile.periods.names)==profile_before and dock.model.profile.initial_minute==initial_before,"serialized profile names and values unchanged")
		check(dock.preview.total_minutes==preview_before and dock.get_child_count()==children_before,"switch neither resets preview nor creates extra controls")
		check(L.t("unknown future key") == "unknown future key","missing key falls back to English")
		check(L.message("Period 7 needs a name.")==L.t("Period %d needs a name.") % 7,"validation placeholders preserved")
		check(L.message("Could not save the profile: 13.")==L.t("Could not save the profile: %s.") % "13","error arguments preserved")
		check(TranslationServer.get_locale()==game_locale,"global game locale unchanged")
	dock.change_language(0)
	check(dock.create_button.text=="Create my clock…" and dock.has_unapplied,"English restored without losing edits")
	L.set_locale("unsupported",false)
	check(L.locale()=="en" and L.t("Play preview")=="Play preview","unsupported locale falls back to English")
	dock.queue_free()
	await process_frame
	print("LOCALIZATION: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
