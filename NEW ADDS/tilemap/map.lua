function initMap(w,h)
	map = {}
	map.width = w
	map.height = h
	map.tileSize = 25 -- default pixel square size
	map.tiles = {}
	
	-- tile types
	map.road = love.graphics.newImage("road.png")
	map.grass = love.graphics.newImage("grass.png")
	map.water = love.graphics.newImage("water.png")
	map.blocked = love.graphics.newImage("blocked.png")
end

function loadMap()	
	io.input("mapFile.txt")	
	data = io.read("*all")
	i = 0
	for c in data:gmatch"%u" do -- match all upper case chars
		map.tiles[i] = c
		i = i + 1	
	end
end

function drawMap()
	for x=0,map.width-1 do
		for y=0,map.height-1 do
			xb = x * map.tileSize
			yb = y * map.tileSize
			
			id = map.tiles[index(x,y)]
			tile = getTile(id)
			love.graphics.draw(tile, xb, yb)
		end
	end
end

function index(x,y)
	return (y * map.width) + x
end

function getTile(id)
	if (id == "R") then
		return map.road
	end
	if (id == "W") then
		return map.water
	end
	if (id == "G") then
		return map.grass
	end
	if (id == "B") then
		return map.blocked
	end
end