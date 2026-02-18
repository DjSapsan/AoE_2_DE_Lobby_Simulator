extends TabContainer

@onready var search_field:= %SearchField
@onready var find_button:= %FindButton
@onready var check_tab: PanelContainer = %Check

var general_search_text := ""
var lobby_search_text := ""
var default_placeholder := "Filter by..."
var default_find_text := "Find"

const LOBBY_PLACEHOLDER := "Find and jump to..."

func _ready():
	default_placeholder = search_field.placeholder_text
	default_find_text = find_button.text
	general_search_text = search_field.text

func _input(event):
	if event.is_action_pressed("switchTab"):
		current_tab = 0 if current_tab != 0 else 1

func _on_search_field_text_changed(new_text: String):
	if current_tab == 1 or current_tab == 2:
		lobby_search_text = new_text
		changeFindButton()
	else:
		general_search_text = new_text

func _on_tab_changed(tab):
	
	if not is_node_ready():
		return
		
	current_tab = tab
	match tab:
		0:	# browser
			%lobbyTips.visible = true
			search_field.placeholder_text = default_placeholder
			search_field.text = general_search_text
			find_button.text = "Find"

		1:	#lobby
			%lobbyTips.visible = false
			if search_field: 
				search_field.placeholder_text = LOBBY_PLACEHOLDER
				search_field.text = lobby_search_text
				changeFindButton()
				
		2:	# check
			%lobbyTips.visible = false
			if search_field: 
				search_field.placeholder_text = LOBBY_PLACEHOLDER
				search_field.text = lobby_search_text
				changeFindButton()
				
			check_tab.refreshLobby()				#refresh only when switching to it
	
func changeFindButton():
	if lobby_search_text.is_empty():
		find_button.text = "Refresh"
	else:
		find_button.text = "Jump"
