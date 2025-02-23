extends State
class_name AISafe

var bomb_snapshot : Array[Bomb]

func _enter():
	idle = true
	# When safe state achieved, snapshot the bombs at that moment
	bomb_snapshot = aiplayer.bombs_near

func _update(delta):
	_idle_and_detect(delta)

func _idle_and_detect(delta):
	if idle:
		# Wait in idle for a set time after moving
		if(idle_time>0):
			idle_time -= delta
		else:
			idle = false
			idle_time = default_idle_time
			currently_moving = false
			# Once idle time finished, evaluate the situation and change state
			# depending on the things detected
			_detect_surroundings()

func _exit():
	super()
	bomb_snapshot = []

func _detect_surroundings():
	# If no more bombs near, it's safe to wander again
	if aiplayer.bombs_near == bomb_snapshot:
		idle = true
	if aiplayer.bombs_near.size() == 0:
		state_changed.emit(self, "Wander")
	# If more bombs added to the list of bombs near, dodge again
	if bombs_added():
		state_changed.emit(self, "Dodge")

func bombs_added() -> bool:
	for bomb in aiplayer.bombs_near:
		if bomb not in bomb_snapshot:
			return true
	return false
