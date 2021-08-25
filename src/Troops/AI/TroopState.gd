tool
extends "res://src/Troops/Player/StateMachine/State.gd"


func _get_configuration_warning() -> String:
	var warning := ""
	if owner != Troop:
		warning = "L''owner' de l'estat no és una tropa"
	return warning

