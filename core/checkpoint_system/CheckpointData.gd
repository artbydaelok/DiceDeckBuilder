extends Resource
class_name CheckpointData

## The name of this checkpoint
@export var checkpoint_name : String

## Screenshot of the checkpoint
@export var image : Texture

## The name of the level that this checkpoint is in
@export var level_name : String

## The path to the level scene
@export var level_path : String

## Where the player should be spawning
@export var spawn_point : Vector3
