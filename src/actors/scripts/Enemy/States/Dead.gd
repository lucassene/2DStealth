extends State

func enter(actor,_delta = 0.0):
	actor.set_debug_text("DEAD")
	actor.enter_dead_state()

