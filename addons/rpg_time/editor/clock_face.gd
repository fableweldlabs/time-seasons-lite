@tool
extends Control
var minute: int = 480:
	set(value):
		minute = value
		queue_redraw()
func _ready() -> void:
	call_deferred("_fw_install_appearance")
	custom_minimum_size = Vector2(180,180)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	var center := size/2
	var radius := minf(size.x,size.y)*0.42
	draw_circle(center+Vector2(0,5),radius+5,Color(0,0,0,0.15))
	draw_circle(center,radius,preload("res://addons/rpg_time/appearance.gd").palette(preload("res://addons/rpg_time/appearance.gd").selected).surface)
	draw_arc(center,radius,0,TAU,96,preload("res://addons/rpg_time/appearance.gd").palette(preload("res://addons/rpg_time/appearance.gd").selected).border,1.5,true)
	draw_arc(center,radius-5,PI,TAU,48,preload("res://addons/rpg_time/appearance.gd").palette(preload("res://addons/rpg_time/appearance.gd").selected).muted,1,true)
	for i in range(24):
		var angle := TAU*i/24.0-PI/2
		var dir := Vector2(cos(angle),sin(angle))
		draw_line(center+dir*(radius-9),center+dir*(radius-15 if i%6==0 else radius-12),preload("res://addons/rpg_time/appearance.gd").palette(preload("res://addons/rpg_time/appearance.gd").selected).muted,2 if i%6==0 else 1,true)
	var progress := TAU*(minute%1440)/1440.0-PI/2
	draw_arc(center,radius-22,-PI/2,progress,64,preload("res://addons/rpg_time/appearance.gd").palette(preload("res://addons/rpg_time/appearance.gd").selected).accent,3,true)
	var hand := Vector2(cos(progress),sin(progress))
	draw_line(center,center+hand*(radius-32),preload("res://addons/rpg_time/appearance.gd").palette(preload("res://addons/rpg_time/appearance.gd").selected).text,3,true)
	draw_circle(center,5,preload("res://addons/rpg_time/appearance.gd").palette(preload("res://addons/rpg_time/appearance.gd").selected).accent)
	draw_circle(center+hand*(radius-22),4,preload("res://addons/rpg_time/appearance.gd").palette(preload("res://addons/rpg_time/appearance.gd").selected).text)

func _fw_install_appearance() -> void:
	var controller=preload("res://addons/rpg_time/appearance.gd").install(self,preload("res://addons/rpg_time/appearance.gd"))
	controller.apply()
