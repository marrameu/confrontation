extends "res://src/Troops/Player/StateMachine/StateMachine.gd"


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	# si no és el servidor que es desactivi l'state machine (active) o crear un estat Client
	states_map = {
		"chose_objective": $ChoseObjective,
		"ground_idle": $GroundIdle,
		"go_to_cp": $GoToCP,
		"conquer": $Conquer,
		"search_ship": $SearchShip,
		#"dead": $Dead
	}


func _on_PathMaker_arrived():
	if not _active:
		return
	current_state._on_PathMaker_arrived()
