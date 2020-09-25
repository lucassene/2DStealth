extends Node
class_name StateMachine

onready var actor = owner

var current_state setget ,get_current_state
var previous_state setget ,get_previous_state

func get_current_state():
	return current_state

func get_previous_state():
	return previous_state

func initialize(first_state):
	#actor = owner
	current_state = first_state
	actor.states[current_state].enter(actor)

func set_state(new_state):
	previous_state = current_state
	exit_state(current_state)
	current_state = new_state
	enter_state(current_state)
	
func enter_state(state):
	actor.states[state].enter(actor)
	
func exit_state(state):
	actor.states[state].exit(actor)

func handle_input(event):
	actor.states[current_state].handle_input(event)

func update(delta):
	actor.states[current_state].update(actor,delta)

