local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "BuildDataGUI"
screenGui.ResetOnSpawn = false

local uiCorner = function(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = instance
end

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 400, 0, 320)
mainFrame.Position = UDim2.new(0.5, -200, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
uiCorner(mainFrame, 12)

mainFrame.Active = true
mainFrame.Draggable = true

local tabFrame = Instance.new("Frame", mainFrame)
tabFrame.Size = UDim2.new(1, 0, 0, 40)
tabFrame.BackgroundTransparency = 1

local saveTab = Instance.new("TextButton", tabFrame)
saveTab.Text = "💾 save .JSON"
saveTab.Size = UDim2.new(0.5, 0, 1, 0)
saveTab.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
saveTab.TextColor3 = Color3.new(1, 1, 1)
saveTab.Font = Enum.Font.GothamBold
saveTab.TextSize = 18
uiCorner(saveTab, 8)

local loadTab = saveTab:Clone()
loadTab.Parent = tabFrame
loadTab.Position = UDim2.new(0.5, 0, 0, 0)
loadTab.Text = "📦 load .JSON"

-- Filename input
local fileNameBox = Instance.new("TextBox", mainFrame)
fileNameBox.PlaceholderText = "Enter filename here"
fileNameBox.Text = "BuildModeData.json"
fileNameBox.Size = UDim2.new(1, -20, 0, 30)
fileNameBox.Position = UDim2.new(0, 10, 0, 45)
fileNameBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
fileNameBox.TextColor3 = Color3.new(1, 1, 1)
fileNameBox.Font = Enum.Font.Gotham
fileNameBox.TextSize = 14
uiCorner(fileNameBox, 6)

-- Save Frame
local saveFrame = Instance.new("Frame", mainFrame)
saveFrame.Size = UDim2.new(1, -20, 1, -90)
saveFrame.Position = UDim2.new(0, 10, 0, 85)
saveFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
uiCorner(saveFrame, 10)

local saveButton = Instance.new("TextButton", saveFrame)
saveButton.Size = UDim2.new(0.5, 0, 0.3, 0)
saveButton.Position = UDim2.new(0.25, 0, 0.35, 0)
saveButton.Text = "📥 export to .JSON"
saveButton.BackgroundColor3 = Color3.fromRGB(75, 75, 75)
saveButton.TextColor3 = Color3.new(1, 1, 1)
saveButton.Font = Enum.Font.Gotham
saveButton.TextSize = 16
uiCorner(saveButton, 8)

-- Load Frame
local loadFrame = saveFrame:Clone()
loadFrame.Parent = mainFrame
loadFrame.Visible = false

local loadButton = loadFrame:FindFirstChildOfClass("TextButton")
loadButton.Text = "📤 import from .JSON"

-- Tab switching
saveTab.MouseButton1Click:Connect(function()
	saveFrame.Visible = true
	loadFrame.Visible = false
end)

loadTab.MouseButton1Click:Connect(function()
	saveFrame.Visible = false
	loadFrame.Visible = true
end)

saveButton.MouseButton1Click:Connect(function()
	local fileName = fileNameBox.Text or "BuildModeData.json"
	if not fileName:match("%.json$") then
		fileName = fileName .. ".json"
	end

	local build = workspace:WaitForChild("BuildModel")
	local data = {}

	for _, object in pairs(build:GetChildren()) do
		local part = object:FindFirstChild("Base") or object:FindFirstChild("ColorPart")
		if part and part:IsA("BasePart") then
			table.insert(data, {
				Name = object.Name,
				CFrame = { X = part.CFrame.X, Y = part.CFrame.Y, Z = part.CFrame.Z },
				Material = part.Material.Name,
				Color = part.BrickColor.Number,
				Size = { X = part.Size.X, Y = part.Size.Y, Z = part.Size.Z },
				Rotation = { X = part.Rotation.X, Y = part.Rotation.Y, Z = part.Rotation.Z }
			})
		end
	end

	local json = HttpService:JSONEncode(data)
	if writefile then
		writefile(fileName, json)
		print("kill saved to workspace" .. fileName)
	else
		warn("writefile isn't supported")
	end
end)

loadButton.MouseButton1Click:Connect(function()
	local fileName = fileNameBox.Text or "BuildModeData.json"
	if not fileName:match("%.json$") then
		fileName = fileName .. ".json"
	end

	local placeBlock = ReplicatedStorage:WaitForChild("Functions"):WaitForChild("PlaceBlock")
	local commitResize = ReplicatedStorage:WaitForChild("Functions"):WaitForChild("CommitResize")
	local blocksMainFolder = ReplicatedStorage:WaitForChild("Blocks")
	local buildModel = workspace:WaitForChild("BuildModel")
	local placedBlocks = {}

	local function findBlockModel(name)
		for _, category in ipairs(blocksMainFolder:GetChildren()) do
			if category:IsA("Folder") then
				local model = category:FindFirstChild(name, true)
				if model and model:IsA("Model") then
					return model
				end
				for _, subfolder in ipairs(category:GetChildren()) do
					if subfolder.Name == name and subfolder:IsA("Folder") then
						local nestedModel = subfolder:FindFirstChild(name)
						if nestedModel and nestedModel:IsA("Model") then
							return nestedModel
						end
					end
				end
			end
		end
		return nil
	end

	local jsonData
	if readfile then
		local success, result = pcall(function()
			return readfile(fileName)
		end)
		if success then
			jsonData = result
		else
			warn("failed to read file: " .. fileName)
			return
		end
	else
		warn("readfile isn't supported")
		return
	end

	local blockData = HttpService:JSONDecode(jsonData)

	for _, entry in ipairs(blockData) do
		local cf = CFrame.new(entry.CFrame.X, entry.CFrame.Y, entry.CFrame.Z) *
			CFrame.Angles(math.rad(entry.Rotation.X), math.rad(entry.Rotation.Y), math.rad(entry.Rotation.Z))

		local blockModel = findBlockModel(entry.Name)
		if not blockModel then
			warn("kill: couldn't find block model:", entry.Name)
			continue
		end

		local materialStr = entry.Material or "Plastic"
		local cleanedMaterialStr = string.gsub(materialStr, "^Enum%.Material%.", "")
		local material = Enum.Material[cleanedMaterialStr] or Enum.Material.Plastic

		local successColor, brickColor = pcall(function()
			return BrickColor.new(tonumber(entry.Color))
		end)
		brickColor = successColor and brickColor or BrickColor.new("Medium stone grey")

		local before = {}
		for _, child in ipairs(buildModel:GetChildren()) do
			before[child] = true
		end

		local args = { blockModel, cf, brickColor, material }
		local success, err = pcall(function()
			placeBlock:InvokeServer(unpack(args))
		end)

		if success then
			for _, child in ipairs(buildModel:GetChildren()) do
				if not before[child] then
					table.insert(placedBlocks, {
						instance = child,
						cf = cf,
						size = Vector3.new(entry.Size.X, entry.Size.Y, entry.Size.Z)
					})
					break
				end
			end
		else
			warn("kill: failed to place block:", entry.Name, err)
		end
	end

	task.wait(1)

	for _, info in ipairs(placedBlocks) do
		local block = info.instance
		local cf = info.cf
		local size = info.size
		local part = block:FindFirstChild("Base") or block:FindFirstChild("ColorPart")
		if part then
			local args = { block, { part, cf, size } }
			pcall(function()
				commitResize:InvokeServer(unpack(args))
			end)
		else
			warn("invalid colorpart/basepart")
		end
	end

	print("loading complete " .. fileName)
end)
