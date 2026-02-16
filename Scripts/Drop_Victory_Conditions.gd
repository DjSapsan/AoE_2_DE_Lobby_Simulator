extends Node

@onready var fieldConditions: Label = %F_Conditions

func _ready() -> void:
	pass # Replace with function body.



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
		4: #Score
			enableConditions(true)
		5: #LastMan
			enableConditions(false)

func enableConditions(e: bool = true):
	if e:
		fieldConditions.self_modulate = 0xffffffff
		fieldConditions.mouse_filter = 1
	else:
		fieldConditions.self_modulate = 0xffffff64
		fieldConditions.mouse_filter = 0
		
