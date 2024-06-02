class_name GenericMenu extends Node2D

enum StateVars {
	Index = 0,
	LastInputPressed = 1,
	AnimationTicks = 2,
	SelectedOption = 3
}

var _index : int = 0
var _lastInputReceived : int = 0
@export var options : Array[int] = []
@export var _optionSprites : Array[Sprite2D] = []
var _animationTicks : int = 0
var _optionSelected : bool = 0
const animationPeriod : int = 20

func reset_and_hide():
	_index = 0
	_lastInputReceived = 0
	_optionSelected = false
	visible = false

func _save_state() -> Dictionary:
	var dict = {}
	dict[StateVars.Index] = _index
	dict[StateVars.LastInputPressed] = _lastInputReceived
	dict[StateVars.AnimationTicks] = _animationTicks
	dict[StateVars.SelectedOption] = _optionSelected
	return dict

func _load_state(state : Dictionary) -> void:
	_index = state[StateVars.Index]
	_lastInputReceived = state[StateVars.LastInputPressed]
	_animationTicks = state[StateVars.AnimationTicks]
	_optionSelected = state[StateVars.SelectedOption]
	
func _network_preprocess(_input: Dictionary) -> void:
	pass
	
func _update_highlighted_option():
	for sprite in _optionSprites:
		sprite.offset.x = 0
		sprite.scale = Vector2(1., 1.)
	_optionSprites[_index].scale = Vector2(1.1, 1.1)
	if !selection_performed():
		_optionSprites[_index].offset.x = -4
		@warning_ignore("integer_division")
		var animationPeriodHalf = animationPeriod / 2
		if _animationTicks > animationPeriodHalf:
			_optionSprites[_index].offset.x = 4

func selection_performed() -> bool:
	return _optionSelected

func get_highlighted_option() -> int:
	return options[_index]
	
func update(allButtonsPressed : int):
	if !_optionSelected:
		if ((allButtonsPressed & ~_lastInputReceived) & GameDatabaseAccessor.GameInputButton.Down):
			_index += 1
			_index %= options.size()
		elif ((allButtonsPressed & ~_lastInputReceived) & GameDatabaseAccessor.GameInputButton.Up):
			_index -= 1
			if _index < 0: _index = options.size() - 1
	if ((allButtonsPressed & ~_lastInputReceived) & GameDatabaseAccessor.GameInputButton.Confirm):
		_optionSelected = true
	_lastInputReceived = allButtonsPressed
	_animationTicks += 1
	_animationTicks %= animationPeriod
	_update_highlighted_option()
# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group('network_sync')

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
