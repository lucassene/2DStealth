extends State

var player_controller

func enter(actor,delta = 0.0):
	player_controller = actor.get_player_controller()
	actor.set_debug_text("WALL SLIDE")
	actor.move(delta,Vector2.ZERO,state_machine.get_x_speed(),state_machine.get_y_speed(),Vector2.ZERO)

func update(actor,delta):
	actor.move(delta,Vector2.ZERO,state_machine.get_x_speed(),state_machine.get_y_speed(),Vector2.ZERO)
	if actor.is_on_floor(): state_machine.set_state("Idle")

func handle_input(event):
	if player_controller.check_input_pressed(event,"jump","jump"): return
