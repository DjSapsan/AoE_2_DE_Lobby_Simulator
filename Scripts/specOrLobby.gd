extends Button

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

var timeElapsed = 0
var animationActive = false
var specsLoading = false

func _ready():
	Global.ACTIVE_BROWSER = $"%Browser/LobbiesListNode"
	Global.ACTIVE_BROWSER_ID = 0

func _on_switch ():
	if Global.ACTIVE_BROWSER_ID == 0:
		Global.ACTIVE_BROWSER_ID = 1
		labelNode.text = "Spectate"
		imgNode.texture = null #for binocle animation
		animBinocle.visible = true
		Global.ACTIVE_BROWSER = browser.get_child(1)
		browser.get_child(0).visible = false
		browser.get_child(1).visible = true
		browser.clearSpecList()
		request_spec_node.connectToSpecSite()
		specsLoading = true
		animationActive = true
		find_button.disabled = true
		balance_button.disabled = true
		browser.populateSpecList()
	elif specsLoading:
		specsLoading = false
		request_spec_node.disconnectFromSpecSite()
		animationActive = false
	else:
		Global.ACTIVE_BROWSER_ID = 0
		labelNode.text = "Lobbies"
		imgNode.texture = iconLobby
		animBinocle.visible = false
		Global.ACTIVE_BROWSER = browser.get_child(0)
		browser.get_child(0).visible = true
		browser.get_child(1).visible = false
		request_spec_node.disconnectFromSpecSite()
		animationActive = false
		find_button.disabled = false
		balance_button.disabled = false
		
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
