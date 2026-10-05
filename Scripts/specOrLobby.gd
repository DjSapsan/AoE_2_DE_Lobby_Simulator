extends MenuButton

@onready var labelNode = $columns/Label
@onready var imgNode:TextureRect = $columns/TextureRect

#@onready var iconEye = load("res://img/icons8-eye-96.png")
@onready var animBinocle = $AnimatedSprite2D
@onready var iconLobby = load("res://img/icons8-an-encyclopedia-web-page-search-online-with-a-brief-details-96.png")

@onready var browser = %Browser
@onready var status = %Status
@onready var request_spec_node: Node = %WebSocket_spec
@onready var find_button: Button = %FindButton
@onready var balance_button: Button = %BalanceButton
@onready var popup: PopupMenu = get_popup()

var timeElapsed = 0
var animationActive = false	# also means auto-updating the spectate browser
#var specsLoading = false
var isAutorefresh: bool = true
var autorefresh_time := 0.0

func _ready():
	Global.ACTIVE_BROWSER = $"%Browser/LobbiesListNode"
	Global.ACTIVE_BROWSER_ID = 0
	popup.id_pressed.connect(_on_popup_id_pressed)

func _on_popup_id_pressed(_id:int) -> void:
	isAutorefresh = !isAutorefresh
	popup.set_item_checked(0, isAutorefresh)
	autorefresh_time = 0.0
	animationActive = isAutorefresh and Global.ACTIVE_BROWSER_ID == 1

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			show_popup()
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			accept_event()
			_on_switch()

func _on_switch ():
	if Global.ACTIVE_BROWSER_ID == 0:
		Global.ACTIVE_BROWSER_ID = 1
		labelNode.text = "Spectate"
		imgNode.texture = null #for binocle animation
		animBinocle.visible = true
		Global.ACTIVE_BROWSER = browser.get_child(1)
		browser.showSpecs(true)
		#browser.clearSpecList()
		request_spec_node.requestSpecs()
		#specsLoading = true
		animationActive = isAutorefresh
		autorefresh_time = 0.0
		balance_button.disabled = true
		#browser.populateSpecList()
	#elif specsLoading:
		#specsLoading = false
		#request_spec_node.disconnectFromSpecSite()
		#animationActive = false
	else:
		Global.ACTIVE_BROWSER_ID = 0
		labelNode.text = "Lobbies"
		imgNode.texture = iconLobby
		animBinocle.visible = false
		Global.ACTIVE_BROWSER = browser.get_child(0)
		browser.showSpecs(false)
		animationActive = false
		balance_button.disabled = Storage.OPENED_LOBBY and Storage.OPENED_LOBBY.isOngoging
		if find_button.disabled:	# still downloading
			status.changeStatus("Loading lobbies...")
		else:
			status.showAmountOfLobbies()

func _process(delta):
	timeElapsed = timeElapsed + delta

	if(animationActive and timeElapsed > 0.025):
		if(animBinocle.get_frame() == 48):
			animBinocle.set_frame(0)
		else:
			animBinocle.set_frame(animBinocle.get_frame() + 1)

		timeElapsed = 0
	elif not animationActive:
		animBinocle.set_frame(0)

	if animationActive:
		autorefresh_time += delta
		if autorefresh_time >= 15.0:
			autorefresh_time = 0.0
			request_spec_node.requestSpecs()
