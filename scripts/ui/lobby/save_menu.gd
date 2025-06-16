extends Control

signal save_menu_new_save
signal save_menu_existing_save
signal save_menu_back


@onready var save_buttons_file: Dictionary = {
	%SaveSelectButton_1: "save_1",
	%SaveSelectButton_2: "save_2",
	%SaveSelectButton_3: "save_3",
	%SaveSelectButton_4: "save_4",
	%SaveSelectButton_5: "save_5",
	%SaveSelectButton_6: "save_6",
	}

@onready var save_buttons: Dictionary = {
	%SaveSelectButton_1: {},
	%SaveSelectButton_2: {},
	%SaveSelectButton_3: {},
	%SaveSelectButton_4: {},
	%SaveSelectButton_5: {},
	%SaveSelectButton_6: {},
	}

@onready var next: Button = %Next
@onready var delete: Button = %Delete
@onready var back: Button = %Back
@onready var confirmation_dialog: ConfirmationDialog = $ConfirmationDialog

var save_button_group: ButtonGroup

func _ready() -> void:
	delete.disabled = true
	next.disabled = true
	save_button_group = ButtonGroup.new()
	for button in save_buttons.keys():
		# setup each save button
		button.button_group = save_button_group
		save_button_group.pressed.connect(button._on_toggled)
		button.set_save_name(int(button.name.right(1)))

		# read the save if it exists
		if !campaign_save_manager.save_exist(save_buttons_file[button]): continue
		save_buttons[button] = campaign_save_manager.load(save_buttons_file[button])

		# populate savefile_button
		button.set_player_name(save_buttons[button].player_name)
		button.set_character(save_buttons[button].character_paths)
		#TODO: write high score and completion percent to load button

	save_button_group.pressed.connect(_on_button_group_pressed)


func _on_button_group_pressed(button: BaseButton):
	assert(save_buttons.has(button))
	if !save_buttons[button].is_empty(): delete.disabled = false
	else: delete.disabled = true
	next.disabled = false

func _on_next_pressed() -> void:
	gamestate.current_save_file = save_buttons_file[save_button_group.get_pressed_button()]

	if save_buttons[save_button_group.get_pressed_button()].is_empty():
		gamestate.current_save = campaign_save_manager.get_new_save()
		save_menu_new_save.emit()
		return

	gamestate.current_save = save_buttons[save_button_group.get_pressed_button()]
	save_menu_existing_save.emit()

func _on_delete_pressed() -> void:
	confirmation_dialog.popup_centered()

func _on_delete_confirmed():
	var button: BaseButton = save_button_group.get_pressed_button()
	campaign_save_manager.delete_save(save_buttons_file[button])
	button.reset_to_empty()
	save_buttons[button] = {}
	confirmation_dialog.hide()

func _on_delete_cancelled():
	confirmation_dialog.hide()

func _on_back_pressed() -> void:
	save_menu_back.emit()
