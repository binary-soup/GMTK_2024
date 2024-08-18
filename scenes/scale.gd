extends Node3D

@export var LIFT_SPEED := 2.0
@onready var gs_node: GSNode = $CounterWeight/GSNode
@onready var anim_player: AnimationPlayer = $AnimationPlayer


func _on_gs_node_gs_val_changed(val: float) -> void:
	if val >= gs_node.GS_MAX_VAL-0.1:
		anim_player.play("move")
		gs_node.gs_disabled = true
