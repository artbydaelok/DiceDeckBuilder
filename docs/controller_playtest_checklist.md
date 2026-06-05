# Controller Playtest — Side Abilities & Gamepad Support

Manual playtest for the shoulder-button side abilities and the controller-support
fixes. Requires a **physical controller connected**.

**Button map (Xbox layout)** — PlayStation in parentheses:

| Button | Action |
|--------|--------|
| A (✕) | Use **top** face ability / interact |
| X (□) | Flip |
| Y (△) | Open quest log |
| **LB (L1)** | Use **left** face ability |
| **RB (R1)** | Use **right** face ability |
| Start (Options) | View deck |
| Back/Select (Share) | Pause |
| D-pad / left stick | Move |
| In menus: LB/RB | Switch tabs · A confirm · Back cancel |

---

## Setup

- [ ] Run the game with a controller connected.
- [ ] Enter a level with the card system active.
- [ ] Equip **distinct, recognizable** abilities on the **top**, **left**, and **right** faces (e.g. shotgun top, axe left, grenade right).
- [ ] Make sure you have **energy** to spend.

## 1. Side abilities (headline feature)

- [ ] **LB fires the LEFT face's ability** — not the top, not the right.
- [ ] **RB fires the RIGHT face's ability.**
- [ ] **A still fires the TOP face's ability** (unchanged).
- [ ] **Energy is consumed** on each side activation.
- [ ] **Insufficient-energy** cue plays when you can't afford a side ability.
- [ ] **Roll the die, then press LB/RB** — they fire whatever rolled into the left/right faces (face tracking works, not a fixed slot).
- [ ] An **ON_FACE_UP** or **LINKED** card on a side face does **nothing** on LB/RB press (only ACTIVATE/BOTH respond — same as the top button).
- [ ] An **empty** side face → LB/RB does nothing (no error/crash).
- [ ] During a roll / commit-lock, LB/RB are ignored (no firing mid-roll).

## 2. Other player actions on gamepad

- [ ] **X performs the flip** (new binding — was keyboard-only).
- [ ] **Start opens the deck viewer**; press again to close.
- [ ] **LB no longer opens the deck viewer** (old conflict resolved).
- [ ] **Y opens the quest log.**
- [ ] **Back/Select opens the pause menu.**

## 3. Menu navigation (focus fixes)

- [ ] **Pause menu**: a button is focused on open; D-pad/stick **up/down** moves between buttons; **A** activates; **Back** closes.
- [ ] **Quest log**: a control is focused on open; **A** on a completed quest's **Claim** button works; after claiming, focus is not left dead.
- [ ] **Quest log**: **LB/RB switch tabs** (Main / Side / Challenge).
- [ ] Main menu and dialogue still navigate fine (regression check).

## 4. Regressions to watch

- [ ] Mouse + keyboard still work for everything (LMB top ability, F flip, Tab deck, J quest log, Esc pause).
- [ ] A single LB/RB press fires **one** ability, once (no double-trigger).
- [ ] Switching from controller to mouse mid-session doesn't break menu focus.

---

## Results / notes

> Jot down anything that failed or felt off — button, expected vs actual:

-
-
-
