extends KinematicBody2D

export var movement: Vector2 = Vector2(0, -300)
export var time: float = 2

var start: Vector2;
var target: Vector2
var velocity: Vector2;

func _ready() -> void:
    start = position;
    target = start + movement
    velocity = movement / time;


func _physics_process(delta: float) -> void:
    position += velocity * delta

    if (position - start).length() >= movement.length() or (
        target - position).length() >= movement.length():
        velocity *= -1