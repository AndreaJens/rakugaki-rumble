class_name InputManager extends Node

var _device : int
var _suffix : String

var _baseActionDict : Dictionary = {
	"move_u" : GameDatabaseAccessor.GameInputButton.Up,
	"move_d" : GameDatabaseAccessor.GameInputButton.Down,
	"move_l" : GameDatabaseAccessor.GameInputButton.Left,
	"move_r" : GameDatabaseAccessor.GameInputButton.Right,
	"attack1" : GameDatabaseAccessor.GameInputButton.Action1,
	"attack2" : GameDatabaseAccessor.GameInputButton.Action2,
	"confirm" : GameDatabaseAccessor.GameInputButton.Confirm,
	"cancel" : GameDatabaseAccessor.GameInputButton.Cancel,
}
var _actionsToDuplicate : Array[String] = []
var _deviceActionDict : Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
		
func initialize(device: int):
	if device == -1:
		push_error("Cannot set up DeviceInput for all devices")
		return
	
	_actionsToDuplicate = []
	for key in _baseActionDict:
		_actionsToDuplicate.push_back(key)
	
	_device = device
	_suffix = "_device_%d" % device
	
	# Find all controller inputs, and add new actions that are device-specific
	for base_action in InputMap.get_actions():
		_deviceActionDict[base_action] = base_action + _suffix
		# Ensure the action hasn't already been added in another scene
		if not base_action.ends_with(_suffix) and _actionsToDuplicate.has(base_action):
			_duplicate_action(base_action)
			
func _duplicate_action(base_action: String):
	var new_action = base_action + _suffix
	for event in InputMap.action_get_events(base_action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			if not InputMap.has_action(new_action):
				var base_deadzone = InputMap.action_get_deadzone(base_action)
				InputMap.add_action(new_action, base_deadzone)
			
			var new_event = event.duplicate()
			new_event.device = _device
			
			InputMap.action_add_event(new_action, new_event)
			
func is_action_pressed(action: String) -> bool:
	return Input.is_action_pressed(_deviceActionDict[action])

func is_action_just_pressed(action: String) -> bool:
	return Input.is_action_just_pressed(_deviceActionDict[action])
	
func is_action_just_released(action: String) -> bool:
	return Input.is_action_just_released(_deviceActionDict[action])

func get_action_strength(action: String) -> float:
	return Input.get_action_strength(_deviceActionDict[action])

func get_mapped_action(action: String) -> String:
	return _deviceActionDict[action]

# Called every frame. 'delta' is the elapsed time since the previous frame.

