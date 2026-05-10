extends Node
class_name EchoSwitchGate

var _switches: Array = []
var _gate: Node = null

func setup(switches: Array, gate: Node) -> void:
	_gate = gate
	_switches = switches
	for sw in _switches:
		if sw.has_signal("activated"):
			sw.activated.connect(_on_switch_activated)

func _on_switch_activated(_sw: Node) -> void:
	# Check if all switches are triggered
	var done := _switches.all(func(s): return s._triggered)
	if done and is_instance_valid(_gate) and _gate.has_method("open"):
		_gate.open()
