extends Control

signal configFileDetected

@onready var BalanceDisplay = %BalanceDisplay
@onready var updateButton = $MainContainer/Sections/TopElements/UpdateButton

var cmd:String
#aoe2de://0/307853820

func _ready():
	var config = ConfigFile.new()
	var err = config.load(Global.SETTINGS_FILE_PATH)
	if err != OK:
		pass
		#print("Config could not be saved" +str(err))
	else:
		configFileDetected.emit()
		%LoadNameButton._on_pressed()

	checkUpdates()

func _on_config_file_detected():
	%LoadNameButton.disabled = false

func removeTeamDisplay():
	for node in BalanceDisplay.get_children():
		node.queue_free()

func openAge(lobby):

	if not lobby:
		return

	#var joinOrSpec = Global.ACTIVE_BROWSER_ID

	if Global.OStype == "Windows":
		cmd = lobby.getRegularURL()
		#print("Attempting to open ",cmd)
		OS.shell_open(cmd)
	elif Global.OStype == "Linux/BSD":
		cmd = "xdg-open " + lobby.getSteamURL()
		#print("Attempting to open ",cmd)
		OS.execute("sh", ["-c", cmd], [], false)

func checkUpdates():
	var numRegex = RegEx.new()
	numRegex.compile("[0-9]*\\.[0-9]+")

	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request(Global.URL_API_Updates)
	var rawResults = await http_request.request_completed
	if rawResults[1] != 200:
		return
	var jsonResults = JSON.parse_string(rawResults[3].get_string_from_utf8())

	var remoteVersion = numRegex.search(jsonResults.tag_name).get_string().to_float()
	if float(remoteVersion) > Global.VERSION:
		updateButton.visible = true


func _on_update_button_pressed():
	updateButton.visible = false
	OS.shell_open(Global.URL_UPDATE)
	pass # Replace with function body.
