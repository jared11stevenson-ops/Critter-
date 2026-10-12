# CRITTER v2 balance matrix

Bouts: 1920 (about 200 per ordered matchup, split over profiles novice/standard/expert, both seats), seed base 1, default stakes (Blood, lethal), arena ring.
Cell = win rate of ROW critter against COLUMN critter. Targets: overall 45-55%, no matchup beyond 40/60.

| row \ col | aruun | cigarra | bramvex | scarlith | mollusk | zephyr | nyxaris | pharilux | **overall** |
|---|---|---|---|---|---|---|---|---|---|
| **aruun** | - | 45% | 75% ! | 38% ! | 43% | 73% ! | 47% | 47% | **52.6%** |
| **cigarra** | 55% | - | 68% ! | 61% ! | 32% ! | 65% ! | 57% | 20% ! | **51.1%** |
| **bramvex** | 25% ! | 32% ! | - | 68% ! | 48% | 53% | 33% ! | 13% ! | **39.0%** ! |
| **scarlith** | 62% ! | 39% ! | 32% ! | - | 67% ! | 40% | 65% ! | 13% ! | **45.4%** |
| **mollusk** | 57% | 68% ! | 52% | 33% ! | - | 30% ! | 61% ! | 17% ! | **45.4%** |
| **zephyr** | 27% ! | 35% ! | 47% | 60% | 70% ! | - | 47% | 8% ! | **41.9%** ! |
| **nyxaris** | 53% | 43% | 67% ! | 35% ! | 39% ! | 53% | - | 25% ! | **45.1%** |
| **pharilux** | 53% | 80% ! | 87% ! | 87% ! | 83% ! | 92% ! | 75% ! | - | **79.5%** ! |

## Overall by AI profile

| critter | novice | standard | expert |
|---|---|---|---|
| aruun | 47.1% | 52.1% | 58.6% |
| cigarra | 44.3% | 51.1% | 57.9% |
| bramvex | 57.9% | 34.3% | 25.0% |
| scarlith | 57.1% | 33.2% | 45.7% |
| mollusk | 31.1% | 48.6% | 56.4% |
| zephyr | 38.6% | 42.1% | 45.0% |
| nyxaris | 38.2% | 45.7% | 51.4% |
| pharilux | 85.7% | 92.9% | 60.0% |

## Bout stats (row critter seated first)

| critter | avg seconds | KO % | ring-out % | timeout % | ability uses/bout | Last Stand % |
|---|---|---|---|---|---|---|
| aruun | 45 | 93 | 7 | 0 | 7.2 | 78 |
| cigarra | 34 | 85 | 15 | 0 | 6.7 | 59 |
| bramvex | 46 | 97 | 3 | 0 | 8.4 | 83 |
| scarlith | 33 | 98 | 2 | 0 | 7.9 | 65 |
| mollusk | 46 | 97 | 3 | 0 | 5.6 | 74 |
| zephyr | 42 | 96 | 4 | 0 | 10.6 | 79 |
| nyxaris | 40 | 96 | 4 | 0 | 4.3 | 71 |
| pharilux | 46 | 88 | 12 | 0 | 9.2 | 42 |

Seat bias: first seat wins 49.1% of bouts.

Matchups beyond 40/60: aruun vs scarlith = 38%, cigarra vs mollusk = 32%, cigarra vs pharilux = 20%, bramvex vs aruun = 25%, bramvex vs cigarra = 32%, bramvex vs nyxaris = 33%, bramvex vs pharilux = 13%, scarlith vs cigarra = 39%, scarlith vs bramvex = 32%, scarlith vs pharilux = 13%, mollusk vs scarlith = 33%, mollusk vs zephyr = 30%, mollusk vs pharilux = 17%, zephyr vs aruun = 27%, zephyr vs cigarra = 35%, zephyr vs pharilux = 8%, nyxaris vs scarlith = 35%, nyxaris vs mollusk = 39%, nyxaris vs pharilux = 25%

## Role-pair matrix (row role vs column role, win rate of the row)

| role (critter) | breaker | warden | drifter | brewer | anchor | binder | reader |
|---|---|---|---|---|---|---|---|
| **breaker** (aruun) | - | 46.7% > | 73.3% | 38.3% | 43.3% | 46.7% | 45.0% |
| **warden** (pharilux) | 53.3% | - | 91.7% > | 86.7% | 83.3% | 75.0% | 80.0% |
| **drifter** (zephyr) | 26.7% | 8.3% | - | 60.0% > | 70.0% | 46.7% | 35.0% |
| **brewer** (scarlith) | 61.7% | 13.3% | 40.0% | - | 66.7% > | 65.0% | 39.2% |
| **anchor** (mollusk) | 56.7% | 16.7% | 30.0% | 33.3% | - | 60.8% > | 68.3% |
| **binder** (nyxaris) | 53.3% | 25.0% | 53.3% | 35.0% | 39.2% | - | 43.3% > |
| **reader** (cigarra) | 55.0% > | 20.0% | 65.0% | 60.8% | 31.7% | 56.7% | - |

`>` = the row role has the soft-counter advantage. Cycle: breaker > warden > drifter > brewer > anchor > binder > reader > breaker.

| disadvantaged role vs its counter | all AI levels | expert AI only |
|---|---|---|
| warden vs breaker | 53.3% | 25.0% |
| drifter vs warden | 8.3% | 15.0% |
| brewer vs drifter | 40.0% | 45.0% |
| anchor vs brewer | 33.3% | 40.0% |
| binder vs anchor | 39.2% | 35.0% |
| reader vs binder | 56.7% | 60.0% |
| breaker vs reader | 45.0% | 25.0% |

Out of role-pair targets: breaker>warden 46.7% (want 51-54), breaker~drifter 73.3% (want 46-54), breaker~brewer 38.3% (want 46-54), breaker~anchor 43.3% (want 46-54), warden>drifter 91.7% (want 51-54), warden~brewer 86.7% (want 46-54), warden~anchor 83.3% (want 46-54), warden~binder 75.0% (want 46-54), warden~reader 80.0% (want 46-54), drifter>brewer 60.0% (want 51-54), drifter~anchor 70.0% (want 46-54), drifter~reader 35.0% (want 46-54), brewer>anchor 66.7% (want 51-54), brewer~binder 65.0% (want 46-54), brewer~reader 39.2% (want 46-54), anchor>binder 60.8% (want 51-54), anchor~reader 68.3% (want 46-54), binder>reader 43.3% (want 51-54), reader>breaker 55.0% (want 51-54)
Disadvantaged below 46% at expert: warden vs breaker expert 25.0%, drifter vs warden expert 15.0%, brewer vs drifter expert 45.0%, anchor vs brewer expert 40.0%, binder vs anchor expert 35.0%, breaker vs reader expert 25.0%

