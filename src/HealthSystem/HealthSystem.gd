extends Node

signal die

export var MAX_HEALTH : int = 150 
# 150 Tropes d'assalt, 1200 Caces estelars, 800 Interceptors, 2100 Bombarders, 3600 Naus de transport, 600000 Creuers 
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
