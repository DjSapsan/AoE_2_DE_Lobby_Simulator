extends Node

@onready var browser = %Browser
@onready var status = %Status

#var arrayHeaders = PackedStringArray([
#	"Origin: https://aoe2lobby.com",
#])

const SUBSCRIBE := '{"action":"subscribe","type":"matches","context":"spectate"}'
const TIMEOUT_MSEC := 15000

var socket: WebSocketPeer
var subscribed := false  # track one-time subscribe
var waiting := false  # a snapshot is requested and hasn't arrived yet
var requestTime := 0
var parseTask := -1
var parsed := []	# filled by the parse task

#@onready var find_button: Button = %FindButton

#func _init() -> void:
#	pass

func _ready():
	set_process(false)

# aoe2lobby sends no updates after the snapshot, but answers every subscribe with all ongoing
# matches, so the socket stays open and a refresh is one small message instead of a new connection
func requestSpecs():
	if Global.ACTIVE_BROWSER_ID == 1:
		status.changeStatus("Loading ongoing matches...")
	if waiting and Time.get_ticks_msec() - requestTime < TIMEOUT_MSEC:
		return
	var reuse := not waiting and socket != null and socket.get_ready_state() == WebSocketPeer.STATE_OPEN
	waiting = true
	requestTime = Time.get_ticks_msec()
	if reuse:
		socket.send_text(SUBSCRIBE)
		return
	# first request, a lost connection or an unanswered request
	socket = WebSocketPeer.new()
	socket.inbound_buffer_size = 1 << 23  # all matches come in one ~3MB message
	socket.heartbeat_interval = 30.0  # keeps the idle connection alive between refreshes
	subscribed = false
	var error = socket.connect_to_url(Global.URL_SPEC_WSS)
	if error != OK:
		waiting = false
		showError("Error " + str(error))
		return
	set_process(true)

func showError(txt: String):
	if Global.ACTIVE_BROWSER_ID == 1:
		status.changeStatus(txt, 1)

func _process(_delta):
	socket.poll()

	match socket.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			if not subscribed:
				socket.send_text(SUBSCRIBE)
				subscribed = true
			elif parseTask == -1 and socket.get_available_packet_count() > 0:
				var packet := socket.get_packet()
				var result := []
				parsed = result
				# parsing the ~3MB of matches takes ~60 ms, too long for the main thread
				parseTask = WorkerThreadPool.add_task(func(): result.append(JSON.parse_string(packet.get_string_from_utf8())))

		WebSocketPeer.STATE_CLOSED:
			if parseTask == -1:
				set_process(false)
				if waiting:
					waiting = false
					showError("Error loading ongoing matches " + str(socket.get_close_code()))

	if parseTask != -1 and WorkerThreadPool.is_task_completed(parseTask):
		WorkerThreadPool.wait_for_task_completion(parseTask)
		parseTask = -1
		var jsonData = parsed[0]
		parsed = []
		if jsonData is Dictionary and jsonData.has("spectate_match_all"):
			waiting = false
			browser.refreshSpecs(jsonData.spectate_match_all)
			if Global.ACTIVE_BROWSER_ID == 1:
				status.showAmountOfSpecs()

# raw TCP/TLS websocket with permessage-deflate, not needed: the server works without compression
#enum {CLOSED, RESOLVING, CONNECTING, HANDSHAKING, UPGRADING, OPEN}
#
#var state := CLOSED
#var host: String
#var path: String
#var resolve_id: int
#var tcp: StreamPeerTCP
#var tls: StreamPeerTLS
#var rx := PackedByteArray()
#var msg := PackedByteArray()
#var msg_compressed := false
#var inflater: StreamPeerGZIP
#var no_context_takeover := false
#var crypto := Crypto.new()
#
#@onready var find_button: Button = %FindButton
#
#func _init() -> void:
#	pass
#
#func _ready():
#	set_process(false)
#
#func start_process():
#	set_process(true)
#
#func stop_process():
#	set_process(false)
#
#func connectToSpecSite():
#	_close()
#	var url := Global.URL_SPEC_WSS.trim_prefix("wss://")
#	host = url.get_slice("/", 0)
#	path = url.substr(host.length())
#	rx.clear()
#	inflater = null
#	resolve_id = IP.resolve_hostname_queue_item(host)
#	state = RESOLVING
#	start_process()
#
#func disconnectFromSpecSite():
#	print("disconnecting web socket")
#	if state == OPEN:
#		_send_frame(8, PackedByteArray([0x03, 0xE8]))
#	_close()
#
#func _close():
#	if state == RESOLVING:
#		IP.erase_resolve_item(resolve_id)
#	if tcp:
#		tcp.disconnect_from_host()
#	tcp = null
#	tls = null
#	state = CLOSED
#	stop_process()
#
#func _fail(reason: String):
#	print("WebSocket failed: ", reason)
#	_close()
#
#func _process(_delta):
#	match state:
#		RESOLVING:
#			var s := IP.get_resolve_item_status(resolve_id)
#			if s == IP.RESOLVER_STATUS_DONE:
#				var ip := IP.get_resolve_item_address(resolve_id)
#				IP.erase_resolve_item(resolve_id)
#				tcp = StreamPeerTCP.new()
#				tcp.connect_to_host(ip, 443)
#				state = CONNECTING
#			elif s != IP.RESOLVER_STATUS_WAITING:
#				_fail("DNS")
#		CONNECTING:
#			tcp.poll()
#			var s := tcp.get_status()
#			if s == StreamPeerTCP.STATUS_CONNECTED:
#				tls = StreamPeerTLS.new()
#				tls.connect_to_stream(tcp, host)
#				state = HANDSHAKING
#			elif s != StreamPeerTCP.STATUS_CONNECTING:
#				_fail("TCP")
#		HANDSHAKING:
#			tls.poll()
#			var s := tls.get_status()
#			if s == StreamPeerTLS.STATUS_CONNECTED:
#				var key := Marshalls.raw_to_base64(crypto.generate_random_bytes(16))
#				tls.put_data(("GET %s HTTP/1.1\r\nHost: %s\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: %s\r\nSec-WebSocket-Version: 13\r\nSec-WebSocket-Extensions: permessage-deflate\r\n\r\n" % [path, host, key]).to_utf8_buffer())
#				state = UPGRADING
#			elif s != StreamPeerTLS.STATUS_HANDSHAKING:
#				_fail("TLS")
#		UPGRADING, OPEN:
#			_read()
#
#func _read():
#	tls.poll()
#	while tls.get_available_bytes() > 0:
#		rx.append_array(tls.get_partial_data(tls.get_available_bytes())[1])
#		tls.poll()
#	if state == UPGRADING:
#		var end := rx.find(10)
#		while end > 1 and not (rx[end - 1] == 13 and rx[end - 2] == 10):
#			end = rx.find(10, end + 1)
#		if end > 1:
#			var head := rx.slice(0, end).get_string_from_utf8()
#			rx = rx.slice(end + 1)
#			if not head.begins_with("HTTP/1.1 101"):
#				return _fail(head.get_slice("\r\n", 0))
#			no_context_takeover = head.contains("server_no_context_takeover")
#			state = OPEN
#			_send_frame(1, '{"action":"subscribe","type":"matches","context":"spectate"}'.to_utf8_buffer())
#	if state == OPEN:
#		_parse_frames()
#	if state != CLOSED and tls.get_status() != StreamPeerTLS.STATUS_CONNECTED:
#		_fail("connection lost")
#
#func _parse_frames():
#	while rx.size() >= 2:
#		var b0 := rx[0]
#		var size := rx[1] & 0x7F
#		var off := 2
#		if size == 126:
#			if rx.size() < 4:
#				return
#			size = rx[2] << 8 | rx[3]
#			off = 4
#		elif size == 127:
#			if rx.size() < 10:
#				return
#			size = 0
#			for i in range(2, 10):
#				size = size << 8 | rx[i]
#			off = 10
#		if rx.size() < off + size:
#			return
#		var payload := rx.slice(off, off + size)
#		rx = rx.slice(off + size)
#		var op := b0 & 0x0F
#		if op == 9:
#			_send_frame(10, payload)
#		elif op == 8:
#			print("WebSocket closed with code: %d" % (payload[0] << 8 | payload[1] if payload.size() >= 2 else -1))
#			_send_frame(8, payload.slice(0, 2))
#			return _close()
#		elif op < 3:
#			if op != 0:
#				msg = PackedByteArray()
#				msg_compressed = b0 & 0x40 != 0
#			msg.append_array(payload)
#			if b0 & 0x80:
#				var data := _inflate(msg) if msg_compressed else msg
#				if data.is_empty():
#					return _fail("inflate")
#				_on_message(data)
#
## permessage-deflate is raw deflate: fake a zlib header once, re-append the stripped 00 00 FF FF tail per message
#func _inflate(data: PackedByteArray) -> PackedByteArray:
#	if inflater == null or no_context_takeover:
#		inflater = StreamPeerGZIP.new()
#		inflater.start_decompression(true, 1 << 20)
#		inflater.put_data(PackedByteArray([0x78, 0x9C]))
#	var input := data + PackedByteArray([0, 0, 0xFF, 0xFF])
#	var out := PackedByteArray()
#	var off := 0
#	while off < input.size():
#		var r := inflater.put_partial_data(input.slice(off))
#		var chunk: PackedByteArray = inflater.get_partial_data(inflater.get_available_bytes())[1]
#		if r[0] != OK or (r[1] == 0 and chunk.is_empty()):
#			return PackedByteArray()
#		off += r[1]
#		out.append_array(chunk)
#	return out
#
#func _send_frame(op: int, payload: PackedByteArray):
#	var mask := crypto.generate_random_bytes(4)
#	var frame := PackedByteArray([0x80 | op])
#	if payload.size() < 126:
#		frame.append(0x80 | payload.size())
#	else:
#		frame.append_array(PackedByteArray([0xFE, payload.size() >> 8, payload.size() & 0xFF]))
#	frame.append_array(mask)
#	for i in payload.size():
#		frame.append(payload[i] ^ mask[i % 4])
#	tls.put_data(frame)
#
#func _on_message(data: PackedByteArray):
#	var jsonData = JSON.parse_string(data.get_string_from_utf8())
#	if jsonData:
#		for key in jsonData.keys():
#			print(key)
#			if find_button.FUNCTIONS_TABLE.has(key):
#				var didChange = find_button.FUNCTIONS_TABLE[key].call(jsonData)
#				if didChange:
#					browser.populateSpecList()
#					status.showAmountOfSpecs()
