extends Game

func start():
	stage = get_child(0) #This is assuming the first child is the stage which is kind of a bad assumtion
	stage.enable()

## checks if there is only 1 alive player if so makes that player win, if there is no player is draws the game and for any other state this function does nothing
func _check_ending_condition(_alive_enemies: int = 0):
	if win_screen.visible: return
	var alive_players: Array[Player] = globals.player_manager.get_alive_players()
	if len(alive_players) == 0:
		win_screen.draw_game()
	if len(alive_players) == 1:
		win_screen.declare_winner(alive_players[0])
