local RunService = game:GetService("RunService")
local LocalPlayer = game.Players.LocalPlayer

local OreData = require(game.ReplicatedStorage.Modules.OresModule).Ores
local ItemData = require(game.ReplicatedStorage.Modules.ItemsModule)

local MineRemote = game.ReplicatedStorage.Events.ClientRemoteEvents.MineOre
local TeleportRemote = game.ReplicatedStorage.Events.ClientRemoteEvents.TeleportPlayer
local ServerChatRemote = game.ReplicatedStorage.Events.ServerRemoteEvents.ServerChat
local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jxinxy/alphalibrary/refs/heads/main/main.luau"))()
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local fearId = 0 --2440220671
local isFear = LocalPlayer.UserId == fearId

local V0 = Vector3.zero

local noclip = false
local walkSpd = 45
local jumpH = 30
local antiAfk = false
local autoMineOres = false
local autoOpenChests = false
local instaOpenChests = true
local antiFall = true
local antiFallDuration = 8
local mineRange = 600
local minRar = 1000
local blocksPerTick = 25
local maxAttempts = 25
local recipe = nil --"Lucky Staff"

local chestOpenDuration = 1
local chestOpenAttempts = 1
local clttl = 150
local cci = 30

local tping = false
local spos = nil
local ccf = nil

local characterConnection
local stateConnection
local heartbeatConnection

local falling = false
local fallStart = 0

local whitelist = {}

local autoTpAfterReset = false
local selectedDepth = nil
local tpDepths = {
	"500m",
	"1000m",
	"1500m",
	"2000m",
	"2500m",
	"3000m",
	"3500m",
	"4000m",
	"4500m",
	"5000m",
	"5500m",
	"6000m",
	"6500m",
	"7000m",
	"7500m",
	"8000m",
	"8500m",
}

local Window = Rayfield:CreateWindow({
	Name=isFear and "Scriptn't" or "Something v1.1", Icon=0,
	LoadingTitle=isFear and "Scriptn't" or "Something", LoadingSubtitle="By Someone",
	ShowText="-... --- -- -... --- -.-. .-.. .- -",
	Theme={
		TextColor=Color3.fromRGB(255,255,255),
		Background=Color3.fromRGB(10,10,10),
		Topbar=Color3.fromRGB(18,18,18),
		Shadow=Color3.fromRGB(0,0,0),
		NotificationBackground=Color3.fromRGB(15,15,15),
		NotificationActionsBackground=Color3.fromRGB(240,240,240),
		TabBackground=Color3.fromRGB(25,25,25),
		TabStroke=Color3.fromRGB(45,45,45),
		TabBackgroundSelected=Color3.fromRGB(245,245,245),
		TabTextColor=Color3.fromRGB(200,200,200),
		SelectedTabTextColor=Color3.fromRGB(15,15,15),
		ElementBackground=Color3.fromRGB(20,20,20),
		ElementBackgroundHover=Color3.fromRGB(30,30,30),
		SecondaryElementBackground=Color3.fromRGB(14,14,14),
		ElementStroke=Color3.fromRGB(45,45,45),
		SecondaryElementStroke=Color3.fromRGB(35,35,35),
		SliderBackground=Color3.fromRGB(255,255,255),
		SliderProgress=Color3.fromRGB(130,130,130),
		SliderStroke=Color3.fromRGB(180,180,180),
		ToggleBackground=Color3.fromRGB(20,20,20),
		ToggleEnabled=Color3.fromRGB(255,255,255),
		ToggleDisabled=Color3.fromRGB(60,60,60),
		ToggleEnabledStroke=Color3.fromRGB(220,220,220),
		ToggleDisabledStroke=Color3.fromRGB(90,90,90),
		ToggleEnabledOuterStroke=Color3.fromRGB(140,140,140),
		ToggleDisabledOuterStroke=Color3.fromRGB(40,40,40),
		DropdownSelected=Color3.fromRGB(40,40,40),
		DropdownUnselected=Color3.fromRGB(20,20,20),
		InputBackground=Color3.fromRGB(18,18,18),
		InputStroke=Color3.fromRGB(55,55,55),
		PlaceholderColor=Color3.fromRGB(140,140,140),
	},
	ToggleUIKeybind="K",
	ConfigurationSaving={ Enabled=true, FolderName=nil, FileName="GoMining" },
})
Rayfield:Notify({ Title=isFear and "Scriptn't" or "Loading...", Content="Please wait.", Duration=5, Image=4483362458 })

local function PlaySound(id)
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = 10
	s.Parent = game.SoundService
	s:Play()
end

if isFear then PlaySound("123726708700660") return end

local WorkspaceBlocks = workspace:WaitForChild("Blocks")
local Chests = workspace:WaitForChild("Chests")

local sorted = {}
local openedChests = {}

local function CheckDistance(p1, p2)
    return (p1 - p2).Magnitude
end

local function GetRoot()
	return LocalPlayer and LocalPlayer.Character and LocalPlayer.Character.HumanoidRootPart
end

local function FindFirstDescendantOfClass(parent, className)
	for _, descendant in parent:GetDescendants() do
		if descendant:IsA(className) then
			return descendant
		end
	end
	return nil
end

local function UpdateProximityDuration(pp, d)
	if typeof(pp) ~= "ProximityPrompt" then
		pp = FindFirstDescendantOfClass(pp, "ProximityPrompt")
	end
	if not pp then return end
	d = d or 0
	if pp.HoldDuration == d then return end
	pp.HoldDuration = d
	pp.RequiresLineOfSight = false
end

local function PositionRoot(tcf)
	local root = GetRoot()
	if not root then return end
	root.CFrame = tcf
	root.AssemblyLinearVelocity  = V0
	root.AssemblyAngularVelocity = V0
end

local function CamLookAtCF(cP, tP)
	cP = cP or workspace.CurrentCamera.CFrame.Position
	workspace.CurrentCamer.CFrame = CFrame.lookAt(cP, tP)
end

local function TeleportToSelectedDepth()
	if not selectedDepth or not autoTpAfterReset then warn(selectedDepth, autoTpAfterReset) return end
	local root = GetRoot()
	if not root then return end
	root.AssemblyLinearVelocity  = V0
	root.AssemblyAngularVelocity = V0
	TeleportRemote:FireServer(selectedDepth)
end

ServerChatRemote.OnClientEvent:Connect(function(a, b, c ,d ,e)
	if e == "MineRegenerated" then
		TeleportToSelectedDepth()
	end
end)

local function HideSingle(obj)
	if obj:IsA("BasePart") then
        obj.Transparency = 1
        obj.CanCollide = false
        obj.CanTouch = false
        obj.CanQuery = false
    end
end

local function HideAll(m)
    for _, obj in ipairs(m:GetDescendants()) do
        HideSingle(obj)
    end
end

local function MoveInFrontOfCamera(obj, distance)
    local camera = workspace.CurrentCamera
    if not camera or not obj then
        return
    end

    distance = distance or 5

    local cf = camera.CFrame
    local target = cf.Position + cf.LookVector * distance

    if obj:IsA("Model") then
		HideAll(obj)
        obj:PivotTo(CFrame.new(target, target + cf.LookVector))
    elseif obj:IsA("BasePart") then
		HideSingle(obj)
        obj.CFrame = CFrame.new(target, target + cf.LookVector)
    end
end

local noclipPts={}
local function RebuildNC(char)
	noclipPts={}
	if not char then return end
	for _,d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") then noclipPts[#noclipPts+1]=d end
	end
	char.DescendantAdded:Connect(function(d)
		if d:IsA("BasePart") then noclipPts[#noclipPts+1]=d end
	end)
end
LocalPlayer.CharacterAdded:Connect(RebuildNC)
if LocalPlayer.Character then RebuildNC(LocalPlayer.Character) end

local function NoclipLoop()
	for i=1,#noclipPts do
		local p=noclipPts[i]
		if p.Parent and p.CanCollide then p.CanCollide=false end
	end
end

local function GetChestData(m)
    local d = openedChests[m]

    if not d then
        d = {
            Attempts = 0,
            LastAttempt = tick(),
        }
        openedChests[m] = d
    end

    return d
end

local function RemoveChestLog(m)
    openedChests[m] = nil
end

local function OpenChest(m)
    local d = GetChestData(m)

    if d.Attempts >= chestOpenAttempts then
        return
    end

    d.Attempts += 1
    d.LastAttempt = tick()

    local pp = FindFirstDescendantOfClass(m, "ProximityPrompt")
    if not pp then
        return
    end

    if not tping then
        local r = GetRoot()
        if r then
            spos = r.CFrame
        end
		ccf = workspace.CurrentCamera.CFrame
    end

    tping = true
    PositionRoot(m:GetPivot())

    local t = tick() + chestOpenDuration

    while task.wait(0.02) do
        if tick() >= t then
            break
        end

        UpdateProximityDuration(pp, 0)
        fireproximityprompt(pp)
		MoveInFrontOfCamera(pp.Parent)
		--CamLookAtCF(nil, m:GetPivot())
    end

    PositionRoot(spos)
	tping = false
	workspace.CurrentCamera.CFrame = ccf
end

local function MineBlock(block)
    local hitPos = block:GetPivot().Position
    local camPos = hitPos - Vector3.one * 8
    MineRemote:FireServer(block, hitPos, true, camPos)
    --MineRemote:FireServer(nil, nil, false, nil)
end

local function CanMine(block)
    local hitPos = block:GetPivot().Position
	local root = GetRoot()
	if not root then print("Root missing") return end
    if CheckDistance(hitPos, root.Position) >= mineRange then return false end
    return true
end

local function unlog(block)
    sorted[block] = nil
end

local function MineWithCheck(block)
    if sorted[block].Attempt >= maxAttempts then
	    unlog(block)
        return
    end

    sorted[block].Attempt += 1

    if not block.Parent then
        return
    end

    if not CanMine(block) then
        --warn("Out of range:", block, "Attempt:", sorted[block].Attempt)
        return
    end

    MineBlock(block)

    task.wait()
end

local function logBlock(block)
    if not (block:IsA("BasePart") or block:IsA("Model")) then
        return
    end

    if block:GetAttribute("Tag") and block:GetAttribute("Tag") ~= LocalPlayer.Name then
        warn(block, "belongs to:", block:GetAttribute("Tag"))
        return
    end

    if not table.find(whitelist, block.Name) then
		if minRar
        	and OreData[block.Name]
        	and OreData[block.Name].Rarity
        	and OreData[block.Name].Rarity <= minRar then
        	return
    	end

    	if recipe
        	and ItemData[recipe]
        	and ItemData[recipe].block
        	and not ItemData[recipe].block.Name then
        	return
    	end
	else
		print(block, "whitelisted")
	end

    sorted[block] = {
        Attempt = 0
    }

	if autoMineOres then
		MineWithCheck(block)
	end
end

local function LoopMineAll()
    local bl = 0
    local succ, err = pcall(function()
        for block, v in pairs(sorted) do
            bl += 1
            if bl % blocksPerTick == 0 then task.wait() end
            MineWithCheck(block)
        end
    end)
    if not succ then
        print(err)
        return
    end
end

local function OnFallDetected(character, duration)
	TeleportToSelectedDepth()
end

local function CleanupCharacterAntiFall()
	if stateConnection then
		stateConnection:Disconnect()
		stateConnection = nil
	end

	if heartbeatConnection then
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
	end

	falling = false
	fallStart = 0
end

local function SetupCharacterAntiFall(character)
	CleanupCharacterAntiFall()

	local humanoid = character:WaitForChild("Humanoid")

	stateConnection = humanoid.StateChanged:Connect(function(_, newState)
		if not antiFall then
			falling = false
			fallStart = 0
			return
		end

		if newState == Enum.HumanoidStateType.Freefall then
			if not falling then
				falling = true
				fallStart = os.clock()
			end
		else
			falling = false
			fallStart = 0
		end
	end)

	heartbeatConnection = RunService.Heartbeat:Connect(function()
		if not antiFall or not falling then
			return
		end

		if not character.Parent then
			CleanupCharacterAntiFall()
			return
		end

		local duration = os.clock() - fallStart

		if duration >= antiFallDuration then
			falling = false
			fallStart = 0

			OnFallDetected(character, duration)
		end
	end)
end

if LocalPlayer.Character then
	SetupCharacterAntiFall(LocalPlayer.Character)
end

characterConnection = LocalPlayer.CharacterAdded:Connect(function(character)
	SetupCharacterAntiFall(character)
end)

WorkspaceBlocks.ChildAdded:Connect(logBlock)

WorkspaceBlocks.ChildRemoved:Connect(unlog)

local function ListAllBlocks()
	local bl = 0
    for i, v in pairs(WorkspaceBlocks:GetChildren()) do
        bl += 1
        if bl % blocksPerTick == 0 then task.wait() end
        logBlock(v)
    end
end

task.spawn(function()
	ListAllBlocks()
end)

task.spawn(function()
	while task.wait(0.05) do
		if noclip then NoclipLoop() end
		local char=LocalPlayer.Character
		if char then
			local hum=char:FindFirstChild("Humanoid")
			if hum then
				if hum.WalkSpeed  ~= walkSpd then hum.WalkSpeed  = walkSpd end
				if hum.JumpHeight ~= jumpH   then hum.JumpHeight = jumpH   end
			end
		end
	end
end)

warn("Initiated")
task.spawn(function()
	while task.wait(0.35) do
		if not autoMineOres then continue end
    	LoopMineAll()
	end
end)

task.spawn(function()
	while task.wait(0.5) do
		for i, v in pairs(Chests:GetChildren()) do
			if instaOpenChests then
				UpdateProximityDuration(v, 0)
			end
			if not autoOpenChests then continue end
			OpenChest(v)
		end
	end
end)

task.spawn(function()
    while true do
        task.wait(cci)

        local now = tick()

        for model, data in pairs(openedChests) do
            if not model or not model.Parent then
                openedChests[model] = nil
            elseif data.LastAttempt and now - data.LastAttempt >= clttl then
                openedChests[model] = nil
            end
        end
    end
end)

local InfoTab   = Window:CreateTab("Info",   4483362458)
local PlayerTab = Window:CreateTab("Player", 4483362458)
local AutoTab   = Window:CreateTab("Auto",   4483362458)
local AfkTab   = Window:CreateTab("AFK",   4483362458)

local dcInvite = "https://discord.gg/"

InfoTab:CreateSection("About")
InfoTab:CreateLabel("Go Mining Script")
InfoTab:CreateParagraph({ Title="Discord:", Content=dcInvite })
InfoTab:CreateButton({
	Name = "Copy to clipboard",
	Callback = function() setclipboard(dcInvite) end,
})
InfoTab:CreateSection("Notes")
InfoTab:CreateParagraph({ Title="v1.1:", Content="Added the afk tab" })
InfoTab:CreateParagraph({ Title="v1:", Content="Added chest functions" })
InfoTab:CreateParagraph({ Title="NOTE:", Content="Jump Height might not be working / This script is still heavily WIP" })
InfoTab:CreateSection("Hotkeys")
InfoTab:CreateLabel("K — Toggle UI")

PlayerTab:CreateSection("Main")
PlayerTab:CreateToggle({ Name="Noclip", CurrentValue=noclip, Flag="noclip",
	Callback=function(v) noclip=v end })
PlayerTab:CreateSlider({ Name="Walk Speed", Range={0,250}, Increment=1,
	CurrentValue=walkSpd, Flag="walkspd",
	Callback=function(v) walkSpd=v end })
PlayerTab:CreateSlider({ Name="Jump Height", Range={0,100}, Increment=0.5,
	CurrentValue=jumpH, Flag="jumph",
	Callback=function(v) jumpH=v end })

AutoTab:CreateSection("Main")
AutoTab:CreateToggle({ Name="Auto Mine Ores", CurrentValue=autoMineOres, Flag="autoMineOres",
	Callback=function(v) autoMineOres=v; if v then LoopMineAll() end end })
AutoTab:CreateSlider({ Name="Minimum Rarity", Range={1,100}, Increment=1, Suffix="k",
	CurrentValue=minRar/1000, Flag="minRar",
	Callback=function(v) minRar=v*1000 end })

AutoTab:CreateSection("Chests")
AutoTab:CreateParagraph({ Title="Instant Open Chests:", Content="On" })
AutoTab:CreateToggle({ Name="Auto Open Chests", CurrentValue=autoOpenChests, Flag="autoMineOres",
	Callback=function(v) autoOpenChests=v end })
--[[AutoTab:CreateToggle({ Name="Instant Chests", CurrentValue=autoMineOres, Flag="instaChests",
	Callback=function(v) instaOpenChests=v end })]]

AutoTab:CreateSection("Whitelist")

local paragraph = AutoTab:CreateParagraph({Title = "Whitelisted ores:", Content = ""})

AutoTab:CreateInput({
   Name = "Add to whitelist",
   CurrentValue = "",
   PlaceholderText = "Ore name",
   RemoveTextAfterFocusLost = true,
   Flag = "Input1",
   Callback = function(text)
		table.insert(whitelist, text)
		local str = table.concat(array, ", ")
		paragraph:Set({Content = str})
   end,
})

AfkTab:CreateSection("Layer Teleportation")
AfkTab:CreateDropdown({ Name="Select Depth", Options=tpDepths, CurrentOption={},
	MultipleOptions=false, Flag="tpDepthSelection",
	Callback=function(o) selectedDepth=o[1] end })
AfkTab:CreateToggle({ Name="Auto teleport after reset", CurrentValue=autoTpAfterReset, Flag="autoTpAfterReset",
	Callback=function(v) autoTpAfterReset=v end })
AfkTab:CreateSection("Anti")
AfkTab:CreateToggle({ Name="Anti Fall", CurrentValue=antiFall, Flag="antiFall",
	Callback=function(v) antiFall=v end })
AfkTab:CreateButton({
	Name = "Execute Anti Afk script",
	Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/evxncodes/mainroblox/main/anti-afk", true))() end,
})
