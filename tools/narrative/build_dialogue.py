#!/usr/bin/env python3
"""Lead-authored story script for the vertical slice. Generates game/narrative/dialogue/*.json.
Voice sources: CRITTER Master Lore Bible v12 (section refs in comments). Run: python3 tools/narrative/build_dialogue.py"""
import json, os
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "game", "narrative", "dialogue")
os.makedirs(OUT, exist_ok=True)

def L(who, expr, text, **kw):
    d = {"who": who, "expr": expr, "text": text}; d.update(kw); return d
def N(text, **kw):
    d = {"who": "narration", "text": text}; d.update(kw); return d
def H(text, **kw):
    d = {"who": "handler", "text": text}; d.update(kw); return d
def M(expr, text, **kw):  return L("comms:mara", expr, text, **kw)
def DX(expr, text, **kw): return L("comms:dexter", expr, text, **kw)
def A(expr, text, **kw):  return L("aruun", expr, text, **kw)
def C(expr, text, **kw):  return L("cigarra", expr, text, **kw)
def MA(expr, text, **kw): return L("mara", expr, text, **kw)

D = {}

# ------------------------------------------------------------------ HUB
D["hub_intro"] = [
    N("Terrarium One. It began as a laboratory containing ecosystems. It became an ecosystem containing laboratories."),
    MA("focused", "Handler. Welcome to the Common. Your certification is still warm, so I'll keep this simple."),
    MA("neutral", "Six hours ago the seismographs on our Red Reaches Gate started singing. Something is shaking the foundations of the Ochre Span."),
    A("focused", "A Spanwright crossing. Older than anyone's records. Built in the same tradition as the Red Span."),
    A("calm", "The tradition that failed."),
    C("curious", "Translation: he's going. He decided before you walked in. I saw that one without even trying."),
    MA("annoyed", "There's a licensed extraction operation in the valley. Thoughtstone prospecting. The permit is Dominion-backed."),
    C("focused", "The signature on the permit is Dexter Mane's. His decisions are loud. Very sharp branches."),
    MA("tired", "Dexter does nothing by accident. That's the problem."),
    {"choice": [
        {"text": "Aruun, I'd be glad to have you with me.", "goto": "c_aruun", "trust": {"aruun": 5}},
        {"text": "Why does one bridge matter this much?", "goto": "c_bridge", "trust": {"aruun": 3}},
        {"text": "Cigarra — can you see how this goes?", "goto": "c_oracle", "trust": {"cigarra": -2}},
    ]},
    {"label": "c_aruun"},
    A("calm", "Glad isn't required. Careful is."),
    {"goto": "rules"},
    {"label": "c_bridge"},
    A("calm", "In the Reaches, strength means the burden you can accept without forcing it onto someone weaker."),
    A("focused", "A bridge is that idea, in stone. When it fails, it fails on the people who trusted it."),
    {"goto": "rules"},
    {"label": "c_oracle"},
    C("annoyed", "No. And if I could, I wouldn't tell you. A future seen is a future touched."),
    C("happy", "Ask me what's likely. That's cheaper. For both of us."),
    {"label": "rules"},
    MA("focused", "Ground rules. These two are partners, not equipment. You don't order them. You ask, and you'd better be right."),
    MA("neutral", "Dangerous wildlife can come home under Wild Containment. Anything that might be a person — you scan, you talk, you leave it be."),
    C("happy", "She means me. She always means me."),
    MA("soft", "I mean everyone, Cigarra."),
    MA("focused", "The Gate is tuned to the Red Reaches. First descents hit hard — we call it the Tilt. Breathe through it."),
    {"event": "briefing_done"},
    N("Tap the GATE when you're ready to descend."),
]

D["hub_lab_mara"] = [
    MA("neutral", "Mara's lab. Officially 'Scale-State Instrumentation'. Unofficially, where the coffee lives.", **{"if_not": "rr_complete"}),
    MA("curious", "You're wondering about Dexter. Everyone does, eventually.", **{"if_not": "rr_complete"}),
    MA("focused", "Half the Gate math came off one whiteboard we shared. We could argue for hours and still solve the problem afterward.", **{"if_not": "rr_complete"}),
    MA("tired", "I know he isn't pretending to care about humanity. That's what frightens me.", **{"if_not": "rr_complete"}),
    MA("soft", "You came back. Both of them came back. On a first descent, that's the whole score.", **{"if": "rr_complete"}),
    MA("focused", "The Thoughtstone readings from your field log are... wrong. Not broken. Wrong in a very consistent direction.", **{"if": "rr_complete"}),
    MA("neutral", "Curiosity always wins. It just usually costs more than people expect."),
]

D["hub_debrief"] = [
    N("The Common. Hours later. The Tilt has almost faded."),
    MA("soft", "Seismographs on the Reaches went quiet an hour ago. The Ochre Span is holding.", **{"if": "ochre_span_braced"}),
    A("calm", "Holding is the job.", **{"if": "ochre_span_braced"}),
    MA("curious", "The Dominion filed a complaint. Forty pages. I'm framing page twelve.", **{"if": "ochre_span_braced"}),
    MA("tired", "The Dominion contract paid out. Supply lines are full for a month. The Span's sensors are... noisy.", **{"if": "ochre_span_failing"}),
    A("calm", "Bridges don't fail all at once. They fail when everyone stops listening.", **{"if": "ochre_span_failing"}),
    C("annoyed", "He's going to go back out there. I've seen it from four directions.", **{"if": "ochre_span_failing"}),
    MA("neutral", "Ecology flagged a disturbed grazer herd near the waystation. It will recover. Slowly.", **{"if": "grazers_harmed"}),
    MA("soft", "And the plate beetles walked away from the drill site on their own. That's the outcome I'll be quoting.", **{"if": "beetles_calmed"}),
    MA("focused", "Now. You brought life home with you. That makes it ours to keep alive."),
    MA("neutral", "We also pulled a dust grazer off the drill perimeter — Protective Extraction. It's stressed. It needs a Habitat.", **{"if_not": "has_specimen"}),
    MA("focused", "Habitats aren't cages. They're medicine. Soil, microbes, light, symbionts, a tuned Scale Anchor."),
    MA("neutral", "Get the chain right and it lives. Get it wrong and it won't. Habitat Wing's open."),
    {"set": {"debriefed": True}},
    {"event": "open_habitat"},
]

D["hub_habitat_intro"] = [
    MA("focused", "Four slots: Substrate, Symbiont, Climate, Anchor. Your scan data tells you what it needs."),
    MA("neutral", "Wrong pieces stress the resident. The better the Habitat, the healthier and more behaviourally complex it becomes."),
    A("calm", "If my bridge design is in the catalogue, it's free. I don't charge for load paths.", **{"if": "ochre_span_braced"}),
]

D["hub_hook"] = [
    N("Later. The Common Table. Aruun sets something down very carefully."),
    MA("annoyed", "We said don't touch it."),
    A("calm", "I didn't. It followed."),
    N("A sliver of Thoughtstone, smaller than a thumbnail. It turns on the tabletop until it points at Morrow. Then it stops."),
    MA("focused", "Thoughtstone near Morrow aligns its internal structure toward it. We've seen it in the lab. Never in the field."),
    A("focused", "And nobody cuts Morrow open to find out why. Morrow is not a sample."),
    C("focused", "I tried reading it. It has too many futures. Every one of them is pointing the same way."),
    MA("neutral", "Mineral. Organism. Network. Memory medium. Or something without a human category."),
    DX("amused", "Mara. Handler. Lovely work out there. One more thing before you pretend not to answer."),
    DX("serious", "Your rock turned. Ours did too. Every sample in my lab, the same second. Call me when you want to compare notes."),
    MA("tired", "...He's going to be impossible about this."),
    C("happy", "He was always going to be. That one I didn't need the crown for."),
    N("MYSTERY LOGGED — THOUGHTSTONE."),
    {"set": {"slice_complete": True}},
    {"event": "slice_end"},
]

# ambient cast — voices from Books VI, XIV, XXX
D["hub_npc_mollusk"] = [
    L("mollusk", "calm", "Ah. The new Handler. Slow down. ...No, truly. Most people move like the next second is free."),
    L("mollusk", "focused", "Every second is borrowed. Move someone. Brace something. Choose. Act. Don't admire the miracle — use it.", **{"if_not": "rr_complete"}),
    L("mollusk", "serene", "Aruun held a bridge again. Tell him I'm proud. Do not tell him I said proud.", **{"if": "ochre_span_braced"}),
    L("mollusk", "calm", "Some things don't break. They just take longer. That bridge is taking longer.", **{"if": "ochre_span_failing"}),
    L("mollusk", "curious", "Have you seen the new forklift in Bay Four? Don't answer. I'm going to go look at it again."),
]
D["hub_npc_bramvex"] = [
    L("bramvex", "default", "Handler. How many exits does this hall have?"),
    {"choice": [
        {"text": "Three?", "goto": "b_wrong"},
        {"text": "I haven't counted.", "goto": "b_honest"},
    ]},
    {"label": "b_wrong"},
    L("bramvex", "default", "Five. Two of them are vents. Count them. Every room, every time."),
    {"goto": "b_end"},
    {"label": "b_honest"},
    L("bramvex", "default", "Honest. Good. Now count. Every room, every time."),
    {"label": "b_end"},
    L("bramvex", "default", "If Cigarra improvises, let her. I leave deliberate gaps in my plans for her now. Someone named them. I regret it.", **{"if_not": "rr_complete"}),
    L("bramvex", "default", "You brought both of them back. That's the job. The rest is paperwork.", **{"if": "rr_complete"}),
]
D["hub_npc_nerit"] = [
    L("nerit", "default", "This hall has eleven cameras and nowhere to be unseen."),
    L("nerit", "default", "So I made one corner where light forgets to go. You're welcome to sit in it. Nobody has to watch you there."),
    L("nerit", "default", "Your physicists say my darkness is simply removed photons. They're describing the result, not the process."),
    L("nerit", "default", "You keep measuring light because you are afraid to measure absence.", **{"if": "rr_complete"}),
]
D["hub_npc_zephyr"] = [
    L("zephyr", "curious", "Courier? No — Handler. Same face as someone with a job to finish."),
    L("zephyr", "calm", "Promise me something. Anything small. You'd be surprised how few people do.", **{"if_not": "promised_zephyr"}),
    {"choice": [
        {"text": "I promise to bring them both home.", "set": {"promised_zephyr": True}, "goto": "z_promise"},
        {"text": "I don't make promises I can't word carefully.", "goto": "z_careful"},
    ], "if_not": "promised_zephyr"},
    {"label": "z_promise"},
    L("zephyr", "focused", "Witnessed. Wording noted. 'Both.' 'Home.' Don't break it.", **{"if_not": "rr_complete"}),
    L("zephyr", "calm", "You kept it. I like you a measurable amount more.", **{"if": "rr_complete"}),
    {"goto": "z_end"},
    {"label": "z_careful"},
    L("zephyr", "curious", "Oh, I like you. Careful wording is the whole art."),
    {"label": "z_end"},
    L("zephyr", "calm", "That drink on the table was unattended. That's practically a gift."),
]
D["hub_npc_nyxaris"] = [
    L("nyxaris", "default", "Do not step on the silk. It is not decoration. It is a sentence you are standing on."),
    L("nyxaris", "default", "Helix still calls my work 'secretion'. The court will learn to read.", **{"if_not": "rr_complete"}),
    L("nyxaris", "default", "They drilled a foundation that was not theirs. Ask them who gave them permission. Ask it slowly.", **{"if": "rr_complete"}),
]
D["hub_npc_pharilux"] = [
    L("pharilux", "watchful", "..."),
    {"choice": [
        {"text": "Where are you from?", "goto": "p_from"},
        {"text": "Keeping watch?", "goto": "p_watch"},
    ]},
    {"label": "p_from"},
    L("pharilux", "calm", "Wrong direction."),
    {"goto": "p_end"},
    {"label": "p_watch"},
    L("pharilux", "watchful", "Even in darkness, someone keeps watch."),
    {"label": "p_end"},
    L("pharilux", "calm", "Thresholds remember who crossed them carefully.", **{"if": "rr_complete"}),
]
D["hub_npc_solmara"] = [
    L("solmara", "default", "Handler. The tides here are very small. Pipes. Valves. Pumps."),
    L("solmara", "default", "Your plumbers are magnificent."),
    L("solmara", "default", "You are smiling. Is that a threat display? Mara says no. Mara is not always correct."),
    L("solmara", "default", "Your Moon. It is not in the wrong orbit. The relationship is displaced. There is a missing return.", **{"if": "rr_complete"}),
]
D["hub_npc_scarlith"] = [
    L("scarlith", "default", "Down here, Handler. Lower. On the table. Yes. Hello."),
    L("scarlith", "default", "Value begins where neglect ends. Neglect must be real, though. I am told this often.", **{"if_not": "rr_complete"}),
    L("scarlith", "default", "The Dominion bought a whole cache? Excellent customers. Terrible precedent.", **{"if": "ochre_span_failing"}),
    L("scarlith", "default", "A braced foundation. Nobody can sell that. Annoying. Admirable. Mostly annoying.", **{"if": "ochre_span_braced"}),
]

# ------------------------------------------------------------------ RED REACHES
D["rr_arrival"] = [
    M("focused", "Handler, read me? You're through. Vitals show the Tilt — that's normal. Give it a second."),
    C("unhinged", "Everything is very close and very far. I love it. I hate it. Mostly love."),
    A("calm", "The Red Reaches. Smell the iron in the dust."),
    A("focused", "The Ochre Span is east, past the fracture valley."),
    M("neutral", "Follow the valley floor east. I'm watching your telemetry."),
    {"set": {"arrived_rr": True}},
]
D["rr_valley"] = [
    C("focused", "Skitter mites. Six — no, four — no, six. The futures keep counting differently."),
    A("amused", "Then I'll count with Morrow."),
    M("focused", "Handler — scan before you swing. Know what you're hitting."),
]
D["rr_first_scan"] = [
    M("neutral", "That's your scanner. Wildlife, Sapient, Sacred, Resource, Dominion Asset. The label matters more than the health bar."),
    M("focused", "Anything wild and weakened can be contained and brought home. Anything sapient — never."),
    {"set": {"first_scan_done": True}},
]
D["rr_valley_clear"] = [
    A("calm", "Mites strip mineral crust off the rock. Annoying. Not evil."),
    C("happy", "You're kind to things that bite you."),
    A("calm", "Everything bites something."),
    {"set": {"valley_clear": True}},
]
D["rr_gap"] = [
    A("focused", "The old rope span is gone. Cut. Not rotted."),
    C("happy", "Gaps are my favourite shape. Swap to me, Handler — I'll hop it and drop a line for the big one."),
]
D["rr_rope"] = [
    C("happy", "Landed in the version where I land. Good version."),
    C("focused", "The Spanwright anchors on this side still hold. Dropping the line."),
    {"event": "drop_rope"},
    {"set": {"rope_dropped": True}},
    A("amused", "If this breaks, I'm telling everyone you planned it."),
    C("unhinged", "I did plan it. Just not the breaking part. Probably."),
]
D["rr_waystation"] = [
    A("calm", "A Spanwright waystation. Wells. Shade. A place to mend rope."),
    A("calm", "My teacher said infrastructure succeeds when people stop noticing the danger it protects them from."),
    C("curious", "Did you understand that when he said it?"),
    A("focused", "No. I understood it at Red Span."),
    C("neutral", "...Eleven minutes."),
    A("calm", "Thousands crossed. Hundreds didn't."),
    C("focused", "Here's a thing I don't usually do: ask before I look. Can I look at how we fight together?"),
    A("calm", "Look."),
    C("shocked", "Oh. You leave openings on purpose. For whoever's beside you."),
    A("calm", "For whoever carries the next part."),
    C("happy", "Then when I see where they'll be standing — you put Morrow there."),
    {"event": "unlock_combo"},
    {"set": {"combo_unlocked": True}},
    N("COMBO UNLOCKED — PROBABLE IMPACT. During Cigarra's Premonition, Aruun's Gravity Pull lands where she saw it would."),
    M("neutral", "One more thing. The grazers east of you are a keystone herd. Their droppings seed the lichen that holds that plateau together. Please don't."),
]
D["rr_marker_stone"] = [
    A("calm", "An Old Road marker. The same symbols turn up continents apart."),
    C("curious", "Nobody remembers who carved it. The stone remembers being read, though."),
    M("focused", "Logging it. Ruined causeways, dead trade languages... Critter's peoples have connected and forgotten each other many times."),
]
D["rr_grazers_harmed"] = [
    A("aggressive", "Stop. They're grazers."),
    M("annoyed", "Handler, that herd holds the soil together. Every action down there leaves something behind."),
    {"set": {"grazers_harmed": True}},
    {"trust": {"aruun": -3}},
]
D["rr_boulder"] = [
    A("focused", "Thoughtstone vein. Cracked straight through."),
    A("calm", "Morrow wants it. ...Morrow always wants it."),
    C("curious", "Morrow 'wants'?"),
    A("calm", "I don't call Morrow property. Swap to me. A Reaching Strike will open it."),
]
D["rr_boulder_broken"] = [
    N("The Thoughtstone fragments hum. For a moment, the dust drifts toward Morrow."),
    A("calm", "...Collect the dust. The Habitat techs will want it."),
    C("focused", "That one I couldn't read. Interesting."),
    {"set": {"boulder_broken": True}},
]
D["rr_drill"] = [
    M("focused", "That's the drill site. Dominion survey drones — and Handler, look at those beetles."),
    A("aggressive", "Plate beetles don't charge. They graze."),
    C("focused", "Something is singing at them. Scan one."),
]
D["rr_beetle_scanned"] = [
    M("focused", "Resonance pylons. The drill's tuning field is driving the beetles out of their minds."),
    A("focused", "Break the pylons and they calm."),
    C("happy", "Or fight a lot of very upset furniture. Your call, Handler."),
    {"set": {"beetle_scanned": True}},
]
D["rr_pylons_done"] = [
    N("The ringing stops. One by one, the beetles lower their plates and wander back toward the lichen."),
    A("calm", "Good. They were never the enemy."),
    {"set": {"beetles_calmed": True}},
    {"trust": {"aruun": 3, "cigarra": 2}},
]
D["rr_drill_clear"] = [
    M("neutral", "Site's quiet. The drill core runs east — straight under the Ochre Span."),
    {"set": {"drill_clear": True}},
]
D["rr_span"] = [
    A("calm", "The Ochre Span. Look at the keystones. Every one carries the next."),
    C("focused", "This bridge has more futures than most people. Most of them are falling."),
    A("focused", "Then we cross in one of the others."),
]
D["rr_burden"] = [
    N("Somewhere below, the drill bites deep. The Span lurches."),
    A("rage", "Handler — it's going! I can hold it!"),
    C("shocked", "Aruun, your shell —"),
    A("focused", "Move! I'll carry this part!"),
    {"event": "start_burden"},
]
D["rr_burden_done"] = [
    C("focused", "Across. Everyone's across. You can let go."),
    A("calm", "...Not eleven minutes. Just enough."),
    C("happy", "Just enough is my favourite amount."),
    {"set": {"burden_done": True}},
    {"trust": {"aruun": 5, "cigarra": 3}},
]
D["rr_boss_intro"] = [
    N("AUGUR-7 DEEPCORE RIG — DOMINION EXTRACTION PERMIT 7-K"),
    DX("amused", "Ah. You must be the Handler Mara sent. Hi. Dexter Mane. I'd shake your hand, but there's a scale-state in the way."),
    DX("neutral", "That rig is licensed, insured and very expensive. The foundation fails with or without it. I'm making sure the Thoughtstone doesn't fail with it."),
    A("aggressive", "You're the reason it's failing."),
    DX("serious", "I'm the reason it's being measured. Different thing."),
    C("focused", "His futures are sharp. Every one of them has a version where he's sorry. None of them has a version where he stops."),
    DX("genuine", "...That's unsettlingly fair. Do try not to break my drill more than necessary."),
    {"event": "start_boss"},
]
D["rr_boss_phase2"] = [
    M("focused", "It's overheating — the coolant vents are opening! Hit the vents!"),
]
D["rr_boss_phase3"] = [
    C("shocked", "Big beam. Lots of futures with holes in them. Stand in the ones without holes."),
    DX("serious", "Overdrive. That is... not a setting I approved."),
]
D["rr_boss_down"] = [
    N("The drill winds down. Beneath it, a cache of raw Thoughtstone lies exposed, humming against the cracked foundation."),
    A("focused", "There. That's what they were digging for."),
    {"set": {"boss_defeated": True}},
]
D["rr_choice"] = [
    DX("neutral", "Right. The honest version. That cache funds the next ten expeditions. Medicine. Materials. Gate research."),
    DX("amused", "Leave it for my recovery team and your Terrarium will be very, very well supplied."),
    M("focused", "Or you brace the foundation. Aruun's way. The Span stays up. The Dominion gets nothing — and remembers."),
    A("calm", "It isn't my choice, Handler. Burden Architecture: build so that if one part fails, the rest survives."),
    A("focused", "With that Thoughtstone, this foundation holds for a very long time."),
    C("neutral", "I'm not looking at this one. Some choices should be made without me touching them."),
    {"choice": [
        {"text": "Brace the foundation. The Span stays.", "goto": "repair"},
        {"text": "Hand the cache to the Dominion contract.", "goto": "extract"},
    ]},
    {"label": "repair"},
    {"event": "choice_repair"},
    {"end": True},
    {"label": "extract"},
    {"event": "choice_extract"},
    {"end": True},
]
D["rr_after_choice"] = [
    A("focused", "Morrow. Anchor.", **{"if": "ochre_span_braced"}),
    N("Aruun drives the Thoughtstone into the cracked foundation. The stone knits. The Span settles with a sound like a held breath let go.", **{"if": "ochre_span_braced"}),
    A("calm", "A structure should sacrifice itself before it sacrifices the people inside it. This one won't have to.", **{"if": "ochre_span_braced"}),
    DX("irritated", "...Noted. Genuinely. Enjoy your bridge.", **{"if": "ochre_span_braced"}),
    N("Dominion recovery lines lower from the rim and haul the cache away. The foundation groans.", **{"if": "ochre_span_failing"}),
    A("aggressive", "It'll stand a season. Maybe two.", **{"if": "ochre_span_failing"}),
    DX("genuine", "You made the useful choice. I know it doesn't feel like it. It rarely does.", **{"if": "ochre_span_failing"}),
    C("annoyed", "He says that a lot. I've seen him say it a lot.", **{"if": "ochre_span_failing"}),
    N("On the ground, a sliver of Thoughtstone turns slowly on its own — until it points at Morrow."),
    {"event": "thoughtstone_align"},
    C("shocked", "Aruun. That rock just turned."),
    A("focused", "...Morrow isn't surprised."),
    M("focused", "Log it. Don't touch it. Exfil beacon is up — come home."),
    {"set": {"rr_complete": True}},
]
D["rr_exfil"] = [
    M("soft", "Bringing you up. Brace for the Tilt."),
    {"event": "exfil"},
]
D["rr_party_down"] = [
    M("focused", "Vitals critical — pulling you back to the last safe point. Breathe."),
]

for k, lines in D.items():
    with open(os.path.join(OUT, k + ".json"), "w") as f:
        json.dump({"id": k, "lines": lines}, f, indent=1, ensure_ascii=False)
print("wrote", len(D), "dialogues to", os.path.abspath(OUT))
