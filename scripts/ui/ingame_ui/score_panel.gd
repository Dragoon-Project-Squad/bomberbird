class_name ScorePanel extends IconPanel

@onready var score_label: Label = %ScoreLabel
var score = 0

func increment_score():
	score = score + 1
	var format_string = "%01d"
	score_label.set_text(format_string % [score])
	
func decrement_score():
	score = score - 1
	var format_string = "%01d"
	score_label.set_text(format_string % [score])

func set_score(newscore: int):
	score = newscore
	var format_string = "%01d"
	score_label.set_text(format_string % [score])
