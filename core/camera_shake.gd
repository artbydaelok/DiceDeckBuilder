extends Node
## Global camera shake via Phantom Camera's noise system. Call CameraShake.shake().
##
## Phantom Camera only applies an emitter's noise to a PhantomCamera3D whose
## noise_emitter_layer shares a bit with the emitter — and pcams default that to 0.
## So before each shake we OR a shared layer onto every pcam in the tree, which means
## the shake works on whatever camera is active with zero per-scene editor setup.

const SHAKE_LAYER := 1

var _emitter: PhantomCameraNoiseEmitter3D


func _ready() -> void:
	var noise := PhantomCameraNoise3D.new()
	noise.amplitude = 5.0          # shake intensity
	noise.frequency = 0.4          # shake speed
	noise.rotational_noise = true  # rock the view — the classic shake
	noise.positional_noise = false

	_emitter = PhantomCameraNoiseEmitter3D.new()
	_emitter.noise = noise
	_emitter.noise_emitter_layer = SHAKE_LAYER
	_emitter.continuous = false
	_emitter.growth_time = 0.0     # punch to full intensity instantly
	_emitter.duration = 0.12       # hold briefly…
	_emitter.decay_time = 0.35     # …then ease off
	add_child(_emitter)


## One-shot camera shake on whichever PhantomCamera3D is currently active.
func shake() -> void:
	if _emitter == null:
		return
	_enable_layer_on_pcams(get_tree().root)
	_emitter.emit()


## OR the shake layer onto every PhantomCamera3D so the active one receives the noise.
func _enable_layer_on_pcams(node: Node) -> void:
	if node is PhantomCamera3D:
		node.noise_emitter_layer |= SHAKE_LAYER
	for child in node.get_children():
		_enable_layer_on_pcams(child)
