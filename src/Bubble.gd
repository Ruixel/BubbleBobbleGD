extends RigidBody2D

const RADIUS_GROWING = 5.5
const RADIUS_MAX = 8
const BUBBLE_SPEED = 90
const FLOOR = Vector2(0, -1)
const WIND_FORCE = 1
const MAX_SPEED = 12
const POP_RADIUS = 12

export var face_right : bool
var speed = 0
var is_growing = true
var is_popped = false

enum HoldType { NOTHING, ZEN }
var holding = HoldType.NOTHING

enum AirDir { Up = 0, Left = 1, Down = 2, Right = 3 }
const AirTiles = [AirDir.Up, AirDir.Left, AirDir.Down, AirDir.Right]
onready var CollisionMap = get_node("/root/Node2D/CollisionMap")

var velocity = Vector2()

# Called when the node enters the scene tree for the first time.
func _ready():
	# Determine which direction it was fired in
	if face_right:
		speed = BUBBLE_SPEED
	else:
		speed = -BUBBLE_SPEED
		
	# Play animation
	$AnimatedSprite.play("grow")
	is_growing = true

func pop():
	# Set the bubble so it stops collision
	$AnimatedSprite.play("pop")
	$CollisionShape2D.set_disabled(true)
	is_popped = true
	set_collision_layer_bit(0, false)
	set_mode(MODE_KINEMATIC) # Stop the pop effect from moving
	
	# Pop other bubbles nearby
	var current_pos = get_position()
	var bubbles = get_parent().get_children()
	for b in bubbles:
		if b != self and not b.is_popped and current_pos.distance_to(b.get_position()) < POP_RADIUS:
			b.pop()

func finish_growing(anim):
	$AnimatedSprite.play(anim)
	
	set_collision_layer_bit(0, true)
	set_collision_layer_bit(3, false)
	set_collision_mask_bit(0, true)
	is_growing = false

func _physics_process(delta):
	var cell_pos  = CollisionMap.world_to_map(get_position())
	var cell_type = CollisionMap.get_cellv(cell_pos)
	
	# If the bubble is in an unexpected place, pop it
	if not AirTiles.has(cell_type): 
		pop()
	
	# Apply velocity from wind in level
	if is_growing:
		velocity.x = speed
	else:
		match cell_type:
			AirDir.Up:
				velocity.y -= WIND_FORCE
			AirDir.Right:
				velocity.x += WIND_FORCE
			AirDir.Down:
				velocity.y += WIND_FORCE
			AirDir.Left:
				velocity.x -= WIND_FORCE
		
		# Clamp speed to avoid overly fast bubbles
		velocity.x = clamp(velocity.x, -MAX_SPEED, MAX_SPEED)
		velocity.y = clamp(velocity.y, -MAX_SPEED, MAX_SPEED)
	
	# Don't move if popped
	if is_popped:
		velocity = Vector2(0, 0)
	
	set_rotation_degrees(0)
	set_linear_velocity(velocity)

func _on_AnimatedSprite_animation_finished():
	# Once finished growing, behave like a bubble
	if $AnimatedSprite.get_animation() == "grow":
		finish_growing("default")
	
	# Once the animation for pop is done, delete the bubble
	if $AnimatedSprite.get_animation() == "pop":
		queue_free()


func _on_RigidBody2D_body_entered(body):
	# If a player touches the bubble while jumping, pop
	if body.get_name().match("Player"):
		if not is_growing and body.is_player_jumping():
			pop()
	
	# If collided with an enemy while growing, encapsulate them
	if holding == HoldType.NOTHING and is_growing:
		if body.get_name().match("*Zen*") and body.get_parent().get_name().match("Enemies"):
			holding = HoldType.ZEN
			body.queue_free()
			
			# Carry momentum from bubble
			if face_right:
				velocity.x = BUBBLE_SPEED * 2
			else:
				velocity.x = -BUBBLE_SPEED * 2
				
			finish_growing("zen")