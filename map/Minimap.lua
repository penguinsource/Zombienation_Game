Minimap = {}

-- constructor
function Minimap:new(_map, _view, um, _x, _y, ww, wh)
	local object = {
		map = _map,
		view = _view,
		unitManager = um,
		x = _x,
		y = _y,
		width = 100,
		height = 100,
		winWidth = ww,
		winHeight = wh,
		camX = 0,
		camY = 0,
		canvas = 0,
		moving = false,
		visible = true		
	}
			
	setmetatable(object, { __index = Minimap })
	return object
end

function Minimap:init()
	self.canvas = love.graphics.newCanvas(self.map.width, self.map.height)
	for i = 0, self.map.width-1 do
		for j = 0, self.map.height-1 do
			love.graphics.setCanvas(self.canvas)
				love.graphics.draw(self.map.tiles[i][j].mm, i, j)
			love.graphics.setCanvas()
		end
	end
	self.winWidth = self.winWidth/self.map.tileSize
	self.winHeight = self.winHeight/self.map.tileSize
	self.width = self.map.width
	self.height = self.map.height
end

function Minimap:updateCanvas(i,j)
	love.graphics.setCanvas(self.canvas)
		love.graphics.draw(self.map.tiles[i][j].mm, i, j)
	love.graphics.setCanvas()
end

-- update the viewwindow according to the x,y coords of the camera
function Minimap:update(x,y)
	self.camX = math.floor(x/self.map.tileSize)
	self.camY = math.floor(y/self.map.tileSize)
	
	if self.moving then
		local viewX = math.clamp(love.mouse.getX() - self.x - (self.winWidth/2), view.xmin, view.xmax/map.tileSize)
		local viewY = math.clamp(love.mouse.getY() - self.y - (self.winHeight/2),  view.ymin, view.ymax/map.tileSize)
		self.view.x = viewX*self.map.tileSize
		self.view.y = viewY*self.map.tileSize
	end
end

function Minimap:mousepressed(x,y,button)
	local mouseX = love.mouse.getX() 
	local mouseY = love.mouse.getY()
	
	-- move camera to where the mouse clicked on minimap
	if (mouseX > self.x) and (mouseX < self.x + self.width) and (mouseY > self.y) and (mouseY < self.y + self.height) and love.mouse.isDown("l") then
		self.moving = true
	end
end

function Minimap:mousereleased()
	self.moving = false
end

function Minimap:infected(x,y)
end

function Minimap:showHide(bool)
	if bool then self.visible = not self.visible end
end

-- draw the minimap at x,y coord on the screen
function Minimap:draw()
	if self.visible then
		love.graphics.reset()
		love.graphics.draw(self.canvas, self.x, self.y)


		-- fix view window being out of bounds
		local drawX = self.x+self.camX
		local drawY = self.y+self.camY
		if (self.camX > (self.width-self.winWidth)) then
			drawX = self.x + self.width-self.winWidth
		end
		if (self.camY > (self.height-self.winHeight)) then
			drawY = self.y + self.height-self.winHeight
		end
		if (self.camX < 0) then
			drawX = self.x
		end
		if (self.camY < 0) then
			drawY = self.y
		end

		-- draw humans
		love.graphics.setColor(153,217,234)
		--love.graphics.setColor(50,50,255)
		for i = 1, #human_list do
			local hx = human_list[i].x / self.map.tileSize
			local hy = human_list[i].y / self.map.tileSize
			love.graphics.rectangle("fill", self.x + hx, self.y + hy,2,2)
		end

		-- draw zombies
		love.graphics.setColor(252,16,81)
		for i = 1, #zombie_list do
			local zx = zombie_list[i].x / self.map.tileSize
			local zy = zombie_list[i].y / self.map.tileSize
			love.graphics.rectangle("fill", self.x + zx, self.y + zy,2,2)
		end
		
		-- draw rangers
		love.graphics.setColor(0,255,0)
		for i = 1, #ranger_list do
			local rx = ranger_list[i].x / self.map.tileSize
			local ry = ranger_list[i].y / self.map.tileSize
			love.graphics.rectangle("fill", self.x + rx, self.y + ry,2,2)
		end
		
		-- draw workers
		love.graphics.setColor(255,242,0)
		for i = 1, #worker_list do
			local wx = worker_list[i].x / self.map.tileSize
			local wy = worker_list[i].y / self.map.tileSize
			love.graphics.rectangle("fill", self.x + wx, self.y + wy,2,2)
		end

		-- draw view window
		love.graphics.setColor(255,255,0)
		love.graphics.rectangle("line", drawX+0.5, drawY+0.5, self.winWidth-1, self.winHeight-1)
	end
end