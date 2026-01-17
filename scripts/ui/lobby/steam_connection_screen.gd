extends ConnectionScreen

var lobby_type_dropdown : OptionButton

func _ready():
	super()

func _on_host_pressed():
	super()

func _on_join_pressed():
	Steam.activateGameOverlay("Friends")
