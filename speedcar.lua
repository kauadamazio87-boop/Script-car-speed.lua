-- Carrega a biblioteca Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- ============================================
-- VARIÁVEIS DE ESTADO
-- ============================================
local velocityMult = 0.025   -- Multiplicador padrão (25 x1000)
local VELOCIDADE_MAXIMA = 500 -- Limite padrão
local freando = false
local brakeMult = 0.15       -- Força do freio padrão (150 x1000)
local flightEnabled = false
local flightSpeed = 1
local defaultCharacterParent

-- ============================================
-- FUNÇÕES AUXILIARES
-- ============================================
local function GetVehicleFromDescendant(Descendant)
	return
		Descendant:FindFirstAncestor(LocalPlayer.Name .. "\'s Car") or
		(Descendant:FindFirstAncestor("Body") and Descendant:FindFirstAncestor("Body").Parent) or
		(Descendant:FindFirstAncestor("Misc") and Descendant:FindFirstAncestor("Misc").Parent) or
		Descendant:FindFirstAncestorWhichIsA("Model")
end

-- ============================================
-- CRIA A JANELA DA RAYFIELD
-- ============================================
local Window = Rayfield:CreateWindow({
   Name = "Universal Vehicle Script",
   LoadingTitle = "Carregando...",
   LoadingSubtitle = "Rayfield Edition",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

-- ============================================
-- ABA: VEÍCULO (ACELERAÇÃO E FREIO)
-- ============================================
local VehicleTab = Window:CreateTab("Veículo", 4483362458)

VehicleTab:CreateSlider({
   Name = "Limite de Velocidade Máxima",
   Range = {100, 2000}, 
   Increment = 50,
   Suffix = "studs/s",
   CurrentValue = 500,
   Flag = "MaxSpeed",
   Callback = function(Value)
       VELOCIDADE_MAXIMA = Value
   end,
})

VehicleTab:CreateSlider({
   Name = "Multiplicador de Aceleração",
   Range = {1, 50},
   Increment = 5,
   Suffix = "x1000",
   CurrentValue = 25,
   Flag = "AccelForce",
   Callback = function(Value)
       velocityMult = Value / 1000
   end,
})

VehicleTab:CreateToggle({
   Name = "Ativar Freio Automático",
   CurrentValue = false,
   Flag = "BrakeToggle",
   Callback = function(State)
       freando = State
   end,
})

VehicleTab:CreateSlider({
   Name = "Força do Freio (Brake Force)",
   Range = {0, 300},
   Increment = 25,
   Suffix = "x1000",
   CurrentValue = 150,
   Flag = "BrakeForce",
   Callback = function(Value)
       brakeMult = Value / 1000
   end,
})

VehicleTab:CreateButton({
   Name = "Parar Veículo Imediatamente",
   Callback = function()
       local Character = LocalPlayer.Character
       if Character and Character:FindFirstChildWhichIsA("Humanoid") then
           local SeatPart = Character.Humanoid.SeatPart
           if SeatPart and SeatPart:IsA("VehicleSeat") then
               SeatPart.AssemblyLinearVelocity = Vector3.zero
               SeatPart.AssemblyAngularVelocity = Vector3.zero
           end
       end
   end,
})

-- ============================================
-- ABA: FLIGHT (VOAR)
-- ============================================
local FlightTab = Window:CreateTab("Flight", 4483362458)

FlightTab:CreateToggle({
   Name = "Ativar Voo",
   CurrentValue = false,
   Flag = "FlightToggle",
   Callback = function(State)
       flightEnabled = State
   end,
})

FlightTab:CreateSlider({
   Name = "Velocidade do Voo",
   Range = {0, 800},
   Increment = 50,
   Suffix = "Speed",
   CurrentValue = 100,
   Flag = "FlightSpeed",
   Callback = function(Value)
       flightSpeed = Value / 100
   end,
})

-- ============================================
-- ABA: SPRINGS
-- ============================================
local SpringsTab = Window:CreateTab("Springs", 4483362458)

SpringsTab:CreateToggle({
   Name = "Mostrar Springs (Molas)",
   CurrentValue = false,
   Flag = "SpringsToggle",
   Callback = function(v)
       local Character = LocalPlayer.Character
       if Character and Character:FindFirstChildWhichIsA("Humanoid") then
           local SeatPart = Character.Humanoid.SeatPart
           if SeatPart and SeatPart:IsA("VehicleSeat") then
               local Vehicle = GetVehicleFromDescendant(SeatPart)
               if Vehicle then
                   for _, SpringConstraint in pairs(Vehicle:GetDescendants()) do
                       if SpringConstraint:IsA("SpringConstraint") then
                           SpringConstraint.Visible = v
                       end
                   end
               end
           end
       end
   end,
})

-- ============================================
-- LOOP PRINCIPAL (FÍSICA REALISTA)
-- ============================================
RunService.Heartbeat:Connect(function()
    local Character = LocalPlayer.Character
    if Character and Character:FindFirstChildWhichIsA("Humanoid") then
        local SeatPart = Character.Humanoid.SeatPart
        if SeatPart and SeatPart:IsA("VehicleSeat") then
            
            local vel = SeatPart.AssemblyLinearVelocity
            local acelerandoAgora = SeatPart.ThrottleFloat > 0

            -- 1. ACELERAÇÃO (Só quando você segura o botão do jogo)
            if acelerandoAgora then
                SeatPart.AssemblyLinearVelocity = vel * Vector3.new(1 + velocityMult, 1, 1 + velocityMult)
            end

            -- 2. DESACELERAÇÃO NATURAL (Quando solta o botão, perde 2% da velocidade por frame)
            if not acelerandoAgora and not freando then
                if vel.Magnitude > 5 then
                    SeatPart.AssemblyLinearVelocity = vel * Vector3.new(0.98, 1, 0.98)
                end
            end

            -- 3. FREIO (Quando ativa o toggle de freio)
            if freando then
                SeatPart.AssemblyLinearVelocity = vel * Vector3.new(1 - brakeMult, 1, 1 - brakeMult)
            end

            -- 4. LIMITE DE VELOCIDADE
            if SeatPart.AssemblyLinearVelocity.Magnitude > VELOCIDADE_MAXIMA then
                SeatPart.AssemblyLinearVelocity = SeatPart.AssemblyLinearVelocity.Unit * VELOCIDADE_MAXIMA
            end
            
        end
    end
end)

-- ============================================
-- LOOP DO FLIGHT (VOAR)
-- ============================================
RunService.Stepped:Connect(function()
	local Character = LocalPlayer.Character
	if flightEnabled == true then
		if Character and typeof(Character) == "Instance" then
			local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
			if Humanoid and typeof(Humanoid) == "Instance" then
				local SeatPart = Humanoid.SeatPart
				if SeatPart and typeof(SeatPart) == "Instance" and SeatPart:IsA("VehicleSeat") then
					local Vehicle = GetVehicleFromDescendant(SeatPart)
					if Vehicle and Vehicle:IsA("Model") then
						Character.Parent = Vehicle
						if not Vehicle.PrimaryPart then
							if SeatPart.Parent == Vehicle then
								Vehicle.PrimaryPart = SeatPart
							else
								Vehicle.PrimaryPart = Vehicle:FindFirstChildWhichIsA("BasePart")
							end
						end
						local PrimaryPartCFrame = Vehicle:GetPrimaryPartCFrame()
						Vehicle:SetPrimaryPartCFrame(CFrame.new(PrimaryPartCFrame.Position, PrimaryPartCFrame.Position + workspace.CurrentCamera.CFrame.LookVector) * (UserInputService:GetFocusedTextBox() and CFrame.new(0, 0, 0) or CFrame.new((UserInputService:IsKeyDown(Enum.KeyCode.D) and flightSpeed) or (UserInputService:IsKeyDown(Enum.KeyCode.A) and -flightSpeed) or 0, (UserInputService:IsKeyDown(Enum.KeyCode.E) and flightSpeed / 2) or (UserInputService:IsKeyDown(Enum.KeyCode.Q) and -flightSpeed / 2) or 0, (UserInputService:IsKeyDown(Enum.KeyCode.S) and flightSpeed) or (UserInputService:IsKeyDown(Enum.KeyCode.W) and -flightSpeed) or 0)))
						SeatPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
						SeatPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
					end
				end
			end
		end
	else
		if Character and typeof(Character) == "Instance" then
			Character.Parent = defaultCharacterParent or Character.Parent
			defaultCharacterParent = Character.Parent
		end
	end
end)

-- ============================================
-- SISTEMA DE JOGOS ESPECÍFICOS
-- ============================================
repeat task.wait(0) until game:IsLoaded() and game.PlaceId > 0

if game.PlaceId == 3351674303 then
	local WayfortTab = Window:CreateTab("Wayfort", 4483362458)
	local dealershipList = {}
	for index, value in pairs(workspace:WaitForChild("Game"):WaitForChild("Dealerships"):WaitForChild("Dealerships"):GetChildren()) do
		table.insert(dealershipList, value.Name)
	end
	WayfortTab:CreateDropdown({
	   Name = "Concessionária (Dealership)",
	   Options = dealershipList,
	   CurrentOption = "",
	   Flag = "WayfortDealership",
	   Callback = function(Option)
	       game:GetService("ReplicatedStorage").Remotes.Location:FireServer("Enter", Option)
	   end,
	})
elseif game.PlaceId == 891852901 then
	local GreenvilleTab = Window:CreateTab("Greenville", 4483362458)
elseif game.PlaceId == 54865335 then
	local WestoverTab = Window:CreateTab("Westover", 4483362458)
elseif game.PlaceId == 5232896677 then
	local PacificoTab = Window:CreateTab("Pacifico", 4483362458)
end

-- ============================================
-- ABA: INFORMAÇÕES / DISCORD
-- ============================================
local InfoTab = Window:CreateTab("Informações", 4483362458)

InfoTab:CreateButton({
   Name = "Copiar Link do Discord",
   Callback = function()
       setclipboard("https://www.discord.com/invite/ENHYznSPmM")
       Rayfield:Notify({
          Title = "Discord",
          Content = "Link copiado para a área de transferência!",
          Duration = 3,
          Image = 4483362458,
       })
   end,
})

print("✅ Script do Carro (Rayfield) atualizado com física realista!")
