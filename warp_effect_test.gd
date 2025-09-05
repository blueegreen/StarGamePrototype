extends CanvasLayer

@export var shader_rect : ColorRect

func warp_at(pos : Vector2, master_strength := 1.):
	shader_rect.material.set_shader_parameter("master_strength", master_strength)
	$AnimationPlayer.play("warp")
	var reset_centre = func(_n: int):
		shader_rect.material.set_shader_parameter("warp_position", world_to_screen_uv(pos))
	var tween := create_tween()
	tween.tween_method(reset_centre, 0, 1, 1.5)

func world_to_screen_uv(world_pos: Vector2) -> Vector2:
	var viewport := get_viewport()
	var canvas_transform := viewport.get_canvas_transform()
	var screen_pos := canvas_transform * world_pos

	var viewport_size := viewport.get_visible_rect().size
	var screen_uv := screen_pos / viewport_size
	
	var aspect_ratio := viewport_size.x / viewport_size.y
	var aspect_uv := Vector2(
		(screen_uv.x - 0.5) * aspect_ratio + 0.5,
		screen_uv.y
	)

	return aspect_uv
