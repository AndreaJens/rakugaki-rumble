class_name CpuOpponentRule extends Resource

enum ConditionTrigger {
	Always = 0,
	TotalDistanceFromOpponent = 1,
	HorizontalDistanceFromOpponent = 2,
	VerticalDistanceFromOpponent = 3,
	NumOfRoundsLost = 4,
	NumOfRoundsWon = 5,
	TimerTickes = 6,
	CurrentMoveName = 7,
	HasHitOpponent = 8,
	DistanceFromWall = 9,
	OpponentDistanceFromWall = 10,
	IsInHitstun = 11,
	CpuLevel = 12,
	Health = 13,
	OpponentHealth = 14,
	Meter = 15,
	OpponentMeter = 16,
	Airborne = 17,
	OpponentAirborne = 18,
	OpponentInHitStun = 19,
	InfinityInstall = 20,
	OpponentInfinityInstall = 21,
	ZeroInstall = 22,
	OpponentZeroInstall = 23
}

enum ConditionComparison {
	None = -1,
	Equal = 0,
	Different = 1,
	GreaterThan = 2,
	GreaterThanOrEqual = 3,
	LowerThan = 4,
	LowerThanOrEqual = 5
}

@export var trigger : ConditionTrigger = ConditionTrigger.Always
@export var operator : ConditionComparison = ConditionComparison.None
@export var valueInt : int = 0
@export var valueString : String = ""

