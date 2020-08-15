extends Actor
class_name Enemy

onready var animationPlayer = $AnimationPlayer
onready var warningSprite = $warningSprite
onready var dangerSprite = $dangerSprite
onready var alertTimer = $alertTimer
onready var castOrigin: Position2D = $castOrigin
onready var castPoint : Position2D = $castOrigin/castPoint
onready var leftBorder: RayCast2D = $leftBorder
onready var rightBorder: RayCast2D = $rightBorder
onready var bottomRightRC: RayCast2D = $bottomRightRC
onready var bottomLeftRC: RayCast2D = $bottomLeftRC
onready var topRightRC: RayCast2D = $topRightRC
onready var topLeftRC: RayCast2D = $topLeftRC
onready var waypoints = get_node(waypoints_path)

onready var label = $Label

export(Array, String) var idles
export var reaction_time = 450
export var chase_offset = 1000
export var search_offset = 200
export var search_speed = 300
export var waypoints_path = NodePath()

var dir = 0
var next_dir = 0
var next_dir_time = 0
var current_speed = speed

enum states {
	IDLE, 
	PATROLLING, 
	SEARCHING,
	RETURNING, 
	FIGHTING,
}

var facing = Vector2.LEFT
var on_ledge = false
var player
var waypoint_position
var last_player_position
var is_player_in_sight = false

func _ready():
	if !waypoints: return
	position = waypoints.get_start_position()
	waypoint_position = waypoints.get_next_point_position()
	enter_patrol_state()
	
func _process(_delta):
	match(actualState):
		states.IDLE:
			label.text = "IDLE"
			return
		states.PATROLLING:
			label.text = "PATROLLING"
			play_animation("patrol")
		states.SEARCHING:
			label.text = "SEARCHING"
			animationPlayer.playback_speed = 2
			play_animation("patrol")
		states.FIGHTING:
			label.text = "FIGHTING"
			castOrigin.rotation_degrees = (get_angle_to(player.get_global_transform().origin)/3.14)*180
		states.RETURNING:
			label.text = "RETURNING"
	
func _on_fieldOfView_body_entered(body):
	if body.is_in_group("Player"):
		if !player: player = body
		match actualState:
			states.PATROLLING, states.IDLE, states.SEARCHING:
				enter_fight_state()

func _on_fieldOfView_body_exited(body):
	if body.is_in_group("Player"):
		pass

func _on_Timer_timeout():
	match(actualState):
		states.SEARCHING:
			enter_patrol_state()
		states.FIGHTING:
			if not is_player_in_sight:
				enter_search_state()
				alertTimer.start()

func _on_AnimationPlayer_animation_finished(anim_name):
	match(anim_name):
		"turn_W", "turn_E":
			play_animation("patrol")
			enter_patrol_state()
		"smoking_W":
			if facing == Vector2.RIGHT:
				play_animation("turn")
			else:
				enter_patrol_state()
		"smoking_E":
			if facing == Vector2.LEFT:
				play_animation("turn")
			else:
				enter_patrol_state()

func _on_sight_body_entered(body):
	if body.is_in_group("Player"):
		is_player_in_sight = true
		match(actualState):
			states.SEARCHING:
				enter_fight_state()
	
func _on_sight_body_exited(body):
	if body.is_in_group("Player"):
		is_player_in_sight = false
		if actualState == states.FIGHTING:
			alertTimer.start()
	
func _physics_process(delta):
	if is_on_floor() and can_jump(): jump()
	match(actualState):
		states.IDLE, states.PATROLLING:
			go_to_position(waypoint_position, delta)
		states.SEARCHING:
			go_to_position(last_player_position, delta)
		states.FIGHTING:
			go_to_position(player.position, delta)

func go_to_position(target_position, delta):
	match(actualState):
		states.FIGHTING:
			set_facing(target_position,chase_offset)
			if OS.get_ticks_msec() > next_dir_time:
				dir = next_dir
		states.PATROLLING:
			set_facing(target_position,0)
			if check_movement(target_position,delta):
				position = target_position
				waypoint_position = waypoints.get_next_point_position()
				set_facing(waypoint_position,0)
				set_physics_process(false)
				actualState = states.IDLE
				play_animation(idles[waypoints.get_current_index()])
			else: dir = next_dir
		states.SEARCHING:
			set_facing(target_position,search_offset)
			if check_movement(target_position,delta):
				position = target_position
				set_physics_process(false)
			else: dir = next_dir

	velocity.x = dir * current_speed
	velocity.y += clamp(gravity * delta,0.0,max_gspeed)
	velocity = move_and_slide(velocity,FLOOR_NORMAL)

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
	velocity.x = facing.x * current_speed
	velocity.y = - 1.0 * jump_speed
	velocity = move_and_slide(velocity,FLOOR_NORMAL)

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
	
	velocity.x = dir * current_speed
	
	velocity.y += clamp(gravity * delta,0.0,max_gspeed)
	velocity = move_and_slide(velocity,FLOOR_NORMAL)

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
	dangerSprite.visible = false
	warningSprite.visible = false
	animationPlayer.playback_speed = 1
	current_speed = speed
	actualState = states.PATROLLING
	set_physics_process(true)

func enter_search_state():
	dangerSprite.visible = false
	warningSprite.visible = true
	var player_x = player.position.x + (search_offset * facing.x)
	last_player_position = Vector2(player_x,position.y)
	current_speed = search_speed
	actualState = states.SEARCHING

func enter_fight_state():
	warningSprite.visible = false
	dangerSprite.visible = true
	animationPlayer.stop()
	animationPlayer.playback_speed = 2
	current_speed = run_speed
	actualState = states.FIGHTING

func on_hit():
	get_node("CollisionShape2D").set_deferred("disabled",true)
	queue_free()
