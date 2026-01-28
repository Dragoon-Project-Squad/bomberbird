extends CanvasLayer

const SCORE_TEXT: String = "Score: %06d"

@onready var winner_declaring_label: Label = %Winner
@onready var score_label: Label = %Score
var won: bool = false

func _ready() -> void:
	globals.game.win_screen = self

## function for declaring a SP game lost
func lost_game(score: int):
	init_screen(score)
	won = false
	winner_declaring_label.set_text("You Died")

## function for declaring a SP game won
func won_game(score: int):
	init_screen(score)
	won = true
	winner_declaring_label.set_text("Victory!")

func init_screen(score: int):
	get_tree().paused = true
	score_label.set_text(SCORE_TEXT % [score])
	show()

func _on_exit_game_pressed():
	get_tree().paused = false
	gamestate.end_sp_game()

func _on_restart_pressed() -> void:
	get_tree().paused = false
	hide()
	if globals.is_campaign_mode():
		if won:
			globals.game.restart(true)
		else:
			globals.game.restart_current_stage(null, true)
	elif globals.is_boss_rush_mode():
		gamestate.boss_rush_back_to_lobby()
