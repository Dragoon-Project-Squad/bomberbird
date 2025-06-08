class_name HealthPanel extends IconPanel

@onready var health_label: Label = %HealthLabel

func update_health(health: int):
	var format_string = "%01d"
	health_label.set_text(format_string % [health])
