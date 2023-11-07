print("Starting Autofarm...")
local StartTime = tick()
local Buildings = workspace.Buildings
local Pickaxes = Buildings.Pickaxes
local LocalPlayer = game.Players.LocalPlayer
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if workspace:FindFirstChildOfClass("Hint") then
    workspace:FindFirstChildOfClass("Hint"):Destroy()
end

local TELEPORT_SPEED = 52
local GROUND_INTO = 16
local DEPOSIT_THRESHOLD = 1000

local Util = {
    LerpStatus = {
        ETA = 0,
        Distance = 0,
        Lerping = false
    }
}

function Util:TP(Position)
    if typeof(Position) == "Instance" then
        Position = Position.CFrame
    end
    if typeof(Position) == "Vector3" then
        Position = CFrame.new(Position)
    end
    if typeof(Position) == "CFrame" then
        LocalPlayer.Character:PivotTo(Position)
    else
        warn("[!] Invalid Argument Passed to TP()")
    end
end

function Util:Click(Inst : (Model | BasePart | Folder))

    if Inst:IsA("ClickDetector") then
        fireclickdetector(Inst, 1)
        return
    end

    for _, v in next, Inst:GetDescendants() do
        if v:IsA("ClickDetector") then
            fireclickdetector(v, 1)
        end
    end
end

function Util:SineWave(time, maxAmplitude, frequency)
    local sineValue = maxAmplitude * math.sin(2 * math.pi * frequency * time)
    return sineValue
end

function Util:MoveCharacterToPoint(TargetPoint : Vector3, Speed : number, MaxRadius : number)

    if typeof(TargetPoint) == "CFrame" then
        TargetPoint = TargetPoint.Position
    end

    TargetPoint = TargetPoint * Vector3.new(1, 0, 1) - Vector3.new(0, GROUND_INTO, 0)

    local Character = LocalPlayer.Character
    Character.Humanoid.Sit = true
    local CurrentPosition = Character.HumanoidRootPart.Position * Vector3.new(1, 0, 1) - Vector3.new(0, GROUND_INTO, 0)
    local DistanceToTarget = (TargetPoint - CurrentPosition).Magnitude
    local TimeToReachTarget = DistanceToTarget / Speed

    local StartTime = tick()
    local EndTime = StartTime + TimeToReachTarget

    self.LerpStatus.ETA = TimeToReachTarget
    self.LerpStatus.Distance = DistanceToTarget
    self.LerpStatus.Lerping = true

    if MaxRadius then
        while tick() < EndTime and (Character.HumanoidRootPart.Position - TargetPoint).Magnitude < MaxRadius do
            local ElapsedTime = tick() - StartTime
            self.LerpStatus.ETA = TimeToReachTarget - ElapsedTime
            self.LerpStatus.Distance = (Character.HumanoidRootPart.Position - TargetPoint).Magnitude
            local LerpAmount = ElapsedTime / TimeToReachTarget
            Character:PivotTo(CFrame.new(CurrentPosition:Lerp(TargetPoint, LerpAmount)))
            RunService.Heartbeat:Wait()
        end
    else
        while tick() < EndTime do
            local ElapsedTime = tick() - StartTime
            self.LerpStatus.ETA = TimeToReachTarget - ElapsedTime
            self.LerpStatus.Distance = (Character.HumanoidRootPart.Position - TargetPoint).Magnitude
            local LerpAmount = ElapsedTime / TimeToReachTarget
            Character:PivotTo(CFrame.new(CurrentPosition:Lerp(TargetPoint, LerpAmount)))
            RunService.Heartbeat:Wait()
        end
    end
    
    self.LerpStatus.ETA = 0
    self.LerpStatus.Distance = 0
    self.LerpStatus.Lerping = false
    Character.Humanoid.Sit = false

    return true
end

function Util:GetMoney()
    return LocalPlayer.leaderstats.Bux.Value
end

local Status = {
    Label = Instance.new("Hint", workspace)
}

Status.Label.Text = "Starting Autofarm..."

function Status:Set(Text : string)
    self.Label.Text = Text
end

function Status:AsyncBindToLerp(Prefix : string, Mode)

    if not Mode then
        Mode = {
            ["ETA"] = true
        }
    end

    task.spawn(function()
        repeat wait() until Util.LerpStatus.Lerping == true

        local LerpBind; LerpBind = RunService.RenderStepped:Connect(function()

            if Util.LerpStatus.Lerping == false then
                LerpBind:Disconnect()
            end

            local CurrentString = Prefix

            if Mode["ETA"] then
                CurrentString = CurrentString.." ETA: "..tostring(math.floor(Util.LerpStatus.ETA)).."s"
            end
            if Mode["Distance"] then
                CurrentString = CurrentString.." Distance: "..tostring(math.floor(Util.LerpStatus.Distance)).." studs"
            end

            self.Label.Text = CurrentString
        end)
    end)
    
end

local Mining = {
    Ores = {}
}

function Mining:GetPickaxe()
    if LocalPlayer.Character then
        if LocalPlayer.Character:FindFirstChild("Pickaxe") or LocalPlayer.Backpack:FindFirstChild("Pickaxe") then
            return LocalPlayer.Character:FindFirstChild("Pickaxe") or LocalPlayer.Backpack:FindFirstChild("Pickaxe")
        end
        
        Status:Set("Teleporting to pickaxe...")
        Status:AsyncBindToLerp("Teleporting to pickaxe...", {
            ["ETA"] = true,
            ["Distance"] = true
        })
        Util:MoveCharacterToPoint(Pickaxes:GetPivot(), TELEPORT_SPEED)
        
        repeat
            Util:Click(Pickaxes)
            wait(0.75)
        until
            LocalPlayer.Character:FindFirstChild("Pickaxe") or LocalPlayer.Backpack:FindFirstChild("Pickaxe")
        
        Status:Set("")
        return LocalPlayer.Character:FindFirstChild("Pickaxe") or LocalPlayer.Backpack:FindFirstChild("Pickaxe")
    end
end

function Mining:GetOres()
    local Ores = {}
    for _, v in next, Buildings:GetChildren() do
        if v.Name == "MiningJobRock" then
            table.insert(Ores, v)
        end
    end
    return Ores
end

function Mining:GetRockHealth(Rock : Model)
    return Rock.RockHealth.Value
end

if not LocalPlayer.Character then
    LocalPlayer.CharacterAdded:Wait()
end

local function FindDeliveryJob()
    for _, Inst in next, Buildings:GetDescendants() do
        if Inst.Name == "DeliveryJob" then
            return Inst
        end
    end
end

getgenv().AutoFarm = true

for _, Seat in next, workspace:GetDescendants() do
    if Seat:IsA("Seat") or Seat:IsA("VehicleSeat") then
        Seat:Destroy()
    end
end

for _, v in next, workspace:GetDescendants() do
    if v.Name == "Acid" then
        v:Destroy()
    end
end

print("Autofarm started! (took " .. tostring(tick() - StartTime) .. " seconds)")

while wait() do

    if not getgenv().AutoFarm then
        break
    end

    local DeliveryJob : BasePart = FindDeliveryJob()

    local Money = Util:GetMoney()

    if Money < 83 and not (LocalPlayer.Backpack:FindFirstChild("Pickaxe") or LocalPlayer.Character:FindFirstChild("Pickaxe")) then
        Status:Set("Teleporting to delivery job...")
        Status:AsyncBindToLerp("Teleporting to delivery job...", {
            ["ETA"] = true,
            ["Distance"] = true
        })
        Util:MoveCharacterToPoint(DeliveryJob:GetPivot(), TELEPORT_SPEED)
        repeat
            wait()
            Util:Click(DeliveryJob)
        until
            LocalPlayer.Backpack:FindFirstChild("Delivery Box") or LocalPlayer.Character:FindFirstChild("Delivery Box")
        
        Status:Set("Delivering package...")

        local DeliveryBox = LocalPlayer.Backpack:FindFirstChild("Delivery Box") or LocalPlayer.Character:FindFirstChild("Delivery Box")
        local DeliveryTarget = nil
        LocalPlayer.Character.Humanoid:EquipTool(DeliveryBox)
        repeat
            wait()
            for _, v in next, DeliveryBox:GetDescendants() do
                if v:IsA("Beam") then
                    local Beam : Beam = v
                    DeliveryTarget = Beam.Attachment1.WorldCFrame
                end
            end
        until DeliveryTarget
        LocalPlayer.Character.Humanoid:UnequipTools()

        Status:AsyncBindToLerp("Delivering package...", {
            ["ETA"] = true,
            ["Distance"] = true
        })
        Util:MoveCharacterToPoint(DeliveryTarget.Position, TELEPORT_SPEED)

        LocalPlayer.Character.Humanoid:EquipTool(DeliveryBox)

    local DeliverAttemptStart = tick()

    repeat

        local x,y,z = Util:SineWave(tick() - DeliverAttemptStart, 1.2, 1), Util:SineWave(tick() - DeliverAttemptStart, 1.2, 0.5), Util:SineWave(tick() - DeliverAttemptStart, 1.2, 0.25)

        if not LocalPlayer.Character:FindFirstChild("Delivery Box") then
            LocalPlayer.Character.Humanoid:EquipTool(DeliveryBox)
        end
        
        RunService.Heartbeat:Wait()
        Util:TP(DeliveryTarget.Position - (LocalPlayer.Character.HumanoidRootPart.CFrame.LookVector * 1.5) + Vector3.new(x,y,z))
    until
        (not (LocalPlayer.Character:FindFirstChild("Delivery Box") or LocalPlayer.Backpack:FindFirstChild("Delivery Box")))
        or (tick() - DeliverAttemptStart) > 10
    end

    Status:Set("Getting Pickaxe...")
    local Pickaxe = Mining:GetPickaxe()

    Status:Set("Getting Ores...")
    local Ores = Mining:GetOres()
    local ValidOres = {}

    for _, v : Model in next, Ores do
        if Mining:GetRockHealth(v) > 0 then
            table.insert(ValidOres, v)
        end
    end

    if #ValidOres == 0 then
        Status:Set("No ores found, waiting for respawn...")
        local OPos = LocalPlayer.Character.HumanoidRootPart.Position
        local HeartbeatConnection; HeartbeatConnection = RunService.Heartbeat:Connect(function()
            Util:TP(OPos * Vector3.new(1, 0, 1) - Vector3.new(0, GROUND_INTO, 0))
        end)
        repeat
            wait(3)
            local Ores = Mining:GetOres()
            ValidOres = {}
            for _, v : Model in next, Ores do
                if Mining:GetRockHealth(v) > 0 then
                    table.insert(ValidOres, v)
                end
            end
        until
            #ValidOres > 0
        HeartbeatConnection:Disconnect()
    end

    Status:Set("Teleporting to ore...")

    for _, Ore : Model in next, ValidOres do
        Status:AsyncBindToLerp("Teleporting to ore...", {
            ["ETA"] = true,
            ["Distance"] = true
        })
        Util:MoveCharacterToPoint(Ore:GetPivot(), TELEPORT_SPEED)

        Status:Set("Mining ore...")
        LocalPlayer.Character.Humanoid:EquipTool(Pickaxe)

        local HeartbeatConnection; HeartbeatConnection = RunService.Heartbeat:Connect(function()
            Util:TP(
                CFrame.new(Ore:GetPivot().Position - Vector3.new(0, 3.5, 0), Ore:GetPivot().Position)
            )
            if not LocalPlayer.Character:FindFirstChild("Pickaxe") then
                LocalPlayer.Character.Humanoid:EquipTool(Pickaxe)
            end
        end)

        repeat
            Status:Set("Mining ore... (" .. tostring(Mining:GetRockHealth(Ore)) .. " HP )")
            RunService.Heartbeat:Wait()
            Pickaxe.Damage.Key:FireServer("down")
            wait(0.5)
            for i = 20, 0, -1 do
                Pickaxe.Damage.InflictProp:FireServer(Ore.Main)
                wait(0.05)
            end
        until
            Mining:GetRockHealth(Ore) <= 0
        HeartbeatConnection:Disconnect()
    end

    if Money > DEPOSIT_THRESHOLD then
        Status:Set("Finding ATM...")

        local NearestATM = nil
        local NearestATMDistance = math.huge
        for _, ATM : Model in next, workspace.ATMS:GetChildren() do
            local Distance = (LocalPlayer.Character.HumanoidRootPart.Position - ATM:GetPivot().Position).Magnitude
            if Distance < NearestATMDistance then
                NearestATM = ATM
                NearestATMDistance = Distance
            end
        end

        if NearestATM then
            Status:AsyncBindToLerp("Teleporting to ATM...", {
                ["ETA"] = true,
                ["Distance"] = true
            })
            Util:MoveCharacterToPoint(NearestATM:GetPivot(), TELEPORT_SPEED)
            local HeartbeatConnection; HeartbeatConnection = RunService.Heartbeat:Connect(function()
                Util:TP(NearestATM:GetPivot() - Vector3.new(0, 5, 0))
            end)
            task.wait(1)
            ReplicatedStorage.banker:FireServer("apply", Util:GetMoney(), NearestATM)
            HeartbeatConnection:Disconnect()
        else
            Status:Set("No ATM found!")
            wait(5)
        end
        
    end
end
