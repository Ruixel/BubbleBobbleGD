extends KinematicBody2D

const SPEED   = 60
const GRAVITY = 4
const JUMP_POWER = 150
const FLOOR = Vector2(0, -1)
const BUBBLE_DELAY = 0.250 # How long to wait between bubble spawning (s)

var velocity = Vector2()
var on_ground = false

var bubble_wait = INF
var buffer_bubble = false # Buffer inputs

enum PlayerState {IDLE, WALKING, JUMPING, FALLING}
var state = PlayerState.IDLE
var face_right = true

var BubblePrefab = load("res://obj/Bubble.tscn")

func _physics_process(delta):
	state = PlayerState.IDLE
	bubble_wait += delta
	
	if Input.is_action_pressed("ui_right"):
		if (on_ground or velocity.y < 0):
			state = PlayerState.WALKING
			velocity.x = SPEED
		else:
			velocity.x = SPEED / 2.0
		face_right = true
		$Sprite.flip_h = true
	elif Input.is_action_pressed("ui_left"):
		if (on_ground or velocity.y < 0):
			state = PlayerState.WALKING
			velocity.x = -SPEED
		else:
			velocity.x = -SPEED / 2.0
		face_right = false
		$Sprite.flip_h = false
	else:
		velocity.x = 0

	if Input.is_action_pressed("ui_up") and on_ground and velocity.y >= 0:
		velocity.y = -JUMP_POWER
		on_ground = false
	
	# Fall
	velocity.y += GRAVITY
	velocity.y = min(velocity.y, 50)
	velocity = move_and_slide(velocity, FLOOR)
	
	# Fire bubble
	if Input.is_action_just_pressed("ui_select") or buffer_bubble:
		if bubble_wait > BUBBLE_DELAY:
			var bubble = BubblePrefab.instance()
			if face_right:
				bubble.set_position(get_position() + Vector2(12, 3))
				bubble.face_right = true
			else:
				bubble.set_position(get_position() + Vector2(-12, 3))
				bubble.face_right = false
			get_parent().get_node("Bubbles").add_child(bubble)
			bubble_wait = 0
			buffer_bubble = false
		else:
			# Buffer inputs
			buffer_bubble = true
	
	if Input.is_action_just_released("ui_select"):
		buffer_bubble = false
	
	# Use a more accurate way to determine if touching the ground
	if check_ground($LeftFoot) or check_ground($RightFoot) or check_ground($Bottom):
		on_ground = true
	else:
		on_ground = false
		if velocity.y > 0:
			state = PlayerState.FALLING
		else:
			state = PlayerState.JUMPING
	
	# Deal with animations
	match state:
		PlayerState.IDLE:
			$Sprite.set_animation("default")
		PlayerState.WALKING:
			$Sprite.set_animation("walk")
		PlayerState.JUMPING:
			$Sprite.set_animation("jump")
		PlayerState.FALLING:
			$Sprite.set_animation("fall")

func check_ground(foot):
	var space_state = get_world_2d().direct_space_state
	var start_ray = foot.get_global_transform().get_origin()
	var end_ray = Vector2(start_ray.x, start_ray.y+1)
	var ignore = [self, get_node("/root/Node2D/GlobalCollision/Ceiling")]
	var result = space_state.intersect_ray(start_ray, end_ray, ignore, 1, 1)
	
	# Check if it collided with a floor tile collider
	if not result.empty():
		if result.get("collider").get_name().match("*FloorTile*"):
			return true
		elif result.get("collider").get_parent().get_name().match("Bubbles"):
			if Input.is_action_pressed("ui_up"):
				velocity.y = 0.1
				result.get("collider").apply_central_impulse(Vector2(0, -30))
				return true
			else:
				result.get("collider").pop()
				return false
	else:
		return false

func _on_WarpUp_body_entered(body):
	set_position(Vector2(get_position().x, -12))

func is_player_jumping():
	if not on_ground and velocity.y < 2:
		return true
	
	return false