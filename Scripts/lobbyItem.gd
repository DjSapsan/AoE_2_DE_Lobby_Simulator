extends PanelContainer

static var lobbyTabPath = "/root/Control/MainContainer/Sections/TabsNode/Lobby"

var associatedLobby: LobbyClass

func _ready() -> void:
	add_to_group("lobbyItems")

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if event.alt_pressed:
			var cmd: String = ""
			#var joinOrSpec = Global.ACTIVE_BROWSER_ID
			if Global.OStype == "Windows":
				cmd = associatedLobby.getRegularURL()
				#print("Attempting to open ",cmd)
				OS.shell_open(cmd)
			elif Global.OStype == "Linux/BSD":
				cmd = "xdg-open " + associatedLobby.getSteamURL()
				#print("Attempting to open ",cmd)
				OS.execute("sh", ["-c", cmd], [], false)
		else:
			var node = get_node(lobbyTabPath)
			node.openSelectedLobby(associatedLobby)

func refreshUI():
	var lobby = associatedLobby as LobbyClass
	var fields:Array = get_children()[0].get_children()
	fields[0].text = lobby.title
	fields[1].text = "%d/%d" % [lobby.totalPlayers, lobby.maxPlayers]
	fields[2].text = lobby.map
	fields[3].text = lobby.gameModeName
	fields[4].text = "X" if lobby.password else ""


func _mouse_entered() -> void:
	self_modulate = 0x000020a0

func _mouse_exited() -> void:
	self_modulate = 0xffffffff


func _on_tree_exiting() -> void:
	if associatedLobby and associatedLobby.associatedNode == self:
		associatedLobby.associatedNode = null
