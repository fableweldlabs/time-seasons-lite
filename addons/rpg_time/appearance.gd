@tool
extends Node
## Fableweld-owned UI presentation only. Does not change game data or global translation.
const IDS=["light","dark","fableweld","gold"]
const CODES=["en","es","pt_BR","zh_CN","ja","fr","de","pl","ko","zh_TW","tr","uk"]
const WORDS={
 "en":["Appearance","Light","Dark","Fableweld","Gold","Text size","Find action","Search current actions","Focus action","Close"],
 "es":["Apariencia","Claro","Oscuro","Fableweld","Dorado","Tamaño del texto","Buscar acción","Buscar acciones actuales","Enfocar acción","Cerrar"],
 "pt_BR":["Aparência","Claro","Escuro","Fableweld","Dourado","Tamanho do texto","Buscar ação","Buscar ações atuais","Focar ação","Fechar"],
 "zh_CN":["外观","浅色","深色","Fableweld","金色","文字大小","查找操作","搜索当前操作","聚焦操作","关闭"],
 "ja":["外観","ライト","ダーク","Fableweld","ゴールド","文字サイズ","操作を探す","現在の操作を検索","操作にフォーカス","閉じる"],
 "fr":["Apparence","Clair","Sombre","Fableweld","Or","Taille du texte","Trouver une action","Rechercher les actions actuelles","Cibler l’action","Fermer"],
 "de":["Darstellung","Hell","Dunkel","Fableweld","Gold","Textgröße","Aktion finden","Aktuelle Aktionen suchen","Aktion fokussieren","Schließen"],
 "pl":["Wygląd","Jasny","Ciemny","Fableweld","Złoty","Rozmiar tekstu","Znajdź działanie","Szukaj bieżących działań","Ustaw fokus","Zamknij"],
 "ko":["모양","라이트","다크","Fableweld","골드","글자 크기","동작 찾기","현재 동작 검색","동작에 초점 맞추기","닫기"],
 "zh_TW":["外觀","淺色","深色","Fableweld","金色","文字大小","尋找操作","搜尋目前操作","聚焦操作","關閉"],
 "tr":["Görünüm","Açık","Koyu","Fableweld","Altın","Metin boyutu","Eylem bul","Geçerli eylemleri ara","Eyleme odaklan","Kapat"],
 "uk":["Вигляд","Світла","Темна","Fableweld","Золота","Розмір тексту","Знайти дію","Пошук поточних дій","Фокус на дію","Закрити"]}
const PALETTES={
 "light":["f8fafc","ffffff","f1f5f9","17202e","475569","94a3b8","1d4ed8","b91c1c","166534","dbeafe"],
 "dark":["14171c","1e232b","292f39","eef2f6","b3bfce","64748b","93c5fd","fca5a5","86efac","263e5b"],
 "fableweld":["161b30","222c48","2e3b5b","f5f2f7","bcc9df","7b8bab","f4a3ba","ffb3b3","a3e2bc","49384f"],
 "gold":["1b1914","27231c","353026","faf5e7","d3c6a8","938262","f4d28b","ffb5a6","b7ddb1","49402a"]}
static var selected:=""
static var scale_percent:=100
static var _cache:Dictionary={}
static var _hosts:Array[WeakRef]=[]
static var theme_builds:=0
static var theme_hits:=0
static var _palette_cache:Dictionary={}
static var _palette_builds:=0
static var _style_keys:Dictionary={}
static var _style_defaults:Dictionary={}
var _custom_palette_state:=false
var host:Control
var locale_reader:Callable
var bar:HFlowContainer
var theme_picker:OptionButton
var size_picker:OptionButton
var find_button:Button
var dialog:ConfirmationDialog
var query:LineEdit
var results:ItemList
var actions:Array[Dictionary]=[]
var filtered:Array[WeakRef]=[]
var _applying:=false
var _refresh_pending:=false
var _apply_count:=0
var locale:="en"
var backdrop:Node2D

static func palette(id:String)->Dictionary:
 if id not in IDS:id="dark"
 if _palette_cache.has(id):return _palette_cache[id]
 var row:Array=PALETTES.get(id,PALETTES.dark)
 var out:Dictionary={}
 var names=["background","surface","raised","text","muted","border","accent","error","success","selection"]
 for i in names.size():out[names[i]]=Color(row[i])
 out.make_read_only();_palette_cache[id]=out;_palette_builds+=1
 return out

static func _load_preferences()->void:
 if not selected.is_empty():return
 var cfg=ConfigFile.new()
 cfg.load("user://fableweld-appearance.cfg")
 var fallback="dark" if DisplayServer.is_dark_mode_supported() and DisplayServer.is_dark_mode() else "light"
 selected=str(cfg.get_value("appearance","theme",fallback))
 if selected not in IDS:selected=fallback
 scale_percent=int(cfg.get_value("appearance","text_size",100))
 if scale_percent not in [100,125,150]:scale_percent=100

static func _box(color:Color,border:Color,width:int=1)->StyleBoxFlat:
 var b=StyleBoxFlat.new();b.bg_color=color;b.border_color=border;b.set_border_width_all(width);b.set_corner_radius_all(5)
 b.content_margin_left=10;b.content_margin_right=10;b.content_margin_top=7;b.content_margin_bottom=7
 return b

static func _style_resources(control:Control)->Array:
 var source:Script=control.get_script()
 if source==null:return []
 var key=source.get_instance_id()
 if not _style_keys.has(key):
  var names:Array=[];var current:Script=source
  while current!=null:
   for property in current.get_script_property_list():
    var name=String(property.name)
    if name in ["style","appearance"] and name not in names:names.append(name)
   current=current.get_base_script()
  _style_keys[key]=names
 var result:Array=[]
 for name in _style_keys[key]:
  var value=control.get(name)
  if value is Resource:
   var implementation:Script=value.get_script()
   if implementation==null:continue
   var current:Script=implementation;var known:=false
   while current!=null:
    if String(current.get_global_name()) in ["FWHUDStyle","FWHudStyle"]:known=true;break
    current=current.get_base_script()
   if known:result.append(value)
 return result

static func _has_custom_palette(control:Control)->bool:
 for resource in _style_resources(control):
  var implementation:Script=resource.get_script()
  if String(implementation.get_global_name()) not in ["FWHUDStyle","FWHudStyle"]:return true
  var key=implementation.get_instance_id()
  if not _style_defaults.has(key):
   var defaults:Dictionary={}
   for property in implementation.get_script_property_list():
    if int(property.type)==TYPE_COLOR:
     var value=implementation.get_property_default_value(property.name)
     if value is Color:defaults[String(property.name)]=value
   defaults.make_read_only();_style_defaults[key]=defaults
  for name in _style_defaults[key]:
   var value=resource.get(name)
   if value is Color and not value.is_equal_approx(_style_defaults[key][name]):return true
 return false

static func _custom_corner_radius(control:Control)->int:
 for resource in _style_resources(control):
  var value=resource.get("corner_radius")
  var implementation:Script=resource.get_script()
  if value is int and value>=0 and value<=128 and value!=implementation.get_property_default_value("corner_radius"):return value
 return -1

static func _icon(markup:String)->Texture2D:
 var image=Image.new()
 if image.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20">'+markup+'</svg>')!=OK:return null
 return ImageTexture.create_from_image(image)

static func get_theme(id:String="",percent:int=0)->Theme:
 _load_preferences()
 if id.is_empty():id=selected
 if id not in IDS:id="dark"
 if percent not in [100,125,150]:percent=scale_percent
 var key=id+str(percent)
 if _cache.has(key):theme_hits+=1;return _cache[key]
 var p=palette(id);var t=Theme.new();t.default_font_size=roundi(14.0*percent/100.0)
 for kind in ["Label","Button","OptionButton","CheckBox","CheckButton","MenuButton","LineEdit","TextEdit","CodeEdit","SpinBox","RichTextLabel","Tree","ItemList","PopupMenu","TabContainer","TabBar","AcceptDialog"]:
  for color_name in ["font_color","font_hover_color","font_pressed_color","font_focus_color","default_color"]:t.set_color(color_name,kind,p.text)
  t.set_color("font_disabled_color",kind,p.muted);t.set_color("font_placeholder_color",kind,p.muted)
  t.set_color("font_selected_color",kind,p.text);t.set_color("selection_color",kind,p.selection)
  t.set_color("caret_color",kind,p.accent)
 for kind in ["Button","OptionButton","MenuButton","LineEdit","TextEdit","CodeEdit","Tree","ItemList"]:
  t.set_stylebox("normal",kind,_box(p.raised,p.border));t.set_stylebox("hover",kind,_box(p.selection,p.accent))
  t.set_stylebox("pressed",kind,_box(p.selection,p.accent));t.set_stylebox("disabled",kind,_box(p.surface,p.border))
  t.set_stylebox("read_only",kind,_box(p.surface,p.border))
  t.set_stylebox("focus",kind,_box(Color.TRANSPARENT,p.accent,2))
 for kind in ["Panel","PanelContainer","PopupMenu","Window","AcceptDialog"]:t.set_stylebox("panel",kind,_box(p.surface,p.border))
 t.set_stylebox("panel","TabContainer",_box(p.surface,p.border))
 for kind in ["TabContainer","TabBar"]:
  t.set_color("font_selected_color",kind,p.text);t.set_color("font_unselected_color",kind,p.muted)
  t.set_stylebox("tab_selected",kind,_box(p.selection,p.accent));t.set_stylebox("tab_unselected",kind,_box(p.raised,p.border))
 t.set_stylebox("background","ProgressBar",_box(p.raised,p.border));t.set_stylebox("fill","ProgressBar",_box(p.accent,p.accent))
 t.set_color("font_color","ProgressBar",p.text)
 for kind in ["HSeparator","VSeparator"]:t.set_stylebox("separator",kind,_box(p.border,p.border,0))
 for kind in ["VBoxContainer","HBoxContainer","HFlowContainer"]:t.set_constant("separation",kind,8)
 var ink="#"+p.text.to_html(false);var accent="#"+p.accent.to_html(false)
 var tick=_icon('<rect x="2" y="2" width="16" height="16" rx="3" fill="none" stroke="'+ink+'" stroke-width="2"/><path d="M5 10 L9 14 L15 6" fill="none" stroke="'+accent+'" stroke-width="2"/>')
 var blank=_icon('<rect x="2" y="2" width="16" height="16" rx="3" fill="none" stroke="'+ink+'" stroke-width="2"/>')
 t.set_icon("checked","CheckBox",tick);t.set_icon("unchecked","CheckBox",blank)
 t.set_icon("checked_disabled","CheckBox",tick);t.set_icon("unchecked_disabled","CheckBox",blank)
 t.set_icon("arrow","OptionButton",_icon('<path d="M5 7 L10 12 L15 7" fill="none" stroke="'+ink+'" stroke-width="2"/>'))
 t.set_icon("updown","SpinBox",_icon('<path d="M6 7 L10 3 L14 7 M6 13 L10 17 L14 13" fill="none" stroke="'+ink+'" stroke-width="2"/>'))
 _cache[key]=t;theme_builds+=1
 return t

static func install(root_control:Control,implementation:Script,reader:Callable=Callable())->Node:
 var old=root_control.get_node_or_null("FableweldAppearance")
 if old!=null:return old
 var controller=implementation.new()
 controller.name="FableweldAppearance";controller.host=root_control;controller.locale_reader=reader
 root_control.add_child(controller)
 return controller

func _ready()->void:
 _load_preferences();_hosts.append(weakref(self))
 add_to_group("fableweld_ui_appearance_v1")
 host.tree_exiting.connect(_host_exiting)
 backdrop=Node2D.new();backdrop.name="FableweldBackdrop";backdrop.show_behind_parent=true
 host.add_child(backdrop);backdrop.draw.connect(_draw_background)
 host.resized.connect(backdrop.queue_redraw)
 apply()

func _draw_background()->void:
 if is_instance_valid(host) and is_instance_valid(backdrop) and not host.get_meta("fw_transparent_overlay",false) and not host.get_meta("fw_preserve_custom_appearance",false) and (host.get_meta("fw_owned_theme_root",false) or not _has_custom_palette(host)):backdrop.draw_style_box(get_theme().get_stylebox("panel","PanelContainer"),Rect2(Vector2.ZERO,host.size))

func _host_exiting()->void:
 _hosts=_hosts.filter(func(w):return w.get_ref()!=null and w.get_ref()!=self)

func word(index:int)->String:return WORDS.get(locale,WORDS.en)[index]

func _read_locale()->String:
 if locale_reader.is_valid():return str(locale_reader.call())
 for property in host.get_property_list():
  var property_name=String(property.name)
  if "locale" in property_name or "language" in property_name:
   var value=host.get(property_name)
   if value is String and value.replace("-","_") in CODES:return value
 for child in host.find_children("*","OptionButton",true,false):
  if child.item_count==12 and child.get_item_text(0)=="English":return CODES[maxi(child.selected,0)]
 return "en"

func _locale_option_selected(_index:int)->void:call_deferred("_refresh_locale")
func _refresh_locale()->void:set_locale(_read_locale())

func set_locale(code:String)->void:
 code=code.replace("-","_");locale=code if code in CODES else "en"
 if theme_picker==null:return
 theme_picker.tooltip_text=word(0);size_picker.tooltip_text=word(5)
 for i in 4:theme_picker.set_item_text(i,word(i+1))
 find_button.text=word(6)
 if dialog!=null:
  dialog.title=word(6);dialog.get_ok_button().text=word(8);dialog.get_cancel_button().text=word(9);query.placeholder_text=word(7)

func add_toolbar(parent:Container)->void:
 if bar!=null:return
 bar=HFlowContainer.new();bar.name="AppearanceControls";bar.set_meta("fw_appearance_chrome",true)
 parent.add_child(bar);parent.move_child(bar,0)
 theme_picker=OptionButton.new();theme_picker.fit_to_longest_item=false;theme_picker.custom_minimum_size=Vector2(110,36)
 for title in WORDS.en.slice(1,5):theme_picker.add_item(title)
 theme_picker.select(IDS.find(selected));bar.add_child(theme_picker)
 theme_picker.item_selected.connect(func(i):choose(IDS[i],scale_percent))
 size_picker=OptionButton.new();size_picker.custom_minimum_size=Vector2(76,36)
 for percent in [100,125,150]:size_picker.add_item(str(percent)+"%")
 size_picker.select([100,125,150].find(scale_percent));bar.add_child(size_picker)
 size_picker.item_selected.connect(func(i):choose(selected,[100,125,150][i]))
 find_button=Button.new();find_button.text=word(6);find_button.custom_minimum_size.y=36;bar.add_child(find_button);find_button.pressed.connect(open_find)
 set_locale(_read_locale())

func choose(id:String,percent:int)->void:
 if id not in IDS or percent not in [100,125,150]:return
 selected=id;scale_percent=percent
 var cfg=ConfigFile.new();cfg.set_value("appearance","theme",id);cfg.set_value("appearance","text_size",percent)
 var err=cfg.save("user://fableweld-appearance.cfg")
 if err!=OK:push_warning("Fableweld appearance preferences could not be saved; current view remains usable.")
 get_tree().call_group("fableweld_ui_appearance_v1","_receive_selection",id,percent)

func _receive_selection(id:String,percent:int)->void:
 if id not in IDS or percent not in [100,125,150]:return
 selected=id;scale_percent=percent;apply()

func apply()->void:
 if _applying or not is_instance_valid(host) or host.get_meta("fw_preserve_custom_appearance",false):return
 _watch_control(host)
 _custom_palette_state=not host.get_meta("fw_owned_theme_root",false) and _has_custom_palette(host)
 if _custom_palette_state:
  if backdrop!=null:backdrop.queue_redraw()
  return
 _applying=true
 _apply_count+=1
 var tree=host.get_tree() if host.is_inside_tree() else null
 if tree!=null:tree.set_meta("fw_appearance_write_depth_v1",int(tree.get_meta("fw_appearance_write_depth_v1",0))+1)
 host.theme=get_theme()
 _adapt(host)
 if backdrop!=null:backdrop.queue_redraw()
 host.queue_redraw()
 if theme_picker!=null:theme_picker.select(IDS.find(selected));size_picker.select([100,125,150].find(scale_percent))
 if tree!=null:tree.set_meta("fw_appearance_write_depth_v1",maxi(0,int(tree.get_meta("fw_appearance_write_depth_v1",1))-1))
 _applying=false

func _adapt(node:Node)->void:
 if node==self or node==backdrop or node.get_meta("fw_preserve_custom_appearance",false):return
 if not node.child_entered_tree.is_connected(_child_added):node.child_entered_tree.connect(_child_added)
 var p=palette(selected)
 if node is Control:
  _watch_control(node)
  if not host.get_meta("fw_owned_theme_root",false) and _has_custom_palette(node):return
  if node is OptionButton and not node.item_selected.is_connected(_locale_option_selected):node.item_selected.connect(_locale_option_selected)
  if node is TextureRect and node.has_meta("fw_brand_provider"):
   var brand=node.get_meta("fw_brand_provider")
   node.texture=brand.texture(selected!="light")
  if node.theme!=null and (node.theme.resource_path.ends_with("night_bloom.tres") or host.get_meta("fw_owned_theme_root",false)):node.theme=get_theme()
  if not node.has_meta("fw_original_font_size") and node.has_theme_font_size_override("font_size"):node.set_meta("fw_original_font_size",node.get_theme_font_size("font_size"))
  if node.has_meta("fw_original_font_size"):
   var target_size:=roundi(float(node.get_meta("fw_original_font_size"))*scale_percent/100.0)
   node.set_meta("fw_applied_font_size",target_size)
   node.add_theme_font_size_override("font_size",target_size)
  for key in ["font_color","default_color","font_hover_color","font_pressed_color"]:
   if node.has_theme_color_override(key):
    var meta="fw_original_"+key
    if not node.has_meta(meta):node.set_meta(meta,node.get_theme_color(key))
    var c:Color=node.get_meta(meta)
    # Only recolor known built-in palette colors. Host-authored colors stay untouched.
    var html=c.to_html(false).to_lower()
    if html in ["f4eff4","f5f2f7","ffffff","f5f5f5","eef2f6","e8eef8","19253d","26365d"]:node.add_theme_color_override(key,p.text)
    elif html in ["a7b9d2","bcc9df","b8c5d8","afc1dc","a7c5d9","acc7dc","b7cee0"]:node.add_theme_color_override(key,p.muted)
    elif html in ["ef8b9d","f4a3ba","e6c47a","d6b267"]:node.add_theme_color_override(key,p.accent)
    elif html in ["f6c991","facc15"]:node.add_theme_color_override(key,Color("854d0e") if selected=="light" else Color("facc15"))
    elif html in ["cce7cd","9bdfaa","a3e2bc"]:node.add_theme_color_override(key,p.success)
  # Explicit built-in panel/button boxes must not keep the old navy/gold fill.
  for state in ["panel","normal","hover","pressed","disabled","focus","background","fill"]:
   if node.has_theme_stylebox_override(state):
    var meta="fw_original_style_"+state
    if not node.has_meta(meta):node.set_meta(meta,node.get_theme_stylebox(state))
    var original:StyleBox=node.get_meta(meta)
    if original is StyleBoxEmpty:continue
    if original is StyleBoxFlat or original is StyleBoxTexture:
     var color:Color=p.surface if state=="panel" else p.raised
     if state in ["hover","pressed"]:color=p.selection
     if node is ProgressBar:color=p.accent if state=="fill" else p.selection
     var box=_box(color,p.border)
     if original is StyleBoxFlat:
      for corner in 4:box.set_corner_radius(corner,original.get_corner_radius(corner))
      for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:box.set_border_width(side,original.get_border_width(side))
     else:
      var radius=_custom_corner_radius(node)
      if radius>=0:box.set_corner_radius_all(radius)
     if state=="focus":box=_box(Color.TRANSPARENT,p.accent,2)
     for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:box.set_content_margin(side,original.get_content_margin(side))
     node.add_theme_stylebox_override(state,box)
  for key in ["font_color","default_color","font_hover_color","font_pressed_color"]:
   if node.has_theme_color_override(key):node.set_meta("fw_applied_"+key,node.get_theme_color(key))
  for state in ["panel","normal","hover","pressed","disabled","focus","background","fill"]:
   if node.has_theme_stylebox_override(state):node.set_meta("fw_applied_style_"+state,node.get_theme_stylebox(state))
 if node is ScrollContainer:node.follow_focus=true
 for child in node.get_children():_adapt(child)

func _watch_control(control:Control)->void:
 if control.has_meta("fw_theme_watch"):return
 control.set_meta("fw_theme_watch",true);control.theme_changed.connect(_overrides_changed.bind(weakref(control)))

func _under_custom_palette(control:Control)->bool:
 if host.get_meta("fw_owned_theme_root",false):return false
 var current:Node=control
 while current!=null:
  if current is Control and _has_custom_palette(current):return true
  if current==host:break
  current=current.get_parent()
 return false

func _overrides_changed(reference:WeakRef)->void:
 if _applying:return
 if is_inside_tree() and int(get_tree().get_meta("fw_appearance_write_depth_v1",0))>0:return
 var control=reference.get_ref()
 if control==null:return
 var custom:bool=not host.get_meta("fw_owned_theme_root",false) and _has_custom_palette(host)
 if custom!=_custom_palette_state and not _refresh_pending:
  _refresh_pending=true;call_deferred("_refresh_overrides")
 if _under_custom_palette(control):return
 var changed:=false
 for key in ["font_color","default_color","font_hover_color","font_pressed_color"]:
  if control.has_meta("fw_applied_"+key) and control.has_theme_color_override(key):
   var value:Color=control.get_theme_color(key)
   if value!=control.get_meta("fw_applied_"+key):
    control.set_meta("fw_original_"+key,value);changed=true
 if control.has_meta("fw_applied_font_size") and control.has_theme_font_size_override("font_size"):
  var value:int=control.get("theme_override_font_sizes/font_size")
  var owned_target:=roundi(float(control.get_meta("fw_original_font_size",value))*scale_percent/100.0)
  if value!=control.get_meta("fw_applied_font_size") and value!=owned_target:
   control.set_meta("fw_original_font_size",value);changed=true
 for state in ["panel","normal","hover","pressed","disabled","focus","background","fill"]:
  if control.has_meta("fw_applied_style_"+state) and control.has_theme_stylebox_override(state):
   var value:StyleBox=control.get_theme_stylebox(state)
   if value!=control.get_meta("fw_applied_style_"+state):
    control.set_meta("fw_original_style_"+state,value);changed=true
 if changed and not _refresh_pending:
  _refresh_pending=true;call_deferred("_refresh_overrides")

func _refresh_overrides()->void:
 _refresh_pending=false;apply()

func _child_added(child:Node)->void:
 if child!=self:call_deferred("_adapt_added",weakref(child))

func _adapt_added(reference:WeakRef)->void:
 var child=reference.get_ref()
 if child!=null and is_instance_valid(host) and (child==host or host.is_ancestor_of(child)) and not _refresh_pending:
  _refresh_pending=true;call_deferred("_refresh_overrides")

func open_find()->void:
 set_locale(_read_locale())
 if dialog==null:
  dialog=ConfirmationDialog.new();dialog.min_size=Vector2i(320,260);host.add_child(dialog)
  var body=VBoxContainer.new();dialog.add_child(body)
  query=LineEdit.new();body.add_child(query);query.text_changed.connect(_filter);query.text_submitted.connect(func(_text):focus_result())
  results=ItemList.new();results.custom_minimum_size=Vector2(300,180);results.size_flags_vertical=Control.SIZE_EXPAND_FILL;body.add_child(results)
  results.item_activated.connect(func(_i):focus_result());dialog.confirmed.connect(focus_result)
  set_locale(locale)
 actions.clear();_collect_actions(host);query.text="";_filter("")
 dialog.theme=get_theme();dialog.popup_centered(Vector2i(420,320));query.grab_focus()

func _collect_actions(node:Node)->void:
 if node==dialog or node==bar:return
 if node is Button and node.is_visible_in_tree() and not node.disabled and not node.text.strip_edges().is_empty():actions.append({"label":node.text,"search":node.text.to_lower(),"control":weakref(node)})
 for child in node.get_children():_collect_actions(child)

func _filter(text:String)->void:
 results.clear();filtered.clear();var term=text.strip_edges().to_lower()
 for action in actions:
  if term.is_empty() or term in action.search:
   results.add_item(action.label);filtered.append(action.control)
 if not filtered.is_empty():results.select(0)
 dialog.get_ok_button().disabled=filtered.is_empty()

func focus_result()->void:
 var indexes=results.get_selected_items()
 if indexes.is_empty() or indexes[0]>=filtered.size():return
 var control=filtered[indexes[0]].get_ref()
 if control!=null and control.is_visible_in_tree() and not control.disabled:
  dialog.hide();control.grab_focus()
