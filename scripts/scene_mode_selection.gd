extends Node2D

@onready var _menu : GenericMenu = $Menu
# Called when the node enters the scene tree for the first time.

var mapOptions = {
	0 : SceneManager.SceneType.CharacterSelectionMultiplayer,
	1 : SceneManager.SceneType.CharacterSelectionTraining,
}

func _ready():
	_menu.options = [0, 1]

func _update_input() -> int:
	var allButtonsPressed = 0
	if (InputOverseer.input_is_action_just_pressed_all_devices("confirm") or 
		InputOverseer.input_is_action_just_pressed_kb("confirm_p1") or
		InputOverseer.input_is_action_just_pressed_kb("confirm_p2")):
			allButtonsPressed = allButtonsPressed | GameDatabaseAccessor.GameInputButton.Confirm
	if (InputOverseer.input_is_action_pressed_all_devices("move_u") or 
		InputOverseer.input_is_action_pressed_kb("move_u_p1") or
		InputOverseer.input_is_action_pressed_kb("move_u_p2")):
			allButtonsPressed = allButtonsPressed | GameDatabaseAccessor.GameInputButton.Up
	if (InputOverseer.input_is_action_pressed_all_devices("move_d") or 
		InputOverseer.input_is_action_pressed_kb("move_d_p1") or
		InputOverseer.input_is_action_pressed_kb("move_d_p2")):
			allButtonsPressed = allButtonsPressed | GameDatabaseAccessor.GameInputButton.Down
	return allButtonsPressed
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var buttonsPressed = _update_input()
	_menu.update(buttonsPressed)
	if _menu.selection_performed():
		SceneManager.goto_scene_type(mapOptions[_menu.get_highlighted_option()])
