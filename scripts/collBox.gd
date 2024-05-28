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

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	box.visible = visible
	resize_box()

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
	resize_box()
	
func is_mirrored() -> bool:
	return _mirrored
