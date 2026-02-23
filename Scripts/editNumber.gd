extends LineEdit

var regex = RegEx.new()
var oldtext = ""

func _ready():
	regex.compile("^[0-9]*$")

func _on_text_changed(new_text):
	if regex.search(new_text):
		text = new_text   
		oldtext = text
	else:
		text = oldtext
	set_caret_column(text.length())

func get_value():
	return(int(text))
