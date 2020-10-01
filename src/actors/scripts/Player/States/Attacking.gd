extends State

export var ATTACK_SPEED = 0.3
export var ATTACK_COOLDOWN = 0.5 setget ,get_attack_cooldown

var can_attack = true setget set_can_attack,get_can_attack
var cooldown_timer = 0.0

func get_attack_cooldown():
	return ATTACK_COOLDOWN

func set_can_attack(new_value):
	can_attack = new_value

func get_can_attack():
	return can_attack

func enter(actor,_delta = 0.0):
	actor.set_debug_text("ATTACKING")
	actor.make_melee_attack()
	can_attack = false

