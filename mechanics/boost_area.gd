extends Area2D
class_name BoostAreaTest

var _boosted := false
@export var boost_amount := 0.3

func _on_body_entered(body):
	if body is StarTest and not _boosted:
		body.boost(boost_amount)
		_boosted = true
		$Sprite2D.modulate = Color(1, 1, 1, 0.5)
		boost_animation(body)
		await get_tree().create_timer(0.8).timeout
		_boosted = false
		$Sprite2D.modulate = Color.WHITE

func boost_animation(body: StarTest):
	$warp_effect_test.warp_at(global_position, 0.8)
	$GPUParticles2D.emitting = true
	var vel := body.velocity.normalized()
	$GPUParticles2D.process_material.direction = Vector3(vel.x, vel.y, 0)
	#Engine.time_scale = 0.2
	#var tween := get_tree().create_tween()
	#tween.tween_interval(0.03)
	#tween.tween_callback(func():
		#Engine.time_scale = 1.)
