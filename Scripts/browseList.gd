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
@onready var passwordHeader = $"../BrowseHeaders/BrowseFilterPassword"
@onready var timeHeader = $"../BrowseHeaders/BrowseFilterTime"

const GONE_TIMEOUT := 120.0	# seconds a lobby that left the open list may take to show up as ongoing

var toContinue := false
var stripeMaterial: ShaderMaterial

func _ready() -> void:
	set_process(false)
	_setupBrowserStripeShader()

	var v_scroll_bar := get_v_scroll_bar()
	if v_scroll_bar:
		v_scroll_bar.value_changed.connect(_on_scroll_value_changed)

	resized.connect(_on_browser_resized)

	var clock := Timer.new()
	clock.timeout.connect(refreshSpecTimes)
	add_child(clock)
	clock.start(1.0)

	searchField.onBrowseHeaderAction(timeHeader)	# ongoing matches sort by start, newest first, by default

func clearAllLobbiesItems():
	for l in lobbiesListNode.get_children():
		l.queue_free()

func getLobbiesItems():
	return lobbiesListNode.get_children()

func ammendLobbiesList(source: Array = []):
	var lobby: LobbyClass
	for source_lobby in source:
		lobby = Storage.LOBBIES.get(int(source_lobby.id))
		if lobby and not lobby.associatedNode:	# started ones are skipped
			addItem(lobby, lobbiesListNode)
	applySort()

func addItem(lobby: LobbyClass, list: Control):
	var lobbyItem := lobbyItemScene.instantiate()
	list.add_child(lobbyItem)
	lobbyItem.associatedLobby = lobby
	lobby.associatedNode = lobbyItem
	lobbyItem.refreshUI()

func removeItem(lobby: LobbyClass):
	if lobby.associatedNode:
		lobby.associatedNode.free()
		lobby.associatedNode = null

# lobbies missing from the last refresh wait in GONE for their match to show up as ongoing
func sweepLobbies():
	var now := Time.get_unix_time_from_system()
	var lobby: LobbyClass
	for id in Storage.LOBBIES.keys():
		lobby = Storage.LOBBIES[id]
		if lobby.fresh:
			continue
		Storage.LOBBIES.erase(id)
		removeItem(lobby)
		if lobby.isObservable:	# others never show up as ongoing
			lobby.goneTime = now
			Storage.GONE[id] = lobby

# the source always has all ongoing matches. Known ones stay as they are (only finished
# ones are removed), new ones are added, open lobbies that started become ongoing.
# Spectate items exist only while the spectate list is shown.
func refreshSpecs(source: Dictionary):
	var showItems: bool = specListNode.visible
	var added := false
	var lobby: LobbyClass
	var id: int
	for key in source:
		id = int(key)
		lobby = Storage.SPECS.get(id)
		if lobby:
			if lobby.loadingLevel < 4:
				lobby.sourceCache = source[key]	# the next loading levels take the newest data
			continue
		lobby = Storage.LOBBIES.get(id, Storage.GONE.get(id))
		if not lobby and Storage.OPENED_LOBBY and Storage.OPENED_LOBBY.id == id:
			lobby = Storage.OPENED_LOBBY	# the opened lobby keeps its object even after it was dropped
		if lobby:
			Storage.LOBBIES.erase(id)
			Storage.GONE.erase(id)
			removeItem(lobby)
			lobby.setSpecSource(source[key])
		else:
			lobby = LobbyClass.new(source[key], true)
		Storage.SPECS[id] = lobby
		if showItems:
			addItem(lobby, specListNode)
			added = true
	for spec_id in Storage.SPECS.keys():
		if not source.has(str(spec_id)):
			removeItem(Storage.SPECS[spec_id])
			Storage.SPECS.erase(spec_id)
	var expired := Time.get_unix_time_from_system() - GONE_TIMEOUT
	for gone_id in Storage.GONE.keys():
		if Storage.GONE[gone_id].goneTime < expired:
			Storage.GONE.erase(gone_id)
	set_process(true)
	if added:
		applySort()

func showSpecs(isSpec: bool):
	lobbiesListNode.visible = not isSpec
	specListNode.visible = isSpec
	passwordHeader.visible = not isSpec
	timeHeader.visible = isSpec
	if isSpec:
		for spec in Storage.SPECS.values():
			if not spec.associatedNode:
				addItem(spec, specListNode)
	applySort()

func refreshSpecTimes():
	if not specListNode.is_visible_in_tree():
		return
	var now := int(Time.get_unix_time_from_system())
	for lobbyItem in specListNode.get_children():
		lobbyItem.refreshTime(now)

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
	var openedLobby: LobbyClass = Storage.OPENED_LOBBY
	var refreshOpenedLobby := false
	var refreshBrowseList := false
	toContinue = false
	for list in [Storage.LOBBIES, Storage.SPECS]:
		for lobby: LobbyClass in list.values():
			if lobby.loadingLevel == 1:
				lobby.loadBasicDetails()
				toContinue = true
			elif lobby.loadingLevel == 2:
				lobby.loadAllDetails()
				if openedLobby and lobby == openedLobby:
					refreshOpenedLobby = true
			else:
				continue
			# ongoing matches get every listed value in level 1
			if lobby.associatedNode and not lobby.isOngoging:
				lobby.associatedNode.refreshUI()
				refreshBrowseList = true
	if refreshOpenedLobby and Storage.OPENED_LOBBY == openedLobby:
		findButton.refreshActiveTab()
	if refreshBrowseList:
		applySort()
	set_process(toContinue)
