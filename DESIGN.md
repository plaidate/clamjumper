# Clam Jumper — Species Rework Design

## Why

The current game stars two crabs, but the reef's real clam specialists make a
far richer cast: **sea stars** pry bivalves open with tube feet (the perfect
crank fantasy), **octopuses** pry and drill them, and **rays** crush them with
plate teeth after fanning them out of the sand. Replacing the two identical
crabs with a pickable roster of three creatures — each with a distinct
movement ability and pry style — turns a single-verb race into a
character-select game. (Fun fact kept out of the marketing copy: crabs *are*
notorious clam predators too, but three asymmetric specialists beat two
identical crabs.)

The name still works: a "clam jumper" is whoever jumps your clam.

## The roster

All three keep the shared chassis: tile-to-tile movement, crank-to-pry,
A-button special. What differs is speed, pry profile, and what A does.

### Sea Star — the grip

| Stat | Value | Feel |
|---|---|---|
| Speed | 70 px/s (slowest) | deliberate |
| Pry goal | 420° (easiest) | tube feet never slip |
| Pry decay | 90°/s (slowest) | progress sticks |

- **A — Clamp** (replaces the hop): suction-anchor to the seabed for 1.2 s,
  4 s cooldown. While clamped: immune to rival bumps (pry progress keeps),
  and eels slide past harmlessly (armored hide). Cannot move while clamped.
- **No hop at all.** The sea star can never jump coral or leap an eel — it
  must route around, or clamp and let the eel pass. This is its whole risk
  profile.
- Rival-bump interaction when not clamped: a bump only **halves** its pry
  progress instead of zeroing it (tube feet).

### Octopus — the jet

| Stat | Value | Feel |
|---|---|---|
| Speed | 92 px/s (fast) | restless |
| Pry goal | 540° (current) | strong arms |
| Pry decay | 320°/s (fastest) | impatient — commit or lose it |

- **A — Jet dash**: 3 tiles in the facing direction over coral/eels
  (falls back 3→2→1 like the current hop's 2→1), i-frames mid-dash,
  0.7 s cooldown. On launch it leaves an **ink puff** on the departed tile
  for ~2 s; a rival entering it is stunned 1.5 s (eels ignore ink — they
  hunt by smell). Offense is baked into escape.

### Ray — the glide

| Stat | Value | Feel |
|---|---|---|
| Speed | 86 px/s | smooth |
| Pry goal | 480° | crushing plates |
| Pry decay | 200°/s | middle |

- **A (hold) — Glide**: lifts off and flies over tiles, coral and eels
  while A is held, up to 4 tiles, landing on the next open tile when
  released (or at max range). I-frames while airborne. Cooldown scales
  with distance flown (0.3 s per tile).
- **Wing-slam**: landing a glide directly on a clam blasts the sand off it —
  instant +120° pry credit. Rewards gliding onto clams instead of walking.

Balance target: time-to-pearl for an unharassed player within ~10% across
species (verified by harness, below); the differences should be about risk
and routing, not raw speed.

## The rival

The rival is no longer a crab clone: each reef it spawns as a **random
species different from yours**, and its AI uses that species' signature
(as built):

- **Rival octopus** — jet-dashes at your contested clam when it has a
  straight shot, dropping ink on launch that stuns *you* if you wade in.
- **Rival sea star** — slow (speed-factor bumped so it isn't a pushover)
  but pries clams in 0.65× the time, and never chases you — it farms.
- **Rival ray** — covers corridors in 2-tile gliding hops while pathing.

A clamped player sea star is excluded from the contest check entirely, so
the rival never dead-ends chasing an unbumpable target — it just paths to
the next clam. (Implementation note: the original's bump was unreachable —
the pry-branch intercepted arrival first; the rework checks the bump before
the pry branch, so contests actually land.)

Rival speed scales per reef via a species-speed factor (0.73 → 0.93 cap).

## Flow changes

New state between `title` and `intro`: **`pick`** — species select.
Left/right cycles the three creatures (big vector portrait, name, one-line
ability blurb, stat pips for speed/pry/mobility), A confirms. Selection is
remembered in the save file as the default cursor position next game.

Everything else (reef loop, clear card, Pearl Rain bonus every 2nd reef,
extra life every 10 000) is unchanged. The bonus-round catcher and the HUD
life icons render as the chosen species. "EXTRA CRAB" becomes "EXTRA LIFE".

## Code plan

The refactor is small because `crab.lua` is already the shared chassis.

1. **`crab.lua` → `critter.lua`** (`Crab` → `Critter`): keep spawn/step/
   update/idle exactly as-is; generalize `jump` into `Critter.ability(cr)`
   which dispatches on `cr.species`. Hop/dash/glide share the existing
   airborne lerp (`jumpT/sx/ex/hop`) with per-species range and arc height;
   clamp is a new timed state `cr.clampT` checked in `Player.bumped` and
   `Eel.hitsPlayer`.
2. **New `species.lua`**: one table per species — stats (speed, pryGoal,
   pryDecay, bumpKeep), ability parameters, AI hints for the rival, and a
   `draw(cr, filled)` function. Global `Species` namespace per repo
   convention.
3. **`config.lua`**: move PLAYER_SPEED / PRY_GOAL / PRY_DECAY into the
   species table; add ink/clamp/glide tunables.
4. **`clams.lua`**: `playerPry` reads goal/decay from the player's species;
   add the wing-slam credit entry point.
5. **`rival.lua`**: species-aware — use ability in `update` (dash when
   contesting, glide when pathing over an eel tile, clamp when prying);
   bump-fail → retarget branch.
6. **`player.lua`**: `bumped()` respects clamp and `bumpKeep` (sea star
   halves instead of zeroing).
7. **`eel.lua`**: `hitsPlayer` returns false while clamped or airborne
   (airborne already works via `jumping`).
8. **`draw.lua`**: three vector creatures replacing `drawCrab` —
   - *sea star*: 5-armed star polygon with a slow arm-wiggle phase;
   - *octopus*: dome mantle, two big eyes, 5 sine-wave tentacle lines;
   - *ray*: diamond wings flapping (x-scale on a sine), whip tail, eye
     bumps.
   Rival uses the existing 25% dither pattern fill regardless of species.
   Species-shaped HUD life icons; pick-screen portraits are the same
   functions drawn at 2–3×.
9. **`input.lua`**: rename `inp.jump` → `inp.ability`, add `inp.abilityHeld`
   for the ray's hold-to-glide. Human controls unchanged otherwise.
10. **Copy**: title screen, intro, README, `main.lua` header comment.

## Autopilot / harness plan

The smoke autopilot must play all three species (memory: staged-failure and
chart-reading autopilots elsewhere in the repo — same discipline here):

- On the `pick` screen the autopilot selects `(games % 3)`-th species so
  three consecutive smoke games cover the roster; `Harness.extra` reports
  `t.species`.
- Ability logic per species:
  - *octopus/ray*: current hop logic maps straight over (dash/glide over an
    adjacent eel); ray holds `abilityHeld` for 2 tiles then releases.
  - *sea star*: never jumps — when an eel is adjacent or inbound while
    prying, **clamp**; when idle in a corridor with an eel one tile away
    and clamp on cooldown, flee via the existing BFS side-step.
- New harness counters: `abilityUses`, `clampSaves`, `inkStuns`,
  `wingSlams`, plus `pearls` split per species for the balance check.
- Balance harness run: `tools/smoke.sh 120` three times (one forced species
  each via a `SMOKE_SPECIES` build flag), compare pearls/reef within ~10%.

## Out of scope (deliberately)

- Species-specific bonus rounds or abilities inside Pearl Rain (catcher is
  cosmetic-only for now; ray-glide-in-bonus is a stretch note).
- A fourth species (crab as a joke unlock) — funny, later.
- Eel behavior changes; it stays the neutral hazard that ignores ink.

## Build order

1. Chassis refactor + species table, all three stat-only (no abilities yet);
   pick screen; art. Smoke green.
2. Octopus dash + ink, ray glide + wing-slam, sea star clamp + bumpKeep.
3. Rival species AI + bump-fail retarget.
4. Autopilot species coverage + new counters; 3× balance runs; tune.
5. Copy/README/screenshot refresh.
