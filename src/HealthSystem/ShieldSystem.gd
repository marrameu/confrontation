extends "res://src/HealthSystem/HealthSystem.gd"

export var MAX_SHIELD := 300
var shield : float = 0.0

var _healing_shield := false
var _healing_speed := 50

func _ready():
	if health == 0:
		shield = MAX_SHIELD

func _process(delta : float) -> void:
	if shield != MAX_SHIELD:
		if _healing_shield:
			heal_shield(_healing_speed * delta)
		else:
			$ShieldTimer.start()


func heal_shield(amount : float):
	pass 


func _on_ShieldTimer_timeout():
	_healing_shield = true
