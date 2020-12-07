extends Enemy

export var RATE_OF_FIRE = 2.0
var timer = 0
var can_shoot = true

signal shoot_anim_finished()

func _on_AnimationPlayer_animation_finished(anim_name):
	._on_AnimationPlayer_animation_finished(anim_name)
	if anim_name == "shoot":
		emit_signal("shoot_anim_finished")
		timer = 0

func _physics_process(delta):
	if !can_shoot: timer += delta
	if timer > RATE_OF_FIRE: 
		timer = 0
		can_shoot = true
	elif state_machine.get_current_state() == "Alerted" and can_shoot:
			if state_machine.is_player_in_sight and !state_machine.is_player_hidden:
				state_machine.set_state("Shooting")
				can_shoot = false
