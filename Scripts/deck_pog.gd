extends Area2D
signal selection_change

var selected = false
var start_position: Vector2

func _ready():
	start_position = position

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			toggle()

func toggle():
	selected = !selected
	
	if selected:
		position.y = start_position.y - 20
	else:
		position = start_position
	
	selection_change.emit()
