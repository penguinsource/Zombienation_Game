Running the game:

	- this distributable only works on windows machines
	- click the run.bat file in the src directory 
	- this simply runs the game engine (loveapp/love.exe) with the current directory as argument


Controls:

	- arrow keys to move camera around
	- 'esc' to pause the game and access menu
	- some debug controls were used for testing and are left in, but may not be stable
		- '[' and ']' to zoom in and out (some things are not responsive unless at original zoom level)
		- numpad '+' and '-' to speed up and slow down time (may crash past 8x)
		- 'p' and 'r' to quickly pause and restart game (unpredictable behavior if used together with the 'esc' pause menu)

Options:

	- at the start of the game you can modify how many of each units spawn (for easer testing) as well as regenerate the map



Potential compatibility issue:

	- there may be an issue with OpenGL with on-board graphics cards
		- this is due to them not being able to store textures beyond a certain resolution
		- our game uses a canvas to draw the entire map to in order to avoid drawing 10,000 tiles at each cycle
		- this canvas may end up being too big to be stored by older graphics cards
	- if this occurs, the computers in the Windows labs are able to run the game no problem