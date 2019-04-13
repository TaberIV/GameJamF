extends KinematicBody2D

# Editor Parameters
export var move_speed: float = 350
export var accel_time: float = 0.1
export var deccel_time: float = 0.1

export var jump_height: float = 150
export var jump_distance: float = 200
export(float, 0, 1) var air_mobility: float = 0.8
export var jump_forgiveness: float = 0.1

export var max_slope_angle: float = 45

# Movement constants
var move_force: float
var friction: float

var gravity: float
var jump_speed: float

var max_slope_normal: Vector2

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

var on_ground: bool = false setget set_on_ground
var floor_velocity: Vector2 = Vector2()


func set_on_ground(val: bool) -> void:
    if not val:
        velocity.x += floor_velocity.x
        floor_velocity = Vector2()

    on_ground = val

func _ready() -> void:
    # Define constants
    if accel_time == 0:
        move_force = INF
    else:
        move_force = move_speed / accel_time

    if deccel_time == 0:
        friction = INF
    else:
        friction = move_speed / deccel_time

    gravity = 2 * jump_height * pow(move_speed, 2) / pow(jump_distance / 2, 2)
    jump_speed = -2 * jump_height * move_speed / (jump_distance / 2)

    max_slope_normal = Vector2(sin(deg2rad(max_slope_angle + 1)),
                               cos(deg2rad(max_slope_angle + 1)))


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
    # Horizontal Movement=
    if h_input == sign(velocity.x) and abs(velocity.x) >= move_speed:
        if on_ground:
            _apply_friction(delta)
            if abs(velocity.x) < move_speed:
                velocity.x = sign(velocity.x) * move_speed
    elif h_input != 0:
        # Determine force applied to player
        var force = h_input * move_force * delta

        if not on_ground:
            force *= air_mobility
        elif h_input != sign(velocity.x):
            _apply_friction(delta)

        # Apply force
        if h_input == sign(velocity.x):
            velocity.x = h_input * min(move_speed, abs(velocity.x + force))
        else:
            velocity.x += force
    # Friction
    elif on_ground:
        _apply_friction(delta)

    # Vertical Movement
    if (on_ground or jump_timer > 0) and jump_pressed:
        velocity.y = jump_speed
        jump_timer = 0

    velocity.y += gravity * delta
    velocity.y = min(velocity.y, abs(jump_speed))
    jump_timer -= delta

    colY = move_and_collide(Vector2(0, velocity.y) * delta)
    colX = move_and_collide(Vector2(velocity.x + floor_velocity.x, 0) * delta)

    _handle_collisions(delta)


func _apply_friction(delta: float):
    var force = friction * delta
    if abs(velocity.x) <= force:
        velocity.x = 0
    else:
        velocity.x -= sign(velocity.x) * force


func _handle_collisions(delta: float) -> void:
    # Vertical
    if abs(velocity.y) > 0 and colY:
        on_ground = velocity.y > 0
        velocity.y = 0

        if on_ground:
            floor_velocity = colY.collider_velocity
            velocity.y = max(floor_velocity.y, 0)
            jump_timer = jump_forgiveness
    else:
        self.on_ground = false

    # Horizontal
    if velocity.x != 0:
        if colX:
            # Collide with wall
            if abs(colX.normal.x) > max_slope_normal.x:
                velocity.x = 0
            # Walk up slopes
            else:
                var y_off = -(colX.normal.x / colX.normal.y) * colX.remainder.x
                colY = move_and_collide(Vector2(0, y_off))
                colX = move_and_collide(colX.remainder)

                # Check for popping above slope
                if not test_move(transform, Vector2(0, 0.1)):
                    _check_stick(-y_off)
        # Check if walked off ledge/down slope
        elif on_ground and colY and colY.remainder.y > 0:
            colY = move_and_collide(colY.remainder)

            # Stick moving down slopes
            if not colY:
                var slope_desc = abs(velocity.x) * delta / max_slope_normal.y
                _check_stick(slope_desc)


func _check_stick(stick: float) -> void:
    var should_stick = test_move(transform, Vector2(0, stick))

    if should_stick:
        colY = move_and_collide(Vector2(0, stick))
    else:
        self.on_ground = false

