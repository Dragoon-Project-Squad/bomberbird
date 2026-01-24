extends Control

@onready var presents = $TeamPresents
@onready var a_fangame = $AFangame

@onready var sky = %Sky
@onready var sun = %Sun
@onready var land = %Land
@onready var doki = %Doki

func start_splash() -> void:
	get_node("/root/MainMenu/").hide_main_menu()

func anim_splash() -> void:
	$Beat1Timer.start()
	$Beat2Timer.start()
	$Beat3Timer.start()
	$Beat4Timer.start()
	$EntryTimer.start()
	var tween = create_tween()
	tween.tween_property(presents, "modulate", Color(1,1,1,1), 0.741)
	tween.parallel().tween_method(a_fangame.set_position, Vector2(0, 300), Vector2(0,-60), 2.963)

func end_splash() -> void:
	get_node("/root/MainMenu").reveal_main_menu()
	queue_free()

func _process(_delta: float) -> void:
	if Input.is_anything_pressed():
		end_splash()

func _on_entry_timer_timeout() -> void:
	var tween = create_tween()
	tween.tween_method(sun.set_position, Vector2(0, 200), Vector2(0, 0), 3.333)


func _on_beat_1_timer_timeout() -> void:
	var tween = create_tween()
	tween.tween_property(presents, "modulate", Color(1,1,1,0), 0.05)


func _on_beat_2_timer_timeout() -> void:
	var tween = create_tween()
	tween.tween_property(a_fangame, "modulate", Color(1,1,1,0), 0.05)


func _on_beat_3_timer_timeout() -> void:
	var tween = create_tween()
	tween.tween_property(land, "modulate",Color(1,1,1,1), 0.05)


func _on_beat_4_timer_timeout() -> void:
	var tween = create_tween()
	tween.tween_property(doki, "modulate", Color(1,1,1,1), 0.05)
