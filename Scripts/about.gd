extends Control



func _on_rich_text_label_meta_clicked(meta):
	OS.shell_open(meta)
	
func _ready():
	var node = $Panel/MarginContainer/VBoxContainer/version
	node.text = node.text % Global.VERSION
