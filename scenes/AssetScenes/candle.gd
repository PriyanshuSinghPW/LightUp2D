extends AnimatedSprite2D

@onready var point_light: PointLight2D = $PointLight2D

@export var light_enabled: bool = true:
	set(value):
		light_enabled = value
		if point_light:
			point_light.visible = value

@export var light_energy: float = 1.0:
	set(value):
		light_energy = value
		if point_light:
			point_light.energy = value

@export var light_color: Color = Color.WHITE:
	set(value):
		light_color = value
		if point_light:
			point_light.color = value
