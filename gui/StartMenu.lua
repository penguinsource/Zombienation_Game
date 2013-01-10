StartMenu = {}

--[[
Mikus:  added alpha value to menu bg color, so it can be a little bit transparent
		i think it looks cool, you can change it back if you want
]]--

-- constructor
function StartMenu:new(_x,_y)
	local object = {
		x = _x,
		y = _y,
		optionsVisible = false
	}	
	
	setmetatable(object, { __index = StartMenu })
	return object
end

function StartMenu:setup()
	bSG = love.graphics.newImage("gui/startgame.png")
	bOpt = love.graphics.newImage("gui/options.png")
	bQt = love.graphics.newImage("gui/quit.png")
	
	-- create buttons
	buttonStartGame = loveframes.Create("imagebutton")
	buttonStartGame:SetPos(self.x, self.y)
	buttonStartGame:SetImage(bSG)
	buttonStartGame:SizeToImage() 
	buttonStartGame.OnClick = function(object)
		Gamestate.switch(gameSTATE)
	end
	
	-- create buttons
	buttonOptions = loveframes.Create("imagebutton")
	buttonOptions:SetPos(self.x, self.y + 35)
	buttonOptions:SetImage(bOpt)
	buttonOptions:SizeToImage() 
	buttonOptions.OnClick = function(object)
		--print("NO OPTIONS YET SON")
		self.optionsVisible = not self.optionsVisible
	end
	
	-- create buttons
	buttonQuit = loveframes.Create("imagebutton")
	buttonQuit:SetPos(self.x, self.y + 70)
	buttonQuit:SetImage(bQt)
	buttonQuit:SizeToImage() 
	buttonQuit.OnClick = function(object)
		love.event.quit()
	end
	
		--options menu
	optionsFrame = loveframes.Create("frame")
	optionsFrame:SetName("Select Unit Counts")
	optionsFrame:SetSize(120, 160)
	optionsFrame:SetVisible(self.optionsVisible)
	optionsFrame:ShowCloseButton(false)
	optionsFrame:Center()
		
	local civText = loveframes.Create("text", optionsFrame)
	civText:SetPos(5, 32)
	civText:SetWidth(60)
	civText:SetText("Civilians:")
	
	local civilianChoice = loveframes.Create("multichoice", optionsFrame)
	civilianChoice:SetPos(65, 30)
	civilianChoice:SetWidth(45)
	for i=0, 20 do
		civilianChoice:AddChoice(i*5)
	end
	civilianChoice:SetChoice("100")
	civilianChoice.OnChoiceSelected = function(object, choice)
		orig_number_of_humans = choice
	end
	
	local workersText = loveframes.Create("text", optionsFrame)
	workersText:SetPos(5, 57)
	workersText:SetWidth(60)
	workersText:SetText("Workers:")
	
	local workerChoice = loveframes.Create("multichoice", optionsFrame)
	workerChoice:SetPos(65, 55)
	workerChoice:SetWidth(45)
	for i=0, 20 do
		workerChoice:AddChoice(i*5)
	end
	workerChoice:SetChoice("5")
	workerChoice.OnChoiceSelected = function(object, choice)
		orig_number_of_workers = choice
	end
	
	local rangersText = loveframes.Create("text", optionsFrame)
	rangersText:SetPos(5, 82)
	rangersText:SetWidth(60)
	rangersText:SetText("Rangers:")
	
	local rangerChoice = loveframes.Create("multichoice", optionsFrame)
	rangerChoice:SetPos(65, 80)
	rangerChoice:SetWidth(45)
	for i=0, 20 do
		rangerChoice:AddChoice(i*5)
	end
	rangerChoice:SetChoice("0")
	rangerChoice.OnChoiceSelected = function(object, choice)
		orig_number_of_rangers = choice
	end
	
	local zombiesText = loveframes.Create("text", optionsFrame)
	zombiesText:SetPos(5, 107)
	zombiesText:SetWidth(60)
	zombiesText:SetText("Zombies:")
	
	local zombieChoice = loveframes.Create("multichoice", optionsFrame)
	zombieChoice:SetPos(65, 105)
	zombieChoice:SetWidth(45)
	for i=0, 20 do
		zombieChoice:AddChoice(i*2)
	end
	zombieChoice:SetChoice("2")
	zombieChoice.OnChoiceSelected = function(object, choice)
		orig_number_of_zombies = choice
	end
	
	local regenMapBtn = loveframes.Create("button", optionsFrame)
	regenMapBtn:SetSize(109, 20)
	regenMapBtn:SetPos(5, 135)
	regenMapBtn:SetText("Regenerate Map")
	regenMapBtn.OnClick = function(object)
		print("")
		generator:randomMap()
		map = generator:getMap()
		view = View:new(viewHeight, map)
		minimap = Minimap:new(map, view, unitManager, width - map.width - 7, height - map.height - 8, width, height)
		minimap:init()
		map:setMinimap(minimap)
	end
end	

-- update menu
function StartMenu:update()
	optionsFrame:SetVisible(self.optionsVisible)
end

function StartMenu: delete()
	buttonStartGame:Remove()
	buttonOptions:Remove()
	buttonQuit:Remove()
	optionsFrame:Remove()
end
