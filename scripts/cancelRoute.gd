class_name MoveCancelRoute extends Resource

@export var targetMoveName : String
@export var startFrame : int = 0
@export var endFrame : int = 0
@export var onHit : bool = true
@export var onBlock : bool = true
@export var onWhiff : bool = true
@export var automaticCancelOnLanding : bool = false
@export var activeIfNothingPressed : bool = false
@export var autoCancelWhenValid : bool = false
@export var autoPerformAtMoveEnd : bool = false

func is_valid(currentFrame : int) -> bool:
	var flag : bool = (currentFrame >= startFrame and (currentFrame <= endFrame or endFrame < 0))
	return flag

