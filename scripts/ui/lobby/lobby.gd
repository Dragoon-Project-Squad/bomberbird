extends Control

@export var curr_misobon_state = SettingsContainer.misobon_setting
@onready var lobby_music_player: AudioStreamPlayer = $AudioStreamPlayer
var timeout_timer = null

func _ready():
	# Called every time the node is added to the scene.
	gamestate.connection_failed.connect(_on_connection_failed)
	gamestate.connection_succeeded.connect(_on_connection_success)
	gamestate.player_list_changed.connect(refresh_lobby)
	gamestate.game_ended.connect(_on_game_ended)
	gamestate.game_error.connect(_on_game_error)
	# Set the player name according to the system username. Fallback to the path.
	$Connect/Name.text = globals.config.get_player_name()

	# Connection timeout timer
	timeout_timer = Timer.new()
	timeout_timer.name = "ConnectionTimeout"
	timeout_timer.wait_time = 5.0
	timeout_timer.one_shot = true
	timeout_timer.connect("timeout", Callable(self, "_on_connection_timeout"))
	add_child(timeout_timer)
	

func refresh_lobby():
	var players = gamestate.get_player_list()
	players.sort()
	$Players/List.clear()
	$Players/List.add_item(gamestate.get_player_name() + " (You)")
	for p in players:
		$Players/List.add_item(p)

	$Players/Ready.disabled = not multiplayer.is_server()

@rpc("call_local")
func show_css():
	$Players.hide()
	$Connect.hide()
	$Back.hide()
	$CharacterSelectScreen.show()
	$Start.show()

func _on_host_pressed():
	if $Connect/Name.text == "":
		$Connect/ErrorLabel.text = "Invalid name!"
		return

	$Connect.hide()
	$Players.show()
	$Connect/ErrorLabel.text = ""
	
	var player_name = $Connect/Name.text
	globals.config.set_player_name(player_name)
	gamestate.host_game(player_name)
	refresh_lobby()

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
	$Connect.hide()
	$Players.show()


func _on_connection_failed():
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false
	$Connect/ErrorLabel.set_text("Connection failed.")


func _on_game_ended():
	show()
	$Connect.show()
	$Players.hide()
	$Back.show()
	$CharacterSelectScreen.hide()
	$Start.hide()
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false


func _on_game_error(errtxt):
	$ErrorDialog.dialog_text = errtxt
	$ErrorDialog.popup_centered()
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false

func _on_start_pressed():
	if gamestate.total_player_count < 2:
		push_warning("Less than two players!")
	elif gamestate.total_player_count > 4:
		push_error("More than four players!")
	lobby_music_player.stop()
	gamestate.begin_game()


func _on_find_public_ip_pressed():
	OS.shell_open("https://icanhazip.com/")
	
func _on_back_pressed() -> void:
	if gamestate.peer:
		gamestate.peer.close()
		await get_tree().process_frame
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_ready_pressed() -> void:
	gamestate.establish_player_counts()
	gamestate.assign_player_numbers()
	# Tell CSS with a signal of some kind to capture gamestate player nums
	$CharacterSelectScreen.disable_unused_player_slots()
	show_css.rpc()
