extends Node

# Graphics
var quality := 1 # Medium

# Controls
var mouse_sensitivity := 0.6
var joystick_sensitivity := 0.6
var controller_input := false

# Others
var fov := 70


func _ready() -> void:
	load_settings()


func apply_settings():
	if quality == 0:
		ProjectSettings["rendering/quality/voxel_cone_tracing/high_quality"] = false
		get_node("/root/Main/WorldEnvironment").environment.ssao_enabled = false
		get_tree().get_root().msaa = Viewport.MSAA_2X
	elif quality == 1:
		ProjectSettings["rendering/quality/voxel_cone_tracing/high_quality"] = false
		get_tree().get_root().msaa = Viewport.MSAA_4X
	elif quality == 2:
		ProjectSettings["rendering/quality/voxel_cone_tracing/high_quality"] = false # Canviar en un futur
		get_tree().get_root().msaa = Viewport.MSAA_8X


func load_settings():
	var f = File.new()
	var error = f.open("user://settings.json", File.READ)
	if error:
		print("No settings to load...")
		return
	var d = parse_json(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return
	if "quality" in d:
		quality = int(d.quality)
	if "mouse_sensitivity" in d:
		mouse_sensitivity = float(d.mouse_sensitivity)
	if "joystick_sensitivity" in d:
		joystick_sensitivity = float(d.joystick_sensitivity)
	if "controller_input" in d:
		controller_input = bool(d.controller_input)
	if "fov" in d:
		fov = int(d.fov)


func save_settings():
	var f = File.new()
	var error = f.open("user://settings.json", File.WRITE)
	assert( not error )
	
	var d = { "quality":quality, "mouse_sensitivity":mouse_sensitivity, "joystick_sensitivity":joystick_sensitivity, "controller_input":controller_input, "fov":fov }
	f.store_line( to_json(d) )
