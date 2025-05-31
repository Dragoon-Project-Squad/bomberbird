extends Control

@export var curr_misobon_state = SettingsContainer.misobon_setting
@onready var lobby_music_player: AudioStreamPlayer = $AudioStreamPlayer
var timeout_timer = null

func _ready():
	# Called every time the node is added to the scene.
	gamestate.connection_failed.connect(_on_connection_failed)
	gamestate.connection_succeeded.connect(_on_connection_success)
	# Set the player name according to the system username. Fallback to the path.
	$Connect/Name.text = globals.config.get_player_name()

	# Connection timeout timer
	timeout_timer = Timer.new()
	timeout_timer.name = "ConnectionTimeout"
	timeout_timer.wait_time = 5.0
	timeout_timer.one_shot = true
	timeout_timer.connect("timeout", Callable(self, "_on_connection_timeout"))
	add_child(timeout_timer)


func _on_host_pressed():
	if $Connect/Name.text == "":
		$Connect/ErrorLabel.text = "Invalid name!"
		return

	$Connect/ErrorLabel.text = ""
	
	var player_name = $Connect/Name.text
	globals.config.set_player_name(player_name)
	gamestate.host_game(globals.config.get_player_name())
	get_tree().change_scene_to_file("res://scenes/cssmenu/character_select_screen.tscn")

func _on_join_pressed():
	if $Connect/Name.text == "":
		$Connect/ErrorLabel.text = "Invalid name!"
		return

	var ip = $Connect/IPAddress.text
	if not ip.is_valid_ip_address():
		$Connect/ErrorLabel.text = "Invalid IP address!"
		return

	$Connect/ErrorLabel.text = ""
	$Connect/Host.disabled = true
	$Connect/Join.disabled = true

	var player_name = $Connect/Name.text
	globals.config.set_player_name(player_name)	
	timeout_timer.start()
	gamestate.join_game(ip, player_name)
	

func _on_connection_timeout():
	if gamestate.peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		multiplayer.multiplayer_peer = null  # Reset the multiplayer peer
		$Connect/Host.disabled = false
		$Connect/Join.disabled = false
		$Connect/Join.release_focus()
		$Connect/ErrorLabel.text = "Connection timed out"

func _on_connection_success():
	get_tree().change_scene_to_file("res://scenes/cssmenu/character_select_screen.tscn")


func _on_connection_failed():
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false
	$Connect/ErrorLabel.set_text("Connection failed.")


func _on_find_public_ip_pressed():
	OS.shell_open("https://icanhazip.com/")
