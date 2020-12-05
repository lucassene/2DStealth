extends State

var enemy_controller

var waypoints

func enter(actor, _delta = 0.0):
	enemy_controller = actor.get_controller()
	actor.set_debug_text("IDLE")
	waypoints = actor.get_waypoints()
	actor.play_animation(waypoints.get_current_animation())

func _on_idle_anim_finished():
	state_machine.set_state("Patrolling")

func on_player_detected():
	if !state_machine.is_player_hidden: 
		state_machine.set_state("Searching")

func on_player_unhide():
	if state_machine.is_player_in_sight:
		state_machine.set_state("Searching")
