District = {}


function District:new(xa, ya, xb, yb, d)
	local object = {
		x1 = xa,
		y1 = ya,
		x2 = xb, 
		y2 = yb,
		
		sectors = {},
		depth = {},	-- depth map for assigning sector types
		
		divide = d, -- orientation of bisector
		
		sectorCount_residential = 0,
		sectorCount_commercial = 0,
		sectorCount_rural = 0,
		sectorCount_industrial = 0,
		sectorCount_park = 0,
		
		isBase = false
	}
	setmetatable(object, { __index = District })
	return object
end

-- district properties
function District:yd()
	return self.y2 - self.y1
end
function District:xd()
	return self.x2 - self.x1
end
function District:area()
	return self:yd() * self:xd()
end

-- split city into multiple districts
function getDistricts(width, height)
	districts = {}
	cycle = {}

	s = District:new(0,0, width-1, height-1, "H")
	table.insert(districts, s)
	table.insert(cycle, s)
	
	local depth = 3
	local splitChance = 0.85
	
	local minArea = (width * height) - 1

	for d=0,depth do
		cycle = {}	-- reset cycle
		for i,v in pairs(districts) do
			if math.random() < splitChance then
				a,b = v:split()				
				if not(a == nil) then 
					local aa = a:area()
					if aa < minArea then minArea = aa end
					table.insert(cycle, a) 
				end
				if not(b == nil) then 
					local ba = b:area()
					if ba < minArea then minArea = ba end
					table.insert(cycle, b) 
				end				
			else
				local va = v:area()
				if va < minArea then minArea = va end
				table.insert(cycle, v)
			end
		end

		districts = cycle
	end
	
	-- set baseDistrict
	for _,d in pairs(districts) do
		if d:area() == minArea then
			d.isBase = true
		end
	end
	
	return districts
end

-- split this district into 2
-- add one to bound for double road-age
-- 1/3 < bound < 2/3
function District:split()
	if self.divide == "H" then
		local partway = self:yd() / 3
		local boundY = self.y1 + math.floor((math.random() * partway) + partway)		
		a = District:new(self.x1, self.y1, self.x2, boundY, "V")
		b = District:new(self.x1, boundY+1, self.x2, self.y2, "V")
	else -- self.divide == "V"
		local partway = self:xd() / 3
		local boundX = self.x1 + math.floor((math.random() * partway) + partway)
		a = District:new(self.x1, self.y1, boundX, self.y2, "H")
		b = District:new(boundX+1, self.y1, self.x2, self.y2, "H")
	end
	
	return a,b
end

-- create sectors for this district
function District:createSectors(map)
	-- split into sectors
	self.sectors = getSectors(Point:new(self.x1, self.y1), self:xd(), self:yd())
	
	local id = 0
	-- assign sector types and check boundaries
	for _,v in pairs(self.sectors) do
	
		-- bound check
		if v.y1 == self.y1+1 then
			v.boundN = true
			if v.y1 == 0 then v.boundN = false end
		end
		if v.x1 == self.x1+1 then
			v.boundW = true
			if v.x1 == 0 then v.boundW = false end
		end
		if v.y2 == self.y2-1 then
			v.boundS = true
		end
		if v.x2 == self.x2-1 then
			v.boundE = true
		end
		
		self:setType(map, v, id)
		id = id + 1
		if id > 3 then id = 0 end		
	end
end

function District:setType(map, sector, id)
	--if id == 2 then
		--sector.sectorType = "residential"	
	if id == 2 or id == 3 then
		local qx = math.floor(map.width / 4)
		local qy = math.floor(map.height / 4)
		
		if sector.x1 < qx or sector.y1 < qy or 
			sector.x2 > (3*qx) or sector.y2 > (3*qy) then
			
			sector.sectorType = "residential"
		else
			sector.sectorType = "commercial"	 
		end
	elseif id == 0 then
		local qx = math.floor(map.width / 4)
		local qy = math.floor(map.height / 4)
		
		if sector.x1 == 0 or sector.y1 == 0 or
			sector.x2 == map.width-1 or sector.y2 == map.height-1 then
			
			sector.sectorType = "rural"
		else
			sector.sectorType = "residential"
		end
	elseif id == 1 then
		local qx = math.floor(map.width / 4)
		local qy = math.floor(map.height / 4)
		
		if sector.x1 < qx or sector.y1 < qy or 
			sector.x2 > (3*qx) or sector.y2 > (3*qy) then
			
			sector.sectorType = "park"
		else
			sector.sectorType = "commercial"	 
		end
	end	
end

-- use depth value to determine sector type
function District:getTypeFromDepth(depth)
	local numTypes = 5
	local depthDivisor = 100 / numTypes
	
	local val = math.floor((depth / depthDivisor) % numTypes)
	
	-- val frequency order ~= { 2, 3, 1, 4, 0 }
	
	if val == 2 then
		self.sectorCount_residential = self.sectorCount_residential + 1
		return "residential"		
	elseif val == 3 then
		self.sectorCount_commercial = self.sectorCount_commercial + 1
		return "commercial"
	elseif val == 4 then
		self.sectorCount_rural = self.sectorCount_rural + 1
		return "rural"
	elseif val == 1 then
		self.sectorCount_park = self.sectorCount_park + 1
		return "park"
	elseif val == 0 then
		if math.random() > 0.5 then
			self.sectorCount_residential = self.sectorCount_residential + 1
			return "residential"
		else
			self.sectorCount_commercial = self.sectorCount_commercial + 1
			return "commercial"
		end
	else
		return "undefined"
	end
end


