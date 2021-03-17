--[[ TODO:

Anit-aim
Hotbar esp
Auto loot
Aimbot improvements
base loot esp
container loot esp [fix]
sleeper esp

]]

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Camera = game:GetService("Workspace").CurrentCamera
local Mouse = Player:GetMouse()

local GameGravity = workspace.Gravity

local UILib = loadstring(game:HttpGet("https://raw.githubusercontent.com/ArtixSoftware/matlua/main/main.lua"))()

local VisualsData = {}
local DrawnObjects = {}

local LastTick = tick()

local FreeCamModule = loadstring(game:HttpGet('https://raw.githubusercontent.com/ArtixSoftware/extras/main/freecammodule.lua', true))()

-- Useful Functions
function Set(t, i, v)
	t[i] = v;
end
function Find(t, v)
    for i,v2 in pairs(t) do
        if v == v2 then
            return i
        end
    end
end

local HUB = {
    Player = {
        Walkspeed = false,
        HighJump = false,
        Spiderman = false,
        AutoSpiderman = false,
        RemoveJumpDelay = false,
        CustomFOV = Camera.FieldOfView,
    },
    Weapon = {
        NoRecoil = false,
        InstantAim = false,
        ChangeViewmodel = false,
        ViewmodelMaterial = Enum.Material.Neon,
        ViewmodelColor = Color3.fromRGB(255,0 ,0),
    },
    Aim = {
        SilentAim = false,
        Aimbot = false,
        Sensitivity = 8,
        VisCheck = true,
        FOV = false,
        FOVCircleColor = Color3.fromRGB(0,0,0),
        FOVSize = 70,
    },
    Game = {
        Autofarm = false,
    },
    Visuals = {
        Player = {
            Name = false,
            Health = false,
            Distance = false,
            Boxes = false,
            BoxColor = Color3.fromRGB(255, 0 ,0),
            BoxVisibleColor = Color3.fromRGB(0, 255, 0),
            BoxesType = "2D",
            Skeleton = false,
            PlayerInfoColor = Color3.fromRGB(150, 0, 0),
            DistanceCheck = false,
            DistanceAllowed = 500,
            VisibleCheck = false,
        },
        Fullbright = false,
        VisibleIndicator = false,
        VisibleCheck = false,
        MaxDistance = 0,

        --// Game Visuals
        ContainerESP = false,
        PlayerHotbarESP = false,
        BrimstoneNodes = false,
        BrimstoneNodesColor = Color3.fromRGB(255, 221, 3),
        IronNodes = false,
        IronNodesColor = Color3.fromRGB(209, 115, 0),
        StoneNodes = false,
        StoneNodesColor = Color3.fromRGB(105, 105, 105),
        Trees = false,
        TreesColor = Color3.fromRGB(61, 31, 31),
        Plants = {
            Mushrooms = false,
            CactusFleshPlant = false,
            Cactus = false,
            ClothPlants = false,
            AloeVera = false,
            MushroomsColor = Color3.fromRGB(61, 31, 31),
            CactusFleshPlantColor = Color3.fromRGB(0, 150, 0),
            CactusColor = Color3.fromRGB(0, 150, 0),
            ClothPlantsColor = Color3.fromRGB(255, 255, 255),
            AloeVeraColor = Color3.fromRGB(0, 130, 0),
        },
        BaseLootESP = false,
        LootESP = false,
        BanditESP = false,
        BanditESPColor = Color3.fromRGB(255,0,0),
        DaggerESP = false,
        DaggerESP = Color3.fromRGB(255, 187, 105),
    },
}

local TargetedPlayerVisible = false
local LastTargetedPlayer
local LocalPlayerHumanoid = Player.Character:WaitForChild("Humanoid")
local AimbotKeybindDown = false

game:GetService("Lighting").Changed:Connect(function()
    if HUB.Visuals.Fullbright then
        game:GetService("Lighting").ClockTime = 14
    end
end)

Camera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
    Camera.FieldOfView = HUB.Player.CustomFOV
end)

function ValidateDrawnObjects()
    for i,v in pairs(DrawnObjects) do
        local Found = false
        for i2,v2 in pairs(VisualsData) do
            for i3,v3 in pairs(v2) do
                if v == v3 then
                    Found = true
                end
            end
        end
        if not Found then
            table.remove(DrawnObjects, i)
            pcall(function()
                v:Remove()
            end)
            v = nil
        end
    end
end

function GetClosestPlayerToCursor()
    local CurrentClosestPlayer
    for _,v in next, Players:GetChildren() do
        if v ~= Player and v.Character and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 and v.Character.PrimaryPart then
            local Pass = true
            local Pos, InViewport = Camera:WorldToViewportPoint(v.Character.PrimaryPart.Position)
            local Magnitude = (Vector2.new(Pos.X, Pos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
            if HUB.Aim.VisCheck == true then
                local RaycastParams = RaycastParams.new()
                RaycastParams.IgnoreWater = true
                RaycastParams.FilterDescendantsInstances = {Player.Character, v.Character}
                RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                local ray = game:GetService("Workspace"):Raycast(Camera.CFrame.Position, (v.Character.PrimaryPart.Position - Camera.CFrame.Position).unit * (Camera.CFrame.Position - v.Character.PrimaryPart.Position).Magnitude, RaycastParams)
                if ray and ray.Instance then
                    Pass = false
                end
            end
            if InViewport and Magnitude <= HUB.Aim.FOVSize and Pass == true then
                CurrentClosestPlayer = v
            end
        end
    end
    return CurrentClosestPlayer
end

local AttachedPlayers = {}
function ESPAttachToPlayer(APlayer)
    local Allowed = true
    for i,v in pairs(AttachedPlayers) do
        if v == APlayer then
            Allowed = false
            break
        end
    end
    if APlayer and Allowed and APlayer ~= Player then
        table.insert(AttachedPlayers, #AttachedPlayers+1, APlayer)

        local InfoFinalText = ""
        local InfoText = Drawing.new("Text")
        InfoText.Visible = false
        InfoText.Size = 15
        InfoText.Center = true
        InfoText.Color = Color3.fromRGB(255,150,0)
        InfoText.Text = InfoFinalText

        local TWODBox = Drawing.new("Quad")
        TWODBox.Filled = false
        TWODBox.Color = HUB.Visuals.Player.BoxColor
        TWODBox.Thickness = 2

        local THREEDBoxOne = Drawing.new("Quad")
        THREEDBoxOne.Filled = false
        THREEDBoxOne.Color = HUB.Visuals.Player.BoxColor
        THREEDBoxOne.Thickness = 2
        local THREEDBoxTwo = Drawing.new("Quad")
        THREEDBoxTwo.Filled = false
        THREEDBoxTwo.Color = HUB.Visuals.Player.BoxColor
        THREEDBoxTwo.Thickness = 2
        local THREEDBoxThree = Drawing.new("Quad")
        THREEDBoxThree.Filled = false
        THREEDBoxThree.Color = HUB.Visuals.Player.BoxColor
        THREEDBoxThree.Thickness = 2
        local THREEDBoxFour = Drawing.new("Quad")
        THREEDBoxFour.Filled = false
        THREEDBoxFour.Color = HUB.Visuals.Player.BoxColor
        THREEDBoxFour.Thickness = 2
        
        local PRRS = RunService.RenderStepped:Connect(function()
            if InfoText then
                if APlayer.Character and APlayer.Character:FindFirstChild("Head") and APlayer.Character:FindFirstChild("Humanoid") then
                    local Pos, InViewport = Camera:WorldToViewportPoint(APlayer.Character.Head.Position)
                    local Pass = true
                    local APlayerVisCheck = VisibleCheck(APlayer)
                    if HUB.Visuals.Player.DistanceCheck then
                        if Player and Player.Character and Player.Character.PrimaryPart and APlayer and APlayer.Character and APlayer.Character.PrimaryPart then
                            if (Player.Character.PrimaryPart.Position - APlayer.Character.PrimaryPart.Position).Magnitude < HUB.Visuals.Player.DistanceAllowed then else
                                Pass = false
                            end
                        end
                    end
                    if HUB.Visuals.Player.VisibleCheck then
                        Pass = APlayerVisCheck
                    end
                    if InViewport and Pass then
                        if HUB.Visuals.Player.Name or HUB.Visuals.Player.Health or HUB.Visuals.Player.Distance then
                            InfoFinalText = ""
                            if HUB.Visuals.Player.Name then
                                InfoFinalText = InfoFinalText .. APlayer.Name .. " | "
                            end
                            if HUB.Visuals.Player.Health then
                                InfoFinalText = InfoFinalText .. "Health: " .. APlayer.Character.Humanoid.MaxHealth .. "/" .. math.ceil(APlayer.Character.Humanoid.Health) .. " | "
                            end
                            if HUB.Visuals.Player.Distance and Player.Character and Player.Character.PrimaryPart then
                                InfoFinalText = InfoFinalText ..  "Distance: " .. math.ceil((APlayer.Character.PrimaryPart.Position - Player.Character.PrimaryPart.Position).Magnitude) .. " | "
                            end
                            InfoText.Visible = true
                            InfoText.Position = Vector2.new(Pos.X, Pos.Y + 3)
                            InfoText.Text = InfoFinalText
                            InfoText.Color = HUB.Visuals.Player.PlayerInfoColor
                        else
                            InfoText.Visible = false
                        end
                        if HUB.Visuals.Player.Boxes then
                            if HUB.Visuals.Player.BoxesType == "2D" then
                                local TWODBoxSize = Vector3.new(2,3,0) * APlayer.Character.Head.Size.Y
                                local TWODStartCF = APlayer.Character.PrimaryPart.CFrame
                                local TopLeft, TLVis = Camera:WorldToViewportPoint((TWODStartCF * CFrame.new(TWODBoxSize.X, TWODBoxSize.Y, 0)).Position)
                                local TopRight, TRVis = Camera:WorldToViewportPoint((TWODStartCF * CFrame.new(-TWODBoxSize.X, TWODBoxSize.Y, 0)).Position)
                                local BottomRight, BRVis = Camera:WorldToViewportPoint((TWODStartCF * CFrame.new(-TWODBoxSize.X, -TWODBoxSize.Y, 0)).Position)
                                local BottomLeft, BLVis = Camera:WorldToViewportPoint((TWODStartCF * CFrame.new(TWODBoxSize.X, -TWODBoxSize.Y, 0)).Position)
                            
                                if TLVis and TRVis and BRVis and BLVis then
                                    TWODBox.PointA = Vector2.new(TopLeft.X, TopLeft.Y)
                                    TWODBox.PointB = Vector2.new(TopRight.X, TopRight.Y)
                                    TWODBox.PointC = Vector2.new(BottomRight.X, BottomRight.Y)
                                    TWODBox.PointD = Vector2.new(BottomLeft.X, BottomLeft.Y)

                                    if APlayerVisCheck then
                                        TWODBox.Color = HUB.Visuals.Player.BoxVisibleColor
                                    else
                                        TWODBox.Color = HUB.Visuals.Player.BoxColor
                                    end

                                    TWODBox.Visible = true
                                else
                                    TWODBox.Visible = false
	                            end
                            else
                                TWODBox.Visible = false
                                if HUB.Visuals.Player.BoxesType == "3D" then

                                    local THREEDBoxSize = Vector3.new(2,3,0) * APlayer.Character.Head.Size.Y
                                    local THREEDStartCF = APlayer.Character.PrimaryPart.CFrame
                                    local TopLeft, TLVis = Camera:WorldToViewportPoint((THREEDStartCF * CFrame.new(THREEDBoxSize.X, THREEDBoxSize.Y, 0)).Position)
                                    local TopRight, TRVis = Camera:WorldToViewportPoint((THREEDStartCF * CFrame.new(-THREEDBoxSize.X, THREEDBoxSize.Y, 0)).Position)
                                    local BottomRight, BRVis = Camera:WorldToViewportPoint((THREEDStartCF * CFrame.new(-THREEDBoxSize.X, -THREEDBoxSize.Y, 0)).Position)
                                    local BottomLeft, BLVis = Camera:WorldToViewportPoint((THREEDStartCF * CFrame.new(THREEDBoxSize.X, -THREEDBoxSize.Y, 0)).Position)
                                
                                    if TLVis and TRVis and BRVis and BLVis then
                                        THREEDBoxOne.PointA = Vector2.new(TopLeft.X - 20, TopLeft.Y)
                                        THREEDBoxOne.PointB = Vector2.new(TopRight.X - 20, TopRight.Y)
                                        THREEDBoxOne.PointC = Vector2.new(BottomRight.X - 20, BottomRight.Y)
                                        THREEDBoxOne.PointD = Vector2.new(BottomLeft.X - 20, BottomLeft.Y)

                                        THREEDBoxTwo.PointA = Vector2.new(TopLeft.X + 20, TopLeft.Y)
                                        THREEDBoxTwo.PointB = Vector2.new(TopRight.X + 20, TopRight.Y)
                                        THREEDBoxTwo.PointC = Vector2.new(BottomRight.X + 20, BottomRight.Y)
                                        THREEDBoxTwo.PointD = Vector2.new(BottomLeft.X + 20, BottomLeft.Y)

                                        THREEDBoxThree.PointA = Vector2.new(TopLeft.X - 20, TopLeft.Y)
                                        THREEDBoxThree.PointB = Vector2.new(TopLeft.X + 20, TopLeft.Y)
                                        THREEDBoxThree.PointC = Vector2.new(BottomLeft.X + 20, BottomLeft.Y)
                                        THREEDBoxThree.PointD = Vector2.new(BottomLeft.X - 20, BottomLeft.Y)

                                        THREEDBoxFour.PointA = Vector2.new(TopRight.X + 20, TopRight.Y)
                                        THREEDBoxFour.PointB = Vector2.new(TopRight.X - 20, TopRight.Y)
                                        THREEDBoxFour.PointC = Vector2.new(BottomRight.X - 20, BottomRight.Y)
                                        THREEDBoxFour.PointD = Vector2.new(BottomRight.X + 20, BottomRight.Y)

                                        if APlayerVisCheck then
                                            THREEDBoxOne.Color = HUB.Visuals.Player.BoxVisibleColor
                                            THREEDBoxTwo.Color = HUB.Visuals.Player.BoxVisibleColor
                                            THREEDBoxThree.Color = HUB.Visuals.Player.BoxVisibleColor
                                            THREEDBoxFour.Color = HUB.Visuals.Player.BoxVisibleColor
                                        else
                                            THREEDBoxOne.Color = HUB.Visuals.Player.BoxColor
                                            THREEDBoxTwo.Color = HUB.Visuals.Player.BoxColor
                                            THREEDBoxThree.Color = HUB.Visuals.Player.BoxColor
                                            THREEDBoxFour.Color = HUB.Visuals.Player.BoxColor
                                        end

                                        THREEDBoxOne.Visible = true
                                        THREEDBoxTwo.Visible = true
                                        THREEDBoxThree.Visible = true
                                        THREEDBoxFour.Visible = true
                                    else
                                        THREEDBoxOne.Visible = false
                                        THREEDBoxTwo.Visible = false
                                        THREEDBoxThree.Visible = false
                                        THREEDBoxFour.Visible = false
                                    end
                                end
                            end
                        else
                            TWODBox.Visible = false

                            THREEDBoxOne.Visible = false
                            THREEDBoxTwo.Visible = false
                            THREEDBoxThree.Visible = false
                            THREEDBoxFour.Visible = false
                        end
                    else
                        InfoText.Visible = false
                        TWODBox.Visible = false

                        THREEDBoxOne.Visible = false
                        THREEDBoxTwo.Visible = false
                        THREEDBoxThree.Visible = false
                        THREEDBoxFour.Visible = false
                    end
                else
                    InfoText.Visible = false
                    TWODBox.Visible = false

                    THREEDBoxOne.Visible = false
                    THREEDBoxTwo.Visible = false
                    THREEDBoxThree.Visible = false
                    THREEDBoxFour.Visible = false
                end
            end
        end)
        Players.PlayerRemoving:Connect(function(PRPlayer)
            if PRPlayer == APlayer then
                if InfoText then
                    InfoText:Remove()
                end
                if TWODBox then
                    TWODBox:Remove()
                end

                if THREEDBoxOne then
                    THREEDBoxOne:Remove()
                end
                if THREEDBoxTwo then
                    THREEDBoxTwo:Remove()
                end
                if THREEDBoxThree then
                    THREEDBoxThree:Remove()
                end
                if THREEDBoxFour then
                    THREEDBoxFour:Remove()
                end

                PRRS:Disconnect()
                local APlayerIndexAP = 0
                for i,v in pairs(AttachedPlayers) do
                    if v == APlayer then
                        APlayerIndexAP = i
                    end
                end
                if APlayerIndexAP == 0 then else
                    table.remove(AttachedPlayers, APlayerIndexAP)
                end
            end
        end)
    end
end

local AttachedObjects = {}
function ESPAttachToObject(AObject, TableArgs)
    local Allowed = true
    for i,v in pairs(AttachedObjects) do
        if v == AObject then
            Allowed = false
            break
        end
    end
    if AObject and Allowed then
        table.insert(AttachedObjects, #AttachedObjects+1, AObject)

        local InfoFinalText = ""
        local InfoText = Drawing.new("Text")
        InfoText.Visible = false
        InfoText.Size = 15
        InfoText.Center = true
        InfoText.Color = Color3.fromRGB(255,150,0)
        InfoText.Text = InfoFinalText
        local ITDestroyed = false
        local PRRS

        local function EndEverythingHere()
            if ITDestroyed == false then
                local AOBjectIndexInTable = 0
                for i,v in pairs(AttachedObjects) do
                    if v == AObject then
                        AOBjectIndexInTable = i
                    end
                end
                if AOBjectIndexInTable == 0 then else
                    table.remove(AttachedObjects, AOBjectIndexInTable)
                end
                ITDestroyed = true
                if PRRS then
                    PRRS:Disconnect()
                end
                if InfoText then
                    InfoText:Remove()
                end
            end
        end

        PRRS = RunService.RenderStepped:Connect(function()
            if InfoText and ITDestroyed == false and AObject then
                local Pos, InViewport = Camera:WorldToViewportPoint(AObject.Position)
                if InViewport then
                    local VarToCheck = HUB
                    local ColorVar
                    for i = 1,#TableArgs,1 do
                        VarToCheck = VarToCheck[TableArgs[i]]
                        if i == #TableArgs then
                            if ColorVar then
                                ColorVar = ColorVar[TableArgs[i] .. "Color"]
                            end
                        else
                            ColorVar = VarToCheck
                        end
                    end
                    if VarToCheck and VarToCheck == true then
                        if Player.Character and Player.Character.PrimaryPart and (Player.Character.PrimaryPart.Position - AObject.Position).Magnitude < 500 then
                            InfoFinalText = AObject.Parent.Name .. " (" ..  math.ceil((Player.Character.PrimaryPart.Position - AObject.Position).Magnitude) .. ")"
                            InfoText.Visible = true
                            InfoText.Position = Vector2.new(Pos.X, Pos.Y + 3)
                            InfoText.Text = InfoFinalText
                            if ColorVar then
                                InfoText.Color = ColorVar
                            else
                                InfoText.Color = Color3.fromRGB(255,150,0)
                            end
                        else
                            if InfoText and ITDestroyed == false then
                                InfoText.Visible = false
                            end
                        end
                    else
                        EndEverythingHere()
                    end
                else
                    if InfoText and ITDestroyed == false then
                        InfoText.Visible = false
                    end
                end
            end
        end)
        
        AObject.Parent.Parent.ChildRemoved:Connect(function(Child)
            if AObject.Parent == Child then
                EndEverythingHere()
            end
        end)
    end
end

function VisibleCheck(TargetPlayer)
    local Pass = true
    if TargetPlayer and TargetPlayer.Character then
        local RaycastParams = RaycastParams.new()
        RaycastParams.IgnoreWater = true
        RaycastParams.FilterDescendantsInstances = {Player.Character, TargetPlayer.Character}
        RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        local ray = game:GetService("Workspace"):Raycast(Camera.CFrame.Position, (TargetPlayer.Character.PrimaryPart.Position - Camera.CFrame.Position).unit * (Camera.CFrame.Position - TargetPlayer.Character.PrimaryPart.Position).Magnitude, RaycastParams)
        if ray and ray.Instance then    
            Pass = false
        end
    end
    return Pass
end

local SpidermanPart = Instance.new("Part", workspace)
SpidermanPart.Anchored = true
SpidermanPart.Transparency = 1

Mouse.TargetFilter = yespart

RunService.Heartbeat:Connect(function()
    if HUB.Player.Spiderman or HUB.Player.AutoSpiderman then
        if Mouse.UnitRay then
            local rparams = RaycastParams.new()
            rparams.FilterType = Enum.RaycastFilterType.Blacklist
            rparams.FilterDescendantsInstances = {Player.Character, SpidermanPart}
            local Raycas = workspace:Raycast(Mouse.UnitRay.Origin, Mouse.UnitRay.Direction * 5, rparams)
            if Raycas then
                if HUB.Player.Spiderman and not HUB.Player.AutoSpiderman then
                    SpidermanPart.Position = Vector3.new(Player.Character.PrimaryPart.Position.X, Player.Character.PrimaryPart.Position.Y - 3.6, Player.Character.PrimaryPart.Position.Z)
                end
                if HUB.Player.AutoSpiderman then
                    SpidermanPart.Position = Vector3.new(Player.Character.PrimaryPart.Position.X, Player.Character.PrimaryPart.Position.Y - 3, Player.Character.PrimaryPart.Position.Z) -- Auto spiderman
                end
            else
                if tick() - LastTick >= 10 then
                    SpidermanPart.Position = Vector3.new(0,0,0)
                end
            end
        end
    else
        if tick() - LastTick >= 10 then
            SpidermanPart.Position = Vector3.new(0,0,0)
        end
    end
    if Player.Character and Player.Character:FindFirstChild("Humanoid") then
        local CharHumanoid = Player.Character:FindFirstChild("Humanoid")
        if HUB.Player.Walkspeed then
            CharHumanoid.WalkSpeed = 32
        end
        if HUB.Player.HighJump then
            CharHumanoid.JumpPower = 60
        end
    end
    if HUB.Game.Autofarm then
        local rparams = RaycastParams.new()
        rparams.FilterType = Enum.RaycastFilterType.Blacklist
        rparams.FilterDescendantsInstances = {Player.Character}
        local Raycas = workspace:Raycast(Mouse.UnitRay.Origin, Mouse.UnitRay.Direction * 50, rparams)
        if Raycas then
            local args = {
                [1] = Raycas.Instance.Parent,
                [2] = Mouse.Hit.Position
            }
            game:GetService("ReplicatedStorage").RemoteEvents.HarvestEvent:FireServer(unpack(args))
        end
    end
    LastTick = tick()
end)

UserInputService.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        AimbotKeybindDown = true
    end
end)

UserInputService.InputEnded:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        AimbotKeybindDown = false
    end
end)

RunService.RenderStepped:Connect(function()
    if HUB.Aim.Aimbot and AimbotKeybindDown then
        local TargetedPlayer = GetClosestPlayerToCursor()
        if TargetedPlayer then
            --TweenService:Create(Camera, TweenInfo.new(0.1 - HUB.Aim.Sensitivity/1000), {CFrame = CFrame.new(Camera.CFrame.p, TargetedPlayer.Character.PrimaryPart.Position)}):Play()
            local PlayerPosition = Camera:WorldToScreenPoint(TargetedPlayer.Character:FindFirstChild("Head").Position)
            local MouseLocation = Camera:WorldToScreenPoint(Mouse.hit.p)
            local MouseXLocation = (PlayerPosition.X - MouseLocation.X) / HUB.Aim.Sensitivity--((11-HUB.Aim.Sensitivity))
            local MouseYLocation = (PlayerPosition.Y - MouseLocation.Y) / HUB.Aim.Sensitivity--((11-HUB.Aim.Sensitivity))
            mousemoverel(MouseXLocation, MouseYLocation)
        end
    end
end)

Players.PlayerRemoving:Connect(function(DPlayer)
    
end)

Players.PlayerAdded:Connect(function(AdPlayer)
    ESPAttachToPlayer(AdPlayer)
end)

for _,v in next, Players:GetPlayers() do
    ESPAttachToPlayer(v)
end

local UI = UILib.Load({
    Title = "Artix Hub | Dust",
    Style = 1,
    SizeX = 500,
    SizeY = 500,
    Theme = "Dark",
})

local RecoilList1 = {}
local RecoilList2 = {}

function ApplyNoRecoil()
    local PlrHotbar = game.ReplicatedStorage.Players:FindFirstChild(Player.Name).Toolbar
    if PlrHotbar then
        for _,v in next, PlrHotbar:GetChildren() do
            if game.ReplicatedStorage.RangedWeapons:FindFirstChild(v.Name) then
                if v:FindFirstChild("SettingsModule") then
                    local weaponSM = require(v.SettingsModule)
                    if weaponSM.MaxRecoil and weaponSM.Recoil and weaponSM.RecoilTValueMax and weaponSM.RecoilReductionMax and weaponSM.KickBack then
                        if weaponSM.MaxRecoil == 0 then else RecoilList1[v.Name].MaxRecoil = weaponSM.MaxRecoil end
                        if weaponSM.Recoil == 0 then else RecoilList1[v.Name].Recoil = weaponSM.Recoil end
                        if weaponSM.RecoilTValueMax == 0 then else RecoilList1[v.Name].RecoilTValueMax = weaponSM.RecoilTValueMax end
                        if weaponSM.RecoilReductionMax == 0 then else RecoilList1[v.Name].RecoilReductionMax = weaponSM.RecoilReductionMax end
                        if weaponSM.KickBack == 0 then else RecoilList1[v.Name].KickBack = weaponSM.KickBack end

                        weaponSM.MaxRecoil = 0
                        weaponSM.Recoil = 0
                        weaponSM.RecoilTValueMax = 0
                        weaponSM.RecoilReductionMax = 0
                        weaponSM.KickBack = 0
                    end
                end
            end
        end
    end
    for _,v in next, game.ReplicatedStorage.RangedWeapons:GetChildren() do
        if v:FindFirstChild("RecoilPattern") then
            for _,v2 in next, v:GetDescendants() do
                if v2.Name == "x" or v2.Name == "y" then
                    table.insert(RecoilList2, #RecoilList2+1, {Instance = v2, v2.Value})
                    v2.Value = 0
                end
            end
        end
        for _,v2 in next, v.Ammo.Types:GetChildren() do
            if v2:FindFirstChild("RecoilStrength") then
                table.insert(RecoilList2, #RecoilList2+1, {Instance = v2.RecoilStrength, v2.RecoilStrength.Value})
                v2.RecoilStrength.Value = 0
            end
        end
    end
end

local UseSpeedList1 = {}
local UseSpeedList2 = {}
function ApplyFastUse()
    local PlrHotbar = game.ReplicatedStorage.Players:FindFirstChild(Player.Name).Toolbar
    if PlrHotbar then
        for _,v in next, PlrHotbar:GetChildren() do
            if v:FindFirstChild("SettingsModule") then
                local weaponSM = require(v.SettingsModule)
                if weaponSM.swingStartWait and weaponSM.swingEndWait then
                    if not UseSpeedList1[v.Name] then
                        UseSpeedList1[v.Name] = {}
                    end
                    if weaponSM.swingStartWait == 0 then else UseSpeedList1[v.Name].swingStartWait = weaponSM.swingStartWait end
                    if weaponSM.swingEndWait == 0 then else UseSpeedList1[v.Name].swingEndWait = weaponSM.swingEndWait end

                    weaponSM.swingStartWait = 0
                    weaponSM.swingEndWait = 0
                end
            end
            if v:FindFirstChild("ItemProperties") and v.ItemProperties:FindFirstChild("UseSpeed") then
                table.insert(UseSpeedList2, #UseSpeedList2+1, {Instance = v.ItemProperties.UseSpeed, Value = v.ItemProperties.UseSpeed.Value})
            end
        end
    end
end

local PlayerRPHotbar = game.ReplicatedStorage.Players:FindFirstChild(Player.Name).Toolbar
if PlayerRPHotbar then
    PlayerRPHotbar.ChildAdded:Connect(function(Child)
        wait(1)
        if HUB.Weapon.NoRecoil then
            ApplyNoRecoil()
        end
        if HUB.Weapon.FastUse then
            ApplyFastUse()
        end
    end)
end

local WeaponPage = UI.New({Title = "Weapon"})
WeaponPage.Toggle({
    Text = "No Recoil",
    Callback = function(value)
        HUB.Weapon.NoRecoil = value
        if value then
            ApplyNoRecoil()
        else
            local PlrHotbar = game.ReplicatedStorage.Players:FindFirstChild(Player.Name).Toolbar
            if PlrHotbar then
                for _,v in next, PlrHotbar:GetChildren() do
                    if game.ReplicatedStorage.RangedWeapons:FindFirstChild(v.Name) then
                        if v:FindFirstChild("SettingsModule") then
                            local weaponSM = require(v.SettingsModule)
                            if weaponSM and weaponSM.MaxRecoil and weaponSM.Recoil and weaponSM.RecoilTValueMax and weaponSM.RecoilReductionMax and weaponSM.KickBack then
                                weaponSM.MaxRecoil = RecoilList1[v.Name].MaxRecoil
                                weaponSM.Recoil = RecoilList1[v.Name].Recoil
                                weaponSM.RecoilTValueMax = RecoilList1[v.Name].RecoilTValueMax
                                weaponSM.RecoilReductionMax = RecoilList1[v.Name].RecoilReductionMax
                                weaponSM.KickBack = RecoilList1[v.Name].KickBack
                            end
                        end
                    end
                end
            end
            for i,v in pairs(RecoilList2) do
                v.Instance = v.Value
            end
            RecoilList2 = {}
        end
    end,
    Enabled = false,
})
WeaponPage.Toggle({
    Text = "Fast Use/Swing",
    Callback = function(value)
        HUB.Weapon.FastUse = value
        if value then
            ApplyFastUse()
        else
            local PlrHotbar = game.ReplicatedStorage.Players:FindFirstChild(Player.Name).Toolbar
            if PlrHotbar then
                for _,v in next, PlrHotbar:GetChildren() do
                    if v:FindFirstChild("SettingsModule") then
                        local weaponSM = require(v.SettingsModule)
                        if weaponSM and weaponSM.swingStartWait and weaponSM.swingEndWait and UseSpeedList1[v.Name] then
                            weaponSM.swingStartWait = UseSpeedList1[v.Name].swingStartWait
                            weaponSM.swingEndWait = UseSpeedList1[v.Name].swingEndWait
                        end
                    end
                end
            end
            for i,v in pairs(UseSpeedList2) do
                v.Instance = v.Value
            end
            UseSpeedList2 = {}
        end
    end,
    Enabled = false,
})
WeaponPage.Toggle({
    Text = "Instant Aim",
    Callback = function(value)
        HUB.Weapon.NoRecoil = value
        if value then
            local PlrHotbar = game.ReplicatedStorage.Players:FindFirstChild(Player.Name).Toolbar
            if PlrHotbar then
                for _,v in next, PlrHotbar:GetChildren() do
                    if game.ReplicatedStorage.RangedWeapons:FindFirstChild(v.Name) then
                        if v:FindFirstChild("SettingsModule") then
                            local weaponSM = require(v.SettingsModule)
                            weaponSM.AimInSpeed = 0
                            weaponSM.AimOutSpeed = 0
                        end
                    end
                end
            end
        end
    end,
    Enabled = false,
})

function RefreshViewmodel()
    if Camera:FindFirstChild("ViewModel") and HUB.Weapon.ChangeViewmodel then
        for _,v in next, Camera:GetDescendants() do
            if v:IsA("Texture") then
                v:Destroy()
            end
            if v:IsA("BasePart") then
                v.Material = HUB.Weapon.ViewmodelMaterial
                v.Color = HUB.Weapon.ViewmodelColor
            end
            if v:IsA("Clothing") then
                v:Destroy()
            end
        end
    end
end

Camera.ChildAdded:Connect(function(Child)
    wait()
    RefreshViewmodel()
end)
WeaponPage.Toggle({
    Text = "Allow viewmodel changes",
    Callback = function(value)
        HUB.Weapon.ChangeViewmodel = value
        if value then
            RefreshViewmodel()
        end
    end,
    Enabled = false,
})
WeaponPage.Dropdown({
    Text = "Viewmodel Material",
    Callback = function(value)
        if value == "Force field" then
            HUB.Weapon.ViewmodelMaterial = Enum.Material.ForceField
            RefreshViewmodel()
        elseif value == "Neon" then
            HUB.Weapon.ViewmodelMaterial = Enum.Material.Neon
            RefreshViewmodel()
        elseif value == "Wood" then
            HUB.Weapon.ViewmodelMaterial = Enum.Material.Wood
            RefreshViewmodel()
        elseif value == "Slate" then
            HUB.Weapon.ViewmodelMaterial = Enum.Material.Slate
            RefreshViewmodel()
        elseif value == "Ice" then
            HUB.Weapon.ViewmodelMaterial = Enum.Material.Ice
            RefreshViewmodel()
        elseif value == "Glass" then
            HUB.Weapon.ViewmodelMaterial = Enum.Material.Glass
            RefreshViewmodel()
        elseif value == "Foil" then
            HUB.Weapon.ViewmodelMaterial = Enum.Material.Foil
            RefreshViewmodel()
        elseif value == "Smooth Plastic" then
            HUB.Weapon.ViewmodelMaterial = Enum.Material.SmoothPlastic
            RefreshViewmodel()
        elseif value == "Metal" then
            HUB.Weapon.ViewmodelMaterial = Enum.Material.Metal
            RefreshViewmodel()
        end
    end,
    Options = {"Neon", "Force field", "Wood", "Slate", "Ice", "Glass", "Foil", "Smooth Plastic", "Metal"},
})
WeaponPage.ColorPicker({
    Text = "Viewmodel Color",
    Default = HUB.Weapon.ViewmodelColor,
    Callback = function(value)
        HUB.Weapon.ViewmodelColor = value
        RefreshViewmodel()
    end,
})


local GamePage = UI.New({Title = "Game"})
GamePage.Toggle({
    Text = "Autofarm",
    Callback = function(value)
        HUB.Game.Autofarm = value
    end,
    Enabled = false,
})
GamePage.Toggle({
    Text = "Hide Name",
    Callback = function(value)
        if Player.PlayerGui:FindFirstChild("MainGui") then
            if value then
                Player.PlayerGui.MainGui.Fullscreen.Inventory.ClothingFrame.PlayerName.Text = "bad at fortnite"
            else
                Player.PlayerGui.MainGui.Fullscreen.Inventory.ClothingFrame.PlayerName.Text = Player.Name
            end
        end
    end,
    Enabled = false,
})
GamePage.Toggle({
    Text = "Base Xray",
    Callback = function(value)
        if value then
            for _,v in next, Workspace.BuiltObjects:GetChildren() do
                if v.PrimaryPart and v.PrimaryPart.Transparency < 1 then
                    v.PrimaryPart.Transparency = 0.7
                end
            end
        else
            for _,v in next, Workspace.BuiltObjects:GetChildren() do
                if v.PrimaryPart then
                    if v.PrimaryPart.Transparency == 0 or v.PrimaryPart.Transparency == 1 then else
                        v.PrimaryPart.Transparency = 0
                    end
                end
            end
        end
    end,
    Enabled = false,
})
GamePage.Toggle({
    Text = "Freecam",
    Callback = function(value)
        if value then
            FreeCamModule:Start()
        else
            FreeCamModule:Stop()
        end
    end,
    Enabled = false,
})

local VisualsPage = UI.New({Title = "Visuals"})
local CrosshairObject = {}
VisualsPage.Toggle({
    Text = "Crosshair",
    Callback = function(value)
        if value then
            CrosshairObject[1] = Drawing.new("Line")
            CrosshairObject[1].Visible = true
            CrosshairObject[1].Color = Color3.fromRGB(255, 255, 255)
            CrosshairObject[1].Thickness = 2
            CrosshairObject[1].From = Vector2.new(Camera.ViewportSize.X / 2 - 15, Camera.ViewportSize.Y / 2  - (game:GetService("GuiService"):GetGuiInset().Y/2))
            CrosshairObject[1].To = Vector2.new(Camera.ViewportSize.X / 2 + 15, Camera.ViewportSize.Y / 2  - (game:GetService("GuiService"):GetGuiInset().Y/2))
            CrosshairObject[2] = Drawing.new("Line")
            CrosshairObject[2].Visible = true
            CrosshairObject[2].Color = Color3.fromRGB(255, 255, 255)
            CrosshairObject[2].Thickness = 2
            CrosshairObject[2].From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2  - (game:GetService("GuiService"):GetGuiInset().Y/2) - 15)
            CrosshairObject[2].To = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2  - (game:GetService("GuiService"):GetGuiInset().Y/2) + 15)
        else
            if CrosshairObject and CrosshairObject[1] and CrosshairObject[2] then
                CrosshairObject[1]:Remove()
                CrosshairObject[2]:Remove()
            end
        end
    end,
    Enabled = false,
})
VisualsPage.ColorPicker({
    Text = "Crosshair Color",
    Default = Color3.fromRGB(255,255,255),
    Callback = function(value)
        if CrosshairObject and CrosshairObject[1] and CrosshairObject[2] then
            CrosshairObject[1].Color = value
            CrosshairObject[2].Color = value
        end
    end,
})
VisualsPage.Toggle({
    Text = "Player Name",
    Callback = function(value)
        HUB.Visuals.Player.Name = value
    end,
    Enabled = false,
})
VisualsPage.Toggle({
    Text = "Player Boxes",
    Callback = function(value)
        HUB.Visuals.Player.Boxes = value
    end,
    Enabled = false,
})
VisualsPage.Dropdown({
    Text = "Boxes Type",
    Callback = function(value)
        HUB.Visuals.Player.BoxesType = value
    end,
    Options = {"2D", "3D"},
})
VisualsPage.Toggle({
    Text = "Player Health",
    Callback = function(value)
        HUB.Visuals.Player.Health = value
    end,
    Enabled = false,
})
VisualsPage.Toggle({
    Text = "Player Distance",
    Callback = function(value)
        HUB.Visuals.Player.Distance = value
    end,
    Enabled = false,
})
VisualsPage.Toggle({
    Text = "Player ESP Visible Check",
    Callback = function(value)
        HUB.Visuals.Player.VisibleCheck = value
    end,
    Enabled = false,
})
VisualsPage.Toggle({
    Text = "Player Distance Check",
    Callback = function(value)
        HUB.Visuals.Player.DistanceCheck = value
    end,
    Enabled = false,
})
VisualsPage.Slider({
    Text = "Distance Allowed: ",
    Def = HUB.Visuals.Player.DistanceAllowed,
    Min = 1,
    Max = 2000,
    Callback = function(value)
        HUB.Visuals.Player.DistanceAllowed = value
    end,
})

for _,v in next, Workspace.ScavZones:GetChildren() do
    v.ChildAdded:Connect(function(Child)
        wait(1)
        local v2 = Child
        if v2.PrimaryPart and v2.Name ~= "Dagger" and HUB.Visuals.BanditESP then
            ESPAttachToObject(v2.PrimaryPart, {"Visuals", "BanditESP"})
        end
        if v2.PrimaryPart and v2.Name == "Dagger" and HUB.Visuals.DaggerESP then
            ESPAttachToObject(v2.PrimaryPart, {"Visuals", "DaggerESP"})
        end
    end)
    --[[for _,v2 in next, v:GetChildren() do
        if v2.PrimaryPart and v2.Name ~= "Dagger" then
            ESPAttachToObject(v2.PrimaryPart, {"Visuals", "BanditESP"})
        end
    end]]
end

Workspace.Containers.ChildAdded:Connect(function(Child)
    wait(1)
    local v2 = Child
    if v2.PrimaryPart and v2.Name == "Container" and HUB.Visuals.ContainerESP then
        ESPAttachToObject(v2.PrimaryPart, {"Visuals", "ContainerESP"})
    end
end)

VisualsPage.Toggle({
    Text = "Container ESP",
    Callback = function(value)
        HUB.Visuals.ContainerESP = value
        if value then
            for _,v in next, Workspace.Containers:GetChildren() do
                if v2.PrimaryPart and v2.Name == "Container" then
                    ESPAttachToObject(v2.PrimaryPart, {"Visuals", "ContainerESP"})
                end
            end
        end
    end,
    Enabled = false,
})

VisualsPage.Toggle({
    Text = "Bandit ESP",
    Callback = function(value)
        HUB.Visuals.BanditESP = value
        if value then
            for _,v in next, Workspace.ScavZones:GetChildren() do
                for _,v2 in next, v:GetChildren() do
                    if v2.PrimaryPart and v2.Name ~= "Dagger" then
                        ESPAttachToObject(v2.PrimaryPart, {"Visuals", "BanditESP"})
                    end
                end
            end
        end
    end,
    Enabled = false,
})
VisualsPage.Toggle({
    Text = "Dagger ESP",
    Callback = function(value)
        HUB.Visuals.DaggerESP = value
        if value then
            for _,v in next, Workspace.ScavZones:GetChildren() do
                for _,v2 in next, v:GetChildren() do
                    if v2.PrimaryPart and v2.Name == "Dagger" then
                        ESPAttachToObject(v2.PrimaryPart, {"Visuals", "DaggerESP"})
                    end
                end
            end
        end
    end,
    Enabled = false,
})
VisualsPage.Toggle({
    Text = "Fullbright",
    Callback = function(value)
        HUB.Visuals.Fullbright = value
        game:GetService("Lighting").ClockTime = 14
    end,
    Enabled = false
})

for _,v in next, Workspace.SpawnerZones.OreNodes:GetChildren() do
    v.ChildAdded:Connect(function(Child)
        wait(1)
        local v2 = Child
        if v2.PrimaryPart then
            if v2.Name == "StoneNode" and HUB.Visuals.StoneNodes then
                ESPAttachToObject(v2.PrimaryPart, {"Visuals", "StoneNodes"})
            elseif v2.Name == "IronNode" and HUB.Visuals.IronNodes then
                ESPAttachToObject(v2.PrimaryPart, {"Visuals", "IronNodes"})
            elseif v2.Name == "SulfurNode" and HUB.Visuals.BrimstoneNodes then
                ESPAttachToObject(v2.PrimaryPart, {"Visuals", "BrimstoneNodes"})
            end
        end
    end)
    --[[for _,v2 in next, v:GetChildren() do
        if v2.PrimaryPart then
            if v2.Name == "StoneNode" then
                ESPAttachToObject(v2.PrimaryPart, {"Visuals", "StoneNodes"})
            elseif v2.Name == "IronNode" then
                ESPAttachToObject(v2.PrimaryPart, {"Visuals", "IronNodes"})
            elseif v2.Name == "SulfurNode" then
                ESPAttachToObject(v2.PrimaryPart, {"Visuals", "BrimstoneNodes"})
            end
        end
    end]]
end

for _,v in next, Workspace.SpawnerZones.Plants:GetChildren() do
    v.ChildAdded:Connect(function(Child)
        wait(1)
        local v2 = Child
        if v2.PrimaryPart then
            if v2.Name == "AloeVera" and HUB.Visuals.Plants.AloeVera then
                ESPAttachToObject(v2.PrimaryPart, {"Visuals", "Plants", "AloeVera"})
            elseif v2.Name == "Cactus1" or v2.Name == "Cactus2" or v2.Name == "Cactus3" and HUB.Visuals.Plants.Cactus then
                ESPAttachToObject(v2.PrimaryPart, {"Visuals", "Plants", "Cactus"})
            elseif v2.Name == "Opuntia1" or v2.Name == "Opuntia2" and HUB.Visuals.Plants.CactusFleshPlant then
                ESPAttachToObject(v2.PrimaryPart, {"Visuals", "Plants", "CactusFleshPlant"})
            elseif v2.Name == "Mushrooms" and HUB.Visuals.Plants.Mushrooms then
                ESPAttachToObject(v2.PrimaryPart, {"Visuals", "Plants", "Mushrooms"})
            elseif v2.Name == "Nettle" and HUB.Visuals.Plants.ClothPlants then
                ESPAttachToObject(v2.PrimaryPart, {"Visuals", "Plants", "ClothPlants"})
            end
        end
    end)
    --[[for _,v2 in next, v:GetChildren() do
        if v2.PrimaryPart then
            if v2.Name == "AloeVera" then
                ESPAttachToObject(v2.PrimaryPart, {"Visuals", "Plants", "AloeVera"})
            elseif v2.Name == "Cactus1" or v2.Name == "Cactus2" or v2.Name == "Cactus3" then
                ESPAttachToObject(v2.PrimaryPart, {"Visuals", "Plants", "Cactus"})
            elseif v2.Name == "Opuntia1" or v2.Name == "Opuntia2" then
                ESPAttachToObject(v2.PrimaryPart, {"Visuals", "Plants", "CactusFleshPlant"})
            elseif v2.Name == "Mushrooms" then
                ESPAttachToObject(v2.PrimaryPart, {"Visuals", "Plants", "Mushrooms"})
            elseif v2.Name == "Nettle" then
                ESPAttachToObject(v2.PrimaryPart, {"Visuals", "Plants", "ClothPlants"})
            end
        end
    end]]
end

VisualsPage.Toggle({
    Text = "Tree ESP",
    Callback = function(value)
        HUB.Visuals.Trees = value
        if value then
            for _,v in next, Workspace.SpawnerZones.Trees:GetChildren() do
                for _,v2 in next, v:GetChildren() do
                    if v2.PrimaryPart then
                        ESPAttachToObject(v2.PrimaryPart, {"Visuals", "Trees"})
                    end
                end
            end
        end
    end,
    Enabled = false,
})

VisualsPage.Toggle({
    Text = "Stone Node ESP",
    Callback = function(value)
        HUB.Visuals.StoneNodes = value
        if value then
            for _,v in next, Workspace.SpawnerZones.OreNodes:GetChildren() do
                for _,v2 in next, v:GetChildren() do
                    if v2.PrimaryPart then
                        if v2.Name == "StoneNode" then
                            ESPAttachToObject(v2.PrimaryPart, {"Visuals", "StoneNodes"})
                        end
                    end
                end
            end
        end
    end,
    Enabled = false,
})
VisualsPage.Toggle({
    Text = "Iron Node ESP",
    Callback = function(value)
        HUB.Visuals.IronNodes = value
        if value then
            for _,v in next, Workspace.SpawnerZones.OreNodes:GetChildren() do
                for _,v2 in next, v:GetChildren() do
                    if v2.PrimaryPart then
                        if v2.Name == "IronNode" then
                            ESPAttachToObject(v2.PrimaryPart, {"Visuals", "IronNodes"})
                        end
                    end
                end
            end
        end
    end,
    Enabled = false,
})
VisualsPage.Toggle({
    Text = "Brimstone Node ESP",
    Callback = function(value)
        HUB.Visuals.BrimstoneNodes = value
        if value then
            for _,v in next, Workspace.SpawnerZones.OreNodes:GetChildren() do
                for _,v2 in next, v:GetChildren() do
                    if v2.PrimaryPart then
                        if v2.Name == "SulfurNode" then
                            ESPAttachToObject(v2.PrimaryPart, {"Visuals", "BrimstoneNodes"})
                        end
                    end
                end
            end
        end
    end,
    Enabled = false,
})
VisualsPage.Toggle({
    Text = "Cloth Plants ESP",
    Callback = function(value)
        HUB.Visuals.Plants.ClothPlants = value
        if value then
            for _,v in next, Workspace.SpawnerZones.Plants:GetChildren() do
                for _,v2 in next, v:GetChildren() do
                    if v2.PrimaryPart then
                        if v2.Name == "Nettle" then
                            ESPAttachToObject(v2.PrimaryPart, {"Visuals", "Plants", "ClothPlants"})
                        end
                    end
                end
            end
        end
    end,
    Enabled = false,
})
VisualsPage.Toggle({
    Text = "Cactus ESP",
    Callback = function(value)
        HUB.Visuals.Plants.Cactus = value
        if value then
            for _,v in next, Workspace.SpawnerZones.Plants:GetChildren() do
                for _,v2 in next, v:GetChildren() do
                    if v2.PrimaryPart then
                        if v2.Name == "Cactus1" or v2.Name == "Cactus2" or v2.Name == "Cactus3" then
                            ESPAttachToObject(v2.PrimaryPart, {"Visuals", "Plants", "Cactus"})
                        end
                    end
                end
            end
        end
    end,
    Enabled = false,
})
VisualsPage.Toggle({
    Text = "Cactus Flesh Plants ESP",
    Callback = function(value)
        HUB.Visuals.Plants.CactusFleshPlant = value
        if value then
            for _,v in next, Workspace.SpawnerZones.Plants:GetChildren() do
                for _,v2 in next, v:GetChildren() do
                    if v2.PrimaryPart then
                        if v2.Name == "Opuntia1" or v2.Name == "Opuntia2" then
                            ESPAttachToObject(v2.PrimaryPart, {"Visuals", "Plants", "CactusFleshPlant"})
                        end
                    end
                end
            end
        end
    end,
    Enabled = false,
})
VisualsPage.Toggle({
    Text = "Mushrooms ESP",
    Callback = function(value)
        HUB.Visuals.Plants.Mushrooms = value
        if value then
            for _,v in next, Workspace.SpawnerZones.Plants:GetChildren() do
                for _,v2 in next, v:GetChildren() do
                    if v2.PrimaryPart then
                        if v2.Name == "Mushrooms" then
                            ESPAttachToObject(v2.PrimaryPart, {"Visuals", "Plants", "Mushrooms"})
                        end
                    end
                end
            end
        end
    end,
    Enabled = false,
})
VisualsPage.Toggle({
    Text = "Aloe Vera ESP",
    Callback = function(value)
        HUB.Visuals.Plants.AloeVera = value
        if value then
            for _,v in next, Workspace.SpawnerZones.Plants:GetChildren() do
                for _,v2 in next, v:GetChildren() do
                    if v2.PrimaryPart then
                        if v2.Name == "AloeVera" then
                            ESPAttachToObject(v2.PrimaryPart, {"Visuals", "Plants", "AloeVera"})
                        end
                    end
                end
            end
        end
    end,
    Enabled = false,
})

local AimPage = UI.New({Title = "Aim"})
AimPage.Toggle({
    Text = "Aimbot",
    Callback = function(value)
        HUB.Aim.Aimbot = value
    end,
    Enabled = false,
})
AimPage.Toggle({
    Text = "Visible Check",
    Callback = function(value)
        HUB.Aim.VisCheck = value
    end,
    Enabled = false,
})
local DrawingFOVCircle
AimPage.Slider({
    Text = "FOV",
    Callback = function(value)
        HUB.Aim.FOVSize = value
        if DrawingFOVCircle then
            DrawingFOVCircle.Radius = HUB.Aim.FOVSize
            DrawingFOVCircle.Color = HUB.Aim.FOVCircleColor
            DrawingFOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2  - (game:GetService("GuiService"):GetGuiInset().Y/2))
        end
    end,
    Min = 5,
    Max = 300,
    Def = 70,
})
AimPage.Toggle({
    Text = "Show FOV",
    Callback = function(value)
        HUB.Aim.FOV = value

        if HUB.Aim.FOV == true then
            if DrawingFOVCircle then else
                local TDrawingFOVCircle = Drawing.new("Circle")
		        TDrawingFOVCircle.Thickness = 2
		        TDrawingFOVCircle.NumSides = 40
		        TDrawingFOVCircle.Radius = HUB.Aim.FOVSize
		        TDrawingFOVCircle.Visible = true
		        TDrawingFOVCircle.Filled = false
		        TDrawingFOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2  - (game:GetService("GuiService"):GetGuiInset().Y/2))
                TDrawingFOVCircle.Color = HUB.Aim.FOVCircleColor
                DrawingFOVCircle = TDrawingFOVCircle
            end
        else
            if DrawingFOVCircle then
                DrawingFOVCircle:Remove()
                DrawingFOVCircle = nil
            end
        end
    end,
    Enabled = false,
})
AimPage.ColorPicker({
    Text = "FOV Circle Color",
    Default = HUB.Aim.FOVCircleColor,
    Callback = function(value)
        HUB.Aim.FOVCircleColor = value
        if DrawingFOVCircle then
            DrawingFOVCircle.Color = HUB.Aim.FOVCircleColor
        end
    end,
})
AimPage.Slider({
    Text = "Sensitivity",
    Callback = function(value)
        HUB.Aim.Sensitivity = value
    end,
    Min = 1,
    Max = 10,
    Def  = 8,
    Enabled = false,
})
--[[AimPage.Toggle({
    Text = "Silent Aim",
    Callback = function(value)
        HUB.Aim.SilentAim = value
    end,
    Enabled = false,
})]]

local PlayerPage = UI.New({Title = "Player"})
PlayerPage.Toggle({
    Text = "Speed",
    Callback = function(value)
        HUB.Player.Walkspeed = value
        if HUB.Player.Walkspeed and Player.Character and Player.Character:FindFirstChild("Humanoid") then
            Player.Character.Humanoid.WalkSpeed = 32
        else
            Player.Character.Humanoid.WalkSpeed = 9
        end
    end,
    Enabled = false,
})
PlayerPage.Toggle({
    Text = "High Jump",
    Callback = function(value)
        HUB.Player.HighJump = value
        if HUB.Player.HighJump and Player.Character and Player.Character:FindFirstChild("Humanoid") then
            Player.Character.Humanoid.JumpPower = 60
        else
            Player.Character.Humanoid.JumpPower = 34
        end
    end,
    Enabled = false,
})
PlayerPage.Toggle({
    Text = "Remove Jump Delay",
    Callback = function(value)
        HUB.Player.RemoveJumpDelay = value
        if Player.PlayerGui:FindFirstChild("JumpCooldown") then
            if value then
                Player.PlayerGui:FindFirstChild("JumpCooldown").Disabled = true
            else
                Player.PlayerGui:FindFirstChild("JumpCooldown").Disabled = false
            end
        end
    end,
    Enabled = false,
})
PlayerPage.Toggle({
    Text = "Thirdperson",
    Callback = function(value)
        if value then
            Player.CameraMode = Enum.CameraMode.Classic
            Player.CameraMaxZoomDistance = 20
            Player.CameraMinZoomDistance = 20
        else
            Player.CameraMode = Enum.CameraMode.LockFirstPerson
            Player.CameraMaxZoomDistance = 0.5
            Player.CameraMinZoomDistance = 0.5
        end
    end,
    Enabled = false,
})
PlayerPage.Toggle({
    Text = "Spiderman",
    Callback = function(value)
        HUB.Player.Spiderman = value
    end,
    Enabled = false,
})
PlayerPage.Toggle({
    Text = "Auto Climb/Spiderman",
    Callback = function(value)
        HUB.Player.AutoSpiderman = value
    end,
    Enabled = false,
})
PlayerPage.Slider({
    Text = "Hip Height",
    Min = 1,
    Max = 50,
    Def = LocalPlayerHumanoid.HipHeight,
    Callback = function(value)
        if LocalPlayerHumanoid then
            LocalPlayerHumanoid.HipHeight = value
        end
    end,
})
PlayerPage.Slider({
    Text = "Custom FOV",
    Min = 20,
    Max = 120,
    Def = HUB.Player.CustomFOV,
    Callback = function(value)
        HUB.Player.CustomFOV = value
        Camera.FieldOfView = HUB.Player.CustomFOV
    end,
})

local ColorsPage = UI.New({Title = "Colors"})
ColorsPage.ColorPicker({
    Text = "Player Info ESP Color",
    Default = HUB.Visuals.Player.PlayerInfoColor,
    Callback = function(value)
        HUB.Visuals.Player.PlayerInfoColor = value
    end,
})
ColorsPage.ColorPicker({
    Text = "Player Box ESP Invisible Color",
    Default = HUB.Visuals.Player.BoxColor,
    Callback = function(value)
        HUB.Visuals.Player.BoxColor = value
    end,
})
ColorsPage.ColorPicker({
    Text = "Player Box ESP Visible Color",
    Default = HUB.Visuals.Player.BoxVisibleColor,
    Callback = function(value)
        HUB.Visuals.Player.BoxVisibleColor = value
    end,
})
ColorsPage.ColorPicker({
    Text = "Tree ESP Color",
    Default = HUB.Visuals.TreesColor,
    Callback = function(value)
        HUB.Visuals.TreesColor = value
    end,
})
ColorsPage.ColorPicker({
    Text = "Stone Node ESP Color",
    Default = HUB.Visuals.StoneNodesColor,
    Callback = function(value)
        HUB.Visuals.StoneNodesColor = value
    end,
})
ColorsPage.ColorPicker({
    Text = "Iron Node ESP Color",
    Default = HUB.Visuals.IronNodesColor,
    Callback = function(value)
        HUB.Visuals.IronNodesColor = value
    end,
})
ColorsPage.ColorPicker({
    Text = "Sulfur Node ESP Color",
    Default = HUB.Visuals.BrimstoneNodesColor,
    Callback = function(value)
        HUB.Visuals.BrimstoneNodesColor = value
    end,
})
ColorsPage.ColorPicker({
    Text = "Cloth Plant ESP Color",
    Default = HUB.Visuals.Plants.ClothPlantsColor,
    Callback = function(value)
        HUB.Visuals.Plants.ClothPlantsColor = value
    end,
})
ColorsPage.ColorPicker({
    Text = "Mushroom ESP Color",
    Default = HUB.Visuals.Plants.MushroomsColor,
    Callback = function(value)
        HUB.Visuals.Plants.MushroomsColor = value
    end,
})
ColorsPage.ColorPicker({
    Text = "Cactus ESP Color",
    Default = HUB.Visuals.Plants.CactusColor,
    Callback = function(value)
        HUB.Visuals.Plants.CactusColor = value
    end,
})
ColorsPage.ColorPicker({
    Text = "Cactus Flesh Plant ESP Color",
    Default = HUB.Visuals.Plants.CactusFleshPlantColor,
    Callback = function(value)
        HUB.Visuals.Plants.CactusFleshPlantColor = value
    end,
})
ColorsPage.ColorPicker({
    Text = "Aloe Vera ESP Color",
    Default = HUB.Visuals.Plants.AloeVeraColor,
    Callback = function(value)
        HUB.Visuals.Plants.AloeVeraColor = value
    end,
})

local FPSBoostPage = UI.New({Title = "FPS Boosts"})
FPSBoostPage.Button({
    Text = "Remove Textures",
    Callback = function()
        for _,v in next, Workspace:GetDescendants() do
            if v:IsA("Texture") then
                v:Destroy()
            else
                if v:IsA("MeshPart") then
                    v.TextureID = 0
                else
                    if v.Name == "SurfaceAppearance" then
                        v:Destroy()
                    end
                end
            end
        end
    end,
})
FPSBoostPage.Button({
    Text = "Remove Leaves",
    Callback = function()
        for _,v in next, Workspace.SpawnerZones.Trees:GetDescendants() do
            if v.Name == "Leaf" then
                v:Destroy()
            end
        end
    end,
})
FPSBoostPage.Toggle({
    Text = "Global Shadows",
    Callback = function(value)
        game.Lighting.GlobalShadows = value
    end,
    Enabled = true,
})

Player.CharacterAdded:Connect(function(Char)
    LocalPlayerHumanoid = Char:WaitForChild("Humanoid")
end)

local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
local oldIndex = mt.__index
if setreadonly then setreadonly(mt, false) else make_writeable(mt, true) end
local namecallMethod = getnamecallmethod or get_namecall_method
local newClose = newcclosure or function(f) return f end
LocalPlayerHumanoid.Died:Connect(function()
    LocalPlayerHumanoid.WalkSpeed = 19
    LocalPlayerHumanoid.JumpPower = 34
end)
mt.__index = newcclosure(function(Self, Key)
    if LocalPlayerHumanoid then
        if not checkcaller() and Self == LocalPlayerHumanoid and Key == "WalkSpeed" then
            return 9
        end
        if not checkcaller() and Self == LocalPlayerHumanoid and Key == "JumpPower" then
            return 34
        end
        if not checkcaller() and Self == LocalPlayerHumanoid and Key == "JumpPower" then
            return 34
        end
        if not checkcaller() and Self == LocalPlayerHumanoid and Key == "HipHeight" then
            return 1.85
        end
    end

    return oldIndex(Self, Key)
end)

mt.__namecall = newClose(function(...)
    local method = namecallMethod()
    local args = {...}

    --[[if tostring(method) == "FireServer" and tostring(args[1]) == "Projectile" and HUB.Aim.SilentAim then
        print(args[2], args[3])
        local GCPTC = GetClosestPlayerToCursor()
        if GCPTC then
            local Head = GCPTC.Character.Head
            args[2] = Head.Position
            args[3] = Head.Position.Y .. "posY" .. Player.UserId .. "Id" .. tick()
        end
        print(args[2], args[3])
    end]]

    return oldNamecall(...)
end)

if setreadonly then setreadonly(mt, true) else make_writeable(mt, false) end
