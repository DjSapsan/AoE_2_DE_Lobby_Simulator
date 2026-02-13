extends Button


func _on_pressed():
	var config = ConfigFile.new()
	var err = config.load(Global.SETTINGS_FILE_PATH)
	if err != OK:
		#print("opening config file failed " +str(err))
		return

	var txt = config.get_value("MAIN","SEARCH_TEXT")

	%SearchField.text = txt
