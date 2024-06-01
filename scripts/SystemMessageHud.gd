class_name SystemMessageHud extends Control
@export var koTexture : Texture2D
@export var readyTexture : Texture2D
@export var engageTexture : Texture2D
@export var matchpointTexture : Texture2D
@export var systemMessageSprite : Sprite2D
@export var plasticFoilSprite : Sprite2D
@export var animationPixelsPerTick : int

var _messageToTexture = {}
var _currentMessageType = HudManager.SystemMessage.Ko
var _position_tick = 0
var _message_visible = false
var _enter_screen = false
var _exit_screen = false

enum SystemMessageVar{
	CurrentMessageType = 0,
	PositionTick = 1,
	MessageVisible = 2,
	EnterScreen = 3,
	ExitScreen = 4
}

func _save_state() -> Dictionary:
	return {
		SystemMessageVar.CurrentMessageType : _currentMessageType,
		SystemMessageVar.PositionTick : _position_tick,
		SystemMessageVar.MessageVisible : _message_visible,
		SystemMessageVar.EnterScreen : _enter_screen,
		SystemMessageVar.ExitScreen : _exit_screen
	}
	
func _load_state(state : Dictionary) -> void:
	_position_tick = state[SystemMessageVar.PositionTick]
	_currentMessageType = state[SystemMessageVar.CurrentMessageType]
	if state[SystemMessageVar.MessageVisible]:
		plasticFoilSprite.visible = true
		systemMessageSprite.visible = true
	plasticFoilSprite.position.y = _position_tick
	systemMessageSprite.texture = _messageToTexture[_currentMessageType]
	_enter_screen = state[SystemMessageVar.EnterScreen]
	_exit_screen = state[SystemMessageVar.ExitScreen]

# Called when the node enters the scene tree for the first time.
func _ready():
	_messageToTexture = {
		HudManager.SystemMessage.Ko : koTexture,
		HudManager.SystemMessage.Ready : readyTexture,
		HudManager.SystemMessage.Engage : engageTexture,
		HudManager.SystemMessage.Matchpoint : matchpointTexture,
	}
	add_to_group('network_sync')
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _network_process(_input : Dictionary) -> void:
	pass

func update():
	if _position_tick <= 0 and _enter_screen:
		_position_tick += animationPixelsPerTick
		if _position_tick >= 0:
			_position_tick = 0
			_enter_screen = false
	elif _position_tick > -plasticFoilSprite.texture.get_size().y and _exit_screen:
		_position_tick -= animationPixelsPerTick
		if _position_tick <= -plasticFoilSprite.texture.get_size().y:
			_position_tick = -plasticFoilSprite.texture.get_size().y
			_exit_screen = false
			disable_message()
	plasticFoilSprite.position.y = _position_tick

func show_message(type : HudManager.SystemMessage):
	_enter_screen = true
	_exit_screen = false
	plasticFoilSprite.visible = true
	systemMessageSprite.visible = true
	_currentMessageType = type
	_message_visible = true
	_position_tick = -plasticFoilSprite.texture.get_size().y
	systemMessageSprite.texture = _messageToTexture[type]

func hide_message():
	_exit_screen = true
	_enter_screen = false
	_position_tick = 0

func disable_message():
	_message_visible = false
	_exit_screen = false
	_enter_screen = false
	plasticFoilSprite.visible = false
	systemMessageSprite.visible = false

func inactive():
	return !_message_visible
