extends Control

var cursor_limit := 450
var min_position := 20 # TEST
var ship_sensitivity := 75.0 # Abans 100
onready var initial_pos : Vector2 = $Control/Cursor.rect_position

# Tots els nodes de la nau agafen l'input des d'aquí, millor que l'agafin des del node PlayerInput
var input : Vector2

func _ready():
	if LocalMultiplayer.number_of_players > 1:
		pass # variable per a la sensibilitat en el mode multijugador, aquesta es multiplica per 2

func _physics_process(delta):
	if visible:
		$Control/Cursor.rect_position += Utilities.mouse_movement * delta * ship_sensitivity # Mouse speed?
		$Control/Cursor.rect_position = $Control/Cursor.rect_position.clamped(cursor_limit)
		
		if $Control/Cursor.rect_position.length() > min_position:
			input.x = ($Control/Cursor.rect_position.x - initial_pos.x) / cursor_limit
			input.y = -($Control/Cursor.rect_position.y - initial_pos.y) / cursor_limit
		else:
			input = Vector2()
	else:
		$Control/Cursor.rect_position = Vector2()
		input = Vector2()
