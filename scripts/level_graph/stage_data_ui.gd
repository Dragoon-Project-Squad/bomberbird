class_name StageDataUI extends Control

const ENEMY_SCENE_DIR: String = "res://scenes/enemies/"

const ENEMY_DIR: Dictionary = {
	"Egg Goon 1": "egg_enemy_type1.tscn",
	"Egg Goon 2": "egg_enemy_type2.tscn",
	"Egg Goon 3": "egg_enemy_type3.tscn",
	"Egg Goon 4": "egg_enemy_type4.tscn",
	"R2 Goon": "egg_R2_enemy.tscn",
	"Knight Goon": "knight_enemy.tscn",
	"Slime Goon": "slime_goon.tscn",
	"Tank Goon": "tank_goon.tscn",
	"Skunk Goon": "skunk_goon.tscn",
	"Bomb Eater Goon": "bomb_eater_goon.tscn",
	"Hammer Goon": "hammer_goon.tscn",
	"Bomb Goon 1": "bomb_goon_type1.tscn",
	"Bomb Goon 2": "bomb_goon_type2.tscn",
	"Tomato Doki Boss": "tomato_boss.tscn",
	"Retro Doki Boss": "retro_doki_boss.tscn",
	}

enum draw_mode {FREE, LINE, RECT}
enum tile_type {UNBREAKABLE, BREAKABLE, ENEMY, SPAWNPOINT}

@onready var type_select: OptionButton = get_node("Header/TypeSelect")
@onready var sub_type_select: OptionButton = get_node("Header/SubTypeSelect")
@onready var probability_select: SpinBox = get_node("Header/ProbabilitySelect")
@onready var free_draw: Button = get_node("Header/FreeDraw")
@onready var line_draw: Button = get_node("Header/LineDraw")
@onready var rect_draw: Button = get_node("Header/RectDraw")
@onready var eraser_button: Button = get_node("Header/Eraser")
@onready var overwrite_checkmark: CheckBox = get_node("Header/Overwrite")
@onready var grit_container: GridContainer = $GridContainer
@onready var curr_cell_label: Label = $CurrentCellLabel

@export var map_size: Vector2i = Vector2i(13, 11)

var tile_type_name_str: Dictionary = {
	tile_type.UNBREAKABLE: "Unbreakable",
	tile_type.BREAKABLE: "Breakable",
	tile_type.ENEMY: "Enemy",
	tile_type.SPAWNPOINT: "SpawnPoint"
}

var cell_ui_elements: Array[ReferenceRect]
var selected_cells: Array[Vector2i]

var modified_cells: Dictionary = {}
var cell_border_color_overwrite: Dictionary = {}
var curr_draw_mode: int = draw_mode.FREE
var curr_type: int = 0
var curr_sub_type_id: int = 0
var curr_sub_type_str: String = ""
var curr_probability: float = 1.0

var _is_drawing: bool = false
## The eraser logic is stupid just as a warning
var _eraser_is_selected: bool = false
var _right_click_erase: bool = false
var _do_overwrite: bool = true
var draw_start: Vector2i = Vector2i(-1, 0)
var draw_pos: Vector2i = Vector2i(-1, 0) # Starts in an invalid state

func _ready():
	for type in tile_type_name_str.keys():
		type_select.add_item(tile_type_name_str[type], type)
	type_select.item_selected.connect(_on_selected_type)

	sub_type_select.item_selected.connect(func (index: int):
		curr_sub_type_id = sub_type_select.get_item_id(index)
		curr_sub_type_str = sub_type_select.get_item_text(index)
	)
	sub_type_select.clear()
	sub_type_select.disabled = true

	probability_select.value_changed.connect(func (value: float): curr_probability = value)
	free_draw.pressed.connect(func (): curr_draw_mode = draw_mode.FREE)
	line_draw.pressed.connect(func (): curr_draw_mode = draw_mode.LINE)
	rect_draw.pressed.connect(func (): curr_draw_mode = draw_mode.RECT)
	eraser_button.toggled.connect(func (toggled_on: bool): _eraser_is_selected = toggled_on)
	overwrite_checkmark.toggled.connect(func (toggled_on: bool): _do_overwrite = toggled_on)
	cell_ui_elements.resize(map_size.x * map_size.y)
	for j in range(map_size.y):
		for i in range(map_size.x):
			var cell = Vector2i(i, j)
			var cell_ui_element: StageCellUI = StageCellUI.create()
			cell_ui_element.custom_minimum_size = Vector2(50, 50)
			cell_ui_element.name = "StageCellUI_" + str(i) + "," + str(j)
			# Connecting the mouse entered signal to update the mouse position when it changes inside the grit
			cell_ui_element.mouse_entered.connect(_on_mouse_entered_cell.bind(cell))
			cell_ui_elements[_get_cell_ui_element_index(cell)] = cell_ui_element
			grit_container.add_child(cell_ui_element)

## readed the data from the handed resources and inputs them into the UI
func load_from_resources(enemy_table: EnemyTable = null, spawnpoint_table: SpawnpointTable = null, unbreakable_table: UnbreakableTable = null, breakable_table: BreakableTable = null):
	modified_cells.clear()
	if enemy_table != null:
		for entry in enemy_table.enemies:
			var enemy_name: String = ENEMY_DIR.find_key(entry.file)
			modified_cells[entry.coords] = _create_type_dict(tile_type.ENEMY, enemy_name, entry.probability)
			cell_ui_elements[_get_cell_ui_element_index(entry.coords)].apply_texture(modified_cells[entry.coords])
	if spawnpoint_table != null:
		for entry in spawnpoint_table.spawnpoints:
			modified_cells[entry.coords] = _create_type_dict(tile_type.SPAWNPOINT, null, entry.probability)
			cell_ui_elements[_get_cell_ui_element_index(entry.coords)].apply_texture(modified_cells[entry.coords])
	if unbreakable_table != null:
		for entry in unbreakable_table.unbreakables:
			modified_cells[entry.coords] = _create_type_dict(tile_type.UNBREAKABLE, null, entry.probability)
			cell_ui_elements[_get_cell_ui_element_index(entry.coords)].apply_texture(modified_cells[entry.coords])
	if breakable_table != null:
		for entry in breakable_table.breakables:
			modified_cells[entry.coords] = _create_type_dict(tile_type.BREAKABLE, entry.contained_pickup, entry.probability)
			cell_ui_elements[_get_cell_ui_element_index(entry.coords)].apply_texture(modified_cells[entry.coords])

## stores the data inputed into the UI into the table resources handed to it
func write_to_resources(enemy_table: EnemyTable, spawnpoint_table: SpawnpointTable, unbreakable_table: UnbreakableTable, breakable_table: BreakableTable):
	for tile_pos in modified_cells.keys():
		var tile: Dictionary = modified_cells[tile_pos]
		match modified_cells[tile_pos].main_type:
			tile_type.UNBREAKABLE:
				unbreakable_table.append(tile_pos, tile.probability)
			tile_type.BREAKABLE:
				breakable_table.append(tile_pos, tile.sub_type, tile.probability)
			tile_type.ENEMY:
				if tile.sub_type != "":
					enemy_table.append(tile_pos, ENEMY_DIR[tile.sub_type], StageNode.get_path_to_scene(tile.sub_type, ENEMY_SCENE_DIR, ENEMY_DIR, true), tile.probability)
			tile_type.SPAWNPOINT:
				spawnpoint_table.append(tile_pos, tile.probability)

## Draws the current selection into the cell
## [param cell] Vector2i the cell to draw
func draw(cell: Vector2i):
	if (_eraser_is_selected || _right_click_erase) && modified_cells.has(cell):
		modified_cells.erase(cell)
		cell_ui_elements[_get_cell_ui_element_index(cell)].apply_texture()
	elif (_do_overwrite || !modified_cells.has(cell)) && !(_eraser_is_selected || _right_click_erase):
		match curr_type:
			tile_type.UNBREAKABLE:
				modified_cells[cell] = _create_type_dict(curr_type, null, curr_probability)
			tile_type.BREAKABLE:
				modified_cells[cell] = _create_type_dict(curr_type, curr_sub_type_id, curr_probability)
			tile_type.ENEMY:
				modified_cells[cell] = _create_type_dict(curr_type, curr_sub_type_str, curr_probability)
			tile_type.SPAWNPOINT:
				modified_cells[cell] = _create_type_dict(curr_type, null, curr_probability)
		cell_ui_elements[_get_cell_ui_element_index(cell)].apply_texture(modified_cells[cell])

## static function that creates a valid entry for 'modified_cells' 
static func _create_type_dict(main_type: int, sub_type: Variant, probability: float):
	return {
		"main_type": main_type,
		"sub_type": sub_type,
		"probability": probability,
	}

func add_border_color_overwrite(cell: Vector2i, color: Color):
	cell_border_color_overwrite[cell] = color
	_set_border_color_to(cell)

func remove_border_color_overwrite(cell: Vector2i):
	if cell_border_color_overwrite.has(cell):
		cell_border_color_overwrite.erase(cell)
		_set_border_color_to(cell)

## sets the border color of a cell, defaults to black
func _set_border_color_to(cell: Vector2i, color: Color = Color.BLACK):
	if color == Color.BLACK && cell_border_color_overwrite.has(cell):
		color = cell_border_color_overwrite[cell]
	cell_ui_elements[_get_cell_ui_element_index(cell)].border_color = color

## given a cell returns the index of this cells 'modified_cells' entry
func _get_cell_ui_element_index(cell: Vector2i):
	return cell.x + cell.y * map_size.x

## sets mouse button state
func _on_grid_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton && draw_pos.x != -1:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if !_is_drawing && event.pressed:
					draw_start = draw_pos
					_on_mouse_entered_cell(draw_pos, true)
				elif _is_drawing && !event.pressed:
					_ended_drawing()
				_is_drawing = event.pressed
			MOUSE_BUTTON_RIGHT:
				_right_click_erase = event.pressed
				if !_is_drawing && event.pressed:
					draw_start = draw_pos
					_on_mouse_entered_cell(draw_pos, true)
				elif _is_drawing && !event.pressed:
					_ended_drawing(true)
				_is_drawing = event.pressed

## set the current mouse position to invalid if we exit the UI element
func _on_grid_container_mouse_exited() -> void:
	_set_border_color_to(draw_pos)
	draw_pos = Vector2i(-1, 0)
	_is_drawing = false
	curr_cell_label.text = ""
	if selected_cells.is_empty(): return
	selected_cells.map(_set_border_color_to)
	selected_cells.clear()

## sets the string for the label to inform the user of the contents of the cell they are hovering over
func _set_label(cell: Vector2i):
	var coord_is: String = str(cell) + " is"
	if !modified_cells.has(cell):
		curr_cell_label.text = coord_is + " empty"
		return
	var main_type: String = " " + tile_type_name_str[modified_cells[cell].main_type]
	var sub_type: String = ""
	if modified_cells[cell].main_type == tile_type.BREAKABLE:
		sub_type = " with a " + globals.pickup_name_str[modified_cells[cell].sub_type] + " pickup"
	elif modified_cells[cell].main_type == tile_type.ENEMY:
		sub_type = " with file " + modified_cells[cell].sub_type
	curr_cell_label.text = coord_is + main_type + sub_type

## makes this cell as hovered and if needed draws or adds it to the selection
func _on_mouse_entered_cell(cell: Vector2i, force: bool = false):
	_set_border_color_to(draw_pos)
	draw_pos = cell
	_set_border_color_to(cell, Color.WHITE)
	_set_label(cell)

	if !_is_drawing && !force: return
	var new_selected_cells: Array[Vector2i]
	match curr_draw_mode:
		draw_mode.FREE: 
			draw(draw_pos)
			_set_label(draw_pos)
		draw_mode.LINE:
			var start: Vector2i = draw_start if draw_start.x <= draw_pos.x else draw_pos
			var end: Vector2i = draw_pos if draw_start.x <= draw_pos.x else draw_start
			if end.x == start.x:
				for y in range(start.y, end.y + 1):
					new_selected_cells.append(Vector2i(start.x, y))
					_set_border_color_to(Vector2i(start.x, y), Color.WHITE)
			var m: float = float(end.y - start.y) / float(end.x - start.x)
			var m_count: float = 0
			for x in range(start.x, end.x):
				var y_x: int = floor(m_count) + start.y
				var y_x_1: int = floor(m_count + m) + start.y
				var dir: int = 1
				if y_x == y_x_1: 
					new_selected_cells.append(Vector2i(x, y_x))
					_set_border_color_to(Vector2i(x, y_x), Color.WHITE)
				elif y_x > y_x_1 && m < 0: dir = -1
				for y in range(y_x, y_x_1, dir):
					new_selected_cells.append(Vector2i(x, y))
					_set_border_color_to(Vector2i(x, y), Color.WHITE)
				m_count += m
			new_selected_cells.append(Vector2i(end.x, end.y))
			_set_border_color_to(Vector2i(end.x, end.y), Color.WHITE)
		
		draw_mode.RECT:
			var start: Vector2i = Vector2i(min(draw_start.x, draw_pos.x), min(draw_start.y, draw_pos.y))
			var end: Vector2i = Vector2i(max(draw_start.x, draw_pos.x), max(draw_start.y, draw_pos.y))
			for j in range(start.y, end.y + 1):
				for i in range(start.x, end.x + 1):
					new_selected_cells.append(Vector2i(i, j))
					_set_border_color_to(Vector2i(i, j), Color.WHITE)
	selected_cells.filter(func (old_cell: Vector2i): return !(old_cell in new_selected_cells)).map(_set_border_color_to)
	selected_cells = new_selected_cells

## called when a drawing request ends if a selection exists will draw that selection
func _ended_drawing(force_erase: bool = false):
	if force_erase:
		_right_click_erase = true
	match curr_draw_mode:
		draw_mode.LINE:
			selected_cells.map(draw)
		draw_mode.RECT:
			selected_cells.map(draw)
		_: pass
	selected_cells.map(_set_border_color_to)
	selected_cells.clear()
	_set_label(draw_pos)
	if force_erase:
		_right_click_erase = false

## clears and writes into the sub_type OptionButton depending on the main_type selected
func _on_selected_type(index: int):
	sub_type_select.disabled = false
	curr_type = type_select.get_item_id(index)
	match curr_type:
		tile_type.UNBREAKABLE:
			sub_type_select.clear()
			sub_type_select.disabled = true
		tile_type.BREAKABLE:
			sub_type_select.clear()
			for pickup in range(globals.pickups.RANDOM + 1):
				match pickup:
					globals.pickups.GENERIC_COUNT: continue
					globals.pickups.GENERIC_BOOL: continue
					globals.pickups.GENERIC_EXCLUSIVE: continue
					globals.pickups.GENERIC_BOMB: continue
				sub_type_select.add_item(globals.pickup_name_str[pickup], pickup)
			sub_type_select.select(sub_type_select.get_item_index(globals.pickups.RANDOM))
			curr_sub_type_id = globals.pickups.RANDOM
			curr_sub_type_str = sub_type_select.get_item_text(sub_type_select.get_item_index(globals.pickups.RANDOM))
		tile_type.ENEMY:
			sub_type_select.clear()
			if ENEMY_DIR.keys() == []:
				curr_sub_type_str = ""
				sub_type_select.disabled = true
			else:
				ENEMY_DIR.keys().map(sub_type_select.add_item)
				sub_type_select.select(-1)
		tile_type.SPAWNPOINT:
			sub_type_select.clear()
			sub_type_select.disabled = true
