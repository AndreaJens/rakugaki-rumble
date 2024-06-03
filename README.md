# Rakugaki Rumble
A small Godot 4.2 fighting game project, with a sketchbook aesthetic

## Controls

### P1:
* WASD = movement
* U = attack, confirm (also: I)
* O = install, cancel
* ESC = pause (also: Tab)

### P2:
* Arrows = movement
* Numpad1 = attack, confirm (also: Numpad2 J, K)
* Numpad3 = install, cancel (also: L)
* Numpad+ = pause (also: Numpad/)

### on joypad (P1: first connected device, P2: second device): 
* arrows = movement
* A = attack, confirm
* B = install, cancel
* start/select = pause
* keyboard controls are always active

### training mode hotkeys
* F1/LT: save state
* F2/RT: load state
* F3/RB: show hitboxes
* F4/LB: reset health, refill meter

### other controls
* ALT+ENTER: full screen

### Universal Mechanics (notation uses joypad buttons and numpad notation)
* 4: Backdash (8 frames of full invulnerability)
* B (ground): Infinity Install (with full meter, cancels every grounded attack, lasts 2.5 seconds - removes the Bounce Limit and increases the momentum transfer from the walls)
* 2B (on the ground): Zero Install (with full meter, cancels every grounded attack, lasts 2.5 seconds - removes bounces all together but slashes damage to 66%)
* B (while in air hit stun): Interrupt Stumble (with full meter. If performed without full meter, it will disable the super meter for the whole round) 

### Movelist (notation uses joypad buttons and numpad notation)

#### Naomi
* A: Five Nails Death Slash (cancels into all Command Normals and Specials, jump cancel on hit)
* while walking forward A: Five Nails Dash Slash (forward jump cancel on hit)
* 2A: Skyward Scraper (cancels into all Specials, jump cancel on hit, auto-corrects side)
* j.A: Five Nails Air Slash
* 236A: Cheetah Thrust Kick (air ok)
* 632A: Jaguar Knee (cancels into j.236A on hit)

#### Rho-Zetta
* 4A/5A/6A: Headbash (cancels into all Command Normals and Specials, jump cancel on hit)
* 2A: The Pit and the Pendulum (cancels into all Specials, jump cancel on hit, auto-corrects side)
* j.A: Spikes and Yikes (cancels into Run Amok Rampage on hit)
* 46A: Run Amok Rampage (2 hits, cancels into 2A on hit, forward jump cancel on hit, can be performed from back dash)

### Basic combo structure:
* hitting the opponent during the start of their hitstun frames floats them. A sample starter can be either A > 2A, 2A > 236A or e.g. A > 236A
* then, hit them before they hit the ground. Every wall hit reverses the momentum of the character that was hit 
* max 2 bounces per combo before wall splat, unless Infinity Install is active
* currently there is no block. Backdash (4), Forward Jump (9) and Jaguar Knee (632A) have startup invul

### Extra remarks
* the input buffer accepts negative edge inputs for specials

