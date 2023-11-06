print("Starting Autofarm...")
local StartTime = tick()
local Buildings = workspace.Buildings
local LocalPlayer = game.Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local TELEPORT_SPEED = 75
local GROUND_INTO = 16

local function TP(Position)
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

local function FindDeliveryJob()
    for _, Inst in next, Buildings:GetDescendants() do
        if Inst.Name == "DeliveryJob" then
            return Inst
        end
    end
end

local function Click(Part : BasePart)
    for _, v in next, Part:GetDescendants() do
        if v:IsA("ClickDetector") then
            fireclickdetector(v, 1)
        end
    end
end

local function SineWave(time, maxAmplitude, frequency)
    local sineValue = maxAmplitude * math.sin(2 * math.pi * frequency * time)
    return sineValue
end

local function MoveCharacterToPoint(TargetPoint : Vector3, Speed : number, MaxRadius : number)
    local Character = LocalPlayer.Character
    local CurrentPosition = Character.HumanoidRootPart.Position
    local DistanceToTarget = (TargetPoint - CurrentPosition).Magnitude
    local TimeToReachTarget = DistanceToTarget / Speed

    local StartTime = tick()
    local EndTime = StartTime + TimeToReachTarget

    if MaxRadius then
        while tick() < EndTime and (Character.HumanoidRootPart.Position - TargetPoint).Magnitude < MaxRadius do
            local ElapsedTime = tick() - StartTime
            local LerpAmount = ElapsedTime / TimeToReachTarget
            Character:PivotTo(CFrame.new(CurrentPosition:Lerp(TargetPoint, LerpAmount)))
            RunService.Heartbeat:Wait()
        end
    else
        while tick() < EndTime do
            local ElapsedTime = tick() - StartTime
            local LerpAmount = ElapsedTime / TimeToReachTarget
            Character:PivotTo(CFrame.new(CurrentPosition:Lerp(TargetPoint, LerpAmount)))
            RunService.Heartbeat:Wait()
        end
    end
    
    return true
end

local Hint = Instance.new("Hint", workspace)
local function SetHint(Text : string)
    Hint.Text = Text
end

local Beam = Instance.new("Beam", LocalPlayer.Character.HumanoidRootPart)
Beam.Attachment0 = Instance.new("Attachment", LocalPlayer.Character.HumanoidRootPart)
Beam.Transparency = NumberSequence.new(0)
Beam.LightInfluence = 0
Beam.FaceCamera = true

local BeamRoot = Instance.new("Part", workspace)
BeamRoot.Anchored = true
local BeamTarget = Instance.new("Attachment", BeamRoot)

local function PreformDelivery()
    local DeliveryJob : BasePart = FindDeliveryJob()

    TP(Character.HumanoidRootPart.CFrame - Vector3.new(0, GROUND_INTO, 0))
    SetHint("Traveling to delivery job...")
    BeamTarget.WorldCFrame = DeliveryJob.CFrame

    local HeartbeatConnection = RunService.Heartbeat:Connect(function()
        SetHint(
            "Traveling to delivery job... ("..
            math.floor((DeliveryJob.Position - Vector3.new(0,GROUND_INTO,0) - Character.HumanoidRootPart.Position).Magnitude)
            .." studs left)"
        )
    end)

    MoveCharacterToPoint(DeliveryJob.Position - Vector3.new(0,GROUND_INTO,0), TELEPORT_SPEED)
    TP(DeliveryJob.Position)

    HeartbeatConnection:Disconnect()

    repeat
        wait()
        Click(DeliveryJob)
    until
        LocalPlayer.Backpack:FindFirstChild("Delivery Box") or LocalPlayer.Character:FindFirstChild("Delivery Box")

    local DeliveryBox : Tool = LocalPlayer.Backpack:FindFirstChild("Delivery Box") or LocalPlayer.Character:FindFirstChild("Delivery Box")
    LocalPlayer.Character.Humanoid:EquipTool(DeliveryBox)
    SetHint(DeliveryBox.ToolTip)

    local DeliveryTarget = nil

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

    local Distance = (DeliveryJob.Position - DeliveryTarget.Position).Magnitude
    local TimeToDeliver = Distance / TELEPORT_SPEED
    local WaitStart = tick()

    local TargetCFrame = DeliveryTarget - (LocalPlayer.Character.HumanoidRootPart.CFrame.LookVector * 1.5)
    local OCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame - Vector3.new(0, GROUND_INTO, 0)

    BeamTarget.WorldCFrame = DeliveryTarget

    local HeartbeatConnection; HeartbeatConnection = RunService.Heartbeat:Connect(function()

        TP(OCFrame:Lerp(
            TargetCFrame - Vector3.new(0,GROUND_INTO,0),
            math.clamp((tick() - WaitStart) / TimeToDeliver, 0, 1))
        )

        for _, Part in next, LocalPlayer.Character:GetDescendants() do
            if Part:IsA("BasePart") then
                Part.Velocity = Vector3.new(0, 0, 0)
            end
        end

        SetHint("Delivering " .. DeliveryBox.ToolTip .. ", " .. math.floor(TimeToDeliver - (tick() - WaitStart)).." seconds left.")
    end)

    task.wait(TimeToDeliver)
    HeartbeatConnection:Disconnect()

    if not LocalPlayer.Backpack:FindFirstChild("Delivery Box") and not LocalPlayer.Character:FindFirstChild("Delivery Box") then
        print("Delivery failed! (Delivery Box was lost)")
        return false
    end

    LocalPlayer.Character.Humanoid:EquipTool(DeliveryBox)

    local DeliverAttemptStart = tick()

    repeat

        local x,y,z = SineWave(tick() - DeliverAttemptStart, 1.2, 1), SineWave(tick() - DeliverAttemptStart, 1.2, 0.5), SineWave(tick() - DeliverAttemptStart, 1.2, 0.25)

        if not LocalPlayer.Character:FindFirstChild("Delivery Box") then
            LocalPlayer.Character.Humanoid:EquipTool(DeliveryBox)
        end
        
        RunService.Heartbeat:Wait()
        TP(DeliveryTarget.Position - (LocalPlayer.Character.HumanoidRootPart.CFrame.LookVector * 1.5) + Vector3.new(x,y,z))
    until
        not (LocalPlayer.Character:FindFirstChild("Delivery Box") or LocalPlayer.Backpack:FindFirstChild("Delivery Box"))
end

print("Autofarm started in "..(tick() - StartTime).." seconds.")

while wait() do

    if getgenv().stopautofarm then
        break
    end

    PreformDelivery()

    SetHint("Waiting for delivery cooldown...")
    local WaitStart = tick()
    local OPos = LocalPlayer.Character.HumanoidRootPart.Position
    local HeartbeatConnection = RunService.Heartbeat:Connect(function()
        SetHint("Waiting for delivery cooldown... ("..math.floor(10 - (tick() - WaitStart)).." seconds left)")
        TP(OPos - Vector3.new(0, GROUND_INTO, 0))
    end)
    task.wait(10)
    HeartbeatConnection:Disconnect()
end
