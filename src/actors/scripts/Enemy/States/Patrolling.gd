extends State

export var SPEED_MODIFIER = 2 setget ,get_max_speed
export var ACCELERATION = 20

var enemy_controller

var waypoints
var next_waypoint_position
var current_waypoint_index = 0
var current_speed = get_max_speed()

func get_max_speed():
	return SPEED_MODIFIER * Global.UNIT_SIZE

func enter(actor,_delta = 0.0):
	enemy_controller = actor.get_controller()
	actor.set_debug_text("PATROLLING")
	actor.warningSprite.visible = false
	actor.dangerSprite.visible = false
	waypoints = actor.get_waypoints()
	waypoints.set_current_index(current_waypoint_index)
	next_waypoint_position = waypoints.get_next_point_position()
	set_current_speed()
	enemy_controller.set_x_speed(get_max_speed())
	actor.set_fov_size(Vector2.ONE)
	actor.set_anim_speed(1.0)
	actor.play_animation("patrol")
	
func update(_actor,delta):
	var has_arrived = false
	if current_speed > get_max_speed():
		has_arrived = enemy_controller.update_movement(next_waypoint_position,get_slowing_speed(get_max_speed()),delta,0)
	else:
		has_arrived = enemy_controller.update_movement(next_waypoint_position,get_max_speed(),delta,0)
	if has_arrived:
		current_waypoint_index = waypoints.get_next_index()
		state_machine.set_state("Idle")

func set_current_speed():
	if !enemy_controller.get_x_speed():
		return
	if enemy_controller.get_x_speed() != get_max_speed():
		current_speed = enemy_controller.get_x_speed()
	else:
		current_speed = 0

func get_current_speed():
	current_speed += ACCELERATION
	current_speed = min(current_speed,get_max_speed())
	return current_speed

func get_slowing_speed(speed):
	current_speed = lerp(current_speed,speed,0.25)
	return current_speed

func on_player_detected():
	if !state_machine.is_player_hidden:
		state_machine.set_state("Searching")

func on_player_contact():
	state_machine.set_state("Searching")

func on_player_unhide():
	if state_machine.is_player_in_sight: 
		state_machine.set_state("Searching")

