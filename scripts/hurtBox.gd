class_name HurtBox extends MoveBox

# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	super._process(delta)

func _save_state() -> Dictionary:
	return super._save_state() 

func _load_state(state: Dictionary) -> void:
	super._load_state(state)
