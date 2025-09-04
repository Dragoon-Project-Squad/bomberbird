extends Control

signal mode_select_back
signal enter_short_campaign_mode
signal enter_campaign_mode
signal enter_boss_rush_mode

@onready var description_panel: Panel = %DescriptionPanel
@onready var title_label: Label = %Title
@onready var short_campaign_label: Label = %ShortCampaignDescription
@onready var campaign_label: Label = %CampaignDescription
@onready var boss_rush_label: Label = %BossRushDescription

func _exit():
	description_panel.hide()
	campaign_label.hide()
	boss_rush_label.hide()
	title_label.set_text("CAMPAIGN")


func _on_back_pressed():
	mode_select_back.emit()

func _on_short_campaign_pressed():
	globals.current_gamemode = globals.gamemode.CAMPAIGN
	enter_short_campaign_mode.emit()

func _on_campaign_pressed():
	globals.current_gamemode = globals.gamemode.CAMPAIGN
	enter_campaign_mode.emit()

func _on_campaign_hover():
	description_panel.show()
	campaign_label.show()
	boss_rush_label.hide()
	title_label.set_text("CAMPAIGN")

func _on_boss_rush_pressed():
	globals.current_gamemode = globals.gamemode.BOSSRUSH
	create_temp_save_file()
	enter_boss_rush_mode.emit()

func _on_boss_rush_hover():
	description_panel.show()
	campaign_label.hide()
	boss_rush_label.show()
	title_label.set_text("BOSS RUSH")


func create_temp_save_file():
	gamestate.current_save_file = "temp_boss_rush"
	gamestate.current_save = campaign_save_manager.get_new_save()
