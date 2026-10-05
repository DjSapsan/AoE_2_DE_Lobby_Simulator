extends Label

func changeStatus(txt:String, code:int=0):
	var color = Color.WHITE
	var symbol = "🛈 "
	match code:
		1:
			color = Color.RED
			symbol = "❌ "
	add_theme_color_override("font_color", color)
	text = symbol + txt

func showAmountOfLobbies():
	changeStatus(str(Storage.LOBBIES.size()) + " lobbies loaded")

func showAmountOfSpecs():
	changeStatus(str(Storage.SPECS.size()) + " ongoing matches loaded")
