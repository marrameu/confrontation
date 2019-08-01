extends Node

signal die

# Health
export(int) var max_health : int = 150 # const?
var health : int = 0

func _ready() -> void:
	if health == 0:
		health = max_health

sync func take_damage(amount : int) -> void:
	if not health == 0:
		health -= amount
		health = max(0, health)
		if health == 0:
			emit_signal("die")

sync func heal(amount : int) -> void:
	health += amount
	health = min(health, max_health)
