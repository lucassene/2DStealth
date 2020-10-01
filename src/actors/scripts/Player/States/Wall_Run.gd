extends State

export var SPEED = 1800.0

var player_controller

func enter(actor, delta = 0.0):
	player_controller = actor.get_player_controller()
	actor.set_debug_text("WALL RUN")
	var movement = Vector2(0.0,-1.0)
	actor.set_current_y_speed(SPEED)
	actor.move(delta,movement,Vector2.ZERO)

func handle_input(event):
	if player_controller.check_input_pressed(event,"jump","jump"): return

func update(actor,delta):
	var movement = Vector2.ZERO
	var velocity = actor.move(delta,movement,Vector2.ZERO)
	if velocity.y > 0: state_machine.set_state("Falling")
