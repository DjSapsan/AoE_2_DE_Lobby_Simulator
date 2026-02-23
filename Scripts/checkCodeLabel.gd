extends Label

func isCode():
	return text !="" and text !="sharing code"

func _on_mouse_entered():
	if isCode():
		modulate = 0xa6c9feff

func _on_mouse_exited():
	modulate = 0xffffffff
	
func _on_gui_input(event: InputEvent) -> void:
	if isCode()	and event is InputEventMouseButton:
			DisplayServer.clipboard_set(text)
