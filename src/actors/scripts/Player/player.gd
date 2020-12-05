extends Actor

var projectile = preload("res://src/actors/scenes/bullet.tscn")
onready var playerArea: Area2D = $Areas/playerArea
onready var castPoint = $castOrigin/castPoint
onready var castOrigin = $castOrigin
onready var meleeSprite = $Areas/meleeArea/meleeSlash
onready var meleeArea = $Areas/meleeArea
onready var noiseArea = $Areas/noiseArea
onready var animation_player = $AnimationPlayer
onready var noiseStepTimer: Timer = $Timers/noiseStepTimer
onready var positionTween = $Tweens/PositionTween
onready var fadeTween = $Tweens/FadeTween
onready var cameraTween = $Tweens/CameraTween
onready var noiseTween: Tween = $Tweens/NoiseTween
onready var bottomRightRC: RayCast2D = $RayCasts/bottomRightRC
onready var bottomLeftRC: RayCast2D = $RayCasts/bottomLeftRC2
onready var topRightRC: RayCast2D = $RayCasts/topRightRC
onready var topLeftRC: RayCast2D = $RayCasts/topLeftRC
onready var sprite = $sprite
onready var camera = $Camera2D
onready var state_machine = $StateMachine setget ,get_state_machine
onready var action_state_machine = $ActionStateMachine setget ,get_action_state_machine
onready var player_controller = $PlayerController setget ,get_player_controller

onready var label = $Label
onready var actionLabel = $ActionLabel
onready var current_speed setget set_current_speed, get_current_speed
onready var previous_speed setget set_previous_speed, get_previous_speed
onready var current_y_speed setget set_current_y_speed, get_current_y_speed

export var walk_noise = Vector2(0.5,0.5)
export var walk_step = 0.5
export var run_noise = Vector2(1.25,1.25)
export var run_step = 0.25
export var crouch_noise = Vector2(0.15,0.15)
export var crouch_Step = 0.75
export var jump_noise = Vector2(0.75,0.75)

signal on_ladder_entered(area)
signal on_ladder_exited()
signal on_wall_entered(area)
signal on_wall_exited()
signal on_ledge_entered(area)
signal on_ledge_exited()
signal on_hideout_entered(area)
signal on_hideout_exited()
signal on_hide()
signal on_unhide()
signal on_attack_ended()
signal on_wall_jump_ready()
#signal on_shooting_ended()

enum transition {
	IN,
	OUT
}

var can_change_layer = false
var change_layer_pressed = false
var can_shoot = true
var can_attack = true

var mov_noise

var is_going_to_hide = false
var is_going_to_unhide = false
var climbing_ledge = false
var is_camera_focusing = false

var actual_layer = 0
var last_layer: Area2D

var facing = Vector2.RIGHT
var sprite_size

var is_enemy_alerted = false
var in_enemy_sight = false

func get_state_machine():
	return state_machine

func get_action_state_machine():
	return action_state_machine

func get_player_controller():
	return player_controller

func set_current_speed(new_value):
	set_previous_speed(current_speed)
	current_speed = new_value

func get_current_speed():
	return current_speed

func set_previous_speed(new_value):
	previous_speed = new_value

func get_previous_speed():
	return previous_speed

func set_current_y_speed(new_value):
	current_y_speed = new_value

func get_current_y_speed():
	return current_y_speed

func set_debug_text(text):
	label.text = String(facing.x) + " | " + text

func set_action_text(text):
	actionLabel.text = text

func _ready():
	Global.player = self
	sprite_size = sprite.get_texture().get_size().x
	state_machine.initialize("Idle")
	action_state_machine.initialize(null)

func _process(_delta):
	# DEV ONLY
	set_time_scale()

func set_time_scale():
	if Input.is_action_just_pressed("time_stop"):
		Engine.time_scale = 0.0
	if Input.is_action_just_pressed("slow-motion"):
		Engine.time_scale = 0.15
	if Input.is_action_just_pressed("normal_time"):
		Engine.time_scale = 1.0

func _on_ladder_area_entered(area):
	emit_signal("on_ladder_entered",area)

func _on_ladder_area_exited():
	emit_signal("on_ladder_exited")

func _on_trigger_area_entered(area):
	if area.is_in_group("TriggerArea"):
		match area.get_area_type():
			area.type.PARKOUR_WALL:
				if can_wallrun_check(area): 
					emit_signal("on_wall_entered",area)
					return
			area.type.HIDEOUT:
				emit_signal("on_hideout_entered",area)
				return
			area.type.LAYER_CHANGE:
				can_change_layer = true
				last_layer = area
				exit_layer(last_layer.get_layer_bit())
				return

func _on_trigger_area_exited(area):
	if area.is_in_group("TriggerArea"):
		match area.get_area_type():
			area.type.PARKOUR_WALL:
				emit_signal("on_wall_exited")
				return
			area.type.HIDEOUT:
				emit_signal("on_hideout_exited")
				return
			area.type.LAYER_CHANGE:
				can_change_layer = false
				if !change_layer_pressed: exit_layer(last_layer.get_layer_bit())
				change_layer_pressed = false
				return

func _on_ledge_area_entered(area):
	emit_signal("on_ledge_entered",area)

func _on_ledge_area_exited():
	emit_signal("on_ledge_exited")

func _on_in_enemy_sight():
	in_enemy_sight = true

func _on_out_of_enemy_sight():
	in_enemy_sight = false

func _on_enemy_contact():
	print("you're dead!")

func _on_meleeArea_body_entered(body):
	if body.is_in_group("Enemy"):
		body.on_hit()

func _on_AnimationPlayer_animation_finished(anim_name):
	match anim_name:
		"meleeSlash":
			emit_signal("on_attack_ended")
		"jump_to_hide":
			is_going_to_hide = false
			if state_machine.get_current_state() == "Hiding" and is_going_to_unhide:
				is_going_to_unhide = false
				state_machine.set_state("Idle")

func _on_AnimationPlayer_animation_started(anim_name):
	match anim_name:
		"jump_to_hide":
			if state_machine.get_current_state() != "Hiding":
				state_machine.set_state("Hiding")
			elif animation_player.get_playing_speed() < 0:
				is_going_to_unhide = true

func _on_NoiseTween_tween_completed(_object, _key):
	pass # Replace with function body.

func _on_noiseStepTimer_timeout():
	pass # Replace with function body.

func _on_PositionTween_completed(_object, _key):
	if state_machine.get_current_state() == "On_Ledge" and climbing_ledge:
		tween_position(Vector2(position.x + sprite_size * 1.25 * facing.x,position.y),0.25)
		climbing_ledge = false
		return
	if state_machine.get_current_state() == "Jumping":
		emit_signal("on_wall_jump_ready")
		return

func _on_enemy_alerted():
	is_enemy_alerted = true

func _on_enemy_not_alerted():
	is_enemy_alerted = false

func _physics_process(delta):
	state_machine.update(delta)
	action_state_machine.update(delta)

func _unhandled_input(event):
	state_machine.handle_input(event)
	action_state_machine.handle_input(event)

func move(delta, dir, vector = snap_vector):
	velocity = calculate_move_velocity(velocity, dir, current_y_speed, delta)
	set_facing()
	velocity = move_and_slide_with_snap(velocity, vector, FLOOR_NORMAL, true, 4, SLOPE_THRESHOLD)
	return velocity

func calculate_move_velocity(linear_velocity, direction, up_speed, delta):
	var out = linear_velocity
	out.x = current_speed * direction.x
	out.y += gravity * delta
	if direction.y != 0: 
		out.y = up_speed * direction.y
	elif state_machine.get_current_state() == "Climbing":
		out.y = 0
	return out

func enter_hiding_state():
	move_to_hide(state_machine.hideout)

func exit_hiding_state():
	tween_fade(transition.IN)
	emit_signal("on_unhide")
	z_index = 1

func can_hide():
	if in_enemy_sight:
		return !is_enemy_alerted
	else:
		return true

func is_on_ledge():
	if bottomLeftRC.is_colliding() and !topLeftRC.is_colliding():
		return true
	if bottomRightRC.is_colliding() and !topRightRC.is_colliding():
		return true
	return false

func move_to_ledge(area):
	if is_on_ledge():
		tween_position(Vector2(get_area_offset_position(area,sprite_size/2),position.y),0.1)

func get_area_offset_position(area, offset = 0):
	return area.get_global_position().x + (offset * facing.x * -1)

func move_to_wall(area):
	tween_position(Vector2(get_area_offset_position(area),position.y),0.1)

func move_to_ladder(area):
	if position.x != area.position.x:
		tween_position(Vector2(area.position.x,position.y),0.2)

func move_over_ledge(area):
	climbing_ledge = true
	tween_position(Vector2(position.x,area.get_global_position().y),0.3)

func move_to_hide(area):
	z_index = area.get_area_z_index()
	is_going_to_hide = true
	emit_signal("on_hide")
	if !area.can_move:
		tween_position(Vector2(area.position.x,position.y),0.2)
		tween_fade(transition.OUT)
	elif position.x < area.get_left_point():
		tween_position(Vector2(area.get_left_point() + sprite_size/1.5,position.y),0.2)
		tween_fade(transition.OUT)
	elif position.x > area.get_right_point():
		tween_position(Vector2(area.get_right_point() - sprite_size/1.5,position.y),0.2)
		tween_fade(transition.OUT)
	else:
		tween_fade(transition.OUT)
		animation_player.play("jump_to_hide")

#func _input(event):
#	state_machine.handle_input(event)
#	action_state_machine.handle_input(event)

func can_player_hide():
	return true if !in_enemy_sight else false

func make_melee_attack():
	animation_player.play("meleeSlash")

func make_ranged_attack():
	var projectile_instance = projectile.instance()
	projectile_instance.position = castPoint.get_global_transform().get_origin()
	projectile_instance.shoot(castOrigin.rotation_degrees)
	projectile_instance.origin = "Player"
	get_parent().add_child(projectile_instance)

func change_layer():
	change_layer_pressed = true
	enter_layer(last_layer.get_layer_bit())

func can_wallrun_check(area):
	var can_wallrun = false
	if area:
		if facing == Vector2.LEFT and area.get_enter_vector() == Vector2.LEFT and position.x >= get_area_offset_position(area):
				can_wallrun = true
		if facing == Vector2.RIGHT and area.get_enter_vector() == Vector2.RIGHT and position.x <= get_area_offset_position(area):
				can_wallrun = true
	return can_wallrun

func can_grab_check(area):
	if facing == Vector2.LEFT and area.get_enter_vector() == Vector2.LEFT and position.x >= get_area_offset_position(area,sprite_size/2):
			return true
	if facing == Vector2.RIGHT and area.get_enter_vector() == Vector2.RIGHT and position.x <= get_area_offset_position(area,sprite_size/2):
			return true
	return false

func set_cast_point_side():
	if facing == Vector2.RIGHT:
		castOrigin.rotation_degrees = 0
		meleeArea.transform.origin.x = 96
		meleeSprite.flip_h = false
		meleeSprite.flip_v = false
	else: 
		castOrigin.rotation_degrees = 180
		meleeArea.transform.origin.x = -96
		meleeSprite.flip_h = true
		meleeSprite.flip_v = true

func tween_position(new_position,time):
	positionTween.interpolate_property(self,"position",Vector2(position.x,position.y),new_position,time,positionTween.TRANS_LINEAR,positionTween.EASE_IN_OUT)
	positionTween.start()

func tween_fade(fade):
	var fade_in = Color(1.0,1.0,1.0,1.0)
	var fade_out = Color(0.33,0.33,0.33,1.0)
	if fade == transition.IN:
		fadeTween.interpolate_property(self,"modulate",fade_out,fade_in,0.3,positionTween.TRANS_LINEAR,positionTween.EASE_IN_OUT)
	else:
		fadeTween.interpolate_property(self,"modulate",fade_in,fade_out,0.3,positionTween.TRANS_LINEAR,positionTween.EASE_IN_OUT)
	fadeTween.start()

func tween_camera(trans, dir = Vector2.ZERO):
	var cam_offset = Vector2.ZERO
	if dir == Vector2.ZERO: dir = facing
	if trans == transition.OUT:
		if dir == Vector2.LEFT:
			cam_offset = Vector2(-400,0)
		else: 
			cam_offset = Vector2(400,0)
		is_camera_focusing = true
	else:
		is_camera_focusing = false
	cameraTween.interpolate_property(camera,"offset",camera.offset,cam_offset,0.4,cameraTween.TRANS_LINEAR,cameraTween.EASE_OUT_IN)
	cameraTween.start()

func on_hit():
	print("Hit!")

func is_hidden():
	return true if state_machine.get_current_state() == "Hiding" else false

func set_facing():
	if velocity.x < 0:
		facing = Vector2.LEFT
	elif velocity.x > 0: 
		facing = Vector2.RIGHT
	set_cast_point_side()

func enter_layer(layer_bit):
	if last_layer.can_enter_layer():
		actual_layer = layer_bit
		set_collision_mask_bit(layer_bit,true)

func exit_layer(layer_bit):
	var can_exit = false
	if last_layer.can_exit_layer():
		can_exit = true
	elif last_layer.can_enter_layer():
		can_exit = true
	if can_exit:
		actual_layer = 0
		set_collision_mask_bit(layer_bit,false)

func enable_ray_casts(dir, value):
	if value:
		if dir.x < 0:
			bottomLeftRC.enabled = value
			topLeftRC.enabled = value
		elif dir.x > 0:
			bottomRightRC.enabled = value
			topRightRC.enabled = value
	else:
		bottomLeftRC.enabled = value
		topLeftRC.enabled = value
		bottomRightRC.enabled = value
		topRightRC.enabled = value
