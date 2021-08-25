extends Area


func _ready() -> void:
	connect("body_entered", self, "_on_body_entered")
	connect("body_exited", self, "_on_body_exited")


func _on_body_entered(body : CollisionObject) -> void:
	if body.is_in_group("Ships"):
		body.landing_areas += 1


func _on_body_exited(body : CollisionObject) -> void:
	if body.is_in_group("Ships"):
		body.landing_areas -= 1
