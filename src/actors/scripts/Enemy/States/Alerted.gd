extends State

export var SIGHT_SIZE = Vector2(2.5,2.0)

func enter(actor,_delta = 0.0):
	actor.set_debug_text("ALERTED")
	actor.warningSprite.visible = false
	actor.dangerSprite.visible = true
	actor.set_fov_size(SIGHT_SIZE)

func exit(actor):
	actor.warningSprite.visible = false
	actor.dangerSprite.visible = false
