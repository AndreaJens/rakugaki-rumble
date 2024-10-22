class_name RematchMenu extends Node2D

enum StateVars {
	Index = 0,
	LastInputPressed = 1,
	AnimationTicks = 2,
	ZoomTicks = 5,
	SelectedOption = 3,
	Visible = 4
}

enum Option {
	Yes,
	No
}

var _index : int = 0
var _lastInputReceived : int = 0
@export var _options : Array[Option] = [Option.Yes, Option.No]
@export var _optionSprites : Array[Sprite2D] = []
var _animationTicks : int = 0
var _zoomTicks : int = 0
var _optionSelected : bool = false
const animationPeriod : int = 20
@export_category("Sounds")
@export var confirmSound : AudioStream
@export var cancelSound : AudioStream
@export var cursorSound : AudioStream
@export var audioPlayer : AudioStreamPlayer

func play_confirm_sound():
	if audioPlayer and confirmSound:
		audioPlayer.stream = confirmSound
		audioPlayer.volume_db = GlobalOptions.get_sfx_volume()
		audioPlayer.play()
		
func play_cursor_sound():
	if audioPlayer and cursorSound:
		audioPlayer.stream = cursorSound
		audioPlayer.volume_db = GlobalOptions.get_sfx_volume()
		audioPlayer.play()

func play_cancel_sound():
	if audioPlayer and cancelSound:
		audioPlayer.stream = cancelSound
		audioPlayer.volume_db = GlobalOptions.get_sfx_volume()
		audioPlayer.play()

func reset_and_hide():
	_index = 0
	_lastInputReceived = 0
	_zoomTicks = 0
	_optionSelected = false
	visible = false

func _save_state() -> Dictionary:
	var dict = {}
	dict[StateVars.Index] = _index
	dict[StateVars.LastInputPressed] = _lastInputReceived
	#dict[StateVars.AnimationTicks] = _animationTicks
	dict[StateVars.SelectedOption] = _optionSelected
	dict[StateVars.Visible] = visible
	return dict

func _load_state(state : Dictionary) -> void:
	_index = state[StateVars.Index]
	_lastInputReceived = state[StateVars.LastInputPressed]
	#_animationTicks = state[StateVars.AnimationTicks]
	_optionSelected = state[StateVars.SelectedOption]
	visible = state[StateVars.Visible]
	
func _network_preprocess(_input: Dictionary) -> void:
	pass
	
func _update_highlighted_option():
	for sprite in _optionSprites:
		sprite.offset.x = 0
		sprite.scale = Vector2(1., 1.)
	if _zoomTicks > 0:
		_zoomTicks -= 1
		_optionSprites[_index].scale = Vector2(1.25, 1.25)
	else:
		_optionSprites[_index].scale = Vector2(1.1, 1.1)
	if !selection_performed():
		_optionSprites[_index].offset.x = -4
		@warning_ignore("integer_division")
		var animationPeriodHalf = animationPeriod / 2
		if _animationTicks > animationPeriodHalf:
			_optionSprites[_index].offset.x = 4

func selection_performed() -> bool:
	return _optionSelected

func get_highlighted_option() -> Option:
	return _options[_index]
	
func update(allButtonsPressed : int, newAnimationTicks : int):
	if !_optionSelected:
		if ((allButtonsPressed & ~_lastInputReceived) & GameDatabaseAccessor.GameInputButton.Down):
			_index += 1
			_index %= _options.size()
			_zoomTicks = 8
			play_cursor_sound()
		elif ((allButtonsPressed & ~_lastInputReceived) & GameDatabaseAccessor.GameInputButton.Up):
			_index -= 1
			_zoomTicks = 8
			if _index < 0: 
				_index = _options.size() - 1
			play_cursor_sound()
	if ((allButtonsPressed & ~_lastInputReceived) & GameDatabaseAccessor.GameInputButton.Confirm):
		_optionSelected = true
		play_confirm_sound()
	_lastInputReceived = allButtonsPressed
	_animationTicks = newAnimationTicks
	_animationTicks %= animationPeriod
	_update_highlighted_option()
# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group('network_sync')

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
