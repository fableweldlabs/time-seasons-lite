@tool
extends Node
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func dock_count() -> int:
	return EditorInterface.get_base_control().find_children("Time & Seasons","Control",true,false).size()
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	await get_tree().process_frame
	check(EditorInterface.is_plugin_enabled("rpg_time"), "plugin enabled")
	check(dock_count() == 1, "exactly one dock")
	var settings: Variant = ProjectSettings.get_setting("editor_plugins/enabled")
	EditorInterface.set_plugin_enabled("rpg_time",false)
	await get_tree().process_frame
	check(not EditorInterface.is_plugin_enabled("rpg_time") and dock_count() == 0, "disable removes dock")
	var c := FWClock.new()
	check(c.advance(60), "runtime independent of plugin")
	c.free()
	EditorInterface.set_plugin_enabled("rpg_time",true)
	await get_tree().process_frame
	await get_tree().process_frame
	check(EditorInterface.is_plugin_enabled("rpg_time") and dock_count() == 1, "reenable creates one dock")
	check(ProjectSettings.get_setting("editor_plugins/enabled") == settings, "plugin settings restored")
	var found := false
	for property in ProjectSettings.get_property_list():
		if property.name.begins_with("autoload/") and "Fableweld" in property.name:
			found = true
	check(not found,"no automatic autoload")
	if ResourceLoader.exists("res://addons/rpg_time/paid/world_clock.gd"):
		await test_scene_connection()
	print("EDITOR LIFECYCLE: %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)

func test_scene_connection() -> void:
	var scene_path := "res://fw-editor-world.tscn"
	var profile_path := "res://fw-editor-profile.tres"
	if FileAccess.file_exists(scene_path) or FileAccess.file_exists(profile_path):
		check(false,"preexisting editor test fixtures preserved")
		return
	var world := Node3D.new()
	world.name = "ExistingWorld"
	var sun := DirectionalLight3D.new()
	sun.name = "ExistingSun"
	world.add_child(sun)
	sun.owner = world
	var environment := WorldEnvironment.new()
	environment.name = "ExistingEnvironment"
	environment.environment = Environment.new()
	world.add_child(environment)
	environment.owner = world
	var packed := PackedScene.new()
	packed.pack(world)
	world.free()
	check(ResourceSaver.save(packed,scene_path) == OK,"editor test scene saved")
	EditorInterface.open_scene_from_path(scene_path)
	var edited: Node
	for frame in range(180):
		await get_tree().process_frame
		var candidate := EditorInterface.get_edited_scene_root()
		if candidate != null and candidate.scene_file_path == scene_path and candidate.name == "ExistingWorld":
			edited = candidate
			break
	check(edited != null and edited.get_child_count() == 2,"requested scene is active with its two original lighting nodes")
	if edited == null or edited.get_child_count() != 2:
		print("EDITOR SCENE READINESS: ", EditorInterface.get_edited_scene_root())
		DirAccess.remove_absolute(scene_path)
		DirAccess.remove_absolute(profile_path)
		return
	var panel: Control = EditorInterface.get_base_control().find_children("Time & Seasons","Control",true,false)[0]
	check(panel.model.save_profile(profile_path).is_empty(),"saved profile for auto wiring")
	check(panel.section_picker.item_count == 7,"all sections reachable at narrow width")
	var action_button: Button = panel.find_children("*","Button",true,false)[0]
	check(action_button.get_theme_stylebox("normal").bg_color == Color("#26365D"),"dock applies presentation tokens")
	var connections: Array = panel.get_signal_connection_list("connect_scene_requested")
	var plugin: EditorPlugin = connections[0].callable.get_object()
	print("EDITOR CONNECTION BEFORE: ",edited.scene_file_path," children=",edited.get_child_count()," dirty=",panel.model.dirty," unapplied=",panel.has_unapplied)
	plugin._connect_scene("3d")
	print("EDITOR CONNECTION AFTER: children=",edited.get_child_count()," status=",panel.status.text)
	check(edited.get_child_count() == 4,"editor shortcut adds clock and driver only")
	var driver := edited.get_node_or_null("TimeLighting")
	check(driver != null and driver.get_node(driver.sun_path) == edited.get_node("ExistingSun"),"editor shortcut connects existing sun")
	var manager := plugin.get_undo_redo()
	var history := manager.get_history_undo_redo(manager.get_object_history_id(edited))
	history.undo()
	check(edited.get_child_count() == 2,"scene connection undo restores original nodes")
	history.redo()
	check(edited.get_child_count() == 4,"scene connection redo restores wiring")
	# Clean source fixtures only; the packager removes its entire owned fresh host afterward.
	DirAccess.remove_absolute(scene_path)
	DirAccess.remove_absolute(profile_path)
