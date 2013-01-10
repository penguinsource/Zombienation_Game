InfoText = {}
Text = {}

-- text Constructor
function Text:new(_data)
	local object = {
		lifeTime = 0,
		alpha = 255,
		fadeAt = 2.5,
		fadeSpeed = 100,
		data = _data
	}

	setmetatable(object, { __index = InfoText})		
	
    return object
end

-- Container Constructor
function InfoText:new(_x,_y)

    local object = {
		x = _x,
		y = _y,
		texts = {}
	}

	setmetatable(object, { __index = InfoText})		
	
    return object
end

function InfoText:draw()
	for i = #self.texts, 1, -1 do
		v = self.texts[i]
		love.graphics.setColor(255,255,255,v.alpha)
		love.graphics.printf( v.data, self.x, self.y-(#self.texts-i)*17, width-7, "right")
		--love.graphics.printf( "test", 0, 300, width-7, "right")
	end
end

-- update function
function InfoText:update(dt, paused)
	for i,v in pairs(self.texts) do
		v.lifeTime = v.lifeTime + dt
		if v.lifeTime > v.fadeAt then
			v.alpha = v.alpha - dt*v.fadeSpeed
		end
		if v.alpha <= 0 then
			table.remove(self.texts, i)
		end
	end
end

function InfoText:addText(_string)
	newText = Text:new(_string)
	table.insert(self.texts, newText)
end

function InfoText:reset()
	self.texts = {}
end