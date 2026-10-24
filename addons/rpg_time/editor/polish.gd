@tool
extends RefCounted
const L = preload("res://addons/rpg_time/editor/localization.gd")
const INK = Color("#F4EFF4")
const MUTED = Color("#A7B9D2")
const ROSE = Color("#EF8B9D")
static var cached_theme: Theme
static var surface_textures: Dictionary = {}

static func surface(top: Color, bottom: Color, radius: float = 14.0) -> StyleBoxTexture:
	var key := var_to_str([top,bottom,radius])
	var texture: Texture2D = surface_textures.get(key)
	if texture==null:
		var image := Image.create(64,64,false,Image.FORMAT_RGBA8)
		for y in range(64):
			for x in range(64):
				var center := Vector2(clampf(x,radius,63-radius),clampf(y,radius,63-radius))
				var coverage := clampf(radius-Vector2(x,y).distance_to(center)+0.5,0.0,1.0)
				var color := top.lerp(bottom,float(y)/63.0)
				if y < 2: color = color.lightened(0.12)
				color.a *= coverage
				image.set_pixel(x,y,color)
		texture = ImageTexture.create_from_image(image)
		# Fixed palette cache is bounded; callers still receive separate style boxes.
		if surface_textures.size()<32: surface_textures[key] = texture
	var box := StyleBoxTexture.new()
	box.texture = texture
	for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]:
		box.set_texture_margin(side,16)
		box.set_content_margin(side,14)
	return box

static func theme() -> Theme:
	if cached_theme != null: return cached_theme
	var t := Theme.new()
	t.default_font_size = 14
	t.set_color("font_color","Label",INK)
	t.set_color("font_color","Button",INK)
	t.set_color("font_hover_color","Button",Color.WHITE)
	t.set_color("font_disabled_color","Button",Color("#71809B"))
	for type in ["Button","OptionButton"]:
		t.set_stylebox("normal",type,surface(Color("#344965"),Color("#24344F"),10))
		t.set_stylebox("hover",type,surface(Color("#47617F"),Color("#324965"),10))
		t.set_stylebox("pressed",type,surface(Color("#25364F"),Color("#1B2B43"),10))
		t.set_stylebox("disabled",type,surface(Color("#26344C"),Color("#202C40"),10))
		var focus := StyleBoxFlat.new()
		focus.bg_color = Color.TRANSPARENT
		focus.border_color = ROSE
		focus.set_border_width_all(2)
		focus.set_corner_radius_all(10)
		t.set_stylebox("focus",type,focus)
	t.set_color("font_color","LineEdit",INK)
	t.set_stylebox("normal","LineEdit",surface(Color("#17243A"),Color("#1E304A"),8))
	t.set_color("font_color","CheckBox",INK)
	t.set_color("font_color","OptionButton",INK)
	t.set_color("font_color","PopupMenu",INK)
	t.set_stylebox("panel","PopupMenu",surface(Color("#30425F"),Color("#1E2E48")))
	t.set_stylebox("panel","PanelContainer",surface(Color("#2A3E5A"),Color("#1E2D47")))
	t.set_constant("separation","VBoxContainer",10)
	t.set_constant("h_separation","HFlowContainer",8)
	t.set_constant("v_separation","HFlowContainer",8)
	cached_theme = t
	return t

static func text(parent: Node, value: String, size: int = 14, color: Color = INK) -> Label:
	var label := Label.new()
	L.bind_text(label,value)
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label

static func card(parent: Node, title: String, subtitle: String = "") -> VBoxContainer:
	var panel := PanelContainer.new()
	parent.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	if not title.is_empty(): text(box,title,18)
	if not subtitle.is_empty(): text(box,subtitle,13,MUTED)
	return box

static func button(parent: Node, caption: String, action: Callable, primary: bool = false) -> Button:
	var b := Button.new()
	L.bind_text(b,caption)
	b.custom_minimum_size.y = 40
	b.pressed.connect(action)
	if primary:
		b.add_theme_stylebox_override("normal",surface(Color("#ECA3B2"),Color("#CE718B"),10))
		b.add_theme_stylebox_override("hover",surface(Color("#F6BBC6"),Color("#E190A7"),10))
		b.add_theme_color_override("font_color",Color("#19253D"))
		b.add_theme_color_override("font_hover_color",Color("#19253D"))
	parent.add_child(b)
	return b
