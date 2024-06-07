class_name MoveBox extends Node2D

@export var active : bool = false
	#get:
		#return active
	#set( value ):
		#if !active and value == true and self is HurtBox:
			#print("Box was set to active")
		#active = value
@export var boxSize : Rect2i = Rect2i(0,0,100000,100000)
@onready var box : Sprite2D = $Box
var _mirrored : bool = false

enum BoxStateVars {
	Box = 0,
	Active = 1,
	Mirrored = 2
}

func _save_state() -> Dictionary:
	return {
		BoxStateVars.Box : boxSize,
		BoxStateVars.Active : active,
		BoxStateVars.Mirrored : _mirrored
	}

func _load_state(state: Dictionary) -> void:
	boxSize = state[BoxStateVars.Box]
	active = state[BoxStateVars.Active]
	_mirrored = state[BoxStateVars.Mirrored]
	resize_box()

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group('network_sync')
	pass # Replace with function body.
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	box.visible = visible
	resize_box()
	
func _network_process(_input: Dictionary) -> void:
	_process(0)

func resize_box():
	box.position = boxSize.position / GameDatabaseAccessor.screenCoordMultiplier
	box.region_rect.size = boxSize.size / GameDatabaseAccessor.screenCoordMultiplier
	#if _mirrored:
		#box.position.x = -box.position.x

func get_box() -> Rect2i:
	var pos = boxSize.position
	if _mirrored:
		pos.x = -pos.x
	return Rect2i(pos, boxSize.size)

func mirror():
	#boxSize.position.x = -boxSize.position.x
	_mirrored = !_mirrored
	#resize_box()
	
func is_mirrored() -> bool:
	return _mirrored
