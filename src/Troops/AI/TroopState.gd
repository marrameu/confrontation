tool
extends "res://src/Troops/Player/StateMachine/State.gd"

func _process(delta):
	if Engine.editor_hint:
		assert(owner != Troop)
