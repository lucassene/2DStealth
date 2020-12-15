extends Node2D

onready var bottomRC: RayCast2D = $bottomRC
onready var topRC: RayCast2D = $topRC
onready var floorRC: RayCast2D = $floorRC

func enabled(value):
	bottomRC.enabled = value
	topRC.enabled = value

func can_grab_ledge():
	if bottomRC.is_colliding() and !topRC.is_colliding():
		return true
	return false

func is_in_air():
	if floorRC.is_colliding(): return false
	return true
