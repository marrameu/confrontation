extends Node

signal die

# Health
export(int) var max_health : int = 150 # const?
var health := 0

func _ready() -> void:
	if health == 0:
		health = max_health

sync func take_damage(amount : int) -> void:
	if health == 0:
		return
	health = clamp(health - amount, 0, max_health)
	if health == 0:
		emit_signal("die")
