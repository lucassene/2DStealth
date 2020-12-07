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

export var reaction_time = 450 setget ,get_reaction_time
export var waypoints_path = NodePath()

signal on_idle_anim_finished()
signal on_player_detected()
signal on_player_contact()
signal on_player_exited()
signal on_alerted_state()
signal on_not_alerted_state()

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

func _on_PlayerDetector_body_entered(body):
	if body.is_in_group("Player"):
		if !Global.player.is_hidden(): emit_signal("on_player_contact")

func _on_AnimationPlayer_animation_finished(anim_name):
	match(anim_name):
		"turn","smoking":
			emit_signal("on_idle_anim_finished")
			return

func _physics_process(delta):
	state_machine.update(delta)

func move(delta, direction, speed, vector = snap_vector):
	velocity.x = direction * speed
	velocity.y += clamp(gravity * delta,-1.0,max_gspeed)
	velocity = move_and_slide_with_snap(velocity, vector, FLOOR_NORMAL, true, 4, SLOPE_THRESHOLD)
	return velocity

func rotate_sight():
	castOrigin.rotation_degrees = (get_angle_to(Global.player.get_global_transform().origin)/3.14)*180
	world_detector.scale.x = enemy_controller.get_facing().x

func turn(direction):
	if sprite.scale.x != direction.x and direction != Vector2.ZERO: 
		sprite.scale.x = direction.x

func enter_alerted_state():
	sprite.scale.x = 1.0
	sprite.flip_h = true

func can_jump():
	if world_detector.can_jump() and is_on_floor():
		return true
	else: return false

func jump(speed):
	velocity.y = - 1.0 * speed
	velocity = move_and_slide_with_snap(velocity, Vector2.ZERO, FLOOR_NORMAL, true, 4, SLOPE_THRESHOLD)

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

func on_alerted():
	emit_signal("on_alerted_state")

func on_not_alerted():
	emit_signal("on_not_alerted_state")

func on_hit():
	state_machine.set_state("Dead")

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
