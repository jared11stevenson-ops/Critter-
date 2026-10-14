# CRITTER v2 balance matrix

Bouts: 1920 (about 30 per ordered matchup, split over profiles novice/standard/expert, both seats), seed base 51, default stakes (Blood, lethal), arena ring.
Cell = win rate of ROW critter against COLUMN critter. Targets: overall 45-55%, no matchup beyond 40/60.

| row \ col | aruun | cigarra | bramvex | scarlith | mollusk | zephyr | nyxaris | pharilux | **overall** |
|---|---|---|---|---|---|---|---|---|---|
| **aruun** | - | 63% ! | 58% | 35% ! | 48% | 45% | 48% | 65% ! | **51.9%** |
| **cigarra** | 37% ! | - | 58% | 60% | 22% ! | 63% ! | 72% ! | 57% | **52.6%** |
| **bramvex** | 42% | 42% | - | 77% ! | 62% ! | 53% | 42% | 62% ! | **54.0%** |
| **scarlith** | 65% ! | 40% | 23% ! | - | 47% | 45% | 55% | 45% | **45.7%** |
| **mollusk** | 52% | 78% ! | 38% ! | 53% | - | 33% ! | 63% ! | 30% ! | **49.8%** |
| **zephyr** | 55% | 37% ! | 47% | 55% | 67% ! | - | 50% | 57% | **52.4%** |
| **nyxaris** | 52% | 28% ! | 58% | 45% | 37% ! | 50% | - | 37% ! | **43.8%** ! |
| **pharilux** | 35% ! | 43% | 38% ! | 55% | 70% ! | 43% | 63% ! | - | **49.8%** |

## Overall by AI profile

| critter | novice | standard | expert |
|---|---|---|---|
| aruun | 44.3% | 55.0% | 56.4% |
| cigarra | 45.0% | 53.6% | 59.3% |
| bramvex | 80.7% | 43.6% | 37.9% |
| scarlith | 55.7% | 38.6% | 42.9% |
| mollusk | 44.3% | 43.6% | 61.4% |
| zephyr | 50.0% | 56.4% | 50.7% |
| nyxaris | 30.0% | 47.9% | 53.6% |
| pharilux | 50.0% | 61.4% | 37.9% |

## Bout stats (row critter seated first)

| critter | avg seconds | KO % | ring-out % | timeout % | ability uses/bout | Last Stand % |
|---|---|---|---|---|---|---|
| aruun | 58 | 67 | 33 | 0 | 10.0 | 65 |
| cigarra | 42 | 73 | 27 | 0 | 8.0 | 42 |
| bramvex | 62 | 86 | 13 | 1 | 12.2 | 63 |
| scarlith | 48 | 82 | 16 | 2 | 11.6 | 52 |
| mollusk | 51 | 80 | 18 | 3 | 5.7 | 55 |
| zephyr | 55 | 79 | 20 | 1 | 13.6 | 62 |
| nyxaris | 54 | 83 | 14 | 3 | 5.7 | 65 |
| pharilux | 79 | 35 | 49 | 16 | 15.3 | 44 |

Seat bias: first seat wins 50.4% of bouts.

Matchups beyond 40/60: aruun vs scarlith = 35%, cigarra vs aruun = 37%, cigarra vs mollusk = 22%, scarlith vs bramvex = 23%, mollusk vs bramvex = 38%, mollusk vs zephyr = 33%, mollusk vs pharilux = 30%, zephyr vs cigarra = 37%, nyxaris vs cigarra = 28%, nyxaris vs mollusk = 37%, nyxaris vs pharilux = 37%, pharilux vs aruun = 35%, pharilux vs bramvex = 38%

## Role-pair matrix (row role vs column role, win rate of the row)

| role (critter) | breaker | warden | drifter | brewer | anchor | binder | reader |
|---|---|---|---|---|---|---|---|
| **breaker** (aruun) | - | 65.0% > | 45.0% | 35.0% | 48.3% | 48.3% | 63.3% |
| **warden** (pharilux) | 35.0% | - | 43.3% > | 55.0% | 70.0% | 63.3% | 43.3% |
| **drifter** (zephyr) | 55.0% | 56.7% | - | 55.0% > | 66.7% | 50.0% | 36.7% |
| **brewer** (scarlith) | 65.0% | 45.0% | 45.0% | - | 46.7% > | 55.0% | 40.0% |
| **anchor** (mollusk) | 51.7% | 30.0% | 33.3% | 53.3% | - | 63.3% > | 78.3% |
| **binder** (nyxaris) | 51.7% | 36.7% | 50.0% | 45.0% | 36.7% | - | 28.3% > |
| **reader** (cigarra) | 36.7% > | 56.7% | 63.3% | 60.0% | 21.7% | 71.7% | - |

`>` = the row role has the soft-counter advantage. Cycle: breaker > warden > drifter > brewer > anchor > binder > reader > breaker.

| disadvantaged role vs its counter | all AI levels | expert AI only |
|---|---|---|
| warden vs breaker | 35.0% | 30.0% |
| drifter vs warden | 56.7% | 75.0% |
| brewer vs drifter | 45.0% | 55.0% |
| anchor vs brewer | 53.3% | 75.0% |
| binder vs anchor | 36.7% | 40.0% |
| reader vs binder | 71.7% | 85.0% |
| breaker vs reader | 63.3% | 65.0% |

Out of role-pair targets: breaker>warden 65.0% (want 51-54), breaker~drifter 45.0% (want 46-54), breaker~brewer 35.0% (want 46-54), warden>drifter 43.3% (want 51-54), warden~brewer 55.0% (want 46-54), warden~anchor 70.0% (want 46-54), warden~binder 63.3% (want 46-54), warden~reader 43.3% (want 46-54), drifter>brewer 55.0% (want 51-54), drifter~anchor 66.7% (want 46-54), drifter~reader 36.7% (want 46-54), brewer>anchor 46.7% (want 51-54), brewer~binder 55.0% (want 46-54), brewer~reader 40.0% (want 46-54), anchor>binder 63.3% (want 51-54), anchor~reader 78.3% (want 46-54), binder>reader 28.3% (want 51-54), reader>breaker 36.7% (want 51-54)
Disadvantaged below 46% at expert: warden vs breaker expert 30.0%, binder vs anchor expert 40.0%

