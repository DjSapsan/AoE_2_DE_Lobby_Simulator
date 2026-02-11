extends TabContainer

@onready var search_field:= %searchField
@onready var find_button:= %FindButton

var general_search_text := ""
var lobby_search_text := ""
var default_placeholder := ""
var default_find_text := ""

const LOBBY_PLACEHOLDER := "find and jump to"

func _ready():
	current_tab = 0
	default_placeholder = search_field.placeholder_text
	default_find_text = find_button.text
	general_search_text = search_field.text
	search_field.text_changed.connect(_on_search_field_text_changed)

func _input(event):
	if event.is_action_pressed("switchTab"):
		current_tab = 1 - current_tab

func _on_tab_changed(tab):
	current_tab = tab
	%lobbyTips.visible = current_tab == 0
	_handle_tab_switch(current_tab == 1)

func _on_search_field_text_changed(new_text: String):
	if current_tab == 1:
		lobby_search_text = new_text
		_update_lobby_find_button()
	else:
		general_search_text = new_text

func _handle_tab_switch(is_lobby_tab: bool):
	if is_lobby_tab:
		general_search_text = search_field.text
		search_field.placeholder_text = LOBBY_PLACEHOLDER
		search_field.text = lobby_search_text
		_update_lobby_find_button()
	else:
		lobby_search_text = search_field.text
		search_field.placeholder_text = default_placeholder
		find_button.text = default_find_text
		search_field.text = general_search_text

func _update_lobby_find_button():
	if current_tab != 1:
		return

	search_field.placeholder_text = LOBBY_PLACEHOLDER
	if lobby_search_text.is_empty():
		find_button.text = "Refresh"
	else:
		find_button.text = "Jump"
