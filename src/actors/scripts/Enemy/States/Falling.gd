extends State

var enemy_controller

func enter(actor,_delta = 0.0):
	enemy_controller = actor.get_controller()
	actor.set_debug_text("FALLING")
	if state_machine.get_is_alerted():
		actor.rotate_sight()

func update(actor,delta):
	if state_machine.get_is_alerted():
		actor.rotate_sight()
	enemy_controller.update_air_movement(delta)

