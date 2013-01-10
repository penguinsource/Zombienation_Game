-- SpriteAnimation class
-- Author: Sean Laurvick
-- Must be initiated with the SpriteAnimation:load() function.
-- imageString: the path of the image to be loaded from.
-- width, height: the dimensions of the individual sprites.
-- numRows, numFrames: the dimensions of the source image, in tiles.
 
SpriteAnimation = {}
 
-- Constructor
function SpriteAnimation:new(imageString, width, height, numRows, numFrames)
    local object = {
    imageString = imageString,
    spriteImage = spriteImage,
    sprites = {},
    height = height,
    width = width,
    currentFrame = 1,
    currentRow = 1,
    numFrames = numFrames,
    numRows = numRows,
    delta = 0,
    delay = 200,
    loop = true,
    flipX = false,
    flipY = false,
    isRunning = true,
	angle = 0
    }
    setmetatable(object, { __index = SpriteAnimation})
    return object
end
 
function SpriteAnimation:load(delay)
    -- Set the time between frames
    self.delay = delay
 
    -- Load up our images into a table from quads, and set our SpriteRow
    self.spriteImage = love.graphics.newImage(self.imageString)
    local sourceImage = love.graphics.newImage(self.imageString)
    for i = 1, self.numFrames, 1 do
        self.sprites[i] = {}
        for j = 1, self.numRows, 1 do
            -- Create a matrix of all our sprites
            local wide = self.width * (j - 1)
            local high = self.height * (i - 1)
            self.sprites[i][j] = love.graphics.newQuad(wide, high, self.width, self.height, sourceImage:getWidth(), sourceImage:getHeight())
        end
    end
end
 
function SpriteAnimation:update(dt)
    if self.isRunning then -- skip this if animation is stopped
        -- add in our accumulated delta
        self.delta = self.delta + dt
   
        -- see if it's time to advance the frame
        if self.delta >= (self.delay/1000) then
            -- if set to not loop, keep the frame at the last frame
            if (self.currentFrame == self.numFrames) and not(self.loop) then
                self.currentFrame = self.numFrames - 1
            end
           
            -- advance one frame, then reset delta counter
            self.currentFrame = (self.currentFrame % self.numFrames) + 1
            self.delta = 0
        end
    end
end
 
function SpriteAnimation:draw(x, y)
    -- define temporary offsets for drawing
    local xScale = 1
    local yScale = 1
    local xOffset = 0
    local yOffset = 0
   
    if self.flipX then
        xScale = -1
        xOffset = self.width
    end
    if self.flipY then
        yScale = -1
        yOffset = self.height
    end
    -- draw the quad
	--print(self.sprites[self.currentRow][self.currentFrame])
	--love.graphics.push()
	--love.graphics.rotate(self.angle*math.pi/180)
    love.graphics.drawq(self.spriteImage, self.sprites[self.currentRow][self.currentFrame], x, y, (self.angle+90)*math.pi/180, xScale, yScale, self.width/2, self.height/2)
	--love.graphics.pop()
end
 
function SpriteAnimation:switch(newRow, newMax, newDelay)
    -- Optional: assign a new number of animation frames
    if newMax then
        self.numFrames = newMax
    end
   
    -- Optional: assign a new delta
    if newDelay then
        self.delay = newDelay
    end
   
    -- Switch to the new row
    self.currentRow = newRow
   
    -- If we're beyond the maximum frame, reset
    if self.currentFrame > self.numFrames then
        self:reset()
    end
end
 
-- Sets the animation to frame 1
function SpriteAnimation:reset()
    self.currentFrame = 1
end
 
-- Starts the animation
function SpriteAnimation:start(selectFrame)
    self.isRunning = true
   
    -- Optional: select the frame on which to start the animation
    if selectFrame then
        self.currentFrame = selectFrame
    end
end
 
function SpriteAnimation:stop(selectFrame)
    self.isRunning = false
   
    -- Optional: select the frame on which to stop the animation
    if selectFrame then
        self.currentFrame = selectFrame
    end
end
 
function SpriteAnimation:flip(xIsFlipped, yIsFlipped)
    self.flipX = xIsFlipped
    self.flipY = yIsFlipped
end
 
function SpriteAnimation:rotate(r)
	self.angle = r
end
 
--[[Copyright (c) 2012 Sean Laurvick
 
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
 
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
 
Except as contained in this notice, the name(s) of the above copyright holders
shall not be used in advertising or otherwise to promote the sale, use or
other dealings in this Software without prior written authorization.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.--]]