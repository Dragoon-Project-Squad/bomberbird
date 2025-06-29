class_name SettingsTabContainer
extends Control

@onready var tab_container: TabContainer = $TabContainer
@onready var line_edit: LineEdit = $TabContainer/General/MarginContainer/VBoxContainer/HBoxContainer/LineEdit
@onready var password_status: Label = $TabContainer/General/MarginContainer/VBoxContainer/PasswordStatus
@onready var reset_dialog: ConfirmationDialog = %ResetConfirmationDialog

signal options_menu_exited
signal correct_secret_inputted

@export var error_sound: WwiseEvent
@export var correct_sound: WwiseEvent

func _process(_delta):
	options_menu_inputs()


func change_tab(tab : int) -> void:
	tab_container.set_current_tab(tab)


func options_menu_inputs() -> void:
	if Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("ui_right"):
		if tab_container.current_tab >= tab_container.get_tab_count() - 1:
			change_tab(0)
			return
		
		var next_tab = tab_container.current_tab + 1
		change_tab(next_tab)
	
	if Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("ui_left"):
		if tab_container.current_tab == 0:
			change_tab(tab_container.get_tab_count() - 1)
		
		var previous_tab = tab_container.current_tab - 1
		change_tab(previous_tab)
	
	if (Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("ui_cancel")):
		options_menu_exited.emit()

func accept_password() -> void:
	globals.secrets_enabled = true
	correct_sound.post(self)
	password_status.text = "ALL SECRETS UNLOCKED"
	
func reject_password() -> void:
	error_sound.post(self)
	password_status.text = "NUH UH: WRONG PASSWORD"

func _on_password_submit_pressed() -> void:
	if line_edit.text.to_upper() == "GIVEMETHESECRETNOW":
		accept_password()
	else:
		reject_password()

func _on_reset_pressed():
	reset_dialog.popup_centered()

func _on_reset_confirmed():
	reset_dialog.hide()
	globals.secrets_enabled = false
	SettingsContainer.clean_data_flag()
	SaveManager.on_secret_delete()

func _on_reset_cancelled():
	reset_dialog.hide()
