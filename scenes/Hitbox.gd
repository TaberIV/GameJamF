extends Area2D

class_name Hitbox

export var faction: String = "player"

export var damage: float = 30

func _ready() -> void:
    $ColorRect.visible = false