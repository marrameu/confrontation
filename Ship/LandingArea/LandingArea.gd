extends Area

func _on_LandingArea_body_entered(body : CollisionObject) -> void:
	if body.is_in_group("Ships"):
		body.landing_areas += 1

func _on_LandingArea_body_exited(body : CollisionObject) -> void:
	if body.is_in_group("Ships"):
		body.landing_areas -= 1
