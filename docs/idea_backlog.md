# Oddside — Idea Backlog

Bigger features / levels that are designed-but-not-built. Mirrors the in-session task
list; this file is the durable, detailed record.

---

## Amulet system — Rubik's-cube passive inventory

A secondary inventory of **amulets** (passive modifiers). Each die face is subdivided
into a grid of sub-slots (target **3×3 = 9 per face**, 54 total; **start 2×2 = 4 per face**,
24 total). An amulet applies its passive **whenever its face is the active (top) face** —
so rolling changes both the active ability *and* the active passives.

Example amulets: damage boost, reduced item cost, reduced commit time, +speed after
using an item.

### Architecture (decided in design pass — 3 decoupled layers)
1. **Effects** — what an amulet does. Build a **`PlayerStats` aggregator**: named stats
   (`damage_mult`, `cost_reduction`, `commit_mult`, `post_use_speed`, …) that many
   sources contribute to and many systems read. (Generalizes the existing ad-hoc buffs:
   `next_attack_damage_mult`, lantern speed — these are proto-amulets.)
   - **Passive stats** (constant while the face is up): damage / cost / commit.
   - **Triggered** (on an event while the face is up): "+speed after using an item" hooks
     the existing `item_used` signal.
   - `Amulet` resource = `{ stat contributions[] } + optional { trigger behavior }`
     (same shape as `EnemyModifier`).
   - Integration points are tiny + already-touched: `Hitbox` (damage, like Growl),
     `card_system.play_ability_for_slot` (cost − reduction, commit × mult), `item_used`.
2. **Activation** — on each roll the top face changes (`GameEvents.dice_moved` /
   `player.up_side`). One handler: clear the old face's contributions, apply the new
   face's. Twisting-agnostic.
3. **Arrangement** — how amulets are placed/moved across slots. **The only place the
   "Rubik's" question lives.** Two paths:
   - **(A) Static grid per face** — place freely; storage `amulets[face][r][c]`. Simple.
   - **(B) Real Rubik's twisting** — twisting a layer permutes amulets across 4 faces;
     loadout-building becomes a spatial puzzle. Novel but a big cube-state + permutation
     engine + custom 3D UI.

### MVP / build order
- **Spine first (twisting-agnostic):** `PlayerStats` + per-face amulet grid (2×2, static A)
  + activation on face change. Hook `card_system` cost/commit + `Hitbox` damage. No UI —
  hardcode an amulet on a face, watch cost drop when you roll to it.
- Then UI (Rubik's-cube view), more amulet types, and (optionally) the twist mechanic.

### Open decisions
1. Rubik's: static grid (A) or real twisting (B)?  ← biggest
2. Effect model: start pure stat-contributions, add triggered behaviors for "speed after use"?
3. Does sub-position within a face matter (adjacency / 3-in-a-row synergies), or is a face
   just a bag of N amulets?

### First thing to write
`PlayerStats` aggregator + `Amulet` resource — everything else hangs off it.

---

## Concert level — "Narcoleptika"

Player enters a concert hall; the band **Narcoleptika** has a problem: members
**randomly fall asleep mid-performance**. The player's mission is to **cover for whoever
falls asleep** while **dodging obstacles thrown by their rabid fans**.

- **New Deck: Music Deck** — each die side is a different band instrument the player must
  cover. (Uses the existing **Deck system** — temporary themed loadouts that replace the
  die's faces: `Deck` / `DeckZone` / `card_system.equip_deck`.)

### What's reusable vs new
- **Reuse:** Deck system (Music Deck = a Deck of 6 instruments), enemy/fan **projectiles**
  to dodge, camera zones, dialogue/NPCs.
- **New:**
  - Band-member NPCs that **sleep on a random timer** and signal "cover me."
  - The **cover loop**: when member X sleeps, the player must roll to X's instrument face
    and "play" it (activate) to cover — likely a timing/rhythm beat.
  - **Fan obstacle** spawner (projectiles to dodge while covering).
  - The concert-hall level + stage layout.

### Open questions
- Is covering a **rhythm/timing** minigame, or just "be on the right face while they sleep"?
- Fail state if you don't cover in time (boos? damage? song restarts)?
- One instrument asleep at a time, or escalating (multiple at once)?
