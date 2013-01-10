Menu = {}

-- constructor
function Menu:new(baseX, w, h)
	local object = {
		xs = baseX,
		ys = 0,
		width = w,
		height = h,
		xe = baseX + w,
		ye = h
	}
	setmetatable(object, { __index = Menu })
	return object
end

-- draw the menu
function Menu:draw()
	love.graphics.setColor(0,200,0)
	love.graphics.rectangle("fill", self.xs, self.ys, self.xe, self.ye)
		
	love.graphics.setColor(0,0,200)
	love.graphics.rectangle("line", self.xs, self.ys, self.xe, self.ye)
		
	love.graphics.reset()
end
