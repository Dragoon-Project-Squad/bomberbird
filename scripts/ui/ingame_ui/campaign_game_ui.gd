extends CanvasLayer

@onready var match_timer: Timer = %MatchTimer
@onready var health_panel_container: Container = %HealthPanelContainer
@onready var time_label: Label = %TimeLabel
@onready var score_label: Label = %ScoreLabel

const COLOR_ARR: Array[Color] = [Color8(255, 100, 100), Color8(100, 255, 255), Color8(255, 178, 100), Color8(163, 255, 156)]

var player_health_panel: Array[HealthPanel]
var used_player_health_panel_len: int = 0

func _ready() -> void:
	globals.game.game_ui = self
	for child in health_panel_container.get_children():
		if child is HealthPanel:
			player_health_panel.append(child)

@rpc("call_local")
func add_player(player_id: int, player_dict : Dictionary):
	assert(used_player_health_panel_len <= 3, "attempted to add a 5th player but only 4 are supported")
	player_health_panel[used_player_health_panel_len].player_id = player_id
	player_health_panel[used_player_health_panel_len].show()
	player_health_panel[used_player_health_panel_len].update_icon(player_dict.spritepaths)
	player_health_panel[used_player_health_panel_len].update_icon_color(COLOR_ARR[used_player_health_panel_len])
	used_player_health_panel_len += 1


func start_timer(gametime := 180):
	match_timer.start(gametime)
	
func stop_timer():
	match_timer.stop()

func pause_timer(val: bool):
	match_timer.paused = val

func _process(_delta: float) -> void:
	var time = match_timer.get_time_left()
	var seconds = fmod(time, 60)
	var minutes = time / 60
	var format_string = "%02d:%02d"
	var actual_time_string = format_string % [minutes, seconds]
	time_label.set_text(actual_time_string)

func update_score(score: int):
	var format_string = "%06d"
	score_label.set_text(format_string % [score])

func update_health(health: int, player_id: int):
	for health_panel in player_health_panel:
		if health_panel.player_id == player_id:
			health_panel.update_health(health)

func update_icon(player_id: int, player_dict : Dictionary):
	for health_panel in player_health_panel:
		if health_panel.player_id == player_id:
			health_panel.update_icon(player_dict.spritepaths)

func update_icon_color(color: Color, player_id: int):
	for health_panel in player_health_panel:
		if health_panel.player_id == player_id:
			health_panel.update_icon_color(color)
