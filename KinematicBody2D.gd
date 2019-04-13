extends KinematicBody2D

# Editor Parameters
export var ground_speed: float = 500
export var jump_height: float = 200
export var jump_distance: float = 300
export var max_slope_angle: float = 45
export var jump_forgiveness: float = 0.1

# Movement constants
var gravity: float
var jump_speed: float

var max_slope_x_normal: float
var min_slope_y_normal: float

# Input state
var h_input: int = 0

var jump: bool = false
var jump_pressed: bool = false
var jump_timer: float = 0

# Movement state
var velocity = Vector2()

# Collision info
var colY: KinematicCollision2D
var colX: KinematicCollision2D

var on_ground: bool = false
var floor_normal: Vector2 = Vector2()
var floor_velocity: Vector2 = Vector2()


func _ready() -> void:
    gravity = 2 * jump_height * pow(ground_speed, 2) / pow(jump_distance / 2, 2)
    jump_speed = -2 * jump_height * ground_speed / (jump_distance / 2)
    max_slope_x_normal = sin(deg2rad(max_slope_angle + 1))
    min_slope_y_normal = cos(deg2rad(max_slope_angle + 1))


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


func _physics_process(delta: float) -> void:
    get_input()

    # Move
    _movement(delta)


func _movement(delta: float) -> void:
    # Horizontal Movement
    velocity.x = h_input * ground_speed + floor_velocity.x

    # Vertical Movement
    if (on_ground or jump_timer > 0) and jump_pressed:
        velocity.y = jump_speed
        jump_timer = 0

    velocity.y += gravity * delta
    velocity.y = min(velocity.y, abs(jump_speed))
    jump_timer -= delta

    colY = move_and_collide(Vector2(0, velocity.y) * delta)
    colX = move_and_collide(Vector2(velocity.x, 0) * delta)

    _handle_collisions(delta)


func _handle_collisions(delta: float) -> void:
    # Vertical
    if abs(velocity.y) > 0 and colY:
        on_ground = velocity.y > 0
        velocity.y = 0

        if on_ground:
            jump_timer = jump_forgiveness

            # Stick to platform going down
            floor_velocity = colY.collider_velocity
            floor_normal = colY.normal
            velocity.y = max(floor_velocity.y, 0)
    else:
        on_ground = false

    # Horizontal
    if velocity.x != 0:
        if colX:
            # Collide with wall
            if abs(colX.normal.x) > max_slope_x_normal:
                velocity.x = 0
            # Walk up slopes
            else:
                var y_off = -(colX.normal.x / colX.normal.y) * colX.remainder.x
                move_and_collide(Vector2(0, y_off))
                move_and_collide(colX.remainder)
        # Check if walked off ledge/down slope
        elif on_ground and colY and colY.remainder.y > 0:
            colY = move_and_collide(colY.remainder)

            if not colY:
                var slope_desc = abs(velocity.x) * delta / min_slope_y_normal
                var should_stick = test_move(transform, Vector2(0, slope_desc))

                # Stick moving down slopes
                if should_stick:
                    move_and_collide(Vector2(0, abs(slope_desc)))
                else:
                    on_ground = false

