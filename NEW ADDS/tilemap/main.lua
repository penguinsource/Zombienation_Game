function love.load()	
	dofile("map.lua") 	-- load map functions
	initMap(20,20)		-- init map object
	loadMap()			-- load map from file
end

function love.update(dt)
end

function love.draw()	
	drawMap() 			-- draw the map
end