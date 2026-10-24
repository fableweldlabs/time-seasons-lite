@tool
extends Control
var minute: int = 480:
	set(value):
		minute = value
		queue_redraw()
func _ready() -> void:
	custom_minimum_size = Vector2(180,180)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	var center := size/2
	var radius := minf(size.x,size.y)*0.42
	draw_circle(center+Vector2(0,5),radius+5,Color(0,0,0,0.15))
	draw_circle(center,radius,Color("#20334F"))
	draw_arc(center,radius,0,TAU,96,Color("#526988"),1.5,true)
	draw_arc(center,radius-5,PI,TAU,48,Color("#90ADC9"),1,true)
	for i in range(24):
		var angle := TAU*i/24.0-PI/2
		var dir := Vector2(cos(angle),sin(angle))
		draw_line(center+dir*(radius-9),center+dir*(radius-15 if i%6==0 else radius-12),Color("#A7B9D2"),2 if i%6==0 else 1,true)
	var progress := TAU*(minute%1440)/1440.0-PI/2
	draw_arc(center,radius-22,-PI/2,progress,64,Color("#EF8B9D"),3,true)
	var hand := Vector2(cos(progress),sin(progress))
	draw_line(center,center+hand*(radius-32),Color("#F4EFF4"),3,true)
	draw_circle(center,5,Color("#EF8B9D"))
	draw_circle(center+hand*(radius-22),4,Color("#F4EFF4"))
