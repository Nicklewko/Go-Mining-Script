local LocalPlayer = game.Players.LocalPlayer
local Character = LocalPlayer.Character
local Root = Character.HumanoidRootPart

local OreData = require(game.ReplicatedStorage.Modules.OresModule).Ores
local ItemData = require(game.ReplicatedStorage.Modules.ItemsModule)

local MineRemote = game.ReplicatedStorage.Events.ClientRemoteEvents.MineOre
local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jxinxy/alphalibrary/refs/heads/main/main.luau"))()

local WorkspaceBlocks = workspace:WaitForChild("Blocks")

local MineRange = 600
local MinRar = 1000
local BlocksPerTick = 100
local MaxAttempts = 15
local Recipe = nil --"Lucky Staff"

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
    if CheckDistance(hitPos, Root.Position) >= MineRange then return false end
    return true
end

local function MineWithCheck(block)
    if sorted[block].Attempt >= MaxAttempts then
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

    if MinRar
        and OreData[block.Name]
        and OreData[block.Name].Rarity
        and OreData[block.Name].Rarity <= MinRar then
        return
    end

    if Recipe
        and ItemData[Recipe]
        and ItemData[Recipe].block
        and not ItemData[Recipe].block.Name then
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
            if bl % BlocksPerTick == 0 then task.wait() end
            MineWithCheck(block)
        end
    end)
    if not succ then
        warn(err)
        return
    end
end

WorkspaceBlocks.ChildAdded:Connect(logBlock)

WorkspaceBlocks.ChildRemoved:Connect(unlog)

task.spawn(function()
    local bl = 0
    for i, v in pairs(WorkspaceBlocks:GetChildren()) do
        bl += 1
        if bl % BlocksPerTick == 0 then task.wait() end
        logBlock(v)
    end
end)

warn("Initiated")
while task.wait(0.35) do
    LoopMineAll()
end
