extends Node

@export var noise := FastNoiseLite.new()

func _init():
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 5
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.5
	noise.frequency = 0.01

func get_height(x, z):
	var height = noise.get_noise_2d(x, z) * 10 + 10
	return height
