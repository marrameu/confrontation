extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var ship_sensitivity := 75.0 # Antes 100
onready var initial_pos : Vector2 = $Control/Cursor.rect_position

var input : Vector2 

# Called when the node enters the scene tree for the first time.
func _ready():
	if LocalMultiplayer.number_of_players > 1:
		pass #ship_sensitivity /= 2

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if visible:
		$Control/Cursor.rect_position += Utilities.mouse_movement * delta * ship_sensitivity # Mouse speed?
		$Control/Cursor.rect_position = $Control/Cursor.rect_position.clamped(400)
	
		input.x = ($Control/Cursor.rect_position.x - initial_pos.x) / 400
		input.y = -($Control/Cursor.rect_position.y - initial_pos.y) / 400
