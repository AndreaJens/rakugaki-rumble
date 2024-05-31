class_name CollisionManager extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
	
func distance_from_left_corner(character : Character, stage : Stage) -> int:
	var pushboxChar : Rect2i = character.get_collision_box_top_left()
	@warning_ignore("integer_division")
	var leftBoundary = stage.logicalPosition.x - stage.logicalSize.x / 2
	var leftDistance = pushboxChar.position.x - leftBoundary
	return leftDistance

func distance_from_right_corner(character : Character, stage : Stage) -> int:
	var pushboxChar : Rect2i = character.get_collision_box_top_left()
	@warning_ignore("integer_division")
	var rightBoundary = stage.logicalPosition.x + stage.logicalSize.x / 2
	var rightDistance = rightBoundary - pushboxChar.position.x - pushboxChar.size.x
	return rightDistance
	
func handle_left_character_collision(leftChar : Character, rightChar : Character, 
		stage : Stage, intersection : Rect2i):
	var logicalPositionC1 = leftChar.get_logical_position()
	var logicalPositionC2 = rightChar.get_logical_position()
	var logicalVelocityC1 = leftChar.get_logical_velocity()
	var logicalVelocityC2 = rightChar.get_logical_velocity()
	if logicalVelocityC1.x > 0 and logicalVelocityC2.x <= 0:
		if abs(logicalVelocityC1.x) > abs(logicalVelocityC2.x):
			var distance_r = distance_from_right_corner(rightChar, stage)
			if (distance_r < intersection.size.x):
				logicalPositionC2.x += distance_r
				logicalPositionC1.x -= intersection.size.x - distance_r
			else:
				logicalPositionC2.x += intersection.size.x
		elif abs(logicalVelocityC1.x) == abs(logicalVelocityC2.x):
			var distance_l = distance_from_left_corner(leftChar, stage)
			var distance_r = distance_from_right_corner(rightChar, stage)
			if (distance_l < intersection.size.x):
				logicalPositionC2.x += intersection.size.x - distance_l
				logicalPositionC1.x -= distance_l
			elif (distance_r < intersection.size.x):
				logicalPositionC2.x += distance_r
				logicalPositionC1.x -= intersection.size.x - distance_r
			else:
				@warning_ignore("integer_division")
				logicalPositionC1.x  -= intersection.size.x / 2
				@warning_ignore("integer_division")
				logicalPositionC2.x  += intersection.size.x / 2
		else:
			var distance_l = distance_from_left_corner(leftChar, stage)
			if (distance_l < intersection.size.x):
				logicalPositionC2.x += intersection.size.x - distance_l
				logicalPositionC1.x -= distance_l
			else:
				logicalPositionC1.x -= intersection.size.x
	elif logicalVelocityC2.x <= 0:
		var distance_l = distance_from_left_corner(leftChar, stage)
		var distance_r = distance_from_right_corner(rightChar, stage)
		if (distance_l < intersection.size.x):
			logicalPositionC2.x += intersection.size.x - distance_l
			logicalPositionC1.x -= distance_l
		elif (distance_r < intersection.size.x):
			logicalPositionC2.x += distance_r
			logicalPositionC1.x -= intersection.size.x - distance_r
		else:
			@warning_ignore("integer_division")
			logicalPositionC1.x  -= intersection.size.x / 2
			@warning_ignore("integer_division")
			logicalPositionC2.x  += intersection.size.x / 2
	else:
		@warning_ignore("integer_division")
		logicalPositionC1.x  -= intersection.size.x / 2
		@warning_ignore("integer_division")
		logicalPositionC2.x  += intersection.size.x / 2
	leftChar.set_new_logical_position(logicalPositionC1)
	rightChar.set_new_logical_position(logicalPositionC2)

func update_character_position_on_collision(
	character1 : Character, 
	character2 : Character,
	stage : Stage
	):
	if !character1.pushbox_is_active() or !character2.pushbox_is_active():
		return
	var pushboxChar1 : Rect2i = character1.get_collision_box_top_left()
	var pushboxChar2 : Rect2i = character2.get_collision_box_top_left()
	if !pushboxChar1.intersects(pushboxChar2):
		return
	var intersection : Rect2i = pushboxChar1.intersection(pushboxChar2)
	if (pushboxChar1.position.x < intersection.position.x):
		handle_left_character_collision(character1, character2, stage, intersection)
	elif (pushboxChar2.position.x < intersection.position.x):
		handle_left_character_collision(character2, character1, stage, intersection)
	
