extends State

export var JUMP_SPEED = 800
var enemy_controller

func enter(actor,_delta = 0.0):
	enemy_controller = actor.get_controller()
	actor.set_debug_text("JUMPING")
	actor.jump(JUMP_SPEED)

func update(_actor,delta):
	enemy_controller.update_air_movement(delta,JUMP_SPEED)
