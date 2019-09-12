extends Node

# Mouse
var mouse_position := Vector2()
var mouse_movement := Vector2()
var mouse_acceleration := Vector2() # Not ready

# Time
var time := 0.0

func play_button_audio() -> void:
	var button_audio : AudioStreamPlayer = AudioStreamPlayer.new()
	button_audio.set_stream(preload("res://assets/audio/button_sfx.wav"))
	button_audio.connect("finished", button_audio, "queue_free")
	var current_scene = get_tree().get_root().get_child(get_tree().get_root().get_child_count() -1)
	current_scene.add_child(button_audio)
	button_audio.play()


func _input(event : InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_movement = event.relative
		mouse_position = event.position


func _process(delta : float) -> void:
	mouse_movement = Vector2()
	time = OS.get_ticks_msec() / 1000.0 # Pausa?


func canvas_scaler(number_of_player : int, canvas : CanvasLayer) -> void:
	if LocalMultiplayer.number_of_players == 2:
		canvas.scale = Vector2(0.5, 0.5)
		match number_of_player:
			1:
				canvas.offset = Vector2(480, 0) 
			2:
				canvas.offset = Vector2(480, 540)
		
	elif LocalMultiplayer.number_of_players > 1:
		canvas.scale = Vector2(0.5, 0.5)
		match number_of_player:
			1:
				canvas.offset = Vector2(0, 0) 
			2:
				canvas.offset = Vector2(960, 0)
			3:
				canvas.offset = Vector2(0, 540)
			4:
				canvas.offset = Vector2(960, 540)
