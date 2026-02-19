extends Control

signal configFileDetected

@onready var BalanceDisplay = %BalanceDisplay
@onready var updateButton = $MainContainer/Sections/TopElements/UpdateButton

var cmd:String
#aoe2de://0/307853820

func _ready():
	var config = ConfigFile.new()
	var err = config.load(Global.SETTINGS_FILE_PATH)
	if err != OK:
		pass
		#print("Config could not be saved" +str(err))
	else:
		configFileDetected.emit()
		%LoadNameButton._on_pressed()

	checkUpdates()

func _on_config_file_detected():
	%LoadNameButton.disabled = false

func removeTeamDisplay():
	for node in BalanceDisplay.get_children():
		node.queue_free()

func _extract_version_parts(version_text: String) -> PackedInt32Array:
	var version_regex := RegEx.new()
	version_regex.compile("\\d+(?:\\.\\d+)*")
	var match := version_regex.search(version_text)
	if match == null:
		return PackedInt32Array()

	var version_parts := PackedInt32Array()
	for segment in match.get_string(0).split("."):
		version_parts.append(int(segment))
	return version_parts

func _is_remote_version_newer(remote_tag: String, local_version_text: String) -> bool:
	var remote_parts := _extract_version_parts(remote_tag)
	var local_parts := _extract_version_parts(local_version_text)
	if remote_parts.is_empty() or local_parts.is_empty():
		return false

	var max_size := maxi(remote_parts.size(), local_parts.size())
	for i in range(max_size):
		var remote_part := remote_parts[i] if i < remote_parts.size() else 0
		var local_part := local_parts[i] if i < local_parts.size() else 0
		if remote_part > local_part:
			return true
		if remote_part < local_part:
			return false
	return false

func checkUpdates():
	var http_request := HTTPRequest.new()
	add_child(http_request)

	var request_error := http_request.request(Global.URL_API_Updates)
	if request_error != OK:
		http_request.queue_free()
		return

	var raw_results: Array = await http_request.request_completed
	if raw_results.size() < 4:
		http_request.queue_free()
		return

	var result_code: int = int(raw_results[0])
	var http_code: int = int(raw_results[1])
	var body := raw_results[3] as PackedByteArray
	http_request.queue_free()

	if result_code != HTTPRequest.RESULT_SUCCESS:
		return
	if http_code < 200 or http_code >= 300:
		return

	var json_results = JSON.parse_string(body.get_string_from_utf8())
	if typeof(json_results) != TYPE_DICTIONARY:
		return
	if not json_results.has("tag_name"):
		return

	var remote_tag := str(json_results.get("tag_name"))
	if _is_remote_version_newer(remote_tag, str(Global.VERSION)):
		updateButton.visible = true


func _on_update_button_pressed():
	updateButton.visible = false
	OS.shell_open(Global.URL_UPDATE)
	pass # Replace with function body.
