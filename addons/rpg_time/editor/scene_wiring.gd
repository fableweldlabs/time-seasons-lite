@tool
extends RefCounted
## Produces an explicit, undoable scene edit; never guesses among multiple lighting targets.
static func collect(root: Node, matches: Array, kind: String) -> void:
 if (kind == "clock" and root is FWClock) or (kind == "sun" and root is DirectionalLight3D) or (kind == "environment" and root is WorldEnvironment) or (kind == "canvas" and root is CanvasModulate): matches.append(root)
 for child in root.get_children(): collect(child,matches,kind)
static func plan(root: Node, profile: FWTimeProfile, mode: String) -> Dictionary:
 if root == null: return {"error":"Open a world scene first."}
 if profile == null or not profile.problems(true).is_empty(): return {"error":"Save or reload a valid Paid profile before connecting lighting."}
 if mode not in ["2d","3d"]: return {"error":"Choose 2D or 3D lighting."}
 var clocks: Array = []
 collect(root,clocks,"clock")
 if clocks.size() > 1: return {"error":"Multiple clocks found. Use the driver Inspector to choose your intended clock."}
 var suns: Array = []
 var environments: Array = []
 var canvases: Array = []
 collect(root,suns,"sun")
 collect(root,environments,"environment")
 collect(root,canvases,"canvas")
 if mode == "3d" and (suns.size() != 1 or environments.size() > 1): return {"error":"3D auto-connect needs exactly one DirectionalLight3D and at most one WorldEnvironment. Use manual paths for complex scenes."}
 if mode == "2d" and not canvases.is_empty(): return {"error":"This scene already has a CanvasModulate. Configure its driver instead of adding a second tint."}
 for child in root.find_children("*","Node",true,false):
  if child.get_script() == load("res://addons/rpg_time/paid/day_night_3d.gd") and mode == "3d": return {"error":"A 3D time-lighting driver already exists; adjust it in the Inspector."}
 var additions: Array[Node] = []
 var clock: FWClock = clocks[0] if not clocks.is_empty() else profile.make_clock()
 if clock == null: return {"error":"Save a valid profile first."}
 if clocks.is_empty():
  var suffix := 1
  var clock_name := "WorldTime"
  while root.get_node_or_null(NodePath(clock_name)) != null:
   suffix += 1
   clock_name = "WorldTime%d" % suffix
  clock.name = clock_name
  additions.append(clock)
 var driver: Node = load("res://addons/rpg_time/paid/day_night_2d.gd" if mode == "2d" else "res://addons/rpg_time/paid/day_night_3d.gd").new()
 driver.name = "TimeLighting"
 driver.lighting = profile.lighting
 # Paths originate at the future direct child driver, so prepend its parent step.
 driver.clock_path = NodePath("../" + str(root.get_path_to(clock))) if not clocks.is_empty() else NodePath("../" + str(clock.name))
 if mode == "3d":
  driver.sun_path = NodePath("../" + str(root.get_path_to(suns[0])))
  if not environments.is_empty(): driver.environment_path = NodePath("../" + str(root.get_path_to(environments[0])))
 additions.append(driver)
 return {"error":"","nodes":additions}

