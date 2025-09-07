extends CharacterBody2D
class_name StarTest

enum movement_mode {MOUSE_FOLLOW, ARROW_ROTATE, MOUSE_ANCHOR, MOUSE_MIRROR, AI_MODE}

@export_category("basic variables")
@export var mode : movement_mode
@export var base_speed := 750.
@export var max_speed := 1500.
@export var brake_speed := 200.
@export var mouse_deadzone_radius := 50.
@export var boost_multiplier := 2.5
@export var max_boost_time := 3.
@export var collision_bounce_velocity_fraction := 0.8
@export var collision_slide_boost_time := 1.
@export var collision_applied_impulse := 0.1
@export var ai_follow : StarTest

@export_category("mouse mode variables")
@export var mouse_mode_acc := 2000.
@export var base_turn_rate = 3.
@export var acc_turn_rate = 5.

@export_category("arrow mode variables")
@export var rotation_rate := 3.
@export var rotation_change_rate := 10.
@export var arrow_mode_acc := 1500.
var _rotation_speed := 1.

@export_category("mouse anchor mode variables")
@export var anchor_strength := 3.
@export var anchor_mode_acc := 2000.
@export var anchor_acc_turn_rate := 6.

@export_category("mouse mirror mode variables")
@export var mouse_sensitivity_range := 40.
@export var mouse_mirror_acc := 2000.
@export var mirror_base_turn_rate = 8.
@export var mirror_acc_turn_rate = 12.
@export var mirror_relative_smooth := 12.
@export var mirror_deadzone := 0.5

@export_category("display variables")
@export var trail_segment_length := 10.
@export var max_points := 80
@export var min_width := 0.0
@export var max_width_px := 10.0

@export_category("dependecies")
@export var trail: Line2D
@export var sprite : Sprite2D
@export var movement_particles : GPUParticles2D
@export var collision_particles : GPUParticles2D
@export var held_star_particles : GPUParticles2D
@export var camera : Camera2D

var speeds : Array[float] = []

var _direction := 0.
var _current_speed := 0.
var _boost_time := 0.
var _init_base_speed : float
var _init_max_speed : float
var _init_brake_speed : float
var _held_star : ConnectableStarTest
var _speed_multiplier := 1.0

# Mouse motion accumulation & smoothing (used by MOUSE_MIRROR)
var _mouse_relative := Vector2.ZERO
var _smoothed_relative := Vector2.ZERO

func _ready():
	_init_base_speed = base_speed
	_init_max_speed = max_speed
	_init_brake_speed = brake_speed
	if mode == movement_mode.MOUSE_MIRROR:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _notification(what):
	if what == NOTIFICATION_APPLICATION_FOCUS_IN and mode == movement_mode.MOUSE_MIRROR:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta):
	_render_trail()
	_movement_animation(delta)
	_handle_boost(delta)

	match mode:
		movement_mode.MOUSE_FOLLOW:
			_mouse_mode_process(delta)
		movement_mode.ARROW_ROTATE:
			_arrow_mode_process(delta)
		movement_mode.MOUSE_ANCHOR:
			_mouse_anchor_process(delta)
		movement_mode.MOUSE_MIRROR:
			_mouse_mirror_process(delta)
		movement_mode.AI_MODE:
			_ai_mode_process(delta)

	move_and_slide()
	_handle_collision()
	_handle_held_star()

	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().free()

func _render_trail():
	if trail.get_point_count() > 0:
		if global_position.distance_to(trail.get_point_position(trail.get_point_count() - 1)) < trail_segment_length:
			return

	trail.add_point(global_position)
	speeds.append(velocity.length())

	while speeds.size() > max_points:
		speeds.pop_front()
	while trail.points.size() > max_points:
		trail.remove_point(0)
	
	_update_trail_width_curve()

func _update_trail_width_curve():
	var curve := Curve.new()
	trail.width = max_width_px
	for i in range(speeds.size()):
		var t : float = float(i) / max(1, speeds.size() - 1)
		var norm_speed : float = clamp(speeds[i] / (_init_max_speed), 0.0, 1.0)
		var width : float = lerp(min_width, max_width_px, norm_speed) / max_width_px
		curve.add_point(Vector2(t, width))

	trail.width_curve = curve

func _movement_animation(_delta):
	movement_particles.amount_ratio = velocity.length() / (_init_max_speed * _speed_multiplier)
	#var target_zoom := Vector2.ONE.lerp(max_camera_zoom, velocity.length() / (_init_max_speed * boost_multiplier))
	#target_zoom = target_zoom.limit_length(sqrt(2))
	#camera.zoom = camera.zoom.lerp(target_zoom, delta * 2.)

func _warp_at_pos(pos: Vector2, strength: float):
	var new_warp = preload("res://warp_effect_test.tscn").instantiate()
	add_child(new_warp)
	new_warp.warp_at(pos, strength)
	var tween = get_tree().create_tween()
	tween.tween_interval(0.5)
	tween.tween_callback(func(): new_warp.queue_free())

func _handle_collision():
	if get_slide_collision_count() < 1:
		return

	var collision_data := get_slide_collision(0)
	var normal = collision_data.get_normal()
	var collider = collision_data.get_collider()

	var v_norm = velocity.normalized()
	var dot = v_norm.dot(normal)

	if dot < -0.95:
		velocity = velocity.bounce(normal) * collision_bounce_velocity_fraction
		velocity = velocity.limit_length(_init_max_speed * boost_multiplier)
		
		_warp_at_pos(collision_data.get_position(), velocity.length() / _init_max_speed)
		
		if collider is RigidBody2D:
			collider.apply_impulse(-normal * velocity.length() * collision_applied_impulse, collision_data.get_position() - collider.global_position)
	else:
		var tangent = v_norm.slide(normal)
		velocity = tangent * velocity.length()
		boost(get_process_delta_time() * 1. / collision_slide_boost_time)

	_current_speed = velocity.length() if mode != movement_mode.ARROW_ROTATE else _current_speed
	_direction = velocity.angle() if mode != movement_mode.ARROW_ROTATE else _direction

	_collision_visual_effect(collision_data)

func _collision_visual_effect(collision_data : KinematicCollision2D):
	var new_particles : GPUParticles2D = collision_particles.duplicate()
	collision_data.get_collider().add_child(new_particles)
	new_particles.show()
	new_particles.process_material.direction = Vector3(collision_data.get_normal().x, collision_data.get_normal().y, 0)
	new_particles.emitting = true
	new_particles.global_position = collision_data.get_position()

	await get_tree().create_timer(new_particles.lifetime).timeout
	new_particles.queue_free()

func _mouse_anchor_process(delta):
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)

	var acc_mode := Input.get_axis("right_click", "left_click")

	match acc_mode:
		0.0:
			var target_position = global_position.lerp(get_global_mouse_position(), anchor_strength * delta)
			_current_speed = ((target_position - global_position) / delta).length()
			_current_speed = clamp(_current_speed, 0, _init_max_speed * _speed_multiplier)
			_direction = global_position.angle_to_point(target_position)
			velocity = (target_position - global_position) / delta
		_:
			var target_speed = (_init_max_speed if acc_mode == 1 else _init_brake_speed) * _speed_multiplier
			_current_speed = move_toward(_current_speed, target_speed, anchor_mode_acc * delta)
			var intended_dir = global_position.angle_to_point(get_global_mouse_position())
			_direction = lerp_angle(_direction, intended_dir, anchor_acc_turn_rate * delta)
			velocity = Vector2.from_angle(_direction) * _current_speed

func _mouse_mode_process(delta):
	var acc_mode := Input.get_axis("right_click", "left_click")
	var target_speed = (_init_brake_speed if acc_mode == -1 else _init_max_speed if acc_mode == 1 else _init_base_speed) * _speed_multiplier
	_current_speed = move_toward(_current_speed, target_speed, delta * mouse_mode_acc)

	var intended_dir = global_position.angle_to_point(get_global_mouse_position()) if global_position.distance_to(get_global_mouse_position()) > mouse_deadzone_radius else _direction
	_direction = lerp_angle(_direction, intended_dir, (mirror_base_turn_rate if not acc_mode else mirror_acc_turn_rate) * delta)

	velocity = Vector2.from_angle(_direction) * _current_speed

func _arrow_mode_process(delta):
	var acc_mode := \
	(Input.is_action_pressed("left") and Input.is_action_pressed("right")) or \
	(Input.is_action_pressed("left_click") and Input.is_action_pressed("right_click"))

	var dir = (Input.get_axis("left", "right")) + (Input.get_axis("left_click", "right_click"))
	_rotation_speed = move_toward(_rotation_speed, dir * rotation_rate, rotation_change_rate * delta)

	_direction += _rotation_speed * delta
	sprite.rotation = _direction

	velocity = velocity.move_toward(Vector2.from_angle(_direction) * ((_init_base_speed if not acc_mode else _init_max_speed) * _speed_multiplier), arrow_mode_acc * delta)

	_current_speed = velocity.length()

func _mouse_mirror_process(delta):
	_smoothed_relative = _smoothed_relative.lerp(_mouse_relative, clamp(mirror_relative_smooth * delta, 0.0, 1.0))
	var magnitude := _smoothed_relative.length()

	#if magnitude <= mirror_deadzone:
		#_mouse_relative = Vector2.ZERO
		#return

	var relative_weight : float = clamp(magnitude / mouse_sensitivity_range, 0.0, 1.0)

	var acc_mode := Input.get_axis("right_click", "left_click")
	#if Input.is_action_just_pressed("left_click"): _warp_at_pos(global_position, 0.5)
	var target_speed := (_init_brake_speed if acc_mode == -1 else _init_max_speed if acc_mode == 1 else _init_base_speed) * _speed_multiplier
	_current_speed = move_toward(_current_speed, target_speed, delta * mouse_mirror_acc)

	var intended_dir = _smoothed_relative.angle()
	var turn_rate = (mirror_base_turn_rate if acc_mode == 0 else mirror_acc_turn_rate)
	_direction = lerp_angle(_direction, intended_dir, turn_rate * delta * relative_weight)

	velocity = Vector2.from_angle(_direction) * _current_speed

	_mouse_relative = Vector2.ZERO

func _input(event):
	if event is InputEventMouseMotion:
		# copy and accumulate; don't store the event object (Godot pools events)
		_mouse_relative += event.relative

func _ai_mode_process(delta):
	if not ai_follow:
		return
	var dist_to_follow = global_position.distance_to(ai_follow.global_position)
	var acc_mode := -1. if dist_to_follow < 200. else 0. if dist_to_follow < 600. else 1.
	var target_speed = (_init_brake_speed if acc_mode == -1 else _init_max_speed if acc_mode == 1 else _init_base_speed) * _speed_multiplier
	_current_speed = move_toward(_current_speed, target_speed, delta * mouse_mode_acc)

	var intended_dir = global_position.angle_to_point(ai_follow.global_position) if global_position.distance_to(ai_follow.global_position) > mouse_deadzone_radius else _direction
	_direction = lerp_angle(_direction, intended_dir, (base_turn_rate if not acc_mode else acc_turn_rate) * delta)

	velocity = Vector2.from_angle(_direction) * _current_speed

func boost(boost_amount := 1.):
	_boost_time = clamp(_boost_time + boost_amount * max_boost_time, 0, max_boost_time)

func _handle_boost(delta):
	if _boost_time > 0:
		_boost_time -= delta
		_speed_multiplier = lerp(1.0, boost_multiplier, min( 2. * _boost_time / max_boost_time, 1.))
	else:
		_speed_multiplier = 1.0

func add_held_star(star : ConnectableStarTest):
	if get_held_star():
		remove_held_star()
	_held_star = star
	held_star_particles.emitting = true

func remove_held_star():
	_held_star = null
	held_star_particles.emitting = false

func get_held_star() -> ConnectableStarTest:
	return _held_star

func link_new_star(new_star : ConnectableStarTest):
	_held_star.link(new_star)
	remove_held_star()

func _handle_held_star():
	if not _held_star:
		return
	if global_position.distance_to(_held_star.global_position) > _held_star.max_radius:
		remove_held_star()
