View = {}

function View:new(h, map)
	local object = {
		speed = 1000,
		height = h,
		--x = love.graphics.getWidth() / 2,
		--y = love.graphics.getHeight() / 2,
		x = 0,
		y = 0,
		
		xmin = 0,
		xmax = (map.width * map.tileSize) - love.graphics.getWidth(),
		ymin = 0,
		ymax = (map.height * map.tileSize) -  h 	
	}
	setmetatable(object, { __index = View })
	return object
end

function View:update(dt)
	-- viewpoint movement - arrow keys
	if love.keyboard.isDown("right") then
		self.x = math.clamp(self.x + dt*self.speed, 
			self.xmin, self.xmax)
	end
	if love.keyboard.isDown("left") then
		self.x = math.clamp(self.x - dt*self.speed, 
			self.xmin, self.xmax)
	end
	if love.keyboard.isDown("up") then
		self.y = math.clamp(self.y - dt*self.speed, 
			self.ymin, self.ymax)
	end
	if love.keyboard.isDown("down") then
		self.y = math.clamp(self.y + dt*self.speed, 
			self.ymin, self.ymax)
	end
	
	self.x = math.clamp(self.x, self.xmin, self.xmax)
	self.y = math.clamp(self.y, self.ymin, self.ymax)
end