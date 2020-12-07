extends State

var projectile = preload("res://src/actors/scenes/bullet.tscn")

func _on_shoot_anim_finished():
	state_machine.set_state("Alerted")

func enter(actor, _delta = 0.0):
	actor.set_debug_text("SHOOTING")
	actor.warningSprite.visible = false
	actor.dangerSprite.visible = true
	actor.rotate_sight()
	shoot(actor)

func update(actor,_delta):
	actor.rotate_sight()

func shoot(actor):
	var projectile_instance = projectile.instance()
	projectile_instance.position = actor.castPoint.get_global_transform().get_origin()
	projectile_instance.origin = "Enemy"
	actor.play_animation("shoot")
	projectile_instance.shoot(actor.castOrigin.rotation_degrees)
	actor.get_parent().add_child(projectile_instance)
