extends State

func enter(actor, _delta = 0.0):
	actor.set_debug_text("IDLE")

func _on_idle_anim_finished():
	state_machine.set_state("Patrolling")
