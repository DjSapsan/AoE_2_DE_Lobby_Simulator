extends Button

@onready var finder = %FindButton
@onready var timer = $Timer

@onready var isOn = false

func _on_toggled():
	if isOn:
		isOn = false
		timer.stop()
		text = "II"
	else:
		isOn = true
		timer.start()
		finder._on_find_button_pressed(true)
		text = "↺"

func _on_timer_timeout():
	timer.start()
	finder._on_find_button_pressed(true)
