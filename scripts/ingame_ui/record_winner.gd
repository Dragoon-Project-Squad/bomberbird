extends Control
@onready var winner_declaring_label: Label = $Winner

func _ready() -> void:
	globals.game.win_screen = self

func draw_game():
	winner_declaring_label.set_text("DRAW GAME")
	self.show()
	grab_focus()

func declare_winner(winningplayer: Player):
	winner_declaring_label.set_text("THE WINNER IS:\n" + winningplayer.get_player_name())
	self.show()
	grab_focus()

## Temp function for declaring a SP game lost
func lost_game():
	winner_declaring_label.set_text("LOST")
	self.show()
	grab_focus()

## Temp function for declaring a SP game won
func won_game():
	winner_declaring_label.set_text("WON")
	self.show()
	grab_focus()


func _on_exit_game_pressed():
	gamestate.end_game()
