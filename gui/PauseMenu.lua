PauseMenu = {}

--[[
Mikus:  added alpha value to menu bg color, so it can be a little bit transparent
		i think it looks cool, you can change it back if you want
]]--

-- constructor
function PauseMenu:new(_x,_y)
	local object = {
		x = _x,
		y = _y,
		visible = false,
		background = love.graphics.newImage("gui/menubg3.png")
	}	
	
	setmetatable(object, { __index = PauseMenu })
	return object
end

function PauseMenu:setup()
	bRG = love.graphics.newImage("gui/resume.png")
	bOpt = love.graphics.newImage("gui/options.png")
	bQt = love.graphics.newImage("gui/quit.png")
	bR = love.graphics.newImage("gui/restart.png")
	
	-- create buttons
	buttonResumeGame = loveframes.Create("imagebutton")
	buttonResumeGame:SetPos(self.x, self.y)
	buttonResumeGame:SetImage(bRG)
	buttonResumeGame:SizeToImage() 
	buttonResumeGame:SetVisible(false)
	buttonResumeGame.OnClick = function(object)
		gameSTATE:pauseResume(true, true)
		pauseMenu:showHide()
	end
	
	-- create buttons
	--[[buttonOptions = loveframes.Create("imagebutton")
	buttonOptions:SetPos(self.x, self.y + 35)
	buttonOptions:SetImage(bOpt)
	buttonOptions:SizeToImage() 
	buttonOptions:SetVisible(false)
	buttonOptions.OnClick = function(object)
		print("NO OPTIONS YET SON")
	end]]--
	
	-- create buttons
	buttonRestart = loveframes.Create("imagebutton")
	buttonRestart:SetPos(self.x, self.y + 35)
	buttonRestart:SetImage(bR)
	buttonRestart:SizeToImage() 
	buttonRestart:SetVisible(false)
	buttonRestart.OnClick = function(object)
		gameSTATE:pauseResume(false,true)
		minimap:showHide()
		Gamestate.switch(gameSTATE)
	end
	
	-- create buttons
	buttonQuit = loveframes.Create("imagebutton")
	buttonQuit:SetPos(self.x, self.y + 70)
	buttonQuit:SetImage(bQt)
	buttonQuit:SizeToImage() 
	buttonQuit:SetVisible(false)
	buttonQuit.OnClick = function(object)
		--map:saveMap("map/defaultMap.txt")
		gameSTATE:pauseResume(false,true)
		minimap:showHide()
		Gamestate.switch(startMenuSTATE)
	end
end

-- update menu
function PauseMenu:showHide()
	self.visible = not self.visible
	buttonResumeGame:SetVisible(not buttonResumeGame:GetVisible())
	buttonOptions:SetVisible(not buttonOptions:GetVisible())
	buttonQuit:SetVisible(not buttonQuit:GetVisible())
	buttonRestart:SetVisible(not buttonRestart:GetVisible())
end

function PauseMenu:draw()
	if self.visible then
		--love.graphics.setColor(20,20,20,100)
		--love.graphics.rectangle("fill", 0,0, width, height)
		love.graphics.draw(self.background,0,0)
	end
end

function PauseMenu: delete()
	buttonResumeGame:Remove()
	buttonOptions:Remove()
	buttonQuit:Remove()
	buttonRestart:Remove()
end
