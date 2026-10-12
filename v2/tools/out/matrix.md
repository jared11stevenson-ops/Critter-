# CRITTER v2 balance matrix

Bouts: 1470 (about 200 per ordered matchup, split over profiles novice/standard/expert, both seats), seed base 1, default stakes (Blood, lethal), arena ring.
Cell = win rate of ROW critter against COLUMN critter. Targets: overall 45-55%, no matchup beyond 40/60.

| row \ col | aruun | cigarra | bramvex | scarlith | mollusk | zephyr | nyxaris | **overall** |
|---|---|---|---|---|---|---|---|---|
| **aruun** | - | 47% | 88% ! | 32% ! | 47% | 53% | 45% | **51.9%** |
| **cigarra** | 53% | - | 68% ! | 48% | 35% ! | 63% ! | 47% | **52.5%** |
| **bramvex** | 12% ! | 32% ! | - | 82% ! | 53% | 78% ! | 30% ! | **47.8%** |
| **scarlith** | 68% ! | 52% | 18% ! | - | 65% ! | 45% | 48% | **49.4%** |
| **mollusk** | 53% | 65% ! | 47% | 35% ! | - | 25% ! | 52% | **46.1%** |
| **zephyr** | 47% | 37% ! | 22% ! | 55% | 75% ! | - | 49% | **47.4%** |
| **nyxaris** | 55% | 53% | 70% ! | 52% | 48% | 51% | - | **54.9%** |

## Overall by AI profile

| critter | novice | standard | expert |
|---|---|---|---|
| aruun | 43.3% | 52.5% | 60.0% |
| cigarra | 46.7% | 59.2% | 51.7% |
| bramvex | 72.5% | 35.0% | 35.8% |
| scarlith | 65.8% | 43.3% | 39.2% |
| mollusk | 35.8% | 45.8% | 56.7% |
| zephyr | 42.5% | 50.4% | 49.2% |
| nyxaris | 43.3% | 63.8% | 57.5% |

## Bout stats (row critter seated first)

| critter | avg seconds | KO % | ring-out % | timeout % | ability uses/bout | Last Stand % |
|---|---|---|---|---|---|---|
| aruun | 44 | 96 | 4 | 0 | 7.0 | 80 |
| cigarra | 35 | 92 | 8 | 0 | 6.8 | 62 |
| bramvex | 46 | 99 | 1 | 0 | 8.2 | 80 |
| scarlith | 34 | 97 | 3 | 0 | 8.0 | 69 |
| mollusk | 43 | 96 | 4 | 0 | 5.6 | 76 |
| zephyr | 44 | 95 | 5 | 0 | 10.7 | 76 |
| nyxaris | 40 | 97 | 3 | 0 | 4.3 | 69 |

Seat bias: first seat wins 48.0% of bouts.

Matchups beyond 40/60: aruun vs scarlith = 32%, cigarra vs mollusk = 35%, bramvex vs aruun = 12%, bramvex vs cigarra = 32%, bramvex vs nyxaris = 30%, scarlith vs bramvex = 18%, mollusk vs scarlith = 35%, mollusk vs zephyr = 25%, zephyr vs cigarra = 37%, zephyr vs bramvex = 22%

## Role-pair matrix (row role vs column role, win rate of the row)

| role (critter) | breaker | warden | drifter | brewer | anchor | binder | reader |
|---|---|---|---|---|---|---|---|
| **breaker** (aruun) | - | 88.3% > | 53.3% | 31.7% | 46.7% | 45.0% | 46.7% |
| **warden** (bramvex) | 11.7% | - | 78.3% > | 81.7% | 53.3% | 30.0% | 31.7% |
| **drifter** (zephyr) | 46.7% | 21.7% | - | 55.0% > | 75.0% | 49.2% | 36.7% |
| **brewer** (scarlith) | 68.3% | 18.3% | 45.0% | - | 65.0% > | 48.3% | 51.7% |
| **anchor** (mollusk) | 53.3% | 46.7% | 25.0% | 35.0% | - | 51.7% > | 65.0% |
| **binder** (nyxaris) | 55.0% | 70.0% | 50.8% | 51.7% | 48.3% | - | 53.3% > |
| **reader** (cigarra) | 53.3% > | 68.3% | 63.3% | 48.3% | 35.0% | 46.7% | - |

`>` = the row role has the soft-counter advantage. Cycle: breaker > warden > drifter > brewer > anchor > binder > reader > breaker.

| disadvantaged role vs its counter | all AI levels | expert AI only |
|---|---|---|
| warden vs breaker | 11.7% | 10.0% |
| drifter vs warden | 21.7% | 20.0% |
| brewer vs drifter | 45.0% | 35.0% |
| anchor vs brewer | 35.0% | 45.0% |
| binder vs anchor | 48.3% | 45.0% |
| reader vs binder | 46.7% | 55.0% |
| breaker vs reader | 46.7% | 55.0% |

Out of role-pair targets: breaker>warden 88.3% (want 51-54), breaker~brewer 31.7% (want 46-54), breaker~binder 45.0% (want 46-54), warden>drifter 78.3% (want 51-54), warden~brewer 81.7% (want 46-54), warden~binder 30.0% (want 46-54), warden~reader 31.7% (want 46-54), drifter>brewer 55.0% (want 51-54), drifter~anchor 75.0% (want 46-54), drifter~reader 36.7% (want 46-54), brewer>anchor 65.0% (want 51-54), anchor~reader 65.0% (want 46-54)
Disadvantaged below 46% at expert: warden vs breaker expert 10.0%, drifter vs warden expert 20.0%, brewer vs drifter expert 35.0%, anchor vs brewer expert 45.0%, binder vs anchor expert 45.0%

