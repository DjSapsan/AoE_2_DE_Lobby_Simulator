extends Button

signal configFileDetected

func _save_data():
	var config = ConfigFile.new()
	config.set_value("MAIN","SEARCH_TEXT",%searchField.text)
	config.save(Global.SETTINGS_FILE_PATH)

	var err = config.load(Global.SETTINGS_FILE_PATH)
	if err != OK:
		pass
		#print("Config could not be saved" +str(err))
	else:
		configFileDetected.emit()
