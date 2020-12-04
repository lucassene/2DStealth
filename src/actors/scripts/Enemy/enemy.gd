extends Actor
class_name Enemy

onready var player = get_node("/root/Level/Player") setget ,get_player
onready var animationPlayer = $AnimationPlayer
onready var warningSprite = $warningSprite
onready var dangerSprite = $dangerSprite
onready var alertTimer = $alertTimer
onready var castOrigin: Position2D = $castOrigin
onready var castPoint : Position2D = $castOrigin/castPoint
onready var fieldOfView : Area2D = $castOrigin/fieldOfView
onready var leftBorder: RayCast2D = $RayCasts/leftBorder
onready var rightBorder: RayCast2D = $RayCasts/rightBorder
onready var bottomRightRC: RayCast2D = $RayCasts/bottomRightRC
onready var bottomLeftRC: RayCast2D = $RayCasts/bottomLeftRC
onready var topRightRC: RayCast2D = $RayCasts/topRightRC
onready var topLeftRC: RayCast2D = $RayCasts/topLeftRC
onready var waypoints = get_node(waypoints_path) setget ,get_waypoints
onready var tween = $Tween
onready var state_machine = $StateMachine setget ,get_state_machine
onready var enemy_controller = $EnemyController setget ,get_controller

onready var label = $Label

export(Array, String) var idles
export var reaction_time = 450 setget ,get_reaction_time
export var chase_offset = 1000
export var search_offset = 200
export var looking_offset = 100
export var search_speed = 300
export var sight_size = Vector2.ONE
export var fight_sight_size = Vector2(2.5,2.0)
export var waypoints_path = NodePath()

signal on_idle_anim_finished()
signal on_player_detected()
signal on_player_contact()
signal on_player_exited()

var dir = 0
var next_dir = 0 setget ,get_next_dir
var next_dir_time = 0
var current_speed = speed

enum states {
	IDLE, 
	PATROLLING, 
	ALERTED,
	SEARCHING, 
	FIGHTING,
}

var facing = Vector2.LEFT
var on_ledge = false
var playerArea: Area2D
var target_waypoint_position
var last_player_position
var is_player_in_sight = false

func get_player():
	return player

func get_state_machine():
	return state_machine

func get_controller():
	return enemy_controller

func get_waypoints():
	return waypoints

func get_next_dir():
	return next_dir

func get_reaction_time():
	return reaction_time

func set_debug_text(text):
	label.text = text

func _ready():
	set_fov_size(sight_size)
	position = waypoints.get_start_position()
	state_machine.initialize("Patrolling")
	
func _process(_delta):
	if state_machine.get_current_state() == "Alerted": rotate_sight()
	
func _on_fieldOfView_body_entered(body):
	if body.is_in_group("Player"):
		if !player: 
			player.connect("on_hide",self,"on_player_hide")
			player.connect("on_unhide",self,"on_player_unhide")
		if !player.is_hidden():
			is_player_in_sight = true
			emit_signal("on_player_detected")

func _on_fieldOfView_body_exited(body):
	if body.is_in_group("Player"):
		is_player_in_sight = false
		emit_signal("on_player_exited")
		if actualState == states.FIGHTING:
			alertTimer.start()

func on_player_hide():
	if !is_player_in_sight and actualState == states.FIGHTING: 
		enter_searching_state()

func on_player_unhide():
	if fieldOfView.overlaps_body(player):
		enter_fight_state()

func _on_PlayerDetector_body_entered(body):
	if body.is_in_group("Player"):
		if !player.is_hidden(): emit_signal("on_player_contact")

func _on_Timer_timeout():
	match(actualState):
		states.ALERTED:
			enter_patrol_state()
		states.FIGHTING:
			if not is_player_in_sight:
				enter_alerted_state()
				alertTimer.start()

func _on_AnimationPlayer_animation_finished(anim_name):
	match(anim_name):
		"turn_W", "turn_E":
			emit_signal("on_idle_anim_finished")
		"smoking_W":
			print("smoking_W")
			if facing == Vector2.RIGHT:
				play_animation("turn")
			else:
				emit_signal("on_idle_anim_finished")
		"smoking_E":
			print("smoking_E")
			if facing == Vector2.LEFT:
				play_animation("turn")
			else:
				emit_signal("on_idle_anim_finished")

func _physics_process(delta):
	state_machine.update(delta)

func move(delta, direction, speed, vector = snap_vector):
	velocity.x = direction * speed
	velocity.y += clamp(gravity * delta,-1.0,max_gspeed)
	velocity = move_and_slide_with_snap(velocity, vector, FLOOR_NORMAL, true, 4, SLOPE_THRESHOLD)

func rotate_sight():
	castOrigin.rotation_degrees = (get_angle_to(player.get_global_transform().origin)/3.14)*180

func can_jump():
	match(facing):
		Vector2.LEFT:
			if bottomLeftRC.is_colliding() and !topLeftRC.is_colliding():
				if bottomLeftRC.get_collider().is_in_group("World"): return true
			return false
		Vector2.RIGHT:
			if bottomRightRC.is_colliding() and !topRightRC.is_colliding():
				if bottomRightRC.get_collider().is_in_group("World"): return true
			return false
	return false

func has_wall():
	match(facing):
		Vector2.LEFT:
			if bottomLeftRC.is_colliding() and topLeftRC.is_colliding():
				return true
			return false
		Vector2.RIGHT:
			if bottomRightRC.is_colliding() and topRightRC.is_colliding():
				return true
			return false
	return false

func jump():
	dir = facing.x
	velocity.y = - 1.0 * jump_speed
	velocity = move_and_slide_with_snap(velocity, Vector2.ZERO, FLOOR_NORMAL, true, 4, SLOPE_THRESHOLD)

func play_animation(anim):
	if enemy_controller.get_facing() == Vector2.RIGHT:
		animationPlayer.play(anim + "_E")
	else: animationPlayer.play(anim + "_W")

func stop_animation():
	animationPlayer.stop()

func set_anim_speed(speed):
	animationPlayer.playback_speed = speed

func is_on_ledge():
	if !leftBorder.is_colliding() or !rightBorder.is_colliding():
		return true
	else: return false

func set_fov_size(size):
	if size == Vector2.ONE:
		tween.interpolate_property(fieldOfView,"scale",fieldOfView.get_scale(),size,0.5,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
		tween.start()
	else:
		fieldOfView.set_scale(size)

func turn():
	velocity.x *= -1.0
	if velocity.x > 0:
		facing = Vector2.RIGHT
		animationPlayer.play("turn_WtoE")
	elif velocity.x <0:
		facing = Vector2.LEFT
		animationPlayer.play("turn_EtoW")
	yield(get_tree().create_timer(1.0),"timeout")

func enter_patrol_state():
	set_fov_size(sight_size)
	dangerSprite.visible = false
	warningSprite.visible = false
	animationPlayer.playback_speed = 1
	current_speed = speed
	actualState = states.PATROLLING
	set_physics_process(true)

func enter_alerted_state():
	dangerSprite.visible = false
	warningSprite.visible = true
	var player_x = player.position.x + (search_offset * facing.x)
	last_player_position = Vector2(player_x,position.y)
	current_speed = search_speed
	actualState = states.ALERTED

func enter_searching_state():
	warningSprite.visible = false
	dangerSprite.visible = true
	current_speed = run_speed
	var player_x = player.position.x + (search_offset * facing.x)
	last_player_position = Vector2(player_x,position.y)
	current_speed = run_speed
	actualState = states.SEARCHING

func enter_fight_state():
	set_fov_size(fight_sight_size)
	warningSprite.visible = false
	dangerSprite.visible = true
	animationPlayer.stop()
	animationPlayer.playback_speed = 2
	current_speed = run_speed
	actualState = states.FIGHTING

func on_hit():
	get_node("CollisionShape2D").set_deferred("disabled",true)
	queue_free()




