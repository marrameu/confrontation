extends Node

var mouse_position := Vector2()
var mouse_movement := Vector2()
var mouse_acceleration := Vector2()

func play_button_audio() -> void:
	var button_audio : AudioStreamPlayer = AudioStreamPlayer.new()
	button_audio.set_stream(preload("res://Audio/button_sfx.wav"))
	button_audio.connect("finished", button_audio, "queue_free")
	var current_scene = get_tree().get_root().get_child(get_tree().get_root().get_child_count() -1)
	current_scene.add_child(button_audio)
	button_audio.play()

func _input(event):
	if event is InputEventMouseMotion:
		mouse_movement = event.relative
		mouse_acceleration = event.speed # No va???
		mouse_position = event.position

func _process(delta):
	#mouse_acceleration = Vector2()
	mouse_movement = Vector2()
