extends Node

onready var borderRC: RayCast2D = $borderRC
onready var bottomRC: RayCast2D = $bottomRC
onready var topRC: RayCast2D = $topRC

func can_jump():
	if bottomRC.is_colliding() and !topRC.is_colliding():
		if bottomRC.get_collider().is_in_group("World"): return true
	return false
