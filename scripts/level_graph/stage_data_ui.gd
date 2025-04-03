class_name StageDataUI extends Control

enum draw_mode {FREE, LINE, RECT}
enum tile_type {UNBREAKABLE, BREAKABLE, ENEMY, SPAWNPOINT}

@onready var type_select: OptionButton = get_node("Header/TypeSelect")
@onready var sub_type_select: OptionButton = get_node("Header/SubTypeSelect")
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
var curr_draw_mode: int = draw_mode.FREE
var curr_type: int = 0
var curr_sub_type_id: int = 0
var curr_sub_type_str: String = ""

var _is_drawing: bool = false
var _eraser_is_selected: bool = false
var _do_overwrite: bool = true
var draw_start: Vector2i = Vector2i(-1, 0)
var draw_pos: Vector2i = Vector2i(-1, 0) # Starts in an invalid state

static func create(modified_cell: Dictionary):
	var stage_data_ui: StageDataUI = load("res://scenes/level_graph/stage_data_ui.tscn").instantiate(modified_cell)
	return stage_data_ui

func _ready(modified_cells_overwrite: Dictionary = {}):
	modified_cells = modified_cells_overwrite

	free_draw.pressed.connect(func (): curr_draw_mode = draw_mode.FREE)
	line_draw.pressed.connect(func (): curr_draw_mode = draw_mode.LINE)
	rect_draw.pressed.connect(func (): curr_draw_mode = draw_mode.RECT)
	eraser_button.toggled.connect(func (toggled_on: bool): _eraser_is_selected = toggled_on)
	overwrite_checkmark.toggled.connect(func (toggled_on: bool): _do_overwrite = toggled_on)

	for type in tile_type_name_str.keys():
		type_select.add_item(tile_type_name_str[type], type)
	type_select.item_selected.connect(_on_selected_type)

	sub_type_select.item_selected.connect(func (index: int):
		curr_sub_type_id = sub_type_select.get_item_id(index)
		curr_sub_type_str = sub_type_select.get_item_text(index)
	)
	sub_type_select.clear()
	sub_type_select.disabled = true

	cell_ui_elements.resize(map_size.x * map_size.y)
	for j in range(map_size.y):
		for i in range(map_size.x):
			var cell = Vector2i(i, j)
			var cell_ui_element: StageCellUI = StageCellUI.create() if !modified_cells.has(cell) else StageCellUI.create(modified_cells[cell])
			cell_ui_element.custom_minimum_size = Vector2(50, 50)
			cell_ui_element.name = "StageCellUI_" + str(i) + "," + str(j)
			# Connecting the mouse entered signal to update the mouse position when it changes inside the grit
			cell_ui_element.mouse_entered.connect(_on_mouse_entered_cell.bind(cell))
			cell_ui_elements[_get_cell_ui_element_index(cell)] = cell_ui_element
			grit_container.add_child(cell_ui_element)


func draw(cell: Vector2i):
	if _eraser_is_selected && modified_cells.has(cell):
		modified_cells.erase(cell)
		cell_ui_elements[_get_cell_ui_element_index(cell)].apply_texture()
	elif (_do_overwrite || !modified_cells.has(cell)) && !_eraser_is_selected:
		match curr_type:
			tile_type.UNBREAKABLE:
				modified_cells[cell] = [tile_type.UNBREAKABLE]
			tile_type.BREAKABLE:
				modified_cells[cell] = [tile_type.BREAKABLE, curr_sub_type_id]
			tile_type.ENEMY:
				modified_cells[cell] = [tile_type.ENEMY, curr_sub_type_str]
			tile_type.SPAWNPOINT:
				modified_cells[cell] = [tile_type.SPAWNPOINT]
		cell_ui_elements[_get_cell_ui_element_index(cell)].apply_texture(modified_cells[cell])

func _set_border_color_to(cell: Vector2i, color: Color = Color.BLACK):
	cell_ui_elements[_get_cell_ui_element_index(cell)].border_color = color

func _get_cell_ui_element_index(cell: Vector2i):
	return cell.x + cell.y * map_size.x

## sets mouse button state
func _on_grid_container_gui_input(event: InputEvent) -> void:
	if draw_pos.x == -1: return
	# The final boss of if statment
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
				pass# Color Picker
## set the current mouse position to invalid if we exit the UI element
func _on_grid_container_mouse_exited() -> void:
	_set_border_color_to(draw_pos)
	draw_pos = Vector2i(-1, 0)
	_is_drawing = false
	if selected_cells.is_empty(): return
	selected_cells.map(_set_border_color_to)
	selected_cells.clear()

func _set_label(cell: Vector2i):
	var main_type: String = (tile_type_name_str[modified_cells[cell][0]] if modified_cells.has(cell) else "empty")
	var sub_type: String = ""
	if modified_cells.has(cell) && modified_cells[cell][0] == tile_type.BREAKABLE:
		sub_type = "" if main_type == "empty" else (" with a " + str(globals.pickup_name_str[modified_cells[cell][1]]) + " pickup")
	elif modified_cells.has(cell) && modified_cells[cell][0] == tile_type.ENEMY:
		sub_type = "" if main_type == "empty" else " with file " + modified_cells[cell][1]
	curr_cell_label.text = str(cell) + " is " + main_type + sub_type

func _on_mouse_entered_cell(cell: Vector2i, force: bool = false):
	_set_border_color_to(draw_pos)
	draw_pos = cell
	_set_border_color_to(cell, Color.WHITE)
	_set_label(cell)
	if !_is_drawing && !force: return
	var start: Vector2i = Vector2i(min(draw_start.x, draw_pos.x), min(draw_start.y, draw_pos.y))
	var end: Vector2i = Vector2i(max(draw_start.x, draw_pos.x), max(draw_start.y, draw_pos.y))
	var new_selected_cells: Array[Vector2i]
	match curr_draw_mode:
		draw_mode.FREE: 
			draw(draw_pos)
			_set_label(draw_pos)
		draw_mode.LINE:
			#TODO: Maybe implement a proper draw line algorithm but pretty low prio imo
			if (end.x - start.x) <= (end.y - start.y):
				for j in range (start.y, end.y + 1):
					new_selected_cells.append(Vector2i(draw_start.x, j))
					_set_border_color_to(Vector2i(draw_start.x, j), Color.WHITE)
			else:
				for i in range (start.x, end.x + 1):
					new_selected_cells.append(Vector2i(i, draw_start.y))
					_set_border_color_to(Vector2i(i, draw_start.y), Color.WHITE)
	
		draw_mode.RECT:
			for j in range(start.y, end.y + 1):
				for i in range(start.x, end.x + 1):
					new_selected_cells.append(Vector2i(i, j))
					_set_border_color_to(Vector2i(i, j), Color.WHITE)
	selected_cells.filter(func (old_cell: Vector2i): return !(old_cell in new_selected_cells)).map(_set_border_color_to)
	selected_cells = new_selected_cells

func _ended_drawing():
	match curr_draw_mode:
		draw_mode.LINE:
			selected_cells.map(draw)
		draw_mode.RECT:
			selected_cells.map(draw)
		_: pass
	selected_cells.map(_set_border_color_to)
	selected_cells.clear()
	_set_label(draw_pos)

func _on_selected_type(index: int):
	sub_type_select.disabled = false
	curr_type = type_select.get_item_id(index)
	match curr_type:
		tile_type.UNBREAKABLE:
			sub_type_select.clear()
			sub_type_select.disabled = true
		tile_type.BREAKABLE:
			sub_type_select.clear()
			for pickup in range(globals.pickups.RANDOME + 1):
				match pickup:
					globals.pickups.GENERIC_COUNT: continue
					globals.pickups.GENERIC_BOOL: continue
					globals.pickups.GENERIC_EXCLUSIVE: continue
					globals.pickups.GENERIC_BOMB: continue
				sub_type_select.add_item(globals.pickup_name_str[pickup], pickup)
		tile_type.ENEMY:
			sub_type_select.clear()
			curr_sub_type_str = "ENEMYS NOT YET IMPLEMENTED"
			#TODO: add as subtypes the scene files of enemies
		tile_type.SPAWNPOINT:
			sub_type_select.clear()
			sub_type_select.disabled = true
