extends Control

@export var curr_misobon_state = gamestate.misobon_states.SUPER

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

	# sets the misobon button text to the correct state
	var button_label = ["off", "on", "super"]
	get_node("Options/MisobonState").set_text(button_label[curr_misobon_state])

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

	$Connect.hide()
	$Players.show()
	$Options.show()
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

func _on_misobon_pressed():
	#toggels through the 3 options for misobon and changing the text on the button to reflect the state
	var button = get_node("Options/MisobonState")
	var button_label = ["off", "on", "super"]
	curr_misobon_state = (curr_misobon_state + 1) % 3 as gamestate.misobon_states
	gamestate.misobon_mode = curr_misobon_state
	button.set_text(button_label[curr_misobon_state])

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
	$Options.show()
	$CSS.hide()
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false


func _on_game_error(errtxt):
	$ErrorDialog.dialog_text = errtxt
	$ErrorDialog.popup_centered()
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false


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
	$Options.hide()
	$Players.hide()
	$Connect.hide()
	$Back.hide()
	$CSS.show()

func _on_start_pressed():
	if gamestate.total_player_count < 2:
		push_warning("Less than two players!")
	elif gamestate.total_player_count > 4:
		push_warning("More than four players!")
	gamestate.begin_game()


func _on_find_public_ip_pressed():
	OS.shell_open("https://icanhazip.com/")
	
func _on_back_pressed() -> void:
	if gamestate.peer:
		gamestate.peer.close()
		await get_tree().process_frame
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_ready_pressed() -> void:
	show_css.rpc()


func _on_dokibird_pressed() -> void:
	$CSS/CSSPlayers/P1/Image.texture = load("res://assets/css/dokibh.png")
	gamestate.change_character_player(load("res://assets/css/dokibh.png"))

func _on_dragoon_pressed() -> void:
	$CSS/CSSPlayers/P1/Image.texture = load("res://assets/css/normalgoon.png")
	gamestate.change_character_player(load("res://assets/player/dragoon_walk.png"))

func _on_chonkgoon_pressed() -> void:
	$CSS/CSSPlayers/P1/Image.texture = load("res://assets/css/chonkgoon.png")
	gamestate.change_character_player(load("res://assets/player/chonkgoon_walk.png"))

func _on_longoon_pressed() -> void:
	$CSS/CSSPlayers/P1/Image.texture = load("res://assets/css/longgoon.png")
	gamestate.change_character_player(load("res://assets/css/longgoon.png"))

func _on_eggoon_pressed() -> void:
	$CSS/CSSPlayers/P1/Image.texture = load("res://assets/css/eggoon.png")
	gamestate.change_character_player(load("res://assets/css/eggoon.png"))
	
func _on_tomato_pressed() -> void:
	$CSS/CSSPlayers/P1/Image.texture = load("res://assets/css/tomato.png")
	gamestate.change_character_player(load("res://assets/css/tomato.png"))
