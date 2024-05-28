extends Node

var focused := true
var inputManagers : Array[InputManager] = []
var rng = RandomNumberGenerator.new()

@export var player1DeviceId : int = -1
@export var player2DeviceId : int = -1

func _ready():
	rng.randomize()
	for i in range(0,12):
		inputManagers.push_back(InputManager.new())
		inputManagers[i].initialize(i)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			focused = false
		NOTIFICATION_APPLICATION_FOCUS_IN:
			focused = true
		NOTIFICATION_PREDELETE:
			for manager in inputManagers:
				manager.queue_free()
			inputManagers.clear()
		NOTIFICATION_WM_CLOSE_REQUEST:
			get_tree().quit() 

func input_is_action_pressed_kb(action: StringName) -> bool:
	if focused:
		return Input.is_action_pressed(action)
	return false

func input_is_action_just_pressed_kb(action: StringName) -> bool:
	if focused:
		return Input.is_action_just_pressed(action)
	return false
	
func input_is_action_just_released_kb(action: StringName) -> bool:
	if focused:
		return Input.is_action_just_released(action)
	return false

func input_is_action_pressed(action: StringName, deviceId : int) -> bool:
	if inputManagers.size() <= deviceId or deviceId < 0:
		return false
	if focused:
		return inputManagers[deviceId].is_action_pressed(action)
	return false

func input_is_action_just_pressed(action: StringName, deviceId : int) -> bool:
	if inputManagers.size() <= deviceId or deviceId < 0:
		return false
	if focused:
		return inputManagers[deviceId].is_action_just_pressed(action)
	return false

func input_is_action_just_released(action: StringName, deviceId : int) -> bool:
	if inputManagers.size() <= deviceId or deviceId < 0:
		return false
	if focused:
		return inputManagers[deviceId].is_action_just_released(action)
	return false

func event_is_action_pressed(event: InputEvent, action: StringName) -> bool:
	if focused:
		if event.device >= 0:
			if inputManagers.size() <= event.device:
				return false
			return inputManagers[event.device].is_action_pressed(action)
		else:
			return Input.is_action_pressed(action)
	return false
