extends Enemy

export var rate_of_fire = 2.0
var can_shoot = true

func _process(_delta):
	match(actualState):
		states.FIGHTING:
			if can_shoot: shoot_at_player()

func shoot_at_player():
	can_shoot = false
	var projectile = load("res://src/actors/scenes/bullet.tscn")
	var projectile_instance = projectile.instance()
	projectile_instance.position = castPoint.get_global_transform().get_origin()
	projectile_instance.origin = "Enemy"
	projectile_instance.shoot(castOrigin.rotation_degrees)
	get_parent().add_child(projectile_instance)
	yield(get_tree().create_timer(rate_of_fire),"timeout")
	can_shoot = true

