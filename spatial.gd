extends Node3D

class_name World

const h = 16

const BEDROCK_HEIGHT = -h  # Height level for the bedrock layer
const DIAMOND_MIN_HEIGHT = -h + 1  # Minimum height for diamond blocks
const DIAMOND_MAX_HEIGHT = -10  # Maximum height for diamond blocks
const STONE_HEIGHT = -3  # Maximum height for stone layer
const DIRT_HEIGHT = -1  # Maximum height for dirt layer
const WORLD_MAX_HEIGHT = h  # Maximum height for the world
const WATER_LEVEL = 0  # Define the water level height

var chunk_size = 16
var render_distance = 2  # Change this to adjust the render distance
var chunks = {}
var noise_generator = preload("res://scenes/NoiseGenerator.gd").new()

@onready var gridmap = $GridMap
@onready var player = $Player

# Tree structure definition
const TREE_TRUNK_BLOCK = 5  # Example trunk block type
const TREE_LEAF_BLOCK = 3   # Example leaf block type
const WATER_BLOCK = 8       # Example water block type

func _ready():
	noise_generator.noise.seed = randi()
	await generate_initial_chunks()

func _process(delta):
	update_chunks()

# Use async functions to generate chunks in separate frames
func generate_initial_chunks() -> void:
	var player_chunk_x = int(player.global_position.x / chunk_size)
	var player_chunk_z = int(player.global_position.z / chunk_size)
	for x in range(player_chunk_x - render_distance, player_chunk_x + render_distance + 1):
		for z in range(player_chunk_z - render_distance, player_chunk_z + render_distance + 1):
			await generate_chunk(x, z)

func generate_chunk(chunk_x, chunk_z) -> void:
	if Vector2(chunk_x, chunk_z) in chunks:
		return
	chunks[Vector2(chunk_x, chunk_z)] = true
	
	var chunk_cells = []
	for x in range(chunk_size):
		for z in range(chunk_size):
			var world_x = chunk_x * chunk_size + x
			var world_z = chunk_z * chunk_size + z
			var height = noise_generator.get_height(world_x, world_z)
			for y in range(WORLD_MAX_HEIGHT):
				var cell_pos = Vector3(world_x, y - h, world_z)
				if y - h <= BEDROCK_HEIGHT:
					chunk_cells.append({"pos": cell_pos, "block": 7})  # Bedrock
				elif y - h <= DIAMOND_MAX_HEIGHT and y >= DIAMOND_MIN_HEIGHT and randi() % 90 == 0:
					chunk_cells.append({"pos": cell_pos, "block": 9})  # Diamond
				elif y - h <= STONE_HEIGHT:
					chunk_cells.append({"pos": cell_pos, "block": 4})  # Stone
				elif y - h <= DIRT_HEIGHT:
					chunk_cells.append({"pos": cell_pos, "block": 1})  # Dirt
				elif y - h <= height:
					chunk_cells.append({"pos": cell_pos, "block": 2})  # Grass # Assuming 3 is the bedrock block type

			for y in range(height, WATER_LEVEL):
				chunk_cells.append({"pos": Vector3(world_x, y, world_z), "block": WATER_BLOCK})
			
			for y in range(height):
				var block_type = 1
				if y < height - 3:
					block_type = 4
				elif y < height - 1:
					block_type = 2
				chunk_cells.append({"pos": Vector3(world_x, y, world_z), "block": block_type})
	
	await update_gridmap(chunk_cells)
	await generate_trees(chunk_x, chunk_z)

func update_gridmap(chunk_cells) -> void:
	for cell in chunk_cells:
		gridmap.set_cell_item(cell["pos"], cell["block"])

func generate_trees(chunk_x, chunk_z) -> void:
	var tree_cells = []
	for x in range(chunk_size):
		for z in range(chunk_size):
			if randi() % 100 < 0.3:
				var world_x = chunk_x * chunk_size + x
				var world_z = chunk_z * chunk_size + z
				var height = noise_generator.get_height(world_x, world_z)
				if height >= WATER_LEVEL:
					var trunk_start = Vector3(world_x, height, world_z)
					for y in range(5):
						tree_cells.append({"pos": trunk_start + Vector3(0, y, 0), "block": TREE_TRUNK_BLOCK})
					var leaf_start = trunk_start + Vector3(0, 5, 0)
					for lx in range(-2, 3):
						for lz in range(-2, 3):
							for ly in range(-1, 2):
								if abs(lx) + abs(lz) < 4:
									tree_cells.append({"pos": leaf_start + Vector3(lx, ly, lz), "block": TREE_LEAF_BLOCK})
								if abs(lx) + abs(lz) <= 1 and ly == 0:
									tree_cells.append({"pos": leaf_start + Vector3(lx, ly - 1, lz), "block": TREE_LEAF_BLOCK})
	await update_gridmap(tree_cells)

func update_chunks() -> void:
	var player_chunk_x = int(player.global_position.x / chunk_size)
	var player_chunk_z = int(player.global_position.z / chunk_size)
	var current_visible_chunks = {}
	
	for x in range(player_chunk_x - render_distance, player_chunk_x + render_distance + 1):
		for z in range(player_chunk_z - render_distance, player_chunk_z + render_distance + 1):
			current_visible_chunks[Vector2(x, z)] = true
			await generate_chunk(x, z)

	var chunks_to_remove = []
	for chunk in chunks.keys():
		if chunk not in current_visible_chunks:
			chunks_to_remove.append(chunk)

	for chunk in chunks_to_remove:
		await unload_chunk(chunk)
		chunks.erase(chunk)

func unload_chunk(chunk) -> void:
	var chunk_x = chunk.x * chunk_size
	var chunk_z = chunk.y * chunk_size
	var cells_to_clear = []
	for x in range(chunk_size):
		for z in range(chunk_size):
			var world_x = chunk_x + x
			var world_z = chunk_z + z
			for y in range(WORLD_MAX_HEIGHT):
				cells_to_clear.append(Vector3(world_x, y - h, world_z))
	
	for cell in cells_to_clear:
		gridmap.set_cell_item(cell, -1)  # Clear the block
