BanditTweaks = BanditTweaks or {}
BanditTweaks.Config = BanditTweaks.Config or {}
BanditTweaks.Defaults = BanditTweaks.Defaults or {}

local Config = {}

BanditTweaks.Defaults.spawnDistanceMultiplier = 1.5
BanditTweaks.Defaults.hostileSpawnChanceMultiplier = 0.1
BanditTweaks.Defaults.hostileEventChance = 0.1
BanditTweaks.Defaults.friendlyFireEnabled = true
BanditTweaks.Defaults.civilianFighterPercent = 20
BanditTweaks.Defaults.civilianHidePercent = 20
BanditTweaks.Defaults.civilianPanicPercent = 20
BanditTweaks.Defaults.civilianSeekProtectionPercent = 20
BanditTweaks.Defaults.civilianVoicesEnabled = true
BanditTweaks.Defaults.civilianRandomVoiceIntervalHours = 0.12
BanditTweaks.Defaults.civilianHurtVoiceCooldownHours = 0.05
BanditTweaks.Defaults.doorDisciplineEnabled = true
BanditTweaks.Defaults.doorCloseCooldownHours = 0.02
BanditTweaks.Defaults.startingFollowersEnabled = true

BanditTweaks.Config.spawnDistanceMultiplier = BanditTweaks.Config.spawnDistanceMultiplier or BanditTweaks.Defaults.spawnDistanceMultiplier
BanditTweaks.Config.hostileSpawnChanceMultiplier = BanditTweaks.Config.hostileSpawnChanceMultiplier or BanditTweaks.Defaults.hostileSpawnChanceMultiplier
BanditTweaks.Config.hostileEventChance = BanditTweaks.Config.hostileEventChance or BanditTweaks.Defaults.hostileEventChance
BanditTweaks.Config.friendlyFireEnabled = BanditTweaks.Config.friendlyFireEnabled ~= false
BanditTweaks.Config.civilianFighterPercent = BanditTweaks.Config.civilianFighterPercent or BanditTweaks.Defaults.civilianFighterPercent
BanditTweaks.Config.civilianHidePercent = BanditTweaks.Config.civilianHidePercent or BanditTweaks.Defaults.civilianHidePercent
BanditTweaks.Config.civilianPanicPercent = BanditTweaks.Config.civilianPanicPercent or BanditTweaks.Defaults.civilianPanicPercent
BanditTweaks.Config.civilianSeekProtectionPercent = BanditTweaks.Config.civilianSeekProtectionPercent or BanditTweaks.Defaults.civilianSeekProtectionPercent
BanditTweaks.Config.civilianVoicesEnabled = BanditTweaks.Config.civilianVoicesEnabled ~= false
BanditTweaks.Config.civilianRandomVoiceIntervalHours = BanditTweaks.Config.civilianRandomVoiceIntervalHours or BanditTweaks.Defaults.civilianRandomVoiceIntervalHours
BanditTweaks.Config.civilianHurtVoiceCooldownHours = BanditTweaks.Config.civilianHurtVoiceCooldownHours or BanditTweaks.Defaults.civilianHurtVoiceCooldownHours
BanditTweaks.Config.doorDisciplineEnabled = BanditTweaks.Config.doorDisciplineEnabled ~= false
BanditTweaks.Config.doorCloseCooldownHours = BanditTweaks.Config.doorCloseCooldownHours or BanditTweaks.Defaults.doorCloseCooldownHours
BanditTweaks.Config.startingFollowersEnabled = BanditTweaks.Config.startingFollowersEnabled ~= false

local function getSandboxNumber(options, key, default)
    local value = options and options[key]
    if type(value) == "number" then
        return value
    end
    return default
end

local function getSandboxBoolean(options, key, default)
    local value = options and options[key]
    if value == nil then
        return default
    end
    return value and true or false
end

function BanditTweaks.UpdateConfigFromSandbox()
    local options = SandboxVars and SandboxVars.BanditTweaks
    BanditTweaks.Config.spawnDistanceMultiplier = getSandboxNumber(options, "SpawnDistanceMultiplier", BanditTweaks.Defaults.spawnDistanceMultiplier)
    BanditTweaks.Config.hostileSpawnChanceMultiplier = getSandboxNumber(options, "HostileSpawnChanceMultiplier", BanditTweaks.Defaults.hostileSpawnChanceMultiplier)
    BanditTweaks.Config.hostileEventChance = getSandboxNumber(options, "HostileEventChance", BanditTweaks.Defaults.hostileEventChance)
    BanditTweaks.Config.civilianFighterPercent = getSandboxNumber(options, "CivilianFighterPercent", BanditTweaks.Defaults.civilianFighterPercent)
    BanditTweaks.Config.civilianHidePercent = getSandboxNumber(options, "CivilianHidePercent", BanditTweaks.Defaults.civilianHidePercent)
    BanditTweaks.Config.civilianPanicPercent = getSandboxNumber(options, "CivilianPanicPercent", BanditTweaks.Defaults.civilianPanicPercent)
    BanditTweaks.Config.civilianSeekProtectionPercent = getSandboxNumber(options, "CivilianSeekProtectionPercent", BanditTweaks.Defaults.civilianSeekProtectionPercent)
    BanditTweaks.Config.civilianVoicesEnabled = getSandboxBoolean(options, "CivilianVoicesEnabled", BanditTweaks.Defaults.civilianVoicesEnabled)
    local voiceIntervalMinutes = getSandboxNumber(options, "CivilianVoiceIntervalMinutes", BanditTweaks.Defaults.civilianRandomVoiceIntervalHours * 60)
    local hurtCooldownMinutes = getSandboxNumber(options, "CivilianHurtVoiceCooldownMinutes", BanditTweaks.Defaults.civilianHurtVoiceCooldownHours * 60)
    local doorCooldownMinutes = getSandboxNumber(options, "DoorCloseCooldownMinutes", BanditTweaks.Defaults.doorCloseCooldownHours * 60)
    BanditTweaks.Config.civilianRandomVoiceIntervalHours = math.max(0, voiceIntervalMinutes) / 60
    BanditTweaks.Config.civilianHurtVoiceCooldownHours = math.max(0, hurtCooldownMinutes) / 60
    BanditTweaks.Config.doorCloseCooldownHours = math.max(0, doorCooldownMinutes) / 60
    BanditTweaks.Config.doorDisciplineEnabled = getSandboxBoolean(options, "DoorDisciplineEnabled", BanditTweaks.Defaults.doorDisciplineEnabled)
    BanditTweaks.Config.startingFollowersEnabled = getSandboxBoolean(options, "StartingFollowersEnabled", BanditTweaks.Defaults.startingFollowersEnabled)
end

BanditTweaks.UpdateConfigFromSandbox()

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(BanditTweaks.UpdateConfigFromSandbox)
end
if Events and Events.OnServerStarted then
    Events.OnServerStarted.Add(BanditTweaks.UpdateConfigFromSandbox)
end
if Events and Events.OnSandboxOptionsChanged then
    Events.OnSandboxOptionsChanged.Add(BanditTweaks.UpdateConfigFromSandbox)
end
if Events and Events.OnLoad then
    Events.OnLoad.Add(BanditTweaks.UpdateConfigFromSandbox)
end

BanditTweaks._dataKey = "BanditTweaks"
BanditTweaks._modData = BanditTweaks._modData or nil

function BanditTweaks.IsModActive(modId)
    local mods = getActivatedMods()
    if not mods then
        return false
    end

    for i = 0, mods:size() - 1 do
        local activeId = mods:get(i)
        if activeId then
            activeId = activeId:gsub('^\\', '')
            if activeId == modId then
                return true
            end
        end
    end

    return false
end

local function applySandboxDefault(options, key, default)
    if not options then
        return default
    end
    local value = options[key]
    if value == nil then
        return default
    end
    return value and true or false
end

local function loadModData(isNewGame)
    BanditTweaks.UpdateConfigFromSandbox()

    local data = ModData.getOrCreate(BanditTweaks._dataKey)
    if isClient() then
        ModData.request(BanditTweaks._dataKey)
    end

    if data.friendlyFireEnabled == nil then
        local defaultFriendly = BanditTweaks.Defaults.friendlyFireEnabled
        local options = SandboxVars and SandboxVars.BanditTweaks
        defaultFriendly = applySandboxDefault(options, "FriendlyFireEnabled", defaultFriendly)
        data.friendlyFireEnabled = defaultFriendly
    end

    if data.startingFollowersEnabled == nil then
        local defaultFollowers = BanditTweaks.Defaults.startingFollowersEnabled
        local options = SandboxVars and SandboxVars.BanditTweaks
        defaultFollowers = applySandboxDefault(options, "StartingFollowersEnabled", defaultFollowers)
        data.startingFollowersEnabled = defaultFollowers
    end

    BanditTweaks._modData = data
    BanditTweaks.Config.friendlyFireEnabled = data.friendlyFireEnabled ~= false
    BanditTweaks.Config.startingFollowersEnabled = data.startingFollowersEnabled ~= false
end
Events.OnInitGlobalModData.Add(loadModData)

local function receiveModData(key, data)
    if key == BanditTweaks._dataKey and data then
        BanditTweaks._modData = data
        BanditTweaks.Config.friendlyFireEnabled = data.friendlyFireEnabled ~= false
        BanditTweaks.Config.startingFollowersEnabled = data.startingFollowersEnabled ~= false
    end
end
Events.OnReceiveGlobalModData.Add(receiveModData)

function BanditTweaks.SetFriendlyFireEnabled(enabled)
    enabled = enabled and true or false
    BanditTweaks.Config.friendlyFireEnabled = enabled

    if BanditTweaks._modData then
        BanditTweaks._modData.friendlyFireEnabled = enabled
        if isServer() then
            ModData.transmit(BanditTweaks._dataKey)
        end
    end
end

function BanditTweaks.SetStartingFollowersEnabled(enabled)
    enabled = enabled and true or false
    BanditTweaks.Config.startingFollowersEnabled = enabled

    if BanditTweaks._modData then
        BanditTweaks._modData.startingFollowersEnabled = enabled
        if isServer() then
            ModData.transmit(BanditTweaks._dataKey)
        end
    end
end

return Config
