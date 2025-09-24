require "BanditTweaks/Config"
local CivilianGroups = require "BanditTweaks/CivilianGroups"

local SpawnTweaks = {}

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, entry in pairs(value) do
        copy[key] = deepCopy(entry)
    end
    return copy
end

function BanditTweaks.RewriteCivilianClans()
    if not BanditCustom or not BanditCustom.clanData or not BanditCustom.banditData then
        return
    end

    local fighterCid = CivilianGroups.FIGHTER_CID
    local cowardCid = CivilianGroups.COWARD_CID

    local fighterClan = BanditCustom.clanData[fighterCid]
    if not fighterClan then
        return
    end

    fighterClan.general = fighterClan.general or {}
    fighterClan.spawn = fighterClan.spawn or {}

    local baseName = fighterClan.general.name
    if not baseName or baseName == "" then
        baseName = "Civilians"
    end

    if baseName == "Civilians" then
        fighterClan.general.name = "Civilian Fighters"
    end

    local cowardClan = BanditCustom.clanData[cowardCid]
    if not cowardClan then
        cowardClan = deepCopy(fighterClan)
        BanditCustom.clanData[cowardCid] = cowardClan
    end

    cowardClan.general = cowardClan.general or {}
    cowardClan.spawn = cowardClan.spawn or {}

    local fighterName = fighterClan.general.name or baseName
    if not cowardClan.general.name or cowardClan.general.name == "" or cowardClan.general.name == baseName or cowardClan.general.name == fighterName then
        if fighterName:find("Fighter") then
            cowardClan.general.name = fighterName:gsub("Fighter", "Coward")
        else
            cowardClan.general.name = fighterName .. " Cowards"
        end
    end

    for key, value in pairs(fighterClan.spawn) do
        if key ~= "spawnChance" then
            cowardClan.spawn[key] = value
        end
    end

    local toRemove = {}
    for bid, data in pairs(BanditCustom.banditData) do
        local general = data and data.general
        if general and general._BanditTweaksCowardClone then
            table.insert(toRemove, bid)
        end
    end

    for _, bid in ipairs(toRemove) do
        BanditCustom.banditData[bid] = nil
    end

    local originals = {}
    for bid, data in pairs(BanditCustom.banditData) do
        local general = data and data.general
        if general and general.cid == fighterCid and not general._BanditTweaksCowardClone then
            table.insert(originals, {id = bid, data = data})
        end
    end

    for _, entry in ipairs(originals) do
        local clone = deepCopy(entry.data)
        clone.general = clone.general or {}
        clone.general.cid = cowardCid
        clone.general._BanditTweaksCowardClone = true
        clone.general._BanditTweaksSourceId = entry.id

        if clone.general.name and clone.general.name ~= "" then
            if not clone.general.name:find("Coward") then
                clone.general.name = clone.general.name .. " Coward"
            end
        else
            clone.general.name = "Civilian Coward"
        end

        local newId
        if BanditCustom.GetNextId then
            newId = BanditCustom.GetNextId(entry.id)
        elseif getRandomUUID then
            newId = getRandomUUID()
        end

        if not newId then
            newId = tostring(entry.id) .. "_coward"
        end

        BanditCustom.banditData[newId] = clone
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

    local fighterCid = CivilianGroups.FIGHTER_CID
    local cowardCid = CivilianGroups.COWARD_CID
    local defaults = BanditTweaks.Defaults or {}

    for cid, clan in pairs(BanditCustom.clanData) do
        local spawn = clan and clan.spawn
        if spawn then
            if cid == fighterCid then
                local chance = BanditTweaks.Config.civilianFighterSpawnChance or defaults.civilianFighterSpawnChance or 0
                spawn.spawnChance = chance
                spawn.friendly = true
                spawn._BanditTweaksAdjusted = true
            elseif cid == cowardCid then
                local chance = BanditTweaks.Config.civilianCowardSpawnChance or defaults.civilianCowardSpawnChance or 0
                spawn.spawnChance = chance
                spawn.friendly = true
                spawn._BanditTweaksAdjusted = true
            elseif spawn.friendly == false and not spawn._BanditTweaksAdjusted then
                if type(spawn.spawnChance) == "number" then
                    spawn.spawnChance = spawn.spawnChance * BanditTweaks.Config.hostileSpawnChanceMultiplier
                end
                spawn._BanditTweaksAdjusted = true
            end
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
            BanditTweaks.RewriteCivilianClans()
            BanditTweaks.AdjustClanSpawnChances()
            return result
        end
        BanditTweaks._patchedBanditCustom = true
        BanditTweaks.RewriteCivilianClans()
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

return SpawnTweaks
