-- Brainrot Hunter: client HUD
-- Menampilkan spanduk tangkapan dan pengumuman Golden di layar pemain.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local pemain = Players.LocalPlayer
local guiPemain = pemain:WaitForChild("PlayerGui")
local hud = guiPemain:WaitForChild("HunterHUD")
local spanduk = hud:WaitForChild("Banner")

spanduk.Position = UDim2.new(0.1, 0, 0.12, 0)

local token = 0

local function tampilkanSpanduk(teks, emas)
	token = token + 1
	local milikku = token
	spanduk.Text = teks
	if emas then
		spanduk.BackgroundColor3 = Color3.fromRGB(255, 200, 40)
	else
		spanduk.BackgroundColor3 = Color3.fromRGB(60, 220, 120)
	end
	spanduk.Visible = true
	task.delay(3, function()
		if token == milikku then
			spanduk.Visible = false
		end
	end)
end

local umumkanTangkap = ReplicatedStorage:WaitForChild("UmumkanTangkap")
local umumkanGolden = ReplicatedStorage:WaitForChild("UmumkanGolden")

umumkanTangkap.OnClientEvent:Connect(function(teks, emas)
	tampilkanSpanduk(teks, emas)
end)

umumkanGolden.OnClientEvent:Connect(function(teks)
	tampilkanSpanduk(teks, true)
end)
