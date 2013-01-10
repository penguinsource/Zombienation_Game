require "map/Map"
require "map/Tile"
require "map/Building"
require "map/Minimap"
require "map/PerlinNoise"
require "map/Sector"
require "map/District"

MapGen = {}

-- building sprites
b1x1 = {}
b1x1[1] = love.graphics.newImage("map/buildings/b1x1_1.png")
b1x1[2] = love.graphics.newImage("map/buildings/b1x1_2.png")
b1x1[3] = love.graphics.newImage("map/buildings/b1x1_3.png")
b1x1[4] = love.graphics.newImage("map/buildings/b1x1_4.png")
b1x1[5] = love.graphics.newImage("map/buildings/b1x1_5.png")
b1x1[6] = love.graphics.newImage("map/buildings/b1x1_6.png")
b1x1[7] = love.graphics.newImage("map/buildings/b1x1_7.png")
b1x1[8] = love.graphics.newImage("map/buildings/b1x1_8.png")
b1x1[9] = love.graphics.newImage("map/buildings/b1x1_9.png")
b1x1[10] = love.graphics.newImage("map/buildings/b1x1_10.png")
b1x1[11] = love.graphics.newImage("map/buildings/b1x1_11.png")
b1x1[12] = love.graphics.newImage("map/buildings/b1x1_12.png")
b1x1[13] = love.graphics.newImage("map/buildings/b1x1_13.png")
b1x1[14] = love.graphics.newImage("map/buildings/b1x1_14.png")
b1x1[15] = love.graphics.newImage("map/buildings/b1x1_15.png")
b1x1[16] = love.graphics.newImage("map/buildings/b1x1_16.png")
b1x1[17] = love.graphics.newImage("map/buildings/b1x1_17.png")
b1x1[18] = love.graphics.newImage("map/buildings/b1x1_18.png")
b1x1[19] = love.graphics.newImage("map/buildings/b1x1_19.png")
b1x1[20] = love.graphics.newImage("map/buildings/b1x1_20.png")
b1x2 = {}
b1x2[1] = love.graphics.newImage("map/buildings/b1x2_1.png")
b1x2[2] = love.graphics.newImage("map/buildings/b1x2_2.png")
b1x2[3] = love.graphics.newImage("map/buildings/b1x2_3.png")
b1x2[4] = love.graphics.newImage("map/buildings/b1x2_4.png")
b1x2[5] = love.graphics.newImage("map/buildings/b1x2_5.png")
b1x2[6] = love.graphics.newImage("map/buildings/b1x2_6.png")
b2x1 = {}
b2x1[1] = love.graphics.newImage("map/buildings/b2x1_1.png")
b2x1[2] = love.graphics.newImage("map/buildings/b2x1_2.png")
b2x1[3] = love.graphics.newImage("map/buildings/b2x1_3.png")
b2x1[4] = love.graphics.newImage("map/buildings/b2x1_4.png")
b2x1[5] = love.graphics.newImage("map/buildings/b2x1_5.png")
b2x1[6] = love.graphics.newImage("map/buildings/b2x1_6.png")

b2x2 = {}
b2x2[1] = love.graphics.newImage("map/buildings/b2x2_1.png")
b2x2[2] = love.graphics.newImage("map/buildings/b2x2_2.png")
b2x2[3] = love.graphics.newImage("map/buildings/b2x2_3.png")
b2x2[4] = love.graphics.newImage("map/buildings/b2x2_4.png")
cementImg = love.graphics.newImage("map/buildings/commercialGround.png")


-- constructor
function MapGen:new()
	local object = {
		map = nil,
		width = 0,
		height = 0,
	}
			
	setmetatable(object, { __index = MapGen })
	return object
end

-- create new blank map
function MapGen:newMap(w, h)
	self.width = w
	self.height = h
	
	self.map = Map:new() 	-- constr obj
	self.map:initMap(w,h)   -- default blank map	
	
	
	-- default map
	--self:blockBoundary() 	-- outline edges black
	self:addCircleLake(15,15,5)
	
	-- some test roads (for quick testing, until debug map draw mode is in)
	self:addRoad(24, 6, 24, 10)
	self:addRoad(23, 6, 25, 6)
	self:addRoad(21, 10, 23, 10)
	
	-- a couple random buildings
	--[[self:addBuilding(5, 5, 66)
	self:addBuilding(27, 28, 43)
	self:addBuilding(33, 48, 35)
	self:addBuilding(55, 92, 33)
	self:addBuilding(78, 12, 34)
	self:addBuilding(12, 84, 64)]]--
	
	-- save info on each tile's neighbor
	for x=0,self.width-1 do
		for y=0,self.height-1 do
			self.map:getNeighborInfo(x,y)						
		end
	end
	
	self.map:drawMap()
end

-- create random map based on difficulty
function MapGen:randomMap()
	print("generating random map")
	-- init new map
	self.width = mapW -- / random number
	self.height = mapH -- / rand
	self.map = Map:new()
	self.map:initMap(self.width, self.height)
	
	local freq = 4
	-- roads
	print("--dividing city")
	self:divideCity()	
	-- buildings
	print("--placing buildings")
	self:generateBuildings()
	-- remove roads to nowhere
	local size = 25
	--self:thinRoads(size)
	self:thin("R", "G", size)	
	-- remove silly lakes
	self:thin("W", "G", size)
	
	
	print("--updating tile info")
	-- update tiles
	local m = self.map
	for x=0,m.width-1 do
		for y=0,m.height-1 do
			m:updateTileInfo(x,y)
		end
	end
	
	-- draw the map
	print("--drawing canvas")
	self.map:drawMap()
	print("-complete")
end

-- split city to districts, split districts to sectors
function MapGen:divideCity()
	local m = self.map
	-- surround map with road
	self:roadBoundary()
	
	-- split city into districts
	m.districts = getDistricts(m.width, m.height)
	
	for _,v in pairs(m.districts) do
		-- add roads between districts
		if not(v.y1 == 0) then
			self:addRoad(v.x1, v.y1, v.x2, v.y1)
		end
		if not(v.x1 == 0) then
			self:addRoad(v.x1, v.y1, v.x1, v.y2)
		end
		if not(v.y2 == m.height-1) then
			self:addRoad(v.x1, v.y2, v.x2, v.y2)
		end
		if not(v.x2 == m.width-1) then
			self:addRoad(v.x2, v.y1, v.x2, v.y2)				
		end
		
		
		-- don't touch base district
		if not(v.isBase) then
			-- split district into sectors
			v:createSectors(m)		
			
			-- add roads to divide sectors
			local roadChance = 0.8
			for _,s in pairs(v.sectors) do
				if math.random() < roadChance and 
					not(s.y1 == v.y1+1) and not(s.y1 == 0) then
					self:addRoad(s.x1, s.y1, s.x2, s.y1)
				end
				if math.random() < roadChance and 
					not(s.x1 == v.x1+1) and not(s.x1 == 0) then
					self:addRoad(s.x1, s.y1, s.x1, s.y2)
				end
				if math.random() < roadChance and 
					not(s.y2 == v.y2-1) and not(s.y2 == m.height-1) then
					self:addRoad(s.x1, s.y2, s.x2, s.y2)
				end
				if math.random() < roadChance and 
					not(s.x2 == v.x2-1) and not(s.x2 == m.width-1) then
					self:addRoad(s.x2, s.y1, s.x2, s.y2)
				end
			end

			
			-- generate water for each district
			local waterChance = 0.75
			if math.random() < waterChance then
				-- water never touches the district separating roads...easy to change
				self:generateWater(v:xd()-6, v:yd()-6, Point:new(v.x1+3, v.y1+3))
			end
		else -- set the base and store 
			m:newBuilding(v.x1+1, v.y1+1, 32, nil, nil)
			m.baseTilePt = Point:new(v.x1+4,v.y1+3)
			--m.baseTilePt = Point:new(v.x1+1,v.y1+1)
			m.storeTilePt = Point:new(v.x2-1,v.y2-1)
		end
	end
	
	--[[ remove roads to nowhere
	local size = 25
	--self:thinRoads(size)
	self:thin("R", "G", size)	
	-- remove silly lakes
	self:thin("W", "G", size)
	--]]
end

function MapGen:thin(from, to, size)
	-- remove small connected components
	small = self:findConnectedComponents(0, size, from)
	self:removeComponents(small, to)
	-- remove dead ends
	while self:removeTiles(from, from, to, 2, 4, false) > 0 do end
end
--[[ thin roads and remove ones that don't make sense
function MapGen:thinRoads(size)
	-- find and remove connected components
	smallRoads = self:findConnectedComponents(0, size, "R")
	self:removeComponents(smallRoads, "G")	
	
	-- remove dead ends
	while self:removeTiles("R", "R", "G", 2, 4, false) > 0 do end
	
end
--]]

-- set neighbors (neighborType) of tile (tileType) to resetValue 
-- if not(minN < #neighbors < maxN)
--  return number of tiles reset
function MapGen:removeTiles(tileType, neighborType, resetValue, minN, maxN, eight)
	local m = self.map 
	local retVal = 0
	
	for x=0,m.width-1 do
		for y=0,m.height-1 do
			if m.tiles[x][y]:getId() == tileType then
				local count = 0
				if x-1 > -1 and m.tiles[x-1][y]:getId() == neighborType then
					count = count + 1
				end
				if x+1 < m.width and m.tiles[x+1][y]:getId() == neighborType then
					count = count + 1
				end
				if y-1 > -1 and m.tiles[x][y-1]:getId() == neighborType then
					count = count + 1
				end
				if y+1 < m.height and m.tiles[x][y+1]:getId() == neighborType then
					count = count + 1
				end
				
				-- 8 way
				if eight then
					if x-1 > -1 and y-1 > -1 and m.tiles[x-1][y-1]:getId() == neighborType then
						count = count + 1
					end
					if x+1 < m.width and y-1 > -1 and m.tiles[x+1][y-1]:getId() == neighborType then
						count = count + 1
					end
					if x-1 > -1 and y+1 < m.height and m.tiles[x-1][y+1]:getId() == neighborType then
						count = count + 1
					end
					if x+1 < m.width and y+1 < m.height and m.tiles[x+1][y+1]:getId() == neighborType then
						count = count + 1
					end
				end
				
				if count < minN or count > maxN then
					m.tiles[x][y]:setId(resetValue)
					retVal = retVal + 1
				end
			end
		end
	end
	
	return retVal
end

function MapGen:findConnectedComponents(minSize, maxSize, tileType)
	nodes = {}
	open = {}
	closed = {}
	components = {}
	local m = self.map
	
	-- all tiles of type tileType
	for x=0,m.width-1 do
		for y=0,m.height-1 do
			if m.tiles[x][y]:getId() == tileType then
				table.insert(nodes, Point:new(x,y))
			end
		end
	end
	
	-- find components
	cur = table.remove(nodes)
	while not(cur == nil) do
		comp = {}
		table.insert(comp, cur)
		self:getNeighbors(cur, nodes, open)
		
		-- consider all neighbors
		local size = 1
		cur = table.remove(open)
		while not(cur == nil) do
			table.insert(comp, cur)
			self:getNeighbors(cur, nodes, open)
			cur = table.remove(open)
			size = size + 1
		end
		
		-- ignore small/big components
		if size > minSize and size < maxSize then
			table.insert(components, comp)
		end
		
		cur = table.remove(nodes)
	end
	
	return components
end

-- get neighbors of tile from nodes
function MapGen:getNeighbors(p, nodes, neighbors)
	local m = self.map
	
	if p.x > 0 then
		consider(nodes, p.x-1, p.y, neighbors)
	end
	if p.x+1 < m.width then
		consider(nodes, p.x+1, p.y, neighbors)
	end
	if p.y > 0 then
		consider(nodes, p.x, p.y-1, neighbors)
	end
	if p.y+1 < m.height then
		consider(nodes, p.x, p.y+1, neighbors)
	end
end

-- find and remove tile[x,y] in nodes, add to neighbors
function consider(nodes, x, y, neighbors)
	for i,v in pairs(nodes) do
		if v.x == x and v.y == y then
			table.insert(neighbors, v)
			table.remove(nodes, i)			
			return
		end
	end
end

-- reset tiles belonging to components
function MapGen:removeComponents(comps, tileType)
	cur = table.remove(comps)
	while not(cur == nil) do
		for _,v in pairs(cur) do
			self.map.tiles[v.x][v.y]:setId(tileType)
		end
		cur = table.remove(comps)
	end
end

-- create water bodies using a depth map
-- p is the top left corner of the district
function MapGen:generateWater(w, h, p)
	local m = self.map
	--local w = m.width
	--local h = m.height
	
	local depth = nil
	-- high octave results in lower values, smoother distribution
	local octaves = 10
	local waterLevel = 35	-- tweak this to work with octaves
	local minCover = 0.05
	local maxCover = 0.1
	local count = 0
	
	local ratio = 1
	while ratio < minCover or ratio > maxCover do
		depth = generatePerlinNoise(octaves, w, h)	
		count = 0
		for x=0,w-1 do
			for y=0,h-1 do
				if depth[x][y] < waterLevel then
					count = count + 1
				end
			end
		end		
		ratio = count / (w*h)
	end
	
	for x=0,w-1 do
		for y=0,h-1 do
			if depth[x][y] < waterLevel then
				self:addCircleLake(x + p.x, y + p.y , 2)	-- "smooth" water bodies
			end
		end
	end
	
	
	-- remove useless land
	self:removeTiles("G", "W", "W", 0, 2, false)
	self:removeTiles("G", "W", "W", 0, 3, false)
	self:removeTiles("R", "W", "W", 0, 2, false)
	self:removeTiles("R", "W", "W", 0, 3, false)
end

-- place random buildings
function MapGen:generateBuildings()
	local m = self.map
	
	for i,d in pairs(m.districts) do
		for j,s in pairs(d.sectors) do
			--print("District "..i..", Sector "..j.."["..s.depthValue.."]: "..s.sectorType)
			s:placeBuildings(m)
		end
	end
end

-- load default map
function MapGen:defaultMap()
	-- load default map if it exists
	if io.open("map/defaultMap.txt", "r") then
		self.map = Map:new()
		self.map:initMap(100, 100)
		self.map:loadMap("map/defaultMap.txt")
		
		-- save info on each tile's neighbor
		for x=0,self.map.width-1 do
			for y=0,self.map.height-1 do
				self.map:getNeighborInfo(x,y)						
			end
		end
		
		self.map:drawMap()
	-- generate a random map
	else
		--self:newMap(100,100)
		self:randomMap(100, 100, 0)
	end
end

-- return map reference
function MapGen:getMap()
	self.map:addBoundary()
	return self.map
end

-- outline map with blocked tiles
function MapGen:roadBoundary()
	m = self.map
	maxy = self.height - 1
	maxx = self.width - 1
	
	-- top/bottom tiles
	for i=0,maxx do
		m.tiles[i][0]:setId("R")
		--index = m:index(i, maxy)
		m.tiles[i][maxy]:setId("R")
	end
	
	-- left/right tiles
	for i=0,maxy do
		--index = m:index(0,i)
		m.tiles[0][i]:setId("R")
		--index = m:index(maxx, i)
		m.tiles[maxx][i]:setId("R")
	end	

end

-- add rectangular lake
function MapGen:addLake(x, y, width, height)
	m = self.map
	
	for xi=0,width-1 do
		for yi=0,height-1 do
			--index = m:index(x+xi, y+yi)
			local xn = x + xi
			local yn = y + yi
			if (xn > -1) and (xn < m.width) and (yn > -1) and (yn < m.height) then
				m.tiles[x+xi][y+yi]:setId("W")
			end
		end
	end
end

-- add "circular" lake
function MapGen:addCircleLake(x, y, r)
	self:addLake(x-r, y-1, r*2 + 1, 3)		-- center block
	
	-- "circle"
	local n = r - 1
	for i=2,r do
		self:addLake(x - n, y - i, n*2 + 1, 1)
		self:addLake(x - n, y + i, n*2 + 1, 1)
		n = n - 1
	end
end

-- add road - only right angles
function MapGen:addRoad(x1, y1, x2, y2)
	m = self.map
	
	-- vertical
	if x1 == x2 then
		for y=y1,y2 do
			m.tiles[x1][y]:setId("R")
		end
	-- horizontal
	elseif y1 == y2 then		
		for x=x1,x2 do
			m.tiles[x][y1]:setId("R")
		end
	end
end

-- add building from predefined types
function MapGen:addBuilding(x, y, b_type)
	self.map:newBuilding(x, y, b_type)
end
