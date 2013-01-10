function love.load()
	-- libraries	
	require "zombie/Zombie"
	require "menu"
	require "camera"
	
	-- load map
	local ATL = require("AdvTiledLoader")
	ATL.Loader.path = 'map/'
	map = ATL.Loader.load("map01.tmx")
	map:setDrawRange(0, 0, map.width * map.tileWidth, map.height * map.tileHeight)
			
	-- graphics
	width = love.graphics.getWidth()
	menuWidth = 150
	viewWidth = width - menuWidth	
	height = love.graphics.getHeight()
	
	-- init menu
	menu = Menu:new(viewWidth, menuWidth, height)
	
	-- init Zombie
	z = Zombie:new()
	z.x = 150
	z.y = 150
	
	-- viewpoint
	vspeed = 4							  	
	vpxmin = viewWidth / 2
	vpxmax = (map.width * map.tileWidth) - vpxmin
	vpx = vpxmin
	vpymin = height / 2
	vpymax = (map.height * map.tileHeight) - vpymin
	vpy = vpymin
	
	-- background color
	love.graphics.setBackgroundColor(85,85,85)
	
	-- restrict camera
	camera:setBounds(0, 0, map.width * map.tileWidth - viewWidth, 
		map.height * map.tileHeight - height)
	
	-- global vars
	--delay = 120	
end


function love.update(dt)
	-- viewpoint movement - arrow keys
	if love.keyboard.isDown("right") then
		vpx = math.clamp(vpx + vspeed, vpxmin, vpxmax)
	end
	if love.keyboard.isDown("left") then
		vpx = math.clamp(vpx - vspeed, vpxmin, vpxmax)
	end
	if love.keyboard.isDown("up") then
		vpy = math.clamp(vpy - vspeed, vpymin, vpymax)
	end
	if love.keyboard.isDown("down") then
		vpy = math.clamp(vpy + vspeed, vpymin, vpymax)
	end
	
	-- zombie movement
	if love.keyboard.isDown("w") then
		zombie.move = "N"
	elseif love.keyboard.isDown("d") then
		zombie.move = "E"
	elseif love.keyboard.isDown("s") then
		zombie.move = "S"
	elseif love.keyboard.isDown("a") then
		zombie.move = "W"
	end	
	
	-- update zombie
	--z:update(dt, map)
	
	-- center camera
	camera:setPosition(math.floor(vpx - (viewWidth / 2)), 
		math.floor(vpy - height / 2))
end


function love.draw()
	camera:set()
	
	map:draw()	
	
	--zombie:draw()
	
	camera:unset()
	
	menu:draw()
end


-- callback, only exec on event
function love.keyreleased(key)
	if key == "escape" then -- kill app
		love.event.quit()
	end	
end

function math.clamp(x, min, max)
	return x < min and min or (x > max and max or x)
end	