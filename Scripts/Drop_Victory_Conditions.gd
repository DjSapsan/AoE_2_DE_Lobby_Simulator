extends Node

@onready var f_check_conditions: OptionButton = %F_CheckConditions

func _ready() -> void:
	pass # Replace with function body.

func populateItems(source: Array[String]):
	f_check_conditions.clear()
	for option in source:
		f_check_conditions.add_item(option)

func _on_item_selected(index: int) -> void:
	if (index == 3):
		enableConditions(true)
		populateItems(Tables.LobbyOptions_TimeLimit_Conditions)
	elif (index == 4):
		enableConditions(true)
		populateItems(Tables.LobbyOptions_Score_Conditions)
	else:
		enableConditions(false)

func enableConditions(e: bool = true):
	if e:
		f_check_conditions.self_modulate = 0xffffffff
		f_check_conditions.mouse_filter = Control.MOUSE_FILTER_PASS
	else:
		f_check_conditions.self_modulate = 0xffffff64
		f_check_conditions.mouse_filter = Control.MOUSE_FILTER_IGNORE
		f_check_conditions.clear()
