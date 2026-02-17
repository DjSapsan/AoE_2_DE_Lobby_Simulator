extends Node

@onready var fieldConditions: OptionButton = %F_Conditions

func _ready() -> void:
	pass # Replace with function body.

func populateItems(source: Array[String]):
	fieldConditions.clear()
	for option in source:
		fieldConditions.add_item(option)

func _on_item_selected(index: int) -> void:
	match index:
		0: # -
			enableConditions(false)
		1: #Standard
			enableConditions(false)
		2: #Conquest
			enableConditions(false)
		3: #Time
			enableConditions(true)
			populateItems(Tables.LobbyOptions_TimeLimit_Conditions)
		4: #Score
			enableConditions(true)
			populateItems(Tables.LobbyOptions_Score_Conditions)
		5: #LastMan
			enableConditions(false)

func enableConditions(e: bool = true):
	if e:
		fieldConditions.self_modulate = 0xffffffff
		fieldConditions.mouse_filter = Control.MOUSE_FILTER_PASS
	else:
		fieldConditions.self_modulate = 0xffffff64
		fieldConditions.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fieldConditions.clear()
