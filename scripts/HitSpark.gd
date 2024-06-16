class_name HitSpark extends Node2D

@export var defaultDurationFrames = 20
@export var networkMode : bool = false
var _durationTicks = 0
var _logicalPosition = Vector2i(0, 0)
var _localPause = false
@onready var _animPlayer : AnimationPlayer = $AnimationPlayer


enum HitSparkVars {
	Position = 0,
	Visible = 1,
	DurationTicks = 2,
}

func _save_state() -> Dictionary:
	return {
		HitSparkVars.Position : _logicalPosition,
		HitSparkVars.Visible : visible,
		HitSparkVars.DurationTicks : _durationTicks
	}

func _load_state(state: Dictionary) -> void:
	_logicalPosition = state[HitSparkVars.Position]
	visible = state[HitSparkVars.Visible]
	_durationTicks = state[HitSparkVars.DurationTicks]
# Called when the node enters the scene tree for the first time.
func _ready():
	_durationTicks = 0
	visible = false
	add_to_group('network_sync')

func update():
	if visible and _durationTicks > 0:
		_durationTicks -= 1
		if _durationTicks <= 0:
			visible = false
			_animPlayer.stop()
	if !visible and _animPlayer.is_playing():
		_animPlayer.stop()
	position = _logicalPosition / GameDatabaseAccessor.screenCoordMultiplier

func activate_hitspark(newLogicalPosition : Vector2i):
	_animPlayer.stop()
	_logicalPosition = newLogicalPosition
	_durationTicks = defaultDurationFrames
	visible = true
	_animPlayer.play("hitspark")

func deactivate_hitspark():
	_animPlayer.stop()
	visible = false
	_durationTicks = 0
	
func pause_hitspark():
	_localPause = true

func unpause_hitspark():
	_localPause = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if !networkMode and _animPlayer.is_playing() and !_localPause:
		_animPlayer.advance(1. / GameDatabaseAccessor.frameRateFps)
	
func _network_process(_delta):
	pass
