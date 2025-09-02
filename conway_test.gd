extends Node2D

@export_category("Game of Life")
@export var step_time := 0.5
@export var neighborhood := Vector2i(3, 3)
@export var stable_range := Vector2i(2, 3)
@export var born_range := Vector2i(3, 3)

@export_category("Dependecies")
@export var tile_map : TileMapLayer
@export var color_rect : ColorRect
@export var timer : Timer

const FILLED_CELL_ID = Vector2i(0, 0)
const BLANK_CELL_ID  = Vector2i(1, 0)
const TILE_SIZE = 16

var _running := false:
	set(value):
		_running = value
		tile_map.visible = !_running

var _draw_size := 1:
	set(value):
		value += 1 if value % 2 == 0 else 0
		value = clamp(value, 1, 11)
		_draw_size = value

var _life_texture : ImageTexture

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	timer.wait_time = step_time
	_setup_image_texture()

func _setup_image_texture():
	_life_texture = ImageTexture.new()
	var image := Image.create(int(1920./TILE_SIZE), int(1080./TILE_SIZE), false, Image.FORMAT_RF)
	image.fill(Color(0, 0, 0, 1))

	_life_texture = ImageTexture.create_from_image(image)
	
	if color_rect.material is ShaderMaterial:
		color_rect.material.set_shader_parameter("life_texture", _life_texture)

func _draw():
	#draw_circle(get_global_mouse_position(), _draw_size * TILE_SIZE / 2., Color.WHITE, false, TILE_SIZE / 4.) 
	if _running:
		return
	var rect = \
	Rect2(tile_map.map_to_local(tile_map.local_to_map(get_global_mouse_position())) - (Vector2.ONE * TILE_SIZE * _draw_size) / 2., \
	Vector2.ONE * _draw_size * TILE_SIZE)
	draw_rect(rect, Color.WHITE, false, TILE_SIZE/4.)

func _input(event):
	match _running:
		true:
			if Input.is_action_pressed("left_click") or event.is_action_pressed("play_pause"):
				_running = false
				timer.stop()
		false:
			if event is InputEventMouse:
				queue_redraw()
			if Input.is_action_pressed("left_click"):
				_paint_at(get_global_mouse_position())
				_running = false
			if event.is_action_pressed("play_pause"):
				timer.start()
				_running = true
				queue_redraw()
				return
			_draw_size += int(Input.get_axis("scroll_down", "scroll_up")) * 2

func _run_automata():
	var cells_to_update : Dictionary[Vector2i, Vector2i] = {}

	for cell_coord in tile_map.get_used_cells():
		var cell_type : Vector2i = tile_map.get_cell_atlas_coords(cell_coord)
		var neighboring_living_cells := 0
		for x : int in range((cell_coord.x - int(neighborhood.x / 2.)), (cell_coord.x + int(neighborhood.x / 2.)) + 1):
			for y : int in range((cell_coord.y - int(neighborhood.y / 2.)), (cell_coord.y + int(neighborhood.y / 2.)) + 1):
				var neighbor_coord = Vector2i(x, y)
				var neighbor_type : Vector2i = tile_map.get_cell_atlas_coords(neighbor_coord)
				if neighbor_type == FILLED_CELL_ID and neighbor_coord != cell_coord:
					neighboring_living_cells += 1
					
		#if neighboring_living_cells > 0 and cell_type == FILLED_CELL_ID:
			#print(neighboring_living_cells)
	
		if (neighboring_living_cells < stable_range.x or neighboring_living_cells > stable_range.y) and cell_type == FILLED_CELL_ID:
			cells_to_update[cell_coord] = BLANK_CELL_ID
		elif neighboring_living_cells >= born_range.x and neighboring_living_cells <= born_range.y and cell_type == BLANK_CELL_ID:
			cells_to_update[cell_coord] = FILLED_CELL_ID
	
	for coord in cells_to_update:
		tile_map.set_cell(coord, 0, cells_to_update[coord])
		
		if coord.x < 0 or coord.x >= int(1920./TILE_SIZE) or coord.y < 0 or coord.y >= int(1080./TILE_SIZE):
			continue
		var image = _life_texture.get_image()
		var data := 0 if cells_to_update[coord] == BLANK_CELL_ID else 1
		image.set_pixelv(Vector2(coord), Color(data, 0, 0, 1))
		_life_texture.update(image)

func _paint_at(mouse_pos: Vector2):
	var local_pos = tile_map.to_local(mouse_pos)
	var center = tile_map.local_to_map(local_pos)

	var half : int = int(_draw_size / 2.)

	for x in range(-half, -half + _draw_size):
		for y in range(-half, -half + _draw_size):
			var coords = center + Vector2i(x, y)
			tile_map.set_cell(coords, 0, FILLED_CELL_ID)
