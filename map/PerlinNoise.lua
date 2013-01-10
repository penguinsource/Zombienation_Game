-- generate Perlin Noise to be used as a depth map
function generatePerlinNoise(numOctaves, width, height)
	local persistance = 0.5
	local amplitude = 1
	local totalAmplitude = 0
	
	-- base white nosie
	base = generateWhiteNoise(width, height)
	
	-- init noise array
	perlinNoise = {}	
	for x=0,width-1 do
		perlinNoise[x] = {}
		for y=0,height-1 do
			perlinNoise[x][y] = 0
		end
	end
	
	-- blend octaves
	for o=0,numOctaves-1 do
		amplitude = amplitude + persistance
		totalAmplitude = totalAmplitude + amplitude
		
		local smooth = generateSmoothNoise(base, o, width, height)
	
		for x=0,width-1 do			
			for y=0,height-1 do
				perlinNoise[x][y] = perlinNoise[x][y] + (smooth[x][y] * amplitude)
			end
		end
	end
	
	-- normalize
	for x=0,width-1 do
		for y=0,height-1 do
			perlinNoise[x][y] = math.floor((perlinNoise[x][y] / totalAmplitude) * 100)
		end
	end
	
	return perlinNoise
end

-- white noise
function generateWhiteNoise(width, height)
	local noise = {}
	
	for x=0,width-1 do
		noise[x] = {}
		for y=0,height-1 do
			noise[x][y] = math.random() % 1
		end
	end
	
	return noise
end

-- octaves
function generateSmoothNoise(base, octave, width, height)
	local period = 2 ^ octave
	local frequency = 1 / period
	
	noise = {}
	
	for x=0,width-1 do
		noise[x] = {}
		
		-- calc horizontal sampling indices
		local sx0 = math.floor(x / period) * period
		local sx1 = (sx0 + period) % width
		local horizontalBlend = (x - sx0) * frequency
	
		for y=0,height-1 do
			-- vertical sampling indices
			local sy0 = math.floor(y / period) * period
			local sy1 = (sy0 + period) % height
			local verticalBlend = (y - sy0) * frequency
			
			-- blend top corners
			top = interpolate(base[sx0][sy0], base[sx1][sy0], horizontalBlend)
			-- blend bottom corners
			bottom = interpolate(base[sx0][sy1], base[sx1][sy1], horizontalBlend)
			-- final blend
			noise[x][y] = interpolate(top, bottom, verticalBlend)
		end
	end
	
	return noise
end

function interpolate(x0, x1, alpha)	
	return (x0 * (1 - alpha)) + (alpha * x1)
end



-- dump to console
function display(noise)
	for x=0,width-1 do
		for y=0,height-1 do
			print("n["..x..","..y.."]: "..noise[x][y])
		end
	end
end

-- dump to file
function outputNoise(noise, width, height)
	io.output("depthMap.txt")
	
	for x=0,width-1 do
		for y=0,height-1 do
			io.write(noise[x][y].." ")
		end
		io.write("\n")
	end
end


