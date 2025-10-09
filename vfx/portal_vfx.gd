@tool
extends Node3D

@export var gradient_texture : GradientTexture1D :
	set(value):
		gradient_texture = value
		update_gradient()
	get:
		return gradient_texture
		
		
@export var gpu_particles_3d_1: GPUParticles3D
@export var gpu_particles_3d_2: GPUParticles3D
@export var portal_mesh: MeshInstance3D

func update_gradient():
	if gpu_particles_3d_1 != null and gpu_particles_3d_2 != null:
		gpu_particles_3d_1.process_material.color_initial_ramp = gradient_texture
		gpu_particles_3d_2.process_material.color_initial_ramp = gradient_texture
		portal_mesh.mesh.material.set_shader_parameter("gradient_texture", gradient_texture)
	
