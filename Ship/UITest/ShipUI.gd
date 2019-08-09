extends Control

var cursor_limit := 450
var ship_sensitivity := 75.0 # Abans 100
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
		$Control/Cursor.rect_position = $Control/Cursor.rect_position.clamped(cursor_limit)
	
		input.x = ($Control/Cursor.rect_position.x - initial_pos.x) / cursor_limit
		input.y = -($Control/Cursor.rect_position.y - initial_pos.y) / cursor_limit
