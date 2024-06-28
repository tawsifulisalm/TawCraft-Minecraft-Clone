extends Node
class_name NoiseGeneratorNode

@export var noise_generator = preload("res://scenes/NoiseGenerator.gd").new()

func get_height(x, z):
	return noise_generator.get_height(x, z)
