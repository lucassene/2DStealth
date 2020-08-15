extends Enemy

onready var meleeArea = $meleeArea
onready var meleeSprite = $meleeArea/meleeSlash

export var attack_speed = 2.0

var can_attack = true

func _process(_delta):
	match(actualState):
		states.FIGHTING:
			if can_attack: melee_attack()
	if castOrigin.rotation_degrees >= 90 and castOrigin.rotation_degrees <= 270 or castOrigin.rotation_degrees <= -90 and castOrigin.rotation_degrees >= -270:
		meleeArea.transform.origin.x = -96
		meleeSprite.flip_h = true
	else:
		meleeArea.transform.origin.x = 96
		meleeSprite.flip_h = false

func _on_meleeArea_body_entered(body):
	if body.is_in_group("Player"):
		body.on_hit()

func melee_attack():
	can_attack = false
	animationPlayer.play("enemy_meleeSlash")
	yield(get_tree().create_timer(attack_speed),"timeout")
	can_attack = true


