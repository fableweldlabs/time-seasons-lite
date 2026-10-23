@tool
class_name FWPeriods
extends Resource
@export var names: PackedStringArray = ["Night", "Morning", "Day", "Evening", "Night"]
@export var starts: PackedInt32Array = [0, 360, 720, 1080, 1320]
func problems() -> PackedStringArray:
	var errors := PackedStringArray()
	if names.is_empty() or names.size() != starts.size():
		errors.append("Periods need one name per start time.")
		return errors
	if starts[0] != 0:
		errors.append("The first period must start at 00:00.")
	for i in range(starts.size()):
		if names[i].strip_edges().is_empty():
			errors.append("Period %d needs a name." % (i + 1))
		if starts[i] < 0 or starts[i] > 1439 or (i > 0 and starts[i] <= starts[i-1]):
			errors.append("Period starts must increase, from 00:00 through 23:59.")
	return errors
func valid() -> bool:
	return problems().is_empty()
func at(minute: int) -> String:
	if not valid():
		return "Invalid periods"
	var index := 0
	for i in range(starts.size()):
		if minute >= starts[i]:
			index = i
	return names[index]
func fingerprint() -> String:
	return JSON.stringify([Array(names), Array(starts)]).sha256_text()