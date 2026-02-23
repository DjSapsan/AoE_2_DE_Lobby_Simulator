extends ScrollContainer

const lobbyItemScene: PackedScene = preload("res://scenes/lobbyItem.tscn")
const BROWSER_ROW_ALPHA_SHADER: Shader = preload("res://styles/browse_item_alpha_stripe.gdshader")

const SHADER_PARAM_ROW_HEIGHT := "row_height_px"
const SHADER_PARAM_VIEWPORT_HEIGHT := "viewport_height_px"
const SHADER_PARAM_SCROLL_OFFSET := "scroll_offset_px"

@onready var searchField: LineEdit = %SearchField
@onready var findButton = %FindButton

@onready var lobbiesListNode = $LobbiesListNode
@onready var specListNode = $SpecListNode



var toContinue := false
var stripeMaterial: ShaderMaterial

func _ready() -> void:
	set_process(false)
	_setupBrowserStripeShader()

	var v_scroll_bar := get_v_scroll_bar()
	if v_scroll_bar:
		v_scroll_bar.value_changed.connect(_on_scroll_value_changed)

	resized.connect(_on_browser_resized)

func clearAllLobbiesItems():
	for l in lobbiesListNode.get_children():
		l.queue_free()

func getLobbiesItems():
	return lobbiesListNode.get_children()

func ammendLobbiesList(source: Array = []):
	var id: int
	var lobby: LobbyClass
	var lobbyItem: Control
	for source_lobby in source:
		id = int(source_lobby.id)
		lobby = Storage.LOBBIES[id]
		lobbyItem = lobby.associatedNode
		if not lobbyItem:
			lobbyItem = lobbyItemScene.instantiate()
			lobbiesListNode.add_child(lobbyItem)
			lobbyItem.associatedLobby = lobby
			lobby.associatedNode = lobbyItem
			Storage.LOBBIES[id] = lobby
			lobbyItem.refreshUI()
	applySort()

func applyFilter():
	searchField.applyFilter()

func applySort():
	searchField.applySort()

func _setupBrowserStripeShader() -> void:
	stripeMaterial = ShaderMaterial.new()
	stripeMaterial.shader = BROWSER_ROW_ALPHA_SHADER
	material = stripeMaterial
	_updateStripeShaderUniforms()
	queue_redraw()

func _updateStripeShaderUniforms() -> void:
	if stripeMaterial == null:
		return

	stripeMaterial.set_shader_parameter(SHADER_PARAM_VIEWPORT_HEIGHT, size.y)
	stripeMaterial.set_shader_parameter(SHADER_PARAM_SCROLL_OFFSET, float(scroll_vertical))
	queue_redraw()

func _on_scroll_value_changed(_value: float) -> void:
	_updateStripeShaderUniforms()

func _on_browser_resized() -> void:
	_updateStripeShaderUniforms()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color.WHITE, true)

#braindead solution to load details over several frames
func _process(_delta: float) -> void:
	var lobby: LobbyClass
	var openedLobby: LobbyClass = Storage.OPENED_LOBBY
	var refreshOpenedLobby := false
	var refreshBrowseList := false
	toContinue = false
	for id in Storage.LOBBIES.keys():
		lobby = Storage.LOBBIES[id]
		if not lobby.fresh:
			Storage.LOBBIES.erase(id)
			lobby.associatedNode.queue_free()
			refreshBrowseList = true
		else:
			if lobby.loadingLevel == 1:
				lobby.loadBasicDetails()
				lobby.associatedNode.refreshUI()
				refreshBrowseList = true
				toContinue = true
				continue
			elif lobby.loadingLevel == 2:
				lobby.loadAllDetails()
				lobby.associatedNode.refreshUI()
				refreshBrowseList = true
				if openedLobby and lobby == openedLobby:
					refreshOpenedLobby = true
				continue
	if refreshOpenedLobby and Storage.OPENED_LOBBY == openedLobby:
		findButton.refreshActiveTab()
	if refreshBrowseList:
		applySort()
	set_process(toContinue)
