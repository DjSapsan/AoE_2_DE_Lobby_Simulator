extends MenuButton

const ID_RESET  := 0
const ID_COPY_LOBBY  := 1

@onready var popup: PopupMenu = get_popup()
@onready var check_tab: PanelContainer = %Check

func _ready() -> void:
	# Connect once.
	popup.id_pressed.connect(_on_popup_id_pressed)

func _on_popup_id_pressed(id: int) -> void:
	match id:
		ID_RESET:
			reset_settings()
		ID_COPY_LOBBY:
			copy_lobby()

func reset_settings() -> void:
	check_tab.resetSettings()

func copy_lobby() -> void:
	check_tab.copyLobby()
