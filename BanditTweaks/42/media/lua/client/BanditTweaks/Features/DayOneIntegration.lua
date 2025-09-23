if isServer() then return end

local DayOneIntegration = {}
local hostilePhaseNames = {"SpawnGang", "SpawnBandits", "SpawnInmates"}

local function tryPatchDayOne()
    if BanditTweaks._dayOnePatched then
        Events.OnTick.Remove(tryPatchDayOne)
        return
    end

    if not BanditTweaks.IsModActive("BanditsDayOne") then
        BanditTweaks._dayOnePatched = true
        Events.OnTick.Remove(tryPatchDayOne)
        return
    end

    local patchedSomething = false

    if DOPhases then
        for _, name in ipairs(hostilePhaseNames) do
            if not BanditTweaks["_patchedPhase" .. name] and type(DOPhases[name]) == "function" then
                local original = DOPhases[name]
                DOPhases[name] = function(player, ...)
                    if ZombRandFloat(0, 1) > BanditTweaks.Config.hostileEventChance then
                        return
                    end
                    return original(player, ...)
                end
                BanditTweaks["_patchedPhase" .. name] = true
                patchedSomething = true
            end
        end
    end

    if BanditScheduler and BanditScheduler.GenerateSpawnPoint and not BanditTweaks._patchedScheduler then
        local originalGenerate = BanditScheduler.GenerateSpawnPoint
        BanditScheduler.GenerateSpawnPoint = function(player, dist, ...)
            if type(dist) == "number" then
                dist = BanditTweaks.AdjustBanditSpawnDistance(dist)
            end
            return originalGenerate(player, dist, ...)
        end
        BanditTweaks._patchedScheduler = true
        patchedSomething = true
    end

    local allPatched = BanditTweaks._patchedScheduler
    for _, name in ipairs(hostilePhaseNames) do
        allPatched = allPatched and BanditTweaks["_patchedPhase" .. name]
    end

    if allPatched then
        BanditTweaks._dayOnePatched = true
        Events.OnTick.Remove(tryPatchDayOne)
    elseif not patchedSomething then
        -- wait for next tick when the functions are available
    end
end
Events.OnTick.Add(tryPatchDayOne)

BanditTweaks.DayOneIntegration = DayOneIntegration
return DayOneIntegration
