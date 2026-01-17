extends ConnectionScreen

func _ready():
	super()
	$Name.text = globals.config.get_player_name()

func _on_host_pressed():
	super()

func _on_join_pressed():
	super()
