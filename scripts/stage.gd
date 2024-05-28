class_name Stage extends Node2D

@export var stageSize : Vector2i 
@export var characterOffset : Vector2i 
@export var stageTexture : Texture2D
var logicalPosition : Vector2i
var logicalSize : Vector2i
@onready var background : Sprite2D = $StageSprite


# Called when the node enters the scene tree for the first time.
func _ready():
	logicalSize = stageSize * GameDatabaseAccessor.screenCoordMultiplierInt
	background.texture = stageTexture
	update_stage_position()

func update_stage_position():
	var cameraViewportSize = get_viewport_rect().size
	@warning_ignore("integer_division")
	var deltaY : int = stageSize.y / 2 - cameraViewportSize.y / 2
	@warning_ignore("integer_division")
	position.x = stageSize.x / 2
	@warning_ignore("integer_division")
	position.y = stageSize.y / 2 - deltaY
	background.position = Vector2i(0, 0)
	logicalPosition = floor(position * GameDatabaseAccessor.screenCoordMultiplierInt)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
