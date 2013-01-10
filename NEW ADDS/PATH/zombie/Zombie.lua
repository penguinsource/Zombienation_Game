Zombie = {}

-- contructor
function Zombie:new()
	local object = {
		x = 0,
		y = 0,
		width = 4,
		height = 4,
		xSpeed = 0,
		ySpeed = 0,
		speed = 100,
		maxSpeed = 125,
		move = ""
	}
	setmetatable(object, { __index = Zombie })
	return object
end

-- move
function Zombie:move()
	if move == "N" then
		self.ySpeed = -self.speed
		move = ""
	elseif move == "E" then
		self.xSpeed = self.speed
		move = ""
	elseif move == "S" then
		self.ySpeed = self.speed
		move = ""
	elseif move == "W" then
		self.xSpeed = -self.speed
		move = ""
	end
end

-- update
function Zombie:update(dt, map)
	move()

	local hX = self.width / 2
	local hY = self.height / 2
	
	-- limit player speed
	self.xSpeed = math.clamp(self.xSpeed, -self.maxSpeed, self.maxSpeed)
	self.ySpeed = math.clamp(self.ySpeed, -self.maxSpeed, self.maxSpeed)
	
	-- calc vert pos
	local nY = math.floor(self.y + (self.ySpeed * dt))
	-- check up
	if self.ySpeed < 0 then
		if not(self:isColliding(map, self.x - hX, nY - hY))
			and not (self:isColliding(map, self.x + hX - 1, nY - hY)) then
			-- no collision
			self.y = nY
		else
			-- collision - move to nearest tile border
			self.Y = nY + map.tileHeight - ((nY - hY) % map.tileHeight)
			self:collide("N")
		end
	-- check down
	elseif self.ySpeed > 0 then
		if not(self:isColliding(map, self.x - hX, nY + hY))
			and not(self:isColliding(map, self.x + hX - 1, nY + hY)) then
			-- no collision
			self.y = nY
		else
			-- collision
			self.y = nY - ((nY + hY) % map.tileHeight)
			self:collide("S")
		end
	end
	
	-- calc horiz pos
	local nX = math.floor(self.x + (self.xSpeed * dt))
	-- check right
	if self.xSpeed > 0 then
		if not(self:isColliding(map, nX + hX, self.y - hY))
			and not (self:isColliding(map, nX + hX, self.y + hY - 1)) then
			-- no collision
			self.x = nX
		else
			-- collision - move to nearest tile border
			self.x = nX - ((nX + hX) % map.tileWidth)		
			self:collide("E")
		end
	-- check left
	elseif self.xSpeed < 0 then
		if not(self:isColliding(map, nX - hX, self.y - hY))
			and not(self:isColliding(map, nX - hX, self.y + hY - 1)) then
			-- no collision
			self.x = nX
		else
			-- collision
			self.x = nX + map.tileWidth - ((nX - hX) % map.tileWidth)
			self:collide("W")
		end
	end
	
end

-- draw
function Zombie:draw()
	love.graphics.setColor(0,150,150)
	love.graphics.rectangle("fill", self.x, self.y, 
		self.x + self.width, self.y + self.height)
	love.graphics.reset()
end

-- collision
function Zombie:isColliding(map, x, y)
	-- get tile cood
	local tileX = math.floor(x / map.tileWidth)
	local tileY = math.floor(y / map.tileHeight)
	
	--  get tile at tile cood
	local tile = map("Walls")(tileX, tileY)

	return not(tile == nil)
end

-- player hits tile
function Zombie:collide(event)
	if event == "N" then
		move = "S"
	elseif event == "E" then
		move = "W"
	elseif event == "S" then
		move = "N"
	elseif event == "W" then
		move = "E"
	end	
end

