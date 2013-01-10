require "Units/Bullet"

Ranger = {}
Ranger_mt = { __index = Ranger }

-- Constructor
function Ranger:new(xnew,ynew)

    local new_object = {					-- define our parameters here
	tag = 0,								-- tag of unit
    x = xnew,									-- x and y coordinates ( by default, left top )
    y = ynew,
	cx = 0,									-- centered x and y coordinates of the unit
	cy = 0,
	radius = 4,
	angle = math.random(360),				-- randomize initial angles
	targetAngle = math.random(360),
    width = 0,
    height = 0,
    state = "",
	statestr = "",
	speed = 0,
	normalSpeed = 15,
	huntingSpeed = 17,
	huntee = nil,
    runSpeed = 0,
	directionTimer = 0,
	zombieCheckTimer = 0,						-- if hunting a zombie, check for other zombies every once in a while (probably once a sec, less comp expensive)
	searchTimer = 0,							-- timer, whenc it reachers searchFreq, human looksAround
	searchFreq = 0.25,							-- intervals at which to lookAround
	initial_direction = 1,
	fov_radius = 150,
	fov_angle = 150,
	fovStartAngle = 0,
	fovEndAngle = 0,
	attacked = 0,								-- if the unit is currently attacked, this var = 1
	shootingTimer = 0,								-- reload time (pretend he's using a hunting rifle)
	interval = 0,									-- interval of time before unit changes angle (randomized every time)
	v1 = Point:new(0,0),							-- vertices for the field of view triangle
	v2 = Point:new(0,0),
	v3 = Point:new(0,0),
	selected = false,
	color = 0,
	controlled = false,
	onCurrentTile = 0,
	neighbourTiles = {},
	bullets = {},
	targetX = -1,
	targetY = -1,
	tilesCrossed = 0,
	turnFast = false,
	animation = SpriteAnimation:new("Units/images/ranger1.png", 10, 12, 8, 1),
	randomDirectionTimer = math.random(7, 10)
	}

	setmetatable(new_object, Ranger_mt )				-- add the new_object to metatable of Ranger
	setmetatable(Ranger, { __index = Unit })        -- Ranger is a subclass of class Unit, so set inheritance..				
	
    return new_object
end

function Ranger:setupUnit()

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
	

	
	self.fovStartAngle = self.angle - self.angle/2
	self.fovEndAngle = self.angle + self.angle/2
	
	self.state = "seeking"
	self.statestr = "seeking"
	self.huntee = nil
	self.speed = self.normalSpeed
	--self.tag = ranger_tag
	self.tag = unitTag
	self.directionTimer = 0
	self.checkZombieTimer = 0
	self.shootingTimer = 1
	self.searchingTimer = 0
	
	self.interval = math.random(3,7)
	
	self.animation:load()
	self.animation:switch(1,8,120)
end

function Ranger:draw(i)
	
	------------------------------- UPDATE FIELD OF VIEW VERTICES
	-- for triangle:
	--self.v1 = Point:new(self.x + self.radius, self.y + self.radius)
	--self.v2 = Point:new(self.x + math.cos( (self.angle - 70) * (math.pi/180) )*180 + self.radius, self.y + math.sin( (self.angle - 70) * (math.pi/180) )*180 + self.radius)
	--self.v3 = Point:new(self.x + math.cos( (self.angle + 70 ) * (math.pi/180) )*180 + self.radius, self.y + math.sin( (self.angle + 70) * (math.pi/180) )*180 + self.radius)
	-- for arc:
	self.fovStartAngle = self.angle - self.angle/2
	self.fovEndAngle = self.angle + self.angle/2
	------------------------------- IF UNIT IS SELECTED.. DRAW:
	if self.selected then
		love.graphics.setColor(0,255,0,50)
		-- draw triangle field of view
		--[[love.graphics.triangle( "fill", 
			self.v1.x,self.v1.y,
			self.v2.x,self.v2.y,
			self.v3.x,self.v3.y
		)]]
		
		-- draw the arc field of view
		love.graphics.arc( "fill", self.x + self.radius, self.y + self.radius, self.fov_radius, math.rad(self.angle + self.fov_angle/2), math.rad(self.angle - self.fov_angle/2) )
		
		-- draw line for angle and targetAngle
		if menu.debugMode then
			love.graphics.line(self.x + self.radius,self.y + self.radius, 
								self.x + math.cos(self.angle * (math.pi/180))* 30 + self.radius , 
								self.y + math.sin(self.angle * (math.pi/180))* 30 + self.radius)
			love.graphics.setColor(255,0,0)
			love.graphics.line(self.x + self.radius,self.y + self.radius, 
								self.x + math.cos(self.targetAngle * (math.pi/180))*30 + self.radius , 
								self.y + math.sin(self.targetAngle * (math.pi/180))* 30 + self.radius)
		end
			
		-- draw circle around selected unit
		love.graphics.setColor(0,255,0, 150)
		love.graphics.circle( "line", self.x + self.radius, self.y + self.radius, 5, 15 )
		love.graphics.circle( "line", self.x + self.radius, self.y + self.radius, 6, 15 )
		
		
		--love.graphics.rectangle()
		--love.graphics.rectangle( "fill", 0, 0, 25, 25 )
		
		
		-- draw state of unit
		if menu.debugMode then love.graphics.print(self.statestr, self.x, self.y + 15) end
		
		local j = 0
		if (self.path ~= nil) and self.state == "moving" then
			love.graphics.setColor(0,255,0,50)
			for i = #self.path, 1, -1 do				
				love.graphics.rectangle("fill", self.path[i].x*54, self.path[i].y*54, 54, 54)
				j = j + 1
			end
		end
		
	end
	
	------------------------------- DRAW UNIT ( A CIRCLE FOR NOW )
	playerColor = {0,255,0}
	love.graphics.setColor(playerColor)
	--if self.color == 1 then love.graphics.setColor(255,255,23, 150) end
	--love.graphics.circle("fill", self.x + self.radius, self.y + self.radius, self.radius, 15)
	
	-- print tag to screen.. for debug !
	if menu.debugMode then love.graphics.print(self.tag, self.x, self.y + 10) end

	-- draw bullets
	for i,_ in pairs(self.bullets) do
		self.bullets[i]:draw()
	end
	
	--draw sprite
	love.graphics.reset()
	self.animation:draw(self.cx,self.cy)
end

--ranja dont run like no pussy
function Ranger:hunt(zom_x, zom_y)
	local x_v, y_v = 0
	if (self.cx < zom_x) and (self.cy < zom_y) then
		x_v = zom_x - self.cx
		y_v = zom_y - self.cy
		self.targetAngle = math.deg( math.atan(y_v / x_v) ) --+ 180
	elseif (self.cx > zom_x) and (self.cy < zom_y) then
		x_v = self.cx - zom_x
		y_v = zom_y - self.cy
		self.targetAngle = math.deg( math.atan(y_v / x_v) )
		self.targetAngle = 180 - self.targetAngle --+ 180
	elseif (self.cx > zom_x) and (self.cy > zom_y) then
		x_v = self.cx - zom_x
		y_v = self.cy - zom_y
		self.targetAngle = math.deg( math.atan(y_v / x_v) )
		self.targetAngle = 180 + self.targetAngle --+ 180
	elseif (self.cx < zom_x) and (self.cy > zom_y) then
		x_v = zom_x - self.cx
		y_v = self.cy - zom_y
		self.targetAngle = math.deg( math.atan(y_v / x_v) )
		self.targetAngle = 360 - self.targetAngle --+ 180
	end
end

 -- look around for zombies; hunt if one is around !
 function Ranger:lookAround() 
	local distToHuntee = 9999
	if not(self.huntee == nil) then distToHuntee = self:distanceBetweenPoints(self.cx,self.cy,self.huntee.cx, self.huntee.cy) end
	local ztag = -1
	if not (self.huntee == nil) then ztag = self.huntee.tag end
	
	-- for each zombie
	for i = 1, number_of_zombies do		
		if ztag ~= zombie_list[i].tag then		
			local distToCurrZomb = self:distanceBetweenPoints(self.cx,self.cy,zombie_list[i].cx, zombie_list[i].cy)		-- redundant but i have no choice 
			local val = self:pointInArc(self.cx, self.cy, zombie_list[i].cx, zombie_list[i].cy, 
										self.fov_radius, self.fovStartAngle, self.fovEndAngle)	-- detect zomvies in an arc (pie shape)
			if val and (distToCurrZomb < distToHuntee) and self:inLineOfSight(zombie_list[i].cx, zombie_list[i].cy) then				-- if zombie i is in the field of view of this Ranger
				self.statestr = "Hunting  ".. zombie_list[i].tag								-- and it's closer than the currently chased zombie
				self.state = "hunting"
				self.huntee = zombie_list[i]
				self:hunt(self.huntee.cx, self.huntee.cy)
				self.turnFast = true
				
				-- reset angles if they go over 360 or if they go under 0
				if self.targetAngle > 360 then
					self.targetAngle = self.targetAngle - 360
				end
				
				if self.targetAngle < 0 then
					self.targetAngle = 360 + self.targetAngle
				end
				break
			end
		end
	end
 end
 
-- update function
function Ranger:update(dt, zi)
	-- update bullets
	for i,_ in pairs(self.bullets) do
		self.bullets[i]:update(dt, paused)
		if self.bullets[i].delete then
			table.remove(self.bullets, i)
		end
	end
	

	-- check if the zombie youre hunting or shooting is dead
	if not (self.huntee == nil) then
		if self.huntee.delete then 
			self.state = "seeking"
			self.statestr = "seeking"
			self.huntee = nil
		end
	end
	------------------------------- CHECK PAUSE AND ATTACKED; LOOK AROUND FOR ZOMBIES
	-- if game is paused, do not update any values
	-- if paused == true then return end
	
	-- if the Ranger is attacked, then he can't move (or could make him move very slow?)
	if self.attacked == 1 then return end
	
	--updating neighbours
	self:updateNeighbours(self)
	
	-- get the angle direction ( positive or negative on axis )
	self.dirVec = self:calcShortestDirection(self.angle, self.targetAngle)
	
	if (self.state == "seeking") or (self.state == "moving")then
	------------------------------- RANDOMIZING DIRECTION AFTER 5 SECONDS.. unless it's controlled by penguins !
		-- after 'interval' seconds, the ranger should change his direction (x and y)
		if self.directionTimer > self.interval and self.state == "seeking" then 
		
			-- randomize a degree, 0 to 360
			self.targetAngle = math.random(360)
						
			-- reset directionTimer
			self.directionTimer = 0	

			-- randomize interval again
			self.interval = math.random(3,7)
		end
		
		-- look around for zombies
		if self.searchTimer > self.searchFreq then
			self:lookAround()				
			self.searchTimer = 0
		end
	end
	
	
	
	------------------------------- HUNTING MODE
	-- if panicZombieAngle is true.. increase speed and change targetAngle to run away from the zombie !
	if self.state == "hunting" then
		-- check if there are any other closer zombies every 1 sec
		if self.zombieCheckTimer > 1 then
			self:lookAround()									-- look around for more zombies
			if self:checkLOS() then return end					-- check if the current huntee got out yo sight
			self.zombieCheckTimer = 0
		end
		
		-- check if zombie's close enough to shoot
		if (self:distanceBetweenPoints(self.cx,self.cy,self.huntee.cx,self.huntee.cy) < self.fov_radius *4/5) then 
			self.state = "shooting"
			self.statestr = "shooting " ..self.huntee.tag
			self.shootingTimer = 1.5
			self.animation:stop()
		else 
			self:hunt(self.huntee.cx, self.huntee.cy)
			-- change speed to huntingSpeed
			self.speed = self.huntingSpeed
				
			-- decrease the panicTimer
			-- self.panicTimer = self.panicTimer - dt
				
			-- while in panic mode, self.targetAngle should never change as the Ranger is trying to run from the zombies
			--self.directionTimer = 0
				
			-- get the angle direction ( positive or negative on axis ) given the current angle and the targetAngle
			self.dirVec = self:calcShortestDirection(self.angle, self.targetAngle)
		end
	elseif self.state == "seeking" then
		self.speed = self.normalSpeed				
	end
	
	-- check which tiles to go on in order to avoid buildings, water, etc
	--self:checkTiles()
	
	
	
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
		
		if self.state == "moving" then
			if (self.path ~= nil) then
				if self.tilesCrossed > 0 then self.turnFast = false end
				if (self.targetX == math.floor(self.x / map.tileSize)) and (self.targetY == math.floor(self.y / map.tileSize)) then
					
					if (#self.path == self.tilesCrossed) then
						self.state = "seeking"
						self.huntee = nil
					else
						self.targetX = self.path[#self.path - self.tilesCrossed].x 
						self.targetY = self.path[#self.path - self.tilesCrossed].y
						self.tilesCrossed = self.tilesCrossed + 1
						self.targetAngle = self:angleToXY( self.x, self.y, self.targetX * map.tileSize + map.tileSize / 2, self.targetY * map.tileSize + map.tileSize / 2 )
						--self.angle = self.targetAngle
						self.dirVec = self:calcShortestDirection(self.angle, self.targetAngle)
					end
				end
			else 
				self.state = "seeking"
			end
		end
	else
		-- every update, the unit is trying to get towards the target angle by changing its angle slowly.
		if self.dirVec == 0 then				-- positive direction	( opposite of conventional as y increases downwards )
			if self.state == "hunting" or self.state == "shooting" or self.turnFast then		-- if the Ranger is hunting or shooting, he is able to turn much faster
				self.angle = self.angle + 1.1
			elseif self.state == "moving" then
				self.angle = self.angle + 0.5
			else
				self.angle = self.angle + 0.3
			end
		elseif self.dirVec == 1 then			-- negative direction
			if self.state == "hunting" or self.state == "shooting" or self.turnFast then		-- if the Ranger is hunting or shooting, he is able to turn much faster
				self.angle = self.angle - 1.1
			elseif self.state == "moving" then
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
	if not(self.state == "shooting") then	-- only move if not shooting
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
			--self.state = "WTF"
			--self.statestr = "WTF"
			self.directionTimer = self.directionTimer + 5
			return
		end	
		
		local nextTileType = self:xyToTileType(next_x,next_y)
		-- check next tile (not in panic mode)
		if  not (nextTileType == "G" or nextTileType == "R" or nextTileType == "F" or nextTileType == "P") then
			self.directionTimer = 0
			--self.state = "STUCK !"
			--self.statestr = "STUCK !"
			--self:avoidTile(self)
			self:avoidTile2(self, nextTileDir)
			return
		end
		
		------------------------------- CHECK MAP BOUNDARIES 	
		if next_x < 0 or next_x > map.tileSize*map.width or next_y < 0 or next_y > map.tileSize*map.height then
			--self.state = "WTF"
			--self.statestr = "WTF"
			self.directionTimer = self.directionTimer + dt
			return
		end																															-- ** IN THE OTHER DIRECTION !
		local val = self:checkMapBoundaries(next_x,next_y, self.radius)											
		if val ~= 999 then			-- if it is too close to a boundary..
			self.angle = val
			self.targetAngle = val
			--return
		end
		------------------------------- END OF BOUNDARY CHECK
		
		-- update Ranger's movement
		self.x = self.x + (dt * self.dirVector.x)
		self.y = self.y + (dt * self.dirVector.y)
		
		-- update the center x and y values of the unit
		self.cx = self.x + self.radius
		self.cy = self.y + self.radius
	elseif (self.state == "shooting") then 
	------------------------------SHOOTING MODE
		-- check if there are any other closer zombies every 1 sec
		if self.zombieCheckTimer > 1 then
			self:lookAround()						-- look around for more zombies
			if self:checkLOS() then return end		-- check if the current huntee got out yo sight
			self.zombieCheckTimer = 0
		end
	
		-- if zombie got out of range, go back to hunting him
		if (self:distanceBetweenPoints(self.cx,self.cy,self.huntee.cx,self.huntee.cy) > self.fov_radius) then
			self.state = "hunting"
			self.statestr = "hunting " ..self.huntee.tag
			self.animation:start()
		else
			self:hunt(self.huntee.cx, self.huntee.cy)
			if self.shootingTimer > 2 then
				self:shoot()
				self.shootingTimer = 0
			end
		end
	end
	-- update timers
	self.directionTimer = self.directionTimer + dt
	self.zombieCheckTimer = self.zombieCheckTimer + dt
	if self.state == "shooting" then self.shootingTimer = self.shootingTimer + dt end	-- only increment shooting timer if youre shooting
	self.searchTimer = self.searchTimer + dt	
	
	--update animation
	self.animation:rotate(self.angle)
	self.animation:update(dt)
 end

-- if huntee not in line of sight, follow shortest path to his last seen location
function Ranger:checkLOS()
	if not self:inLineOfSight(self.huntee.cx, self.huntee.cy) then
		if self:getShortestPath(self.cx,self.cy,self.huntee.cx, self.huntee.cy) then self:patrol() return true end
	end
	
	return false
end 
 
function Ranger:shoot()
	local bulletAngle = self:angleToXY(self.cx,self.cy,self.huntee.cx,self.huntee.cy)
	local newBullet = Bullet:new(self.cx, self.cy, self.targetAngle, self)
	table.insert(self.bullets, newBullet)
end

function Ranger:stopChasing()
	self.huntee = nil
	self.state = "seeking"
	self.statestr = "seeking"
	self.shootingTimer = 0
	self.animation:start()
end

function Ranger:patrol()
	if (self.path ~= nil) then
		self.state = "moving"
		self.huntee = nil
		self.tilesCrossed = 0
		
		self.targetX = self.path[#self.path - self.tilesCrossed].x 
		self.targetY = self.path[#self.path - self.tilesCrossed].y
		self.tilesCrossed = self.tilesCrossed + 1
		self.targetAngle = self:angleToXY( self.x, self.y, self.targetX * map.tileSize + map.tileSize / 2, self.targetY * map.tileSize + map.tileSize / 2 )
		--self.angle = self.targetAngle
		self.dirVec = self:calcShortestDirection(self.angle, self.targetAngle)
		self.turnFast = true
	end

end