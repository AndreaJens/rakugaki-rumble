class_name InputBufferManager extends Node

enum InputBufferState {
	AllPressedButtons = 0,
	NewlyPressedButtons = 4,
	RawBuffer = 1,
	RefinedBuffer = 2,
}

@export var playerIdentifier : String = "p1"
@export var maxBufferSize : int = 50
@export var deviceId : int = -1
var _buffer : Array[int]
var _rawBuffer : Array[int]
var _pressedButtons : int

var _baseActionDict : Dictionary = {
	"move_u" : GameDatabaseAccessor.GameInputButton.Up,
	"move_d" : GameDatabaseAccessor.GameInputButton.Down,
	"move_l" : GameDatabaseAccessor.GameInputButton.Left,
	"move_r" : GameDatabaseAccessor.GameInputButton.Right,
	"attack1" : GameDatabaseAccessor.GameInputButton.Action1,
	"attack2" : GameDatabaseAccessor.GameInputButton.Action2,
}

var _actionDict : Dictionary = {}

# SNOPEK FUNCTIONS

func _save_state() -> Dictionary:
	var dict = {}
	dict[InputBufferState.AllPressedButtons] = _pressedButtons
	dict[InputBufferState.RawBuffer] = _rawBuffer.duplicate()
	dict[InputBufferState.RefinedBuffer] = _buffer.duplicate()
	return dict

func _load_state(state : Dictionary) -> void:
	_pressedButtons = state[InputBufferState.AllPressedButtons]
	_rawBuffer.clear()
	_rawBuffer = state[InputBufferState.RawBuffer].duplicate()
	_buffer.duplicate()
	_buffer = state[InputBufferState.RefinedBuffer].duplicate()
	
func _get_local_input() -> Dictionary:
	return _readout_buttons()
	
func _network_preprocess(input: Dictionary) -> void:
	var currentInput : int = input[InputBufferState.NewlyPressedButtons]
	var allPressedButtons : int = input[InputBufferState.AllPressedButtons]
	_process_new_input(currentInput, allPressedButtons)
	
# Called when the node enters the scene tree for the first time.
func _ready():
	for key in _baseActionDict:
		_actionDict[key + "_" + playerIdentifier] = _baseActionDict[key]
	add_to_group('network_sync')

func _process(_delta):
	pass

func _readout_buttons() -> Dictionary:
	var currentInput : int = 0
	var allPressedButtons : int = 0
	# ANALOG STICKS FIRST
	#if deviceId >= 0:
		#if (InputOverseer.input_get_axis_value(deviceId, JOY_AXIS_LEFT_X) >= 0.5):
			#allPressedButtons |= GameDatabaseAccessor.GameInputButton.Right
			#currentInput |= GameDatabaseAccessor.GameInputButton.Right
		#elif (InputOverseer.input_get_axis_value(deviceId, JOY_AXIS_LEFT_X) <= -0.5):
			#allPressedButtons |= GameDatabaseAccessor.GameInputButton.Left
			#currentInput |= GameDatabaseAccessor.GameInputButton.Left
		#if (InputOverseer.input_get_axis_value(deviceId, JOY_AXIS_LEFT_Y) >= 0.5):
			#allPressedButtons |= GameDatabaseAccessor.GameInputButton.Up
			#currentInput |= GameDatabaseAccessor.GameInputButton.Up
		#elif (InputOverseer.input_get_axis_value(deviceId, JOY_AXIS_LEFT_Y) <= -0.5):
			#allPressedButtons |= GameDatabaseAccessor.GameInputButton.Down
			#currentInput |= GameDatabaseAccessor.GameInputButton.Down
		
	for key in _actionDict:
		if (_actionDict[key] & GameDatabaseAccessor.GameInputButton.AnyDirection):
			if InputOverseer.input_is_action_pressed_kb(key):
				allPressedButtons |= _actionDict[key]
				currentInput |= _actionDict[key]
			elif InputOverseer.input_is_action_just_released_kb(key):
				currentInput |= _actionDict[key] <<  GameDatabaseAccessor.GameInputButton.ReleaseBitShiftModifier
		else:
			if InputOverseer.input_is_action_pressed_kb(key):
				allPressedButtons |= _actionDict[key]
			if InputOverseer.input_is_action_just_pressed_kb(key):
				currentInput |= _actionDict[key]
			elif InputOverseer.input_is_action_just_released_kb(key):
				currentInput |= _actionDict[key] <<  GameDatabaseAccessor.GameInputButton.ReleaseBitShiftModifier
	if deviceId >= 0:
		for key in _baseActionDict:
			if (_baseActionDict[key] & GameDatabaseAccessor.GameInputButton.AnyDirection):
				if InputOverseer.input_is_action_pressed(key, deviceId):
					allPressedButtons |= _baseActionDict[key]
					currentInput |= _baseActionDict[key]	
				elif InputOverseer.input_is_action_just_released(key, deviceId):
					currentInput |= _baseActionDict[key] <<  GameDatabaseAccessor.GameInputButton.ReleaseBitShiftModifier
			else:
				if InputOverseer.input_is_action_pressed(key, deviceId):
					allPressedButtons |= _baseActionDict[key]
				if InputOverseer.input_is_action_just_pressed(key, deviceId):
					currentInput |= _baseActionDict[key]
				elif InputOverseer.input_is_action_just_released(key, deviceId):
					currentInput |= _baseActionDict[key] <<  GameDatabaseAccessor.GameInputButton.ReleaseBitShiftModifier
	var outInput = {}
	outInput[InputBufferState.AllPressedButtons] = allPressedButtons
	outInput[InputBufferState.NewlyPressedButtons] = currentInput
	return outInput

func _process_new_input(currentInput : int, allPressedButtons : int):
	_buffer.push_back(currentInput)
	_rawBuffer.push_back(allPressedButtons)
	if _buffer.size() > maxBufferSize:
		_buffer.pop_front()
		_rawBuffer.pop_front()
	_pressedButtons = allPressedButtons
	
func update_buffer():
	var newInput = _readout_buttons()
	var currentInput : int = newInput[InputBufferState.NewlyPressedButtons]
	var allPressedButtons : int = newInput[InputBufferState.AllPressedButtons]
	_process_new_input(currentInput, allPressedButtons)

func get_current_buffer() -> Array[int]:
	return _buffer

func get_current_raw_buffer() -> Array[int]:
	return _rawBuffer
	
func get_all_pressed_buttons() -> int:
	return _pressedButtons
	
func reset():
	_pressedButtons = 0
	_buffer.clear()
	_rawBuffer.clear()

