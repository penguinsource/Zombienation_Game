Button = {}

-- constructor (x_start, y_start, width, height, text)
function Button:new(xs, ys, w, h, t)
	local object = {
		x = xs,
		y = ys,
		width = w,
		height = h,
		text = t,
		
		lineColor = {255,255,255}, -- unselected option
		fillColor = {200,0,0},		-- default button color
		textColor = {0,0,0}			-- default
	}
	setmetatable(object, { __index = Button })
	return object
end

-- draw button
function Button:draw()
	-- draw fill
	love.graphics.setColor(self.fillColor)
	love.graphics.rectangle("fill", self.x, self.y, 
		self.width, self.height)
	
	-- draw outline
	love.graphics.setColor(self.lineColor)
	love.graphics.rectangle("line", self.x, self.y,
		self.width, self.height)	
	
	-- add text
	love.graphics.setColor(self.textColor)
	love.graphics.print(self.text, self.x + 10, 
		self.y + (self.height / 4))
	
	love.graphics.reset()

end

-- clicked
