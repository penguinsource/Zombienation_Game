Point = {}
Point_mt = { __index = Point }

-- Constructor
function Point:new(x_arg, y_arg)
    -- define our parameters here
    local new_object = {
		x = x_arg,
		y = y_arg
    }
    setmetatable(new_object, Point_mt )
    return new_object
end
