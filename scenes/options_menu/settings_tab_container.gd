class_name SettingsTabContainer
extends Control

@onready var tab_container: TabContainer = $TabContainer
@onready var line_edit: LineEdit = $TabContainer/General/MarginContainer/VBoxContainer/HBoxContainer/LineEdit
@onready var password_audio: AudioStreamPlayer = $AudioStreamPlayer
@onready var password_status: Label = $TabContainer/General/MarginContainer/VBoxContainer/PasswordStatus

signal options_menu_exited
signal correct_secret_inputted

var error_sound: AudioStreamWAV = load("res://sound/fx/error.wav")
var correct_sound: AudioStreamWAV = load("res://sound/fx/secret.wav")

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
	password_audio.stream = correct_sound
	password_audio.play()
	password_status.text = "ALL SECRETS UNLOCKED"
	
func reject_password() -> void:
	password_audio.stream = error_sound
	password_audio.play()
	password_status.text = "INVALID PASSWORD..."

func _on_password_submit_pressed() -> void:
	if line_edit.text.to_upper() == "GIVEMETHESECRETNOW":
		accept_password()
	else:
		reject_password()
