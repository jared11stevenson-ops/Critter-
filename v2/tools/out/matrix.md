# CRITTER v2 balance matrix

Bouts: 1920 (about 200 per ordered matchup, split over profiles novice/standard/expert, both seats), seed base 1, default stakes (Blood, lethal), arena ring.
Cell = win rate of ROW critter against COLUMN critter. Targets: overall 45-55%, no matchup beyond 40/60.

| row \ col | aruun | cigarra | bramvex | scarlith | mollusk | zephyr | nyxaris | pharilux | **overall** |
|---|---|---|---|---|---|---|---|---|---|
| **aruun** | - | 43% | 65% ! | 42% | 30% ! | 73% ! | 52% | 60% | **52.1%** |
| **cigarra** | 57% | - | 72% ! | 55% | 28% ! | 50% | 53% | 32% ! | **49.5%** |
| **bramvex** | 35% ! | 28% ! | - | 75% ! | 55% | 60% | 28% ! | 57% | **48.3%** |
| **scarlith** | 58% | 45% | 25% ! | - | 55% | 58% | 53% | 32% ! | **46.7%** |
| **mollusk** | 70% ! | 72% ! | 45% | 45% | - | 27% ! | 55% | 53% | **52.4%** |
| **zephyr** | 27% ! | 50% | 40% | 42% | 73% ! | - | 50% | 45% | **46.7%** |
| **nyxaris** | 48% | 47% | 72% ! | 47% | 45% | 50% | - | 42% | **50.0%** |
| **pharilux** | 40% | 68% ! | 43% | 68% ! | 47% | 55% | 58% | - | **54.3%** |

## Overall by AI profile

| critter | novice | standard | expert |
|---|---|---|---|
| aruun | 49.3% | 50.0% | 57.1% |
| cigarra | 40.7% | 47.1% | 60.7% |
| bramvex | 71.4% | 37.9% | 35.7% |
| scarlith | 59.3% | 34.3% | 46.4% |
| mollusk | 37.1% | 56.4% | 63.6% |
| zephyr | 41.4% | 45.7% | 52.9% |
| nyxaris | 35.0% | 56.4% | 58.6% |
| pharilux | 65.7% | 72.1% | 25.0% |

## Bout stats (row critter seated first)

| critter | avg seconds | KO % | ring-out % | timeout % | ability uses/bout | Last Stand % |
|---|---|---|---|---|---|---|
| aruun | 50 | 94 | 6 | 0 | 8.2 | 75 |
| cigarra | 39 | 88 | 12 | 0 | 7.7 | 62 |
| bramvex | 47 | 96 | 4 | 0 | 8.4 | 76 |
| scarlith | 39 | 97 | 3 | 0 | 9.3 | 62 |
| mollusk | 47 | 94 | 6 | 0 | 5.7 | 68 |
| zephyr | 46 | 96 | 4 | 0 | 11.4 | 80 |
| nyxaris | 42 | 95 | 5 | 0 | 4.4 | 66 |
| pharilux | 74 | 84 | 15 | 1 | 14.3 | 68 |

Seat bias: first seat wins 49.0% of bouts.

Matchups beyond 40/60: aruun vs mollusk = 30%, cigarra vs mollusk = 28%, cigarra vs pharilux = 32%, bramvex vs aruun = 35%, bramvex vs cigarra = 28%, bramvex vs nyxaris = 28%, scarlith vs bramvex = 25%, scarlith vs pharilux = 32%, mollusk vs zephyr = 27%, zephyr vs aruun = 27%

## Role-pair matrix (row role vs column role, win rate of the row)

| role (critter) | breaker | warden | drifter | brewer | anchor | binder | reader |
|---|---|---|---|---|---|---|---|
| **breaker** (aruun) | - | 60.0% > | 73.3% | 41.7% | 30.0% | 51.7% | 43.3% |
| **warden** (pharilux) | 40.0% | - | 55.0% > | 68.3% | 46.7% | 58.3% | 68.3% |
| **drifter** (zephyr) | 26.7% | 45.0% | - | 41.7% > | 73.3% | 50.0% | 50.0% |
| **brewer** (scarlith) | 58.3% | 31.7% | 58.3% | - | 55.0% > | 53.3% | 45.0% |
| **anchor** (mollusk) | 70.0% | 53.3% | 26.7% | 45.0% | - | 55.0% > | 71.7% |
| **binder** (nyxaris) | 48.3% | 41.7% | 50.0% | 46.7% | 45.0% | - | 46.7% > |
| **reader** (cigarra) | 56.7% > | 31.7% | 50.0% | 55.0% | 28.3% | 53.3% | - |

`>` = the row role has the soft-counter advantage. Cycle: breaker > warden > drifter > brewer > anchor > binder > reader > breaker.

| disadvantaged role vs its counter | all AI levels | expert AI only |
|---|---|---|
| warden vs breaker | 40.0% | 25.0% |
| drifter vs warden | 45.0% | 75.0% |
| brewer vs drifter | 58.3% | 40.0% |
| anchor vs brewer | 45.0% | 50.0% |
| binder vs anchor | 45.0% | 50.0% |
| reader vs binder | 53.3% | 60.0% |
| breaker vs reader | 43.3% | 30.0% |

Out of role-pair targets: breaker>warden 60.0% (want 51-54), breaker~drifter 73.3% (want 46-54), breaker~brewer 41.7% (want 46-54), breaker~anchor 30.0% (want 46-54), warden>drifter 55.0% (want 51-54), warden~brewer 68.3% (want 46-54), warden~binder 58.3% (want 46-54), warden~reader 68.3% (want 46-54), drifter>brewer 41.7% (want 51-54), drifter~anchor 73.3% (want 46-54), brewer>anchor 55.0% (want 51-54), brewer~reader 45.0% (want 46-54), anchor>binder 55.0% (want 51-54), anchor~reader 71.7% (want 46-54), binder>reader 46.7% (want 51-54), reader>breaker 56.7% (want 51-54)
Disadvantaged below 46% at expert: warden vs breaker expert 25.0%, brewer vs drifter expert 40.0%, breaker vs reader expert 30.0%

