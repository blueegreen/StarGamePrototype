extends Area2D
class_name LoopDetectorTest

signal body_looping(ship : StarTest)
signal body_stopped_looping(ship : StarTest)
signal looped(ship : StarTest, direction: int) # +1 = CCW, -1 = CW

@export var detection_radius := 100.0

class LoopData:
	var accum_angle: float
	var prev_angle: float

var _loop_characters : Dictionary[StarTest, LoopData]

func _ready():
	var circle_shape := CircleShape2D.new()
	circle_shape.radius = detection_radius
	var collision_shape := CollisionShape2D.new()
	collision_shape.shape = circle_shape
	add_child(collision_shape)

func _process(_delta):
	for chr in _loop_characters.keys():
		var data: LoopData = _loop_characters[chr]
		
		var cur_angle = global_position.angle_to_point(chr.global_position)
		var delta_angle = wrapf(cur_angle - data.prev_angle, -PI, PI)
		data.accum_angle += delta_angle
		
		if abs(data.accum_angle) > TAU:
			looped.emit(chr, sign(data.accum_angle))
			data.accum_angle = 0.0
		
		data.prev_angle = cur_angle

func _on_body_entered(body):
	if not body is StarTest:
		return
	if not _loop_characters.has(body):
		var data := LoopData.new()
		data.accum_angle = 0.0
		data.prev_angle = global_position.angle_to_point(body.global_position)
		_loop_characters[body] = data
		body_looping.emit(body)

func _on_body_exited(body):
	if not body is StarTest:
		return
	if _loop_characters.has(body):
		_loop_characters.erase(body)
		body_stopped_looping.emit(body)

func get_current_accum(body : StarTest) -> float:
	if _loop_characters.has(body):
		return _loop_characters[body].accum_angle
	return 0.0
