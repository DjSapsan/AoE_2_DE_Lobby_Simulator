extends Button

@onready var panel = %PopupPanel

func _on_pressed():
	panel.visible = true
	disabled = true


func _on_popup_panel_popup_hide():
	disabled = false
