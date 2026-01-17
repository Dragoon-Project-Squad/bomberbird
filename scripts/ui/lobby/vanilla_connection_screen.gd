extends ConnectionScreen

@onready var name_entry: LineEdit = $VBoxContainer/HostContainer/Name

func _ready():
	super()
	name_entry.set_text(SettingsContainer.get_user_preferred_name())
	
func _on_host_pressed():
	if name_entry.get_text() == "":
		$ErrorLabel.set_text("Invalid name!")
		return

	$ErrorLabel.set_text("")
	
	var player_name = name_entry.get_text()
	SettingsSignalBus.emit_on_user_preferred_name_changed(player_name)
	gamestate.player_data_master_dict[1].playername = player_name
	gamestate.host_vanilla_game(SettingsContainer.get_user_preferred_name())
	multiplayer_game_hosted.emit()

func _on_join_pressed():
	if name_entry.get_text() == "":
		$ErrorLabel.set_text("Invalid name!")
		return

	var ip = $IPAddress.text
	if not ip.is_valid_ip_address():
		$ErrorLabel.set_text("Invalid IP address!")
		return

	$ErrorLabel.set_text("")
	$Host.disabled = true
	$Join.disabled = true

	var player_name = $Name.text
	SettingsSignalBus.emit_on_user_preferred_name_changed(player_name)
	timeout_timer.start()
	gamestate.join_game(ip, player_name)
