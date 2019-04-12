extends TileMap

const TILE_WIDTH = 8
const TILE_HEIGHT = 8

const WORLD_TILE_WIDTH = 32
const WORLD_TILE_HEIGHT = 28

enum CTiles { TopCollision = 4, TopLeftCollision = 5, TopRightCollision = 6,
AllCollision = 7, RightCollision = 9, LeftCollision = 10 }
const TopCollisionArray = [CTiles.TopCollision, CTiles.TopLeftCollision, CTiles.TopRightCollision, CTiles.AllCollision]
const LeftCollisionArray = [CTiles.TopLeftCollision, CTiles.AllCollision, CTiles.LeftCollision]
const RightCollisionArray = [CTiles.TopRightCollision, CTiles.AllCollision, CTiles.RightCollision]

# Called when the node enters the scene tree for the first time.
func _ready():
	# Iterate through all tiles
	for x in range(2, WORLD_TILE_WIDTH-3):
		for y in range(-3, WORLD_TILE_HEIGHT+1):
			var cell_id = get_cell(x, y)
			if TopCollisionArray.has(cell_id) or RightCollisionArray.has(cell_id) or LeftCollisionArray.has(cell_id):
				var kine = KinematicBody2D.new()
				kine.set_position(Vector2(4 + (x * TILE_WIDTH), 4 + (y * TILE_HEIGHT)))
				kine.set_rotation(0)
				add_child(kine)
				
				if TopCollisionArray.has(cell_id):
					var col = create_cell_collision(x, y, 0, kine)
					kine.set_name("FloorTile")
					kine.add_child(col)
				if LeftCollisionArray.has(cell_id):
					var col = create_cell_collision(x, y, -90, kine)
					kine.add_child(col)
				if RightCollisionArray.has(cell_id):
					var col = create_cell_collision(x, y, 90, kine)
					kine.add_child(col)


func create_cell_collision(x, y, rotation, kine):
	var wcs = CollisionShape2D.new()
	var rectangle = RectangleShape2D.new()
	rectangle.set_extents(Vector2(4, 4))
	wcs.set_shape(rectangle)
	wcs.set_rotation(deg2rad(rotation))
	wcs.set_one_way_collision(true)
	return wcs
	
