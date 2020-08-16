extends KinematicBody2D
class_name Actor

export var speed = 500.0
export var run_speed = 800.0
export var wall_speed = 1300.0
export var wall_jump_speed = 600
export var max_speed = 800.0
export var crouch_speed = 200
export var climb_speed = 250.0
export var jump_time = 1.0
export var jump_speed = 1000.0
export var gravity = 3200.0
export var max_gspeed = 4000.0

const FLOOR_NORMAL = Vector2.UP

var velocity = Vector2.ZERO

var actualState
var priorState

func _physics_process(_delta):
	return

func set_state(new_state, old_state):
	if new_state != old_state: priorState = old_state
	actualState = new_state

