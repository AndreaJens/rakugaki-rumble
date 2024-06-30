class_name HorizontalGenericMenu extends Node2D

@export var textures : Array[Texture2D]
@export var options : Array[int] = []
@export var leftArrow : Sprite2D
@export var rightArrow : Sprite2D
@export var valueLabel : Sprite2D

var _index : int = 0
var _animationTicks : int = 0
var _zoomTicks : int = 0
var _lastInputReceived : GameDatabaseAccessor.GameInputButton = GameDatabaseAccessor.GameInputButton.None
var active : bool = true
const animationPeriod : int = 20
@export var loopOptions : bool = false
@export_category("Sounds")
@export var cursorSound : AudioStream
@export var audioPlayer : AudioStreamPlayer
	
func set_index_by_value(value : int) -> bool:
	for i in range(0, options.size()):
		if options[i] == value:
			_index = i
			valueLabel.texture = textures[_index]
			update_arrows()
			return true
	valueLabel.texture = textures[_index]
	update_arrows()
	return false
	
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
	leftArrow.offset.x = offsetVal
	rightArrow.offset.x = -offsetVal
	leftArrow.visible = loopOptions or _index > 0
	rightArrow.visible = loopOptions or _index < options.size() -1
	return
	
func update(allButtonsPressed : int):
	if _zoomTicks > 0:
		valueLabel.scale.x = 1.2
		valueLabel.scale.y = 1.2
		_zoomTicks -= 1
	else:
		valueLabel.scale.x = 1.0
		valueLabel.scale.y = 1.0
	if active and visible:
		if ((allButtonsPressed & ~_lastInputReceived) & GameDatabaseAccessor.GameInputButton.Right):
			if loopOptions or _index < options.size() -1:
				_index += 1
				_index %= options.size()
				_zoomTicks = 8
				play_cursor_sound()
		elif ((allButtonsPressed & ~_lastInputReceived) & GameDatabaseAccessor.GameInputButton.Left):
			if loopOptions or _index > 0:
				_index -= 1
				if _index < 0: _index = options.size() - 1
				_zoomTicks = 8
				play_cursor_sound()
	@warning_ignore("int_as_enum_without_cast")
	_lastInputReceived = allButtonsPressed
	_animationTicks += 1
	_animationTicks %= animationPeriod
	valueLabel.texture = textures[_index]
	update_arrows()
