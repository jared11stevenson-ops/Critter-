# Multi-agent reference fidelity protocol (creator-supplied; binding for all character models, starting with Aruun)

Mission: make the Blender model CONVERGE TOWARD the supplied reference. Reference fidelity outranks beauty, detail, complexity, realism,
personal preference and preservation of previous work. Reference = the cleaned original ortho views in design/reference_packs/<id>/ortho
(+ parts.json, ARUUN_BRIEF.md). The only reward signal is measurable reference-fidelity improvement.

Chain of authority: Lead -> Reference Forensics -> Primary Modeler -> Visual Inspector -> Lead review -> Correction loop ->
Production Specialist -> Material Specialist -> Final visual inspection. Specialists are NOT independent designers.

Roles
1. FORENSICS (never models): measures normalized character height, head, snout, neck length/width, shoulders, torso, waist, pelvis, arm, forearm, hand,
   thigh, shin, foot, horn height/spread; silhouette landmarks, negative spaces, asymmetry, armor/cloth boundaries; classifies every feature
   IMMUTABLE / STRUCTURAL / SECONDARY / SURFACE. Output = CHARACTER SPECIFICATION (source of truth) + measuring tool (tools/fidelity/).
2. PRIMARY MODELER: follows the spec, no redesign. Starts with an extremely simple proxy, no details until approved. After each pass: SAVE,
   RENDER VALIDATION VIEWS (same cameras as the reference), HAND OFF. Never grades itself.
3. ADVERSARIAL INSPECTOR (blind: gets only REFERENCE + CURRENT RENDER; no effort, history, previous scores or modeler opinion): finds errors,
   region by region, issues CORRECTION TICKETS (REGION, SEVERITY 1-10, ERROR TYPE, REFERENCE, CURRENT MODEL, REQUIRED CORRECTION, ESTIMATED MAGNITUDE).
   Never edits geometry. Never praises without evidence.
4. PRODUCTION SPECIALIST (after primary forms pass): topology, edge flow, deformation, intersections, organization, UV readiness, performance.
   May not change proportions/silhouette/design; submits CHANGE REQUESTS instead.
5. MATERIAL/STYLE SPECIALIST (after geometry is locked): color/value grouping, roughness, painted variation, material separation, hierarchy in the
   concept's style (not photoreal). May not hide wrong geometry or alter proportions.
LEAD (art director): controls progression; keeps the SCORECARD; arbitrates with visible evidence only.

Scorecard (/100, from comparison renders only): Silhouette /25, Proportions /20, Head-Neck-Horns /15, Armor-Clothing /15, Anatomy-Limbs /10,
Asymmetry /5, Materials /5, Production readiness /3, Microdetail /2. Never raise a score for effort, complexity, "looks cool" or "code worked".

Gates: G1 PROXY: Silhouette >=22.5/25, Proportions >=18/20, Head-Neck-Horns >=13.5/15 (else keep blocking out; no armor detail, materials or sculpt).
G2 PRIMARY FORMS: >=90/100 excluding unavailable later categories. G3 DESIGN FORMS: reference geometry >=92% (production cleanup may begin).
G4 MATERIALS only after geometry is locked. G5 FINAL: >=92/100 AND Silhouette, Proportions, Head-Neck-Horns each >=90%.

Correction loop (mandatory): Modeler models -> Inspector renders/inspects -> Forensics checks the inspector against the reference -> Lead turns confirmed
discrepancies into prioritized tickets -> Modeler fixes the THREE highest-severity tickets only -> rerender -> regrade. Never fix twenty things at once.
Anti-groupthink: Inspector challenges the model, Forensics challenges the Inspector, Lead arbitrates by visible evidence; agreement is not evidence.
Regression protection: every approved stage is saved as LOCKED_BASELINE_NN; later work is compared to it; if detail reduces fidelity, roll back or correct.
Delete bad work: sunk cost is zero; rebuild a component if that beats patching.
Stop only when render->inspect->correct cycles yield minor gains AND every gate passes.
