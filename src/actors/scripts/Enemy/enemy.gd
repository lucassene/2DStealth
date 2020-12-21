extends Actor
class_name Enemy

onready var animationPlayer = $AnimationPlayer
onready var warningSprite = $warningSprite
onready var dangerSprite = $dangerSprite
onready var sprite = $sprite
onready var body_collision = $BodyCollision
onready var castOrigin: Position2D = $sprite/castOrigin
onready var castPoint : Position2D = $sprite/castOrigin/castPoint
onready var fieldOfView : Area2D = $sprite/castOrigin/fieldOfView
onready var sight_collision = $sprite/castOrigin/fieldOfView/SightCollision
onready var world_detector = $sprite/WorldDetector
onready var player_detector = $PlayerDetector
onready var player_detector_collision = $PlayerDetector/PlayerDetectorCollision
onready var waypoints = get_node(waypoints_path) setget ,get_waypoints
onready var tween = $Tween
onready var state_machine = $StateMachine setget ,get_state_machine
onready var enemy_controller = $EnemyController setget ,get_controller

onready var label = $Label

export var SIGHT_SIZE = Vector2(2.15,1.75)
export var reaction_time = 450 setget ,get_reaction_time
export var waypoints_path = NodePath()

signal on_idle_anim_finished()
signal on_player_detected()
signal on_player_contact()
signal on_player_exited()
signal on_alerted_state()
signal on_not_alerted_state()

var is_player_visible = false

func get_state_machine():
	return state_machine

func get_controller():
	return enemy_controller

func get_waypoints():
	return waypoints

func get_reaction_time():
	return reaction_time

func set_debug_text(text):
	label.text = text

func _ready():
	connect_player_signals()
	set_fov_size(Vector2.ONE)
	position = waypoints.get_start_position()
	state_machine.initialize("Patrolling")

func _physics_process(delta):
	state_machine.update(delta)

func move(delta, direction, x_speed, vector = snap_vector):
	velocity = calculate_move_velocity(velocity,direction,x_speed,delta)
	velocity = move_and_slide_with_snap(velocity, vector, FLOOR_NORMAL, true, 4, SLOPE_THRESHOLD)
	return velocity

func calculate_move_velocity(linear_velocity, direction, x_speed, delta):
	var out = linear_velocity
	out.x = x_speed * direction
	out.y += clamp(gravity * delta,-1.0,max_gspeed)
	return out

func jump(dir,x_speed,y_speed):
	velocity.x = x_speed * dir
	velocity.y = -1.0 * y_speed
	velocity = move_and_slide_with_snap(velocity, Vector2.ZERO, FLOOR_NORMAL, true, 4, SLOPE_THRESHOLD)

func rotate_sight():
	castOrigin.rotation_degrees = (get_angle_to(Global.player.get_global_transform().origin)/3.14)*180
	world_detector.scale.x = enemy_controller.get_facing().x

func turn(direction):
	if direction != Vector2.ZERO:
		if direction.x > 1.0:
			sprite.flip_h = true
		else:
			sprite.flip_v = false
		if state_machine.get_current_state() != "Alerted":
			sprite.scale.x = direction.x

func enter_alerted_state():
	sprite.scale.x = 1.0
	world_detector.change_ray_size(true)
	on_alerted()

func exit_alerted_state():
	world_detector.scale.x = 1.0
	sprite.scale.x = enemy_controller.get_facing().x
	world_detector.change_ray_size(false)
	on_not_alerted()

func can_jump():
	if world_detector.can_jump() and is_on_floor():
		return true
	else: return false

func play_animation(anim):
	animationPlayer.play(anim)

func stop_animation():
	animationPlayer.stop()

func set_anim_speed(speed):
	animationPlayer.playback_speed = speed

func set_fov_size(size):
	if size == Vector2.ONE:
		tween.interpolate_property(fieldOfView,"scale",fieldOfView.get_scale(),size,0.5,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
		tween.start()
	else:
		fieldOfView.set_scale(size)

func connect_player_signals():
	connect("on_player_detected",Global.player,"_on_in_enemy_sight")
	connect("on_player_exited",Global.player,"_on_out_of_enemy_sight")
	connect("on_alerted_state",Global.player,"_on_enemy_alerted")
	connect("on_not_alerted_state",Global.player,"_on_enemy_not_alerted")
	connect("on_player_contact",Global.player,"_on_enemy_contact")
	Global.player.connect("on_player_visible",self,"_on_player_visible")
	Global.player.connect("on_player_obscured",self,"_on_player_obscured")

func enter_dead_state():
	disable_collisions()
	play_animation("dying")

func disable_collisions():
	set_physics_process(false)
	castOrigin.visible = false
	body_collision.set_deferred("disabled",true)
	fieldOfView.monitoring = false
	sight_collision.set_deferred("disabled",true)
	player_detector.monitoring = false
	player_detector_collision.set_deferred("disabled",true)

func on_alerted():
	state_machine.set_is_alerted(true)
	emit_signal("on_alerted_state")

func on_not_alerted():
	state_machine.set_is_alerted(false)
	emit_signal("on_not_alerted_state")

func on_hit():
	state_machine.set_state("Dead")

func _on_fieldOfView_body_entered(body):
	if body.is_in_group("Player"):
		emit_signal("on_player_detected")

func _on_fieldOfView_body_exited(body):
	if body.is_in_group("Player"):
		emit_signal("on_player_exited")

func _on_player_hide():
	state_machine.on_player_hide()

func _on_player_unhide():
	if fieldOfView.overlaps_body(Global.player):
		state_machine.on_player_unhide()

func _on_player_visible():
	print("player tá na luz!")
	is_player_visible = true
	if !state_machine.get_is_alerted():
		set_fov_size(SIGHT_SIZE)

func _on_player_obscured():
	print("player saiu da luz!")
	is_player_visible = false
	if !state_machine.get_is_alerted():
		state_machine.set_fov_size()

func _on_PlayerDetector_body_entered(body):
	if body.is_in_group("Player"):
		if !Global.player.is_hidden(): emit_signal("on_player_contact")

func _on_AnimationPlayer_animation_finished(anim_name):
	match(anim_name):
		"turn","smoking":
			emit_signal("on_idle_anim_finished")
			return

