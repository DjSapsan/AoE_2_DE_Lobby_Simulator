extends TabContainer

@onready var search_field: LineEdit = %SearchField
@onready var find_button: Button = %FindButton
@onready var check_tab: PanelContainer = %Check
@onready var lobby_tab: PanelContainer = %Lobby
@onready var lobby_tips: Control = %lobbyTips

var general_search_text := ""
var lobby_search_text := ""
var default_placeholder := "Filter by..."
var default_find_text := "Find"
var default_find_tooltip := ""
var last_handled_tab := -1

const TAB_BROWSE := 0
const TAB_LOBBY := 1
const TAB_CHECK := 2
const LOBBY_PLACEHOLDER := "Find and jump to..."
const REFRESH_TOOLTIP := "Refresh the currently opened lobby."
const JUMP_TOOLTIP := "Jump to the first lobby matching the search text."

func _ready() -> void:
	current_tab = TAB_BROWSE
	default_placeholder = search_field.placeholder_text
	default_find_text = find_button.text
	default_find_tooltip = find_button.tooltip_text
	general_search_text = search_field.text
	last_handled_tab = current_tab
	update_find_button()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("switchTab"):
		current_tab = TAB_BROWSE if current_tab != TAB_BROWSE else TAB_LOBBY

func _on_search_field_text_changed(new_text: String) -> void:
	if current_tab == TAB_LOBBY or current_tab == TAB_CHECK:
		lobby_search_text = new_text
	else:
		general_search_text = new_text

	update_find_button()

func _on_tab_changed(tab: int) -> void:
	if not is_node_ready():
		return
	if tab == last_handled_tab:
		return

	last_handled_tab = tab
	match tab:
		TAB_BROWSE:
			lobby_tips.visible = true
			search_field.placeholder_text = default_placeholder
			set_search_text_if_changed(general_search_text)
		TAB_LOBBY:
			lobby_tips.visible = false
			search_field.placeholder_text = LOBBY_PLACEHOLDER
			set_search_text_if_changed(lobby_search_text)
			lobby_tab.refreshLobby()
		TAB_CHECK:
			lobby_tips.visible = false
			search_field.placeholder_text = LOBBY_PLACEHOLDER
			set_search_text_if_changed(lobby_search_text)
			check_tab.refreshLobby()

	update_find_button()

func set_search_text_if_changed(target_text: String) -> void:
	if search_field.text == target_text:
		return
	search_field.text = target_text

func update_find_button() -> void:
	if current_tab == TAB_BROWSE:
		find_button.text = default_find_text
		find_button.tooltip_text = default_find_tooltip
		return

	if search_field.text.is_empty():
		find_button.text = "Refresh"
		find_button.tooltip_text = REFRESH_TOOLTIP
	else:
		find_button.text = "Jump"
		find_button.tooltip_text = JUMP_TOOLTIP
