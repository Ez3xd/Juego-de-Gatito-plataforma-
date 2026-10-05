extends Area2D
class_name Coin

signal collected

var is_collected: bool = false
var start_y: float = 0.0
var float_time: float = 0.0
var anim_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("coins")
	start_y = position.y
	float_time = randf() * TAU
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if is_collected:
		return
	float_time += delta * 3.0
	position.y = start_y + sin(float_time) * 3.0
	
	anim_timer += delta * 8.0
	if sprite:
		sprite.frame = int(anim_timer) % 4

func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return
	if body.is_in_group("player"):
		is_collected = true
		collected.emit()
		
		# Juice / Polish: Tween up, scale and fade out
		var tween = create_tween().set_parallel(true)
		tween.tween_property(self, "position:y", position.y - 20.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.3)
		tween.tween_property(self, "modulate:a", 0.0, 0.3)
		tween.finished.connect(queue_free)
