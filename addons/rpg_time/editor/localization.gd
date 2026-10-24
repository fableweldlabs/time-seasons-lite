@tool
extends RefCounted
## Editor-only dictionaries. No global TranslationServer or game settings changes.
const CODES = ["en", "es", "pt_BR", "zh_CN", "ja", "fr", "de"]
const NAMES = ["English", "Español", "Português (Brasil)", "简体中文", "日本語", "Français", "Deutsch"]
static var selected: String = ""
static var catalog: Dictionary = {}

static func locale() -> String:
	if selected.is_empty():
		set_locale("en", false)
	return selected

static func set_locale(code: String, _persist: bool = true) -> void:
	selected = code if code in CODES else "en"
	catalog = {}
	if selected != "en":
		var path := "res://addons/rpg_time/editor/locales/%s.json" % selected
		if FileAccess.file_exists(path):
			var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
			if data is Dictionary: catalog = data
	var extra := "res://addons/rpg_time/examples/courtyard/locales/%s.json" % selected
	if selected != "en" and FileAccess.file_exists(extra):
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(extra))
		if data is Dictionary: catalog.merge(data,true)

static func t(source: String) -> String:
	locale()
	return str(catalog.get(source, source))

static func message(source: String) -> String:
	var direct := t(source)
	if direct != source: return direct
	for prefix in ["Please check this change: ", "Please check: ", "Profile rejected: "]:
		if source.begins_with(prefix): return t(prefix) + message(source.substr(prefix.length()))
	# Translate formatted validation messages while retaining their original arguments.
	for key in catalog:
		if "%s" not in key and "%d" not in key: continue
		var regex := RegEx.new()
		var escaped := ""
		for character in str(key):
			escaped += "\\" + character if character in "\\.^$|?*+()[]{}" else character
		escaped = escaped.replace("%s", "(.+)").replace("%d", "([0-9]+)")
		if regex.compile("^" + escaped + "$") != OK: continue
		var found := regex.search(source)
		if found == null: continue
		var result: String = catalog[key]
		for i in range(1, found.get_group_count() + 1):
			var at_s := result.find("%s")
			var at_d := result.find("%d")
			var at := at_s if at_d < 0 else at_d if at_s < 0 else mini(at_s, at_d)
			if at >= 0: result = result.substr(0, at) + t(found.get_string(i)) + result.substr(at + 2)
		return result
	return source

static func bind_text(control: Control, source: String) -> void:
	control.set_meta("fw_source_text", source)
	control.set("text", t(source))

static func apply(root: Node) -> void:
	if root.has_meta("fw_source_text"):
		root.set("text", message(str(root.get_meta("fw_source_text"))))
	for child in root.get_children(): apply(child)
