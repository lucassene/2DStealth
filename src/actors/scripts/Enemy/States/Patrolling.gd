extends State

export var SPEED = 200

var waypoints
var next_waypoint_position
var current_waypoint_index = 0

func _on_player_detected(player):
	state_machine.set_searching_state(player)

func enter(actor,_delta = 0.0):
	actor.set_debug_text("PATROLLING")
	if !waypoints: waypoints = actor.get_waypoints()
	waypoints.set_current_index(current_waypoint_index)
	next_waypoint_position = waypoints.get_next_point_position()
	actor.set_facing(next_waypoint_position,0)
	actor.set_fov_size(Vector2.ONE)
	actor.play_animation("patrol")
	
func update(actor,delta):
	var dir = 0
	if is_on_destination(actor,next_waypoint_position,delta):
		actor.position = next_waypoint_position
		state_machine.set_state("Idle")
		current_waypoint_index = waypoints.get_next_index()
		actor.play_animation(actor.idles[current_waypoint_index]) 
		return
	else:
		dir = actor.get_next_dir()
	actor.move(delta,dir,SPEED)

func is_on_destination(actor,target_position,delta):
	var motion = actor.facing * actor.current_speed * delta
	var distance_to_target = actor.position.distance_to(target_position)
	return true if motion.length() > distance_to_target else false

