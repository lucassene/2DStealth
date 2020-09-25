extends State

onready var player_controller = get_node("../PlayerController")

func enter(actor, _delta = 0.0):
	actor.set_debug_text("ON LEDGE")

func handle_input(event):
	if player_controller.check_input_pressed(event,"climb_up","move_over_ledge"): return
	if player_controller.check_input_pressed(event,"climb_down","enter_falling"): 
		state_machine.set_can_grab_ledge(false)
		return
	if player_controller.check_input_pressed(event,"jump","jump"): return

func update(_actor,_delta):
	if !state_machine.ledge:
		state_machine.set_state("Idle")
