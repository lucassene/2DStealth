extends RigidBody2D

export var SPEED = 2000.0
export var SPAWN_TIME = 3.0

var origin

func _ready():
	match(origin):
		"Player":
			set_collision_mask_bit(0,false)
			set_collision_mask_bit(1,true)
		"Enemy":
			set_collision_mask_bit(0,true)
			set_collision_mask_bit(1,false)
	self_destruct()

func shoot(rotation_deg: float):
	rotation_degrees = rotation_deg
	apply_impulse(Vector2(),Vector2(SPEED,0).rotated(rotation))

func self_destruct():
	yield(get_tree().create_timer(SPAWN_TIME),"timeout")
	queue_free()

func _on_Bullet_body_entered(body):
	get_node("CollisionShape2D").set_deferred("disabled",true)
	if body.is_in_group("Enemy") and origin == "Player":
		body.on_hit()
	elif body.is_in_group("Player") and origin == "Enemy":
		body.on_hit()
	self.hide()
