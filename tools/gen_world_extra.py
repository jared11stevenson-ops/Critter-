import json
def P(k,x,z,r=0,s=1,**kw):
    d={"k":k,"p":[x,z]}
    if r: d["r"]=r
    if s!=1: d["s"]=s
    d.update(kw); return d
S=[]
S.append({"id":"waystation_camp","name":"Waystation Camp","center":[118,-2],"props":[
 P("tent",8,-4.8,80,1,c="#3f7a52"),P("tent",-9.6,-5.2,-20,1,c="#d1b88a"),P("fire",5.4,-7.2),P("rack",-7,5.5),P("barrels",-8.6,-2.6,0,1,n=3),
 P("cart",-3.5,8.5,160,1,n=2),P("lantern",-1,5),P("lantern",5.5,5),P("trough",9.5,8.5,0),
 P("terrace",3.5,11.8,90),P("sacks",-6.5,6.8,0,1,n=5,seed=3),P("banner",-1.5,-7.4,0,1,c="#c47a2a")]})
S.append({"id":"drovers_rest","name":"Drover's Rest","center":[133,-38],"props":[
 P("cart",-1,0,0,1,n=2),P("tent",6.2,2.5,200,1,c="#c9904a"),P("fire",3.2,-3.2),P("hitch",-5,-3,90,1,len=3),P("sacks",-4,2.5,0,1,n=4,seed=5),
 P("barrels",-2,-4.5,0,1,n=2),P("lantern",1,-5.5),P("stump",-6.2,1.8,0,0.8,seed=2),P("stump",-4.4,5.2,40,0.7,seed=4),P("stakes",-3.4,3.0,0,1,len=2.2)]})
S.append({"id":"salt_pans_works","name":"Salt Pans work-site","center":[110,34],"props":[
 P("well",0,0),P("salt_basin",-4,7,0,1,seed=1),P("salt_basin",2.2,8.8,0,1,seed=2),P("salt_basin",-8,0.5,90,1,seed=3),
 P("salt_pile",7,-4),P("salt_pile",-8,-5.5,0,0.8),P("rake",-1,5,40),P("rack",5,-5.5,0,1,c="#8d9a4a"),P("awning",7.2,1.2,0,1,c="#d9a45a"),
 P("sacks",-3,-4.5,0,1,n=4,seed=9,c="#efe9d8"),P("lantern",-6,-1)]})
S.append({"id":"well_line","name":"The Well Line","center":[0,0],"props":[
 P("crank_well",117.8,17.2),P("crank_well",116.3,22.0),P("crank_well",114.6,26.6)]})
S.append({"id":"survey_camp","name":"Survey Camp","center":[206,22],"props":[
 P("tent",-2,-5.5,0,1.15,c="#4f5560"),P("table",-2,-1.8,0),P("permit_board",2.5,-2.2,180),P("tripod",-7,-6),P("tripod",6.5,-6.5),
 P("mast",10,-4),P("crates",7,1,10),P("spool",-6.2,3),P("spool",-4.6,4.4),P("cot",-8,-1.8,90,1,c="#4f5560"),P("lantern",0.3,-3.2),P("lantern",4.5,-3.6),
 P("stakes",-10,6,0,1,len=3),P("barrels",8,-8,0,1,n=2)]})
S.append({"id":"pylon_watch","name":"Pylon watch post","center":[196,-12],"props":[
 P("tripod",-3.2,-1.3),P("tent",5,-5.5,0,1,c="#4f5560"),P("crates",-5,2.5,-20),P("stakes",1.6,2.4,0,1,len=2.0),P("lantern",3.2,-0.8),P("spool",-2,4)]})
S.append({"id":"overlook_works","name":"Spanwright Overlook","center":[238,-31],"props":[
 P("rail",7.2,0,90,1,len=10),P("telescope",5,-2.8,0),P("plinth",-1,-7,0),P("bench",-5,-1.5,90),P("table",-2.6,3.4,0),
 P("cairn",6,-5,0,1.4),P("cairn",6.8,-2,20,0.7,seed=2),P("cairn",6.8,2.2,70,0.7,seed=3),P("flagline",-5.5,-4.8,0,1,len=5),P("lantern",-4,5),P("lantern",4,5.2)]})
S.append({"id":"span_market","name":"Ochre Span market","center":[233,2],"props":[
 P("stall",-6.5,-6.2,0,1,c="#c8803a"),P("stall",-1.8,-6.3,0,1,c="#a8452f"),P("stall",3.0,-6.2,0,1,c="#d9b36a"),
 P("banner",10.5,4.2,0,1,c="#b0462a"),P("banner",10.5,-3.8,0,1,c="#d9a43a"),P("spool",8.5,3.2),P("flagline",-7,7,0,1,len=8),P("lantern",-8,-2),P("lantern",7,-2.5)]})
S.append({"id":"echo_hollow_wall","name":"Echo Hollow","center":[64,-33],"props":[
 P("glyph_wall",0,-1),P("standing_stone",-5,2,0,1,seed=1),P("standing_stone",5.6,1,0,0.9,seed=2),P("standing_stone",-3,6.5,0,0.8,seed=3),P("cairn",4.5,5.5,0,1)]})
S.append({"id":"vault_gate","name":"Thoughtstone Vault","center":[160,-29],"props":[
 P("vault_door",0,-3.4),P("cairn",-4.2,2,0,0.9),P("cairn",4.2,2.4,40,0.9,seed=2),P("standing_stone",-4.5,-2,0,0.9,seed=4),P("standing_stone",4.6,-2.4,0,0.9,seed=5)]})
S.append({"id":"cistern_basin","name":"The Cistern","center":[186,-37],"props":[
 P("pool",0,-0.5),P("slate",-5.5,3.5,0,1.0,seed=1),P("slate",5.5,3,30,0.8,seed=2),P("cairn",-5.5,-3.8,0,0.9,seed=3)]})
S.append({"id":"stranded_cart","name":"Stranded hauler","center":[72,0],"props":[
 P("broken_cart",3.2,2.4,15),P("sacks",0.5,6.0,0,1,n=3,seed=7),P("cairn",-3,-5,0,0.8,seed=5),P("barrels",-1.5,4.5,0,1,n=2)]})
S.append({"id":"beetle_slates","name":"Beetle slates","center":[197,9],"props":[
 P("slate",-5,-5,0,1.2,seed=1),P("slate",5.5,5,40,1.0,seed=2),P("slate",0.5,1,0,1.4,seed=3),P("slate",-9,10,20,1.0,seed=4)]})
def SG(x,z,yaw): return P("signpost",x,z,yaw)
S.append({"id":"wayfinding","name":"Wayfinding","center":[0,0],"props":[
 SG(66.0,-4.0,90),SG(125.0,-17.0,70),SG(118.0,13.5,-80),SG(162.0,-2.0,90),SG(192.5,-13.0,100),SG(234.0,-5.0,92),
 SG(20.0,5.0,0),SG(108.0,-2.0,0),SG(216.0,3.5,0)]})
trail={"path":[[12,4],[34,3],[58,1],[80,-1],[100,-1],[118,-1],[134,-2],[150,1],[164,6],[184,8],[214,3],[246,0]],"step":17,"side":3.4}
loot=[("reach_soil",121,4),("reach_soil",130,12),("reach_soil",142,-4),("lichen_culture",52,-4),("lichen_culture",190,6),("lichen_culture",204,13),
 ("thoughtstone_dust",162,-14),("thoughtstone_dust",68,-30),("thoughtstone_dust",246,-30),("salvage",188,18),("salvage",214,1),("salvage",200,27),("salvage",87,0),
 ("spanwright_cable",228,5),("spanwright_cable",240,5),("spanwright_cable",236,-26),("spanwright_cable",132,-44),
 ("red_slate_plate",192,0),("red_slate_plate",200,16),("red_slate_plate",198,9),
 ("keth_water_flask",117.5,19.5),("keth_water_flask",114.6,28.0),("thoughtstone_cache",312,-12)]
sites=[
 {"id":"survey_board","spoke":"","pos":[208.5,-6,20.5],"kind":"lore","label":"Read the permit board","r":3.0,"text":"Permit seven-one-four, stamped again. Under it, in pencil: 'the beetles are not trespassing'."},
 {"id":"way_notice","spoke":"","pos":[112,-3,-9],"kind":"lore","label":"Read the notice","r":3.0,"text":"A Spanwright notice: wells by the day, bridges by the generation. Whoever mends the rope first signs last."},
 {"id":"salt_tally","spoke":"","pos":[104,-3.5,38.5],"kind":"lore","label":"Read the tally marks","r":3.0,"text":"Sixteen columns of tally marks, one per Keth. The newest column is still wet."},
 {"id":"overlook_plinth","spoke":"","pos":[237,-3,-37.5],"kind":"lore","label":"Read the plinth","r":3.0,"text":"Load limits scratched into the stone, some scored out and written larger. Someone has written 'no' beside the last one."},
 {"id":"drover_tally","spoke":"","pos":[131,-3.5,-42.5],"kind":"lore","label":"Read the tally","r":3.0,"text":"A drover's tally: flour, rope, rope, rope. Under it: 'mind the third rut, it has opinions'."}]
secrets=[
 {"id":"rr_wayfarer_stone","name":"The Wayfarer's Capstone","hint":"A loose capstone in the Waystation ruin's shade.","how_found":"Stand in the old ruin's shadow and push at the loose capstone.","reward":"Behind the capstone: a rolled coil of spanwright cable, left for whoever mends the road next.","ledger_tags":["discovery","stewardship"],"reward_items":{"spanwright_cable":2},"trigger":{"pos":[121,-3,-7],"r":3.4,"mode":"interact","label":"Push the capstone"}},
 {"id":"rr_ticking_seam","name":"The Ticking Seam","hint":"The mites gather where the valley floor has cracked.","how_found":"Stand still at the fresh crack in the Fracture Valley while the mites tick.","reward":"The crack ticks, then stops. A seam of Thoughtstone dust is exposed, still warm.","ledger_tags":["discovery","curiosity"],"reward_items":{"thoughtstone_dust":2},"trigger":{"pos":[50,-4,-5],"r":3.0,"mode":"stand","stand_s":3.0}},
 {"id":"rr_salt_names","name":"The Salt Names","hint":"Names pressed into the salt crust by generations of keepers.","how_found":"Read the oldest row of salt marks at the Salt Pans.","reward":"The oldest names are a family's. The flask beneath them is still sealed and cold.","ledger_tags":["discovery","stewardship"],"reward_items":{"keth_water_flask":1},"trigger":{"pos":[104,-3.5,41],"r":3.2,"mode":"interact","label":"Read the salt names"}},
 {"id":"rr_vault_hum","name":"What the Vault Stores","hint":"A hum under the sealed door, stored carefully.","how_found":"Stand quietly at the sealed vault door once the boulder is broken.","reward":"The hum steadies. A shard hums back from between the door stones and falls into your hand.","ledger_tags":["discovery","burden"],"reward_items":{"thoughtstone_cache":1},"trigger":{"pos":[160,-4,-33],"r":3.4,"mode":"stand","stand_s":4.0,"when":{"flag":"boulder_broken"}}}]
d={"_doc":"World content layered on the Red Reaches by Agent 2 (game/world/red_reaches/level_red_reaches.gd): settlements/props for rr_settlements.gd, cairn_trail, loot (placed from the region loot_table; item, p=[x,z]), extra lore sites and secrets merged into the RegionRunner recipe (kept out of game/canon so Agent 3's data is untouched). Prop kinds: see RrSettlements._prop.",
 "settlements":S,"cairn_trail":trail,"loot":[{"item":i,"p":[x,z]} for i,x,z in loot],"sites":sites,"secrets":secrets,
 "signs":[{"spoke":"echo_hollow","p":[66.0,-4.0]},{"spoke":"drovers_rest","p":[125.0,-17.0]},{"spoke":"salt_pans","p":[118.0,13.5]},{"spoke":"thought_vault","p":[162.0,-2.0]},{"spoke":"cistern","p":[192.5,-13.0]},{"spoke":"overlook","p":[234.0,-5.0]}]}
json.dump(d,open("game/world/red_reaches/world_extra.json","w"),indent=1)
print(len(S), sum(len(s["props"]) for s in S))
