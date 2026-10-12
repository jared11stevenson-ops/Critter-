# CRITTER v2 balance matrix

Bouts: 1920 (about 200 per ordered matchup, split over profiles novice/standard/expert, both seats), seed base 1, default stakes (Blood, lethal), arena ring.
Cell = win rate of ROW critter against COLUMN critter. Targets: overall 45-55%, no matchup beyond 40/60.

| row \ col | aruun | cigarra | bramvex | scarlith | mollusk | zephyr | nyxaris | pharilux | **overall** |
|---|---|---|---|---|---|---|---|---|---|
| **aruun** | - | 75% ! | 62% ! | 43% | 40% | 67% ! | 48% | 62% ! | **56.7%** ! |
| **cigarra** | 25% ! | - | 60% | 47% | 27% ! | 45% | 57% | 43% | **43.3%** ! |
| **bramvex** | 38% ! | 40% | - | 77% ! | 55% | 50% | 47% | 53% | **51.4%** |
| **scarlith** | 57% | 53% | 23% ! | - | 33% ! | 45% | 45% | 37% ! | **41.9%** ! |
| **mollusk** | 60% | 73% ! | 45% | 67% ! | - | 28% ! | 50% | 22% ! | **49.3%** |
| **zephyr** | 33% ! | 55% | 50% | 55% | 72% ! | - | 53% | 52% | **52.9%** |
| **nyxaris** | 52% | 43% | 53% | 55% | 50% | 47% | - | 35% ! | **47.9%** |
| **pharilux** | 38% ! | 57% | 47% | 63% ! | 78% ! | 48% | 65% ! | - | **56.7%** ! |

## Overall by AI profile

| critter | novice | standard | expert |
|---|---|---|---|
| aruun | 52.1% | 59.3% | 58.6% |
| cigarra | 34.3% | 45.7% | 50.0% |
| bramvex | 66.4% | 39.3% | 48.6% |
| scarlith | 56.4% | 34.3% | 35.0% |
| mollusk | 42.9% | 46.4% | 58.6% |
| zephyr | 47.9% | 53.6% | 57.1% |
| nyxaris | 42.1% | 52.9% | 48.6% |
| pharilux | 57.9% | 68.6% | 43.6% |

## Bout stats (row critter seated first)

| critter | avg seconds | KO % | ring-out % | timeout % | ability uses/bout | Last Stand % |
|---|---|---|---|---|---|---|
| aruun | 57 | 73 | 26 | 1 | 10.0 | 63 |
| cigarra | 43 | 75 | 24 | 1 | 8.3 | 51 |
| bramvex | 60 | 81 | 19 | 0 | 12.0 | 61 |
| scarlith | 46 | 74 | 23 | 3 | 11.1 | 48 |
| mollusk | 57 | 82 | 13 | 5 | 6.4 | 58 |
| zephyr | 53 | 75 | 25 | 0 | 13.1 | 57 |
| nyxaris | 55 | 85 | 11 | 4 | 5.7 | 61 |
| pharilux | 80 | 41 | 45 | 15 | 15.5 | 49 |

Seat bias: first seat wins 50.8% of bouts.

Matchups beyond 40/60: cigarra vs aruun = 25%, cigarra vs mollusk = 27%, bramvex vs aruun = 38%, scarlith vs bramvex = 23%, scarlith vs mollusk = 33%, scarlith vs pharilux = 37%, mollusk vs zephyr = 28%, mollusk vs pharilux = 22%, zephyr vs aruun = 33%, nyxaris vs pharilux = 35%, pharilux vs aruun = 38%

## Role-pair matrix (row role vs column role, win rate of the row)

| role (critter) | breaker | warden | drifter | brewer | anchor | binder | reader |
|---|---|---|---|---|---|---|---|
| **breaker** (aruun) | - | 61.7% > | 66.7% | 43.3% | 40.0% | 48.3% | 75.0% |
| **warden** (pharilux) | 38.3% | - | 48.3% > | 63.3% | 78.3% | 65.0% | 56.7% |
| **drifter** (zephyr) | 33.3% | 51.7% | - | 55.0% > | 71.7% | 53.3% | 55.0% |
| **brewer** (scarlith) | 56.7% | 36.7% | 45.0% | - | 33.3% > | 45.0% | 53.3% |
| **anchor** (mollusk) | 60.0% | 21.7% | 28.3% | 66.7% | - | 50.0% > | 73.3% |
| **binder** (nyxaris) | 51.7% | 35.0% | 46.7% | 55.0% | 50.0% | - | 43.3% > |
| **reader** (cigarra) | 25.0% > | 43.3% | 45.0% | 46.7% | 26.7% | 56.7% | - |

`>` = the row role has the soft-counter advantage. Cycle: breaker > warden > drifter > brewer > anchor > binder > reader > breaker.

| disadvantaged role vs its counter | all AI levels | expert AI only |
|---|---|---|
| warden vs breaker | 38.3% | 35.0% |
| drifter vs warden | 51.7% | 50.0% |
| brewer vs drifter | 45.0% | 35.0% |
| anchor vs brewer | 66.7% | 85.0% |
| binder vs anchor | 50.0% | 40.0% |
| reader vs binder | 56.7% | 85.0% |
| breaker vs reader | 75.0% | 65.0% |

Out of role-pair targets: breaker>warden 61.7% (want 51-54), breaker~drifter 66.7% (want 46-54), breaker~brewer 43.3% (want 46-54), breaker~anchor 40.0% (want 46-54), warden>drifter 48.3% (want 51-54), warden~brewer 63.3% (want 46-54), warden~anchor 78.3% (want 46-54), warden~binder 65.0% (want 46-54), warden~reader 56.7% (want 46-54), drifter>brewer 55.0% (want 51-54), drifter~anchor 71.7% (want 46-54), drifter~reader 55.0% (want 46-54), brewer>anchor 33.3% (want 51-54), brewer~binder 45.0% (want 46-54), anchor>binder 50.0% (want 51-54), anchor~reader 73.3% (want 46-54), binder>reader 43.3% (want 51-54), reader>breaker 25.0% (want 51-54)
Disadvantaged below 46% at expert: warden vs breaker expert 35.0%, brewer vs drifter expert 35.0%, binder vs anchor expert 40.0%

