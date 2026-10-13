# CRITTER v2 balance matrix

Bouts: 1920 (about 30 per ordered matchup, split over profiles novice/standard/expert, both seats), seed base 41, default stakes (Blood, lethal), arena ring.
Cell = win rate of ROW critter against COLUMN critter. Targets: overall 45-55%, no matchup beyond 40/60.

| row \ col | aruun | cigarra | bramvex | scarlith | mollusk | zephyr | nyxaris | pharilux | **overall** |
|---|---|---|---|---|---|---|---|---|---|
| **aruun** | - | 57% | 50% | 37% ! | 47% | 57% | 43% | 65% ! | **50.7%** |
| **cigarra** | 43% | - | 50% | 63% ! | 33% ! | 62% ! | 60% | 53% | **52.1%** |
| **bramvex** | 50% | 50% | - | 70% ! | 60% | 50% | 48% | 60% | **55.5%** ! |
| **scarlith** | 63% ! | 37% ! | 30% ! | - | 43% | 43% | 53% | 47% | **45.2%** |
| **mollusk** | 53% | 67% ! | 40% | 57% | - | 27% ! | 48% | 25% ! | **45.2%** |
| **zephyr** | 43% | 38% ! | 50% | 57% | 73% ! | - | 73% ! | 67% ! | **57.4%** ! |
| **nyxaris** | 57% | 40% | 52% | 47% | 52% | 27% ! | - | 45% | **45.5%** |
| **pharilux** | 35% ! | 47% | 40% | 53% | 75% ! | 33% ! | 55% | - | **48.3%** |

## Overall by AI profile

| critter | novice | standard | expert |
|---|---|---|---|
| aruun | 52.9% | 45.7% | 53.6% |
| cigarra | 42.9% | 57.1% | 56.4% |
| bramvex | 79.3% | 45.7% | 41.4% |
| scarlith | 60.7% | 39.3% | 35.7% |
| mollusk | 32.1% | 48.6% | 55.0% |
| zephyr | 50.0% | 61.4% | 60.7% |
| nyxaris | 35.0% | 42.1% | 59.3% |
| pharilux | 47.1% | 60.0% | 37.9% |

## Bout stats (row critter seated first)

| critter | avg seconds | KO % | ring-out % | timeout % | ability uses/bout | Last Stand % |
|---|---|---|---|---|---|---|
| aruun | 58 | 70 | 29 | 1 | 10.3 | 63 |
| cigarra | 40 | 74 | 25 | 1 | 7.8 | 45 |
| bramvex | 61 | 85 | 15 | 0 | 12.0 | 67 |
| scarlith | 47 | 82 | 15 | 3 | 11.4 | 54 |
| mollusk | 54 | 78 | 18 | 4 | 6.1 | 54 |
| zephyr | 54 | 78 | 21 | 2 | 13.4 | 61 |
| nyxaris | 53 | 81 | 16 | 3 | 5.5 | 64 |
| pharilux | 78 | 34 | 48 | 19 | 15.1 | 45 |

Seat bias: first seat wins 49.3% of bouts.

Matchups beyond 40/60: aruun vs scarlith = 37%, cigarra vs mollusk = 33%, scarlith vs cigarra = 37%, scarlith vs bramvex = 30%, mollusk vs zephyr = 27%, mollusk vs pharilux = 25%, zephyr vs cigarra = 38%, nyxaris vs zephyr = 27%, pharilux vs aruun = 35%, pharilux vs zephyr = 33%

## Role-pair matrix (row role vs column role, win rate of the row)

| role (critter) | breaker | warden | drifter | brewer | anchor | binder | reader |
|---|---|---|---|---|---|---|---|
| **breaker** (aruun) | - | 65.0% > | 56.7% | 36.7% | 46.7% | 43.3% | 56.7% |
| **warden** (pharilux) | 35.0% | - | 33.3% > | 53.3% | 75.0% | 55.0% | 46.7% |
| **drifter** (zephyr) | 43.3% | 66.7% | - | 56.7% > | 73.3% | 73.3% | 38.3% |
| **brewer** (scarlith) | 63.3% | 46.7% | 43.3% | - | 43.3% > | 53.3% | 36.7% |
| **anchor** (mollusk) | 53.3% | 25.0% | 26.7% | 56.7% | - | 48.3% > | 66.7% |
| **binder** (nyxaris) | 56.7% | 45.0% | 26.7% | 46.7% | 51.7% | - | 40.0% > |
| **reader** (cigarra) | 43.3% > | 53.3% | 61.7% | 63.3% | 33.3% | 60.0% | - |

`>` = the row role has the soft-counter advantage. Cycle: breaker > warden > drifter > brewer > anchor > binder > reader > breaker.

| disadvantaged role vs its counter | all AI levels | expert AI only |
|---|---|---|
| warden vs breaker | 35.0% | 35.0% |
| drifter vs warden | 66.7% | 70.0% |
| brewer vs drifter | 43.3% | 25.0% |
| anchor vs brewer | 56.7% | 65.0% |
| binder vs anchor | 51.7% | 50.0% |
| reader vs binder | 60.0% | 50.0% |
| breaker vs reader | 56.7% | 45.0% |

Out of role-pair targets: breaker>warden 65.0% (want 51-54), breaker~drifter 56.7% (want 46-54), breaker~brewer 36.7% (want 46-54), breaker~binder 43.3% (want 46-54), warden>drifter 33.3% (want 51-54), warden~anchor 75.0% (want 46-54), warden~binder 55.0% (want 46-54), drifter>brewer 56.7% (want 51-54), drifter~anchor 73.3% (want 46-54), drifter~binder 73.3% (want 46-54), drifter~reader 38.3% (want 46-54), brewer>anchor 43.3% (want 51-54), brewer~reader 36.7% (want 46-54), anchor>binder 48.3% (want 51-54), anchor~reader 66.7% (want 46-54), binder>reader 40.0% (want 51-54), reader>breaker 43.3% (want 51-54)
Disadvantaged below 46% at expert: warden vs breaker expert 35.0%, brewer vs drifter expert 25.0%, breaker vs reader expert 45.0%

