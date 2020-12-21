extends State

export var HEIGHT_MODIFIER = 1.1 setget ,get_height
export var JUMP_DURATION = 0.5
var enemy_controller
var current_jump_speed

func get_height():
	return HEIGHT_MODIFIER * Global.UNIT_HEIGHT

func enter(actor,_delta = 0.0):
	enemy_controller = actor.get_controller()
	actor.set_debug_text("JUMPING")
	set_gravity(actor)
	if state_machine.get_is_alerted():
		actor.rotate_sight()
	enemy_controller.set_y_speed(current_jump_speed)
	enemy_controller.jump(current_jump_speed)

func update(actor,delta):
	if state_machine.get_is_alerted():
		actor.rotate_sight()
	enemy_controller.update_air_movement(delta)

func set_gravity(actor):
	actor.set_gravity(2 * get_height() / pow(JUMP_DURATION,2))
	current_jump_speed = sqrt(2 * actor.get_gravity() * get_height())
