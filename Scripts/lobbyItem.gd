extends PanelContainer

static var lobbyTabPath = "/root/Control/MainContainer/Sections/TabsNode/Lobby"

var associatedLobby: LobbyClass
var panelStylebox: StyleBoxFlat

func _ready() -> void:
	# Use a per-instance stylebox so hover highlight does not affect all rows.
	var stylebox := get_theme_stylebox("panel")
	panelStylebox = stylebox.duplicate() as StyleBoxFlat
	add_theme_stylebox_override("panel", panelStylebox)
	panelStylebox.draw_center = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if event.alt_pressed:
			var url: String = ""
			if Global.OStype == "Windows":
				url = associatedLobby.getRegularURL()
			elif Global.OStype == "Linux/BSD":
				url = associatedLobby.getSteamURL()
			if url != "":
				OS.shell_open(url)
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
	panelStylebox.draw_center = true

func _mouse_exited() -> void:
	panelStylebox.draw_center = false


func _on_tree_exiting() -> void:
	if associatedLobby and associatedLobby.associatedNode == self:
		associatedLobby.associatedNode = null
