extends State

func enter(actor,_delta = 0.0):
	actor.set_debug_text("DEAD")
	actor.warningSprite.visible = false
	actor.dangerSprite.visible = false
	actor.enter_dead_state()

