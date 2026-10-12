# CRITTER v2 balance matrix

Bouts: 1920 (about 200 per ordered matchup, split over profiles novice/standard/expert, both seats), seed base 1, default stakes (Blood, lethal), arena ring.
Cell = win rate of ROW critter against COLUMN critter. Targets: overall 45-55%, no matchup beyond 40/60.

| row \ col | aruun | cigarra | bramvex | scarlith | mollusk | zephyr | nyxaris | pharilux | **overall** |
|---|---|---|---|---|---|---|---|---|---|
| **aruun** | - | 45% | 70% ! | 30% ! | 33% ! | 63% ! | 38% ! | 82% ! | **51.7%** |
| **cigarra** | 55% | - | 53% | 60% | 25% ! | 57% | 45% | 43% | **48.3%** |
| **bramvex** | 30% ! | 47% | - | 77% ! | 48% | 63% ! | 32% ! | 65% ! | **51.7%** |
| **scarlith** | 70% ! | 40% | 23% ! | - | 77% ! | 42% | 65% ! | 40% | **51.0%** |
| **mollusk** | 67% ! | 75% ! | 52% | 23% ! | - | 25% ! | 53% | 32% ! | **46.7%** |
| **zephyr** | 37% ! | 43% | 37% ! | 58% | 75% ! | - | 55% | 35% ! | **48.6%** |
| **nyxaris** | 62% ! | 55% | 68% ! | 35% ! | 47% | 45% | - | 43% | **50.7%** |
| **pharilux** | 18% ! | 57% | 35% ! | 60% | 68% ! | 65% ! | 57% | - | **51.4%** |

## Overall by AI profile

| critter | novice | standard | expert |
|---|---|---|---|
| aruun | 44.3% | 50.7% | 60.0% |
| cigarra | 41.4% | 52.9% | 50.7% |
| bramvex | 80.7% | 41.4% | 32.9% |
| scarlith | 65.0% | 40.7% | 47.1% |
| mollusk | 28.6% | 45.7% | 65.7% |
| zephyr | 32.9% | 49.3% | 63.6% |
| nyxaris | 42.9% | 52.9% | 56.4% |
| pharilux | 64.3% | 66.4% | 23.6% |

## Bout stats (row critter seated first)

| critter | avg seconds | KO % | ring-out % | timeout % | ability uses/bout | Last Stand % |
|---|---|---|---|---|---|---|
| aruun | 49 | 97 | 3 | 0 | 7.9 | 80 |
| cigarra | 39 | 88 | 12 | 0 | 7.5 | 63 |
| bramvex | 47 | 98 | 2 | 0 | 8.5 | 81 |
| scarlith | 36 | 96 | 4 | 0 | 8.5 | 59 |
| mollusk | 49 | 94 | 6 | 0 | 5.9 | 72 |
| zephyr | 45 | 96 | 4 | 0 | 11.2 | 74 |
| nyxaris | 42 | 95 | 5 | 0 | 4.4 | 70 |
| pharilux | 71 | 81 | 18 | 1 | 13.9 | 66 |

Seat bias: first seat wins 47.7% of bouts.

Matchups beyond 40/60: aruun vs scarlith = 30%, aruun vs mollusk = 33%, aruun vs nyxaris = 38%, cigarra vs mollusk = 25%, bramvex vs aruun = 30%, bramvex vs nyxaris = 32%, scarlith vs bramvex = 23%, mollusk vs scarlith = 23%, mollusk vs zephyr = 25%, mollusk vs pharilux = 32%, zephyr vs aruun = 37%, zephyr vs bramvex = 37%, zephyr vs pharilux = 35%, nyxaris vs scarlith = 35%, pharilux vs aruun = 18%, pharilux vs bramvex = 35%

## Role-pair matrix (row role vs column role, win rate of the row)

| role (critter) | breaker | warden | drifter | brewer | anchor | binder | reader |
|---|---|---|---|---|---|---|---|
| **breaker** (aruun) | - | 81.7% > | 63.3% | 30.0% | 33.3% | 38.3% | 45.0% |
| **warden** (pharilux) | 18.3% | - | 65.0% > | 60.0% | 68.3% | 56.7% | 56.7% |
| **drifter** (zephyr) | 36.7% | 35.0% | - | 58.3% > | 75.0% | 55.0% | 43.3% |
| **brewer** (scarlith) | 70.0% | 40.0% | 41.7% | - | 76.7% > | 65.0% | 40.0% |
| **anchor** (mollusk) | 66.7% | 31.7% | 25.0% | 23.3% | - | 53.3% > | 75.0% |
| **binder** (nyxaris) | 61.7% | 43.3% | 45.0% | 35.0% | 46.7% | - | 55.0% > |
| **reader** (cigarra) | 55.0% > | 43.3% | 56.7% | 60.0% | 25.0% | 45.0% | - |

`>` = the row role has the soft-counter advantage. Cycle: breaker > warden > drifter > brewer > anchor > binder > reader > breaker.

| disadvantaged role vs its counter | all AI levels | expert AI only |
|---|---|---|
| warden vs breaker | 18.3% | 0.0% |
| drifter vs warden | 35.0% | 75.0% |
| brewer vs drifter | 41.7% | 20.0% |
| anchor vs brewer | 23.3% | 30.0% |
| binder vs anchor | 46.7% | 25.0% |
| reader vs binder | 45.0% | 45.0% |
| breaker vs reader | 45.0% | 50.0% |

Out of role-pair targets: breaker>warden 81.7% (want 51-54), breaker~drifter 63.3% (want 46-54), breaker~brewer 30.0% (want 46-54), breaker~anchor 33.3% (want 46-54), breaker~binder 38.3% (want 46-54), warden>drifter 65.0% (want 51-54), warden~brewer 60.0% (want 46-54), warden~anchor 68.3% (want 46-54), warden~binder 56.7% (want 46-54), warden~reader 56.7% (want 46-54), drifter>brewer 58.3% (want 51-54), drifter~anchor 75.0% (want 46-54), drifter~binder 55.0% (want 46-54), drifter~reader 43.3% (want 46-54), brewer>anchor 76.7% (want 51-54), brewer~binder 65.0% (want 46-54), brewer~reader 40.0% (want 46-54), anchor~reader 75.0% (want 46-54), binder>reader 55.0% (want 51-54), reader>breaker 55.0% (want 51-54)
Disadvantaged below 46% at expert: warden vs breaker expert 0.0%, brewer vs drifter expert 20.0%, anchor vs brewer expert 30.0%, binder vs anchor expert 25.0%, reader vs binder expert 45.0%

