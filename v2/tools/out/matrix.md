# CRITTER v2 balance matrix

Bouts: 1920 (about 200 per ordered matchup, split over profiles novice/standard/expert, both seats), seed base 1, default stakes (Blood, lethal), arena ring.
Cell = win rate of ROW critter against COLUMN critter. Targets: overall 45-55%, no matchup beyond 40/60.

| row \ col | aruun | cigarra | bramvex | scarlith | mollusk | zephyr | nyxaris | pharilux | **overall** |
|---|---|---|---|---|---|---|---|---|---|
| **aruun** | - | 63% ! | 67% ! | 30% ! | 48% | 55% | 40% | 62% ! | **52.1%** |
| **cigarra** | 37% ! | - | 57% | 55% | 28% ! | 58% | 53% | 37% ! | **46.4%** |
| **bramvex** | 33% ! | 43% | - | 72% ! | 65% ! | 62% ! | 47% | 60% | **54.5%** |
| **scarlith** | 70% ! | 45% | 28% ! | - | 55% | 38% ! | 63% ! | 29% ! | **47.0%** |
| **mollusk** | 52% | 72% ! | 35% ! | 45% | - | 28% ! | 52% | 13% ! | **42.4%** ! |
| **zephyr** | 45% | 42% | 38% ! | 62% ! | 72% ! | - | 58% | 52% | **52.6%** |
| **nyxaris** | 60% | 47% | 53% | 37% ! | 48% | 42% | - | 38% ! | **46.3%** |
| **pharilux** | 38% ! | 63% ! | 40% | 71% ! | 87% ! | 48% | 63% ! | - | **58.6%** ! |

## Overall by AI profile

| critter | novice | standard | expert |
|---|---|---|---|
| aruun | 50.0% | 51.4% | 55.0% |
| cigarra | 42.1% | 47.1% | 50.0% |
| bramvex | 72.1% | 47.1% | 44.3% |
| scarlith | 61.1% | 37.9% | 42.1% |
| mollusk | 32.1% | 47.1% | 47.9% |
| zephyr | 47.9% | 56.4% | 53.6% |
| nyxaris | 40.0% | 40.4% | 58.6% |
| pharilux | 54.6% | 72.5% | 48.6% |

## Bout stats (row critter seated first)

| critter | avg seconds | KO % | ring-out % | timeout % | ability uses/bout | Last Stand % |
|---|---|---|---|---|---|---|
| aruun | 59 | 77 | 23 | 0 | 10.2 | 64 |
| cigarra | 45 | 72 | 25 | 3 | 8.6 | 55 |
| bramvex | 62 | 86 | 14 | 0 | 12.4 | 65 |
| scarlith | 46 | 77 | 20 | 3 | 11.2 | 56 |
| mollusk | 58 | 79 | 16 | 5 | 6.5 | 64 |
| zephyr | 55 | 80 | 19 | 1 | 13.6 | 64 |
| nyxaris | 54 | 84 | 13 | 3 | 5.7 | 62 |
| pharilux | 76 | 33 | 54 | 13 | 14.6 | 41 |

Seat bias: first seat wins 48.1% of bouts.

Matchups beyond 40/60: aruun vs scarlith = 30%, cigarra vs aruun = 37%, cigarra vs mollusk = 28%, cigarra vs pharilux = 37%, bramvex vs aruun = 33%, scarlith vs bramvex = 28%, scarlith vs zephyr = 38%, scarlith vs pharilux = 29%, mollusk vs bramvex = 35%, mollusk vs zephyr = 28%, mollusk vs pharilux = 13%, zephyr vs bramvex = 38%, nyxaris vs scarlith = 37%, nyxaris vs pharilux = 38%, pharilux vs aruun = 38%

## Role-pair matrix (row role vs column role, win rate of the row)

| role (critter) | breaker | warden | drifter | brewer | anchor | binder | reader |
|---|---|---|---|---|---|---|---|
| **breaker** (aruun) | - | 61.7% > | 55.0% | 30.0% | 48.3% | 40.0% | 63.3% |
| **warden** (pharilux) | 38.3% | - | 48.3% > | 70.8% | 86.7% | 62.5% | 63.3% |
| **drifter** (zephyr) | 45.0% | 51.7% | - | 61.7% > | 71.7% | 58.3% | 41.7% |
| **brewer** (scarlith) | 70.0% | 29.2% | 38.3% | - | 55.0% > | 63.3% | 45.0% |
| **anchor** (mollusk) | 51.7% | 13.3% | 28.3% | 45.0% | - | 51.7% > | 71.7% |
| **binder** (nyxaris) | 60.0% | 37.5% | 41.7% | 36.7% | 48.3% | - | 46.7% > |
| **reader** (cigarra) | 36.7% > | 36.7% | 58.3% | 55.0% | 28.3% | 53.3% | - |

`>` = the row role has the soft-counter advantage. Cycle: breaker > warden > drifter > brewer > anchor > binder > reader > breaker.

| disadvantaged role vs its counter | all AI levels | expert AI only |
|---|---|---|
| warden vs breaker | 38.3% | 50.0% |
| drifter vs warden | 51.7% | 45.0% |
| brewer vs drifter | 38.3% | 35.0% |
| anchor vs brewer | 45.0% | 50.0% |
| binder vs anchor | 48.3% | 50.0% |
| reader vs binder | 53.3% | 45.0% |
| breaker vs reader | 63.3% | 70.0% |

Out of role-pair targets: breaker>warden 61.7% (want 51-54), breaker~drifter 55.0% (want 46-54), breaker~brewer 30.0% (want 46-54), breaker~binder 40.0% (want 46-54), warden>drifter 48.3% (want 51-54), warden~brewer 70.8% (want 46-54), warden~anchor 86.7% (want 46-54), warden~binder 62.5% (want 46-54), warden~reader 63.3% (want 46-54), drifter>brewer 61.7% (want 51-54), drifter~anchor 71.7% (want 46-54), drifter~binder 58.3% (want 46-54), drifter~reader 41.7% (want 46-54), brewer>anchor 55.0% (want 51-54), brewer~binder 63.3% (want 46-54), brewer~reader 45.0% (want 46-54), anchor~reader 71.7% (want 46-54), binder>reader 46.7% (want 51-54), reader>breaker 36.7% (want 51-54)
Disadvantaged below 46% at expert: drifter vs warden expert 45.0%, brewer vs drifter expert 35.0%, reader vs binder expert 45.0%

