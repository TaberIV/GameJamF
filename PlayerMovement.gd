extends KinematicBody2D

# Editor Parameters
export var ground_speed: float = 500
export var jump_height: float = 200
export var jump_distance: float = 300
export var max_slope_angle: float = 45

# Physics constants
var gravity: float
var jump_speed: float

var max_slope_x_normal: float

# Input state
var h_input: int = 0

var jump: bool = false
var jump_pressed: bool = false

# Movement state
var velocity = Vector2()

# Collision info
var colY: KinematicCollision2D
var colX: KinematicCollision2D

var on_ground: bool = false
var floor_velocity: Vector2 = Vector2()


func _ready() -> void:
    gravity = 2 * jump_height * pow(ground_speed, 2) / pow(jump_distance / 2, 2)
    jump_speed = -2 * jump_height * ground_speed / (jump_distance / 2)
    max_slope_x_normal = sin(deg2rad(max_slope_angle + .1))


func get_input() -> void:
    # Horizontal Input
    h_input = 0

    if Input.is_action_pressed("left"):
        h_input -= 1
    if Input.is_action_pressed("right"):
        h_input += 1

    # Jump Input
    jump = Input.is_action_pressed("jump")
    jump_pressed = Input.is_action_just_pressed("jump")


func _process(delta: float) -> void:
    get_input()

    # Movement Calculations------------------------------------
    # Horizontal Movement
    velocity.x = h_input * ground_speed + floor_velocity.x

    # Vertical Movement
    if on_ground and jump_pressed:
        velocity.y = jump_speed

    velocity.y += gravity * delta
    velocity.y = min(velocity.y, abs(jump_speed))
    #----------------------------------------------------------

    # Move
    colY = move_and_collide(Vector2(0, velocity.y) * delta)
    colX = move_and_collide(Vector2(velocity.x, 0) * delta)

    # Process Collisions
    if abs(velocity.y) > 0 and colY:
        on_ground = velocity.y > 0
        velocity.y = 0

        # Stick to platform going down
        if on_ground:
            floor_velocity = colY.collider_velocity
            velocity.y = max(floor_velocity.y, 0)
    else:
        on_ground = false
        floor_velocity = Vector2()

    if velocity.x != 0 and colX:
        if abs(colX.normal.x) < max_slope_x_normal and colX.normal.x != 0:
            move_and_collide(Vector2(0, -(colX.normal.x / colX.normal.y) * colX.remainder.x))
            move_and_collide(colX.remainder)
        else:
            velocity.x = 0
