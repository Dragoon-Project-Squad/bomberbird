extends Control

@export var bg_color : Color = Color.TRANSPARENT
@export var title_color := Color.YELLOW
@export var text_color := Color.WHITE
@export var title_font : FontFile = null
@export var text_font : FontFile = null

signal credits_ended

const section_time := 2.0
const line_time := 0.3
var base_speed := 0
const speed_up_multiplier := 10.0

var scroll_speed : float = base_speed
var speed_up := false
var in_credits := false

@onready var colorrect := $ColorRect
@onready var line := $CreditsContainer/ProcessingLine
@onready var credits_container: Control = $CreditsContainer

var started := false
var finished := false

var section
var section_next := true
var section_timer := 0.0
var line_timer := 0.0
var curr_line := 0
var lines := []

var defaultcredits = [ #DO NOT REMOVE, This is here to allow smooth reloads.
	[
		"Bomberbird by Dragoon Project Squad"
	],[
		"Game Director",
		"Medi"
	],[
		"Programming Lead",
		"[Patcheresu] Anton Namtet"
	],[
		"Programming",
		"Rhekar",
		"Minokawa",
		"SchWiniX",
		"SpookyTim",
		"PR55",
		"Mylaskul",
		"itsaperson",
		"Metallix(Lunaryla)",
		"Lithusei"
	],[
		"Art",
		"Onor"
	],[
		"Music"
	],[
		"Menu Music",
		"'Doki Doki Comes Home' by nownoir",
		"'Dragoon Cafe' by nownoir"
	],[
		"Battle Music",
		"'BountyHunter Jam' by Peachii",
		"'Rush (Game Mix)' by Aefen",
		"'D.A.D Drive' by Peachii",
		"'Theme of Minki' by Peachii",
	],[
		"Sound Designer (SFX, Technical)",
		"MonstoBusta"
	],[
		"Testers",
		"Fa1co",
		"JohnVitutus",
		"Kitamerby",
		"Xekra",
		"BigF",
		"Kyle873",
		"JohnnyLacone",
	],[
		"Developed with Godot Engine",
		"https://godotengine.org/license",
	],[
		"Fonts",
		"Thaleah Fat by Rick Hoppmann",
	],[
		"Special Thanks",
		"Dragoon Project Squad",
		"Super B*mberman R's Netcode"
	],[
		"And of course",
		"Dokibird"
	]
]

var credits = [
	[
		"Bomberbird by Dragoon Project Squad"
	],[
		"Game Director",
		"Medi"
	],[
		"Programming Lead",
		"Patcheresu"
	],[
		"Programming",
		"Rhekar",
		"Minokawa",
		"SchWiniX",
		"SpookyTim",
		"PR55",
		"Mylaskul",
		"itsaperson",
		"Metallix(Lunaryla)",
		"Lithusei"
	],[
		"Art",
		"Onor"
	],[
		"Music"
	],[
		"Menu Music",
		"'Doki Doki Comes Home' by nownoir",
		"'Dragoon Cafe' by nownoir"
	],[
		"Battle Music",
		"'BountyHunter Jam' by Peachii",
		"'Rush (Game Mix)' by Aefen",
		"'D.A.D Drive' by Peachii",
		"'Theme of Minki' by Peachii",
	],[
		"Sound Designer (SFX, Technical)",
		"MonstoBusta"
	],[
		"Testers",
		"Fa1co",
		"JohnVitutus",
		"Kitamerby",
		"Xekra",
		"BigF",
		"Kyle873",
		"JohnnyLacone",
	],[
		"Fonts",
		"Thaleah Fat by Rick Hoppmann",
	],[
		"Developed with Godot Engine",
		"https://godotengine.org/license",
	],[
		"Powered by Wwise Copyright 2006 – 2026 Audiokinetic Inc. All rights reserved.",
	],[
		"Special Thanks",
		"Dragoon Project Squad"
	],[
		"And of course",
		"Dokibird"
	]
]

func _on_credits_button_pressed() -> void:
	colorrect.color = bg_color
	in_credits = true
	base_speed = 70
	

func _process(delta):
	if !in_credits: return
	scroll_speed = base_speed * delta
	
	if section_next:
		section_timer += delta * speed_up_multiplier if speed_up else delta
		if section_timer >= section_time:
			section_timer -= section_time
			
			if credits.size() > 0:
				started = true
				section = credits.pop_front()
				curr_line = 0
				add_line()
	
	else:
		line_timer += delta * speed_up_multiplier if speed_up else delta
		if line_timer >= line_time:
			line_timer -= line_time
			add_line()
	
	if speed_up:
		scroll_speed *= speed_up_multiplier
	
	if lines.size() > 0:
		for l in lines:
			l.set_global_position(l.get_global_position() - Vector2(0, scroll_speed))
			if l.get_global_position().y < l.get_line_height():
				lines.erase(l)
				l.queue_free()
	elif started:
		finish()


func finish():
	self.visible = false
	if in_credits == true:
		in_credits = false
		finished = true
	reset()
	credits_ended.emit()
	
func reset():
	section = ""
	section_next = true
	section_timer = 0.0
	line_timer = 0.0
	curr_line = 0
	base_speed = 0
	lines = []
	started = false
	finished = false
	credits = defaultcredits.duplicate()
	for childlabel in credits_container.get_children():
		if childlabel.name != "ProcessingLine":
			credits_container.remove_child(childlabel)
			childlabel.queue_free()
	
func add_line():
	var new_line = line.duplicate()
	new_line.text = section.pop_front()
	lines.append(new_line)
	if curr_line == 0:
		if title_font != null:
			new_line.set("theme_override_fonts/font", title_font)
		new_line.set("theme_override_colors/font_color", title_color)
	
	else:
		if text_font != null:
			new_line.set("theme_override_fonts/font", text_font)
		new_line.set("theme_override_colors/font_color", text_color)
	
	$CreditsContainer.add_child(new_line)
	
	if section.size() > 0:
		curr_line += 1
		section_next = false
	else:
		section_next = true


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		finish()
	if event.is_action_pressed("ui_down") and !event.is_echo():
		speed_up = true
	if event.is_action_released("ui_down") and !event.is_echo():
		speed_up = false
