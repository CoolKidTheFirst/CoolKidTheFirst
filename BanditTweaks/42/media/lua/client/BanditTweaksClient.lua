if isServer() then return end

require "ISUI/ISWorldObjectContextMenu"
require "ISUI/ISUIElement"

local trackedHostiles = {}
local trackedFriendlyHealth = {}

local function clearFriendlyHealth()
    for zombie in pairs(trackedFriendlyHealth) do
        trackedFriendlyHealth[zombie] = nil
    end
end

function BanditTweaks.ToggleFriendlyFire()
    local newState = not BanditTweaks.Config.friendlyFireEnabled
    BanditTweaks.SetFriendlyFireEnabled(newState)

    if newState then
        clearFriendlyHealth()
    end

    local player = getSpecificPlayer(0)
    if player then
        local message = newState and "Friendly fire enabled" or "Friendly fire disabled"
        player:Say(message)
    end
end

local function addFriendlyFireOption(playerNum, context, worldobjects, test)
    local label
    if BanditTweaks.Config.friendlyFireEnabled then
        label = "Disable Friendly Fire"
    else
        label = "Enable Friendly Fire"
    end

    local option = context:addOption("[Bandit Tweaks] " .. label, worldobjects, BanditTweaks.ToggleFriendlyFire)
    if option then
        local toolTip = ISWorldObjectContextMenu.addToolTip()
        toolTip.description = "When disabled you cannot damage friendly bandits."
        toolTip:setName("Enable Friendly Fire")
        option.toolTip = toolTip
    end
end
Events.OnFillWorldObjectContextMenu.Add(addFriendlyFireOption)

local function shouldTrackFriendly()
    return not BanditTweaks.Config.friendlyFireEnabled
end

local function onZombieUpdate(zombie)
    if not zombie then
        return
    end
    if not zombie:getVariableBoolean("Bandit") then
        trackedHostiles[zombie] = nil
        trackedFriendlyHealth[zombie] = nil
        return
    end

    local brain = BanditBrain and BanditBrain.Get(zombie)
    if not brain then
        trackedHostiles[zombie] = nil
        trackedFriendlyHealth[zombie] = nil
        return
    end

    local isHostile = brain.hostile or brain.hostileP
    if isHostile then
        trackedHostiles[zombie] = true
        trackedFriendlyHealth[zombie] = nil
    else
        trackedHostiles[zombie] = nil
        if shouldTrackFriendly() then
            trackedFriendlyHealth[zombie] = zombie:getHealth()
        else
            trackedFriendlyHealth[zombie] = nil
        end
    end
end
Events.OnZombieUpdate.Add(onZombieUpdate)

local function onZombieDead(zombie)
    trackedHostiles[zombie] = nil
    trackedFriendlyHealth[zombie] = nil
end
Events.OnZombieDead.Add(onZombieDead)

local function onHitZombie(zombie, attacker, bodyPartType, handWeapon)
    if BanditTweaks.Config.friendlyFireEnabled then
        return
    end

    if not zombie or not zombie:getVariableBoolean("Bandit") then
        return
    end

    local brain = BanditBrain and BanditBrain.Get(zombie)
    if not brain or brain.hostile or brain.hostileP then
        return
    end

    if not attacker or not instanceof(attacker, "IsoPlayer") then
        return
    end

    local previous = trackedFriendlyHealth[zombie]
    if previous then
        zombie:setHealth(previous)
    end
end
Events.OnHitZombie.Add(onHitZombie)

local function ensureIndicatorPanel()
    if BanditTweaks.IndicatorPanel then
        return
    end

    local width = getCore():getScreenWidth()
    local height = getCore():getScreenHeight()
    local panel = ISUIElement:new(0, 0, width, height)
    panel:initialise()
    panel:setAnchorRight(true)
    panel:setAnchorBottom(true)
    panel:setAlwaysOnTop(true)
    panel.bConsumeMouseEvents = false

    function panel:render()
        if not isIngameState() then
            return
        end

        local player = getSpecificPlayer(0)
        if not player then
            return
        end

        local zoom = getCore():getZoom(player:getPlayerNum())
        local size = math.max(4, math.floor(10 / zoom))
        local verticalOffset = 85 / zoom

        for zombie in pairs(trackedHostiles) do
            if zombie and not zombie:isDead() then
                local screenX, screenY = ISCoordConversion.ToScreen(zombie:getX(), zombie:getY(), zombie:getZ())
                local drawX = screenX / zoom - size / 2
                local drawY = screenY / zoom - verticalOffset - size
                self:drawRect(drawX, drawY, size, size, 0.85, 1, 0, 0)
                self:drawRectBorder(drawX, drawY, size, size, 1, 0.35, 0, 0)
            end
        end
    end

    panel:addToUIManager()
    BanditTweaks.IndicatorPanel = panel
end
Events.OnGameStart.Add(ensureIndicatorPanel)

local function updatePanelSize()
    if not BanditTweaks.IndicatorPanel then
        return
    end

    BanditTweaks.IndicatorPanel:setWidth(getCore():getScreenWidth())
    BanditTweaks.IndicatorPanel:setHeight(getCore():getScreenHeight())
end
Events.OnResolutionChange.Add(updatePanelSize)

local function patchFriendlyFireCheck()
    if BanditTweaks._patchedFriendlyFireCheck then
        Events.OnTick.Remove(patchFriendlyFireCheck)
        return
    end

    if BanditPlayer and BanditPlayer.CheckFriendlyFire then
        local original = BanditPlayer.CheckFriendlyFire
        BanditPlayer.CheckFriendlyFire = function(bandit, attacker)
            if not BanditTweaks.Config.friendlyFireEnabled then
                return
            end
            return original(bandit, attacker)
        end
        BanditTweaks._patchedFriendlyFireCheck = true
        Events.OnTick.Remove(patchFriendlyFireCheck)
    end
end
Events.OnTick.Add(patchFriendlyFireCheck)

local hostilePhaseNames = {"SpawnGang", "SpawnBandits", "SpawnInmates"}

local function cloneSpawnPoint(point)
    if not point then
        return nil
    end
    return {x = point.x, y = point.y, z = point.z}
end

local function normalizeSpawnPoint(spawnPoint)
    if type(spawnPoint) ~= "table" then
        return nil
    end

    if spawnPoint.x and spawnPoint.y then
        return cloneSpawnPoint(spawnPoint)
    end

    for _, value in pairs(spawnPoint) do
        if type(value) == "table" and value.x and value.y then
            return cloneSpawnPoint(value)
        end
    end

    return nil
end

local function isSpawnPointFarEnough(player, point, minDistance)
    if not player or not point or not minDistance then
        return false
    end

    local px, py = player:getX(), player:getY()
    local dx, dy = point.x - px, point.y - py
    return (dx * dx + dy * dy) >= (minDistance * minDistance)
end

local function findDayOneStarterSpawnPoint(player)
    if not player or not BanditScheduler or not BanditScheduler.GenerateSpawnPoint then
        return nil
    end

    local baseDistance = BanditTweaks.Config.dayOneStarterMinDistance or BanditTweaks.Defaults.dayOneStarterMinDistance or 35
    local attempts = {baseDistance + 15, baseDistance + 5, baseDistance}

    for _, dist in ipairs(attempts) do
        local rawPoint = BanditScheduler.GenerateSpawnPoint(player, dist)
        local point = normalizeSpawnPoint(rawPoint)
        if point then
            point.z = point.z or player:getZ()
            if isSpawnPointFarEnough(player, point, baseDistance) then
                return point
            end
        end
    end

    return nil
end

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

        if not BanditTweaks._patchedDayOneFamily and type(DOPhases.SpawnFamilly) == "function" then
            DOPhases.SpawnFamilly = function(player, ...)
                if not player then
                    return
                end

                if not BanditTweaks.Config.dayOneStarterEnabled then
                    return
                end

                local spawnPoint = findDayOneStarterSpawnPoint(player)
                if not spawnPoint then
                    return
                end

                local config = {}
                config.clanId = 1
                config.hasRifleChance = 0
                config.hasPistolChance = 0
                config.rifleMagCount = 0
                config.pistolMagCount = 0

                local event = {}
                event.hostile = false
                event.occured = false
                event.program = {name = "Companion", stage = "Prepare"}
                event.x = spawnPoint.x
                event.y = spawnPoint.y
                event.z = spawnPoint.z or player:getZ()
                event.bandits = {}

                local bandit = BanditCreator.MakeFromWave(config)
                table.insert(event.bandits, bandit)
                table.insert(event.bandits, bandit)

                addSound(player, event.x, event.y, event.z, 40, 100)
                sendClientCommand(player, 'Commands', 'SpawnGroup', event)
            end
            BanditTweaks._patchedDayOneFamily = true
            patchedSomething = true
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

    local allPatched = BanditTweaks._patchedScheduler and BanditTweaks._patchedDayOneFamily
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
