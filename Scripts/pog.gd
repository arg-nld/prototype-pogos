extends RigidBody2D

@onready var front: Sprite2D = $Front
@onready var back: Sprite2D = $Back

var face_up = true

func _ready():
	front.visible = true
	back.visible = false
