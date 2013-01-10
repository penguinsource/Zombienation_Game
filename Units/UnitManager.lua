require "Units/Unit"
require "Units/Zombie"
require "Units/Human"
require "Units/Ranger"
require "Units/Worker"
require "Units/SpriteAnimation"

UnitManager = {}
UnitManager_mt = { __index = UnitManager }

humans_selected = 0
zombies_selected = 0
rangers_selected = 0
workers_selected = 0


	--[[ 

	-> each unit has a unique tag. When zombies chase a unit, they chase them by the tag (eg. human_tag)
	-> number_of_"unit_type" keeps track of all the alive units of that type. They are also the upper limit of the array "unit_type"_list
	
  ]]
  
-- Constructor
function UnitManager:new()
    -- define our parameters here
    local new_object = {
	paused = false,
	RangerCost = 10,
	baseTilePos = nil,
	storeTilePos = nil,
	storeToBasePath = {},
	baseToStorePath = {},
	idleWorkers = 0,
	supplyTimer = 0
    }
    setmetatable(new_object, UnitManager_mt )
    return new_object
end

function UnitManager:initUnits()
	--infoText:addText("Initiating units.. ")
	--[[for i = 0, map.width - 1 do
		for j = 0, map.height - 1 do
			print(map.tiles[i][j].id.." ")
		end
	end--]]
	--[[print(map.tiles[0][0].id)
	print(map.tiles[10][13].id)
	print(map.tiles[10][14].id)
	print(map.tiles[10][15].id)
	print(map.tiles[10][16].id)
	print(map.tiles[10][17].id)
	print(map.tiles[10][18].id)]]
	unitTag = 1
	zombie_list = {}							-- array of zombie objects
	human_list = {}								-- array of human objects
	ranger_list = {}								-- array of ranger objects
	worker_list = {}
	number_of_zombies = orig_number_of_zombies			-- zombies are red
	number_of_humans = orig_number_of_humans			-- humans are blue
	number_of_rangers = orig_number_of_rangers			-- humans are blue
	number_of_workers = orig_number_of_workers			-- 
	self.idleWorkers = number_of_workers
	number_of_cars = orig_number_of_cars
	
	-- set up zombies
	for i = 1, number_of_zombies do
		zombie_list[i] = Zombie:new()
		zombie_list[i]:setupUnit()
		unitTag = unitTag + 1
	end
	
	-- set up humans
	for i = 1, number_of_humans do
		human_list[i] = Human:new()
		human_list[i]:setupUnit()
		unitTag = unitTag + 1
		--human_tag = human_tag + 1
	end	
	
	-- only setup rangers at start for testing
	for i = 1, number_of_rangers do
		ranger_list[i] = Ranger:new()
		ranger_list[i]:setupUnit()
		unitTag = unitTag + 1
		--ranger_tag = ranger_tag + 1
	end	
	
	for i = 1, number_of_workers do
		worker_list[i] = Worker:new()
		worker_list[i]:setupUnit()
		unitTag = unitTag + 1
		--worker_tag = worker_tag + 1
	end
	
	self.baseTilePos = map.baseTilePt
	self.storeTilePos = map.storeTilePt
	
	-- get shortest paths from store to base and from base to store and store the 2 lists
	self.storeToBasePath = astar:findPath(self.storeTilePos.x, self.storeTilePos.y, self.baseTilePos.x, self.baseTilePos.y)
	self.baseToStorePath = astar:findPath(self.baseTilePos.x, self.baseTilePos.y, self.storeTilePos.x, self.storeTilePos.y)
	--[[
	for i = 1, number_of_cars do
		car_list[i] = Car:new()
		car_list[i]:setupUnit()
		worker_tag = worker_tag + 1
	end]]
	
end

-- gets the idle worker (if any) that is the closest to your current screen view
function UnitManager:getClosestIdleWorker()
	local unitRet = nil
	local closestDist = nil
	
	for i,v in pairs(worker_list) do
		if v.working == false then
			local distance = Unit:distanceBetweenPoints( (view.x + width / 2), (view.y + height / 2), v.x, v.y )
			if distance ~= nil then
				if closestDist == nil then 
						unitRet = v 
						closestDist = distance
				end
				if distance < closestDist then
					closestDist = distance
					unitRet = v
				end
			end
		end
	end

	if unitRet ~= nil then
		local pt = Point:new(unitRet.x, unitRet.y)
		return pt
	else
		return Point:new(view.x + width / 2, view.y + height / 2)
	end
end

-- gets the idle worker (if any) that is the closest to your current screen view
function UnitManager:getClosestWorker(posa, other)
	local unitRet = nil
	local closestDist = nil
	
	for i,v in pairs(worker_list) do
		local distance = nil
		if other == "zombie" then
			distance = Unit:distanceBetweenPoints( posa.x, posa.y, v.x, v.y )
		else
			distance = Unit:distanceBetweenPoints( (view.x + width / 2), (view.y + height / 2), v.x, v.y )
		end
		
		if distance ~= nil then
			if closestDist == nil then 
					unitRet = v 
					closestDist = distance
			end
			if distance < closestDist then
				closestDist = distance
				unitRet = v
			end
		end
	end
	
	if unitRet ~= nil then
		local pt = Point:new(unitRet.x, unitRet.y)
		if other == "zombie" then
			return closestDist, unitRet
		end
		return pt
	else
		if other == "zombie" then
			return 9999
		end
		return Point:new(view.x + width / 2, view.y + height / 2)
	end
end

-- gets the ranger (if any) that is the closest to your current screen view
function UnitManager:getClosestRanger(posa, other)
	local unitRet = nil
	local closestDist = nil
	
	for i,v in pairs(ranger_list) do
		local distance = nil
		if other == "zombie" then
			distance = Unit:distanceBetweenPoints( posa.x, posa.y, v.x, v.y )
		else
			distance = Unit:distanceBetweenPoints( (view.x + width / 2), (view.y + height / 2), v.x, v.y )
		end
		
		if distance ~= nil then
			if closestDist == nil then 
					unitRet = v 
					closestDist = distance
			end
			if distance < closestDist then
				closestDist = distance
				unitRet = v
			end
		end
	end
	
	if unitRet ~= nil then
		local pt = Point:new(unitRet.x, unitRet.y)
		if other == "zombie" then
			return closestDist, unitRet
		end
		return pt
	else
		if other == "zombie" then
			return 9999
		end
		return Point:new(view.x + width / 2, view.y + height / 2)
	end
end

-- gets the human (if any) that is the closest to your current screen view
function UnitManager:getClosestCivilian(posa, other)
	local unitRet = nil
	local closestDist = nil
	
	for i,v in pairs(human_list) do
		local distance = nil
		if other == "zombie" then
			distance = Unit:distanceBetweenPoints( posa.x, posa.y, v.x, v.y )
		else
			distance = Unit:distanceBetweenPoints( (view.x + width / 2), (view.y + height / 2), v.x, v.y )
		end
		if distance ~= nil then
			if closestDist == nil then 
					unitRet = v 
					closestDist = distance
			end
			if distance < closestDist then
				closestDist = distance
				unitRet = v
			end
		end
	end
	
	if unitRet ~= nil then
		local pt = Point:new(unitRet.x, unitRet.y)
		if other == "zombie" then
			return closestDist, unitRet
		end
		return pt
	else
		if other == "zombie" then
			return 9999
		end
		return Point:new(view.x + width / 2, view.y + height / 2)
	end
end

function UnitManager:getClosestHuman(unitPos)
	local cdist1, p1 = self:getClosestWorker(unitPos, "zombie")
	local cdist2, p2 = self:getClosestRanger(unitPos, "zombie")
	local cdist3, p3 = self:getClosestCivilian(unitPos, "zombie")
	local cdist = cdist1
	local p = p1
	if cdist2 < cdist then
		cdist = cdist2
		p = p2
	end
	if cdist3 < cdist then
		cdist = cdist3
		p = p3
	end
	
	if cdist < 9990 then
		return p				-- return closest human unit
	else return nil end
end

function UnitManager:resetUnits()
	print("RESETTING UNITS !")
	-- remove all units from tables
	for k in pairs (zombie_list) do
		zombie_list [k] = nil
	end
	for k in pairs (human_list) do
		human_list [k] = nil
	end
	for k in pairs (ranger_list) do
		ranger_list [k] = nil
	end
	for k in pairs (worker_list) do
		worker_list [k] = nil
	end
	-- reset counters and tags
	number_of_humans = 1
	number_of_zombies = 1
	number_of_rangers = 1
	number_of_workers = 1
	--zombie_tag = 1
	--human_tag = 1
	--ranger_tag = 1
	--worker_tag = 1
	unitTag = 1
	-- re init units
	self:initUnits()
	--print("humans".. #human_list)
	--print("zombies".. #zombie_list)
end

function UnitManager:pauseGame()
	if self.paused == true then
		self.paused = false
		infoText:addText("Game Resumed")
	else
		self.paused = true
		infoText:addText("Game Paused")
	end
end

-- Update function
function UnitManager:update(dt, gravity)
	--check if user won/lost
	if number_of_humans <= 0 and number_of_rangers <= 0 and number_of_workers <= 0 then Gamestate.switch(loseSTATE) end
	if number_of_zombies <= 0 then Gamestate.switch(winSTATE) end
	
	if self.paused == false then		-- IF THE GAME IS NOT PAUSED..
		-- every minute, the user receives 1 supply IF the game is not paused !
		if self.supplyTimer > 60 then
			supplies = supplies + 1
			infoText:addText("Additional supply has arrived ( + 1 )")
			self.supplyTimer = 0
		else
			self.supplyTimer = self.supplyTimer + dt
		end
		-- update the unit's position
		
		-- update zombies
		for i = 1, number_of_zombies do
			zombie_list[i]:update(dt, i)
			--zombie_list[i].animation:update(dt)
		end
		-- update humans
		for i = 1, number_of_humans do
			human_list[i]:update(dt,i)
		end
		-- update rangers
		for i = 1, number_of_rangers do
			ranger_list[i]:update(dt,i)
		end
		-- update workers
		for i = 1, number_of_workers do
			worker_list[i]:update(dt,i)
		end
	
		-- check if zombies need to be deleted (needs to be done separate from updating units otherwise 'it messed things up')
		for i,v in pairs(zombie_list) do
			if v.delete then
				table.remove(zombie_list, i)
				number_of_zombies = number_of_zombies - 1
			end
		end
	end
end

function UnitManager:draw()
	
	-- draw zombies
	for i = 1, number_of_zombies do
		zombie_list[i]:draw(i)
		--zombie_list[i].animation:draw(zombie_list[i].x, zombie_list[i].y)
	end
	
	-- draw humans
	for i = 1, number_of_humans do
		human_list[i]:draw(i)
	end
	
	-- draw rangers
	for i = 1, number_of_rangers do
		ranger_list[i]:draw(i)
	end
	
	-- draw workers
	for i = 1, number_of_workers do
		worker_list[i]:draw(i)
	end
	
	love.graphics.setColor(0,255,0)
	love.graphics.rectangle("fill", self.baseTilePos.x*54, self.baseTilePos.y*54, 54, 54)
	love.graphics.rectangle("fill", self.storeTilePos.x*54, self.storeTilePos.y*54, 54, 54)

end

function UnitManager:selectUnits(x1,y1,x2,y2)
	-- get the max y and x coords
	--if not x1
	self:deselectUnits()
	local max_x = 0
	local min_x = 0
	if x1 < x2 then
		max_x = x2
		min_x = x1
	else
		max_x = x1
		min_x = x2
	end
	
	local max_y = 0
	local min_y = 0
		if y1 < y2 then
		max_y = y2
		min_y = y1
	else
		max_y = y1
		min_y = y2
	end

	for i = 1, number_of_humans do
		if ( ( human_list[i].cx > min_x ) and ( human_list[i].cx < max_x )
			and ( human_list[i].cy > min_y ) and ( human_list[i].cy < max_y ) ) then
			
			human_list[i].selected = true	-- set the selected value to true
			humans_selected = humans_selected + 1
		end
	end
	
	for i = 1, number_of_zombies do
		if ( ( zombie_list[i].cx > min_x ) and ( zombie_list[i].cx < max_x )
			and ( zombie_list[i].cy > min_y ) and ( zombie_list[i].cy < max_y ) ) then
			
			zombie_list[i].selected = true	-- set the selected value to true
			zombies_selected = zombies_selected + 1
		end
	end
	
	for i = 1, number_of_rangers do
		if ( ( ranger_list[i].cx > min_x ) and ( ranger_list[i].cx < max_x )
			and ( ranger_list[i].cy > min_y ) and ( ranger_list[i].cy < max_y ) ) then
			
			ranger_list[i].selected = true	-- set the selected value to true
			rangers_selected = rangers_selected + 1
		end
	end
	
	for i = 1, number_of_workers do
		if ( ( worker_list[i].cx > min_x ) and ( worker_list[i].cx < max_x )
			and ( worker_list[i].cy > min_y ) and ( worker_list[i].cy < max_y ) ) then
			
			worker_list[i].selected = true	-- set the selected value to true
			workers_selected = workers_selected + 1
		end
	end
end

function UnitManager:deselectUnits()
	for i = 1, number_of_humans do
		human_list[i].selected = false	-- deselect all humans 
	end
	for i = 1, number_of_zombies do
		zombie_list[i].selected = false	-- deselect all zombies 
	end
	for i = 1, number_of_rangers do
		ranger_list[i].selected = false	-- deselect all rangers 
	end
	for i = 1, number_of_workers do
		worker_list[i].selected = false	-- deselect all workers 
	end
	
	humans_selected = 0
	zombies_selected = 0
	rangers_selected = 0
	workers_selected = 0

	
end

function UnitManager:updateUnit(unitOrig, newType)
		--local deadx = u[h_index].x
		--local deady = human_list[h_index].y
		--table.remove(human_list, h_index)							-- remove human from human_list array
end

function UnitManager:createRanger(xo,yo)
	print("Creating a Ranger at x:"..xo..",y:"..yo)
	number_of_rangers = number_of_rangers + 1					-- increase count of zombies alive
	ranger_list[number_of_rangers] = Ranger:new(xo+view.x, yo+view.y)	-- create new zombie at the location of this zombie
	ranger_list[number_of_rangers]:setupUnit()
	unitTag = unitTag + 1
	--ranger_tag = ranger_tag + 1
end

function UnitManager:createWorker(xo,yo)
	print("Creating a Ranger at x:"..xo..",y:"..yo)
	number_of_workers = number_of_workers + 1					-- increase count of zombies alive
	worker_list[number_of_workers] = Worker:new(xo+view.x, yo+view.y)	-- create new zombie at the location of this zombie
	worker_list[number_of_workers]:setupUnit()
	unitTag = unitTag + 1
	--ranger_tag = ranger_tag + 1
end

function UnitManager:moveTo(xo,yo)

	for i,v in pairs (human_list) do
		if v.selected == true then
			v:getShortestPath(v.x,v.y,xo,yo)
		end
	end

	for i,v in pairs (worker_list) do
		if v.selected == true then
			--v:getShortestPath(v.x,v.y,xo,yo)
			print("HIIIII")
			v:sendToWork()
		end
	end
end

function UnitManager:collectSupplies()
	--[[for i,v in pairs (worker_list) do
		if v.selected == true then
			v:getShortestPath(v.x,v.y,xo,yo)
			v:sendToWork()
		end
	end]]--
end

function UnitManager:patrol(xtar,ytar)
	for i,v in pairs (ranger_list) do
		if v.selected == true then
			print("patrol")
			local bool = v:getShortestPath(v.x,v.y,xtar,ytar)
			if bool then v:patrol() end
		end
	end
end

function UnitManager:selectedType()
	local total_units_selected = zombies_selected + rangers_selected + workers_selected + humans_selected
	local uType = "X"
	if zombies_selected == 0 and rangers_selected == 0 and workers_selected == 0 then
		uType = "Humans"
	elseif zombies_selected == 0 and rangers_selected == 0 and humans_selected == 0 then
		uType = "Workers"
	elseif zombies_selected == 0 and workers_selected == 0 and humans_selected == 0 then
		uType = "Rangers"
	elseif workers_selected == 0 and rangers_selected == 0 and humans_selected == 0 then
		uType = "Zombies"
	else
		uType = "Mixed"
	end
	return total_units_selected, uType
end

-- check if the unit (argument) is being followed by a zombie ! if it is, give the zombie the new tag
-- that it is supposed to follow !
function UnitManager:checkIfFollowed(newType, oldTag, newTag)
	for i,v in pairs(zombie_list) do
		if v.followingTag == oldTag and v.followingType == "Human" then
			v.followingTag = newTag
			v.followingType = newType
		end
	end
end

function UnitManager:convertUnits(convType)
	if (convType == "Worker") then
		local selectedU = 0
		for i,v in pairs (human_list) do
			if v.selected == true then
				selectedU = selectedU + 1
			end
		end
		local suppliesNeeded = selectedU * 2
		
		--local listindexDelete = {}
		if supplies >= suppliesNeeded then
			supplies = supplies - suppliesNeeded
			for i,v in pairs (human_list) do
				if v.selected == true then
					local dx = v.x
					local dy = v.y
					number_of_workers = number_of_workers + 1
					self.idleWorkers = self.idleWorkers + 1
					newWorker = Worker:new(dx,dy)
					table.insert(worker_list, newWorker)
					newWorker:setupUnit()
					self:checkIfFollowed("Worker", v.tag, unitTag)		-- check if this unit is followed and update zombie the new tag
					unitTag = unitTag + 1
					table.remove(human_list, i)
					--table.insert(listindexDelete, i)
					number_of_humans = number_of_humans - 1
				end
			end
			
			--for i,v in pairs(listindexDelete) do
				
			--end
			
			if selectedU > 1 then
				infoText:addText(selectedU.." civilians have been recruited to Workers")
			else
				infoText:addText(selectedU.." civilian has been recruited to a Worker")
			end
		else
			infoText:addText("Insufficient funds ! ".. suppliesNeeded.. " supplies needed.")
		end
	elseif (convType == "Ranger") then
		local selectedU = 0
		for i,v in pairs (human_list) do
			if v.selected == true then
				selectedU = selectedU + 1
			end
		end
		local suppliesNeeded = selectedU * 3
		
		if supplies >= suppliesNeeded then
			supplies = supplies - suppliesNeeded
			for i,v in pairs (human_list) do
				if v.selected == true then
						local dx = v.x
						local dy = v.y
						number_of_rangers = number_of_rangers + 1
						newRanger = Ranger:new(dx,dy)
						table.insert(ranger_list, newRanger)
						newRanger:setupUnit()
						self:checkIfFollowed("Ranger", v.tag, unitTag)		-- check if this unit is followed and update zombie the new tag
						unitTag = unitTag + 1
						table.remove(human_list, i)
						number_of_humans = number_of_humans - 1
				end
			end
			if selectedU > 1 then
				infoText:addText(selectedU.." civilians have been recruited to Rangers")
			else
				infoText:addText(selectedU.." civilian has been recruited to a Ranger")
			end
		else
			infoText:addText("Insufficient funds ! ".. suppliesNeeded.. " supplies needed.")
		end
	end	
end

function UnitManager:sendWorkers()
	for i,v in pairs (worker_list) do
		if v.selected == true and v.working == false then
			self.idleWorkers = self.idleWorkers - 1
			v:sendToWork()
		end
	end
end
