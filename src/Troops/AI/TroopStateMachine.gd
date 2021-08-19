extends "res://src/Troops/Player/StateMachine/StateMachine.gd"


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	states_map = {
		"ground_idle": $GroundIdle,
		"go_to_cp": $GoingToCP,
		"conquer": $Conquering,
		"search_ship": $SearchShip,
	}


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
