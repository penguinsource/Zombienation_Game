Node = {}
Node_mt = { __index = Node }

function Node:new(x_a, y_a)
    -- define our parameters here
    local new_object = {
    nodeX = x_a,
    nodeY = y_a,
	gcost = 0,
	fcost = 0,
	parentNode = nil
    }
    setmetatable(new_object, Node_mt )
    return new_object
end
