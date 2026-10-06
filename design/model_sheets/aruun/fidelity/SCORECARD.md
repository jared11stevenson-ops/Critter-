# Aruun fidelity scorecard (Lead-maintained; scores come ONLY from comparison renders)
| date | stage | Silhouette /25 | Proportions /20 | Head-Neck-Horns /15 | Armor-Clothing /15 | Anatomy-Limbs /10 | Asymmetry /5 | Materials /5 | Production /3 | Microdetail /2 | TOTAL | gate | evidence |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 2026-10-06 | BASELINE v3 (current aruun.glb) | 15 | 8 | 4 | 7 | 4 | 3 | 2 | 2 | 1 | 46 | G1 FAIL | tools/fidelity baseline_v3: IoU side 0.697 / back 0.852 / front(3/4) 0.575; head length +109%, neck top depth +136%, horn A side span +70%, thigh depth +206% (skirt panel), foot +32% |

## Gate 1 decision (2026-10-06)
Creator approved treating the proxy as a CONDITIONAL PASS (measured: IoU side 0.876 / back 0.884; all measured proportions within ~1-3 cm; inspectors 19-20/25, 17/20, 8-9/15 with +-4 noise) and approved moving to Gate 2 (primary forms) CONDITIONAL on the new design-locked reference views looking good.
LOCKED_BASELINE_02 (design/model_sheets/aruun/fidelity/proxy/LOCKED_BASELINE_02/) is the Gate 1 baseline. Gate 2 rule: every added form is measured against the reference; any form that lowers side/back IoU by >0.005 or worsens a measured region is rolled back.

## Creator approval (2026-10-06): the v2 reference views (design/reference_gen/aruun/v2/) approved as modeling references with these limits:
side/back (completed) and the two faces are AUTHORITATIVE; the true front and the 3/4 views are layout/color-blocking aids only (88% / 80%+ inferred): never take measurements from them.
Gate 2 (primary forms) started.
