extends Interactable
class_name RouteGate

@export var route_id := "scrap_highway"

func setup_route(new_route_id: String, label: String, pos: Vector2, gate_radius := 58.0) -> void:
	route_id = new_route_id
	interaction_id = "route:" + route_id
	prompt = label
	position = pos
	radius = gate_radius
