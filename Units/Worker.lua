require "Units/SpriteAnimation"


Worker = {}
Worker_mt = { __index = Worker }

-- Constructor
function Worker:new(xnew,ynew)

    local new_object = {						-- define our parameters here
	tag = 0,									-- tag of unit
    x = xnew,									-- x and y coordinates ( by default, left top )
    y = ynew,
	cx = 0,										-- centered x and y coordinates of the unit
	cy = 0,
	radius = 4,
	angle = math.random(360),					-- randomize initial angles
	targetAngle = math.random(360),
    state = "",
	speed = 0,
	normalSpeed = 13,
	panicSpeed = 15,
	directionTimer = 0,
	searchTimer = 0,							-- timer, whenc it reachers searchFreq, human looksAround
	searchFreq = 0.25,							-- intervals at which to lookAround
	initial_direction = 1,
	fov_radius = 90,
	fov_angle = 140,
	fovStartAngle = 0,
	fovEndAngle = 0,
	attacked = 0,									-- if the unit is currently attacked, this var = 1
    panicMode = false,								-- panic mode is on if this is true..
	panicTimer = 0,									-- a unit that has spotted a zombie will be in panic mode for 6-7 seconds ( after spotting last zombie )
	v1 = Point:new(0,0),							-- vertices for the field of view triangle
	v2 = Point:new(0,0),
	v3 = Point:new(0,0),
	selected = false,
	working = false,
	tarXTile = -1,
	tarYTile = -1,
	turnFast = false,
	workingTileCount = 0,
	atLocation = "Other",
	carryingResource = false,
	color = 0,
	controlled = false,
	onCurrentTile = 0,
	neighbourTiles = {},
	animation = SpriteAnimation:new("Units/images/worker1.png", 10, 8, 8, 1),
	randomDirectionTimer = math.random(7, 10)
	}

	setmetatable(new_object, Worker_mt )				-- add the new_object to metatable of Human
	setmetatable(Worker, { __index = Unit })        -- Human is a subclass of class Unit, so set inheritance..				
	
    return new_object
end

function Worker:setupUnit()

	local map_w = map.width*map.tileSize
	local map_h = map.height*map.tileSize
	
	if not self.x then self.x = math.random(self.radius * 3, map_w - self.radius * 3) end
	if not self.y then self.y = math.random(self.radius * 3, map_h - self.radius * 3) end
	
	self.cx = self.x + self.radius
	self.cy = self.y + self.radius
	--------------------------               TILE CHECKS
	--print("Tile type:".. map.tiles[self.y][self.x].id)
	-- the unit must be randomized on a GROUND tile
	self.onCurrentTile = self:xyToTileType(self.cx, self.cy)
	
	while not (self.onCurrentTile == "R" or self.onCurrentTile == "G" or self.onCurrentTile == "F"  or self.onCurrentTile == "P") do
		self.x = math.random(self.radius * 3, map_w - self.radius * 3)
		self.y = math.random(self.radius * 3, map_h - self.radius * 3)
		self.cx = self.x + self.radius
		self.cy = self.y + self.radius
		self.onCurrentTile = self:xyToTileType(self.cx, self.cy)
	end
	--print("W:"..map.tiles[-1][-1].id)
	-- get neighbour tile types
	self:updateNeighbours(self)
	--------------------------		  TILE CHECKS
	
	self.fovStartAngle = self.angle - 45
	self.fovEndAngle = self.angle + 45
	
	self.state = "WORKER !"
	self.speed = self.normalSpeed
	--self.tag = worker_tag
	self.tag = unitTag
	self.directionTimer = 0
	
	self.animation:load()
	self.animation:switch(1,8,120)	
end

function Worker:draw(i)
	
	------------------------------- UPDATE FIELD OF VIEW VERTICES
	-- for triangle:
	--self.v1 = Point:new(self.x + self.radius, self.y + self.radius)
	--self.v2 = Point:new(self.x + math.cos( (self.angle - 70) * (math.pi/180) )*180 + self.radius, self.y + math.sin( (self.angle - 70) * (math.pi/180) )*180 + self.radius)
	--self.v3 = Point:new(self.x + math.cos( (self.angle + 70 ) * (math.pi/180) )*180 + self.radius, self.y + math.sin( (self.angle + 70) * (math.pi/180) )*180 + self.radius)
	-- for arc:
	self.fovStartAngle = self.angle - 45
	self.fovEndAngle = self.angle + 45
	------------------------------- IF UNIT IS SELECTED.. DRAW:
	if self.selected then
		love.graphics.setColor(0,0,255,70)
		-- draw triangle field of view
		--[[love.graphics.triangle( "fill", 
			self.v1.x,self.v1.y,
			self.v2.x,self.v2.y,
			self.v3.x,self.v3.y
		)]]
		
		-- draw the arc field of view
		
			love.graphics.arc( "fill", self.x + self.radius, self.y + self.radius, self.fov_radius, math.rad(self.angle + (self.fov_angle / 2)), math.rad(self.angle - (self.fov_angle / 2)) )
		if menu.debugMode then	
			-- draw line for angle and targetAngle
			love.graphics.line(self.x + self.radius,self.y + self.radius, 
								self.x + math.cos(self.angle * (math.pi/180) )*30 + self.radius , 
								self.y + math.sin(self.angle * (math.pi/180))* 30 + self.radius)
			love.graphics.setColor(0,255,0)
			love.graphics.line(self.x + self.radius,self.y + self.radius, 
								self.x + math.cos(self.targetAngle * (math.pi/180) )*30 + self.radius , 
								self.y + math.sin(self.targetAngle * (math.pi/180))* 30 + self.radius)
		end
		
		-- draw circle around selected unit
		love.graphics.setColor(0,0,255, 150)
		love.graphics.circle( "line", self.x + self.radius, self.y + self.radius, 5, 15 )
		love.graphics.circle( "line", self.x + self.radius, self.y + self.radius, 6, 15 )
		
		local currentTileW = math.floor(self.x / map.tileSize)
		local currentTileH = math.floor(self.y / map.tileSize)
		
		-- drawing neighbour tiles
		--[[
		love.graphics.setColor(0,255,60, 150, 150)
		love.graphics.rectangle( "fill", (currentTileW-1) * 25 , (currentTileH-1) * 25 , 25, 25 )
		love.graphics.rectangle( "fill", currentTileW * 25 , (currentTileH - 1) * 25 , 25, 25 )
		love.graphics.rectangle( "fill", (currentTileW + 1) * 25 , (currentTileH - 1) * 25 , 25, 25 )
		
		love.graphics.rectangle( "fill", (currentTileW - 1) * 25 , (currentTileH) * 25 , 25, 25 )
		love.graphics.rectangle( "fill", (currentTileW) * 25 , (currentTileH) * 25 , 25, 25 )
		love.graphics.rectangle( "fill", (currentTileW + 1) * 25 , (currentTileH) * 25 , 25, 25 )
		
		love.graphics.rectangle( "fill", (currentTileW - 1) * 25 , (currentTileH+1) * 25 , 25, 25 )
		love.graphics.rectangle( "fill", (currentTileW) * 25 , (currentTileH+1) * 25 , 25, 25 )
		love.graphics.rectangle( "fill", (currentTileW + 1) * 25 , (currentTileH+1) * 25 , 25, 25 )
		]]
		
		-- draw state of unit
		if menu.debugMode then love.graphics.print(self.state, self.x, self.y + 15) end
		
		local j = 0
		if (self.path ~= nil) then
			for i = #self.path, 1, -1 do
				love.graphics.setColor(0,255,0,50)
				love.graphics.rectangle("fill", self.path[i].x*54, self.path[i].y*54, 54, 54)
				j = j + 1
			end
		end
		
	end

		love.graphics.setColor(0,255,60, 150, 150)
		--love.graphics.rectangle( "fill", (22) * 54 , (30) * 54 , 54, 54 )
		--love.graphics.rectangle( "fill", (24) * 54 , (30) * 54 , 54, 54 )
	------------------------------- DRAW UNIT ( A CIRCLE FOR NOW )
	playerColor = {0,0,255}
	love.graphics.setColor(playerColor)
	--[[if self.color == 1 then love.graphics.setColor(255,255,23, 150) end
	love.graphics.circle("fill", self.x + self.radius, self.y + self.radius, self.radius, 15)]]--
	
	-- print tag to screen.. for debug !
	if menu.debugMode then
		love.graphics.print(self.tag, self.x, self.y + 10)
		love.graphics.print(self.x, self.x, self.y + 20)
		love.graphics.print(self.y, self.x, self.y + 30)
	end
	
	--draw sprite
	love.graphics.reset()
	self.animation:draw(self.cx,self.cy)
end

function Worker:runAwayFrom(zom_x, zom_y)
	local x_v, y_v = 0
	if (self.x < zom_x) and (self.y < zom_y) then
		x_v = zom_x - self.x
		y_v = zom_y - self.y
		self.targetAngle = math.deg( math.atan(y_v / x_v) ) + 180
	elseif (self.x > zom_x) and (self.y < zom_y) then
		x_v = self.x - zom_x
		y_v = zom_y - self.y
		self.targetAngle = math.deg( math.atan(y_v / x_v) )
		self.targetAngle = 180 - self.targetAngle + 180
	elseif (self.x > zom_x) and (self.y > zom_y) then
		x_v = self.x - zom_x
		y_v = self.y - zom_y
		self.targetAngle = math.deg( math.atan(y_v / x_v) )
		self.targetAngle = 180 + self.targetAngle + 180
	elseif (self.x < zom_x) and (self.y > zom_y) then
		x_v = zom_x - self.x
		y_v = self.y - zom_y
		self.targetAngle = math.deg( math.atan(y_v / x_v) )
		self.targetAngle = 360 - self.targetAngle + 180
	end
end

 -- look around for zombies; panic if one is around !
 function Worker:lookAround()
	
	-- for each zombie
	for i = 1, number_of_zombies do
	
			local zombie_point = Point:new(zombie_list[i].cx, zombie_list[i].cy)
			--local val = self:pTriangle(zombie_point, self.v1, self.v2, self.v3)						-- detect zombies in a triangle
			local val = self:pointInArc(self.x, self.y, zombie_point.x, zombie_point.y, 
										self.fov_radius, self.fovStartAngle, self.fovEndAngle)	-- detect humans in an arc (pie shape)
			if val == true then										-- if zombie i is in the field of view of this human
				self.state = "Running from  ".. zombie_list[i].tag
				self.panicMode = true
				if self.working == true then
					unitManager.idleWorkers = unitManager.idleWorkers + 1
					self.working = false									-- the worker is getting chased, so he is not working anymore
				end
				self.carryingResource = false							-- whether the unit was or was not carrying a resource, they drop it in order to run !
				self:runAwayFrom(zombie_list[i].x, zombie_list[i].y)

				-- reset angles if they go over 360 or if they go under 0
				if self.targetAngle > 360 then
					self.targetAngle = self.targetAngle - 360
				end
				
				if self.targetAngle < 0 then
					self.targetAngle = 360 + self.targetAngle
				end
				
			end
	end
 end
 
-- update function
function Worker:update(dt, zi)
	------------------------------- CHECK PAUSE AND ATTACKED; LOOK AROUND FOR ZOMBIES
	-- if game is paused, do not update any values
	-- if paused == true then return end
	
	-- if the worker is attacked, then he can't move (or could make him move very slow?)
	if self.attacked == 1 then return end
	
	-- updating neighbours
	self:updateNeighbours(self)
	if self.working == false then			-- don't randomize if the worker is working !
		if self.panicMode == false then
		------------------------------- RANDOMIZING DIRECTION AFTER 5 SECONDS.. unless it's controlled by penguins !
			-- after 5 seconds, the zombie should change his direction (x and y)
			if self.directionTimer > self.randomDirectionTimer then 
			
				-- randomize a degree, 0 to 360
				self.targetAngle = math.random(360)
				
				-- get the angle direction ( positive or negative on axis )
				self.dirVec = self:calcShortestDirection(self.angle, self.targetAngle)
				
				-- reset directionTimer
				self.directionTimer = 0

				self.randomDirectionTimer = math.random(7, 10)				
			end
		end
	end
	------------------------------- PANIC MODE
	-- look around for zombies
	if self.searchTimer > self.searchFreq then
		self:lookAround()
		self.searchTimer = 0
	end
	
	-- if panicZombieAngle is true.. increase speed and change targetAngle to run away from the zombie !
	if self.panicMode == true then
		
		-- change speed to panicSpeed
		self.speed = self.panicSpeed
			
		-- decrease the panicTimer
		-- self.panicTimer = self.panicTimer - dt
			
		-- while in panic mode, self.targetAngle should never change as the human is trying to run from the zombies
		--self.directionTimer = 0
			
		-- get the angle direction ( positive or negative on axis ) given the current angle and the targetAngle
		self.dirVec = self:calcShortestDirection(self.angle, self.targetAngle)
	else
		self.speed = self.normalSpeed
		self.state = "worker !"
	end
	
	------------------------------- UPDATE SELF.ANGLE
	if ((self.targetAngle - 1) < self.angle) and ((self.targetAngle + 1) > self.angle) then
		-- target has been reached, no need to change the direction vector; keep the same self.angle value !
				-- reset angles if they go over 360 or if they go under 0
		if self.angle > 360 then
			self.angle = self.angle - 360
		end
		
		if self.angle < 0 then
			self.angle = 360 + self.angle
		end
		
		------------------------------- IF THE WORKER IS WORKING ( ON A PATH )
		if self.working == true then
			if self.workingTileCount > 0 then self.turnFast = false end
			if (self.tarXTile == math.floor(self.x / map.tileSize)) and (self.tarYTile == math.floor(self.y / map.tileSize)) then
				if (#self.path == self.workingTileCount) then
					--self.working = false						-- the path of the worker should be finished by now, so the worker should be at a set location
					self:checkLocation()						-- check location and set next path of this worker
					self.working = true							-- time for worker to go to the next location.. either base or store
					self.workingTileCount = 0
					self.tarXTile = self.path[#self.path - self.workingTileCount].x 
					self.tarYTile = self.path[#self.path - self.workingTileCount].y
					self.workingTileCount = self.workingTileCount + 1
					self.targetAngle = self:angleToXY( self.x, self.y, self.tarXTile * map.tileSize + map.tileSize / 2, self.tarYTile * map.tileSize + map.tileSize / 2 )
					--self.angle = self.targetAngle
					self.dirVec = self:calcShortestDirection(self.angle, self.targetAngle)
					self.turnFast = true
				else
					self.tarXTile = self.path[#self.path - self.workingTileCount].x -- else worker is still on path to a destination..
					self.tarYTile = self.path[#self.path - self.workingTileCount].y
					self.workingTileCount = self.workingTileCount + 1
					self.targetAngle = self:angleToXY( self.x, self.y, self.tarXTile * map.tileSize + map.tileSize / 2, self.tarYTile * map.tileSize + map.tileSize / 2 )
					--self.angle = self.targetAngle
					self.dirVec = self:calcShortestDirection(self.angle, self.targetAngle)
				end
			end			
		end
		
	else
		-- every update, the unit is trying to get towards the target angle by changing its angle slowly.
		if self.dirVec == 0 then				-- positive direction	( opposite of conventional as y increases downwards )
			if self.panicMode == true or self.controlled == true then		-- if the human is panicking, he is able to turn much faster
				self.angle = self.angle + 1
			elseif self.turnFast then
				self.angle = self.angle + 1.1
			elseif self.working then
				self.angle = self.angle + 0.5
			else
				self.angle = self.angle + 0.3
			end
		elseif self.dirVec == 1 then			-- negative direction
			if self.panicMode == true or self.controlled == true then		-- if the human is panicking, he is able to turn much faster
				self.angle = self.angle - 1
			elseif self.turnFast then
				self.angle = self.angle - 1.1
			elseif self.working then
				self.angle = self.angle - 0.5
			else
				self.angle = self.angle - 0.3
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
	
		--if self.x < 0 or self.x > map.tileSize*map.width or self.y < 0 or self.y > map.tileSize*map.height then
	--	--print("tag:"..self.tag..", prevdt:"..self.prevDt..",prevdy:"..self.prevdy..",prevdx:"..self.prevdx)
	--	print("out of boundaries:"..self.tag)
	--end
	
	------------------------------------------------------------------------------ UPDATE MOVEMENT
	-- get direction vector
	self.dirVector = self:getDirection(self.angle, self.speed)
	
	if self.working == false then
		-- checking the tile that the unit is or will be on
		local next_x = self.cx + (self.radius * self:signOf(self.dirVector.x)) + (dt * self.dirVector.x)
		local next_y = self.cy + (self.radius * self:signOf(self.dirVector.y)) + (dt * self.dirVector.y)
		
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
		
		------------------------------- CHECK MAP BOUNDARIES ( # 1 )
		if next_x < 0 or next_x > map.tileSize*map.width or next_y < 0 or next_y > map.tileSize*map.height then
			self.state = "WTF"
			self.directionTimer = self.directionTimer + 5
			return
		end	
		
		local nextTileType = self:xyToTileType(next_x,next_y)
		-- check next tile (not in panic mode)
		if  not (nextTileType == "G" or nextTileType == "R" or nextTileType == "P" or nextTileType == "F") then
			self.directionTimer = self.directionTimer + dt
			--self.state = "STUCK !"
			self:avoidTile2(self, nextTileDir)
			return
		end
	
		------------------------------- CHECK MAP BOUNDARIES ( # 2 )						** IF IN PANIC MODE, MAYBE SHOULD CHECK WHERE ZOMBIE IS COMING FROM AND THEN SET THE TARGET ANGLE																														-- ** IN THE OTHER DIRECTION !
		local val = self:checkMapBoundaries(next_x,next_y, self.radius)											
		if val ~= 999 then			-- if it is too close to a boundary..
			self.angle = val
			self.targetAngle = val
			--return
		end
	end
	
	-- update worker's movement
	self.x = self.x + (dt * self.dirVector.x)
	self.y = self.y + (dt * self.dirVector.y)
	
	-- update the center x and y values of the unit
	self.cx = self.x + self.radius
	self.cy = self.y + self.radius
	-- update direction time ( after 5 seconds, the unit will randomly change direction )
	self.directionTimer = self.directionTimer + dt
	self.searchTimer = self.searchTimer + dt	
	
	--update animation
	self.animation:rotate(self.angle)
	self.animation:update(dt)
 end
 
function Worker:checkLocation()

	if ( (unitManager.baseTilePos.x == math.floor(self.x / map.tileSize) ) and (unitManager.baseTilePos.y == math.floor(self.y / map.tileSize) ) ) then
		--print("Arrived at the base ! Heading to the store..")
		infoText:addText("Gathered 1 supply")
		if (self.carryingResource == true) then
			supplies = supplies + 1				-- increase resources
		end
		self.atLocation = "Base"
		self.path = unitManager.baseToStorePath
		self.carryingResource = false
	elseif ( (unitManager.storeTilePos.x == math.floor(self.x / map.tileSize) ) and (unitManager.storeTilePos.y == math.floor(self.y / map.tileSize) ) ) then
		--print("Arrived at the store ! Heading to the base..")
		infoText:addText("Picked up 1 supply")
		self.atLocation = "Store"
		self.path = unitManager.storeToBasePath
		self.carryingResource = true
	else
		--print("In transit or lost ?")
		self.atLocation = "Other"
	end	
	
end
 -- if atLocation is at Base, self.path will be set to baseToStorePath
 -- if at... 			store ...					   storeToBasePath
 -- if at ..			Transit, then it is following a path, don't interrupt
 -- if at ..			Lost, then it needs to check if its carrying package. if it is, send to base, else send to store !
  
function Worker:sendToWork()			-- this gets called when user presses the 'gather resources' button
	
	self:checkLocation()
	if self.atLocation == "Other" then
		--print("Time to Work !")
		if self.carryingResource == true then
			--print("Got resource, going to Base !")
			self:getShortestPath(self.x,self.y,unitManager.baseTilePos.x * map.tileSize, unitManager.baseTilePos.y * map.tileSize)
		else
			--print("Got NO resource, going to Store !")
			self:getShortestPath(self.x, self.y, unitManager.storeTilePos.x * map.tileSize, unitManager.storeTilePos.y * map.tileSize)
		end
		
		if (self.path ~= nil) then
			self.working = true
			self.workingTileCount = 0
			self.tarXTile = self.path[#self.path - self.workingTileCount].x 
			self.tarYTile = self.path[#self.path - self.workingTileCount].y
			self.workingTileCount = self.workingTileCount + 1
			self.targetAngle = self:angleToXY( self.x, self.y, self.tarXTile * map.tileSize + map.tileSize / 2, self.tarYTile * map.tileSize + map.tileSize / 2 )
			--self.angle = self.targetAngle
			self.dirVec = self:calcShortestDirection(self.angle, self.targetAngle)
			self.turnFast = true
		end
	end				-- else the path is set in the self:checkLocation() function
end
