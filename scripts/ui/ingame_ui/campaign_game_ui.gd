extends CanvasLayer

@onready var match_timer: Timer = %MatchTimer
@onready var player_health_panel_container: Container = %PlayerHealthPanelContainer
@onready var boss_health_panel_container: Container = %BossHealthPanelContainer
@onready var time_label: Label = %TimeLabel
@onready var score_label: Label = %ScoreLabel

const COLOR_ARR: Array[Color] = [Color8(255, 100, 100), Color8(100, 255, 255), Color8(255, 178, 100), Color8(163, 255, 156)]

var player_health_panel: Array[HealthPanel]
var used_player_health_panel_len: int = 0
var boss_health_panel: Array[HealthPanel]
var used_boss_health_panel_len: int = 0

func _ready() -> void:
	globals.game.game_ui = self
	for child in player_health_panel_container.get_children():
		if child is HealthPanel:
			player_health_panel.append(child)
	for child in boss_health_panel_container.get_children():
		if child is HealthPanel:
			boss_health_panel.append(child)


@rpc("call_local")
func add_player(player_id: int, player_dict : Dictionary):
	assert(used_player_health_panel_len <= 3, "attempted to add a 5th player but only 4 are supported")
	player_health_panel[used_player_health_panel_len].player_id = player_id
	player_health_panel[used_player_health_panel_len].show()
	player_health_panel[used_player_health_panel_len].update_icon(player_dict.spritepaths)
	player_health_panel[used_player_health_panel_len].update_icon_color(COLOR_ARR[used_player_health_panel_len])
	used_player_health_panel_len += 1

func add_boss(health: int, health_signal: Signal, sprite_paths: Dictionary, color: Color) -> int:
	assert(used_boss_health_panel_len <= 3, "attempted to add a 5th boss but only 4 are supported")
	boss_health_panel[used_boss_health_panel_len].show()
	boss_health_panel[used_boss_health_panel_len].update_health(health)
	health_signal.connect(boss_health_panel[used_boss_health_panel_len].update_health)
	boss_health_panel[used_boss_health_panel_len].update_icon(sprite_paths)
	boss_health_panel[used_boss_health_panel_len].update_icon_color(color)
	used_boss_health_panel_len += 1
	return used_boss_health_panel_len - 1

func delete_boss(health_signal: Signal, ui_idx: int):
	if used_boss_health_panel_len <= ui_idx: return
	boss_health_panel[ui_idx].hide()
	health_signal.disconnect(boss_health_panel[ui_idx].update_health)
	used_boss_health_panel_len -= 1


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

func reset():
	pass
