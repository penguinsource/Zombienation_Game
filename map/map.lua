Map = {}

-- tile images
road = love.graphics.newImage("map/roadSprites.png")
grass = love.graphics.newImage("map/grassSprites.png")
water = love.graphics.newImage("map/waterSprites.png")
fence = love.graphics.newImage("map/tree tile.png")
blocked = love.graphics.newImage("map/blocked.png")
roadMM = love.graphics.newImage("map/roadMM.png")
grassMM = love.graphics.newImage("map/grassMM.png")
waterMM = love.graphics.newImage("map/waterMM.png")
fenceMM = love.graphics.newImage("map/fenceMM.png")
blockedMM = love.graphics.newImage("map/blockedMM.png")
farmMM = love.graphics.newImage("map/farmMM.png")

farm1 = love.graphics.newImage("map/farm1.png")

function Map:new()
	local object = {
		width = 0,
		height = 0,
		tileSize = 0,
		tiles = {},
		buildings = {},
		districts = {},
		baseTilePt = nil,
		storeTilePt = nil,
		canvas = 0,
		minimap = nil,
		bloodImg = love.graphics.newImage("Map/blood1.png")
	}
	setmetatable(object, { __index = Map })
	return object
end

-- create new w*h map of all grass tiles
function Map:initMap(w,h)
	self.width = w
	self.height = h
	self.tileSize = 54 -- default pixel square size
	self.canvas = love.graphics.newCanvas(self.width*self.tileSize, self.height*self.tileSize)
	--[[for i=0, (w * h - 1) do
		self.tiles[i] = Tile:new()
	end]]--
	self.tiles[-1] = {}
	self.tiles[w] = {}
	for i=0, w-1 do
		self.tiles[i] = {}
		for j=0, h-1 do
			self.tiles[i][j] = Tile:new("", self.tileSize)
			self.tiles[i][j]:setId("G")
		end
	end
end

function Map:setMinimap(mm)
	self.minimap = mm
end

-- load map from file
function Map:loadMap(filename)	
	io.input(filename)	
	data = io.read("*all")
	x = 0
	y = 0
	for c in data:gmatch"%u" do -- match all upper case chars
		self.tiles[x][y]:setId(c)
		
		x = x + 1	
		if x == self.width then
			x = 0
			y = y + 1
		end
	end
	
	-- find map buildings
	--self:detectBuildings()														** COMMENTED OUT
end

-- save map to file
function Map:saveMap(filename)
	io.output(filename)
	for y=0,self.height-1 do
		for x=0,self.width-1 do
			io.write(self.tiles[x][y]:getId())
		end
		io.write("\n")
	end
end	

-- draw map to canvas
function Map:drawMap()
	love.graphics.reset()

	self.canvas:clear()	
	
	local w = self.tileSize
	
	local NEcorner = love.graphics.newQuad(0, 16*w, w, w, w*16, w*20)
	local SEcorner = love.graphics.newQuad(0, 17*w, w, w, w*16, w*20)
	local SWcorner = love.graphics.newQuad(0, 18*w, w, w, w*16, w*20)
	local NWcorner = love.graphics.newQuad(0, 19*w, w, w, w*16, w*20)
		
	for x=0,self.width-1 do
		for y=0,self.height-1 do
			xb = x * self.tileSize
			yb = y * self.tileSize

			tile = self.tiles[x][y]
			
			if tile.draw then				
				love.graphics.setCanvas(self.canvas)
					love.graphics.drawq(tile:getImg(), tile.sprite, xb, yb)
					if (tile.id == "W") then
						if tile.NE then love.graphics.drawq(tile:getImg(), NEcorner, xb, yb) end
						if tile.SE then love.graphics.drawq(tile:getImg(), SEcorner, xb, yb) end
						if tile.SW then love.graphics.drawq(tile:getImg(), SWcorner, xb, yb) end
						if tile.NW then love.graphics.drawq(tile:getImg(), NWcorner, xb, yb) end
					end
				love.graphics.setCanvas()
			end
		end
	end
end

function Map:draw()
	love.graphics.draw(self.canvas, 0,0)
end

function Map:drawBlood(bx, by, angle)
	love.graphics.setCanvas(self.canvas)
		love.graphics.draw(self.bloodImg, bx, by, angle*math.pi/180, 1,1, self.bloodImg:getWidth()/2, self.bloodImg:getHeight()/2)
	love.graphics.setCanvas()
end

-- tile index
function Map:index(x,y)
	return (y * self.width) + x
end

function Map:updateTileInfo(x,y)
	self:getNeighborInfo(x,y)
	self:getNeighborInfo(x,y-1)
	self:getNeighborInfo(x+1,y-1)
	self:getNeighborInfo(x+1,y)
	self:getNeighborInfo(x+1,y+1)
	self:getNeighborInfo(x,y+1)
	self:getNeighborInfo(x-1,y+1)
	self:getNeighborInfo(x-1,y)
	self:getNeighborInfo(x-1,y-1)	
	--self:drawMap()
end

function Map:getNeighborInfo(x,y)
	if (x < 0) or (y < 0) or (x > self.width-1) or (y > self.height-1) then return end
	xb = x * self.tileSize
	yb = y * self.tileSize
	
	if not(self.minimap == nil) then self.minimap:updateCanvas(x,y) end
	
	--index = self:index(x,y)
	tile = self.tiles[x][y]
	
	-- reset corner flags
	tile.NE = false
	tile.SE = false
	tile.SW = false
	tile.NW = false
	
	-- check bounds and set each neighbor to 1 if it is the same tile
	if (y-1 > -1) then
		--tileN  = self.tiles[self:index(x,y-1)]
		tileN  = self.tiles[x][y-1]
		N = (tile.id == tileN.id) and 1 or 0
	else N = 0 end
	if ((x+1 < self.width) and (y-1 > -1)) then
		--tileNE  = self.tiles[self:index(x+1,y-1)]
		tileNE  = self.tiles[x+1][y-1]
		NE = (tile.id == tileNE.id) and 1 or 0
	else NE = 0 end
	if (x+1 < self.width) then
		--tileE  = self.tiles[self:index(x+1,y)]
		tileE  = self.tiles[x+1][y]
		E = (tile.id == tileE.id) and 1 or 0
	else E = 0 end
	if ((x+1 < self.width) and (y+1 < self.height)) then
		--tileSE  = self.tiles[self:index(x+1,y+1)]
		tileSE  = self.tiles[x+1][y+1]
		SE = (tile.id == tileSE.id) and 1 or 0
	else SE = 0 end
	if (y+1 < self.height) then
		--tileS  = self.tiles[self:index(x,y+1)]
		tileS  = self.tiles[x][y+1]
		S = (tile.id == tileS.id) and 1 or 0
	else S = 0 end
	if ((x-1 > -1) and (y+1 < self.height)) then
		--tileSW  = self.tiles[self:index(x-1,y+1)]
		tileSW  = self.tiles[x-1][y+1]
		SW = (tile.id == tileSW.id) and 1 or 0
	else SW = 0 end
	if (x-1 > -1) then
		--tileW  = self.tiles[self:index(x-1,y)]
		tileW  = self.tiles[x-1][y]
		W = (tile.id == tileW.id) and 1 or 0
	else W = 0 end
	if ((x-1 > -1) and (y-1 > -1)) then
		--tileNW  = self.tiles[self:index(x-1,y-1)]
		tileNW  = self.tiles[x-1][y-1]
		NW = (tile.id == tileNW.id) and 1 or 0
	else NW = 0 end
		
	if (tile.id == "R") then
		self:selectRoadSprite(tile)
	elseif (tile.id == "W") then
		self:selectWaterSprite(tile)	
	elseif (tile.id == "G") then
		self:selectGroundSprite(tile)
	elseif (tile.id == "D") then	-- builDing tile
		self:selectBuildingSprite(tile, x, y)
	elseif (tile.id == "P") then	-- fence tile (p for park, f might be for farm)
		self:selectFenceSprite(tile)	
	end
	
	--self.canvas:renderTo(function()
	love.graphics.setCanvas(self.canvas)
		love.graphics.drawq(tile.img, tile.sprite, xb, yb)
		if (tile.id == "W") then
			local w = self.tileSize
			local NEcorner = love.graphics.newQuad(0, 16*w, w, w, w*16, w*20)
			local SEcorner = love.graphics.newQuad(0, 17*w, w, w, w*16, w*20)
			local SWcorner = love.graphics.newQuad(0, 18*w, w, w, w*16, w*20)
			local NWcorner = love.graphics.newQuad(0, 19*w, w, w, w*16, w*20)
			if tile.NE then love.graphics.drawq(tile:getImg(), NEcorner, xb, yb) end
			if tile.SE then love.graphics.drawq(tile:getImg(), SEcorner, xb, yb) end
			if tile.SW then love.graphics.drawq(tile:getImg(), SWcorner, xb, yb) end
			if tile.NW then love.graphics.drawq(tile:getImg(), NWcorner, xb, yb) end
		end
	love.graphics.setCanvas()
	--end)
end


function Map:selectRoadSprite(tile)
	local w = self.tileSize
	spritei = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}

	-- eliminate sprites based on neighbor info
	if (N == 1) then
		spritei[2], spritei[3], spritei[4], spritei[7], spritei[8], spritei[10], spritei[13], spritei[16] = 0,0,0,0,0,0,0,0 else 
		spritei[1], spritei[5], spritei[6], spritei[9], spritei[11], spritei[12], spritei[14], spritei[15] = 0,0,0,0,0,0,0,0 end
	if (E == 1) then
		spritei[1], spritei[4], spritei[5], spritei[7], spritei[8], spritei[9], spritei[14], spritei[16] = 0,0,0,0,0,0,0,0 else
		spritei[2], spritei[3], spritei[6], spritei[10], spritei[11], spritei[12], spritei[13], spritei[15] = 0,0,0,0,0,0,0,0 end
	if (S == 1) then
		spritei[2], spritei[5], spritei[6], spritei[8], spritei[9], spritei[10], spritei[11], spritei[16] = 0,0,0,0,0,0,0,0 else
		spritei[1], spritei[3], spritei[4], spritei[7], spritei[12], spritei[13], spritei[14], spritei[15] = 0,0,0,0,0,0,0,0 end
	if (W == 1) then
		spritei[1], spritei[3], spritei[6], spritei[7], spritei[9], spritei[10], spritei[12], spritei[16] = 0,0,0,0,0,0,0,0 else
		spritei[2], spritei[4], spritei[5], spritei[8], spritei[11], spritei[13], spritei[14], spritei[15] = 0,0,0,0,0,0,0,0 end
		
	local i = self:findi(spritei)
	
	local j = 0
	
	-- check for horiz and vert double roads
	if (i == 11) then
		if (NE == 1) and (NW == 1) then
			i = 2
			j = 2
		elseif (NE == 0) and (NW == 1) then
			j = 1
		elseif (NE == 1) and (NW == 0) then
			j = 2
		end
	end
	if (i == 12) then
		if (NE == 1) and (SE == 1) then
			i = 1
			j = 1
		elseif (NE == 1) and (SE == 0) then
			j = 1
		elseif (NE == 0) and (SE == 1) then
			j = 2
		end
	end
	if (i == 13) then
		if (SE == 1) and (SW == 1) then
			i = 2
			j = 1
		elseif (SE == 1) and (SW == 0) then
			j = 1
		elseif (SE == 0) and (SW == 1) then
			j = 2
		end
	end
	if (i == 14) then
		if (NW == 1) and (SW == 1) then
			i = 1
			j = 2
		elseif (NW == 0) and (SW == 1) then
			j = 1
		elseif (NW == 1) and (SW == 0) then
			j = 2
		end
	end
	
	-- check for curved double roads
	if (i == 3) and (SE == 1) then j = 1 end
	if (i == 4) and (SW == 1) then j = 1 end
	if (i == 5) and (NW == 1) then j = 1 end
	if (i == 6) and (NE == 1) then j = 1 end		
	
	-- check for 4way double roads
	if (i == 15) then
		if (NE == 1) and (SE == 1) then j = 1 end
		if (NW == 1) and (SW == 1) then j = 2 end
		if (SE == 1) and (SW == 1) then j,i = 1,16 end
		if (NE == 1) and (NW == 1) then j,i = 2,16 end
		
		if (NE == 1) and (SE == 1) and (SW == 1) and (NW == 0) then i,j = 9,1 end
		if (NE == 0) and (SE == 1) and (SW == 1) and (NW == 1) then i,j = 9,2 end
		if (NE == 1) and (SE == 1) and (SW == 0) and (NW == 1) then i,j = 10,1 end
		if (NE == 1) and (SE == 0) and (SW == 1) and (NW == 1) then i,j = 10,2 end
	end
	
	tile.sprite = love.graphics.newQuad((i-1)*w, j*w, w, w, tile:getImg():getWidth(), tile:getImg():getHeight())
end

function Map:selectWaterSprite(tile)
	local w = self.tileSize
	spritei = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}

	-- eliminate sprites based on neighbor info
	if (N == 1) then
		spritei[1], spritei[5], spritei[4], spritei[11], spritei[3], spritei[7], spritei[10], spritei[14] = 0,0,0,0,0,0,0,0 else 
		spritei[2], spritei[9], spritei[6], spritei[15], spritei[8], spritei[12], spritei[13], spritei[16] = 0,0,0,0,0,0,0,0 end
	if (E == 1) then
		spritei[1], spritei[5], spritei[4], spritei[11], spritei[2], spritei[9], spritei[6], spritei[15] = 0,0,0,0,0,0,0,0 else
		spritei[3], spritei[7], spritei[10], spritei[14], spritei[8], spritei[12], spritei[13], spritei[16] = 0,0,0,0,0,0,0,0 end
	if (S == 1) then
		spritei[1], spritei[5], spritei[3], spritei[7], spritei[2], spritei[9], spritei[8], spritei[12] = 0,0,0,0,0,0,0,0 else
		spritei[4], spritei[11], spritei[10], spritei[14], spritei[6], spritei[15], spritei[13], spritei[16] = 0,0,0,0,0,0,0,0 end
	if (W == 1) then
		spritei[1], spritei[4], spritei[3], spritei[10], spritei[2], spritei[6], spritei[8], spritei[13] = 0,0,0,0,0,0,0,0 else
		spritei[5], spritei[11], spritei[7], spritei[14], spritei[9], spritei[15], spritei[12], spritei[16] = 0,0,0,0,0,0,0,0 end
	
	local i = self:findi(spritei)
		
	local j = 0
	if (i == 16) then
		j = math.random(0,15)
		if (NE == 0) then tile.NE = true end	
		if (SE == 0) then tile.SE = true end	
		if (SW == 0) then tile.SW = true end	
		if (NW == 0) then tile.NW = true end	
	end
	
	tile.sprite = love.graphics.newQuad(j*w, (i-1)*w, w, w, tile:getImg():getWidth(), tile:getImg():getHeight())
end

function Map:selectFenceSprite(tile)
	local w = self.tileSize
	--[[spritei = {1,1,1,1,1,1}

	-- eliminate sprites based on neighbor info
	if (N == 1) then
		spritei[2], spritei[3], spritei[4] = 0,0,0 else 
		spritei[5], spritei[6] = 0,0 end
	if (E == 1) then
		spritei[1], spritei[4], spritei[5] = 0,0,0 else
		spritei[3], spritei[6] = 0,0 end
	if (S == 1) then
		spritei[2], spritei[5], spritei[6] = 0,0,0 else
		spritei[3], spritei[4] = 0,0 end
	if (W == 1) then
		spritei[1], spritei[3], spritei[6] = 0,0,0 else
		spritei[4], spritei[5] = 0,0 end
	
	local i = self:findi(spritei)]]--
	
	--tile.sprite = love.graphics.newQuad((i-1)*w, 0, w, w, tile:getImg():getWidth(), tile:getImg():getHeight())
	tile.sprite = love.graphics.newQuad(0, 0, w, w, tile:getImg():getWidth(), tile:getImg():getHeight())
end

function Map:selectGroundSprite(tile)
	local w = self.tileSize

	i = math.random(0, tile:getImg():getWidth()/w - 1)
	--print(i)
	tile.sprite = love.graphics.newQuad(i*w, 0, w, w, tile:getImg():getWidth(), w)
end

-- find the correct sprite within building
function Map:selectBuildingSprite(tile, x, y)
	local building = self:findBuilding(x, y) 
	if not(building == nil) then
		tile.img = building.img
		tile.sprite = building:getSprite(x, y, self.tileSize)
	end
end

-- return building containing [x,y], else nil
function Map:findBuilding(x, y)
	for _,v in pairs(self.buildings) do
		if x >= v.x and x <= v.xend and y >= v.y and y <= v.yend then
			return v
		end
	end
	-- not found
	return nil
end

-- detect building placement in a pre-loaded map
function Map:detectBuildings()
	-- defining corners
	local topCorner = {}
	local bottomCorner = {}
	
	-- iterate over all tiles, find the building-defining corners
	for y=0,self.height-1 do
		for x=0,self.width-1 do
			-- is a building tile
			local id = self.tiles[x][y]:getId()
			if id == "D" then				
				-- neighbor tiles
				local N = (self.tiles[x][y-1]:getId() == id)
				local S = (self.tiles[x][y+1]:getId() == id)
				local W = (self.tiles[x-1][y]:getId() == id)
				local E = (self.tiles[x+1][y]:getId() == id)
				
				-- test corners
				if not(N) and not(W) and S and E then
					table.insert(topCorner, Point:new(x, y))
				elseif N and W and not(S) and not(E) then
					table.insert(bottomCorner, Point:new(x, y))
				end
			end
		end
	end
	
	-- create buildings based on the corners
	for i,v in pairs(topCorner) do
		-- get type
		local xd = bottomCorner[i].x - v.x + 1
		local yd = bottomCorner[i].y - v.y + 1
		
		local b_type = (xd * 10) + yd
	
		-- create building
		local building = Building:new()
		building:set(v.x, v.y, b_type)		
		table.insert(self.buildings, building)
	end
end

-- add building from here rather than MapGen
-- return success as boolean
function Map:newBuilding(x, y, b_type, dir, style)
	-- add building to list
	local b = Building:new(self.tileSize)
	b:set(x, y, b_type, dir, style)
	
	-- building out of bounds
	if (b.xend >= self.width) or (b.yend >= self.height) then
		return false
	end
	
	-- already a building here
	if not(self:findBuilding(b.x, b.y) == nil) or
		not(self:findBuilding(b.x, b.yend) == nil) or
		not(self:findBuilding(b.xend, b.y) == nil) or
		not(self:findBuilding(b.xend, b.yend) == nil) then
		
		return false
	end
	
	-- keep this building
	table.insert(self.buildings, b)
	
	-- set and update tiles
	for xi=x,b.xend do
		for yi=y,b.yend do
			self.tiles[xi][yi]:setId("D")
			self:updateTileInfo(xi, yi)
		end
	end
	
	-- success
	return true
end

function Map:newFence(x, y)
	self.tiles[x][y]:setId("P")
end

function Map:newFarm(x, y, o, i)
	local tile = self.tiles[x][y]
	w = self.tileSize
	tile:setId("F")
	tile.sprite = love.graphics.newQuad(i*w, o*w, w, w, tile:getImg():getWidth(), tile:getImg():getHeight())
end

function Map:addBoundary()
	local boundTile = Tile:new("X", self.tileSize)
	for i = -1, self.height do
		self.tiles[-1][i] = boundTile
		self.tiles[self.width][i] = boundTile
	end
	
	for i = -1, self.width do
		self.tiles[i][-1] = boundTile
		self.tiles[i][self.width] = boundTile
	end
end

function Map:findi(spritei)
	for i,v in ipairs(spritei) do
		if (v == 1) then return i end
	end
	print ("didn't find i")
	return 1
end

-- returns tile at x,y pixel coordinates
function Map:tileAt(x,y)
	return self.tiles[math.floor(x/self.tileSize)][math.floor(y/self.tileSize)]
end
