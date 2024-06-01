# Square Space Fight
repository for a small Godot 4.2 fighting game project, with a sketchbook aesthetic

## Controls

### P1:
* WASD = movement
* U = attack (also: I)
* O = install

### P2:
* Arrows = movement
* Numpad1 = attack (also: Numpad2 J, K)
* Numpad3 = install (also: L)

### on joypad (P1: first connected device, P2: second device): 
* arrows = movement
* A = attack
* B = install
* keyboard controls are always active

### debug hotkeys
* F1/LT: save state
* F2/RT: load state
* F3/RB: show hitboxes
* F4/LB: reset health, refill meter
* F5/R3: toggle training mode
* ALT+ENTER: full screen

### Universal Mechanics (notation uses joypad buttons and numpad notation)
* 4: Backdash (8 frames of full invulnerability)
* B (ground): Infinity Install (with full meter, cancels every grounded attack, lasts 2.5 seconds - removes the Bounce Limit and increases the momentum transfer from the walls)
* 2B (on the ground): Zero Install (with full meter, cancels every grounded attack, lasts 2.5 seconds - removes bounces all together but slashes damage to 66%)
* B (while in air hit stun): Interrupt Stumble (with full meter. If performed without full meter, it will disable the super meter for the whole round) 

### Movelist (notation uses joypad buttons and numpad notation)
#### Naomi
* A: slash attack (cancels into all Command Normals and Specials, jump cancel on hit)
* while walking forward A: dash slash (forward jump cancel on hit)
* 2A: upwards kick (cancels into all Specials, jump cancel on hit, auto-corrects side)
* j.A: jumping slash
* 236A: flying kick (air ok)
* 632A: jaguar knee (cancels into j.236A on hit)

### Basic combo structure:
* hitting the opponent during the start of their hitstun frames floats them. A sample starter can be either A > 2A, 2A > 236A or e.g. A > 236A
* then, hit them before they hit the ground. Every wall hit reverses the momentum of the character that was hit 
* max 2 bounces per combo before wall splat, unless Infinity Install is active
* currently there is no block. Backdash (4), Forward Jump (9) and Jaguar Knee (632A) have startup invul

### Extra remarks
* the input buffer accepts negative edge inputs for specials

