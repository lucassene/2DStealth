extends State

var waypoints

func enter(actor, _delta = 0.0):
	actor.set_debug_text("IDLE")
	actor.warningSprite.visible = false
	actor.dangerSprite.visible = false
	waypoints = actor.get_waypoints()
	actor.play_animation(waypoints.get_current_animation())

func _on_idle_anim_finished():
	state_machine.set_state("Patrolling")

func on_player_detected():
	if !state_machine.is_player_hidden: 
		state_machine.set_state("Searching")

func on_player_contact():
	state_machine.set_state("Searching")

func on_player_unhide():
	if state_machine.is_player_in_sight:
		state_machine.set_state("Searching")
