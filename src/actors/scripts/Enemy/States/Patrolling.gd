extends State

export var SPEED = 200

var waypoints
var next_waypoint_position

func enter(actor,_delta = 0.0):
	actor.set_debug_text("PATROLLING")
	actor.play_animation("patrol")
	if !waypoints: waypoints = actor.get_waypoints()
	next_waypoint_position = waypoints.get_next_point_position()
	print(waypoints.get_current_index())
	actor.set_facing(next_waypoint_position,0)
	
func update(actor,delta):
	var dir = 0
	if is_on_destination(actor,next_waypoint_position,delta):
		actor.position = next_waypoint_position
		#next_waypoint_position = waypoints.get_next_point_position()
		#actor.set_facing(next_waypoint_position,0)
		state_machine.set_state("Idle")
		actor.play_animation(actor.idles[waypoints.get_current_index()]) 
		return
	else:
		dir = actor.get_next_dir()
	actor.move(delta,dir,SPEED)

func is_on_destination(actor,target_position,delta):
	var motion = actor.facing * actor.current_speed * delta
	var distance_to_target = actor.position.distance_to(target_position)
	return true if motion.length() > distance_to_target else false

