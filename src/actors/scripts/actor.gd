extends KinematicBody2D
class_name Actor

export var speed = 500.0
export var run_speed = 800.0
export var wall_speed = 1500.0
export var wall_jump_speed = 1000
export var max_speed = 800.0
export var crouch_speed = 200
export var climb_speed = 250.0
export var jump_time = 0.6
export var jump_speed = 1150.0
export var gravity = 3200.0
export var max_gspeed = 4000.0

const FLOOR_NORMAL = Vector2.UP
const SNAP_DIRECTION = Vector2.DOWN
const SNAP_LENGTH = 32.0
const SLOPE_THRESHOLD = deg2rad(46)

var velocity = Vector2.ZERO
var snap_vector = SNAP_DIRECTION * SNAP_LENGTH setget , get_snap_vector

var actualState
var priorState

func _physics_process(_delta):
	return

func set_state(new_state, old_state):
	if new_state != old_state: priorState = old_state
	actualState = new_state

func get_snap_vector():
	return snap_vector
