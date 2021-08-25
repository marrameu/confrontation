extends Gun


func _ready() -> void:
	$RayCast.global_transform.origin = owner.global_transform.origin
