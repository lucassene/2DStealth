extends Actor
class_name Enemy

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
onready var waypoints = $Waypoints setget ,get_waypoints
onready var tween = $Tween
onready var state_machine = $StateMachine setget ,get_state_machine

onready var label = $Label

export(Array, String) var idles
export var reaction_time = 450
export var chase_offset = 1000
export var search_offset = 200
export var looking_offset = 100
export var search_speed = 300
export var sight_size = Vector2.ONE
export var fight_sight_size = Vector2(2.5,2.0)
export var waypoints_path = NodePath()

signal on_idle_anim_finished()

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

var player

var facing = Vector2.LEFT
var on_ledge = false
var playerArea: Area2D
var target_waypoint_position
var last_player_position
var is_player_in_sight = false

func get_state_machine():
	return state_machine

func get_waypoints():
	return waypoints

func get_next_dir():
	return next_dir

func set_debug_text(text):
	label.text = text

func _ready():
	set_fov_size(sight_size)
	#position = waypoints.get_start_position()
	state_machine.initialize("Patrolling")
	
func _process(_delta):
	pass
#	match(actualState):
#		states.IDLE:
#			label.text = "IDLE"
#			return
#		states.PATROLLING:
#			label.text = "PATROLLING"
#			play_animation("patrol")
#		states.ALERTED:
#			label.text = "ALERTED"
#			animationPlayer.playback_speed = 2
#			play_animation("patrol")
#		states.FIGHTING:
#			label.text = "FIGHTING"
#			castOrigin.rotation_degrees = (get_angle_to(player.get_global_transform().origin)/3.14)*180
#		states.SEARCHING:
#			label.text = "SEARCHING"
	
func _on_fieldOfView_body_entered(body):
	if body.is_in_group("Player"):
		print("player in sight")
		if !player: 
			player = body
			player.connect("on_hide",self,"on_player_hide")
			player.connect("on_unhide",self,"on_player_unhide")
		if !player.is_hidden():
			is_player_in_sight = true
			match actualState:
				states.PATROLLING, states.IDLE, states.ALERTED:
					enter_fight_state()

func _on_fieldOfView_body_exited(body):
	if body.is_in_group("Player"):
		is_player_in_sight = false
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
		if !player: player = body
		if !player.is_hidden(): enter_fight_state()

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
			#play_animation("patrol")
			emit_signal("on_idle_anim_finished")
			#enter_patrol_state()
		"smoking_W":
			if facing == Vector2.RIGHT:
				play_animation("turn")
			else:
				emit_signal("on_idle_anim_finished")
		"smoking_E":
			if facing == Vector2.LEFT:
				play_animation("turn")
			else:
				emit_signal("on_idle_anim_finished")

func _physics_process(delta):
	state_machine.update(delta)
#	if is_on_floor() and can_jump(): jump()
#	match(actualState):
#		states.IDLE, states.PATROLLING:
#			get_direction(target_waypoint_position, delta)
#		states.ALERTED, states.SEARCHING:
#			get_direction(last_player_position, delta)
#		states.FIGHTING:
#			get_direction(player.position, delta)

func get_direction(target_position, delta):
#	match(actualState):
#		states.FIGHTING:
#			set_facing(target_position,chase_offset)
#			if OS.get_ticks_msec() > next_dir_time:
#				dir = next_dir
#		states.PATROLLING:
#			set_facing(target_position,0)
#			if check_movement(target_position,delta):
#				position = target_position
#				target_waypoint_position = waypoints.get_next_point_position()
#				set_facing(target_waypoint_position,0)
#				set_physics_process(false)
#				actualState = states.IDLE
#				play_animation(idles[waypoints.get_current_index()])
#			else: dir = next_dir
#		states.ALERTED:
#			set_facing(target_position,search_offset)
#			if check_movement(target_position,delta):
#				position = target_position
#				set_physics_process(false)
#			else: dir = next_dir
#		states.SEARCHING:
#			set_facing(target_position,looking_offset * facing.x)
#			if check_movement(target_position,delta):
#				position = target_position
#				enter_alerted_state()
#				alertTimer.start()
#			else: dir = next_dir
#	move(delta,current_speed)
	pass

func move(delta, direction, speed, vector = snap_vector):
	velocity.x = direction * speed
	velocity.y += clamp(gravity * delta,-1.0,max_gspeed)
	velocity = move_and_slide_with_snap(velocity, vector, FLOOR_NORMAL, true, 4, SLOPE_THRESHOLD)
	
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
	if facing == Vector2.RIGHT:
		animationPlayer.play(anim + "_E")
	else: animationPlayer.play(anim + "_W")
	
func is_on_ledge():
	if !leftBorder.is_colliding() or !rightBorder.is_colliding():
		return true
	else: return false

func set_facing(target_position, offset):
	if target_position.x < position.x - offset:
		set_chase_direction(-1)
		facing = Vector2.LEFT
	elif target_position.x > position.x + offset:
		set_chase_direction(1)
		facing = Vector2.RIGHT
	else:
		set_chase_direction(0)
		facing = Vector2.LEFT

func set_chase_direction(target_dir):
	if next_dir != target_dir:
		next_dir = target_dir
		next_dir_time = OS.get_ticks_msec() + reaction_time

func check_movement(target_position, delta):
	var motion = facing * current_speed * delta
	var distance_to_target = position.distance_to(target_position)
	return true if motion.length() > distance_to_target else false

func start_chase(delta):	
	if player.position.x < position.x - chase_offset:
		set_chase_direction(-1)
	elif player.position.x > position.x + chase_offset:
		set_chase_direction(1)
	else:
		set_chase_direction(0)
	
	if OS.get_ticks_msec() > next_dir_time:
		dir = next_dir
		
	#move(delta,current_speed)

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

