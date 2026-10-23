@tool
extends EditorPlugin
var dock: Control
func _enter_tree() -> void:
	dock = preload("res://addons/rpg_time/editor/dock.gd").new()
	dock.name = "Time & Seasons"
	dock.connect_scene_requested.connect(_connect_scene)
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)
	# Explicit hidden/headless test opt-in; never active in a normal editor session.
	if "--fw-editor-probe" in OS.get_cmdline_user_args() and ResourceLoader.exists("res://tests/editor_probe.gd"):
		call_deferred("_start_probe")
func _start_probe() -> void:
	var base := EditorInterface.get_base_control()
	if base.has_meta("fw_probe_started"): return
	base.set_meta("fw_probe_started",true)
	base.add_child(load("res://tests/editor_probe.gd").new())
func _exit_tree() -> void:
	if is_instance_valid(dock):
		remove_control_from_docks(dock)
		dock.free()
	dock = null
func _connect_scene(mode: String) -> void:
	if dock.has_unapplied or dock.model.dirty or dock.model.source_path.is_empty():
		dock.show_message("Apply and save your profile before connecting a scene.")
		return
	var root := EditorInterface.get_edited_scene_root()
	var profile := load(dock.model.source_path) as FWTimeProfile
	var result: Dictionary = preload("res://addons/rpg_time/editor/scene_wiring.gd").plan(root,profile,mode)
	if not result.error.is_empty():
		dock.show_message(result.error)
		return
	var undo := get_undo_redo()
	undo.create_action("Connect Fableweld time lighting",UndoRedo.MERGE_DISABLE,root)
	for node in result.nodes:
		undo.add_do_method(root,"add_child",node,true)
		undo.add_do_property(node,"owner",root)
		undo.add_do_reference(node)
		undo.add_undo_method(root,"remove_child",node)
	undo.commit_action()
	dock.show_message("Connected to existing lighting. Save your scene; Ctrl+Z undoes this change.")
