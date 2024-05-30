# Square Space Fight
repository for a small Godot 4.2 fighting game project, with a sketchbook aesthetic

## Controls

### P1:
* WASD = movement
* U = attack (also: I, O)

### P2:
* Arrows = movement
* Numpad1 = attack (also: Numpad2, Numpad3, J, K, L)

### on joypad (P1: first connected device, P2: second device): 
* D-Pad = movement
* A = attack
* keyboard controls are always active even when a joypad is connected

### Debug hotkeys
* F1: save state
* F2: load state
* F3: show hitboxes
* F4: reset health
* F5: toggle training mode
* ALT+ENTER: full screen

### Extra remarks
* the input buffer accepts negative edge inputs too for specials

## Movelist

### Naomi
* A: slash attack (cancels into all Command Normals and Specials, jump cancel on hit)
* while walking forward A: dash slash (can't cancel into anything)
* 2A: upwards kick (cancels into all Specials, jump cancel on hit, auto-corrects side)
* j.A: jumping slash
* 236A: flying kick (air ok)
* 632A: jaguar knee (cancels into j.236A on hit)

## Basic combo structure:
* hitting the opponent during the start of their hitstun frames floats them. A sample starter can be either A > 2A, 2A > 236A or e.g. A > 236A
* then, hit them before they hit the ground. Every wall hit reverses the momentum of the character that was hit
* currently there is no block. Backdash (4), Forward Jump (9) and Jaguar Knee (632A) have startup invul


