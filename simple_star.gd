extends Node2D
class_name BaseStarTest

@export var canvas_layer : CanvasLayer
@export var connections : Dictionary[BaseStarTest, bool]
@export var text : String
@export var activated := false
@export var sprite : AnimatedSprite2D
var _lines : Dictionary[BaseStarTest, Line2D]

func _ready():
	for n in connections:
		if connections[n]:
			connect_to(n, true)
	if activated: activation_animation()

#func set_lines():
	#for connected_star in _lines:
		#if _lines[connected_star].get_point_count() != 2:
			#continue
#
		#var star_canvas = connected_star.get_canvas_layer_node()
		#var self_canvas = get_canvas_layer_node()
#
		#var star_xform = star_canvas.get_final_transform() if star_canvas else Transform2D.IDENTITY
		#var self_xform = self_canvas.get_final_transform() if self_canvas else Transform2D.IDENTITY
		#
		#var star_pos_view = star_xform * connected_star.global_position
		#var self_pos_view = self_xform * global_position
#
		#var final_pos = self_xform.affine_inverse() * (star_pos_view)
		#
		#_lines[connected_star].set_point_position(1, to_local(final_pos))

func _warp_at_pos(pos: Vector2, strength: float):
	var new_warp = preload("res://warp_effect_test.tscn").instantiate()
	add_child(new_warp)
	new_warp.warp_at(pos, strength)
	var tween = get_tree().create_tween()
	tween.tween_interval(0.5)
	tween.tween_callback(func(): new_warp.queue_free())

func activation_animation():
	var text_block := Label.new()
	text_block.modulate = Color(1., 1., 1., 0.)
	text_block.text = text
	text_block.label_settings = load("res://assets/dialogue_text_settings.tres")
	
	if canvas_layer:
		canvas_layer.add_child(text_block)
	else:
		add_child(text_block)
	
	text_block.global_position = global_position
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2.ONE * 5., 1.).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel().tween_property(sprite, "rotation", 2*PI, 1.).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(text_block, "modulate", Color.WHITE, 1.).set_ease(Tween.EASE_IN_OUT)
	
	_warp_at_pos(global_position, 0.8)
	
func _on_loop_detector_test_looped(_ship, _direction):
	for n in connections:
		if connections[n]:
			continue
		connections[n] = true
		connect_to(n)
	
	if activated:
		return
	activated = true
	activation_animation()

func connect_to(star: BaseStarTest, quick := false):
	if star == self:
		return
	var new_line = Line2D.new()
	new_line.width = 5.
	add_child(new_line)
	_lines[star] = new_line
	new_line.add_point(Vector2.ZERO)
	new_line.add_point(Vector2.ZERO)
	
	var final_position := to_local(star.global_position)
	if quick:
		new_line.set_point_position(1, final_position)
		return
	
	var time_to_connect = global_position.distance_to(star.global_position) / 2000.
	var set_line = func(pos:Vector2):
		new_line.set_point_position(1, pos)
	var line_tween = create_tween()
	line_tween.tween_method(set_line, Vector2.ZERO, final_position, time_to_connect).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	
