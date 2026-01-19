class_name SettingsTabContainer
extends Control

@onready var tab_container: TabContainer = $TabContainer
@onready var line_edit: LineEdit = $TabContainer/General/MarginContainer/VBoxContainer/HBoxContainer/LineEdit
@onready var password_status: Label = $TabContainer/General/MarginContainer/VBoxContainer/PasswordStatus
@onready var reset_dialog: ConfirmationDialog = %ResetConfirmationDialog

signal options_menu_exited
#signal correct_secret_input #Not actually used by anything at the moment.

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

func unlock_mint() -> void:
	set_mint_unlock_vars()
	correct_sound.post(self)
	password_status.text = "MAID MINT, WISP, AKIBA, AND VINTAGE STAGE UNLOCKED!"

func set_mint_unlock_vars() -> void:
	globals.secrets.mint = true
	SettingsContainer.unlock_secret_permanently("mint")
	
func unlock_snuffy() -> void:
	set_snuffy_unlock_vars()
	correct_sound.post(self)
	password_status.text = "SNUFFY UNLOCKED"
	
func set_snuffy_unlock_vars() -> void:
	globals.secrets.snuffy = true
	SettingsContainer.unlock_secret_permanently("snuffy")
	
func unlock_laimu() -> void:
	set_laimu_unlock_vars()
	correct_sound.post(self)
	password_status.text = "LAIMU UNLOCKED"
	
func set_laimu_unlock_vars() -> void:
	globals.secrets.laimu = true
	SettingsContainer.unlock_secret_permanently("laimu")
	
func unlock_dooby() -> void:
	set_dooby_unlock_vars()
	correct_sound.post(self)
	password_status.text = "DOOBY UNLOCKED"
	
func set_dooby_unlock_vars() -> void:
	globals.secrets.dooby = true
	SettingsContainer.unlock_secret_permanently("dooby")
	
func unlock_nimi() -> void:
	set_nimi_unlock_vars()
	correct_sound.post(self)
	password_status.text = "NIMI UNLOCKED"

func set_nimi_unlock_vars() -> void:
	globals.secrets.nimi = true
	SettingsContainer.unlock_secret_permanently("nimi")

func unlock_all() -> void:
	set_mint_unlock_vars()
	set_snuffy_unlock_vars()
	set_laimu_unlock_vars()
	set_dooby_unlock_vars()
	set_nimi_unlock_vars()
	correct_sound.post(self)
	password_status.text = "ALL SECRETS UNLOCKED"

func reject_password() -> void:
	error_sound.post(self)
	password_status.text = "NUH UH: WRONG PASSWORD"

func _on_password_submit_pressed() -> void:
	if line_edit.text.to_upper().contains("KEPT YOU WAITING") or line_edit.text.to_upper().contains("JINZOU FAIYA"):
		unlock_mint()
	elif line_edit.text.to_upper() == "GIMMIE THE GARBAGE":
		unlock_snuffy()
	elif line_edit.text.to_upper().contains("IONGRTEGRTIOY^T"):
		unlock_laimu()
	elif line_edit.text.to_upper() == "YELLOW WOMEN UNITE":
		unlock_dooby()
	elif line_edit.text.to_upper() == "LIBRARY OF LETOURNEAU":
		unlock_nimi()
	elif line_edit.text.contains("8008135") or line_edit.text.contains("80085"):
		unlock_all()
	else:
		reject_password()

func _on_reset_pressed():
	reset_dialog.popup_centered()

func _on_reset_confirmed():
	reset_dialog.hide()
	globals.secrets.mint = false
	globals.secrets.snuffy = false
	globals.secrets.laimu = false
	globals.secrets.dooby = false
	globals.secrets.nimi = false
	SettingsContainer.clean_all_unlock_flags()
	SaveManager.on_secret_delete()

func _on_reset_cancelled():
	reset_dialog.hide()


func _on_exit_pressed() -> void:
	options_menu_exited.emit()
