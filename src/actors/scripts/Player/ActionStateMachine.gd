extends StateMachine

var player_controller
var state_machine

var melee_cooldown = 0.0
var ranged_cooldown = 0.0

func _on_Player_on_attack_ended():
	exit_state("Attacking")

func initialize(_first_state):
	for child in get_children():
		states[child.get_name()] = child
	player_controller = actor.get_player_controller()
	player_controller.set_action_state_machine(self)
	state_machine = actor.get_state_machine()

func set_state(new_state):
	.set_state(new_state)
	
func enter_state(state):
	.enter_state(state)

func exit_state(state):
	.exit_state(state)

func handle_input(_event):
	return
	
func update(delta):
	if !states.Attacking.get_can_attack():
		melee_cooldown += delta
		if melee_cooldown >= states.Attacking.get_attack_cooldown():
			melee_cooldown = 0.0
			states.Attacking.set_can_attack(true)
	if !states.Shooting.get_can_shoot():
		ranged_cooldown += delta
		if ranged_cooldown >= states.Shooting.get_rate_of_fire():
			ranged_cooldown = 0.0
			states.Shooting.set_can_shoot(true)
			if current_state == "Shooting": exit_state("Shooting")
	.update(delta)

func set_melee_attack_state():
	if states.Attacking.get_can_attack():
		set_state("Attacking")

func set_ranged_attack_state():
	if states.Shooting.get_can_shoot():
		set_state("Shooting")


