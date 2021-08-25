extends Node

class_name InputManager

var number_of_device := 0
onready var number_of_player : int = get_parent().number_of_player

# Input
var input_map = {
	"shoot" : "",
	#
	"move_forward" : "",
	"move_backward" : "",
	"move_left" : "",
	"move_right" : "",
	#
	"jump" : "",
	"run" : "",
	"crouch" : "",
	#
	"zoom" : "",
	"zoom_ship" : "",
	"change_view" : "",
	"look_behind" : "",
	"camera_up" : "",
	"camera_down" : "",
	"camera_right" : "",
	"camera_left" : "",
	#
	"pause" : "",
	"interact" : ""
}

func _ready():
	if LocalMultiplayer.number_of_players == 1:
		return
	
	number_of_device = LocalMultiplayer.controller_of_each_player[number_of_player - 1]
	
	# Es pot fer una funció per a no tenir de repetir-ho tants cops
	var a : String = "_player_" + String(number_of_player)
	input_map.shoot = "shoot" + a
	input_map.move_forward = "move_forward" + a
	input_map.move_backward = "move_backward" + a
	input_map.move_left = "move_left" + a
	input_map.move_right = "move_right" + a
	if number_of_device != -1:
		input_map.camera_up = "camera_up" + a
		input_map.camera_down = "camera_down" + a
		input_map.camera_right = "camera_right" + a
		input_map.camera_left = "camera_left" + a
	input_map.jump = "jump" + a
	input_map.run = "run" + a
	input_map.crouch = "crouch" + a
	input_map.zoom = "zoom" + a
	input_map.zoom_ship = "zoom_ship" + a
	input_map.change_view = "change_view" + a
	input_map.look_behind = "look_behind" + a
	input_map.pause = "pause" + a
	input_map.interact = "interact" + a
