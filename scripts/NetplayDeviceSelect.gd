extends MenuButton

var currentItemIndex = -1

func _get_device_id() -> int:
	return currentItemIndex

func _get_selected_device_text() -> String:
	return get_popup().get_item_text(currentItemIndex + 1)

func _on_item_menu_pressed(id: int):
	print("Device ID: ", id - 1)
	currentItemIndex = id - 1
	$Label.text = _get_selected_device_text()
	NetworkAssistant.localPlayerDeviceId = currentItemIndex

# Called when the node enters the scene tree for the first time.
func _ready():
	$Label.text = _get_selected_device_text()
	get_popup().id_pressed.connect(_on_item_menu_pressed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
