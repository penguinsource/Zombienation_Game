Building = {}

tempblock = love.graphics.newImage("map/buildings/house.png")

-- brun hice
houseN = love.graphics.newImage("map/buildings/houseN.png") -- 1x1
houseW = love.graphics.newImage("map/buildings/houseW.png")
houseS = love.graphics.newImage("map/buildings/houseS.png")
houseE = love.graphics.newImage("map/buildings/houseE.png")
-- blue hice
houseN2 = love.graphics.newImage("map/buildings/houseN2.png")
houseW2 = love.graphics.newImage("map/buildings/houseW2.png")
houseS2 = love.graphics.newImage("map/buildings/houseS2.png")
houseE2 = love.graphics.newImage("map/buildings/houseE2.png")

-- brun garages
garageN = love.graphics.newImage("map/buildings/garageN.png") -- 1x2
garageW = love.graphics.newImage("map/buildings/garageW.png") -- 2x1
garageS = love.graphics.newImage("map/buildings/garageS.png")
garageE = love.graphics.newImage("map/buildings/garageE.png")
-- blue garages
garageN2 = love.graphics.newImage("map/buildings/garageN2.png")
garageW2 = love.graphics.newImage("map/buildings/garageW2.png")
garageS2 = love.graphics.newImage("map/buildings/garageS2.png")
garageE2 = love.graphics.newImage("map/buildings/garageE2.png")

-- base
home = love.graphics.newImage("map/buildings/basecamp.png") -- 3x2

-- need minimap images

function Building:new(t_size)
	local object = {
		x = 0,
		y = 0,
		xend = 0,
		yend = 0,
		width = 0,
		height = 0,
		tileSize = t_size,
		img = nil
	}
	setmetatable(object, { __index = Building })
	return object
end

function Building:set(x, y, b_type, dir, style)
	self.x = x
	self.y = y		
	self.width = math.floor(b_type / 10)
	self.height = b_type % 10
	self.xend = x + self.width - 1
	self.yend = y + self.height - 1		
	
	local selector = ""
	
	-- get building type
	if b_type == 11 then
		selector = selector.."house"
	elseif b_type == 21 or b_type == 12 then
		selector = selector.."garage"
	elseif b_type == 32 then
		selector = "base"
	end
	
	
	-- get direction
	if not(dir == nil) then
		selector = selector..dir
	end
	
	-- get style
	if not(style == nil) then
		selector = selector..style
	end
	
	-- get img
	self.img = self:getImg(selector)
end

function Building:getImg(selector)
	-- houses
	if selector == "houseN" then
		return houseN
	elseif selector == "houseW" then
		return houseW
	elseif selector == "houseS" then
		return houseS
	elseif selector == "houseE" then
		return houseE
	elseif selector == "houseN2" then
		return houseN2
	elseif selector == "houseW2" then
		return houseW2
	elseif selector == "houseS2" then
		return houseS2
	elseif selector == "houseE2" then
		return houseE2
		
	elseif selector == "house" then
		return tempblock
		
	-- garages
	elseif selector == "garageN" then
		return garageN
	elseif selector == "garageW" then
		return garageW
	elseif selector == "garageS" then
		return garageS
	elseif selector == "garageE" then
		return garageE
	elseif selector == "garageN2" then
		return garageN2
	elseif selector == "garageW2" then
		return garageW2
	elseif selector == "garageS2" then
		return garageS2
	elseif selector == "garageE2" then
		return garageE2
	
	
	-- base
	elseif selector == "base" then
		return home
	end
end

function Building:getSprite(x, y, w)
	local xi = (x - self.x) * w
	local yi = (y - self.y) * w
	
	return love.graphics.newQuad(xi, yi, w, w, 
		self.tileSize * self.width, self.tileSize * self.height)
end