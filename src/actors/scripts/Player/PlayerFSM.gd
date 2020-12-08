extends StateMachine

var player_controller

var ladder = null
var wall = null
var ledge = null
var hideout = null

var can_grab_ledge = true setget set_can_grab_ledge,get_can_grab_ledge
var x_speed = 0.0 setget set_x_speed,get_x_speed
var y_speed = 0.0 setget set_y_speed,get_y_speed

enum CLIMB_DIR {
	UP,
	DOWN
}

func set_can_grab_ledge(new_value):
	can_grab_ledge = new_value

func get_can_grab_ledge():
	return can_grab_ledge

func set_x_speed(new_value):
	x_speed = new_value

func get_x_speed():
	return x_speed

func set_y_speed(new_value):
	y_speed = new_value

func get_y_speed():
	return y_speed

func _on_Player_on_ladder_entered(area):
	ladder = area

func _on_Player_on_ladder_exited():
	if get_current_state() == "Climbing":
		actor.velocity.y = 0
		set_state("Idle")
	ladder = null

func _on_Player_on_wall_entered(area):
	print("entrou")
	wall = area

func _on_Player_on_wall_exited():
	print("saiu")
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

func _on_CoyoteTimer_timeout():
	#reset_gravity()
	set_state("Falling")

func initialize(first_state):
	.initialize(first_state)
	player_controller = actor.get_player_controller()
	player_controller.set_state_machine(self)
	x_speed = states.Walking.get_speed()
	states.Jumping.set_gravity(actor)

func update(delta):
	.update(delta)

func set_movement_state():
	if x_speed == states.Running.get_speed():
		set_state("Running")
		return
	if x_speed == states.Walking.get_speed():
		set_state("Walking")
		return
	if x_speed == states.Crouch_Walk.get_speed():
		set_state("Crouch")
		return

func set_climb_state(dir):
	if dir == CLIMB_DIR.UP:
		ladder.set_platform_collision(true)
	else:
		ladder.set_platform_collision(false)
	actor.move_to_ladder(ladder)
	set_state("Climbing")

func set_wall_run_state():
	if wall and actor.can_wallrun_check(wall):
		actor.move_to_wall(wall)
		set_state("Wall_Run")

func set_on_ledge_state():
	if ledge and can_grab_ledge:
		actor.move_to_ledge(ledge)
		set_state("On_Ledge")

func move_over_ledge():
	actor.move_over_ledge(ledge)

func set_hiding_state():
	actor.set_current_speed(states.Crouch_Walk.get_speed())
	actor.move_to_hide(hideout)

func reset_gravity():
	states.Jumping.set_gravity(actor)

func is_player_on_ladder_top():
	return true if ladder.position.y > actor.position.y else false

func is_in_grounded_state():
	if current_state == "Walking" or current_state == "Running" or current_state == "Crouch_Walk" or current_state == "Idle" or current_state == "Crouch" or current_state == "Crouch_Walk":
		return true
	else:
		return false

func is_in_airbone_state():
	if current_state == "Jumping" or current_state == "Falling" or current_state == "Wall_Run" or current_state == "Wall_Slide":
		return true
	else:
		return false
