class_name CharacterProjectile extends Character

@export var deactivateOnHit : bool = true 
 
var _lifetimeTicks : int = -1 

enum ProjectileStateValues{
	Visible = 9000,
	LifetimeTicks = 9001
}
# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready() # Replace with function body.
	add_to_group('network_sync')

func activate(logicalPosition : Vector2i, leftSide : bool, maxLifetimeTicks : int):
	visible = true
	_lifetimeTicks = maxLifetimeTicks
	characterState.logicalPosition = logicalPosition
	characterState.onLeftSide = leftSide
	reset_character_to_idle_full_health()

func isInitialized() -> bool:
	return characterData != null

func isActive() -> bool:
	return isInitialized() and _lifetimeTicks > 0

func can_be_updated() -> bool:
	return super.can_be_updated() and isActive()

func deactivate():
	visible = false
	_lifetimeTicks = -1	

func _save_state() -> Dictionary:
	if !isInitialized():
		return {}
	var stateDict = characterState._save_state()
	stateDict[ProjectileStateValues.Visible] = visible
	stateDict[ProjectileStateValues.LifetimeTicks] = _lifetimeTicks
	return stateDict

func _load_state(state : Dictionary) -> void:
	if !isInitialized():
		return
	super._load_state(state)
	visible = state[ProjectileStateValues.Visible]
	_lifetimeTicks = state[ProjectileStateValues.LifetimeTicks]
	
#func _update_character_logical_position():
	#super._update_character_logical_position()
	#print("Proj position: %s" % characterState.logicalPosition)
#
#func update_screen_position():
	#super.update_screen_position()
	
func update( inputManager : InputBufferManager, extraInputLeniency : int = 0 ):
	if !isInitialized():
		return
	if can_be_updated():
		_lifetimeTicks -= 1
		if !isActive():
			deactivate()
	super.update(inputManager, extraInputLeniency)
