extends Node

onready var physics : ShipPhysics = get_node("../../Physics") # ¿?
onready var ship : Ship = get_node("../../") # ¿?

var pitch := 0.0
var yaw := 0.0
var roll := 0.0
var strafe := 0.0
var throttle := 0.0
export(float, -1, 1) var min_throttle := 0.3
