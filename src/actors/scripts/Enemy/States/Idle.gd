extends State

var enemy_controller

func enter(actor, _delta = 0.0):
	enemy_controller = actor.get_controller()
	actor.set_debug_text("IDLE")

func _on_idle_anim_finished():
	state_machine.set_state("Patrolling")

func on_player_detected(player):
	state_machine.set_searching_state(player)
