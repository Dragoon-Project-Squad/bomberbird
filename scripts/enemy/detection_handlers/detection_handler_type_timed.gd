extends Timer
# implements the detection of the player for Priority target 'A' described in https://gamefaqs.gamespot.com/snes/562899-super-bomberman-5/faqs/79457

@onready var enemy: Enemy = get_parent()
var has_timeout: bool = false

func _ready() -> void:
	self.timeout.connect(func (): has_timeout = true)
	self.one_shot = true
	self.autostart = false

func check_for_priority_target():
	enemy.statemachine.target = null
	if has_timeout:
		has_timeout = false
		self.start()
		return true
	return false


func on():
	has_timeout = false
	self.start()

func off():
	has_timeout = false
	self.stop()
