# CRITTER v2 balance matrix

Bouts: 1920 (about 200 per ordered matchup, split over profiles novice/standard/expert, both seats), seed base 1, default stakes (Blood, lethal), arena ring.
Cell = win rate of ROW critter against COLUMN critter. Targets: overall 45-55%, no matchup beyond 40/60.

| row \ col | aruun | cigarra | bramvex | scarlith | mollusk | zephyr | nyxaris | pharilux | **overall** |
|---|---|---|---|---|---|---|---|---|---|
| **aruun** | - | 62% ! | 55% | 47% | 52% | 55% | 47% | 57% | **53.3%** |
| **cigarra** | 38% ! | - | 62% ! | 67% ! | 38% ! | 47% | 57% | 50% | **51.2%** |
| **bramvex** | 45% | 38% ! | - | 75% ! | 47% | 53% | 45% | 63% ! | **52.4%** |
| **scarlith** | 53% | 33% ! | 25% ! | - | 35% ! | 47% | 63% ! | 45% | **43.1%** ! |
| **mollusk** | 48% | 62% ! | 53% | 65% ! | - | 30% ! | 42% | 22% ! | **46.0%** |
| **zephyr** | 45% | 53% | 47% | 53% | 70% ! | - | 57% | 62% ! | **55.2%** ! |
| **nyxaris** | 53% | 43% | 55% | 37% ! | 58% | 43% | - | 40% | **47.1%** |
| **pharilux** | 43% | 50% | 37% ! | 55% | 78% ! | 38% ! | 60% | - | **51.7%** |

## Overall by AI profile

| critter | novice | standard | expert |
|---|---|---|---|
| aruun | 43.6% | 55.0% | 61.4% |
| cigarra | 50.0% | 52.9% | 50.7% |
| bramvex | 66.4% | 46.4% | 44.3% |
| scarlith | 54.3% | 34.3% | 40.7% |
| mollusk | 38.6% | 42.1% | 57.1% |
| zephyr | 51.4% | 59.3% | 55.0% |
| nyxaris | 36.4% | 43.6% | 61.4% |
| pharilux | 59.3% | 66.4% | 29.3% |

## Bout stats (row critter seated first)

| critter | avg seconds | KO % | ring-out % | timeout % | ability uses/bout | Last Stand % |
|---|---|---|---|---|---|---|
| aruun | 57 | 74 | 25 | 1 | 10.2 | 68 |
| cigarra | 43 | 76 | 24 | 0 | 8.2 | 50 |
| bramvex | 59 | 87 | 13 | 0 | 11.6 | 65 |
| scarlith | 47 | 80 | 17 | 3 | 11.3 | 54 |
| mollusk | 55 | 85 | 12 | 2 | 6.2 | 65 |
| zephyr | 51 | 82 | 18 | 0 | 12.8 | 65 |
| nyxaris | 52 | 87 | 13 | 0 | 5.6 | 65 |
| pharilux | 83 | 58 | 32 | 10 | 16.1 | 56 |

Seat bias: first seat wins 50.6% of bouts.

Matchups beyond 40/60: cigarra vs aruun = 38%, cigarra vs mollusk = 38%, bramvex vs cigarra = 38%, scarlith vs cigarra = 33%, scarlith vs bramvex = 25%, scarlith vs mollusk = 35%, mollusk vs zephyr = 30%, mollusk vs pharilux = 22%, nyxaris vs scarlith = 37%, pharilux vs bramvex = 37%, pharilux vs zephyr = 38%

## Role-pair matrix (row role vs column role, win rate of the row)

| role (critter) | breaker | warden | drifter | brewer | anchor | binder | reader |
|---|---|---|---|---|---|---|---|
| **breaker** (aruun) | - | 56.7% > | 55.0% | 46.7% | 51.7% | 46.7% | 61.7% |
| **warden** (pharilux) | 43.3% | - | 38.3% > | 55.0% | 78.3% | 60.0% | 50.0% |
| **drifter** (zephyr) | 45.0% | 61.7% | - | 53.3% > | 70.0% | 56.7% | 53.3% |
| **brewer** (scarlith) | 53.3% | 45.0% | 46.7% | - | 35.0% > | 63.3% | 33.3% |
| **anchor** (mollusk) | 48.3% | 21.7% | 30.0% | 65.0% | - | 41.7% > | 61.7% |
| **binder** (nyxaris) | 53.3% | 40.0% | 43.3% | 36.7% | 58.3% | - | 43.3% > |
| **reader** (cigarra) | 38.3% > | 50.0% | 46.7% | 66.7% | 38.3% | 56.7% | - |

`>` = the row role has the soft-counter advantage. Cycle: breaker > warden > drifter > brewer > anchor > binder > reader > breaker.

| disadvantaged role vs its counter | all AI levels | expert AI only |
|---|---|---|
| warden vs breaker | 43.3% | 35.0% |
| drifter vs warden | 61.7% | 75.0% |
| brewer vs drifter | 46.7% | 40.0% |
| anchor vs brewer | 65.0% | 85.0% |
| binder vs anchor | 58.3% | 75.0% |
| reader vs binder | 56.7% | 65.0% |
| breaker vs reader | 61.7% | 70.0% |

Out of role-pair targets: breaker>warden 56.7% (want 51-54), breaker~drifter 55.0% (want 46-54), warden>drifter 38.3% (want 51-54), warden~brewer 55.0% (want 46-54), warden~anchor 78.3% (want 46-54), warden~binder 60.0% (want 46-54), drifter~anchor 70.0% (want 46-54), drifter~binder 56.7% (want 46-54), brewer>anchor 35.0% (want 51-54), brewer~binder 63.3% (want 46-54), brewer~reader 33.3% (want 46-54), anchor>binder 41.7% (want 51-54), anchor~reader 61.7% (want 46-54), binder>reader 43.3% (want 51-54), reader>breaker 38.3% (want 51-54)
Disadvantaged below 46% at expert: warden vs breaker expert 35.0%, brewer vs drifter expert 40.0%

