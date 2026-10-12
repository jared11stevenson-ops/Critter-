# CRITTER v2 balance matrix

Bouts: 1920 (about 200 per ordered matchup, split over profiles novice/standard/expert, both seats), seed base 1, default stakes (Blood, lethal), arena ring.
Cell = win rate of ROW critter against COLUMN critter. Targets: overall 45-55%, no matchup beyond 40/60.

| row \ col | aruun | cigarra | bramvex | scarlith | mollusk | zephyr | nyxaris | pharilux | **overall** |
|---|---|---|---|---|---|---|---|---|---|
| **aruun** | - | 68% ! | 62% ! | 48% | 55% | 65% ! | 40% | 58% | **56.7%** ! |
| **cigarra** | 32% ! | - | 35% ! | 50% | 33% ! | 45% | 35% ! | 42% | **38.8%** ! |
| **bramvex** | 38% ! | 65% ! | - | 82% ! | 67% ! | 60% | 37% ! | 65% ! | **59.0%** ! |
| **scarlith** | 52% | 50% | 18% ! | - | 48% | 57% | 60% | 40% | **46.4%** |
| **mollusk** | 45% | 67% ! | 33% ! | 52% | - | 27% ! | 27% ! | 27% ! | **39.5%** ! |
| **zephyr** | 35% ! | 55% | 40% | 43% | 73% ! | - | 52% | 53% | **50.2%** |
| **nyxaris** | 60% | 65% ! | 63% ! | 40% | 73% ! | 48% | - | 43% | **56.2%** ! |
| **pharilux** | 42% | 58% | 35% ! | 60% | 73% ! | 47% | 57% | - | **53.1%** |

## Overall by AI profile

| critter | novice | standard | expert |
|---|---|---|---|
| aruun | 53.6% | 57.1% | 59.3% |
| cigarra | 27.9% | 47.9% | 40.7% |
| bramvex | 77.9% | 49.3% | 50.0% |
| scarlith | 60.7% | 30.0% | 48.6% |
| mollusk | 31.4% | 37.1% | 50.0% |
| zephyr | 47.1% | 51.4% | 52.1% |
| nyxaris | 44.3% | 56.4% | 67.9% |
| pharilux | 57.1% | 70.7% | 31.4% |

## Bout stats (row critter seated first)

| critter | avg seconds | KO % | ring-out % | timeout % | ability uses/bout | Last Stand % |
|---|---|---|---|---|---|---|
| aruun | 55 | 75 | 25 | 0 | 9.5 | 62 |
| cigarra | 45 | 72 | 28 | 0 | 8.3 | 54 |
| bramvex | 60 | 88 | 12 | 0 | 12.0 | 65 |
| scarlith | 48 | 85 | 12 | 2 | 11.6 | 55 |
| mollusk | 59 | 85 | 13 | 2 | 6.8 | 70 |
| zephyr | 52 | 81 | 19 | 0 | 13.0 | 67 |
| nyxaris | 51 | 87 | 13 | 0 | 5.4 | 62 |
| pharilux | 82 | 57 | 33 | 10 | 15.9 | 55 |

Seat bias: first seat wins 50.9% of bouts.

Matchups beyond 40/60: cigarra vs aruun = 32%, cigarra vs bramvex = 35%, cigarra vs mollusk = 33%, cigarra vs nyxaris = 35%, bramvex vs aruun = 38%, bramvex vs nyxaris = 37%, scarlith vs bramvex = 18%, mollusk vs bramvex = 33%, mollusk vs zephyr = 27%, mollusk vs nyxaris = 27%, mollusk vs pharilux = 27%, zephyr vs aruun = 35%, pharilux vs bramvex = 35%

## Role-pair matrix (row role vs column role, win rate of the row)

| role (critter) | breaker | warden | drifter | brewer | anchor | binder | reader |
|---|---|---|---|---|---|---|---|
| **breaker** (aruun) | - | 58.3% > | 65.0% | 48.3% | 55.0% | 40.0% | 68.3% |
| **warden** (pharilux) | 41.7% | - | 46.7% > | 60.0% | 73.3% | 56.7% | 58.3% |
| **drifter** (zephyr) | 35.0% | 53.3% | - | 43.3% > | 73.3% | 51.7% | 55.0% |
| **brewer** (scarlith) | 51.7% | 40.0% | 56.7% | - | 48.3% > | 60.0% | 50.0% |
| **anchor** (mollusk) | 45.0% | 26.7% | 26.7% | 51.7% | - | 26.7% > | 66.7% |
| **binder** (nyxaris) | 60.0% | 43.3% | 48.3% | 40.0% | 73.3% | - | 65.0% > |
| **reader** (cigarra) | 31.7% > | 41.7% | 45.0% | 50.0% | 33.3% | 35.0% | - |

`>` = the row role has the soft-counter advantage. Cycle: breaker > warden > drifter > brewer > anchor > binder > reader > breaker.

| disadvantaged role vs its counter | all AI levels | expert AI only |
|---|---|---|
| warden vs breaker | 41.7% | 30.0% |
| drifter vs warden | 53.3% | 75.0% |
| brewer vs drifter | 56.7% | 65.0% |
| anchor vs brewer | 51.7% | 60.0% |
| binder vs anchor | 73.3% | 80.0% |
| reader vs binder | 35.0% | 35.0% |
| breaker vs reader | 68.3% | 70.0% |

Out of role-pair targets: breaker>warden 58.3% (want 51-54), breaker~drifter 65.0% (want 46-54), breaker~anchor 55.0% (want 46-54), breaker~binder 40.0% (want 46-54), warden>drifter 46.7% (want 51-54), warden~brewer 60.0% (want 46-54), warden~anchor 73.3% (want 46-54), warden~binder 56.7% (want 46-54), warden~reader 58.3% (want 46-54), drifter>brewer 43.3% (want 51-54), drifter~anchor 73.3% (want 46-54), drifter~reader 55.0% (want 46-54), brewer>anchor 48.3% (want 51-54), brewer~binder 60.0% (want 46-54), anchor>binder 26.7% (want 51-54), anchor~reader 66.7% (want 46-54), binder>reader 65.0% (want 51-54), reader>breaker 31.7% (want 51-54)
Disadvantaged below 46% at expert: warden vs breaker expert 30.0%, reader vs binder expert 35.0%

