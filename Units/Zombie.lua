require "Units/SpriteAnimation"

Zombie = {}
Zombie_mt = { __index = Zombie }

--[[ 
		nothing here. move on.
]]

-- see_human_dist = 50				-- at what distance will the zombie see the human ?

-- Constructor
function Zombie:new(x_new, y_new)

    local new_object = {							-- define our parameters here
    tag = 0,										-- tag of unit			
	dirVector = 0,
	x = x_new,										-- x and y coordinates ( by default, left top )
    y = y_new,
	cx = 0,											-- centered x and y coordinates of the unit
	cy = 0,
	angle = math.random(360),						-- randomize initial angles
	targetAngle = math.random(360),
	dirVec = 0,										-- 0 for negative, 1 for positive
	radius = 4,
    width = 0,
    height = 0,
	speed = 0,
    state = "",
    runSpeed = 0,
	directionTimer = 0,
	searchTimer = 0,
	searchFreq = 0.25,
	time_kill = 0,
	initial_direction = 1,
	x_direction = math.random(-1,1),
	y_direction = math.random(-1,1),
	fov_radius = 120,
	fov_angle = 95,
	fovStartAngle = 0,
	fovEndAngle = 0,
	followingTag = 0,									-- index of the human in human_list that this zombie will follow. if it's 0, then this zombie
	followingType = "None",
	selected = false,
	v1 = Point:new(0,0),							-- vertices for the field of view triangle
	v2 = Point:new(0,0),
	v3 = Point:new(0,0),
	controlled = false,
	onCurrentTile = 0,
	neighbourTiles = {},
	delete = false,				-- if this is set to true, this zombie will be deleted by unitManager on the next update
	animation = SpriteAnimation:new("Units/images/zombie2.png", 10, 12, 8, 1),
	zombieSniffTimer = 0,						-- after 20-30 seconds of checking one place around, the zombie gets shortest path
	hangAroundAreaTimer = math.random(25, 35),	-- to the nearest human (civilian, worker or ranger ) and goes there 
	followingSP = false,							-- following shortest path to the nearest human.. no boundary check req.
	followingTileCount = 0,
	tarXTile = -1,
	tarYTile = -1,
	path = nil,
	randomDirectionTimer = math.random(7, 10),
	timerToGetToNextTile = 0
	}											

	setmetatable(new_object, Zombie_mt )			-- add the new_object to metatable of Zombie
	setmetatable(Zombie, { __index = Unit })        -- Zombie is a subclass of class Unit, so set inheritance..
	
	--self:setupUnit()					
	
    return new_object								--
end

function Zombie:setupUnit()							-- init vars for Zombie unit

	local map_w = map.width*map.tileSize
	local map_h = map.height*map.tileSize
	
	--print("map size W:"..map_w..", H:".. map_h)
	--print("spawning boundaries: x:".. (self.radius * 3) .. ", ".. (map_w - self.radius * 3) )
	--print("spawning boundaries: y:".. (self.radius * 3) .. ", ".. (map_h - self.radius * 3) )
	if not self.x then self.x = math.random(self.radius * 3, map_w - self.radius * 3) end
	if not self.y then self.y = math.random(self.radius * 3, map_h - self.radius * 3) end

	self.cx = self.x + self.radius
	self.cy = self.y + self.radius
	self.onCurrentTile = self:xyToTileType(self.cx, self.cy)
	
	while not (self.onCurrentTile == "R" or self.onCurrentTile == "G" or self.onCurrentTile == "F" or self.onCurrentTile == "P") do
		self.x = math.random(self.radius * 3, map_w - self.radius * 3)
		self.y = math.random(self.radius * 3, map_h - self.radius * 3)
		self.cx = self.x + self.radius
		self.cy = self.y + self.radius
		self.onCurrentTile = self:xyToTileType(self.cx, self.cy)
	end
	
	-- get neighbour tile types
	--self:updateNeighbours(self)

	--local val = math.random(1,5)
	--print("val:"..val)
	
	-- print( math.tan(5))		-- prints (in degrees) 5/1 ( 5 degrees / 1 degree )
	
	--print(self:xyToTileType(250,350))				-- FIRST WATER
	
	self.timerToGetToNextTile = 0
	self.followingTileCount = 0
	self.followingSP = false
	self.cx = self.x + self.radius
	self.cy = self.y - self.radius
	
	self.speed = 20
	self.dirVector = self:getDirection(self.angle, self.speed)
	self.x_direction = 0
	self.y_direction = 0
	self.width = 50
	self.height = 50
	self.state = "Looking around"
	self.normalSpeed = 5
	self.runSpeed = 7
	--self.tag = zombie_tag
	self.tag = unitTag
	--zombie_tag = zombie_tag + 1
	
	self.animation:load()
	self.animation:switch(1,8,120)
end

function Zombie:draw(i)

	love.graphics.setColor(211,211,211,150)
	
	------------------------------- UPDATE FIELD OF VIEW VERTICES
	-- for triangle:
	self.v1 = Point:new(self.x + self.radius, self.y + self.radius)
	self.v2 = Point:new(self.x + math.cos( (self.angle - 40) * (math.pi/180) )*90 + self.radius, self.y + math.sin( (self.angle - 40) * (math.pi/180) )*90 + self.radius)
	self.v3 = Point:new(self.x + math.cos( (self.angle + 40 ) * (math.pi/180) )*90 + self.radius, self.y + math.sin( (self.angle + 40) * (math.pi/180) )*90 + self.radius)
	-- for arc:
	self.fovStartAngle = self.angle - self.angle/2
	self.fovEndAngle = self.angle + self.angle/2
	
	------------------------------- IF UNIT IS SELECTED.. DRAW:
	if self.selected then	
	
		love.graphics.setColor(201,85,91,70)	
		
		-- draw the arc field of view
		love.graphics.arc( "fill", self.x + self.radius, self.y + self.radius, self.fov_radius, math.rad(self.angle + self.fov_angle / 2), math.rad(self.angle - self.fov_angle / 2) )
		-- love.graphics.arc( mode, x, y, radius, angle1, angle2, segments )
		
		-- draw the triangle fov
		--[[love.graphics.triangle( "fill",
			self.v1.x,self.v1.y,
			self.v2.x,self.v2.y,
			self.v3.x,self.v3.y
			)--]]
		
		-- draw line for angle and targetAngle
		if menu.debugMode then
			love.graphics.line(self.x + self.radius,self.y + self.radius, 
								self.x + math.cos(self.angle * (math.pi/180) )*30 + self.radius , 
								self.y + math.sin(self.angle * (math.pi/180))* 30 + self.radius)
			love.graphics.setColor(0,255,0)
			love.graphics.line(self.x + self.radius,self.y + self.radius, 
								self.x + math.cos(self.targetAngle * (math.pi/180) )*30 + self.radius , 
								self.y + math.sin(self.targetAngle * (math.pi/180))* 30 + self.radius)
		end
		
			-- draw green circle around him
			love.graphics.setColor(0,255,0, 150)
			love.graphics.circle( "line", self.x + self.radius, self.y + self.radius, 9, 15 )
			love.graphics.circle( "line", self.x + self.radius, self.y + self.radius, 10, 15 )
		
		
		--love.graphics.circle( "fill", self.x + self.radius, self.y + self.radius, 70, 25 )
		
		local j = 0
		if (self.path ~= nil) then
			for i = #self.path, 1, -1 do
				love.graphics.setColor(0,255,0,50)
				love.graphics.rectangle("fill", self.path[i].x*54, self.path[i].y*54, 54, 54)
				j = j + 1
			end
		end

	end
	
	if menu.debugMode then
		if self.followingSP == true then
			love.graphics.print("TRUE", self.x, self.y + 10)
		else
			love.graphics.print("FALSE", self.x, self.y + 10)
		end
	end
	
	playerColor = {255,0,0}
	love.graphics.setColor(playerColor)
	
	------------------------------- DRAW UNIT ( A CIRCLE FOR NOW )
	--love.graphics.circle("fill", self.x + self.radius, self.y + self.radius, self.radius, 15)
	--love.graphics.print(self.tag.. " ".. self.state, self.x, self.y + 10)
	
	------------------------------- DEBUG CODE -------------------------------------
	
	-- for debugging:	FIELD OF VIEW OF ZOMBIE:
	--love.graphics.rectangle("line", self.x - see_human_dist, self.y, 10, 10)
	--love.graphics.rectangle("line", self.x, self.y + see_human_dist, 10, 10)
	--love.graphics.rectangle("line", self.x + see_human_dist, self.y, 10, 10)
	--love.graphics.rectangle("line", self.x, self.y - see_human_dist, 10, 10)
	-- end debugging
	

	
	--draw sprite
	love.graphics.reset()
	self.animation:draw(self.cx,self.cy)
end

-- Update function
function Zombie:update(dt, zi)
		
	-- update animation
	self.animation:rotate(self.angle)
	self.animation:update(dt)
	
	------------------------------- CHECK PAUSE AND LOOK AROUND / FOLLOW HUMAN
	-- if game is paused, do not update any values
	--if paused == true then return end
	
	if self.followingTag ~= 0 then			-- if zombie is following a human				
		self:follow_human(dt)			-- zombie is following a human
		return							-- no need to update anything else here so return
	else
		if self.searchTimer > self.searchFreq then
			self:lookAround(zi)				-- else look around 
			self.searchTimer = 0
		end
	end
	
	if self.followingSP == false and self.followingTag == 0 then
		------------------------------- CHECK SNIFF TIMER AND IF ZOMBIE NEEDS TO MOVE TO ANOTHER HUMAN LOCATION
		-- increase zombieSniffTimer // look around in one area // go to nearest human
		if self.zombieSniffTimer > self.hangAroundAreaTimer then
			-- get nearest human location, get shortest path to it
			local zposition = Point:new(self.x, self.y)
			local hUnit = unitManager:getClosestHuman(zposition)
			if hUnit ~= nil then
				--print("zombie: "..self.tag.." is moving towards human: "..hUnit.tag)
				-- this should set self.path
				self:getShortestPath(self.x, self.y, hUnit.x, hUnit.y)
				
				-- if self.path is set ..
				if (self.path ~= nil) then
					self.followingTileCount = 0
					self.followingSP = true
					self.timerToGetToNextTile = 0
					self.tarXTile = self.path[#self.path - self.followingTileCount].x 
					self.tarYTile = self.path[#self.path - self.followingTileCount].y
					self.followingTileCount = self.followingTileCount + 1
					-- its + map.tileSize / 2 because the targetAngle is aiming for the middle of the tile !
					self.targetAngle = self:angleToXY( self.x, self.y, self.tarXTile * map.tileSize + map.tileSize / 2, self.tarYTile * map.tileSize + map.tileSize / 2 )
					--self.angle = self.targetAngle
					self.dirVec = self:calcShortestDirection(self.angle, self.targetAngle)
				end
			end
			
			self.hangAroundAreaTimer = math.random(20,30)
			self.zombieSniffTimer = 0
		else
			self.zombieSniffTimer = self.zombieSniffTimer + dt
		end
	end
	
	if self.followingSP == false and self.followingTag == 0 then			-- randomize direction only if the zombie is not in motion to another human location
		------------------------------- RANDOMIZING DIRECTION AFTER 5 SECONDS
		if self.directionTimer > self.randomDirectionTimer then
			-- randomize a degree, 0 to 360
			self.targetAngle = math.random(360)
			
		-- get the angle direction ( positive or negative on axis ) given the current angle and the targetAngle
			self.dirVec = self:calcShortestDirection(self.angle, self.targetAngle)

			-- reset directionTimer
			self.directionTimer = 0		

			self.randomDirectionTimer = math.random(7, 10)
		end
	end
	
	------------------------------- UPDATE SELF.ANGLE
	if ((self.targetAngle - 1) < self.angle) and ((self.targetAngle + 1) > self.angle) then		-- targetAngle reached
	
		------------------------------- IF THE ZOMBIE IS FOLLOWING SHORTEST PATH....
		if self.followingSP == true and self.followingTag == 0 then
			if (self.tarXTile == math.floor(self.x / map.tileSize)) and (self.tarYTile == math.floor(self.y / map.tileSize)) then
				if (#self.path == self.followingTileCount) then
					self.followingSP = false
					self.followingTileCount = 0
					self.tarXTile = self.path[#self.path - self.followingTileCount].x 
					self.tarYTile = self.path[#self.path - self.followingTileCount].y
					self.followingTileCount = self.followingTileCount + 1
					self.targetAngle = self:angleToXY( self.x, self.y, self.tarXTile * map.tileSize + map.tileSize / 2, self.tarYTile * map.tileSize + map.tileSize / 2 )
					self.dirVec = self:calcShortestDirection(self.angle, self.targetAngle)
					self.path = nil
				else
					self.tarXTile = self.path[#self.path - self.followingTileCount].x -- else worker is still on path to a destination..
					self.tarYTile = self.path[#self.path - self.followingTileCount].y
					self.followingTileCount = self.followingTileCount + 1
					self.targetAngle = self:angleToXY( self.x, self.y, self.tarXTile * map.tileSize + map.tileSize / 2, self.tarYTile * map.tileSize + map.tileSize / 2 )
					--self.angle = self.targetAngle
					self.dirVec = self:calcShortestDirection(self.angle, self.targetAngle)
					
				end
				--print("Next Tile ! ".. self.timerToGetToNextTile)
				self.timerToGetToNextTile = 0
			end

			self.timerToGetToNextTile = self.timerToGetToNextTile + dt
			-- EXCEPTION CATCHER:
			if self.timerToGetToNextTile > 5 then
				self.followingSP = false
				self.path = nil
				self.followingTileCount = 0
			end
		end
	
	else																						-- else.. 
	
		-- every update, the unit is trying to get towards the target angle by changing its angle slowly.
		if self.dirVec == 0 then			-- positive direction	( opposite of conventional as y increases downwards )
			if self.followingSP == true then
				self.angle = self.angle + 1.1
			else
				
				self.angle = self.angle + 0.2
			end
		elseif self.dirVec == 1 then		-- negative direction
			if self.followingSP == true then
				self.angle = self.angle - 1.1
			else
				self.angle = self.angle - 0.2
			end
		end
		
		-- reset angles if they go over 360 or if they go under 0
		if self.angle > 360 then
			self.angle = self.angle - 360
		end
		
		if self.angle < 0 then
			self.angle = 360 + self.angle
		end
	end
	
	------------------------------- UPDATE MOVEMENT
	-- get direction vector
	self.dirVector = self:getDirection(self.angle, self.speed)
	
	--if self.followingSP == false then
		-- checking the tile that the unit is or will be on
		local next_x = self.x + (self.radius * self:signOf(self.dirVector.x)) + (dt * self.dirVector.x)
		local next_y = self.y + (self.radius * self:signOf(self.dirVector.y)) + (dt * self.dirVector.y)
		
		-- determine the direction of the tile the unit will most likely next collide with
		local dx = math.floor(next_x/map.tileSize) - math.floor(self.cx/map.tileSize)
		local dy = math.floor(next_y/map.tileSize) - math.floor(self.cy/map.tileSize)
		local nextTileDir = ""
		
		if 	   (dx == 0) and (dy == -1) then 	nextTileDir = "N"
		elseif (dx == 1) and (dy == -1) then 	nextTileDir = "NE"
		elseif (dx == 1) and (dy == 0) then 	nextTileDir = "E"
		elseif (dx == 1) and (dy == 1) then 	nextTileDir = "SE"
		elseif (dx == 0) and (dy == 1) then 	nextTileDir = "S"
		elseif (dx == -1) and (dy == 1) then 	nextTileDir = "SW"
		elseif (dx == -1) and (dy == 0) then 	nextTileDir = "W"
		elseif (dx == -1) and (dy == -1) then 	nextTileDir = "NW" end
		
		local nextTileType = self:xyToTileType(next_x,next_y)
		-- check next tile (not in panic mode)
		if  not (nextTileType == "G" or nextTileType == "R" or nextTileType == "F" or nextTileType == "P") then
			self.directionTimer = self.directionTimer + dt
			self.state = "STUCK !"
			self:avoidTile2(self,nextTileDir)
			return
		end
		
		------------------------------- CHECK MAP BOUNDARIES 						** IF IN PANIC MODE, MAYBE SHOULD CHECK WHERE ZOMBIE IS COMING FROM AND THEN SET THE TARGET ANGLE
		-- next move would be out of bounds so cancel it and return !
		if next_x < 0 or next_x > map.tileSize*map.width or next_y < 0 or next_y > map.tileSize*map.height then
			self.state = "WTF"
			self.directionTimer = self.directionTimer + dt
			return
		end																															-- ** IN THE OTHER DIRECTION !
		local val = self:checkMapBoundaries(next_x,next_y, self.radius)											
		if val ~= 999 then			-- if it is too close to a boundary..
			self.angle = val
			self.targetAngle = val
			--return
		end
	--end
	
	-- update zombie's movement
	self.x = self.x + (dt * self.dirVector.x)
	self.y = self.y + (dt * self.dirVector.y)
	-- update the center x and y values of the unit
	self.cx = self.x + self.radius
	self.cy = self.y + self.radius
	
	-- update direction time ( after 5 seconds, the unit will randomly change direction )
	self.directionTimer = self.directionTimer + dt			-- increasing directionTimer
	self.searchTimer = self.searchTimer + dt	
 end
 
 function Zombie:lookAround(zi)
 
	-- followingTag stores the tag of the human to be followed ( if any )
	for i = 1, number_of_humans do
	
			local human_point = Point:new(human_list[i].cx, human_list[i].cy)
			--local val = self:pTriangle(human_point, self.v1, self.v2, self.v3)						-- detect humans in a triangle
			local val = self:pointInArc(self.x, self.y, human_point.x, human_point.y, 
										self.fov_radius, self.fovStartAngle, self.fovEndAngle)	-- detect humans in an arc (pie shape)
			if val == true then										-- if human i is in the field of view of the zombie
				self.followingTag = human_list[i].tag
				self.followingType = "Human"
				self.state = "Chasing ".. self.followingTag	
				human_list[i].color = 1
				
				-- disable following shortest path as the zombie is now chasing a human
				self.followingSP = false
				self.path = nil
				--self.zombieSniffTimer = 0
			end
		
		-- zombie found a human to chase; break out of loop
		if self.followingTag ~= 0 then break end
	end
	
	-- followingTag stores the  of the human to be followed ( if any )
	for i,v in pairs (ranger_list) do
	
			local ranger_point = Point:new(v.cx, v.cy)
			local val = self:pointInArc(self.x, self.y, ranger_point.x, ranger_point.y, 
										self.fov_radius, self.fovStartAngle, self.fovEndAngle)	-- detect humans in an arc (pie shape)
			if val == true then										-- if human i is in the field of view of the zombie
				self.followingTag = ranger_list[i].tag
				self.followingType = "Ranger"
				self.state = "Chasing ".. self.followingTag
				
				-- disable following shortest path as the zombie is now chasing a human
				self.followingSP = false
				self.path = nil
				--self.zombieSniffTimer = 0
			end
		
		-- zombie found a human to chase; break out of loop
		if self.followingTag ~= 0 then break end
	end
	
	-- followingTag stores the tag of the worker to be followed ( if any )
	for i,v in pairs (worker_list) do
	
			local worker_point = Point:new(v.cx, v.cy)
			local val = self:pointInArc(self.x, self.y, worker_point.x, worker_point.y, 
										self.fov_radius, self.fovStartAngle, self.fovEndAngle)	-- detect humans in an arc (pie shape)
			if val == true then										-- if human i is in the field of view of the zombie
				self.followingTag = worker_list[i].tag
				self.followingType = "Worker"
				self.state = "Chasing ".. self.followingTag
				
				-- disable following shortest path as the zombie is now chasing a human
				self.followingSP = false
				self.path = nil
				--self.zombieSniffTimer = 0
			end
		
		-- zombie found a human to chase; break out of loop
		if self.followingTag ~= 0 then break end
	end
	
 end
 
 function Zombie:follow_human(dt)
	
	local h_index = 0
	local dist = 999
			
	if self.followingType == "Human" then
		-- find the index (in the 'human_list' array) of the human followed 
		for i = 1, number_of_humans do
			if human_list[i].tag == self.followingTag then
				h_index = i
			end
		end
		------------------------------- CALCULATE DISTANCE BETWEEN ZOMBIE AND THE HUMAN IT IS FOLLOWING
		dist = self:distanceBetweenPoints(self.cx,self.cy,human_list[h_index].cx, human_list[h_index].cy)
		
	elseif self.followingType == "Ranger" then
		for i = 1, number_of_rangers do
			if ranger_list[i].tag == self.followingTag then
				h_index = i
			end
		end
		------------------------------- CALCULATE DISTANCE BETWEEN ZOMBIE AND THE RANGER IT IS FOLLOWING
		dist = self:distanceBetweenPoints(self.cx,self.cy,ranger_list[h_index].cx, ranger_list[h_index].cy)
	elseif self.followingType == "Worker" then
		for i = 1, number_of_workers do
			if worker_list[i].tag == self.followingTag then
				h_index = i
			end
		end
		------------------------------- CALCULATE DISTANCE BETWEEN ZOMBIE AND THE WORKER IT IS FOLLOWING
		dist = self:distanceBetweenPoints(self.cx,self.cy,worker_list[h_index].cx, worker_list[h_index].cy)
	end

	-- if its very close, zombie eats human
	if dist < (self.radius * 2 + 7) then
	   
	   -- set followed unit's attacked state to 1
	   if self.followingType == "Human" then human_list[h_index].attacked = 1
	   elseif self.followingType == "Ranger" then ranger_list[h_index].attacked = 1
	   elseif self.followingType == "Worker" then worker_list[h_index].attacked = 1 end
	   
		if (self.time_kill > 2) then									-- unit with index 'followingTag' should be dead by now !
			local deadx = 99
			local deady = 99
			if self.followingType == "Human" then 
				deadx = human_list[h_index].x
				deady = human_list[h_index].y
				table.remove(human_list, h_index)							-- remove human from human_list array
				number_of_humans = number_of_humans - 1						-- decrease count of humans alive
				infoText:addText("A civilian has been killed by a zombie !")
			elseif self.followingType == "Ranger" then 
				deadx = ranger_list[h_index].x
				deady = ranger_list[h_index].y
				table.remove(ranger_list, h_index)							-- remove human from human_list array
				number_of_rangers = number_of_rangers - 1						-- decrease count of humans alive
				infoText:addText("A ranger has been killed by a zombie !")
			elseif self.followingType == "Worker" then 
				deadx = worker_list[h_index].x
				deady = worker_list[h_index].y
				if worker_list[h_index].working == false then
					unitManager.idleWorkers = unitManager.idleWorkers - 1
					infoText:addText("An idle worker has been killed by a zombie !")
				else
					infoText:addText("A worker has been killed by a zombie !")
				end
				table.remove(worker_list, h_index)							-- remove human from human_list array
				number_of_workers = number_of_workers - 1						-- decrease count of humans alive
			end
			
			number_of_zombies = number_of_zombies + 1					-- increase count of zombies alive
			zombie_list[number_of_zombies] = Zombie:new(deadx, deady)	-- create new zombie at the location of this zombie
			zombie_list[number_of_zombies]:setupUnit()					-- setup zombie
			unitTag = unitTag + 1
			-- tell all zombies that human with tag 'self.followingTag' is dead
			self:tellZombies(self.followingTag)		
			
			-- reset timer for time to kill a unit
			self.time_kill = 0										
			self.followingTag = 0				-- reset followingTag as the zombie is not following any units anymore
			self.followingType = "None"
			self.state = "Looking around"
			return
		end
		
		self.time_kill = self.time_kill + dt
		return								-- no need to follow the human unit anymore
	elseif	dist > 120 then					-- if zombie is too far, abandon the follow
		self.followingTag = 0					-- unset follow
		self.state = "Looking around"
		if self.followingType == "Human" then
			human_list[h_index].panicMode = false		-- the human is not in panicMode anymore as it is not being followed anymore
		elseif self.followingType == "Ranger" then
			ranger_list[h_index].panicMode = false
		elseif self.followingType == "Worker" then
			worker_list[h_index].panicMode = false
		end
	end
	
	
	------------------------------- FOLLOWING THE HUMAN
	
	-- get angle from this zombie's position to the followed unit's position
	if self.followingType == "Human" then
		self.targetAngle = self:angleToXY(self.x,self.y,human_list[h_index].x,human_list[h_index].y)
	elseif self.followingType == "Ranger" then
		self.targetAngle = self:angleToXY(self.x,self.y,ranger_list[h_index].x,ranger_list[h_index].y)
	elseif self.followingType == "Worker" then
		self.targetAngle = self:angleToXY(self.x,self.y,worker_list[h_index].x,worker_list[h_index].y)
	end
	
	-- check map boundaries
	local val = self:checkMapBoundaries(self.x,self.y, self.radius)
	if val ~= 999 then			-- if it is too close to a boundary..
		self.angle = val
	end
	
	-- get the angle direction ( positive or negative on axis ) given the current angle and the targetAngle
	self.dirVec = self:calcShortestDirection(self.angle, self.targetAngle)
	
	if ((self.targetAngle - 1) < self.angle) and ((self.targetAngle + 1) > self.angle) then
		-- target has been reached, no need to change the direction vector; keep the same self.angle value !
	else
		-- every update, the unit is trying to get towards the target angle by changing its angle slowly.
		if self.dirVec == 0 then			-- positive direction	( opposite of conventional as y increases downwards )
			self.angle = self.angle + 0.35
		elseif self.dirVec == 1 then		-- negative direction
			self.angle = self.angle - 0.35
		end
		
		-- reset angles if they go over 360 or if they go under 0
		if self.angle > 360 then
			self.angle = self.angle - 360
		end
		
		if self.angle < 0 then
			self.angle = 360 + self.angle
		end
	end
	
	-- get direction vector
	self.dirVector = self:getDirection(self.angle, self.speed)
	
	-- checking the tile that the unit is or will be on
	local next_x = self.cx + (dt * self.dirVector.x)
	local next_y = self.cy + (dt * self.dirVector.y)
	
	local nextTileType = self:xyToTileType(next_x,next_y)
	-- check next tile (not in panic mode)
	if  not (nextTileType == "G" or nextTileType == "R" or nextTileType == "F" or nextTileType == "P") then
		self.directionTimer = self.directionTimer + dt
		--self.state = "STUCK !"
		self:avoidTile2(self)
		return
	end
	
	-- update zombie's movement
	self.x = self.x + (dt * self.dirVector.x)
	self.y = self.y + (dt * self.dirVector.y)												
	-- update the center x and y values of the unit
	self.cx = self.x + self.radius
	self.cy = self.y + self.radius
 end
 
 -- alerting all zombies that human with tag 'human_tag' is dead
 function Zombie:tellZombies(unit_tag)
	-- if zombie i is following human with index followingTag, it should stop as that human is dead
	for i = 1, number_of_zombies do
		if zombie_list[i].followingTag == unit_tag then
			zombie_list[i].followingTag = 0
			zombie_list[i].time_kill = 0
			zombie_list[i].state = "Looking around"
		end
	end
end

function Zombie:die()
	-- tell the human you're following not to panic, its all good now brah

				--self.followingTag = 0				-- reset followingTag as the zombie is not following any units anymore
			--self.followingType = "None"
	local h_index = -1
	if self.followingType == "Human" then
		-- copying and pastng your own code here, but this could have been made much easier if you 
		-- just saved a reference to the human you're following as a self var like i did with rangers
		
		for i = 1, number_of_humans do
			if human_list[i].tag == self.followingTag then
				h_index = i
				human_list[i].attacked = 0
				break
			end
		end
		if h_index ~= -1 then human_list[h_index].panicMode = false end
	elseif self.followingType == "Worker" then
		for i = 1, number_of_workers do
			if worker_list[i].tag == self.followingTag then
				h_index = i
				worker_list[i].attacked = 0
				break
			end
		end
		if h_index ~= -1 then worker_list[h_index].panicMode = false end
	elseif self.followingType == "Ranger" then
		for i = 1, number_of_rangers do
			if ranger_list[i].tag == self.followingTag then
				h_index = i
				ranger_list[i].attacked = 0
				break
			end
		end
		if h_index ~= -1 then ranger_list[h_index].panicMode = false end
	end
	infoText:addText("A zombie has been killed !")
	-- mark this zombie for deletion (unitManager's update method will delete it on next update)
	self.delete = true	
end
 