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
	var count := 0
	for s in _switches:
		if s._triggered: count += 1
		
	if is_instance_valid(_gate) and _gate.has_method("update_switch_progress"):
		_gate.update_switch_progress(count, _switches.size())

	var done := (count == _switches.size())
	if done and is_instance_valid(_gate) and _gate.has_method("open"):
		_gate.open()
