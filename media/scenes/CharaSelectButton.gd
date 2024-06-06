extends MenuButton

var currentItemIndex = 0
var characterPaths = [
	"chara_naomi",
	"chara_rhozetta"
]

func _get_selected_character() -> String:
	return characterPaths[currentItemIndex]

func _get_selected_texture() -> Texture2D:
	return get_popup().get_item_icon(currentItemIndex)

func _on_item_menu_pressed(id: int):
	print("Item ID: ", id)
	currentItemIndex = id

# Called when the node enters the scene tree for the first time.
func _ready():
	get_popup().id_pressed.connect(_on_item_menu_pressed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
