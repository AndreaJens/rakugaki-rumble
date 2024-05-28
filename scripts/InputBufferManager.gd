class_name InputBufferManager extends Node

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
}

var _actionDict : Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	for key in _baseActionDict:
		_actionDict[key + "_" + playerIdentifier] = _baseActionDict[key]


func _process(_delta):
	pass
	
func update_buffer():
	var currentInput : int = 0
	var allPressedButtons : int = 0
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
	_buffer.push_back(currentInput)
	_rawBuffer.push_back(allPressedButtons)
	if _buffer.size() > maxBufferSize:
		_buffer.pop_front()
		_rawBuffer.pop_front()
	_pressedButtons = allPressedButtons

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
