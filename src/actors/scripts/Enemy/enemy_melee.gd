extends Enemy

onready var meleeArea = $meleeArea
onready var meleeSprite = $meleeArea/meleeSlash

export var MELEE_ANIM = "melee_slash"
export var ATTACK_COOLDOWN = 2.0
export var RANGE = 175
var timer = 0
var can_attack = true

signal melee_anim_finished()

func _on_AnimationPlayer_animation_finished(anim_name):
	._on_AnimationPlayer_animation_finished(anim_name)
	if anim_name == MELEE_ANIM:
		emit_signal("melee_anim_finished")
		timer = 0

func _on_meleeArea_body_entered(body):
	if body.is_in_group("Player"):
		body.on_hit()

func _physics_process(delta):
	if !can_attack: timer += delta
	if timer > ATTACK_COOLDOWN: 
		timer = 0
		can_attack = true
	elif state_machine.get_current_state() == "Alerted" and can_attack:
			if state_machine.is_player_in_sight and !state_machine.is_player_hidden  and is_target_in_range():
				state_machine.set_state("Attacking")
				can_attack = false

func is_target_in_range():
	var distance_to_target = position.distance_to(Global.player.position)
	return true if distance_to_target <= RANGE else false

func update_melee_area_side():
	if enemy_controller.get_facing() == Vector2.RIGHT:
		meleeArea.position.x = 96.0
		meleeSprite.scale.x = -1.0
	else:
		meleeArea.position.x = -96.0
		meleeSprite.scale.x = 1.0
		
func attack():
	play_animation(MELEE_ANIM)
