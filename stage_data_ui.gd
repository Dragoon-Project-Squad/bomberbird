extends Control

signal ended_drawing

enum draw_mode {FREE, LINE, RECT}
enum tile_type {UNBREAKABLE, BREAKABLE, ENEMY, SPAWNPOINT}

@onready var grit_container: GridContainer = $GridContainer
@onready var type_select: OptionButton = get_node("HBoxContainer/TypeSelect")
@onready var sub_type_select: OptionButton = get_node("HBoxContainer/SubTypeSelect")
@onready var free_draw: Button = get_node("HBoxContainer/FreeDraw")
@onready var line_draw: Button = get_node("HBoxContainer/LineDraw")
@onready var rect_draw: Button = get_node("HBoxContainer/RectDraw")
@onready var eraser_button: Button = get_node("HBoxContainer/Eraser")
@onready var overwrite_checkmark: CheckBox = get_node("HBoxContainer/Overwrite")


@export var map_size: Vector2i = Vector2i(13, 11)

var curr_draw_mode: int = draw_mode.FREE
var curr_type: int
var curr_sub_type_idx: int
var curr_sub_type_str: String

var _is_drawing: bool = false
var _is_erasing: bool = false
var _do_overwrite: bool = true
var draw_start: Vector2i = Vector2i(-1, 0)
var draw_pos: Vector2i = Vector2i(-1, 0) # Starts in an invalid state

var tile_type_name_str: Dictionary = {
	tile_type.UNBREAKABLE: "Unbreakable",
	tile_type.BREAKABLE: "Breakable",
	tile_type.ENEMY: "Enemy",
	tile_type.SPAWNPOINT: "Spawnpoint",
}


func _ready():
	free_draw.pressed.connect(func (): curr_draw_mode = draw_mode.FREE)
	line_draw.pressed.connect(func (): curr_draw_mode = draw_mode.LINE)
	rect_draw.pressed.connect(func (): curr_draw_mode = draw_mode.RECT)
	eraser_button.toggled.connect(_on_eraser_toggled)
	overwrite_checkmark.toggled.connect(func (toggled_on: bool): _do_overwrite = toggled_on)

	for type in tile_type_name_str.keys():
		type_select.add_item(tile_type_name_str[type], type)
	type_select.item_selected.connect(_on_selected_type)

	sub_type_select.item_selected.connect(func (index: int):
		curr_sub_type_idx = index
		curr_sub_type_str = sub_type_select.get_item_text(index)
	)
	sub_type_select.clear()
	sub_type_select.disabled = true

	for i in range(map_size.y):
		for j in range(map_size.x):
			var cell_ui_element: ReferenceRect = ReferenceRect.new()
			cell_ui_element.custom_minimum_size = Vector2(50, 50)
			cell_ui_element.editor_only = false
			cell_ui_element.border_color = Color.BLACK
			cell_ui_element.border_width = 1.0
			cell_ui_element.mouse_filter = Control.MOUSE_FILTER_PASS
			# Connecting the mouse entered signal to update the mouse position when it changes inside the grit
			cell_ui_element.mouse_entered.connect(_on_mouse_entered_cell.bind(Vector2i(i, j)))
			grit_container.add_child(cell_ui_element)

func draw(cells: Array[Vector2i]):
	pass

## sets mouse button state
func _on_grid_container_gui_input(event: InputEvent) -> void:
	# The final boss of if statment
	if event is InputEventMouseButton && draw_pos.x != -1:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if !_is_drawing && event.pressed && !_is_erasing:
					draw_start = draw_pos
				elif _is_drawing && (!event.pressed || _is_erasing):
					ended_drawing.emit()
				_is_drawing = event.pressed && !_is_erasing
			MOUSE_BUTTON_RIGHT:
				if !_is_erasing && event.pressed && !_is_drawing:
					draw_start = draw_pos
				elif !_is_erasing && (!event.pressed || _is_drawing):
					ended_drawing.emit()
				_is_erasing = event.pressed && !_is_drawing

## set the current mouse position to invalid if we exit the UI element
func _on_grid_container_mouse_exited() -> void:
	draw_pos = Vector2i(-1, 0)
	_is_drawing = false
	if curr_draw_mode != draw_mode.FREE: return
	draw([draw_pos])

func _on_mouse_entered_cell(cell: Vector2i):
	draw_pos = cell
	if curr_draw_mode != draw_mode.FREE: return
	if _is_drawing:
		pass #TODO store the current selection in this cell
	elif _is_erasing:
		pass #TODO delete the current selection in this cell

func _ended_drawing(end_cell: Vector2i):
	#TODO: WRITE OR ERASE AS EITHER A LINE FROM START POS OF A RECT SPANNED BY START POS AND END POS
	match curr_draw_mode:
		draw_mode.LINE:
			draw([end_cell])
		draw_mode.RECT:
			draw([end_cell])
		_: pass

func _on_selected_type(index: int):
	sub_type_select.disabled = false
	match index:
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
			#TODO: add as subtypes the scene files of enemies
		tile_type.SPAWNPOINT:
			sub_type_select.clear()
			sub_type_select.disabled = true

func _on_eraser_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.
