7 years after Mikus and I made this game, here is a little video demo of it on a Windows machine. Yes, I can't remember how the simulation works exactly but it's surprinsingly complex: https://www.loom.com/share/d6a19f504ead4c539f9ad9ecadb55d54

Running the game:

	- Click the run.bat file in the src directory for Windows launch.
	- Unix and Mac OS X require love2d implementation.
	- Runs the game engine (loveapp/love.exe) with the current directory as argument.


Controls:

	- Press arrow keys to move camera around.
	- Press 'esc' to pause the game and access menu.
	- Some debug controls were used for testing and are left in - but may not be stable.
	- Press '[' and ']' to zoom in and out (some things are not responsive unless at original zoom level).
	- Press numpad '+' and '-' to speed up and slow down time (may crash past 8x).
	- Press 'p' and 'r' to quickly pause and restart game (unpredictable behavior if used together with the 'esc' pause menu).

Options:

	- At the start of the game you can modify how many of each units spawn (for easer testing) as well as regenerate the map.
	- main.lua allows game settings customization of number of zombies, workers, rangers, humans and editing of width and height of map size.
	- main.lua has settings to change difficulty of random map generation.



Potential compatibility issue:

	- There may be an issue with OpenGL with on-board graphics cards due to not being able to store textures beyond a certain resolution.
	- Game uses a canvas to draw the entire map in order to avoid drawing 10,000 tiles at each cycle.
	- Canvas may end up being too big to be stored by older graphics cards.
	- This app is compatible and tested on Linux/Windows/Mac OS X systems using love2d implementation: https://love2d.org/wiki/Getting_Started

Authors:

Mihai Oprescu ( me )

Mikus Lorence ( https://github.com/shade45 )

Michael Bessette
