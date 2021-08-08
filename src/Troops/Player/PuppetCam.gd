extends Camera


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var target : Spatial = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	"""
	dubt que açò retrassi el joc un fps, car el node Splitscreen -que és el
	que conté els viewpors i, per tant, aquestes càmeres- és el primer del
	arbre, ergo serà l'últim en executar-se.
	Però si sí retrasses el joc, fer alguna invenció per senyals.
	"""
	translation = target.global_transform.origin
	rotation = target.global_transform.basis.get_euler()
