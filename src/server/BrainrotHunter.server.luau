-- Brainrot Hunter: server utama
-- Menangkap brainrot, Koin per detik, toko upgrade, dan event Golden Tung Tung.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local folderBrainrot = Workspace:WaitForChild("Brainrots")
local goldenStorage = ServerStorage:WaitForChild("GoldenStorage")
local umumkanTangkap = ReplicatedStorage:WaitForChild("UmumkanTangkap")
local umumkanGolden = ReplicatedStorage:WaitForChild("UmumkanGolden")
local papanUmum = Workspace:WaitForChild("PapanUmum")
local labelPapan = papanUmum:WaitForChild("GuiPapan"):WaitForChild("Label")

local JALAN_DASAR = 16
local JEDA_KOMBO = 10
local JEDA_EMAS_AWAL = 45
local EMAS_BERTAHAN = 30

-- Data tujuh tipe karakter. "muncul" kosong untuk Golden karena ia hanya
-- datang lewat event berkala, bukan muncul lagi otomatis.
local TIPE = {
	TungTung = { tampil = "TUNG TUNG TUNG SAHUR", rarity = "Common", tingkat = 1, koin = 1, muncul = 15, cepat = 4 },
	Tralala = { tampil = "TRALALERO TRALALA", rarity = "Common", tingkat = 1, koin = 2, muncul = 15, cepat = 4 },
	Patapim = { tampil = "BRR BRR PATAPIM", rarity = "Common", tingkat = 1, koin = 2, muncul = 15, cepat = 4 },
	Lirili = { tampil = "LIRILI LARILA", rarity = "Uncommon", tingkat = 2, koin = 4, muncul = 20, cepat = 5 },
	Bananini = { tampil = "CHIMPANZINI BANANINI", rarity = "Uncommon", tingkat = 2, koin = 5, muncul = 20, cepat = 5 },
	Bombardiro = { tampil = "BOMBARDIRO CROCODILO", rarity = "Rare", tingkat = 3, koin = 10, muncul = 30, cepat = 6.5 },
	Golden = { tampil = "GOLDEN TUNG TUNG", rarity = "MYTHIC", tingkat = 4, koin = 25, muncul = nil, cepat = 10 },
}
local URUTAN_TIPE = { "TungTung", "Tralala", "Patapim", "Lirili", "Bananini", "Bombardiro", "Golden" }
local TINGKAT_RARITY = { ["-"] = 0, Common = 1, Uncommon = 2, Rare = 3, MYTHIC = 4 }

local NAMA_ZONA = { "SAWAH TUNG TUNG", "LAUT TRALALA", "GURUN BOMBARDIRO", "HUTAN BANANINI" }
local TITIK_GOLDEN = {
	Vector3.new(-45, 4.25, -62),
	Vector3.new(45, 4.25, -62),
	Vector3.new(-45, 4.25, 62),
	Vector3.new(45, 4.25, 62),
}

local TOKO = {
	Magnet = { tampil = "MAGNET", harga = { 50, 150, 400 } },
	Sepatu = { tampil = "SEPATU KILAT", harga = { 40, 120, 300 } },
	Hoki = { tampil = "KEBERUNTUNGAN", harga = { 60, 180, 500 } },
}

local posisiSpawn = {}
local goldenAktif = false
local modelGolden = goldenStorage:FindFirstChildOfClass("Model")

-- Tempat sembunyi sementara untuk model yang baru ditangkap.
local folderSimpan = Instance.new("Folder")
folderSimpan.Name = "Disimpan"
folderSimpan.Parent = ServerStorage

local function tulisPapan(teks)
	labelPapan.Text = teks
end

local function kirimSpanduk(pemain, teks, emas)
	umumkanTangkap:FireClient(pemain, teks, emas == true)
end

local function kenaliTipe(model)
	local nama = model.Name:gsub("^Char", ""):gsub("%d+$", "")
	if TIPE[nama] then
		return nama
	end
	return nil
end

local function terapkanJalan(pemain)
	local state = pemain:FindFirstChild("HunterState")
	local karakter = pemain.Character
	if not state or not karakter then
		return
	end
	local manusia = karakter:FindFirstChildOfClass("Humanoid")
	if not manusia then
		return
	end
	local levelSepatu = state:FindFirstChild("Sepatu")
	local level = levelSepatu and levelSepatu.Value or 0
	manusia.WalkSpeed = JALAN_DASAR + 4 * level
end

local function tambahInt(induk, nama, awal)
	local nilai = Instance.new("IntValue")
	nilai.Name = nama
	nilai.Value = awal
	nilai.Parent = induk
	return nilai
end

local function siapkanPemain(pemain)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = pemain
	tambahInt(stats, "Koin", 0)
	tambahInt(stats, "Brainrot", 0)
	tambahInt(stats, "KoinDetik", 0)

	local state = Instance.new("Folder")
	state.Name = "HunterState"
	state.Parent = pemain
	local koleksi = Instance.new("Folder")
	koleksi.Name = "Koleksi"
	koleksi.Parent = state
	for _, kunci in ipairs(URUTAN_TIPE) do
		tambahInt(koleksi, kunci, 0)
	end
	local terlangka = Instance.new("StringValue")
	terlangka.Name = "Terlangka"
	terlangka.Value = "-"
	terlangka.Parent = state
	tambahInt(state, "Kombo", 0)
	local lastCatch = Instance.new("NumberValue")
	lastCatch.Name = "LastCatch"
	lastCatch.Value = 0
	lastCatch.Parent = state
	tambahInt(state, "Magnet", 0)
	tambahInt(state, "Sepatu", 0)
	tambahInt(state, "Hoki", 0)
	local lengkap = Instance.new("BoolValue")
	lengkap.Name = "Lengkap"
	lengkap.Value = false
	lengkap.Parent = state

	terapkanJalan(pemain)
	pemain.CharacterAdded:Connect(function()
		task.wait(0.1)
		terapkanJalan(pemain)
	end)
end

local function pemainDariSentuhan(bagian)
	local karakter = bagian.Parent
	local pemain = Players:GetPlayerFromCharacter(karakter)
	if pemain then
		return pemain
	end
	if karakter and karakter.Parent then
		return Players:GetPlayerFromCharacter(karakter.Parent)
	end
	return nil
end

local function tangkap(pemain, model)
	if model:GetAttribute("Caught") then
		return
	end
	local kunci = kenaliTipe(model)
	if not kunci then
		return
	end
	local info = TIPE[kunci]
	local state = pemain:FindFirstChild("HunterState")
	local stats = pemain:FindFirstChild("leaderstats")
	if not state or not stats then
		return
	end
	model:SetAttribute("Caught", true)

	local koleksi = state:FindFirstChild("Koleksi")
	local jumlahTipe = koleksi:FindFirstChild(kunci)
	local baru = jumlahTipe.Value == 0

	local komboNilai = state:FindFirstChild("Kombo")
	local lastCatch = state:FindFirstChild("LastCatch")
	local sekarang = os.clock()
	if sekarang - lastCatch.Value < JEDA_KOMBO then
		komboNilai.Value = komboNilai.Value + 1
	else
		komboNilai.Value = 1
	end
	lastCatch.Value = sekarang

	local bonus = 0
	if baru then
		bonus = bonus + 10
	end
	if komboNilai.Value >= 3 then
		bonus = bonus + komboNilai.Value
	end
	if kunci == "Golden" then
		bonus = bonus + 100
	end

	jumlahTipe.Value = jumlahTipe.Value + 1
	stats:FindFirstChild("Brainrot").Value = stats:FindFirstChild("Brainrot").Value + 1
	stats:FindFirstChild("Koin").Value = stats:FindFirstChild("Koin").Value + bonus

	local terlangka = state:FindFirstChild("Terlangka")
	if info.tingkat > (TINGKAT_RARITY[terlangka.Value] or 0) then
		terlangka.Value = info.rarity
	end

	local teks = "MENANGKAP " .. info.tampil .. " (" .. info.rarity .. ", +" .. info.koin .. "/detik)"
	if baru then
		teks = teks .. " BARU +10 KOIN"
	end
	if komboNilai.Value >= 3 then
		teks = teks .. " KOMBO x" .. komboNilai.Value
	end
	if kunci == "Golden" then
		teks = teks .. " +100 KOIN"
	end
	kirimSpanduk(pemain, teks, kunci == "Golden")

	tulisPapan("TERAKHIR " .. pemain.Name .. " menangkap " .. info.tampil)

	local lengkap = state:FindFirstChild("Lengkap")
	if not lengkap.Value then
		local semua = true
		for _, nama in ipairs(URUTAN_TIPE) do
			if koleksi:FindFirstChild(nama).Value < 1 then
				semua = false
				break
			end
		end
		if semua then
			lengkap.Value = true
			stats:FindFirstChild("Koin").Value = stats:FindFirstChild("Koin").Value + 500
			umumkanGolden:FireAllClients(pemain.Name .. " MELENGKAPI KOLEKSI 7 BRAINROT +500 KOIN")
			tulisPapan(pemain.Name .. " RAJA BRAINROT KOLEKSI LENGKAP")
		end
	end

	if kunci == "Golden" then
		model.Parent = goldenStorage
		goldenAktif = false
		model:SetAttribute("Caught", false)
	else
		model.Parent = folderSimpan
		local levelHoki = state:FindFirstChild("Hoki").Value
		local jeda = math.max(8, info.muncul - 5 * levelHoki)
		task.spawn(function()
			task.wait(jeda)
			local badan = model:FindFirstChild("Body")
			if badan and posisiSpawn[model] then
				badan.CFrame = posisiSpawn[model]
			end
			model:SetAttribute("Caught", false)
			model.Parent = folderBrainrot
		end)
	end
end

local function beli(pemain, kunci)
	local barang = TOKO[kunci]
	if not barang then
		return
	end
	local state = pemain:FindFirstChild("HunterState")
	local stats = pemain:FindFirstChild("leaderstats")
	if not state or not stats then
		return
	end
	local levelNilai = state:FindFirstChild(kunci)
	local level = levelNilai.Value
	if level >= 3 then
		kirimSpanduk(pemain, barang.tampil .. " SUDAH LEVEL MAKS", false)
		return
	end
	local harga = barang.harga[level + 1]
	local koinNilai = stats:FindFirstChild("Koin")
	if koinNilai.Value < harga then
		kirimSpanduk(pemain, "KOIN KURANG " .. barang.tampil .. " LV " .. (level + 1) .. " BUTUH " .. harga .. " KOIN", false)
		return
	end
	koinNilai.Value = koinNilai.Value - harga
	levelNilai.Value = level + 1
	if kunci == "Sepatu" then
		terapkanJalan(pemain)
	end
	kirimSpanduk(pemain, barang.tampil .. " LEVEL " .. levelNilai.Value, false)
end

local cooldownPad = {}
local function pasangPad(pad, kunci)
	pad.Touched:Connect(function(bagian)
		local pemain = pemainDariSentuhan(bagian)
		if not pemain then
			return
		end
		local kunciCooldown = pemain.UserId .. "_" .. kunci
		local sekarang = os.clock()
		if cooldownPad[kunciCooldown] and sekarang - cooldownPad[kunciCooldown] < 2 then
			return
		end
		cooldownPad[kunciCooldown] = sekarang
		beli(pemain, kunci)
	end)
end

local function hokiTertinggi()
	local tertinggi = 0
	for _, pemain in ipairs(Players:GetPlayers()) do
		local state = pemain:FindFirstChild("HunterState")
		if state then
			local hoki = state:FindFirstChild("Hoki")
			if hoki and hoki.Value > tertinggi then
				tertinggi = hoki.Value
			end
		end
	end
	return tertinggi
end

-- Event Golden Tung Tung: muncul berkala di zona acak, kabur kalau tidak
-- ditangkap dalam 30 detik.
task.spawn(function()
	if not modelGolden then
		warn("BrainrotHunter: model Golden tidak ditemukan di GoldenStorage, event Golden dimatikan.")
		return
	end
	task.wait(JEDA_EMAS_AWAL)
	while true do
		local zona = math.random(1, 4)
		local titik = TITIK_GOLDEN[zona]
		local badan = modelGolden:FindFirstChild("Body")
		if badan then
			badan.CFrame = CFrame.new(titik)
			posisiSpawn[modelGolden] = badan.CFrame
		end
		modelGolden:SetAttribute("Caught", false)
		modelGolden.Parent = folderBrainrot
		goldenAktif = true
		tulisPapan("GOLDEN TUNG TUNG MUNCUL DI ZONA " .. NAMA_ZONA[zona] .. " 25 KOIN/detik")
		umumkanGolden:FireAllClients("GOLDEN TUNG TUNG MUNCUL DI ZONA " .. NAMA_ZONA[zona])
		local menunggu = 0
		while goldenAktif and menunggu < EMAS_BERTAHAN do
			task.wait(1)
			menunggu = menunggu + 1
		end
		if goldenAktif then
			modelGolden.Parent = goldenStorage
			goldenAktif = false
			tulisPapan("GOLDEN TUNG TUNG KABUR, TUNGGU LAGI YA")
		end
		local jeda = math.max(30, 60 - 10 * hokiTertinggi())
		task.wait(jeda)
	end
end)

-- Penghasilan per detik dan bar atas layar.
task.spawn(function()
	while true do
		task.wait(1)
		for _, pemain in ipairs(Players:GetPlayers()) do
			local state = pemain:FindFirstChild("HunterState")
			local stats = pemain:FindFirstChild("leaderstats")
			if state and stats then
				local koleksi = state:FindFirstChild("Koleksi")
				local total = 0
				for _, nama in ipairs(URUTAN_TIPE) do
					local jumlah = koleksi:FindFirstChild(nama)
					if jumlah then
						total = total + jumlah.Value * TIPE[nama].koin
					end
				end
				local koinNilai = stats:FindFirstChild("Koin")
				koinNilai.Value = koinNilai.Value + total
				stats:FindFirstChild("KoinDetik").Value = total
				local gui = pemain:FindFirstChild("PlayerGui")
				if gui then
					local hud = gui:FindFirstChild("HunterHUD")
					if hud then
						local bar = hud:FindFirstChild("BarAtas")
						if bar then
							bar.Text = "KOIN " .. koinNilai.Value
								.. " | BRAINROT " .. stats:FindFirstChild("Brainrot").Value
								.. " | +" .. total .. "/DETIK"
								.. " | KOMBO x" .. state:FindFirstChild("Kombo").Value
								.. " | TERLANGKA " .. state:FindFirstChild("Terlangka").Value
						end
					end
				end
			end
		end
	end
end)

-- Magnet otomatis: tangkap karakter dekat pemain tiap setengah detik.
task.spawn(function()
	while true do
		task.wait(0.5)
		for _, pemain in ipairs(Players:GetPlayers()) do
			local state = pemain:FindFirstChild("HunterState")
			if state then
				local level = state:FindFirstChild("Magnet").Value
				if level > 0 then
					local karakter = pemain.Character
					local akar = karakter and karakter:FindFirstChild("HumanoidRootPart")
					if akar then
						local radius = 8 + 4 * level
						for _, model in ipairs(folderBrainrot:GetChildren()) do
							if not model:GetAttribute("Caught") then
								local badan = model:FindFirstChild("Body")
								if badan and (badan.Position - akar.Position).Magnitude <= radius then
									tangkap(pemain, model)
								end
							end
						end
					end
				end
			end
		end
	end
end)

-- Hook sentuhan: semua part turunan tiap model bisa ditangkap.
local function pasangSentuhanModel(model)
	for _, bagian in ipairs(model:GetDescendants()) do
		if bagian:IsA("BasePart") then
			bagian.Touched:Connect(function(sentuhan)
				local pemain = pemainDariSentuhan(sentuhan)
				if pemain then
					tangkap(pemain, model)
				end
			end)
		end
	end
end

for _, model in ipairs(folderBrainrot:GetChildren()) do
	local badan = model:FindFirstChild("Body")
	if badan then
		posisiSpawn[model] = badan.CFrame
	end
	pasangSentuhanModel(model)
end
if modelGolden then
	pasangSentuhanModel(modelGolden)
	local badanEmas = modelGolden:FindFirstChild("Body")
	if badanEmas then
		posisiSpawn[modelGolden] = badanEmas.CFrame
	end
end

pasangPad(Workspace:WaitForChild("PadMagnet"), "Magnet")
pasangPad(Workspace:WaitForChild("PadSepatu"), "Sepatu")
pasangPad(Workspace:WaitForChild("PadHoki"), "Hoki")

Players.PlayerAdded:Connect(siapkanPemain)
for _, pemain in ipairs(Players:GetPlayers()) do
	siapkanPemain(pemain)
end
