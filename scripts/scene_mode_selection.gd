class_name SceneModeSelection extends SceneBase

@onready var _menu : GenericMenu = $Menu
@onready var _vsMenu : GenericMenu = $VS_Menu
var _sceneChange : bool = false
# Called when the node enters the scene tree for the first time.

var mapOptions = {
	1 : SceneManager.SceneType.CharacterSelectionTraining,
	2 : SceneManager.SceneType.NetplayMenu,
	3 : SceneManager.SceneType.Settings,
}

var vsMenuOptions = {
	0 : SceneManager.SceneType.CharacterSelectionMultiplayer,
	1 : SceneManager.SceneType.CharacterSelectionPlayerVsCpu,
	2 : SceneManager.SceneType.CharacterSelectionCpuVsCpu,
}

func _ready():
	_menu.options = [0, 1, 2, 3]
	_vsMenu.options = [0, 1, 2, 3]
	_deactivate_vs_menu()

func _update_input() -> int:
	var allButtonsPressed = 0
	if (InputOverseer.input_is_action_just_pressed_all_devices("confirm") or 
		InputOverseer.input_is_action_just_pressed_kb("confirm_p1") or
		InputOverseer.input_is_action_just_pressed_kb("confirm_p2")):
			allButtonsPressed = allButtonsPressed | GameDatabaseAccessor.GameInputButton.Confirm
	if (InputOverseer.input_is_action_just_pressed_all_devices("cancel") or 
		InputOverseer.input_is_action_just_pressed_kb("cancel_p1") or
		InputOverseer.input_is_action_just_pressed_kb("cancel_p2")):
			allButtonsPressed = allButtonsPressed | GameDatabaseAccessor.GameInputButton.Cancel
	if (InputOverseer.input_is_action_pressed_all_devices("move_u") or 
		InputOverseer.input_is_action_pressed_kb("move_u_p1") or
		InputOverseer.input_is_action_pressed_kb("move_u_p2")):
			allButtonsPressed = allButtonsPressed | GameDatabaseAccessor.GameInputButton.Up
	if (InputOverseer.input_is_action_pressed_all_devices("move_d") or 
		InputOverseer.input_is_action_pressed_kb("move_d_p1") or
		InputOverseer.input_is_action_pressed_kb("move_d_p2")):
			allButtonsPressed = allButtonsPressed | GameDatabaseAccessor.GameInputButton.Down
	return allButtonsPressed
	
func _activate_vs_menu():
	_menu.deselect_option()
	_vsMenu.deselect_option()
	_vsMenu.reset_index()
	_menu.active = false
	_menu.visible = false
	_vsMenu.active = true
	_vsMenu.visible = true
	_sceneChange = false
	
func _deactivate_vs_menu():
	_menu.deselect_option()
	_vsMenu.deselect_option()
	_vsMenu.reset_index()
	_menu.active = true
	_menu.visible = true
	_vsMenu.active = false
	_vsMenu.visible = false
	_sceneChange = false

func _update_main_menu(buttonsPressed : int):
	_menu.update(buttonsPressed)
	var menuIndex : int = _menu.get_highlighted_option()
	if _menu.selection_performed():
		if mapOptions.has(menuIndex):
			_sceneChange = true
			await(get_tree().create_timer(0.3).timeout)
			SceneManager.goto_scene_type(mapOptions[_menu.get_highlighted_option()])
		elif menuIndex == 0: #VS_Menu
			_sceneChange = true
			await(get_tree().create_timer(0.3).timeout)
			_activate_vs_menu()

func _update_vs_menu(buttonsPressed : int):
	_vsMenu.update(buttonsPressed)
	var menuIndex : int = _vsMenu.get_highlighted_option()
	if _vsMenu.selection_performed():
		if vsMenuOptions.has(menuIndex):
			_sceneChange = true
			await(get_tree().create_timer(0.3).timeout)
			SceneManager.goto_scene_type(vsMenuOptions[_vsMenu.get_highlighted_option()])
		elif menuIndex == _vsMenu.options.back(): #back to menu
			_sceneChange = true
			await(get_tree().create_timer(0.3).timeout)
			_deactivate_vs_menu()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if _sceneChange:
		return
	var buttonsPressed = _update_input()
	if _menu.visible:
		_update_main_menu(buttonsPressed)
	if _vsMenu.visible:
		_update_vs_menu(buttonsPressed)
