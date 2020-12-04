extends State

export var SPEED = 200

var enemy_controller

var waypoints
var next_waypoint_position
var current_waypoint_index = 0

func enter(actor,_delta = 0.0):
	enemy_controller = actor.get_controller()
	actor.set_debug_text("PATROLLING")
	if !waypoints: waypoints = actor.get_waypoints()
	waypoints.set_current_index(current_waypoint_index)
	next_waypoint_position = waypoints.get_next_point_position()
	enemy_controller.set_facing(next_waypoint_position,0)
	actor.set_fov_size(Vector2.ONE)
	actor.set_anim_speed(1.0)
	actor.play_animation("patrol")
	
func update(actor,delta):
	var has_arrived = enemy_controller.update_movement(next_waypoint_position,SPEED,delta,0)
	if has_arrived:
		state_machine.set_state("Idle")
		current_waypoint_index = waypoints.get_next_index()
		actor.play_animation(waypoints.get_current_animation())

func on_player_detected(player):
	state_machine.set_searching_state(player)

func on_player_contact(player):
	state_machine.set_searching_state(player)

