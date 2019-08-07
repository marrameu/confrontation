extends Node

signal die

# Health
export(int) var MAX_HEALTH : int = 150
var health : int = 0

func _ready() -> void:
	if health == 0:
		health = MAX_HEALTH

sync func take_damage(amount : int) -> void:
	if not health == 0:
		health -= amount
		health = max(0, health)
		if health == 0:
			emit_signal("die")

sync func heal(amount : int) -> void:
	health += amount
	health = min(health, MAX_HEALTH)
