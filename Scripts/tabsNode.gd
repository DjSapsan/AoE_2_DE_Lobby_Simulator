extends TabContainer

@onready var search_field: LineEdit = %searchField

#var generalSearch = ""
#var jumpSearch = ""

func _ready():
	current_tab = 0

func _input(event):
	if event.is_action_pressed("switchTab"):
		current_tab = 1 - current_tab
		
		#if current_tab == 1:
			##generalSearch = search_field.text
			#search_field.placeholder_text = "instant open lobby with that search text"
			##search_field.text = jumpSearch
		#else:
			##jumpSearch = search_field.text
			#search_field.placeholder_text = "filter by name, map, lobby id, steam id"
			##search_field.text = generalSearch

func _on_tab_changed(tab):
	%lobbyTips.visible = current_tab == 0
