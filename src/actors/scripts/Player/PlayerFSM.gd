extends StateMachine

var player_controller

var ladder = null
var first_wall = null
var second_wall = null
var current_ledge = null
var previous_ledge = null setget set_previous_ledge
var hideout = null

var can_grab_ledge = true setget set_can_grab_ledge,get_can_grab_ledge
var x_speed = 0.0 setget set_x_speed,get_x_speed
var y_speed = 0.0 setget set_y_speed,get_y_speed
var current_climb_dir = Vector2.ZERO

enum CLIMB_DIR {
	UP,
	DOWN
}

func set_can_grab_ledge(new_value):
	can_grab_ledge = new_value

func get_can_grab_ledge():
	return can_grab_ledge

func set_previous_ledge(value):
	previous_ledge = value

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
		ladder.set_platform_collision(true)
		actor.velocity.y = 0
		set_state("Idle")
	ladder = null

func _on_Player_on_wall_entered(area):
	if first_wall and first_wall != area:
		second_wall = first_wall
	if !first_wall or first_wall != area:
		first_wall = area

func _on_Player_on_wall_exited(area):
	if first_wall == area:
		first_wall = null
	if second_wall == area:
		second_wall = null

func _on_Player_on_ledge_entered(area):
	current_ledge = area
	set_can_grab_ledge(true)

func _on_Player_on_ledge_exited():
	if current_state == "On_Ledge":
		set_state("Idle")
	previous_ledge = current_ledge
	current_ledge = null
	set_can_grab_ledge(false)

func _on_Player_on_hideout_entered(area):
	hideout = area

func _on_Player_hide():
	set_state("Hiding")

func _on_Player_on_hideout_exited(area):
	if area == hideout:
		hideout = null

func _on_hideout_body_exited():
	if current_state == "Hiding": set_state("Walking")

func _on_CoyoteTimer_timeout():
	set_state("Falling")

func initialize(first_state):
	.initialize(first_state)
	player_controller = actor.get_player_controller()
	player_controller.set_state_machine(self)
	x_speed = states.Walking.get_max_speed()
	states.Jumping.set_gravity(actor)

func update(delta):
	.update(delta)

func set_movement_state():
	if x_speed == states.Running.get_max_speed():
		set_state("Running")
		return
	if x_speed == states.Walking.get_max_speed():
		set_state("Walking")
		return
	if x_speed == states.Crouch_Walk.get_max_speed():
		set_state("Crouch")
		return

func set_climb_state(dir):
	if dir == CLIMB_DIR.UP:
		ladder.set_platform_collision(true)
	else:
		ladder.set_platform_collision(false)
	current_climb_dir = dir
	actor.move_to_area(ladder,0)
	set_state("Climbing")

func set_wall_run_state(wall):
	if wall and actor.check_pos_to_wall(wall):
		actor.move_to_area(wall,0)
		set_state("Wall_Run")

func set_on_ledge_state():
	if current_ledge and current_ledge != previous_ledge and can_grab_ledge and actor.can_grab_check(current_ledge):
		actor.move_to_area(current_ledge)
		set_state("On_Ledge")

func move_over_ledge():
	actor.move_over_ledge(current_ledge)

func set_hiding_state():
	actor.set_current_speed(states.Crouch_Walk.get_max_speed())
	actor.move_to_hide(hideout)

func reset_x_speed():
	x_speed = states.Walking.get_max_speed()

func reset_gravity():
	states.Jumping.set_gravity(actor)

func is_player_on_ladder_top():
	return true if ladder.get_top_position() >= actor.position.y else false

func is_in_grounded_state():
	if current_state == "Walking" or current_state == "Running" or current_state == "Crouch_Walk" or current_state == "Idle" or current_state == "Crouch" or current_state == "Crouch_Walk":
		return true
	else:
		return false

func get_wall_to_run():
	if first_wall and first_wall.get_enter_vector() == actor.get_facing():
		return first_wall
	if second_wall and second_wall.get_enter_vector() == actor.get_facing():
		return second_wall
	return null

#func is_in_airbone_state():
#	if current_state == "Jumping" or current_state == "Falling" or current_state == "Wall_Run" or current_state == "Wall_Slide":
#		return true
#	else:
#		return false
