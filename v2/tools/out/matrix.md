# CRITTER v2 balance matrix

Bouts: 1920 (about 200 per ordered matchup, split over profiles novice/standard/expert, both seats), seed base 1, default stakes (Blood, lethal), arena ring.
Cell = win rate of ROW critter against COLUMN critter. Targets: overall 45-55%, no matchup beyond 40/60.

| row \ col | aruun | cigarra | bramvex | scarlith | mollusk | zephyr | nyxaris | pharilux | **overall** |
|---|---|---|---|---|---|---|---|---|---|
| **aruun** | - | 50% | 84% ! | 33% ! | 53% | 65% ! | 43% | 85% ! | **59.2%** ! |
| **cigarra** | 50% | - | 88% ! | 48% | 23% ! | 70% ! | 52% | 48% | **54.3%** |
| **bramvex** | 16% ! | 12% ! | - | 78% ! | 45% | 47% | 40% | 68% ! | **43.7%** ! |
| **scarlith** | 67% ! | 52% | 22% ! | - | 67% ! | 45% | 65% ! | 42% | **51.2%** |
| **mollusk** | 47% | 77% ! | 55% | 33% ! | - | 25% ! | 65% ! | 35% ! | **48.1%** |
| **zephyr** | 35% ! | 30% ! | 53% | 55% | 75% ! | - | 62% ! | 40% | **50.0%** |
| **nyxaris** | 57% | 48% | 60% | 35% ! | 35% ! | 38% ! | - | 37% ! | **44.3%** ! |
| **pharilux** | 15% ! | 52% | 32% ! | 58% | 65% ! | 60% | 63% ! | - | **49.3%** |

## Overall by AI profile

| critter | novice | standard | expert |
|---|---|---|---|
| aruun | 51.8% | 57.9% | 67.9% |
| cigarra | 47.1% | 60.0% | 55.7% |
| bramvex | 63.2% | 33.6% | 34.3% |
| scarlith | 66.4% | 40.0% | 47.1% |
| mollusk | 37.9% | 45.0% | 61.4% |
| zephyr | 40.7% | 50.7% | 58.6% |
| nyxaris | 31.4% | 49.3% | 52.1% |
| pharilux | 61.4% | 63.6% | 22.9% |

## Bout stats (row critter seated first)

| critter | avg seconds | KO % | ring-out % | timeout % | ability uses/bout | Last Stand % |
|---|---|---|---|---|---|---|
| aruun | 48 | 96 | 4 | 0 | 7.8 | 75 |
| cigarra | 38 | 90 | 10 | 0 | 7.3 | 57 |
| bramvex | 48 | 95 | 5 | 0 | 8.6 | 75 |
| scarlith | 37 | 97 | 3 | 0 | 8.8 | 62 |
| mollusk | 49 | 97 | 3 | 0 | 5.9 | 72 |
| zephyr | 46 | 95 | 5 | 0 | 11.2 | 72 |
| nyxaris | 43 | 96 | 4 | 0 | 4.6 | 75 |
| pharilux | 71 | 87 | 13 | 0 | 13.6 | 68 |

Seat bias: first seat wins 48.3% of bouts.

Matchups beyond 40/60: aruun vs scarlith = 33%, cigarra vs mollusk = 23%, bramvex vs aruun = 16%, bramvex vs cigarra = 12%, scarlith vs bramvex = 22%, mollusk vs scarlith = 33%, mollusk vs zephyr = 25%, mollusk vs pharilux = 35%, zephyr vs aruun = 35%, zephyr vs cigarra = 30%, nyxaris vs scarlith = 35%, nyxaris vs mollusk = 35%, nyxaris vs zephyr = 38%, nyxaris vs pharilux = 37%, pharilux vs aruun = 15%, pharilux vs bramvex = 32%

## Role-pair matrix (row role vs column role, win rate of the row)

| role (critter) | breaker | warden | drifter | brewer | anchor | binder | reader |
|---|---|---|---|---|---|---|---|
| **breaker** (aruun) | - | 85.0% > | 65.0% | 33.3% | 53.3% | 43.3% | 50.0% |
| **warden** (pharilux) | 15.0% | - | 60.0% > | 58.3% | 65.0% | 63.3% | 51.7% |
| **drifter** (zephyr) | 35.0% | 40.0% | - | 55.0% > | 75.0% | 61.7% | 30.0% |
| **brewer** (scarlith) | 66.7% | 41.7% | 45.0% | - | 66.7% > | 65.0% | 51.7% |
| **anchor** (mollusk) | 46.7% | 35.0% | 25.0% | 33.3% | - | 65.0% > | 76.7% |
| **binder** (nyxaris) | 56.7% | 36.7% | 38.3% | 35.0% | 35.0% | - | 48.3% > |
| **reader** (cigarra) | 50.0% > | 48.3% | 70.0% | 48.3% | 23.3% | 51.7% | - |

`>` = the row role has the soft-counter advantage. Cycle: breaker > warden > drifter > brewer > anchor > binder > reader > breaker.

| disadvantaged role vs its counter | all AI levels | expert AI only |
|---|---|---|
| warden vs breaker | 15.0% | 5.0% |
| drifter vs warden | 40.0% | 80.0% |
| brewer vs drifter | 45.0% | 20.0% |
| anchor vs brewer | 33.3% | 40.0% |
| binder vs anchor | 35.0% | 50.0% |
| reader vs binder | 51.7% | 65.0% |
| breaker vs reader | 50.0% | 65.0% |

Out of role-pair targets: breaker>warden 85.0% (want 51-54), breaker~drifter 65.0% (want 46-54), breaker~brewer 33.3% (want 46-54), breaker~binder 43.3% (want 46-54), warden>drifter 60.0% (want 51-54), warden~brewer 58.3% (want 46-54), warden~anchor 65.0% (want 46-54), warden~binder 63.3% (want 46-54), drifter>brewer 55.0% (want 51-54), drifter~anchor 75.0% (want 46-54), drifter~binder 61.7% (want 46-54), drifter~reader 30.0% (want 46-54), brewer>anchor 66.7% (want 51-54), brewer~binder 65.0% (want 46-54), anchor>binder 65.0% (want 51-54), anchor~reader 76.7% (want 46-54), binder>reader 48.3% (want 51-54), reader>breaker 50.0% (want 51-54)
Disadvantaged below 46% at expert: warden vs breaker expert 5.0%, brewer vs drifter expert 20.0%, anchor vs brewer expert 40.0%

