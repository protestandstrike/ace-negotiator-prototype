# ACE NEGOTIATOR — Prototype (Intro + Case 1)

A playable Godot 4 prototype of the **introduction** and **Case 1: The Restructuring**.

## How to play it
1. Download **Godot 4.3** (or newer 4.x) from godotengine.org.
2. Open Godot → **Import** → pick `project.godot` in this folder.
3. Press **F5** (or the ▶ Play button).

**Controls:** click / Enter / Space = next line · E = records · L = log · Esc = menu.
Keyboard and mouse both work for every choice.

## What's in it
- Title screen, 8-page introduction (setting, cast, how to play), Case 1 title card.
- All **12 scenes** of Case 1, running straight from the script file `data/C01_SCRIPT_v2_0.json`.
- **Negotiations** N01 and N02: QUESTION! / CHALLENGE! / EVIDENCE! / CONSULT, Momentum 5, checkpoints.
- **4 puzzles** with a case board, free hints and full / limited / "not enough info" results.
- **Evidence board**, dialogue log, Nina's consent choice, Daniel's instructions, authority checks.
- All **3 endings** (Agreement / Continuing / Disagreement) and a Case 1 report screen.
- Autosave (scene start + negotiation checkpoints), Continue, settings (text speed, size, reduced motion).

## Placeholders
- Characters and backgrounds are simple shapes drawn in code — no art files yet.
- No sound or music.
- Intro text is written from the GDD; it is not script dialogue.

## Rules I had to fill in (the script doesn't define them)
- **Collecting records:** when a record is offered, you choose "verify" or "set aside (gap)".
- **Puzzle answers:** the "correct" level depends on which records you verified.
- **Nina / Daniel decisions:** shown as their own decision screen. You choose for them.
- **UWF authority (Scene 6):** always starts as "not verified". Either recovery option then verifies it.

## Script issue spotted
In `C01_S05`, lines `D0002` (Daniel) and `D0003` (Julian Vane) look swapped.
D0003 says "systems *I* maintain", which sounds like Daniel. Kept as written.

## Testing
Automated full playthroughs (all 3 endings reached, no errors):
`godot --headless --path . -- --autotest --seed=1`
