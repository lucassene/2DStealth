extends Node

onready var actor = owner
onready var state_machine

var facing = Vector2.LEFT setget ,get_facing
var next_dir = 0 setget ,get_next_dir
var next_dir_time = 0
var reaction_time = 450
var y_speed setget set_y_speed,get_y_speed
var x_speed setget set_x_speed,get_x_speed

func get_facing():
	return facing

func get_next_dir():
	return next_dir

func set_y_speed(value):
	y_speed = value

func get_y_speed():
	return y_speed
	
func set_x_speed(value):
	x_speed = value

func get_x_speed():
	return x_speed

func initialize(machine,reaction):
	state_machine = machine
	reaction_time = reaction

func update_movement(target,speed,delta,offset):
	var previous_facing = facing
	var dir = 0
	set_facing(target,offset)
	if actor.can_jump():
		state_machine.set_air_state("Jumping")
		return
	var target_position = get_target_position_with_offset(target,offset)
	if is_on_destination(target_position,speed,delta):
		actor.position = target_position
		facing = previous_facing
		actor.turn(facing)
		return true
	elif state_machine.get_current_state() == "Alerted" and OS.get_ticks_msec() > next_dir_time:
		dir = next_dir
	elif state_machine.get_current_state() != "Alerted":
		dir = next_dir
	actor.turn(facing)
	actor.move(delta,dir,speed)
	return false

func jump(speed):
	actor.jump(facing.x,x_speed,speed)

func update_air_movement(delta):
	var velocity = actor.move(delta,facing.x,x_speed)
	if velocity.y > 1.0 and !actor.is_on_floor(): 
		state_machine.set_state("Falling")
	elif actor.is_on_floor():
		state_machine.back_from_air()

func get_target_position_with_offset(target,offset):
	var pos = (target.x + offset) * facing.x
	return Vector2(pos,target.y)

func is_on_destination(target_position,speed,delta):
	var motion = facing * speed * delta
	var distance_to_target = actor.position.distance_to(target_position)
	return true if motion.length() > distance_to_target else false

func set_facing(target_position,offset):
	if target_position.x < actor.position.x - offset:
		set_chase_direction(-1)
		facing = Vector2.LEFT
	elif target_position.x > actor.position.x + offset:
		set_chase_direction(1)
		facing = Vector2.RIGHT
	elif target_position.x < actor.position.x:
		set_chase_direction(0)
		facing = Vector2.LEFT
	elif target_position.x > actor.position.x:
		set_chase_direction(0)
		facing = Vector2.RIGHT

func set_chase_direction(target_dir):
	if next_dir != target_dir:
		next_dir = target_dir
		next_dir_time = OS.get_ticks_msec() + reaction_time
