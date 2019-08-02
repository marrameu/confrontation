extends Spatial

# State
var shooting := false

# Particles
const hit_scene : PackedScene = preload("res://Bullets/Particles/HitParticles.tscn")

func _ready() -> void:
	$RayCast.global_transform.origin = get_parent().global_transform.origin

func _process(delta : float) -> void:
	pass

func start_shooting() -> void:
	shooting = true
	($Timer as Timer).start()

func stop_shooting() -> void:
	shooting = false
	($Timer as Timer).stop()

# Millorar per l'online i altres?
func shoot() -> void:
	# $AudioStreamPlayer3D.play() Volver a activar cuando configure el audio y las zonas 3d
	# Shoot Offset
	$RayCast.cast_to = Vector3(rand_range(-60, 60), rand_range(-60, 60), $RayCast.cast_to.z)
	var collider = ($RayCast as RayCast).get_collider()
	var point = ($RayCast as RayCast).get_collision_point()
	if collider:
		hit(collider.get_path(), point)

func _on_Timer_timeout() -> void:
	shoot()

sync func hit(collider_path : NodePath, point : Vector3) -> void:
	var hit : Particles = hit_scene.instance()
	get_node("/root/Main").add_child(hit)
	hit.global_transform.origin = point
	
	if not get_node(collider_path):
		return
	var collider : CollisionObject = get_node(collider_path)
	if collider.is_in_group("Players") or collider.is_in_group("Troops"):
		if collider.get_node("TroopManager").m_team !=  get_node("../../TroopManager").m_team:
			var damage := 40
			if collider.translation.y > collider.get_global_transform().origin.y + 0.85:
				damage = 40
			else:
				damage = 20 
			# Server
			if get_tree().has_network_peer():
				if get_tree().is_network_server():
					collider.get_node("HealthSystem").rpc("take_damage", damage)
			else:
				collider.get_node("HealthSystem").take_damage(damage)
