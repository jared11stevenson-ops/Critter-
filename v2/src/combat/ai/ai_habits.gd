extends RefCounted
## Habit table: counts what the opponent does in a context (range band + my last action),
## so the AI can predict and pre-empt their patterns.
const KINDS := ["light", "heavy", "grab", "dodge", "guard", "ability", "wait"]
var counts: Dictionary = {}

func record(ctx: String, kind: String) -> void:
	if not counts.has(ctx):
		counts[ctx] = {}
	counts[ctx][kind] = counts[ctx].get(kind, 0) + 1

func total(ctx: String) -> int:
	var t := 0
	for k in counts.get(ctx, {}).keys():
		t += counts[ctx][k]
	return t

## Smoothed probability distribution over KINDS in `ctx`.
func predict(ctx: String) -> Dictionary:
	var d := {}
	var tot := float(total(ctx)) + 0.5 * KINDS.size()
	for k in KINDS:
		d[k] = (float(counts.get(ctx, {}).get(k, 0)) + 0.5) / tot
	return d

func confidence(ctx: String) -> float:
	return clampf(float(total(ctx)) / 8.0, 0.0, 1.0)

## What to do about the predicted opponent action -> weights over my options.
static func counter_weights(pred: Dictionary) -> Dictionary:
	return {
		"light": pred["grab"] * 1.0 + pred["dodge"] * 0.3 + pred["wait"] * 0.2,
		"heavy": pred["dodge"] * 0.2 + pred["guard"] * 0.2 + pred["wait"] * 0.4,
		"grab": pred["guard"] * 1.4 + pred["wait"] * 0.3,
		"guard": pred["light"] * 0.8 + pred["heavy"] * 0.5,
		"dodge": pred["heavy"] * 1.0 + pred["grab"] * 0.8 + pred["ability"] * 0.6,
		"parry": pred["light"] * 1.0 + pred["heavy"] * 0.4,
	}
