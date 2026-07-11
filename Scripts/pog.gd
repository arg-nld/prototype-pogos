extends RigidBody2D

@onready var front: Sprite2D = $Front
@onready var back: Sprite2D = $Back

var face_up = true
var spin_speed = .05

func _ready():
	front.visible = true
	back.visible = false

func flip():
	var tween = create_tween()
	tween.set_loops(randi_range(3, 6))
	
	if face_up:
		tween.tween_property(front, "scale", Vector2(1, 0), spin_speed)
		
		tween.tween_callback(func():
			front.visible = false
			back.visible = true
		)
		
		tween.tween_property(back, "scale", Vector2(1, 1), spin_speed)
	else:
		tween.tween_property(back, "scale", Vector2(1, 0), spin_speed)
		
		tween.tween_callback(func():
			back.visible = false
			front.visible = true
		)
		
		tween.tween_property(front, "scale", Vector2(1, 1), spin_speed)
	
	await tween.finished
	face_up = !face_up
