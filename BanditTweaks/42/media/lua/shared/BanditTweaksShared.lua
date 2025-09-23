BanditTweaks = BanditTweaks or {}
BanditTweaks.Config = BanditTweaks.Config or {}

BanditTweaks.Config.spawnDistanceMultiplier = 1.5
BanditTweaks.Config.hostileSpawnChanceMultiplier = 0.1
BanditTweaks.Config.hostileEventChance = 0.1
BanditTweaks.Config.friendlyFireEnabled = BanditTweaks.Config.friendlyFireEnabled ~= false

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
            activeId = activeId:gsub("^\\", "")
            if activeId == modId then
                return true
            end
        end
    end

    return false
end

local function loadModData(isNewGame)
    local data = ModData.getOrCreate(BanditTweaks._dataKey)
    if isClient() then
        ModData.request(BanditTweaks._dataKey)
    end

    if data.friendlyFireEnabled == nil then
        data.friendlyFireEnabled = true
    end

    BanditTweaks._modData = data
    BanditTweaks.Config.friendlyFireEnabled = data.friendlyFireEnabled ~= false
end
Events.OnInitGlobalModData.Add(loadModData)

local function receiveModData(key, data)
    if key == BanditTweaks._dataKey and data then
        BanditTweaks._modData = data
        BanditTweaks.Config.friendlyFireEnabled = data.friendlyFireEnabled ~= false
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

function BanditTweaks.AdjustBanditSpawnDistance(dist)
    if type(dist) == "number" then
        dist = dist * BanditTweaks.Config.spawnDistanceMultiplier
    end
    return dist
end

function BanditTweaks.AdjustClanSpawnChances()
    if not BanditCustom or not BanditCustom.clanData then
        return
    end

    for _, clan in pairs(BanditCustom.clanData) do
        local spawn = clan and clan.spawn
        if spawn and spawn.friendly == false and not spawn._BanditTweaksAdjusted then
            if type(spawn.spawnChance) == "number" then
                spawn.spawnChance = spawn.spawnChance * BanditTweaks.Config.hostileSpawnChanceMultiplier
            end
            spawn._BanditTweaksAdjusted = true
        end
    end
end

local function tryPatchBanditCustom()
    if BanditTweaks._patchedBanditCustom then
        Events.OnTick.Remove(tryPatchBanditCustom)
        return
    end

    if BanditCustom and BanditCustom.Load then
        local originalLoad = BanditCustom.Load
        BanditCustom.Load = function(...)
            local result = originalLoad(...)
            BanditTweaks.AdjustClanSpawnChances()
            return result
        end
        BanditTweaks._patchedBanditCustom = true
        BanditTweaks.AdjustClanSpawnChances()
        Events.OnTick.Remove(tryPatchBanditCustom)
    end
end
Events.OnTick.Add(tryPatchBanditCustom)

local function tryPatchSpawnType()
    if BanditTweaks._patchedSpawnType then
        Events.OnTick.Remove(tryPatchSpawnType)
        return
    end

    if BanditServer and BanditServer.Spawner and BanditServer.Spawner.Type then
        local index = 1
        while true do
            local name, value = debug.getupvalue(BanditServer.Spawner.Type, index)
            if not name then
                break
            end
            if name == "spawnType" and type(value) == "function" then
                local original = value
                local function tweakedSpawnType(player, args)
                    if args and args.dist then
                        args.dist = BanditTweaks.AdjustBanditSpawnDistance(args.dist)
                    end
                    return original(player, args)
                end
                debug.setupvalue(BanditServer.Spawner.Type, index, tweakedSpawnType)
                BanditTweaks._patchedSpawnType = true
                break
            end
            index = index + 1
        end

        if BanditTweaks._patchedSpawnType then
            Events.OnTick.Remove(tryPatchSpawnType)
        end
    end
end

if isServer() then
    Events.OnTick.Add(tryPatchSpawnType)
end
