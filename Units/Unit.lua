Unit = {}
Unit_mt = { __index = Unit }

--[[ 
d
	unit info .. 
	no enumerations in lua so.. 
	unitTypes:
		zombie = 0
		civilian = 1
		armedCivilian = 2
		etc ?
]]--

-- Constructor
function Unit:new()
    -- define our parameters here
    local new_object = {
    x = 0,
    y = 0,
	--radius = 5,
    width = 0,
    height = 0,
    xSpeed = 0,
    ySpeed = 0,
    state = "",
    normalSpeed = 0,
    runSpeed = 0,
	path = nil
	--selected = true
    }
    setmetatable(new_object, Unit_mt )
    return new_object
end

function Unit:calcShortestDirection(angle, targetAngle)
		local dirVec = -1
		local newAngle = 180 + angle		-- current angle + 180 degrees
		-- if newAngle is < 360
		if newAngle < 360 then
			if (targetAngle < newAngle) and (targetAngle > angle) then
				dirVec = 0
			else
				dirVec = 1
			end
		else	-- if newAngle is > 360
			newAngle = newAngle - 360
			if (targetAngle > newAngle) and (targetAngle < angle) then
				dirVec = 1
			else
				dirVec = 0
			end
		end
		return dirVec
end

function Unit:getDirection(angle, unitSpeed)				-- returns a point (x and y) given an angle
    
	dvector = Point:new()
	local angle_rad = self.angle * (math.pi/180)
	dvector.x = math.cos(angle_rad) * unitSpeed
	dvector.y = math.sin(angle_rad) * unitSpeed
	
	return dvector
end

function Unit:getAngle(x,y)				-- returns a point (x and y) given an angle
	retAngle = math.tan( y/x )
	return retAngle * (180 / math.pi)
end

function Unit:checkMapBoundaries(mx, my, unitRadius)
	-- checking map boundaries
	local map_w = map.width*map.tileSize
	local map_h = map.height*map.tileSize
	local random_direction = math.random(1,2)
	
	if  (my < unitRadius * 2) then							-- too close to the top of the screen
		--print("top")
		if random_direction == 1 then return math.random(10,25)
		else return math.random(155,170) end
	elseif (mx < unitRadius * 2) then						-- too close to the left side of the screen
		--print("left")
		if random_direction == 1 then return math.random(65,80)
		else return math.random(280,295) end
	elseif (my > (map_h - unitRadius * 2)) then				-- too close to the bottom of the screen
		--print("bottom")
		if random_direction == 1 then return math.random(190,205)
		else return math.random(335,350) end
	elseif (mx > (map_w - unitRadius * 2)) then				-- too close to the right side of the screen
		--print("right")
		if random_direction == 1 then return math.random(245,260)
		else return math.random(100,115) end
	end
	
	return 999
end

function Unit:avoidTile(unitObject)
	local t2 = unitObject.neighbourTiles[2]
	local t4 = unitObject.neighbourTiles[4]
	local t6 = unitObject.neighbourTiles[6]
	local t8 = unitObject.neighbourTiles[8]
	local stuckDir = "O"
	
	if unitObject.angle >= 45 and unitObject.angle <= 135 then stuckDir = "S"
	elseif unitObject.angle > 135 and unitObject.angle <= 225 then stuckDir = "W"
	elseif unitObject.angle > 225 and unitObject.angle <= 315 then stuckDir = "N"
	else stuckDir = "E" end
	
	if stuckDir == "N" then
		unitObject.angle = math.random(0,180)
		unitObject.targetAngle = unitObject.angle
	elseif stuckDir == "E" then
		unitObject.angle = math.random(90,270)
		unitObject.targetAngle = unitObject.angle
	elseif stuckDir == "S" then
		unitObject.angle = math.random(180,360)
		unitObject.targetAngle = unitObject.angle
	elseif stuckDir == "W" then
		local r = math.random(1,2)
		if r == 1 then unitObject.angle = math.random(270,360) else
		unitObject.angle = math.random(0,90) end
		unitObject.targetAngle = unitObject.angle
	end
	
	--[[
	if unitObject.neighbourTiles[2] == "G" or unitObject.neighbourTiles[2] == "R" then
		unitObject.angle = math.random(180,360)
		unitObject.targetAngle = unitObject.angle
	elseif unitObject.neighbourTiles[4] == "G" or unitObject.neighbourTiles[4] == "R" then
		unitObject.angle = math.random(90,270)
		unitObject.targetAngle = unitObject.angle
	elseif unitObject.neighbourTiles[6] == "G" or unitObject.neighbourTiles[6] == "R" then
		local r = math.random(1,2)
		if r == 1 then unitObject.angle = math.random(270,360) else
		unitObject.angle = math.random(0,90) end
		unitObject.targetAngle = unitObject.angle
	elseif unitObject.neighbourTiles[8] == "G" or unitObject.neighbourTiles[8] == "R" then
		unitObject.angle = math.random(0,180)
		unitObject.targetAngle = unitObject.angle
	end
	--]]
end

function Unit:avoidTile2(unit, tile)
	if tile == "N" then
		if unit.angle > 180 and unit.angle <= 270 then
			unit.angle = math.random(160,175)
		elseif unit.angle > 270 and unit.angle <= 360 then
			unit.angle = math.random(5,20)
		end
	elseif tile == "E" then
		if unit.angle > 270 and unit.angle <= 360 then
			unit.angle = math.random(250,265)
		elseif unit.angle > 0 and unit.angle <= 90 then
			unit.angle = math.random(95,110)
		end	
	elseif tile == "S" then
		if unit.angle > 0 and unit.angle <= 90 then
			unit.angle = math.random(340,355)
		elseif unit.angle > 90 and unit.angle <= 180 then
			unit.angle = math.random(185,200)
		end	
	elseif tile == "W" then
		if unit.angle > 90 and unit.angle <= 180 then
			unit.angle = math.random(70,85)
		elseif unit.angle > 180 and unit.angle <= 270 then
			unit.angle = math.random(275,290)
		end	
	elseif tile == "NE" then
		unit.angle = 225
	elseif tile == "SE" then
		unit.angle = 315
	elseif tile == "SW" then
		unit.angle = 225
	elseif tile == "NW" then
		unit.angle = 315
	end	
	unit.targetAngle = unit.angle	
end

function Unit:updateNeighbours(unitObject)
	local currentTileW = math.floor(unitObject.x / map.tileSize)
	local currentTileH = math.floor(unitObject.y / map.tileSize)
	unitObject.neighbourTiles[1] = map.tiles[currentTileW-1][currentTileH-1].id
	unitObject.neighbourTiles[2] = map.tiles[currentTileW][currentTileH-1].id
	unitObject.neighbourTiles[3] = map.tiles[currentTileW+1][currentTileH-1].id
	
	unitObject.neighbourTiles[4] = map.tiles[currentTileW-1][currentTileH].id
	unitObject.neighbourTiles[5] = map.tiles[currentTileW][currentTileH].id
	unitObject.neighbourTiles[6] = map.tiles[currentTileW+1][currentTileH].id
	
	unitObject.neighbourTiles[7] = map.tiles[currentTileW-1][currentTileH+1].id
	unitObject.neighbourTiles[8] = map.tiles[currentTileW][currentTileH+1].id
	unitObject.neighbourTiles[9] = map.tiles[currentTileW+1][currentTileH+1].id
end

function Unit:xyToTileType(x11,y11)
	w = math.floor( x11 / map.tileSize )
	h = math.floor( y11 / map.tileSize )
	--print("x:"..x11..",y:"..y11)
	--print("w:"..w..",h:"..h)
	return map.tiles[w][h].id
end

function Unit:checkNextTile(unitObject)
	local tileType = self:xyToTileType(unitObject.x, unitObject.y)
	if tileType ~= "G" then
		return false
	end
	return true
end

 -- distance between 2 points
 function Unit:distanceBetweenPoints(x1,y1,x2,y2)
 
	local x_v1, y_v1 = 0
	
	--[[if (x1 < x2) and (y1 < y2) then]]--
		x_v1 = x2 - x1
		y_v1 = y2 - y1
		return math.sqrt( x_v1 * x_v1 + y_v1 * y_v1 )
	--[[elseif (x1 > x2) and (y1 < y2) then
		x_v1 = x1 - x2
		y_v1 = y2 - y1
		return math.sqrt( x_v1 * x_v1 + y_v1 * y_v1 )
	elseif (x1 > x2) and (y1 > y2) then
		x_v1 = x1 - x2
		y_v1 = y1 - y2
		return math.sqrt( x_v1 * x_v1 + y_v1 * y_v1 )
	elseif (x1 < x2) and (y1 > y2) then
		x_v1 = x2 - x1
		y_v1 = y1 - y2
		return math.sqrt( x_v1 * x_v1 + y_v1 * y_v1 )
	end
	return 9999]]--
 end
 
 --[[
function Unit:pointInTriangle(p, az, b, c)			-- arguments: Point p, Point a, Point b, Point c

    as_x = p.x-az.x
    as_y = p.y-az.y
	
	if ( ( (b.x-az.x)*as_y-(b.y-az.y)*as_x ) > 0 ) then
		s_ab = 1
	else
		s_ab = 0
	end

    if((c.x-az.x)*as_y-(c.y-az.y)*as_x > 0 == s_ab) then return false end
	--print("x,y:"..az.x.. ","..az.y)
    if((c.x-b.x)*(p.y-b.y)-(c.y-b.y)*(p.x-b.x) > 0 ~= s_ab) then return false end
	
    return true
end--]]

function Unit:pointInArc(x1, y1, x2, y2, fovRadius, startAngle, endAngle)
	if self:distanceBetweenPoints(x1,y1,x2,y2) < fovRadius then			-- if the point x2,y2 is < fovRadius, it is in the circle

		local angleToPoint = self:angleToXY(x1,y1,x2,y2)
		if  angleToPoint >= startAngle and angleToPoint <= endAngle then
			return true
		elseif endAngle > 360 then						-- EXCEPTIONS ! if endAngle is > 360 or startAngle < 0 .. then boundary check is diff
			endAngle = endAngle - 360
			if angleToPoint >= 0 and angleToPoint < endAngle then
				return true
			end
		elseif startAngle < 0 then
			startAngle = 360 + startAngle
			if angleToPoint >= startAngle and angleToPoint < 360 then
				return true
			end
		end
	end
	return false
end

-- gets the angle from x1,y1 through to point x2,y2
function Unit: angleToXY(x1,y1,x2,y2)
	local x_v, y_v = 0
	local angleRet = 0
	if (x1 < x2) and (y1 < y2) then
		x_v = x2 - x1
		y_v = y2 - y1
		angleRet = math.deg( math.atan(y_v / x_v) )
	elseif (x1 > x2) and (y1 < y2) then
		x_v = x1 - x2
		y_v = y2 - y1
		angleRet = math.deg( math.atan(y_v / x_v) )
		angleRet = 180 - angleRet
	elseif (x1 > x2) and (y1 > y2) then
		x_v = x1 - x2
		y_v = y1 - y2
		angleRet = math.deg( math.atan(y_v / x_v) )
		angleRet = 180 + angleRet
	elseif (x1 < x2) and (y1 > y2) then
		x_v = x2 - x1
		y_v = y1 - y2
		angleRet = math.deg( math.atan(y_v / x_v) )
		angleRet = 360 - angleRet
	end
	return angleRet
end

function Unit:sign(p1, p2, p3)
  return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y)
end

	-- checks if point 'pt' is in a triangle with vertices v1,v2,v3
function Unit:pTriangle(pt, v1, v2, v3)

  if (self:sign(pt, v1, v2) < 0) then
	b1 = 1
  else
	b1 = 0
  end
  
  if (self:sign(pt, v2, v3) < 0) then
	b2 = 1
  else
	b2 = 0
  end
  
  if (self:sign(pt, v3, v1) < 0) then
	b3 = 1
  else
	b3 = 0
  end

  return ((b1 == b2) and (b2 == b3))
end

function Unit:signOf(v)	
	return v > 0 and 1 or (v < 0 and -1 or 0)
end

function Unit:getShortestPath(x1,y1,x2,y2)
	local x1tile = math.floor(x1 / map.tileSize)
	local y1tile = math.floor(y1 / map.tileSize)
	local x2tile = math.floor(x2 / map.tileSize)
	local y2tile = math.floor(y2 / map.tileSize)
	
	local path = astar:findPath(x1tile,y1tile,x2tile,y2tile)

	if path ~= nil then 
		self.path = path 
		return true
	else return false end
end

function Unit:inLineOfSight(cx, cy)
	local curTile = map:tileAt(self.cx, self.cy)		-- tile you are checking from
	local tAngle = self:angleToXY(self.cx, self.cy, cx,cy)
	local targetTileX = math.floor(cx/map.tileSize)				-- tile of your target
	local targetTileY = math.floor(cy/map.tileSize)
	local selfTileX = math.floor(self.cx/map.tileSize)		
	local selfTileY = math.floor(self.cy/map.tileSize)
	local nextX = self.cx
	local nextY = self.cy
	local dx = 0
	local dy = 0
		
	while (not((selfTileX + dx == targetTileX) and (selfTileY + dy == targetTileY))) do
		-- somehow get the next tile that your self angle intersects
		-- trying to use code from ranger class that gets next time to collide with
		-- checking the tile that the unit is or will be on
		nextX = nextX + math.cos(tAngle * (math.pi/180))*1
		nextY = nextY + math.sin(tAngle * (math.pi/180))*1
		
		-- determine the direction of the tile the unit will most likely next collide with
		dx = math.floor(nextX/map.tileSize) - math.floor(self.cx/map.tileSize)
		dy = math.floor(nextY/map.tileSize) - math.floor(self.cy/map.tileSize)
		
		-- go up to next tile
		curTile = map.tiles[selfTileX + dx][selfTileY + dy]
		
		print(selfTileX + dx..","..selfTileY + dy..":"..curTile.id.."  (target: "..targetTileX..","..targetTileY..")")
		
		if curTile.id == "X" then return true end
		
		-- if next tile building, you cant see the target
		if curTile.id == "D" then return false end
	end
	
	return true
end