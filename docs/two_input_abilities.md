# Two-Input Abilities — Canonical Spec

Every item has a **primary** (LMB / controller X) and a **secondary** (RMB / controller Y)
action. This table is the **single source of truth** for the two-input designs — it
overrides any older brainstorm board. Update it here when designs change.

**Inputs:** Primary = LMB / X · Secondary = RMB / Y

| Status | Item | Primary (current) | Secondary | Notes |
|---|---|---|---|---|
| ✅ Done | **Axe Throw** | Chops directly in front of you. (Good for breaking obstacles and melee damage) | Throws the axe forward at an upwards angle. (Puzzles where we might need to break something across a gap, or deal with bosses while keeping our distance) | The axe is the first item the player gets. It should be a simple one. The ranged secondary should miss things in front of the player while the axe hit directly damages stuff in front. Throwing Axe should be able to reliably hit things 2 and 3 tiles away. |
| ✅ Done | **Bow & Arrow** | Straight shot forward (long commit, high dmg). Can be held to make arrow even stronger. Releasing at the right time (perfect timing) does critical hit damage. | Arc Volley — lob over obstacles onto a target tile. Holding the button adds more arrows that land on tiles adjacent to the target tile. | For puzzles: torches that arrows pass through to be lit on fire (tall torches needed). A 3D target model attached to a level that controls a wheel — Crash Bandicoot style: hit it and it spins to activate something (door, bridge, whatever). |
| ⏭️ Deferred | **Balloon Pop** | Delete all enemy projectiles (defensive nuke) | Float — ride it up a tile to skip a hazard/gap. Alt: stick to an enemy to lift & disable | Likes the floating idea; unsure how it plays out in-game. Skipped for now. |
| ✅ Done | **Bear Swipe** | Heavy frontal swipe | Growl — your next attack deals 50% more damage. (medium commit) | Incentive for melee players that go all-in with a big attack (buff yourself with right-click, then bear swipe harder). Alternatively, strategic players use it for massive AOE damage to a group. |
| ✅ Done | **Shotgun Blast** | Two pellets forward (focused), knocks player back one tile (check for obstacles) | Reload — while the gun is still active, lets the user reload so they can fire again. | Strong item; must be balanced carefully. Idea: moving after firing "reloads" (kind of implemented). Currently the player can spam left-click and the shotgun keeps appearing — that should stop. Left-click = shoot, right-click = reload micro-game. |
| ✅ Done | **Grenade** | Lob with fuse, big risky AoE | C4 — place at player position, arms after you leave. Alt: press again to remote-detonate | Player should keep the item on top to both place and detonate. Placing a new C4 while one exists makes the first explode or disappear. |
| ✅ Done | **Bear Trap** | Drops behind you when you move | Trap Release — trap unleashes a creature that was previously trapped. | Could be a cool mechanic: catch a flying imp/bird enemy, then resummon them on your side for an attack. Requires many enemies to be capturable. |
| ✅ Done | **Lantern** | Spawn floating light above you. Grants small movement speed. (Does not stack) | Leave lantern behind — stays there until you place another (separate from the primary lantern). Also grants small movement speed. (Does not stack) | Mostly exploratory until the player learns: shoot the lantern with an arrow and it breaks into a fiery arrow. If so, give the lantern later (haunted house level) so fire-arrow puzzles aren't trivially bypassed. |
| ✅ Done | **Revolver** | Loads 6 shots over your next 6 moves | Fan the hammer — dump all loaded bullets now in a fanned half-circle in front of you. | Add gun-in-front animation with the player rotating; tween a recoil push per shot. An NPC accuracy test (break 6 bottles / hit 6 targets perfectly) would be very satisfying. |
| ✅ Done | **Map** | Reveal area / minimap | Drop a recall marker you can warp back to. | The marker must remember which camera zone it was in, so warping back restores that camera. |

## Conventions (from the implemented items)

- One ability scene per item; the script branches on `is_secondary` (`initialize()`).
- `Card` resource carries `secondary_ability_id`, `secondary_description`,
  `secondary_cost`, `secondary_commit_value`, plus `chargeable` / `secondary_chargeable`.
- Hold-to-charge: the ability spawns on press and `on_charge_release()` fires on release
  (see Bow). `set_charge_progress(seconds)` is pushed each frame while held.
- Tile-based hits: tiles are 2 units; forward is −Z, right is +X (see `player.gd`).
  Reuse `core/components/hitbox.tscn` (`collision_mask = 48` = EnemyHurtbox + Breakable).
