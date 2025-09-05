extends Area2D
class_name ConnectableStarTest

@export var linked_to : Dictionary[ConnectableStarTest, Line2D]
@export var link_limit := 2
@export var max_radius := 3000.

@export var particles : GPUParticles2D

func _ready():
	for linked_star in linked_to:
		_add_linked_line(linked_star)

func _on_body_entered(body):
	if body is StarTest:
		body.boost(0.6)
		$warp_effect_test.warp_at(global_position)
		var held_star : ConnectableStarTest = body.get_held_star()
		if held_star and held_star != self:
			held_star.link_star(self)
			link_star(held_star)
			body.remove_held_star()
		if can_have_more_links():
			body.add_held_star(self)
			


func can_have_more_links() -> bool:
	return linked_to.size() < link_limit

func link_star(star : ConnectableStarTest):
	if linked_to.has(star) or star == self:
		return
	_add_linked_line(star)

func unlink_star(star : ConnectableStarTest):
	var could_link = can_have_more_links()
	if linked_to.has(star):
		linked_to[star].queue_free()
		linked_to.erase(star)
		if star.linked_to.has(self):
			star.unlink_star(self)
	
	update_animation()
	if not could_link: $AnimationPlayer.play_backwards("linked")

func _add_linked_line(star: ConnectableStarTest):
	if star == self:
		return
	var new_line = Line2D.new()
	add_child(new_line)
	new_line.z_index = -1
	new_line.width = 10.
	new_line.add_point(to_local(self.global_position))
	new_line.add_point(to_local(self.global_position))
	linked_to[star] = new_line
	
	var set_line_point = func(pos):
		new_line.set_point_position(1, pos)
	
	var line_tween := create_tween()
	line_tween.tween_method(set_line_point, to_local(self.global_position), to_local(star.global_position), 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	line_tween.set_parallel().tween_property(new_line, "width", 25., 0.3)
	line_tween.set_parallel(false).tween_property(new_line, "width", 10., 0.3)
	line_tween.tween_callback(update_animation)

func update_animation():
	particles.emitting = can_have_more_links()
	if not can_have_more_links(): $AnimationPlayer.play("linked")
