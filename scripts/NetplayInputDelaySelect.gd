extends MenuButton

var currentItemIndex = 2

func _get_device_id() -> int:
	return currentItemIndex

func _get_input_delay_text() -> String:
	return get_popup().get_item_text(get_popup().get_item_index(currentItemIndex))

func _on_item_menu_pressed(id: int):
	print("Input Delay: ", id)
	currentItemIndex = id
	$Label.text = _get_input_delay_text()
	NetworkAssistant.localPlayerInputDelay = currentItemIndex

# Called when the node enters the scene tree for the first time.
func _ready():
	$Label.text = _get_input_delay_text()
	get_popup().id_pressed.connect(_on_item_menu_pressed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
