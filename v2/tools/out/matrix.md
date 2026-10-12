# CRITTER v2 balance matrix

Bouts: 1470 (about 28 per ordered matchup, split over profiles novice/standard/expert, both seats), seed base 7, default stakes (Blood, lethal), arena ring.
Cell = win rate of ROW critter against COLUMN critter. Targets: overall 45-55%, no matchup beyond 40/60.

| row \ col | aruun | cigarra | bramvex | scarlith | mollusk | zephyr | nyxaris | **overall** |
|---|---|---|---|---|---|---|---|---|
| **aruun** | - | 53% | 68% ! | 38% ! | 53% | 70% ! | 48% | **55.3%** ! |
| **cigarra** | 47% | - | 60% | 43% | 28% ! | 55% | 60% | **48.9%** |
| **bramvex** | 32% ! | 40% | - | 70% ! | 53% | 52% | 40% | **47.8%** |
| **scarlith** | 62% ! | 57% | 30% ! | - | 52% | 53% | 72% ! | **54.2%** |
| **mollusk** | 47% | 72% ! | 47% | 48% | - | 22% ! | 55% | **48.3%** |
| **zephyr** | 30% ! | 45% | 48% | 47% | 78% ! | - | 68% ! | **52.8%** |
| **nyxaris** | 52% | 40% | 60% | 28% ! | 45% | 32% ! | - | **42.8%** ! |

## Overall by AI profile

| critter | novice | standard | expert |
|---|---|---|---|
| aruun | 50.8% | 55.8% | 59.2% |
| cigarra | 42.5% | 52.5% | 51.7% |
| bramvex | 75.0% | 41.7% | 26.7% |
| scarlith | 64.2% | 46.7% | 51.7% |
| mollusk | 40.8% | 50.0% | 54.2% |
| zephyr | 44.2% | 57.5% | 56.7% |
| nyxaris | 32.5% | 45.8% | 50.0% |

## Bout stats (row critter seated first)

| critter | avg seconds | KO % | ring-out % | timeout % | ability uses/bout | Last Stand % |
|---|---|---|---|---|---|---|
| aruun | 44 | 99 | 1 | 0 | 7.2 | 79 |
| cigarra | 34 | 88 | 12 | 0 | 6.6 | 60 |
| bramvex | 47 | 97 | 3 | 0 | 8.4 | 80 |
| scarlith | 32 | 98 | 2 | 0 | 7.6 | 57 |
| mollusk | 45 | 98 | 2 | 0 | 5.7 | 78 |
| zephyr | 42 | 95 | 5 | 0 | 10.5 | 74 |
| nyxaris | 40 | 96 | 4 | 0 | 4.2 | 69 |

Seat bias: first seat wins 50.7% of bouts.

Matchups beyond 40/60: aruun vs scarlith = 38%, cigarra vs mollusk = 28%, bramvex vs aruun = 32%, scarlith vs bramvex = 30%, mollusk vs zephyr = 22%, zephyr vs aruun = 30%, nyxaris vs scarlith = 28%, nyxaris vs zephyr = 32%

## Role-pair matrix (row role vs column role, win rate of the row)

| role (critter) | breaker | warden | drifter | brewer | anchor | binder | reader |
|---|---|---|---|---|---|---|---|
| **breaker** (aruun) | - | 68.3% > | 70.0% | 38.3% | 53.3% | 48.3% | 53.3% |
| **warden** (bramvex) | 31.7% | - | 51.7% > | 70.0% | 53.3% | 40.0% | 40.0% |
| **drifter** (zephyr) | 30.0% | 48.3% | - | 46.7% > | 78.3% | 68.3% | 45.0% |
| **brewer** (scarlith) | 61.7% | 30.0% | 53.3% | - | 51.7% > | 71.7% | 56.7% |
| **anchor** (mollusk) | 46.7% | 46.7% | 21.7% | 48.3% | - | 55.0% > | 71.7% |
| **binder** (nyxaris) | 51.7% | 60.0% | 31.7% | 28.3% | 45.0% | - | 40.0% > |
| **reader** (cigarra) | 46.7% > | 60.0% | 55.0% | 43.3% | 28.3% | 60.0% | - |

`>` = the row role has the soft-counter advantage. Cycle: breaker > warden > drifter > brewer > anchor > binder > reader > breaker.

| disadvantaged role vs its counter | all AI levels | expert AI only |
|---|---|---|
| warden vs breaker | 31.7% | 15.0% |
| drifter vs warden | 48.3% | 50.0% |
| brewer vs drifter | 53.3% | 45.0% |
| anchor vs brewer | 48.3% | 55.0% |
| binder vs anchor | 45.0% | 35.0% |
| reader vs binder | 60.0% | 55.0% |
| breaker vs reader | 53.3% | 50.0% |

Out of role-pair targets: breaker>warden 68.3% (want 51-54), breaker~drifter 70.0% (want 46-54), breaker~brewer 38.3% (want 46-54), warden~brewer 70.0% (want 46-54), warden~binder 40.0% (want 46-54), warden~reader 40.0% (want 46-54), drifter>brewer 46.7% (want 51-54), drifter~anchor 78.3% (want 46-54), drifter~binder 68.3% (want 46-54), drifter~reader 45.0% (want 46-54), brewer~binder 71.7% (want 46-54), brewer~reader 56.7% (want 46-54), anchor>binder 55.0% (want 51-54), anchor~reader 71.7% (want 46-54), binder>reader 40.0% (want 51-54), reader>breaker 46.7% (want 51-54)
Disadvantaged below 46% at expert: warden vs breaker expert 15.0%, brewer vs drifter expert 45.0%, binder vs anchor expert 35.0%

