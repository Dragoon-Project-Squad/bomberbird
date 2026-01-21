extends ConnectionScreen

@onready var name_entry: LineEdit = $VBoxContainer/HostContainer/HBoxContainer/Name
@onready var ip_addr_entry: LineEdit = $VBoxContainer/JoinContainer/IPAddress

func _ready():
	super()
	name_entry.set_text(SettingsContainer.get_user_preferred_name())
	
func _on_host_pressed():
	if name_entry.get_text() == "":
		error_label.set_text("Invalid name!")
		return

	error_label.set_text("")
	
	var player_name = name_entry.get_text()
	SettingsSignalBus.emit_on_user_preferred_name_changed(player_name)
	gamestate.player_data_master_dict[1].playername = player_name
	gamestate.host_vanilla_game(SettingsContainer.get_user_preferred_name())
	multiplayer_game_hosted.emit()

func _on_join_pressed():
	if name_entry.get_text() == "":
		error_label.set_text("Invalid name!")
		return

	var ip = ip_addr_entry.get_text()
	if not ip.is_valid_ip_address():
		#error_label.set_text("Invalid IP address!")
		#return
		ip = "127.0.0.1"
	error_label.set_text("")
	host_button.disabled = true
	join_button.disabled = true

	var player_name = name_entry.get_text()
	SettingsSignalBus.emit_on_user_preferred_name_changed(player_name)
	timeout_timer.start()
	gamestate.join_vanilla_game_as_peer(ip, player_name)
