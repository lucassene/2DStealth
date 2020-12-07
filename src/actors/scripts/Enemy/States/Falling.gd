extends State

export var FALL_SPEED = 600
var enemy_controller

func enter(actor,_delta = 0.0):
	enemy_controller = actor.get_controller()
	actor.set_debug_text("FALLING")

func update(_actor,delta):
	enemy_controller.update_air_movement(delta,FALL_SPEED)

