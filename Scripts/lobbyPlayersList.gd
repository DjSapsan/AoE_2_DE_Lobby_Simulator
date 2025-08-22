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

@onready var eloSelector = %L_elo
@onready var balancer: Button = %BalanceButton

func changePlayersInSlots():
	var lobby = Storage.CURRENT_LOBBY
	for i in range(8):
		var player = lobby.slots[i]
		var playerSlot = playerSlots[i]
		playerSlot.changePlayer(player)

func reset():
	for i in range(8):
		playerSlots[i].changePlayer()

func refreshAllElo():
	for i in range(8):
		playerSlots[i].showElo()

func signalRefreshAllElo(index):
	var LB_ID = eloSelector.get_item_id(index)
	for i in range(8):
		playerSlots[i].showElo(LB_ID)
	balancer.startBalancing()

func refreshAllSmurfs():
	for i in range(8):
		playerSlots[i].showSmurf()

func refreshAllNames():
	for i in range(8):
		playerSlots[i].showName()

func refreshAllOtherInfo():
	var lobby = Storage.CURRENT_LOBBY
	for i in range(8):
		playerSlots[i].showOtherInfo(lobby.civs[i], lobby.colors[i], lobby.teams[i])
