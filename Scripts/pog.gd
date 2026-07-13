extends RigidBody2D

@onready var shadow: Sprite2D = $Shadow
@onready var front: Sprite2D = $Front
@onready var back: Sprite2D = $Back

var face_up = true
var spin_speed = 0.08

var sprite_scale: Vector2
var shadow_scale: Vector2

func _ready():
	sprite_scale = front.scale
	shadow_scale = shadow.scale
	
	front.visible = true
	back.visible = false

func start():
	jump()
	flip()

func jump():
	var tween = create_tween()
	
	tween.parallel().tween_property(self, "position:y", position.y - 15, 0.35)
	tween.parallel().tween_property(self, "scale", Vector2(1.08, 1.08), 0.35)
	tween.parallel().tween_property(shadow, "scale", shadow_scale * 0.8, 0.35)
	
	tween.parallel().tween_property(self, "position:y", position.y, 0.35)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.35)
	tween.parallel().tween_property(shadow, "scale", shadow_scale, 0.35)

func flip():
	var tween = create_tween()
	
	if face_up:
		tween.parallel().tween_property(shadow, "scale", shadow_scale * 0.8, spin_speed)
		tween.tween_property(front, "scale", Vector2(sprite_scale.x, 0), spin_speed)
		
		tween.tween_callback(func():
			front.visible = false
			back.visible = true
			back.scale = Vector2(sprite_scale.x, 0)
		)
		
		tween.parallel().tween_property(shadow, "scale", shadow_scale, spin_speed)
		tween.tween_property(back, "scale", sprite_scale, spin_speed)
		
		tween.parallel().tween_property(shadow, "scale", shadow_scale * 0.8, spin_speed)
		tween.tween_property(back, "scale", Vector2(sprite_scale.x, 0), spin_speed)
		
		tween.tween_callback(func():
			back.visible = false
			front.visible = true
			front.scale = Vector2(sprite_scale.x, 0)
		)
		tween.parallel().tween_property(shadow, "scale", shadow_scale, spin_speed)
		tween.tween_property(front, "scale", sprite_scale, spin_speed)
	else:
		tween.parallel().tween_property(shadow, "scale", shadow_scale * 0.8, spin_speed)
		tween.tween_property(back, "scale", Vector2(sprite_scale.x, 0), spin_speed)
		
		tween.tween_callback(func():
			back.visible = false
			front.visible = true
			front.scale = Vector2(sprite_scale.x, 0)
		)
		
		tween.parallel().tween_property(shadow, "scale", shadow_scale, spin_speed)
		tween.tween_property(front, "scale", sprite_scale, spin_speed)
		
		tween.parallel().tween_property(shadow, "scale", shadow_scale * 0.8, spin_speed)
		tween.tween_property(front, "scale", Vector2(sprite_scale.x, 0), spin_speed)
		
		tween.tween_callback(func():
			front.visible = false
			back.visible = true
			back.scale = Vector2(sprite_scale.x, 0)
		)
		tween.parallel().tween_property(shadow, "scale", shadow_scale, spin_speed)
		tween.tween_property(back, "scale", sprite_scale, spin_speed)
		
	await tween.finished
	face_up = !face_up
