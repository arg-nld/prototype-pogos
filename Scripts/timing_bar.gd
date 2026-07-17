#dont forget to make bar Area2D Zones / the current one is placeholder only retard - Past andrei to future andrei
extends Node2D

signal slam_finished(result)

@onready var bar = $Bar
@onready var indicator = $Indicator
@onready var slam_sound = $SlamSound

var direction := 1
var speed := 250.0

var stopped := false
var can_input := true

var top_limit : float
var bottom_limit : float

var slam_result = {
	"power": 0.0,
	"rating": "None"
}


func _ready():
	# Calculate Y-axis bounds based on scaled sprite dimensions
	var bar_height = bar.texture.get_height() * bar.scale.y
	var indicator_height = indicator.texture.get_height() * indicator.scale.y

	top_limit = bar.position.y - bar_height / 2.0 + indicator_height / 2.0
	bottom_limit = bar.position.y + bar_height / 2.0 - indicator_height / 2.0


func _process(delta):
	if stopped:
		return

	indicator.position.y += speed * direction * delta

	# Clamp and reverse direction at boundaries
	if indicator.position.y <= top_limit:
		indicator.position.y = top_limit
		direction = 1

	elif indicator.position.y >= bottom_limit:
		indicator.position.y = bottom_limit
		direction = -1


func _input(event):
	if event.is_action_pressed("ui_accept") and can_input:
		can_input = false
		stopped = true

		await slam_animation()

		print("Slam Finished!")


func slam_animation():
	var original_indicator = indicator.position

	# Anticipation tween (pullback)
	var tween = create_tween()

	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		indicator,
		"position",
		original_indicator + Vector2(12, 0),
		0.12
	)

	tween.tween_interval(0.04)

	await tween.finished

	slam_sound.play()

	# Strike tween
	var slam = create_tween()

	slam.set_trans(Tween.TRANS_QUART)
	slam.set_ease(Tween.EASE_IN)

	slam.tween_property(
		indicator,
		"position",
		original_indicator,
		0.03
	)

	await slam.finished

	# Post-strike juice
	await bar_impact()

	calculate_result()


func bar_impact():
	var original = bar.position

	var tween = create_tween()

	# Micro-shake on hit
	tween.tween_property(
		bar,
		"position",
		original + Vector2(-2, 0),
		0.025
	)

	tween.tween_property(
		bar,
		"position",
		original,
		0.04
	)

	await tween.finished


func calculate_result():
	# Normalize distance from center to a 0.0 - 1.0 power scale
	var center = (top_limit + bottom_limit) / 2.0
	var max_distance = (bottom_limit - top_limit) / 2.0

	var distance = abs(indicator.position.y - center)

	var power = clamp(1.0 - (distance / max_distance), 0.0, 1.0)

	# Map float power to string rating
	var rating = ""

	if power >= 0.95:
		rating = "Perfect"

	elif power >= 0.80:
		rating = "Great"

	elif power >= 0.60:
		rating = "Good"

	elif power >= 0.35:
		rating = "Okay"

	else:
		rating = "Weak"


	slam_result = {
		"power": power,
		"rating": rating
	}

	print(slam_result)

	emit_signal("slam_finished", slam_result)
