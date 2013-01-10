Bullet = {}

-- Constructor
function Bullet:new(_x,_y,_angle, ranger)

    local object = {					
	id = 0,								
    x = _x,									-- x and y coordinates 
    y = _y,
	prevx = _x,
	prevy = _y,
	angle = _angle,
    state = "",
	speed = 160,
	hit = false,
	delete = false,
	lifetime = 0,
	parent = ranger,
	bloodSprite = SpriteAnimation:new("Units/images/blood1.png", 25, 32, 4, 1),
	bloodTimer = 0
	}

	setmetatable(object, { __index = Bullet})		
	
    return object
end

function Bullet:draw()
	if not self.hit then
		love.graphics.setColor(0,0,0)
		love.graphics.line(self.prevx, self.prevy, self.x, self.y)	
	else
		love.graphics.reset()
		self.bloodSprite:draw(self.x + math.cos(self.angle * (math.pi/180))*20, self.y + math.sin(self.angle * (math.pi/180))*20)
	end	
end

-- update function
function Bullet:update(dt, paused)
	if not paused then
		if (self.lifetime > 5)  and not self.hit then 
			self.delete = true
			return
		end
		
		if self.hit then
			self.bloodSprite:update(dt)
			self.bloodTimer = self.bloodTimer + dt
			if self.bloodTimer > 0.480 then
				map:drawBlood(self.x + math.cos(self.angle * (math.pi/180))*20, self.y + math.sin(self.angle * (math.pi/180))*20, self.angle)
				self.delete = true
			end
		else
			self.prevx = self.x
			self.prevy = self.y
			self.x = self.x + math.cos(self.angle * (math.pi/180))*self.speed*dt
			self.y = self.y + math.sin(self.angle * (math.pi/180))*self.speed*dt
			
			-- check if bullet hits building or blocked area
			tile = map.tiles[math.floor(self.prevx/map.tileSize)][math.floor(self.prevy/map.tileSize)]
			if (tile.id == "B") or (tile.id == "D") or (tile.id == "X") then
				self.delete = true
				return
			end
			
			-- check if any zombies are hit 
			for i = 1, number_of_zombies do
				
				if (self:distanceBetweenPoints(self.prevx, self.prevy, zombie_list[i].cx, zombie_list[i].cy) <= zombie_list[i].radius) then
					zombie_list[i]:die()
					self.parent:stopChasing()
					self.hit = true
					self.bloodSprite:load()
					self.bloodSprite:switch(1,4,120)
					self.bloodSprite:rotate(self.angle-90)
					--self.delete = true
					break
				end
			end 
		end
		self.lifetime = self.lifetime + dt
	end
end

function Bullet:distanceBetweenPoints(x1, y1, x2, y2)
	local x_v1, y_v1 = 0
	
	x_v1 = x2 - x1
	y_v1 = y2 - y1
	return math.sqrt( x_v1 * x_v1 + y_v1 * y_v1 )
end
