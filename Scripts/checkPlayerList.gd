extends VBoxContainer

@onready var playerSlots = [
	$playerSlot1,
	$playerSlot2,
	$playerSlot3,
	$playerSlot4,
	$playerSlot5,
	$playerSlot6,
	$playerSlot7,
	$playerSlot8	
]

func changePlayersInSlots():
	var lobby = Storage.CURRENT_LOBBY
	for i in range(8):
		var player = lobby.slots[i]
		var playerSlot = playerSlots[i]
		playerSlot.changePlayer(player, 1)
		playerSlot.lockTeam = true

func reset():
	for i in range(8):
		playerSlots[i].changePlayer()

func refreshAllNames():
	for i in range(8):
		playerSlots[i].showName()

func showRealTeams():
	var lobby = Storage.CURRENT_LOBBY
	for i in range(8):
		playerSlots[i].showRealTeam(lobby.realTeams[i])
