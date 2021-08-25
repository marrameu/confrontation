extends "res://src/Troops/Player/StateMachine/StateMachine.gd"

func _ready() -> void:
	states_map = {
		"idle": $Movement/Idle,
		"move": $Movement/Move,
		"jump": $Movement/Jump,
		"stagger": $Stagger,
		"shoot": $Attack/Shoot,
	}
