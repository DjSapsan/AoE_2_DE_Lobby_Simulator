extends Node

@onready var browser = %Browser
@onready var status = %Status

var arrayHeaders = PackedStringArray([
	"Origin: https://aoe2lobby.com",
])

var socket: WebSocketPeer
var subscribed := false  # track one-time subscribe

@onready var find_button: Button = %FindButton

func _init() -> void:
	pass

func _ready():
	set_process(false)

func start_process():
	set_process(true)

func stop_process():
	set_process(false)

func connectToSpecSite():
	socket = WebSocketPeer.new()
	#socket.handshake_headers = arrayHeaders
	#socket.write_mode = WebSocketPeer.WRITE_MODE_TEXT  # send JSON as text frames
	subscribed = false
	var error = socket.connect_to_url(Global.URL_SPEC_WSS)
	if error != OK:
		print("Failed to start WebSocket connection: ", error)
	else:
		start_process()

func disconnectFromSpecSite():
	print("disconnecting web socket")
	socket.close()
	stop_process()

func _process(_delta):
	socket.poll()

	match socket.get_ready_state():
		WebSocketPeer.STATE_CONNECTING:
			print("Connecting to WebSocket...")

		WebSocketPeer.STATE_OPEN:
			# subscribe once when connection is open
			if not subscribed:
				var msg:String = '{"action":"subscribe","type":"matches","context":"spectate"}'
				socket.send_text(msg)
				subscribed = true
			else:
				var buffer := ""
				while socket.get_available_packet_count() > 0:
					var packet = socket.get_packet()
					buffer += packet.get_string_from_utf8()

				if buffer.length() > 0:
					var jsonData = JSON.parse_string(buffer)
					if jsonData:
						for key in jsonData.keys():
							print(key)
							if find_button.FUNCTIONS_TABLE.has(key):
								var didChange = find_button.FUNCTIONS_TABLE[key].call(jsonData)
								if didChange:
									browser.populateSpecList()
									status.showAmountOfSpecs()

		WebSocketPeer.STATE_CLOSING:
			print("Stopping WebSocket...")

		WebSocketPeer.STATE_CLOSED:
			var code = socket.get_close_code()
			var reason = socket.get_close_reason()
			print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
			stop_process()
