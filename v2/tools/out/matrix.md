# CRITTER v2 balance matrix

Bouts: 2058 (about 42 per ordered matchup, split over profiles novice/standard/expert, both seats), seed base 21, default stakes (Blood, lethal), arena ring.
Cell = win rate of ROW critter against COLUMN critter. Targets: overall 45-55%, no matchup beyond 40/60.

| row \ col | aruun | cigarra | bramvex | scarlith | mollusk | zephyr | nyxaris | **overall** |
|---|---|---|---|---|---|---|---|---|
| **aruun** | - | 61% ! | 75% ! | 24% ! | 44% | 64% ! | 39% ! | **51.2%** |
| **cigarra** | 39% ! | - | 74% ! | 51% | 24% ! | 60% | 52% | **50.0%** |
| **bramvex** | 25% ! | 26% ! | - | 71% ! | 49% | 51% | 29% ! | **41.9%** ! |
| **scarlith** | 76% ! | 49% | 29% ! | - | 62% ! | 56% | 49% | **53.4%** |
| **mollusk** | 56% | 76% ! | 51% | 38% ! | - | 21% ! | 46% | **48.2%** |
| **zephyr** | 36% ! | 40% | 49% | 44% | 79% ! | - | 52% | **50.0%** |
| **nyxaris** | 61% ! | 48% | 71% ! | 51% | 54% | 48% | - | **55.4%** ! |

## Overall by AI profile

| critter | novice | standard | expert |
|---|---|---|---|
| aruun | 47.6% | 52.4% | 53.6% |
| cigarra | 43.5% | 48.2% | 58.3% |
| bramvex | 64.3% | 33.3% | 28.0% |
| scarlith | 65.5% | 49.4% | 45.2% |
| mollusk | 39.3% | 48.8% | 56.5% |
| zephyr | 46.4% | 54.8% | 48.8% |
| nyxaris | 43.5% | 63.1% | 59.5% |

## Bout stats (row critter seated first)

| critter | avg seconds | KO % | ring-out % | timeout % | ability uses/bout | Last Stand % |
|---|---|---|---|---|---|---|
| aruun | 44 | 96 | 4 | 0 | 7.0 | 80 |
| cigarra | 35 | 93 | 7 | 0 | 6.9 | 62 |
| bramvex | 46 | 96 | 4 | 0 | 8.1 | 79 |
| scarlith | 33 | 98 | 2 | 0 | 7.7 | 57 |
| mollusk | 45 | 98 | 2 | 0 | 5.8 | 78 |
| zephyr | 43 | 94 | 6 | 0 | 10.7 | 73 |
| nyxaris | 39 | 95 | 5 | 0 | 4.2 | 67 |

Seat bias: first seat wins 48.6% of bouts.

Matchups beyond 40/60: aruun vs scarlith = 24%, aruun vs nyxaris = 39%, cigarra vs aruun = 39%, cigarra vs mollusk = 24%, bramvex vs aruun = 25%, bramvex vs cigarra = 26%, bramvex vs nyxaris = 29%, scarlith vs bramvex = 29%, mollusk vs scarlith = 38%, mollusk vs zephyr = 21%, zephyr vs aruun = 36%

## Role-pair matrix (row role vs column role, win rate of the row)

| role (critter) | breaker | warden | drifter | brewer | anchor | binder | reader |
|---|---|---|---|---|---|---|---|
| **breaker** (aruun) | - | 75.0% > | 64.3% | 23.8% | 44.0% | 39.3% | 60.7% |
| **warden** (bramvex) | 25.0% | - | 51.2% > | 71.4% | 48.8% | 28.6% | 26.2% |
| **drifter** (zephyr) | 35.7% | 48.8% | - | 44.0% > | 78.6% | 52.4% | 40.5% |
| **brewer** (scarlith) | 76.2% | 28.6% | 56.0% | - | 61.9% > | 48.8% | 48.8% |
| **anchor** (mollusk) | 56.0% | 51.2% | 21.4% | 38.1% | - | 46.4% > | 76.2% |
| **binder** (nyxaris) | 60.7% | 71.4% | 47.6% | 51.2% | 53.6% | - | 47.6% > |
| **reader** (cigarra) | 39.3% > | 73.8% | 59.5% | 51.2% | 23.8% | 52.4% | - |

`>` = the row role has the soft-counter advantage. Cycle: breaker > warden > drifter > brewer > anchor > binder > reader > breaker.

| disadvantaged role vs its counter | all AI levels | expert AI only |
|---|---|---|
| warden vs breaker | 25.0% | 28.6% |
| drifter vs warden | 48.8% | 46.4% |
| brewer vs drifter | 56.0% | 53.6% |
| anchor vs brewer | 38.1% | 53.6% |
| binder vs anchor | 53.6% | 53.6% |
| reader vs binder | 52.4% | 60.7% |
| breaker vs reader | 60.7% | 60.7% |

Out of role-pair targets: breaker>warden 75.0% (want 51-54), breaker~drifter 64.3% (want 46-54), breaker~brewer 23.8% (want 46-54), breaker~anchor 44.0% (want 46-54), breaker~binder 39.3% (want 46-54), warden~brewer 71.4% (want 46-54), warden~binder 28.6% (want 46-54), warden~reader 26.2% (want 46-54), drifter>brewer 44.0% (want 51-54), drifter~anchor 78.6% (want 46-54), drifter~reader 40.5% (want 46-54), brewer>anchor 61.9% (want 51-54), anchor>binder 46.4% (want 51-54), anchor~reader 76.2% (want 46-54), binder>reader 47.6% (want 51-54), reader>breaker 39.3% (want 51-54)
Disadvantaged below 46% at expert: warden vs breaker expert 28.6%

