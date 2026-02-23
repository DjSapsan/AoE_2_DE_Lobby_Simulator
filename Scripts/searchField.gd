extends LineEdit

const SORT_NONE := 0
const SORT_DESC := -1
const SORT_ASC := 1

@onready var finder = %FindButton
@onready var browser = %Browser
@onready var tabsNode = %TabsNode

var lowerTextCache: String = ""
var currentHeader: Control

var sortButtonActive: Button
var sortDirection: int = SORT_NONE
var hidePasswords := false

func _ready():
	pass

func _on_search_field_text_changed(_new_text: String):
	lowerTextCache = _new_text.to_lower()
	browser.applyFilter()

func filterLobby(lobby: LobbyClass) -> bool:
	if lowerTextCache == "":
		return not (hidePasswords and lobby.password)
	return lobby.index.contains(lowerTextCache) and not (hidePasswords and lobby.password)

func addArrowToTitle(label_text: String) -> String:
	if sortDirection == SORT_NONE:
		return label_text
	elif sortDirection == SORT_DESC:
		return "↓" + label_text
	elif sortDirection == SORT_ASC:
		return "↑" + label_text
	return label_text

func removeArrowsFromTitle(label_text: String) -> String:
	return label_text.trim_prefix("↓").trim_prefix("↑")

func getNextSortDirection(current_direction: int) -> int:
	match current_direction:
		SORT_DESC:
			return SORT_ASC
		SORT_ASC:
			return SORT_NONE
		_:
			return SORT_DESC

func resetHeaderText(header: Control):
	if header and header.name != "BrowseFilterPassword":
		header.text = removeArrowsFromTitle(header.text)

func onBrowseHeaderAction(header: Control):
	if header.name == "BrowseFilterPassword":
		hidePasswords = !hidePasswords
		header.text = "X" if hidePasswords else ""
		applyFilter()
		return

	if header != currentHeader:
		if currentHeader:
			resetHeaderText(currentHeader)
		currentHeader = header
		sortDirection = SORT_DESC
	else:
		sortDirection = getNextSortDirection(sortDirection)

	header.text = addArrowToTitle(removeArrowsFromTitle(header.text))
	applySort(header.name)

func applySort(sortBy: String = ""):
	var active_browser = Global.ACTIVE_BROWSER

	if not currentHeader:
		applyFilter()
		return

	if sortBy == "":
		sortBy = currentHeader.name

	if sortDirection == SORT_NONE or sortBy == "":
		applyFilter()
		return

	var newOrder = active_browser.get_children()

	match sortBy:
		"BrowseFilterTitles":
			newOrder.sort_custom(func(a, b): return sortByTitle(a, b, sortDirection))
		"BrowseFilterPlayers":
			newOrder.sort_custom(func(a, b): return sortByPlayers(a, b, sortDirection))
		"BrowseFilterType":
			newOrder.sort_custom(func(a, b): return sortByType(a, b, sortDirection))
		"BrowseFilterMap":
			newOrder.sort_custom(func(a, b): return sortByMap(a, b, sortDirection))

	for i in newOrder.size():
		active_browser.move_child(newOrder[i], i)

	applyFilter()

static func sortByTitle(a, b, direction: int) -> bool:
	return direction * (a.associatedLobby.title.casecmp_to(b.associatedLobby.title)) < 0

static func sortByPlayers(a, b, direction: int) -> bool:
	return direction * (a.associatedLobby.totalPlayers - b.associatedLobby.totalPlayers) < 0

static func sortByType(a, b, direction: int) -> bool:
	return direction * (a.associatedLobby.gameModeName.casecmp_to(b.associatedLobby.gameModeName)) < 0

static func sortByMap(a, b, direction: int) -> bool:
	return direction * (str(a.associatedLobby.map).casecmp_to(str(b.associatedLobby.map))) < 0

func applyFilter():
	if tabsNode.current_tab == 0:
		var active_browser = Global.ACTIVE_BROWSER
		if not active_browser:
			return

		for lItem in active_browser.get_children():
			lItem.visible = filterLobby(lItem.associatedLobby)
