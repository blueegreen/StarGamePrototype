extends Camera2D

@export var player : StarTest
@export var deadzone_radius := 400.
@export var deadzone_softness_width := 300.
@export var exceed_distance_max := 1500.
@export var max_zoom_out := Vector2(0.6, 0.6)
@export var smoothing_min := 1.;
@export var smoothing_max := 3.;

func _process(delta: float):
	handle_zoom(delta)
	handle_position(delta)

func handle_zoom(delta: float):
	if not player:
		return
	var target_zoom := Vector2.ONE.lerp(max_zoom_out, player.velocity.length() / (player.max_speed * player.boost_multiplier))
	target_zoom = target_zoom.limit_length(sqrt(2))
	zoom = zoom.lerp(target_zoom, delta * 2.)

var _smooth_vel_dir := Vector2.ZERO
func handle_position(delta: float):
	if not player:
		return
	
	var player_dist = (player.get_screen_transform().origin).distance_to(get_viewport_rect().size * 0.5)
	#var deadzone_weight = smoothstep(deadzone_radius - deadzone_softness_width, deadzone_radius + deadzone_softness_width, player_dist)
	var weight : float= lerp(0., 1., player.velocity.length() / (player.max_speed * player.boost_multiplier - player.base_speed))
	
	var player_pos := player.global_position
	_smooth_vel_dir = _smooth_vel_dir.lerp(player.velocity.normalized(), delta * 5.)
	var exceed_pos := player_pos + _smooth_vel_dir * exceed_distance_max
	var camera_target_pos : Vector2 = lerp(player_pos, exceed_pos, weight)
	var camera_smoothing : float = lerp(smoothing_min, smoothing_max, weight)
	
	global_position = lerp(global_position, camera_target_pos, delta * camera_smoothing)

func shake(strength: float = 10.0, duration: float = 0.3) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	var apply_shake := func(s: float) -> void:
		var target_offset := Vector2(
			randf_range(-s, s),
			randf_range(-s, s)
		)

	tween.tween_method(apply_shake, strength, 0.0, duration)
	tween.finished.connect(func(): offset = Vector2.ZERO)
	
