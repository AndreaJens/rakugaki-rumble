class_name HitBox extends MoveBox

var HitReactionDict : Dictionary = {
	0 : GameDatabaseAccessor.defaultGroundHitReaction,
	1 : GameDatabaseAccessor.defaultAirHitReaction,
	2 : GameDatabaseAccessor.defaultDownSpikeReaction,
}

enum HitboxStateVars {
	Damage = 1000,
	HitReactionGroundCode = 1001,
	HitReactionAirCode = 1002,
	InactiveOnHit = 1003,
	MeterGain = 1004
}

@export var attackType : GameDatabaseAccessor.AttackType = GameDatabaseAccessor.AttackType.None
@export var moveReactionOnHitGround : String = GameDatabaseAccessor.defaultGroundHitReaction
@export var moveReactionOnHitAir : String = GameDatabaseAccessor.defaultAirHitReaction
@export var hitReactionGroundCode : int = 0
@export var hitReactionAirCode : int = 1
@export var damage : int = 0
@export var meterGain : int = 3000
@export var canBeBlocked : bool = true
@export var chipDamageOnBlock : int = 0
@export var meterGainOnBlock : int = 0
@export var canHitKnockedDownOpponents : bool = false
@export var deactivateOnHit : bool = true
@export var affectedByScaling : bool = true
@export var minimumScalingPercent : int = 10
@export var minimumAttackDamage : int = 1

func _save_state() -> Dictionary:
	return {
		MoveBox.BoxStateVars.Box : boxSize,
		MoveBox.BoxStateVars.Active : active,
		MoveBox.BoxStateVars.Mirrored : _mirrored,
		HitboxStateVars.Damage : damage,
		HitboxStateVars.HitReactionGroundCode : hitReactionGroundCode,
		HitboxStateVars.HitReactionAirCode : hitReactionAirCode,
		HitboxStateVars.InactiveOnHit : deactivateOnHit,
		HitboxStateVars.MeterGain : meterGain,
	}

func _load_state(state: Dictionary) -> void:
	boxSize = state[MoveBox.BoxStateVars.Box]
	active = state[MoveBox.BoxStateVars.Active]
	_mirrored = state[MoveBox.BoxStateVars.Mirrored]
	damage = state[HitboxStateVars.Damage]
	hitReactionGroundCode = state[HitboxStateVars.HitReactionGroundCode]
	hitReactionAirCode = state[HitboxStateVars.HitReactionAirCode]
	deactivateOnHit = state[HitboxStateVars.InactiveOnHit]
	meterGain = state[HitboxStateVars.MeterGain]
	super.resize_box()

# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	super._process(delta)
