extends Node

signal die
signal shield_die

export var MAX_SHIELD : float = 0 # no caldria perquè l'escut, se suposa que no es pot regenerar -ah, calla, amb les caus sí-, però per a les health bars potser convindria
var shield : int = 0

export var MAX_HEALTH : int = 150 
# 150 Tropes d'assalt, 1200 Caces estelars, 800 Interceptors, 2100 Bombarders, 3600 Naus de transport, 600000 Creuers 
var health : int = 0


func _ready() -> void:
	if health == 0:
		health = MAX_HEALTH
	
	shield = MAX_SHIELD


sync func take_damage(amount : int, obviar_shield : bool = false) -> void:
	if not health == 0: #pq si no moriria de nou, per evitar possibles bugs més q res -diria-
		if shield > 0 and not obviar_shield:
			shield -= amount
			shield = max(0, shield)
			if shield <= 0:
				emit_signal("shield_die")
		else:
			health -= amount
			health = max(0, health)
			if health <= 0:
				emit_signal("die")


sync func heal(amount : int) -> void:
	health += amount
	health = min(health, MAX_HEALTH)
