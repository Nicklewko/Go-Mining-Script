local LocalPlayer = game.Players.LocalPlayer

local OreData = require(game.ReplicatedStorage.Modules.OresModule).Ores
local ItemData = require(game.ReplicatedStorage.Modules.ItemsModule)

local MineRemote = game.ReplicatedStorage.Events.ClientRemoteEvents.MineOre
local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jxinxy/alphalibrary/refs/heads/main/main.luau"))()
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local noclip = false
local walkSpd = 45
local jumpH = 30
local antiAfk = false
local autoMineOres = false

local mineRange = 600
local minRar = 100
local blocksPerTick = 25
local maxAttempts = 15
local recipe = nil --"Lucky Staff"

local Window = Rayfield:CreateWindow({
	Name="Astro Hub", Icon=0,
	LoadingTitle="Astro Hub", LoadingSubtitle="By Someone",
	ShowText="Rayfield",
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
Rayfield:Notify({ Title="Loading...", Content="Please wait.", Duration=5, Image=4483362458 })

local WorkspaceBlocks = workspace:WaitForChild("Blocks")

local sorted = {}

local function CheckDistance(p1, p2)
    return (p1 - p2).Magnitude
end

local function unlog(block)
    sorted[block] = nil
end

local function MineBlock(block)
    local hitPos = block:GetPivot().Position
    local camPos = hitPos - Vector3.one * 8
    MineRemote:FireServer(block, hitPos, true, camPos)
    --MineRemote:FireServer(nil, nil, false, nil)
end

local function CanMine(block)
    local hitPos = block:GetPivot().Position
	local root = LocalPlayer and LocalPlayer.Character and LocalPlayer.Character.HumanoidRootPart
	if not root then print("Root missing") return end
    if CheckDistance(hitPos, root.Position) >= mineRange then return false end
    return true
end

local function MineWithCheck(block)
    if sorted[block].Attempt >= maxAttempts then
		warn("Removed:", block)
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

    print("Mining:", block, "Attempt:", sorted[block].Attempt)

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

    sorted[block] = {
        Attempt = 0
    }

    warn("Added:", block)
    MineWithCheck(block)
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
   	--[[while task.wait(5) do
		ListAllBlocks()
	end]]
end)

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

local InfoTab   = Window:CreateTab("Info",   4483362458)
local PlayerTab = Window:CreateTab("Player", 4483362458)
local AutoTab   = Window:CreateTab("Auto",   4483362458)

local dcInvite = "https://discord.gg/"

InfoTab:CreateSection("About")
InfoTab:CreateLabel("Go Mining Script")
InfoTab:CreateParagraph({ Title="Discord:", Content=dcInvite })
InfoTab:CreateButton({
	Name = "Copy to clipboard",
	Callback = function() setclipboard(dcInvite) end,
})
InfoTab:CreateSection("Notes")
InfoTab:CreateParagraph({ Title="NOTE:", Content="Added UI / Player Section and Auto (fOR)" })
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

PlayerTab:CreateSection("Misc")
PlayerTab:CreateToggle({ Name="Anti-AFK (WIP)", CurrentValue=antiAfk, Flag="antiafk",
	Callback=function(v) antiAfk=v end })

AutoTab:CreateSection("Main")
AutoTab:CreateToggle({ Name="Auto Mine Ores", CurrentValue=autoMineOres, Flag="autoMineOres",
	Callback=function(v) autoMineOres=v; if v then LoopMineAll() end end })
AutoTab:CreateSlider({ Name="Minimum Rarity", Range={1,999}, Increment=1, Suffix="k",
	CurrentValue=minRar, Flag="minRar",
	Callback=function(v) minRar=v*1000 end })
