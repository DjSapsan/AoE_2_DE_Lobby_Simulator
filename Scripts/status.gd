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
	var amount = Global.ACTIVE_BROWSER.get_child_count()
	changeStatus(str(amount) + " lobbies loaded")

func showAmountOfSpecs():
	var amount = Global.ACTIVE_BROWSER.get_child_count()
	changeStatus(str(amount) + " ongoing matches loaded")
