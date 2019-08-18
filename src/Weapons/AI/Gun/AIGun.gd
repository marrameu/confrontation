extends Gun


func _ready() -> void:
	$RayCast.global_transform.origin = get_parent().global_transform.origin
