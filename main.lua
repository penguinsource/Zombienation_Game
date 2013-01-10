require "map/MapGen"
require "gui/Menu"
require "gui/StartMenu"
require "gui/PauseMenu"
require "gui/View"
require "gui/InfoText"
require "camera"
require "units/UnitManager"
require "loveframes/init"
require "Units/Point"
require "Units/shortestPath/Astar"

--[[ 
H
	write little messages here so changes arent confusing ? if i do modify something and it still needs to be changed,
	i put a comment with a tag *change* right by the line
	
	mike:
		- viewpoint code, clean up this main file a bit
		- moved all the menu type code to the menu type file
		- map changes saved in "map/defaultMap.txt"
		- building editing with debug menu 
	
	mikus: 
		- hid cursor, replaced with a zombie hand (just a random image i found for now)
		- added mouse isDown check to draw road tiles
	
	mihai: (reminder to myself to print out states.. check arrays.. there was a small bug which i cant reproduce. if you find a bug, save the file and line
	 and write it here please !)
		- zombies wonder around.. transform human after 2 seconds of 'eating them (??)'
		- human n zombie moving around while zombie is feasting on human.. will change so they stay in same place when 
		-- zombie eats human
		
		- have some animation code, didnt work out, commented out, ignore it, its together with the unit code so it shouldnt
		- confuse anything..
		
		- mike, can we get rid of the black outline around the map ?
			-- if you want to..it was a boundary those are just blocked tiles
		
		-Update: I added some main menu pics.. idk if they're good or not.. use em or not, idc. and here s some other images ( have to look
		through the pages):
		http://gmc.yoyogames.com/index.php?showtopic=513891&st=0
]]--

-- game settings
supplies = 0

orig_number_of_zombies = 2			-- zombies are red
orig_number_of_humans = 100			-- humans are blue
orig_number_of_rangers = 0			-- i thought this was a poem
orig_number_of_workers = 5			-- i wish it was too

orig_number_of_cars = 5				--cars?? whesn this commin

-- map size
mapW = 100
mapH = 100

-- gamestate
Gamestate = require "utils/gamestate"
Timer = require "utils/timer"
startMenuSTATE = Gamestate.new()
gameSTATE = Gamestate.new()
winSTATE = Gamestate.new()
loseSTATE = Gamestate.new()
paused = false
multiplier = 1

function love:load()	
	-- debug menu bools
	drawTile = "R"
	dragSelect = false
	selectPatrol = false
	dragx, dragy = 0, 0
	defaultFont = love.graphics.newFont(12)
	
	-- music
	music = love.audio.newSource("/units/fellowship.mp3") 
	
	-- seeding randomizer
	randomizer = math.random(30,60)				
	math.randomseed( os.time() + randomizer )
	
	-- generate a map
	generator = MapGen:new()
	--generator:defaultMap()
	difficulty = 1
	--generator:randomMap()
	--generator:newMap(75,75)
	generator:randomMap()
	--generator:newMap(75,75)


	-- get the map	
	map = generator:getMap()
	
	-- A* algorithm
	astar = Astar:new()
	astar:init()
	
	-- initiate units
	unitManager = UnitManager:new()
	unitManager:initUnits()	
	
	-- graphics setup	
	width = love.graphics.getWidth()
	height = love.graphics.getHeight()
	menuWidth = 115
	viewHeight = height - menuWidth
	
	-- viewpoint
	view = View:new(viewHeight, map)
	
	-- info text
	infoText = InfoText:new(0,height - menuWidth - 17)
	
	-- minimap
	minimap = Minimap:new(map, view, unitManager, width - map.width - 7, height - map.height - 8, width, height)
	minimap:init()
	map:setMinimap(minimap)
		
	-- restrict camera
	camera:setBounds(0, 0, map.width * map.tileSize - width, map.height * map.tileSize - viewHeight)
		
	-- cursor
	love.mouse.setVisible(false)
	cursor = love.graphics.newImage("gui/cursor.png")
	xcursor = love.graphics.newImage("gui/xcursor.png")
	
	Gamestate.switch(startMenuSTATE)
end

------------------ START STATE CODE ----------------------------------------------
function startMenuSTATE:enter()
	Timer.clear()	
	titleScreen = love.graphics.newImage("gui/titleScreen.png")
	startMenu = StartMenu:new(width/2 - 100, height/2 + 100)
	startMenu:setup()
	alpha = 0
	Timer.add(0.005, function(func) alpha = alpha+1 Timer.add(0.005, func) end)
	
end

function startMenuSTATE:leave()
	Timer.clear()	
end

function startMenuSTATE:update(dt)
	Timer.update(dt)
	if (alpha == 255) then Timer.clear() end
	if love.keyboard.isDown(" ") then
		--Gamestate.switch(gameSTATE)
	end
	
	startMenu:update()
	loveframes.update(dt)
end

function startMenuSTATE:draw()
	love.graphics.setColor(255,255,255,alpha)
	love.graphics.draw(titleScreen, 0, 0)
	
	loveframes.draw()
	
	-- cursor
	love.graphics.reset()	
	love.graphics.draw(cursor, love.mouse.getX(), love.mouse.getY())		
end

function startMenuSTATE:mousepressed(x, y, button)
	loveframes.mousepressed(x, y, button)
end

function startMenuSTATE:mousereleased(x, y, button)
	loveframes.mousereleased(x, y, button)
end

function startMenuSTATE:leave()
	startMenu:delete()
end

------------------ GAME STATE CODE ----------------------------------------------

-- this function is called everytime the game restarts
-- put any resetting code in here
function gameSTATE:enter()
	-- init menu
	menu = Menu:new(0, width, 115)
	menu:setup()
	
	-- pause menu
	pauseMenu = PauseMenu:new(width/2 - 100, height/2 - 100)
	pauseMenu:setup()
	
	-- reset units
	unitManager:resetUnits()	
	
	-- redraw map (to get rid of blood splatter)
	map:drawMap()
	
	-- reset camera
	view.x, view.y = 0,0
	paused = false
	infoText:reset()
end

function gameSTATE:leave()
	-- init menu
	menu:delete()
	pauseMenu:delete()
end

function gameSTATE:pauseResume(menubool, mmbool)
	selectPatrol = false
	unitManager:pauseGame()	-- pause and resume game
	paused = not paused
	menu:showHide(menubool)
	minimap:showHide(mmbool)
end

function gameSTATE:update(dt)
	dt = dt*multiplier
	-- restrict drag select
	if dragSelect and (love.mouse.getY() >= viewHeight) then
		love.mouse.setPosition(love.mouse.getX(), height - menuWidth)
	end

	-- viewpoint movement - arrow keys
	view:update(dt)
	
	-- update unit positions
	unitManager:update(dt)
	
	-- update menu
	menu:update(dt)
	
	-- current mouse position
	xpos = math.floor((love.mouse.getX() + view.x) / map.tileSize)
	ypos = math.floor((love.mouse.getY() + view.y) / map.tileSize)
	
	-- map editing
	
	-- in building mode
	--[[if menu.buildingMode then
		-- clicking, not on the side menu
		if love.mouse.isDown("l") and love.mouse.getX() < viewWidth then
			-- valid map position
			if (xpos > -1) and (ypos > -1) and (xpos < map.width) and (ypos < map.height) then
				-- can place building here
				map:newBuilding(xpos, ypos, menu.b_type)
			end
		end
	else]]--
	if menu.debugMode then
		if love.mouse.isDown("l") and (love.mouse.getY() < viewHeight) and  not minimap.moving then
			if (xpos > -1) and (ypos > -1) and (xpos < map.width) and (ypos < map.height) then
				--map.tiles[map:index(xpos,ypos)]:setId(drawTile)
				map.tiles[xpos][ypos]:setId(drawTile);
				map:updateTileInfo(xpos,ypos)
			end
		end
	end
	
	
	-- center camera
	camera:setPosition(math.floor(view.x), math.floor(view.y))
	
	-- update minimap
	minimap:update(view.x,view.y)
	
	-- loveframes
	loveframes.update(dt)
	
	--update infotext
	infoText:update(dt)
end

function gameSTATE:draw()
	local mx = love.mouse.getX()
	local my = love.mouse.getY()

-- restrict drag select
	--[[if dragSelect and (mx >= viewWidth) then
		love.mouse.setPosition(viewWidth - (mx - viewWidth), my)
	end	]]--
	-- gotta set font to default because loveframes imagebutton messes it up for some reason
	love.graphics.setFont(defaultFont)
	-- set camera
	camera:set()					
	
	-- draw the map
	map:draw() 		
	
	-- draw building placement rectangle
	--menu:buildingPlacement(map, view.x, view.y)
	
	-- draw the units
	unitManager:draw()
	
	-- unset camera
	camera:unset()					
	
	-- draw menu
	menu:draw()
	
	-- draw minimap
	minimap:draw()
	
	-- drag selection
	if (not(menu.debugMode) --[[and not(menu.buildingMode)]] and dragSelect) then 
		love.graphics.setColor(50,50,50,50)
		love.graphics.rectangle("fill", dragx, dragy, mx - dragx, my - dragy)
		love.graphics.setColor(50,50,50,150)
		love.graphics.setLineWidth(1)
		love.graphics.rectangle("line", dragx+0.5, dragy+0.5, math.floor(mx) - dragx, math.floor(my) - dragy)
	end
	
	-- pause menu
	pauseMenu:draw()
	
	-- debug
	if menu.debugMode then
		love.graphics.setColor(255,255,255)
		love.graphics.print("Camera Cood: ["..view.x..","..view.y.."]", 0, 0)
		love.graphics.print("Mouse Cood: ["..mx..","..my.."]", 0, 15)
		love.graphics.print("Zombies alive: " .. number_of_zombies, 0, 30)
		love.graphics.print("Humans alive: " .. number_of_humans, 0, 45)
		love.graphics.print("Framerate: " .. love.timer.getFPS(), 0, 60)
	end
	
	--love.graphics.print("Gold: ".. gold, 715, 0)
	--love.graphics.print("Under Ranger: ".. gold, 715, 0)
	
	-- loveframes
	loveframes.draw()
	
	-- infotext
	infoText:draw()
	
	-- cursor
	love.graphics.reset()	
	if not selectPatrol then
		love.graphics.draw(cursor, love.mouse.getX(), love.mouse.getY())	
	else
		love.graphics.draw(xcursor, love.mouse.getX(), love.mouse.getY())	
	end
	
	love.graphics.reset()	
end

-- callback functions needed by loveframes, we can use them too
function gameSTATE:mousepressed(x, y, button)
	--[[if (y < viewHeight) and (button == "l") then
			local xmap  = math.floor((x+view.x)/map.tileSize)
			local ymap  = math.floor((y+view.y)/map.tileSize)
		print(xmap..","..ymap..": "..map.tiles[xmap][ymap].id)
	end]]--
	if (y < viewHeight) and not menu.debugMode and not paused then
		--unitManager:deselectUnits()
		if (button == "l") then	
			--[[local xmap  = math.floor((x+view.x)/map.tileSize)
			local ymap  = math.floor((y+view.y)/map.tileSize)
			print(xmap..","..ymap..": "..map.tiles[xmap][ymap].id)]]--
			if selectPatrol then
				selectPatrol = false
				unitManager:patrol(x+view.x, y+view.y)
			else
				dragSelect = true
				dragx, dragy = x, y
			end
		elseif (button == "r") then
			if selectPatrol then
				selectPatrol = false
			end
			--unitManager:createRanger(x,y)
			--unitManager:createWorker(x,y)
			--local timer = os.clock()
			--unitManager:moveTo(x+view.x,y+view.y)
			--print(string.format("elapsed time: %.2f\n", os.clock() - timer))
		end
	end
	
	minimap:mousepressed(x, y, button)
	loveframes.mousepressed(x, y, button)
end

function gameSTATE:mousereleased(x, y, button)
	-- process loveframes callback first so that DEBUG can be set to false
	loveframes.mousereleased(x, y, button)
	
	minimap:mousereleased()
	
	if (button == "l") and not menu.debugMode and (y < viewHeight) then	
		if dragSelect then
			dragSelect = false
			unitManager:selectUnits(dragx+view.x, dragy+view.y, x+view.x, y+view.y)
		end		
	end	
	
end

function gameSTATE:keypressed(key, unicode)
	loveframes.keypressed(key, unicode)
end


function gameSTATE:keyreleased(key)
	if key == "escape" then 
		pauseMenu:showHide()
		gameSTATE:pauseResume(true, true)
	elseif key == "p" then
		gameSTATE:pauseResume(true, false)
		--paused = not paused
	elseif key == "r" and (not paused) then
		--if paused then gameSTATE:pauseResume() end
		Gamestate.switch(gameSTATE)
	elseif key == "]"  then		
		camera:scale(1/1.3,1/1.3)
		infoText:addText("Zoom Level: "..1/camera.scaleX.."X")
	elseif key == "["  then		
		camera:scale(1.3,1.3)
		infoText:addText("Zoom Level: "..1/camera.scaleX.."X")
	elseif key == "kp+"  then
		multiplier = multiplier*2
		infoText:addText("Fast Forward: "..multiplier.."X")
	elseif key == "kp-"  then
		multiplier = multiplier/2
		infoText:addText("Fast Forward: "..multiplier.."X")
	elseif key == "m" then
		love.audio.play(music)
	end
	
	--loveframes
	loveframes.keyreleased(key)
end

----------win state
function winSTATE:enter()
	winPic = love.graphics.newImage("gui/youwinbg.png")
end

function winSTATE:draw()
	love.graphics.draw(winPic,0,0)
end

function winSTATE:keyreleased(key)
	Gamestate.switch(startMenuSTATE)
end

function winSTATE:mousereleased(key)
	Gamestate.switch(startMenuSTATE)
end

----------lose state
function loseSTATE:enter()
	losePic = love.graphics.newImage("gui/gameoverbg.png")
end

function loseSTATE:draw()
	love.graphics.draw(losePic,0,0)
end

function loseSTATE:keyreleased(key)
	Gamestate.switch(startMenuSTATE)
end

function loseSTATE:mousereleased(key)
	Gamestate.switch(startMenuSTATE)
end

-- love callbacks redirected to gamestate
function love.draw()
    Gamestate.draw()
end

function love.update(dt)
	loveframes.update(dt)
    Gamestate.update(dt) 
end

function love.keyreleased(key)
    Gamestate.keyreleased(key)
end

function love.keypressed(key)
    Gamestate.keypressed(key)
end

function love.mousepressed(x, y, button)
	Gamestate.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
	Gamestate.mousereleased(x, y, button)
end
-----------------------------------------------

function math.clamp(x, min, max)
	return x < min and min or (x > max and max or x)
end	