extends StateMachine

var ladder = null
var wall = null
var ledge = null
var hideout = null

var can_grab_ledge = true setget set_can_grab_ledge,get_can_grab_ledge

enum CLIMB_DIR {
	UP,
	DOWN
}

func set_can_grab_ledge(new_value):
	can_grab_ledge = new_value

func get_can_grab_ledge():
	return can_grab_ledge

func _on_Player_on_ladder_entered(area):
	ladder = area

func _on_Player_on_ladder_exited():
	if get_current_state() == "Climbing":
		set_state("Idle")
	ladder = null

func _on_Player_on_wall_entered(area):
	wall = area

func _on_Player_on_wall_exited():
	wall = null

func _on_Player_on_ledge_entered(area):
	ledge = area
	set_can_grab_ledge(true)

func _on_Player_on_ledge_exited():
	ledge = null
	set_can_grab_ledge(false)

func _on_Player_on_hideout_entered(area):
	hideout = area

func _on_Player_hide():
	set_state("Hiding")

func _on_Player_on_hideout_exited():
	hideout = null
	if current_state == "Hiding": set_movement_state()

func set_movement_state():
	if actor.get_current_speed() == actor.states.Running.get_speed():
		set_state("Running")
	set_state("Walking")

func set_climb_state(dir):
	if dir == CLIMB_DIR.UP:
		ladder.set_platform_collision(true)
	else:
		ladder.set_platform_collision(false)
	actor.move_to_ladder(ladder)
	set_state("Climbing")

func set_wall_run_state():
	if wall:
		actor.move_to_wall(wall)
		set_state("Wall_Run")

func set_on_ledge_state():
	if ledge and can_grab_ledge:
		actor.move_to_ledge(ledge)
		set_state("On_Ledge")

func move_over_ledge():
	actor.move_over_ledge(ledge)

func set_hiding_state():
	actor.set_current_speed(actor.states.Crouch_Walk.get_speed())
	actor.move_to_hide(hideout)

func is_player_on_ladder_top():
	return true if ladder.position.y > actor.position.y else false
