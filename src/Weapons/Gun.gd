extends Spatial
class_name Gun

"""
Serveix tant a jugadors com a bots ja que l'unic necesari per disparar es
canviar la variable _shooting a true.

Té un raycast per a determinar on ha de dsisparar, en el cas de la IA,
el raycast es reposiciona al seu centre, mentrés que en els jugadors aquest 
es posiciona en la càmara. En el futur no serà necesari reposicionar-ho.

També du un Audio3D com a fill per al só de dispar

Emet quatre senyals: shoot, quan el dispar té lloc;
hit, quan el raycast col·lisiona amb qualsevol objecte;
shot, quan el dispar té lloc amb el dany normal; headshot, quan el dispar
té lloc amb el dany especial o dany 'headshot'.

---

S'hauria de crear una variable per a determinar el retrocés.

Com fer per a que el só es sincronitzi online? Senyals?
"""

signal shoot
signal hit
signal shot
signal headshot

const hit_scene = preload("res://src/Bullets/Particles/HitParticles.tscn")

export var continuous := true
export var fire_rate := 5.0

export var shoot_range := 500
export var offset := Vector2(60, 60)

export var shot_damage := 25
export var headshot_damage := 50

var _next_time_to_fire := 0.0

var m_team := 0
var shooting := false


func _ready() -> void:
	m_team = get_node("../../TroopManager").m_team


func _process(delta : float) -> void:
	if shooting and Utilities.time >= _next_time_to_fire:
		_next_time_to_fire = Utilities.time + 1.0 / fire_rate
		_shoot()


func _shoot() -> void:
	emit_signal("shoot")
	
	if not continuous:
		shooting = false
	
	$Audio.play()
	
	# zoom /2
	var x = rand_range(-offset.x, offset.x)
	var y = rand_range(-offset.y, offset.y)
	$RayCast.cast_to = Vector3(x, y, shoot_range)
	
	var collider = $RayCast.get_collider()
	var point = $RayCast.get_collision_point()
	if collider:
		if get_tree().has_network_peer():
			#if owner.is_network_master():
			rpc("_hit", collider.get_path(), point)
		else:
			_hit(collider.get_path(), point)


sync func _hit(collider_path : NodePath, point : Vector3) -> void:
	var root = get_tree().get_root()
	var current_scene = root.get_child(root.get_child_count() - 1)
	
	# Consumeix molt rendiment instanciar les particules
	var hit : Particles = hit_scene.instance()
	current_scene.add_child(hit)
	hit.global_transform.origin = point
	
	emit_signal("hit", point)
	
	if not get_node(collider_path):
		return
	
	if get_tree().has_network_peer():
		if not get_tree().is_network_server():
			return
	
	var collider : CollisionObject = get_node(collider_path)
	var damage := shot_damage
	
	if collider.is_in_group("Troops"):
		if collider.get_node("TroopManager").m_team != m_team:
			if point.y > collider.get_global_transform().origin.y + 1.2:
				damage = headshot_damage
				emit_signal("headshot", collider_path)
			else:
				emit_signal("shot", collider_path)
			
			if get_tree().has_network_peer():
				collider.get_node("HealthSystem").rpc("take_damage", damage)
			else:
				collider.get_node("HealthSystem").take_damage(damage)
		
	elif collider.is_in_group("Ships"):
		emit_signal("shot", collider_path)
		
		if get_tree().has_network_peer():
			collider.get_node("HealthSystem").rpc("take_damage", damage)
		else:
			collider.get_node("HealthSystem").take_damage(damage)
