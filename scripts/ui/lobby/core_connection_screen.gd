extends PanelContainer
class_name ConnectionScreen

var timeout_timer = null
@onready var error_label: Label = $VBoxContainer/ErrorContainer/ErrorLabel
@onready var host_button: SeButton = $VBoxContainer/HostContainer/HBoxContainer/Host
@onready var join_button: SeButton = $VBoxContainer/JoinContainer/Join

signal multiplayer_game_hosted #Is used in children, from the Lobby.
signal multiplayer_game_joined

func _ready():
	# Called every time the node is added to the scene.
	gamestate.connection_failed.connect(_on_connection_failed)
	gamestate.connection_succeeded.connect(_on_connection_success)

	# Connection timeout timer
	timeout_timer = Timer.new()
	timeout_timer.name = "ConnectionTimeout"
	timeout_timer.wait_time = 5.0
	timeout_timer.one_shot = true
	timeout_timer.connect("timeout", Callable(self, "_on_connection_timeout"))
	add_child(timeout_timer)

func _on_connection_timeout():
	if gamestate.peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		multiplayer.multiplayer_peer = null  # Reset the multiplayer peer
		host_button.disabled = false
		join_button.disabled = false
		join_button.release_focus()
		error_label.text = "Connection timed out"

func _on_connection_success():
	multiplayer_game_joined.emit()

func _on_connection_failed():
	host_button.disabled = false
	join_button.disabled = false
	error_label.set_text("Connection failed.")
