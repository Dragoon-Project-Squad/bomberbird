extends Control
@onready var winner_declaring_label: Label = $Winner

func _on_game_ui_game_decided(winningplayer: Variant) -> void:
	if winningplayer == null:
		draw_game()
	else:
		declare_winner(winningplayer)
		
func draw_game():
		winner_declaring_label.set_text("DRAW GAME")
		self.show()

func declare_winner(winningplayer: Variant):
		winner_declaring_label.set_text("THE WINNER IS:\n" + winningplayer.get_player_name())
		self.show()

func _on_exit_game_pressed() -> void:
	gamestate.end_game()
