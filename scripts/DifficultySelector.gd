class_name DifficultySelector extends Node2D

@export var textures : Array[Texture2D]
@export var options : Array[SceneCharacterSelection.DifficultySettings] = [
	SceneCharacterSelection.DifficultySettings.Easy,
	SceneCharacterSelection.DifficultySettings.Medium,
	SceneCharacterSelection.DifficultySettings.Hard,
]

var _index : int = 0
var _animationTicks : int = 0
var _zoomTicks : int = 0
var _lastInputReceived : GameDatabaseAccessor.GameInputButton = GameDatabaseAccessor.GameInputButton.None
var active : bool = true
const animationPeriod : int = 20
@export_category("Sounds")
@export var cursorSound : AudioStream
@export var audioPlayer : AudioStreamPlayer
	
func get_highlighted_option() -> int:
	return options[_index]
		
func play_cursor_sound():
	if audioPlayer and cursorSound:
		audioPlayer.stream = cursorSound
		audioPlayer.volume_db = GlobalOptions.get_sfx_volume()
		audioPlayer.play()

func update_arrows():
	var offsetVal : float = 4.
	@warning_ignore("integer_division")
	var animHalfPeriod = animationPeriod / 2
	if _animationTicks % animationPeriod < animHalfPeriod:
		offsetVal = -4.
	$ArrowLeft.offset.x = offsetVal
	$ArrowRight.offset.x = -offsetVal
	return
	
func update(allButtonsPressed : int):
	if _zoomTicks > 0:
		$DifficultyLabel.scale.x = 1.2
		$DifficultyLabel.scale.y = 1.2
		_zoomTicks -= 1
	else:
		$DifficultyLabel.scale.x = 1.0
		$DifficultyLabel.scale.y = 1.0
	if active and visible:
		if ((allButtonsPressed & ~_lastInputReceived) & GameDatabaseAccessor.GameInputButton.Right):
			_index += 1
			_index %= options.size()
			_zoomTicks = 8
			play_cursor_sound()
		elif ((allButtonsPressed & ~_lastInputReceived) & GameDatabaseAccessor.GameInputButton.Left):
			_index -= 1
			if _index < 0: _index = options.size() - 1
			_zoomTicks = 8
			play_cursor_sound()
	@warning_ignore("int_as_enum_without_cast")
	_lastInputReceived = allButtonsPressed
	_animationTicks += 1
	_animationTicks %= animationPeriod
	$DifficultyLabel.texture = textures[_index]
	update_arrows()
