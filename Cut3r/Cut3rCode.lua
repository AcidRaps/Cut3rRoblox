--WARNING: THIS CODE DOES NOT HAVE ITS DEPENDANTCIES, WHICH ARE SUPER IMPORTANT FOR THE CODE TO FUNCTION!!!
--WE RECCOMMEND USING THE .RBXM VERSION OR THE MODULE FOUND IN THE DEMO PLACE FILE
--THIS CODE IS ONLY MENT FOR VIEWING.
local Cut = {}
--[[welcome to Cut3r
		This is a really early build of the vornoi based CSG cutting.
		Visit devfourm/github for code usage.
]]

local Settings = {
	--toggles
	OverrideLimits = false,
	--Limits
	IterationLimit = 100,
}

--internal 

--services
local GeoService = game:GetService("GeometryService")
local ConstraintSolver = require(script.Constraints) -- Code by Roblox themselves.

local function resize(part:BasePart,increment,Dimension:Vector3)
	
	local dimension = Dimension or Vector3.new(1,0,0)
	
	part.Size += math.abs(increment) * dimension
	part.CFrame *= CFrame.new(dimension * increment / 2)
end

local options = { --Settings for the Unions, for internalCSGSlice to work, keep split apart true
	RenderFidelity=Enum.RenderFidelity.Automatic,
	CollisionFidelity=Enum.CollisionFidelity.Default,
	SplitApart=true,

}

local constraintOptions = { -- Settings for contstraint preservation
	tolerance = 0.1,
	weldConstraintPreserve = Enum.WeldConstraintPreserve.All
}

local function drawLine(startVector, endVector, parent)
	-- 1. Calculate the center position (midpoint) of the line
	local midpoint = (startVector + endVector) / 2

	-- 2. Calculate the distance (length) of the line
	local distance = (startVector - endVector).Magnitude

	-- 3. Calculate the orientation (CFrame)
	-- The CFrame.lookAt constructor handles the rotation to point from midpoint to endVector
	local orientation = CFrame.lookAt(midpoint, endVector)

	-- 4. Create the Part
	local linePart = Instance.new("Part")

	-- Set visual and physical properties
	linePart.Anchored = true              -- Should not move
	linePart.CanCollide = false           -- For debugging, collision is usually unnecessary
	linePart.Material = Enum.Material.Neon -- The requested neon material
	linePart.Color = Color3.new(1, 0, 0)  -- Bright Red (R, G, B) for visibility

	-- Apply the calculated CFrame and Size
	linePart.CFrame = orientation
	linePart.Size = Vector3.new(0.1, 0.1, distance) -- Thickness (X, Y) is small, Z is the length

	-- Set the parent
	linePart.Parent = parent or workspace -- Default to workspace if no parent is specified

	return linePart
end

local function joinTables(table1,table2)
	local final = {}
	for _,item in table1 do
		table.insert(final,item)
	end
	
	for _,item in table2 do
		table.insert(final,item)
	end
	
	return final
end

local function internalCSGSlice(Part:BasePart,newSlicer,Extension,UCFO,offset)
	
	if UCFO then
		
		newSlicer.CFrame = Part.ExtentsCFrame:ToWorldSpace(offset)
	else
		newSlicer.CFrame = offset
	end
	local Tags = game:GetService("CollectionService"):GetTags(Part)
	local NegateThing : Part = newSlicer:Clone()
	NegateThing.Parent = workspace
	NegateThing.CFrame = newSlicer.CFrame
	NegateThing.Size = Vector3.new(0.05,Extension,Extension)
	NegateThing:ClearAllChildren()
	NegateThing.Material = Part.Material
	NegateThing.Color = Part.Color
	NegateThing.Transparency = 1
	local Results = {}
	
	local status,err = pcall(function()
		Results = GeoService:subtractAsync(Part,{NegateThing},options)
		
		NegateThing:Destroy()
	end)
	
	if Results and status then
		local recommendedTable = GeoService:CalculateConstraintsToPreserve(Part, Results, constraintOptions)
		ConstraintSolver.preserveConstraints(recommendedTable)
		for i,Item in Results do
			Item.Anchored = false
			for _,tag in Tags do
				game:GetService("CollectionService"):AddTag(Item,tag)
			end
			Item.Parent = workspace
			
		end
		Part:Destroy()
		
		return Results
	else
		warn("Cut3r Failure: CSG operation failed: "..err)
		return false
		
	end
	
	
end

local function internalCSGCut(Part:BasePart,newSlicer,Extension,UCFO,offset)
	if Part == nil then warn("Cut3r failure: no part given") return false end
	if UCFO then

		newSlicer.CFrame = Part.ExtentsCFrame:ToWorldSpace(offset)
	else
		newSlicer.CFrame = offset
	end
	local Tags = game:GetService("CollectionService"):GetTags(Part)
	local NegateThing : Part = newSlicer:Clone()
	NegateThing.Parent = workspace
	NegateThing.CFrame = newSlicer.CFrame
	NegateThing.Size = Vector3.new(Extension,Extension,0.05)
	resize(NegateThing,Extension,Vector3.new(0,0,1))
	NegateThing:ClearAllChildren()
	NegateThing.Material = Part.Material
	NegateThing.Color = Part.Color
	NegateThing.Transparency = 1
	local Results = {}

	local status,err = pcall(function()
		Results = GeoService:subtractAsync(Part,{NegateThing},options)
		NegateThing:Destroy()
	end)

	if Results and status then
		local recommendedTable = GeoService:CalculateConstraintsToPreserve(Part, Results, constraintOptions)
		ConstraintSolver.preserveConstraints(recommendedTable)
		for i,Item in Results do
			Item.Anchored = true
			for _,tag in Tags do
				game:GetService("CollectionService"):AddTag(Item,tag)
			end
			Item.Parent = workspace

		end
		Part:Destroy()

		return Results
	else
		warn("Cut3r Failure: CSG operation failed: "..err)
		return false

	end
end

local function internalGenerateCutPart(Part:BasePart,newSlicer,Extension,UCFO,offset)
	if Part == nil then warn("Cut3r failure: no part given") return false end
	if UCFO then

		newSlicer.CFrame = Part.ExtentsCFrame:ToWorldSpace(offset)
	else
		newSlicer.CFrame = offset
	end
	local Tags = game:GetService("CollectionService"):GetTags(Part)
	local NegateThing : Part = newSlicer:Clone()
	NegateThing.Parent = workspace
	NegateThing.CFrame = newSlicer.CFrame
	NegateThing.Size = Vector3.new(Extension,Extension,0.05)
	resize(NegateThing,Extension,Vector3.new(0,0,1))
	NegateThing:ClearAllChildren()
	NegateThing.Material = Part.Material
	NegateThing.Color = Part.Color
	NegateThing.Transparency = 1
	
	return NegateThing
end

local function internalCSGChunk(Part:BasePart ,UseCFrameOffset:boolean, Size:Vector3, Position:CFrame, Shape:Enum.PartType)
	local newSlicer = Instance.new("Part")
	newSlicer.Material = Part.Material
	newSlicer.Color = Part.Color
	newSlicer.Transparency = 0
	newSlicer.Anchored = true
	newSlicer.Shape = Shape
	newSlicer.Size = Size
	if UseCFrameOffset then
		newSlicer.CFrame = Part.CFrame:ToWorldSpace(Position)
	else
		newSlicer.CFrame = Position
	end
	newSlicer.Parent = workspace
	local Tags = game:GetService("CollectionService"):GetTags(Part)
	local Results = {}
	--stage 1, Intersect
	
	local success,err = pcall(function()
		Results = GeoService:IntersectAsync(Part,{newSlicer},options)
	end)
	if success then
		local recommendedTable = GeoService:CalculateConstraintsToPreserve(Part, Results, constraintOptions)
		ConstraintSolver.preserveConstraints(recommendedTable)
		for i,Item in Results do
			Item.Anchored = false
			for _,tag in Tags do
				game:GetService("CollectionService"):AddTag(Item,tag)
			end
			
			Item.Parent = workspace
		end
		-- stage 2, cut.
		
		local Remainings = {}
		local success,err = pcall(function()
			Remainings = GeoService:SubtractAsync(Part,{newSlicer},options)
		end)
		if success then
			local recommendedTable = GeoService:CalculateConstraintsToPreserve(Part, Remainings, constraintOptions)
			ConstraintSolver.preserveConstraints(recommendedTable)
			for i,Item in Remainings do
				for _,tag in Tags do
					game:GetService("CollectionService"):AddTag(Item,tag)
				end
				Item.Parent = workspace
				if Item:IsA("BasePart") then
					local touching = Item:GetTouchingParts()
					if #touching <= 0 then
						Item.Anchored = false
					end
				end
			end
				Part:Destroy()
			
			newSlicer:Destroy()
			return Results,Remainings
		end
	else
		warn("Cut3r Failure: CSG operation failed: "..err)
		return false
	end
	
	
end

local function internalSliceTableShatter(Parts,UseCFrameOffset:boolean,Extension:number)
	local newSlicer = script.Slicer:Clone()
	local sparts = Parts
	if typeof(Parts) == "table" then
		local returnChildren = {}
		for i,Part:Part in Parts do
			returnChildren = joinTables(returnChildren,internalCSGSlice(Part,newSlicer,Extension,UseCFrameOffset,CFrame.fromEulerAngles(math.rad(math.random(0,360)),math.rad(math.random(0,360)),math.rad(math.random(0,360)))))
		end
		return returnChildren
	else
		warn("Cut3r Failure: Slice(Parts,UseCFrameOffset,CFrameOffset,Extension) <Part> needs to be a Part or a Model/Folder. Meshparts are not supported by roblox's CSG.")
	end
end

-- the fun stuff, Functions

function Cut:Slice(Parts,UseCFrameOffset:boolean,CFrameOffset:CFrame,Extension:number)
	local newSlicer = script.Slicer:Clone()
	if Parts:IsA("BasePart") then
		local Part = Parts
		if Part:IsA("Part") or Part:IsA("UnionOperation") then
			return internalCSGSlice(Part,newSlicer,Extension,UseCFrameOffset,CFrameOffset)
		end
	elseif Parts:IsA("Model") or Parts:IsA("Folder") then
		local children = Parts:GetChildren()
		local returnChildren = {}
		for i,Part in children do

			returnChildren[i] = internalCSGSlice(Part,newSlicer,Extension,UseCFrameOffset,CFrameOffset)

		end
		return returnChildren

	
	else
		warn("Cut3r Failure: Slice(Parts,UseCFrameOffset,CFrameOffset,Extension) <Part> needs to be a Part or a Model/Folder. Meshparts are not supported by roblox's CSG.")
	end
end

function Cut:SliceTable(Parts,UseCFrameOffset:boolean,CFrameOffset:CFrame,Extension:number)
	local newSlicer = script.Slicer:Clone()



	if typeof(Parts) == "table" then
		local returnChildren = {}
		for i,Part in Parts do
			local p1,p2 = internalCSGSlice(Part,newSlicer,Extension,UseCFrameOffset,CFrameOffset)
			returnChildren[#returnChildren + 1] = p1
			returnChildren[#returnChildren + 1] = p2

		end
		return returnChildren

	else
		warn("Cut3r Failure: Slice(Parts,UseCFrameOffset,CFrameOffset,Extension) <Part> needs to be a Part or a Model/Folder. Meshparts are not supported by roblox's CSG.")
	end
end

function Cut:Shatter(Parts:Instance,UseCFrameOffset:boolean,CFrameOffset:CFrame,Extension:number,ExtraIterations:number)
	local newSlicer = script.Slicer:Clone()
	local Results
	
	if Parts:IsA("BasePart") then
		if ExtraIterations <= Settings.IterationLimit then
			local Part = Parts
			local sparts = {}
			Results = internalCSGSlice(Part,newSlicer,Extension,UseCFrameOffset,CFrame.fromEulerAngles(math.rad(math.random(0,360)),math.rad(math.random(0,360)),math.rad(math.random(0,360))) + CFrameOffset.Position)
			if Results then
				sparts = Results
				for i = 0, ExtraIterations  do
					sparts = internalSliceTableShatter(sparts,true,Extension)
				end
				return sparts
			end
		else
			warn("Cut3r Failure: Shatter(Parts,UseCFrameOffset,CFrameOffset,Extension,ExtraIterations) <ExtraIterations> cannot be the limit of "..tostring(Settings.IterationLimit)..". You can turn this off in the module.")
		end
		
	else
		warn("Cut3r Failure: Shatter(Parts,UseCFrameOffset,CFrameOffset,Extension,ExtraIterations) <Part> needs to be a Part. Meshparts are not supported by roblox's CSG.")

	end

	
	
end

function Cut:Crush(Part:Instance,UseCFrameOffset:boolean,CFrameOffset:CFrame,Extension:number,ExtraIterations:number,DistanceThreshHold:number)
	-- Voronoi Implimentation of Shatter
	local newSlicer = script.Slicer:Clone()
	local Results = {}

	if Part:IsA("BasePart") then
		if ExtraIterations <= Settings.IterationLimit then
			local points = {}
			local RNG = Random.new()
			
			local boundingX = NumberRange.new(- Part.Size.X / 2,Part.Size.X / 2)
			local boundingY = NumberRange.new(- Part.Size.Y / 2,Part.Size.Y / 2)
			local boundingZ = NumberRange.new(- Part.Size.Z / 2,Part.Size.Z / 2)
			
			for i = 0, ExtraIterations do
				local point = Part.CFrame:ToWorldSpace(CFrame.new(Vector3.new(RNG:NextNumber(boundingX.Min,boundingX.Max),RNG:NextNumber(boundingY.Min,boundingY.Max),RNG:NextNumber(boundingZ.Min,boundingZ.Max))))
				table.insert(points, point)
				-- debug, spawn parts
				--local dpart = Instance.new("Part")
				--dpart.CFrame = point
				--dpart.Size = Vector3.new(0.1,0.1,0.1)
				--dpart.Color = Color3.new(RNG:NextNumber(),RNG:NextNumber(),RNG:NextNumber())
				--dpart.Material = Enum.Material.Neon
				--dpart.Anchored = true
				--dpart.Parent = workspace
				--dpart.CanCollide = false
				--dpart.CanQuery = false
				
				
			end
			--task.wait(10)
			local K_NEIGHBORS = 6 
			for i,point:CFrame in points do
				local cell = Part:Clone()

				
				local distances = {}
				for j, otherPoint:CFrame in points do
					if i ~= j then
						local distance = (point.Position - otherPoint.Position).Magnitude
						table.insert(distances, {dist = distance, point = otherPoint})
					end
				end

				
				table.sort(distances, function(a, b)
					return a.dist < b.dist
				end)

				for idx = 1, math.min(#distances, K_NEIGHBORS) do
					local neighbor = distances[idx]
					local otherPoint:CFrame = neighbor.point
					
					
					local midpoint = (point.Position + otherPoint.Position) / 2
					local cframe = CFrame.new(midpoint, otherPoint.Position)

					local result = internalCSGCut(cell, script.Slicer, 100, false, cframe)[1]

					if result then
						cell = result
						
					end
				end
				table.insert(Results,cell)
			end
			Part:Destroy()
			for i,Part:BasePart in Results do
				Part.Anchored = false
				if Part:IsA("UnionOperation") then
					Part.UsePartColor = true 
				end
			end
			return Results
		else
			warn("Cut3r Failure: Shatter(Parts,UseCFrameOffset,CFrameOffset,Extension,ExtraIterations) <ExtraIterations> cannot be the limit of "..tostring(Settings.IterationLimit)..". You can turn this off in the module.")
		end

	else
		warn("Cut3r Failure: Shatter(Parts,UseCFrameOffset,CFrameOffset,Extension,ExtraIterations) <Part> needs to be a Part. Meshparts are not supported by roblox's CSG.")

	end



end

function Cut:ShatterChunk(Parts:Instance,UseCFrameOffset:boolean,CFrameOffset:CFrame,Size:Vector3,ExtraIterations:number)
	if Parts:IsA("BasePart") then
		local results,remains = internalCSGChunk(Parts,UseCFrameOffset,Size,CFrameOffset,Enum.PartType.Block)
		local finalResults = {}
		for _,item in results do
			local re = Cut:Shatter(item,true,CFrame.new(0,0,0),100,ExtraIterations)
			finalResults = joinTables(finalResults,re)
		end
		return finalResults,remains
	else
		warn("Cut3r Failure: ShatterChunks(Parts,UseCFrameOffset,CFrameOffset,Size,ExtraIterations) <Part> needs to be a Part. Meshparts are not supported by roblox's CSG.")
	end
	
end

function Cut:CrushChunk(Parts:Instance,UseCFrameOffset:boolean,CFrameOffset:CFrame,Size:Vector3,ExtraIterations:number)
	if Parts:IsA("BasePart") then
		local results,remains = internalCSGChunk(Parts,UseCFrameOffset,Size,CFrameOffset,Enum.PartType.Block)
		local finalResults = {}
		for _,item in results do
			local re = Cut:Crush(item,true,CFrame.new(0,0,0),100,ExtraIterations,4)
			finalResults = joinTables(finalResults,re)
		end
		return finalResults,remains
	else
		warn("Cut3r Failure: ShatterChunks(Parts,UseCFrameOffset,CFrameOffset,Size,ExtraIterations) <Part> needs to be a Part. Meshparts are not supported by roblox's CSG.")
	end
end

return Cut
