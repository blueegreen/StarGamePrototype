extends CanvasLayer

@export var shader_rect : ColorRect

func warp_at(node: Node2D):
	$AnimationPlayer.play("warp")
	var reset_centre = func(_n: int):
		shader_rect.material.set_shader_parameter("warp_position", world_to_screen_uv(node.global_position))
	var tween := create_tween()
	tween.tween_method(reset_centre, 0, 1, 1.5)

func world_to_screen_uv(world_pos: Vector2) -> Vector2:
	var viewport := get_viewport()
	var canvas_transform := viewport.get_canvas_transform()
	var screen_pos := canvas_transform * world_pos

	var viewport_size = viewport.get_visible_rect().size
	return screen_pos / viewport_size
