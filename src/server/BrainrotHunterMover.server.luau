-- Brainrot Hunter: penggerak patroli
-- Las semua aksesori ke Body, lalu gerakkan Body bolak-balik dengan tween.

local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")

local folderBrainrot = Workspace:WaitForChild("Brainrots")
local goldenStorage = ServerStorage:WaitForChild("GoldenStorage")

local KECEPATAN = {
	TungTung = 4,
	Tralala = 4,
	Patapim = 4,
	Lirili = 5,
	Bananini = 5,
	Bombardiro = 6.5,
	Golden = 10,
}

local arahPatroli = {}
local tweenAktif = {}
local patroliJalan = {}

local function kenaliTipe(model)
	local nama = model.Name:gsub("^Char", ""):gsub("%d+$", "")
	if KECEPATAN[nama] then
		return nama
	end
	return nil
end

local function lasModel(model)
	local badan = model:FindFirstChild("Body")
	if not badan then
		return
	end
	badan.Anchored = true
	for _, bagian in ipairs(model:GetDescendants()) do
		if bagian:IsA("BasePart") and bagian ~= badan then
			local las = Instance.new("WeldConstraint")
			las.Part0 = badan
			las.Part1 = bagian
			las.Parent = bagian
			bagian.Anchored = false
		end
	end
end

local function mulaiPatroli(model)
	if patroliJalan[model] then
		return
	end
	patroliJalan[model] = true
	task.spawn(function()
		local badan = model:FindFirstChild("Body")
		local kunci = kenaliTipe(model)
		if not badan or not kunci then
			patroliJalan[model] = nil
			return
		end
		local cepat = KECEPATAN[kunci]
		local langkah = arahPatroli[model] or Vector3.new(8, 0, 0)
		local durasi = langkah.Magnitude / cepat
		while model.Parent == folderBrainrot do
			local awal = badan.CFrame
			local maju = TweenService:Create(
				badan,
				TweenInfo.new(durasi, Enum.EasingStyle.Linear),
				{ CFrame = awal * CFrame.new(langkah) }
			)
			tweenAktif[model] = maju
			maju:Play()
			task.wait(durasi)
			if model.Parent ~= folderBrainrot then
				break
			end
			local kembali = TweenService:Create(
				badan,
				TweenInfo.new(durasi, Enum.EasingStyle.Linear),
				{ CFrame = awal }
			)
			tweenAktif[model] = kembali
			kembali:Play()
			task.wait(durasi)
		end
		tweenAktif[model] = nil
		patroliJalan[model] = nil
	end)
end

folderBrainrot.ChildAdded:Connect(function(anak)
	if anak:IsA("Model") then
		mulaiPatroli(anak)
	end
end)

folderBrainrot.ChildRemoved:Connect(function(anak)
	local tween = tweenAktif[anak]
	if tween then
		tween:Cancel()
		tweenAktif[anak] = nil
	end
end)

-- Init: las semua model, tentukan arah patroli selang-seling, mulai patroli.
local daftar = folderBrainrot:GetChildren()
for urutan, model in ipairs(daftar) do
	if model:IsA("Model") then
		lasModel(model)
		if kenaliTipe(model) == "Golden" then
			arahPatroli[model] = Vector3.new(10, 0, 0)
		elseif urutan % 2 == 0 then
			arahPatroli[model] = Vector3.new(8, 0, 0)
		else
			arahPatroli[model] = Vector3.new(0, 0, 8)
		end
	end
end

local golden = goldenStorage:FindFirstChildOfClass("Model")
if golden then
	lasModel(golden)
	arahPatroli[golden] = Vector3.new(10, 0, 0)
end

for _, model in ipairs(daftar) do
	if model:IsA("Model") then
		mulaiPatroli(model)
	end
end
