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
	for code in L.CODES:
		L.set_locale(code, false)
		var patterns := L.message_patterns.duplicate()
		for count in range(20):
			check(L.message("Period 7 needs a name.") == L.t("Period %d needs a name.") % 7, "number interpolation " + code)
			check(L.message("Could not save the profile: res://worlds/my_world.tres.") == L.t("Could not save the profile: %s.") % "res://worlds/my_world.tres", "path interpolation " + code)
			check(L.message("Please check: Period 7 needs a name.") == L.t("Please check: ") + L.t("Period %d needs a name.") % 7, "nested message " + code)
			check(L.message("unknown status") == "unknown status", "unknown fallback " + code)
		check(L.message_patterns == patterns, "message translation reuses compiled patterns " + code)
		if code != "en": check(patterns.size() > 0, "non-English patterns " + code)
	L.set_locale("ko", false)
	var before := L.message_patterns.duplicate()
	L.set_locale("pl", false)
	check(L.message_patterns != before, "locale switch rebuilds patterns")
	L.set_locale("unknown", false)
	check(L.message_patterns.is_empty() and L.locale() == "en", "fallback clears cache")
	print("TRANSLATION CACHE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
