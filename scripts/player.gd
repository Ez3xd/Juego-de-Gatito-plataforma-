extends CharacterBody2D
class_name CatPlayer

const SPEED = 140.0
const ACCELERATION = 900.0
const FRICTION = 1000.0
const AIR_ACCEL = 700.0
const AIR_FRICTION = 400.0

const JUMP_VELOCITY = -320.0
const GRAVITY = 950.0
const FALL_GRAVITY_MULT = 1.35

# Game feel / Juiciness
const COYOTE_TIME_MAX = 0.12
const JUMP_BUFFER_MAX = 0.12

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var spawn_position: Vector2 = Vector2.ZERO

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("player")
	_setup_inputs()
	_setup_animations()
	spawn_position = global_position

func _setup_inputs() -> void:
	# Ensure actions exist so the game works out of the box
	_register_action("move_left", [KEY_A, KEY_LEFT])
	_register_action("move_right", [KEY_D, KEY_RIGHT])
	_register_action("jump", [KEY_SPACE, KEY_W, KEY_UP])
	_register_action("restart", [KEY_R])

func _register_action(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var event = InputEventKey.new()
		event.physical_keycode = key
		var exists = false
		for existing in InputMap.action_get_events(action):
			if existing is InputEventKey and existing.physical_keycode == key:
				exists = true
				break
		if not exists:
			InputMap.action_add_event(action, event)

func _setup_animations() -> void:
	var frames = SpriteFrames.new()

	# Idle: 8 frames, 32x32
	frames.add_animation("idle")
	frames.set_animation_speed("idle", 8.0)
	frames.set_animation_loop("idle", true)
	var idle_tex = load("res://assets/cat/1_Cat_Idle-Sheet.png")
	for i in range(8):
		var atlas = AtlasTexture.new()
		atlas.atlas = idle_tex
		atlas.region = Rect2(i * 32, 0, 32, 32)
		frames.add_frame("idle", atlas)

	# Run: 10 frames, 32x32
	frames.add_animation("run")
	frames.set_animation_speed("run", 12.0)
	frames.set_animation_loop("run", true)
	var run_tex = load("res://assets/cat/2_Cat_Run-Sheet.png")
	for i in range(10):
		var atlas = AtlasTexture.new()
		atlas.atlas = run_tex
		atlas.region = Rect2(i * 32, 0, 32, 32)
		frames.add_frame("run", atlas)

	# Jump: 4 frames, 32x32
	frames.add_animation("jump")
	frames.set_animation_speed("jump", 10.0)
	frames.set_animation_loop("jump", false)
	var jump_tex = load("res://assets/cat/3_Cat_Jump-Sheet.png")
	for i in range(4):
		var atlas = AtlasTexture.new()
		atlas.atlas = jump_tex
		atlas.region = Rect2(i * 32, 0, 32, 32)
		frames.add_frame("jump", atlas)

	# Fall: 4 frames, 32x32
	frames.add_animation("fall")
	frames.set_animation_speed("fall", 10.0)
	frames.set_animation_loop("fall", true)
	var fall_tex = load("res://assets/cat/4_Cat_Fall-Sheet.png")
	for i in range(4):
		var atlas = AtlasTexture.new()
		atlas.atlas = fall_tex
		atlas.region = Rect2(i * 32, 0, 32, 32)
		frames.add_frame("fall", atlas)

	animated_sprite.sprite_frames = frames
	animated_sprite.play("idle")

func _physics_process(delta: float) -> void:
	# Quick restart level
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
		return

	var on_floor = is_on_floor()

	# Coyote time logic
	if on_floor:
		coyote_timer = COYOTE_TIME_MAX
	else:
		coyote_timer = max(0.0, coyote_timer - delta)

	# Jump buffering logic
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_MAX
	else:
		jump_buffer_timer = max(0.0, jump_buffer_timer - delta)

	# Execute Jump
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

	# Variable Jump Height (cut jump short when releasing button)
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.5

	# Gravity
	if not on_floor:
		var current_gravity = GRAVITY
		if velocity.y > 0.0:
			current_gravity *= FALL_GRAVITY_MULT
		velocity.y += current_gravity * delta

	# Horizontal Movement
	var direction = Input.get_axis("move_left", "move_right")
	var accel = ACCELERATION if on_floor else AIR_ACCEL
	var friction = FRICTION if on_floor else AIR_FRICTION

	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * SPEED, accel * delta)
		animated_sprite.flip_h = (direction < 0.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	move_and_slide()
	_update_animation(direction, on_floor)

	# Fall out of bounds check
	if global_position.y > 380.0:
		respawn()

func _update_animation(direction: float, on_floor: bool) -> void:
	if not on_floor:
		if velocity.y < 0.0:
			if animated_sprite.animation != "jump":
				animated_sprite.play("jump")
		else:
			if animated_sprite.animation != "fall":
				animated_sprite.play("fall")
	else:
		if abs(velocity.x) > 10.0 or direction != 0.0:
			if animated_sprite.animation != "run":
				animated_sprite.play("run")
		else:
			if animated_sprite.animation != "idle":
				animated_sprite.play("idle")

func respawn() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
