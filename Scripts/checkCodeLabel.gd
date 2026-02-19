extends Label

func _on_gui_input(event: InputEvent) -> void:
	if \
	text !="" \
	and text !="sharing code"\
	and event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_RIGHT:
			DisplayServer.clipboard_set(text)
