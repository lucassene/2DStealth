extends State

func _on_melee_anim_finished():
	state_machine.set_state("Alerted")

func enter(actor, _delta = 0.0):
	actor.set_debug_text("ATTACKING")
	actor.warningSprite.visible = false
	actor.dangerSprite.visible = true
	actor.rotate_sight()
	actor.update_melee_area_side()
	actor.attack()

func update(actor,_delta):
	actor.rotate_sight()
	actor.update_melee_area_side()
