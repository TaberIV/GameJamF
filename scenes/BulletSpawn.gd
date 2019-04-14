extends Node2D

signal shoot(bullet, location)

# Editor values


# Constants
var Bullet: PackedScene = preload("res://scenes/Bullet.tscn")

# Shoot state
var shoot: bool
var shoot_pressed: bool
var shoot_released: bool
var shoot_hold_time: float = 0


func _process(delta: float) -> void:
    get_input()
    
    if shoot_pressed:
        shoot_hold_time = 0
    elif shoot:
        shoot_hold_time += delta
    elif shoot_released:
        emit_signal("shoot", Bullet, position)


func get_input() -> void:
    shoot = Input.is_action_pressed("shoot")
    shoot_pressed = Input.is_action_just_pressed("shoot")
    shoot_released = Input.is_action_just_released("shoot")

