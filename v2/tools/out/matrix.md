# CRITTER v2 balance matrix

Bouts: 1920 (about 200 per ordered matchup, split over profiles novice/standard/expert, both seats), seed base 1, default stakes (Blood, lethal), arena ring.
Cell = win rate of ROW critter against COLUMN critter. Targets: overall 45-55%, no matchup beyond 40/60.

| row \ col | aruun | cigarra | bramvex | scarlith | mollusk | zephyr | nyxaris | pharilux | **overall** |
|---|---|---|---|---|---|---|---|---|---|
| **aruun** | - | 70% ! | 65% ! | 18% ! | 38% ! | 62% ! | 40% | 62% ! | **50.7%** |
| **cigarra** | 30% ! | - | 75% ! | 48% | 38% ! | 57% | 50% | 37% ! | **47.9%** |
| **bramvex** | 35% ! | 25% ! | - | 63% ! | 60% | 57% | 38% ! | 65% ! | **49.0%** |
| **scarlith** | 82% ! | 52% | 37% ! | - | 55% | 58% | 62% ! | 43% | **55.5%** ! |
| **mollusk** | 62% ! | 62% ! | 40% | 45% | - | 22% ! | 60% | 37% ! | **46.7%** |
| **zephyr** | 38% ! | 43% | 43% | 42% | 78% ! | - | 65% ! | 57% | **52.4%** |
| **nyxaris** | 60% | 50% | 62% ! | 38% ! | 40% | 35% ! | - | 40% | **46.4%** |
| **pharilux** | 38% ! | 63% ! | 35% ! | 57% | 63% ! | 43% | 60% | - | **51.4%** |

## Overall by AI profile

| critter | novice | standard | expert |
|---|---|---|---|
| aruun | 54.3% | 46.4% | 51.4% |
| cigarra | 47.9% | 45.7% | 50.0% |
| bramvex | 69.3% | 32.1% | 45.7% |
| scarlith | 60.7% | 52.1% | 53.6% |
| mollusk | 30.0% | 50.0% | 60.0% |
| zephyr | 48.6% | 50.0% | 58.6% |
| nyxaris | 32.9% | 55.7% | 50.7% |
| pharilux | 56.4% | 67.9% | 30.0% |

## Bout stats (row critter seated first)

| critter | avg seconds | KO % | ring-out % | timeout % | ability uses/bout | Last Stand % |
|---|---|---|---|---|---|---|
| aruun | 48 | 92 | 8 | 0 | 7.9 | 76 |
| cigarra | 38 | 82 | 18 | 0 | 7.2 | 62 |
| bramvex | 49 | 98 | 2 | 0 | 8.9 | 78 |
| scarlith | 38 | 98 | 2 | 0 | 8.9 | 58 |
| mollusk | 49 | 96 | 4 | 0 | 6.0 | 74 |
| zephyr | 46 | 95 | 5 | 0 | 11.4 | 75 |
| nyxaris | 41 | 92 | 8 | 0 | 4.3 | 66 |
| pharilux | 69 | 81 | 19 | 0 | 13.5 | 66 |

Seat bias: first seat wins 50.1% of bouts.

Matchups beyond 40/60: aruun vs scarlith = 18%, aruun vs mollusk = 38%, cigarra vs aruun = 30%, cigarra vs mollusk = 38%, cigarra vs pharilux = 37%, bramvex vs aruun = 35%, bramvex vs cigarra = 25%, bramvex vs nyxaris = 38%, scarlith vs bramvex = 37%, mollusk vs zephyr = 22%, mollusk vs pharilux = 37%, zephyr vs aruun = 38%, nyxaris vs scarlith = 38%, nyxaris vs zephyr = 35%, pharilux vs aruun = 38%, pharilux vs bramvex = 35%

## Role-pair matrix (row role vs column role, win rate of the row)

| role (critter) | breaker | warden | drifter | brewer | anchor | binder | reader |
|---|---|---|---|---|---|---|---|
| **breaker** (aruun) | - | 61.7% > | 61.7% | 18.3% | 38.3% | 40.0% | 70.0% |
| **warden** (pharilux) | 38.3% | - | 43.3% > | 56.7% | 63.3% | 60.0% | 63.3% |
| **drifter** (zephyr) | 38.3% | 56.7% | - | 41.7% > | 78.3% | 65.0% | 43.3% |
| **brewer** (scarlith) | 81.7% | 43.3% | 58.3% | - | 55.0% > | 61.7% | 51.7% |
| **anchor** (mollusk) | 61.7% | 36.7% | 21.7% | 45.0% | - | 60.0% > | 61.7% |
| **binder** (nyxaris) | 60.0% | 40.0% | 35.0% | 38.3% | 40.0% | - | 50.0% > |
| **reader** (cigarra) | 30.0% > | 36.7% | 56.7% | 48.3% | 38.3% | 50.0% | - |

`>` = the row role has the soft-counter advantage. Cycle: breaker > warden > drifter > brewer > anchor > binder > reader > breaker.

| disadvantaged role vs its counter | all AI levels | expert AI only |
|---|---|---|
| warden vs breaker | 38.3% | 25.0% |
| drifter vs warden | 56.7% | 80.0% |
| brewer vs drifter | 58.3% | 40.0% |
| anchor vs brewer | 45.0% | 75.0% |
| binder vs anchor | 40.0% | 55.0% |
| reader vs binder | 50.0% | 55.0% |
| breaker vs reader | 70.0% | 50.0% |

Out of role-pair targets: breaker>warden 61.7% (want 51-54), breaker~drifter 61.7% (want 46-54), breaker~brewer 18.3% (want 46-54), breaker~anchor 38.3% (want 46-54), breaker~binder 40.0% (want 46-54), warden>drifter 43.3% (want 51-54), warden~brewer 56.7% (want 46-54), warden~anchor 63.3% (want 46-54), warden~binder 60.0% (want 46-54), warden~reader 63.3% (want 46-54), drifter>brewer 41.7% (want 51-54), drifter~anchor 78.3% (want 46-54), drifter~binder 65.0% (want 46-54), drifter~reader 43.3% (want 46-54), brewer>anchor 55.0% (want 51-54), brewer~binder 61.7% (want 46-54), anchor>binder 60.0% (want 51-54), anchor~reader 61.7% (want 46-54), binder>reader 50.0% (want 51-54), reader>breaker 30.0% (want 51-54)
Disadvantaged below 46% at expert: warden vs breaker expert 25.0%, brewer vs drifter expert 40.0%

