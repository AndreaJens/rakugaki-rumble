class_name SceneSettings extends Node2D

@onready var menu : GenericMenuNodes = $Menu
@onready var musicVolume : HorizontalGenericMenu = $Menu/Music/HorizontalMenu
@onready var sfxVolume : HorizontalGenericMenu = $Menu/SFX/HorizontalMenu
var _sceneChange : bool = false

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
	elif (InputOverseer.input_is_action_pressed_all_devices("move_d") or 
		InputOverseer.input_is_action_pressed_kb("move_d_p1") or
		InputOverseer.input_is_action_pressed_kb("move_d_p2")):
			allButtonsPressed = allButtonsPressed | GameDatabaseAccessor.GameInputButton.Down
	if (InputOverseer.input_is_action_pressed_all_devices("move_r") or 
		InputOverseer.input_is_action_pressed_kb("move_r_p1") or
		InputOverseer.input_is_action_pressed_kb("move_r_p2")):
			allButtonsPressed = allButtonsPressed | GameDatabaseAccessor.GameInputButton.Right
	elif (InputOverseer.input_is_action_pressed_all_devices("move_l") or 
		InputOverseer.input_is_action_pressed_kb("move_l_p1") or
		InputOverseer.input_is_action_pressed_kb("move_l_p2")):
			allButtonsPressed = allButtonsPressed | GameDatabaseAccessor.GameInputButton.Left
	return allButtonsPressed

# Called when the node enters the scene tree for the first time.
func _ready():
	GlobalOptions.load_from_file()
	musicVolume.set_index_by_value(GlobalOptions.musicVolume)
	sfxVolume.set_index_by_value(GlobalOptions.sfxVolume)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if _sceneChange: 
		return
	var inputButtons = _update_input()
	menu.update(inputButtons)
	var menuIndex = menu.get_highlighted_option()
	if menuIndex == 2:
		if menu.selection_performed():
			_sceneChange = true
			GlobalOptions.save_to_file()
			await(get_tree().create_timer(0.5).timeout)
			SceneManager.goto_scene_type(SceneManager.SceneType.ModeSelection)
	elif menuIndex == 0:
		musicVolume.update(inputButtons)
		GlobalOptions.musicVolume = musicVolume.get_highlighted_option()
		menu.cancel_selection()
	elif menuIndex == 1:
		sfxVolume.update(inputButtons)
		GlobalOptions.sfxVolume = sfxVolume.get_highlighted_option()
		menu.cancel_selection()
