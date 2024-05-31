extends Node

enum GameInputButton{
	None = 0,
	# directions
	Down = 1 << 0,
	Up = 1 << 1,
	Right = 1 << 2,
	Left = 1 << 3,
	# diagonals / composite directions
	UpLeft = Up | Left,
	UpRight = Up | Right,
	DownLeft = Down | Left,
	DownRight = Down | Right,
	# basic buttons
	Action1 = 1 << 4,
	Action2 = 1 << 5,
	Action3 = 1 << 6,
	Action4 = 1 << 7,
	Action5 = 1 << 8,
	# action 1 plus directionals
	#DownAction1 = Down | Action1,
	#UpAction1 = Up | Action1,
	#LeftAction1 = Left | Action1,
	#RightAction1 = Right | Action1,
	#DownLeftAction1 = DownLeft | Action1,
	#DownRightAction1 = DownRight | Action1,
	#UpLeftAction1 = UpLeft | Action1,
	#UpRightAction1 = UpRight | Action1,
	## action 2 plus directionals
	#DownAction2 = Down | Action2,
	#UpAction2 = Up | Action2,
	#LeftAction2 = Left | Action2,
	#RightAction2 = Right | Action2,
	#DownLeftAction2 = DownLeft | Action2,
	#DownRightAction2 = DownRight | Action2,
	#UpLeftAction2 = UpLeft | Action2,
	#UpRightAction2 = UpRight | Action2,
	## action 3 plus directionals
	#DownAction3 = Down | Action3,
	#UpAction3 = Up | Action3,
	#LeftAction3 = Left | Action3,
	#RightAction3 = Right | Action3,
	#DownLeftAction3 = DownLeft | Action3,
	#DownRightAction3 = DownRight | Action3,
	#UpLeftAction3 = UpLeft | Action3,
	#UpRightAction3 = UpRight | Action3,
	## action 4 plus directionals
	#DownAction4 = Down | Action4,
	#UpAction4 = Up | Action4,
	#LeftAction4 = Left | Action4,
	#RightAction4 = Right | Action4,
	#DownLeftAction4 = DownLeft | Action4,
	#DownRightAction4 = DownRight | Action4,
	#UpLeftAction4 = UpLeft | Action4,
	#UpRightAction4 = UpRight | Action4,
	## action 5 plus directionals
	#DownAction5 = Down | Action5,
	#UpAction5 = Up | Action5,
	#LeftAction5 = Left | Action5,
	#RightAction5 = Right | Action5,
	#DownLeftAction5 = DownLeft | Action5,
	#DownRightAction5 = DownRight | Action5,
	#UpLeftAction5 = UpLeft | Action5,
	#UpRightAction5 = UpRight | Action5,
	# all buttons of a kind
	AnyAction = Action1 | Action2 | Action3 | Action4 | Action5,
	AnyDirection = Up | Down | Left | Right,
	AnyActionOrDirection = AnyAction | AnyDirection,
	# released buttons
	ReleaseBitShiftModifier = 10,
	ReleaseDown = Down << ReleaseBitShiftModifier,
	ReleaseUp   = Up << ReleaseBitShiftModifier,
	ReleaseRight = Right << ReleaseBitShiftModifier,
	ReleaseLeft = Left << ReleaseBitShiftModifier,
	ReleaseAction1 = Action1 << ReleaseBitShiftModifier,
	ReleaseAction2 = Action2 << ReleaseBitShiftModifier,
	ReleaseAction3 = Action3 << ReleaseBitShiftModifier,
	ReleaseAction4 = Action4 << ReleaseBitShiftModifier,
	ReleaseAction5 = Action5 << ReleaseBitShiftModifier,
	# menu stuff
	Confirm = 1 << 20,
	Cancel =  1 << 21,
	AllMenuButtons = Confirm | Cancel
}

enum AttackType {
	None = 0,
	Grounded = 1,
	AntiAir = 2,
	Aerial = 3,
	OTG = 4,
	Grab = 5
}

@export var frameRateFps : int = 60
@export var screenCoordMultiplier : float = 1000.0
@export var screenCoordMultiplierInt : int = 1000
@export var showBoxes : bool = false
@export var player1Device : int = -1
@export var player2Device : int = -1
@export var defaultGroundHitReaction : String = "hurtG"
@export var defaultAirHitReaction : String = "hurtA"
@export var defaultWallsplatReaction : String = "wallsplat"
@export var defaultInstallDurationTicks : int = 300
@export var defaultMaxNumberOfBounces : int = 2
@export var characterAbsVelocityCapX : int = 1000000


