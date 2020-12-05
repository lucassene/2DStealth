extends State

export var SPEED = 200

var enemy_controller

var waypoints
var next_waypoint_position
var current_waypoint_index = 0

func enter(actor,_delta = 0.0):
	enemy_controller = actor.get_controller()
	actor.set_debug_text("PATROLLING")
	waypoints = actor.get_waypoints()
	waypoints.set_current_index(current_waypoint_index)
	next_waypoint_position = waypoints.get_next_point_position()
	actor.set_fov_size(Vector2.ONE)
	actor.set_anim_speed(1.0)
	actor.play_animation("patrol")
	
func update(_actor,delta):
	var has_arrived = enemy_controller.update_movement(next_waypoint_position,SPEED,delta,0)
	if has_arrived:
		current_waypoint_index = waypoints.get_next_index()
		state_machine.set_state("Idle")

func on_player_detected():
	if !state_machine.is_player_hidden:
		state_machine.set_state("Searching")

func on_player_contact():
	state_machine.set_state("Searching")

func on_player_unhide():
	if state_machine.is_player_in_sight: 
		state_machine.set_state("Searching")

