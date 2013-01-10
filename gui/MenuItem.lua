MenuItem = {}

function MenuItem:new()

	local object = {
		height = 0,
		width = 0,
		
	}
	setmetatable(object, { __index = MenuItem })
	return object
end