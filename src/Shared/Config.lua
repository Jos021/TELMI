--!strict
local Config = {}

-- ============================================================
-- RECURSOS
-- ============================================================
Config.RESOURCES = {
	WOOD  = "Wood",
	STONE = "Stone",
	IRON  = "Iron",
	FOOD  = "Food",
}

Config.RESOURCE_NODE_DATA = {
	Wood = {
		color       = Color3.fromRGB(101, 67, 33),
		material    = Enum.Material.Wood,
		size        = Vector3.new(4, 8, 4),
		health      = 3,
		yieldMin    = 2,
		yieldMax    = 5,
		respawnTime = 30,
		label       = "Madeira",
	},
	Stone = {
		color       = Color3.fromRGB(128, 128, 128),
		material    = Enum.Material.SmoothPlastic,
		size        = Vector3.new(3, 3, 3),
		health      = 5,
		yieldMin    = 2,
		yieldMax    = 4,
		respawnTime = 45,
		label       = "Pedra",
	},
	Iron = {
		color       = Color3.fromRGB(170, 170, 170),
		material    = Enum.Material.Metal,
		size        = Vector3.new(2, 2, 2),
		health      = 7,
		yieldMin    = 1,
		yieldMax    = 3,
		respawnTime = 60,
		label       = "Ferro",
	},
	Food = {
		color       = Color3.fromRGB(80, 200, 80),
		material    = Enum.Material.Grass,
		size        = Vector3.new(2, 2, 2),
		health      = 1,
		yieldMin    = 1,
		yieldMax    = 3,
		respawnTime = 20,
		label       = "Comida",
	},
}

-- ============================================================
-- CONSTRUÇÕES
-- ============================================================
Config.BUILDINGS = {
	WOOD_BLOCK  = "WoodBlock",
	STONE_BLOCK = "StoneBlock",
	WALL        = "Wall",
	FLOOR       = "Floor",
	DOOR        = "Door",
	CHEST       = "Chest",
	NUCLEUS     = "Nucleus",
	TOWER       = "Tower",
}

Config.BUILDING_DATA = {
	WoodBlock = {
		label    = "Bloco de Madeira",
		cost     = { Wood = 5 },
		size     = Vector3.new(4, 4, 4),
		color    = Color3.fromRGB(160, 120, 60),
		material = Enum.Material.Wood,
		health   = 100,
	},
	StoneBlock = {
		label    = "Bloco de Pedra",
		cost     = { Stone = 5 },
		size     = Vector3.new(4, 4, 4),
		color    = Color3.fromRGB(100, 100, 100),
		material = Enum.Material.SmoothPlastic,
		health   = 250,
	},
	Wall = {
		label    = "Parede",
		cost     = { Stone = 8 },
		size     = Vector3.new(4, 6, 1),
		color    = Color3.fromRGB(120, 120, 120),
		material = Enum.Material.SmoothPlastic,
		health   = 200,
	},
	Floor = {
		label    = "Piso",
		cost     = { Wood = 3 },
		size     = Vector3.new(4, 0.5, 4),
		color    = Color3.fromRGB(180, 140, 80),
		material = Enum.Material.Wood,
		health   = 150,
	},
	Door = {
		label    = "Porta",
		cost     = { Wood = 5, Iron = 2 },
		size     = Vector3.new(4, 6, 0.5),
		color    = Color3.fromRGB(140, 90, 40),
		material = Enum.Material.Wood,
		health   = 150,
		isDoor   = true,
	},
	Chest = {
		label        = "Baú",
		cost         = { Wood = 8 },
		size         = Vector3.new(3, 2, 2),
		color        = Color3.fromRGB(160, 120, 40),
		material     = Enum.Material.Wood,
		health       = 100,
		storageSlots = 20,
	},
	Nucleus = {
		label    = "Núcleo",
		cost     = { Stone = 20, Iron = 10 },
		size     = Vector3.new(4, 4, 4),
		color    = Color3.fromRGB(80, 200, 255),
		material = Enum.Material.Neon,
		health   = 1000,
		isNucleus = true,
	},
	Tower = {
		label    = "Torre",
		cost     = { Stone = 15, Iron = 5 },
		size     = Vector3.new(4, 12, 4),
		color    = Color3.fromRGB(100, 100, 100),
		material = Enum.Material.SmoothPlastic,
		health   = 300,
	},
}

-- ============================================================
-- NÍVEIS DE CLÃ
-- ============================================================
Config.CLAN_LEVELS = {
	[1] = { capacity = 3,  label = "Pequeno grupo",  nucleusHealth = 500  },
	[2] = { capacity = 5,  label = "Pequeno clã",    nucleusHealth = 750  },
	[3] = { capacity = 10, label = "Clã médio",      nucleusHealth = 1000 },
	[4] = { capacity = 20, label = "Clã grande",     nucleusHealth = 2000 },
	[5] = { capacity = 30, label = "Grande força",   nucleusHealth = 3000 },
	[6] = { capacity = 50, label = "Endgame",        nucleusHealth = 5000 },
}

Config.CLAN_UPGRADE_COST = {
	[2] = { Stone = 50,   Iron = 20  },
	[3] = { Stone = 150,  Iron = 60,  Wood = 100 },
	[4] = { Stone = 400,  Iron = 150, Wood = 200 },
	[5] = { Stone = 1000, Iron = 400, Wood = 500 },
	[6] = { Stone = 2500, Iron = 1000,Wood = 1000},
}

Config.MAX_CLAN_LEVEL = 6

-- ============================================================
-- JOGADOR
-- ============================================================
Config.PLAYER = {
	maxHealth          = 100,
	walkSpeed          = 16,
	jumpPower          = 50,
	respawnTime        = 5,
	inventorySlots     = 30,
	protectionDuration = 30 * 60, -- 30 minutos
}

Config.INVENTORY = {
	MAX_STACK  = 99,
	SLOT_COUNT = 30,
}

-- ============================================================
-- COMBATE
-- ============================================================
Config.COMBAT = {
	SWORD = {
		damage   = 25,
		cooldown = 0.8,
		range    = 6,
		label    = "Espada",
	},
	BOW = {
		damage         = 35,
		cooldown       = 1.5,
		range          = 80,
		projectileSpeed = 200,
		label          = "Arco",
	},
	ARMOR = {
		damageReduction = 0.25,
		label           = "Armadura",
	},
}

-- ============================================================
-- RAID
-- ============================================================
Config.RAID = {
	minPlayers     = 3,
	maxLootPercent = 0.30, -- 30% dos recursos saqueados
	cooldown       = 10 * 60, -- 10 min entre raids ao mesmo clã
	duration       = 15 * 60, -- duração máxima da raid (15 min)
}

-- ============================================================
-- DATASTORES
-- ============================================================
Config.DATA_VERSION = "v1"
Config.DS_INVENTORY = "Inventory_" .. Config.DATA_VERSION
Config.DS_BASE      = "Base_"      .. Config.DATA_VERSION
Config.DS_CLAN      = "Clan_"      .. Config.DATA_VERSION
Config.DS_STATS     = "Stats_"     .. Config.DATA_VERSION

return Config
