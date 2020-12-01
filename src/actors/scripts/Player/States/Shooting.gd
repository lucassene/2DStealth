extends State

export var RATE_OF_FIRE = 0.5 setget ,get_rate_of_fire

var can_shoot = true setget set_can_shoot,get_can_shoot
var cooldown_timer = 0.0

func get_rate_of_fire():
	return RATE_OF_FIRE

func set_can_shoot(new_value):
	can_shoot = new_value

func get_can_shoot():
	return can_shoot

func enter(actor,_delta = 0.0):
	actor.set_action_text("SHOOTING")
	actor.make_ranged_attack()
	can_shoot = false

func exit(actor):
	actor.set_action_text("")


