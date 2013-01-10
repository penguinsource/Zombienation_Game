Sector = {}

function Sector:new(xa, ya, xb, yb, d)
	local object = {
		x1 = xa,
		y1 = ya,
		x2 = xb,
		y2 = yb,
		sectorType = nil,
		divide = d,		-- orientation of bisector
		depthValue = nil,
		
		-- is this sector on a district boundary?
		boundN = false,
		boundE = false,
		boundS = false,
		boundW = false
	}
	setmetatable(object, { __index = Sector })
	return object
end

function Sector:yd()
	return self.y2 - self.y1
end
function Sector:xd()
	return self.x2 - self.x1
end
function Sector:area()
	return self:xd() * self:yd()
end

-- start as point
function getSectors(start, width, height)
	sectors = {}
	cycle = {}

	s = Sector:new(start.x , start.y , start.x + width, start.y + height, "H")
	table.insert(sectors, s)
	table.insert(cycle, s)
	
	local depth = 50
	local splitChance = 0.65

	for d=0,depth do
		cycle = {}	-- reset cycle
		for _,v in pairs(sectors) do
			if math.random() < splitChance then				
				a,b = v:split()
				if not(a == nil) then table.insert(cycle, a) end
				if not(b == nil) then table.insert(cycle, b) end				
			else
				table.insert(cycle, v)
			end
		end
		
		sectors = cycle
	end
	
	return sectors
end

function Sector:split()
	local a,b = nil,nil
	local xd, yd = self:xd(), self:yd()
	
	-- control splits
	local minLen = 10
	local minArea = 30
	
	-- sector size check
	if yd < minLen and xd > 2*yd then
		self.divide = "V"
	elseif xd < minLen and yd > 2*xd then
		self.divide = "H"
	elseif yd < minLen or xd < minLen or self:area() < minArea then
		return self, nil	
	end

	if self.divide == "H" then
		local partway = yd / 3
		local r = math.floor((math.random() * partway) + partway)
		if r < 3 then r = 3 end
		local boundY = self.y1 + r
		
		a = Sector:new(self.x1, self.y1, self.x2, boundY, "V")
		b = Sector:new(self.x1, boundY, self.x2, self.y2, "V")
	elseif self.divide == "V" then
		local partway = xd / 3
		local r = math.floor((math.random() * partway) + partway)
		if r < 3 then r = 3 end
		local boundX = self.x1 + r
		
		a = Sector:new(self.x1, self.y1, boundX, self.y2, "H")
		b = Sector:new(boundX, self.y1, self.x2, self.y2, "H")
	end
	
	return a,b
end

-- semi-randomness
function Sector:placeBuildings(map)
	if self.sectorType == "residential" then
		self:residential(map)
	elseif self.sectorType == "park" then
		self:park(map)
	elseif self.sectorType == "rural" then
		self:rural(map)
	elseif self.sectorType == "commercial" then
		self:commercial(map)
	end
end

-- residential sector
function Sector:residential(map)
	local r = math.random()
	local x1,y1,x2,y2 = self.x1, self.y1, self.x2, self.y2
		
	-- choose sector color
	local style = nil
	if math.random() < 0.5 then
		style = "2"
	end
		
	-- north road
	local yn = y1+1 -- building placement y 
	for x=x1+1,x2-1 do		
		if tileHere(map,x,y1,"R") and tileHere(map,x,yn,"G") then						
			if math.random() < 0.7 then
				if math.random() < 0.5 then
					map:newBuilding(x,yn,11,"N",style)
				elseif tileHere(map,x,yn+1,"G") then
					map:newBuilding(x,yn,12,"N",style)				
				end
			end
		end
	end
	-- west road
	local xn = x1+1
	for y=y1+1,y2-1 do		
		if tileHere(map,x1,y,"R") and tileHere(map,xn,y,"G") then
			if math.random() < 0.7 then
				if math.random() < 0.5 then
					map:newBuilding(xn,y,11,"W",style)
				elseif tileHere(map,xn+1,y,"G") then
					map:newBuilding(xn,y,21,"W",style)					
				end
			end
		end
	end
	-- south road
	local yn = y2-1
	for x=x1+1,x2-1 do		
		if tileHere(map,x,y2,"R") and tileHere(map,x,yn,"G") then
			if math.random() < 0.7 then
				if math.random() < 0.5 then
					map:newBuilding(x,yn,11,"S",style)
				elseif tileHere(map,x,yn-1,"G") then
					map:newBuilding(x,yn-1,12,"S",style)
				end
			end
		end
	end
	-- east road
	local xn = x2-1
	for y=y1+1,y2-1 do
		if tileHere(map,x2,y,"R") and tileHere(map,xn,y,"G") then
			if math.random() < 0.7 then
				if math.random() < 0.5 then
					map:newBuilding(xn,y,11,"E",style)
				elseif tileHere(map,xn-1,y,"G") then
					map:newBuilding(xn-1,y,21,"E",style)
				end
			end
		end
	end
end

-- place commercial buildings
function Sector:commercial(map)
	local x1,y1,x2,y2 = self.x1, self.y1, self.x2, self.y2
	
	-- setup roads around commerical sectors (or find another fix becasue right now most commercialal sectors are in the middle of a huge field)
	for x=x1, x2 do
		if not(self.boundN) then map.tiles[x][y1]:setId("R") end
		if not(self.boundS) then map.tiles[x][y2]:setId("R") end
	end
	for y=y1, y2 do
		if not(self.boundW) then map.tiles[x1][y]:setId("R") end
		if not(self.boundE) then map.tiles[x2][y]:setId("R") end
	end
	
	-- check road islands
	if self:roadIsland(map,x1,y1,x2,y2) then 
		print("--road island detected at "..x1..","..y1)
		-- randomize start of the road
		local startX = 0
		local startY = 0
		local dirX = 0
		local dirY = 0
		if math.random() < 0.5 then
			startX = math.random(x1,x2)
			if math.random() < 0.5 then 
				startY = y1 
				dirY = -1 
			else 
				startY = y2 
				dirY = 1 
			end
		else
			startY = math.random(y1,y2)
			if math.random() < 0.5 then 
				startX = 
				x1 dirX = -1
			else 
				startX = x2 
				dirX = 1 
			end
		end
		
		-- shoot a road out until it hits another road
		local xx = startX+dirX local yy = startY+dirY
		while(not(map.tiles[xx][yy].id == "R")) do
			--print("tracing: "..xx..","..yy)
			map.tiles[xx][yy]:setId("R")
			xx = xx + dirX
			yy = yy + dirY
		end
	end
	
	-- place buildings along north and south edges
	for x=x1+1, x2-1 do
	------NORTH
		local bType = math.random(1,4)
		-- 2x2 buildings
		if (bType == 4) then
			if not(self:areaClear(map,x,y1+1,x+1,y1+2)) then
				bType = math.random(1,3)						-- try smaller size
			else
				local bRand = math.random(1,4)
				map.tiles[x][y1+1]:setId("D")
				map.tiles[x][y1+1].img = b2x2[bRand]
				map.tiles[x][y1+1].sprite = love.graphics.newQuad(0,0, map.tileSize*2, map.tileSize*2, b2x2[bRand]:getWidth(), b2x2[bRand]:getHeight())
				map.tiles[x][y1+2]:setId("D")	map.tiles[x][y1+2]:setDraw(false)
				map.tiles[x+1][y1+1]:setId("D")	map.tiles[x+1][y1+1]:setDraw(false)
				map.tiles[x+1][y1+2]:setId("D")	map.tiles[x+1][y1+2]:setDraw(false)
			end
		end
		--2x1 buildings
		if (bType == 3) then
			if not self:areaClear(map,x,y1+1,x+1,y1+1) then
				bType = math.random(1,2)						-- try smaller size
			else
				local bRand = math.random(1,6)
				map.tiles[x][y1+1]:setId("D")
				map.tiles[x][y1+1].img = b2x1[bRand]
				map.tiles[x][y1+1].sprite = love.graphics.newQuad(0,0, map.tileSize*2, map.tileSize, b2x1[bRand]:getWidth(), b2x1[bRand]:getHeight())
				map.tiles[x+1][y1+1]:setId("D")	map.tiles[x+1][y1+1]:setDraw(false)
			end
		end
		--1x2 buildings
		if (bType == 2) then
			if not self:areaClear(map,x,y1+1,x,y1+2) then
				bType = 1										-- try smaller size
			else
				local bRand = math.random(1,6)
				map.tiles[x][y1+1]:setId("D")
				map.tiles[x][y1+1].img = b1x2[bRand]
				map.tiles[x][y1+1].sprite = love.graphics.newQuad(0,0, map.tileSize, map.tileSize*2, b1x2[bRand]:getWidth(), b1x2[bRand]:getHeight())
				map.tiles[x][y1+2]:setId("D")	map.tiles[x][y1+2]:setDraw(false)
			end
		end
		--1x1 buildings
		if (bType == 1) and self:areaClear(map,x,y1+1,x,y1+1) then
			local bRand = math.random(1,20)
			map.tiles[x][y1+1]:setId("D")
			map.tiles[x][y1+1].img = b1x1[bRand]
			map.tiles[x][y1+1].sprite = love.graphics.newQuad(0,0, map.tileSize, map.tileSize, b1x1[bRand]:getWidth(), b1x1[bRand]:getHeight())
		end
		
		
		--SOUTH
		bType = math.random(1,4)
		-- 2x2 buildings
		if (bType == 4) then
			if not(self:areaClear(map,x,y2-2,x+1,y2-1)) then
				bType =math.random(1,3)						-- try smaller size
			else
				local bRand = math.random(1,4)
				map.tiles[x][y2-2]:setId("D")
				map.tiles[x][y2-2].img = b2x2[bRand]
				map.tiles[x][y2-2].sprite = love.graphics.newQuad(0,0, map.tileSize*2, map.tileSize*2, b2x2[bRand]:getWidth(), b2x2[bRand]:getHeight())
				map.tiles[x][y2-1]:setId("D")	map.tiles[x][y2-1]:setDraw(false)
				map.tiles[x+1][y2-2]:setId("D")	map.tiles[x+1][y2-2]:setDraw(false)
				map.tiles[x+1][y2-1]:setId("D")	map.tiles[x+1][y2-1]:setDraw(false)
			end
		end
		--2x1 buildings
		if (bType == 3) then
			if not self:areaClear(map,x,y2-1,x+1,y2-1) then
				bType = math.random(1,2)						-- try smaller size
			else
				local bRand = math.random(1,6)
				map.tiles[x][y2-1]:setId("D")
				map.tiles[x][y2-1].img = b2x1[bRand]
				map.tiles[x][y2-1].sprite = love.graphics.newQuad(0,0, map.tileSize*2, map.tileSize, b2x1[bRand]:getWidth(), b2x1[bRand]:getHeight())
				map.tiles[x+1][y2-1]:setId("D")	map.tiles[x+1][y2-1]:setDraw(false)
			end
		end
		--1x2 buildings
		if (bType == 2) then
			if not self:areaClear(map,x,y2-2,x,y2-1) then
				bType = 1										-- try smaller size
			else
				local bRand = math.random(1,6)
				map.tiles[x][y2-2]:setId("D")
				map.tiles[x][y2-2].img = b1x2[bRand]
				map.tiles[x][y2-2].sprite = love.graphics.newQuad(0,0, map.tileSize, map.tileSize*2, b1x2[bRand]:getWidth(), b1x2[bRand]:getHeight())
				map.tiles[x][y2-1]:setId("D")	map.tiles[x][y2-1]:setDraw(false)
			end
		end
		if (bType == 1) then
			local bRand = math.random(1,20)
			map.tiles[x][y2-1]:setId("D")
			map.tiles[x][y2-1]:resetImg()
			map.tiles[x][y2-1].img = b1x1[bRand]
			map.tiles[x][y2-1].sprite = love.graphics.newQuad(0,0, map.tileSize, map.tileSize, b1x1[bRand]:getWidth(), b1x1[bRand]:getHeight())
		end
	end
	
	-- place buildings along east and west
	for y=y1+1, y2-1 do
	------WEST
		local bType = math.random(1,4)
		-- 2x2 buildings
		if (bType == 4) then
			if not(self:areaClear(map,x1+1,y,x1+2,y+1)) then
				bType =math.random(1,3)						-- try smaller size
			else
				local bRand = math.random(1,4)
				map.tiles[x1+1][y]:setId("D")
				map.tiles[x1+1][y].img = b2x2[bRand]
				map.tiles[x1+1][y].sprite = love.graphics.newQuad(0,0, map.tileSize*2, map.tileSize*2, b2x2[bRand]:getWidth(), b2x2[bRand]:getHeight())
				map.tiles[x1+1][y+1]:setId("D")	map.tiles[x1+1][y+1]:setDraw(false)
				map.tiles[x1+2][y]:setId("D")	map.tiles[x1+2][y]:setDraw(false)
				map.tiles[x1+2][y+1]:setId("D")	map.tiles[x1+2][y+1]:setDraw(false)
			end
		end
		--2x1 buildings
		if (bType == 3) then
			if not self:areaClear(map,x1+1,y,x1+2,y) then
				bType = math.random(1,2)						-- try smaller size
			else
				local bRand = math.random(1,6)
				map.tiles[x1+1][y]:setId("D")
				map.tiles[x1+1][y].img = b2x1[bRand]
				map.tiles[x1+1][y].sprite = love.graphics.newQuad(0,0, map.tileSize*2, map.tileSize, b2x1[bRand]:getWidth(), b2x1[bRand]:getHeight())
				map.tiles[x1+2][y]:setId("D")	map.tiles[x1+2][y]:setDraw(false)
			end
		end
		--1x2 buildings
		if (bType == 2) then
			if not self:areaClear(map,x1+1,y,x1+1,y+1) then
				bType = 1										-- try smaller size
			else
				local bRand = math.random(1,6)
				map.tiles[x1+1][y]:setId("D")
				map.tiles[x1+1][y].img = b1x2[bRand]
				map.tiles[x1+1][y].sprite = love.graphics.newQuad(0,0, map.tileSize, map.tileSize*2, b1x2[bRand]:getWidth(), b1x2[bRand]:getHeight())
				map.tiles[x1+1][y+1]:setId("D")	map.tiles[x1+1][y+1]:setDraw(false)
			end
		end
		--1x1 buildings
		if (bType == 1) and self:areaClear(map,x1+1,y,x1+1,y) then
			local bRand = math.random(1,20)
			map.tiles[x1+1][y]:setId("D")
			map.tiles[x1+1][y].img = b1x1[bRand]
			map.tiles[x1+1][y].sprite = love.graphics.newQuad(0,0, map.tileSize, map.tileSize, b1x1[bRand]:getWidth(), b1x1[bRand]:getHeight())
		end
		
	----EAST
		local bType = math.random(1,4)
		-- 2x2 buildings
		if (bType == 4) then
			if not(self:areaClear(map,x2-2,y,x2-1,y+1)) then
				bType =math.random(1,3)						-- try smaller size
			else
				local bRand = math.random(1,4)
				map.tiles[x2-2][y]:setId("D")
				map.tiles[x2-2][y].img = b2x2[bRand]
				map.tiles[x2-2][y].sprite = love.graphics.newQuad(0,0, map.tileSize*2, map.tileSize*2, b2x2[bRand]:getWidth(), b2x2[bRand]:getHeight())
				map.tiles[x2-2][y+1]:setId("D")	map.tiles[x2-2][y+1]:setDraw(false)
				map.tiles[x2-1][y]:setId("D")	map.tiles[x2-1][y]:setDraw(false)
				map.tiles[x2-1][y+1]:setId("D")	map.tiles[x2-1][y+1]:setDraw(false)
			end
		end
		--2x1 buildings
		if (bType == 3) then
			if not self:areaClear(map,x2-2,y,x2-1,y) then
				bType = math.random(1,2)						-- try smaller size
			else
				local bRand = math.random(1,6)
				map.tiles[x2-2][y]:setId("D")
				map.tiles[x2-2][y].img = b2x1[bRand]
				map.tiles[x2-2][y].sprite = love.graphics.newQuad(0,0, map.tileSize*2, map.tileSize, b2x1[bRand]:getWidth(), b2x1[bRand]:getHeight())
				map.tiles[x2-1][y]:setId("D")	map.tiles[x2-1][y]:setDraw(false)
			end
		end
		--1x2 buildings
		if (bType == 2) then
			if not self:areaClear(map,x2-1,y,x2-1,y+1) then
				bType = 1										-- try smaller size
			else
				local bRand = math.random(1,6)
				map.tiles[x2-1][y]:setId("D")
				map.tiles[x2-1][y].img = b1x2[bRand]
				map.tiles[x2-1][y].sprite = love.graphics.newQuad(0,0, map.tileSize, map.tileSize*2, b1x2[bRand]:getWidth(), b1x2[bRand]:getHeight())
				map.tiles[x2-1][y+1]:setId("D")	map.tiles[x2-1][y+1]:setDraw(false)
			end
		end
		--1x1 buildings
		if (bType == 1) and self:areaClear(map,x2-1,y,x2-1,y) then
			local bRand = math.random(1,20)
			map.tiles[x2-1][y]:setId("D")
			map.tiles[x2-1][y].img = b1x1[bRand]
			map.tiles[x2-1][y].sprite = love.graphics.newQuad(0,0, map.tileSize, map.tileSize, b1x1[bRand]:getWidth(), b1x1[bRand]:getHeight())
		end
	end
	
	-- put cement tile on any blocks not occupied
	for x=x1+1, x2-1 do
		for y=y1+1, y2-1 do
			if not (map.tiles[x][y].id == "D") then
				map.tiles[x][y]:setId("D")
				map.tiles[x][y].img = cementImg
				map.tiles[x][y].sprite = love.graphics.newQuad(0,0, map.tileSize, map.tileSize, cementImg:getWidth(), cementImg:getHeight())
			end
		end
	end
end

-- place crops
function Sector:rural(map)
	-- self ref
	local x1,y1,x2,y2 = self.x1, self.y1, self.x2, self.y2
	
	-- kill small farmers
	if self:area() < 25 then
		self:park(map)
		return
	end
	
	local orientation = math.random(0,1)
	for x=x1+1, x2-1 do
		for y = y1+1, y2-1 do
			local i = 8
			if (x == x1+1) then i = 0 end 
			if (x == x2-1) then i = 2 end 
			if (y == y1+1) then i = 1 end 
			if (y == y2-1) then i = 3 end 
			if (x == x1+1) and (y == y1+1) then i = 4 end 
			if (x == x2-1) and (y == y1+1) then i = 5 end 
			if (x == x2-1) and (y == y2-1) then i = 6 end 
			if (x == x1+1) and (y == y2-1) then i = 7 end 	
			
			map:newFarm(x,y,orientation, i)
		end
	end
end

-- place a park
function Sector:park(map)
	--[[ no tiny parks
	if self:xd() < 6 or self:yd() < 6 or self:area() < 50 then
		return
	end
	--]]
	-- self ref
	local x1,y1,x2,y2 = self.x1, self.y1, self.x2, self.y2
	
	-- local vars
	local xmid = x1 + math.floor(self:xd() / 2) + 1
	local ymid = y1 + math.floor(self:yd() / 2) + 1	
	local dir,style = nil,nil
	
	-- detect roads
	local N,W,E,S = true, true, true, true
	-- north/south side
	for xi=x1,x2 do
		if not(tileHere(map,xi,y1,"R")) then 
			N = false 
		end
		if not(tileHere(map,xi,y2,"R")) then 
			S = false 
		end
	end
	-- east/west side
	for yi=y1,y2 do
		if not(tileHere(map,x1,yi,"R")) then 
			W = false 
		end
		if not(tileHere(map,x2,yi,"R")) then
			E = false
		end
	end
	
	-- no roads means no park
	if not(N) and not(S) and not(W) and not(E) then 
		return 
	end
	
	-- change sector into grass
	self:fillWithGrass(map)
	
	-- north side
	local yn = y1+1 -- building placement y 
	for x=x1+1,x2-1 do		
		--if tileHere(map,x,yn,"G") then						
			if gapSide == 0 then
				if not(x == xmid) then
					--map:newBuilding(x,yn,11,dir,style)
					map:newFence(x,yn)
				end
			else
				--map:newBuilding(x,yn,11,dir,style)
				map:newFence(x,yn)
			end
		--end
	end
	-- west road
	local xn = x1+1
	for y=y1+1,y2-1 do		
		--if tileHere(map,xn,y,"G") then
			if gapSide == 1 then
				if not(y == ymid) then
					--map:newBuilding(xn,y,11,dir,style)
					map:newFence(xn,y)
				end
			else
				--map:newBuilding(xn,y,11,dir,style)
				map:newFence(xn,y)
			end
		--end
	end
	-- south road
	local yn = y2-1
	for x=x1+1,x2-1 do		
		--if tileHere(map,x,yn,"G") then
			if gapSide == 2 then
				if not(x == xmid) then
					--map:newBuilding(x,yn,11,dir,style)
					map:newFence(x,yn)
				end
			else 
				--map:newBuilding(x,yn,11,dir,style)
				map:newFence(x,yn)
			end
		--end
	end
	-- east road
	local xn = x2-1
	for y=y1+1,y2-1 do
		--if tileHere(map,xn,y,"G") then
			if gapSide == 3 then
				if not(y == ymid) then
					--map:newBuilding(xn,y,11,dir,style)
					map:newFence(xn,y)
				end
			else
				--map:newBuilding(xn,y,11,dir,style)
				map:newFence(xn,y)
			end
		--end
	end	
end

function Sector:fillWithGrass(map)
	for x=self.x1+1,self.x2-1 do
		for y=self.y1+1,self.y2-1 do
			map.tiles[x][y]:setId("G")
		end
	end
end

function tileHere(map,x,y,t)
	return map.tiles[x][y]:getId() == t
end

-- returns true if are from x1,y1 to x2,y2 is clear
function Sector:areaClear(map,x1,y1,x2,y2)
	for xx = x1, x2 do
		for yy = y1, y2 do
			if (map.tiles[xx][yy].id == "R") or (map.tiles[xx][yy].id == "D") then
				return false
			end
		end
	end
	
	return true
end

function Sector:roadIsland(map, x1,y1,x2,y2)
	for x = x1-1, x2+1 do
		if (x > -1) and (x < map.width) and (y1-1 > -1) and (y1-1 < map.height) and (map.tiles[x][y1-1].id == "R") then return false end
		if (x > -1) and (x < map.width) and (y2+1 > -1) and (y2+1 < map.height) and (map.tiles[x][y2+1].id == "R") then return false end
	end
	
	for y = y1-1, y2+1 do
		if (x1-1 > -1) and (x1-1 < map.width) and (y > -1) and (y < map.height) and (map.tiles[x1-1][y].id == "R") then return false end
		if (x2+1 > -1) and (x2+1 < map.width) and (y > -1) and (y < map.height) and (map.tiles[x2+1][y].id == "R") then return false end
	end
	
	return true
end

function outputSectors(sectors)
	io.output("sectors.txt")
	
	for _,v in pairs(sectors) do
		io.write("["..v.x1..","..v.y1.."]-["..v.x2..","..v.y2.."]")
		io.write("\n")
	end
end




