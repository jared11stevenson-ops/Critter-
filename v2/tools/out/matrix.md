# CRITTER v2 balance matrix

Bouts: 1920 (about 200 per ordered matchup, split over profiles novice/standard/expert, both seats), seed base 1, default stakes (Blood, lethal), arena ring.
Cell = win rate of ROW critter against COLUMN critter. Targets: overall 45-55%, no matchup beyond 40/60.

| row \ col | aruun | cigarra | bramvex | scarlith | mollusk | zephyr | nyxaris | pharilux | **overall** |
|---|---|---|---|---|---|---|---|---|---|
| **aruun** | - | 42% | 83% ! | 30% ! | 43% | 73% ! | 45% | 67% ! | **54.8%** |
| **cigarra** | 58% | - | 75% ! | 48% | 23% ! | 60% | 58% | 25% ! | **49.8%** |
| **bramvex** | 17% ! | 25% ! | - | 77% ! | 53% | 62% ! | 37% ! | 42% | **44.5%** ! |
| **scarlith** | 70% ! | 52% | 23% ! | - | 63% ! | 34% ! | 55% | 27% ! | **46.3%** |
| **mollusk** | 57% | 77% ! | 47% | 37% ! | - | 27% ! | 57% | 20% ! | **45.7%** |
| **zephyr** | 27% ! | 40% | 38% ! | 66% ! | 73% ! | - | 60% | 13% ! | **45.4%** |
| **nyxaris** | 55% | 42% | 63% ! | 45% | 43% | 40% | - | 32% ! | **45.7%** |
| **pharilux** | 33% ! | 75% ! | 58% | 73% ! | 80% ! | 87% ! | 68% ! | - | **67.9%** ! |

## Overall by AI profile

| critter | novice | standard | expert |
|---|---|---|---|
| aruun | 47.9% | 56.4% | 60.0% |
| cigarra | 42.1% | 52.1% | 55.0% |
| bramvex | 66.4% | 32.1% | 35.0% |
| scarlith | 53.9% | 35.7% | 49.3% |
| mollusk | 37.1% | 45.0% | 55.0% |
| zephyr | 38.2% | 49.3% | 48.6% |
| nyxaris | 35.7% | 44.3% | 57.1% |
| pharilux | 78.6% | 85.0% | 40.0% |

## Bout stats (row critter seated first)

| critter | avg seconds | KO % | ring-out % | timeout % | ability uses/bout | Last Stand % |
|---|---|---|---|---|---|---|
| aruun | 46 | 94 | 6 | 0 | 7.6 | 79 |
| cigarra | 36 | 87 | 13 | 0 | 7.1 | 63 |
| bramvex | 49 | 98 | 2 | 0 | 8.9 | 79 |
| scarlith | 36 | 97 | 3 | 0 | 8.4 | 67 |
| mollusk | 47 | 98 | 2 | 0 | 5.9 | 80 |
| zephyr | 45 | 96 | 4 | 0 | 11.2 | 79 |
| nyxaris | 42 | 96 | 4 | 0 | 4.4 | 68 |
| pharilux | 58 | 85 | 15 | 0 | 11.4 | 51 |

Seat bias: first seat wins 51.7% of bouts.

Matchups beyond 40/60: aruun vs scarlith = 30%, cigarra vs mollusk = 23%, cigarra vs pharilux = 25%, bramvex vs aruun = 17%, bramvex vs cigarra = 25%, bramvex vs nyxaris = 37%, scarlith vs bramvex = 23%, scarlith vs zephyr = 34%, scarlith vs pharilux = 27%, mollusk vs scarlith = 37%, mollusk vs zephyr = 27%, mollusk vs pharilux = 20%, zephyr vs aruun = 27%, zephyr vs bramvex = 38%, zephyr vs pharilux = 13%, nyxaris vs pharilux = 32%, pharilux vs aruun = 33%

## Role-pair matrix (row role vs column role, win rate of the row)

| role (critter) | breaker | warden | drifter | brewer | anchor | binder | reader |
|---|---|---|---|---|---|---|---|
| **breaker** (aruun) | - | 66.7% > | 73.3% | 30.0% | 43.3% | 45.0% | 41.7% |
| **warden** (pharilux) | 33.3% | - | 86.7% > | 73.3% | 80.0% | 68.3% | 75.0% |
| **drifter** (zephyr) | 26.7% | 13.3% | - | 65.8% > | 73.3% | 60.0% | 40.0% |
| **brewer** (scarlith) | 70.0% | 26.7% | 34.2% | - | 63.3% > | 55.0% | 51.7% |
| **anchor** (mollusk) | 56.7% | 20.0% | 26.7% | 36.7% | - | 56.7% > | 76.7% |
| **binder** (nyxaris) | 55.0% | 31.7% | 40.0% | 45.0% | 43.3% | - | 41.7% > |
| **reader** (cigarra) | 58.3% > | 25.0% | 60.0% | 48.3% | 23.3% | 58.3% | - |

`>` = the row role has the soft-counter advantage. Cycle: breaker > warden > drifter > brewer > anchor > binder > reader > breaker.

| disadvantaged role vs its counter | all AI levels | expert AI only |
|---|---|---|
| warden vs breaker | 33.3% | 15.0% |
| drifter vs warden | 13.3% | 40.0% |
| brewer vs drifter | 34.2% | 35.0% |
| anchor vs brewer | 36.7% | 55.0% |
| binder vs anchor | 43.3% | 45.0% |
| reader vs binder | 58.3% | 55.0% |
| breaker vs reader | 41.7% | 30.0% |

Out of role-pair targets: breaker>warden 66.7% (want 51-54), breaker~drifter 73.3% (want 46-54), breaker~brewer 30.0% (want 46-54), breaker~anchor 43.3% (want 46-54), breaker~binder 45.0% (want 46-54), warden>drifter 86.7% (want 51-54), warden~brewer 73.3% (want 46-54), warden~anchor 80.0% (want 46-54), warden~binder 68.3% (want 46-54), warden~reader 75.0% (want 46-54), drifter>brewer 65.8% (want 51-54), drifter~anchor 73.3% (want 46-54), drifter~binder 60.0% (want 46-54), drifter~reader 40.0% (want 46-54), brewer>anchor 63.3% (want 51-54), brewer~binder 55.0% (want 46-54), anchor>binder 56.7% (want 51-54), anchor~reader 76.7% (want 46-54), binder>reader 41.7% (want 51-54), reader>breaker 58.3% (want 51-54)
Disadvantaged below 46% at expert: warden vs breaker expert 15.0%, drifter vs warden expert 40.0%, brewer vs drifter expert 35.0%, binder vs anchor expert 45.0%, breaker vs reader expert 30.0%

