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

function BanditTweaks.ToggleEnemyIndicators()
    local newState = not BanditTweaks.Config.indicatorEnabled
    BanditTweaks.SetIndicatorEnabled(newState)

    local player = getSpecificPlayer(0)
    if player then
        local message = newState and "Enemy indicators enabled" or "Enemy indicators disabled"
        player:Say(message)
    end
end

function BanditTweaks.ToggleIndicatorStyle()
    local outline = not BanditTweaks.Config.indicatorOutline
    BanditTweaks.SetIndicatorOutline(outline)

    local player = getSpecificPlayer(0)
    if player then
        local message = outline and "Enemy indicators set to outline" or "Enemy indicators set to filled"
        player:Say(message)
    end
end

local function addBanditTweaksOptions(playerNum, context, worldobjects, test)
    local friendlyLabel = BanditTweaks.Config.friendlyFireEnabled and "Disable Friendly Fire" or "Enable Friendly Fire"
    local friendlyOption = context:addOption("[Bandit Tweaks] " .. friendlyLabel, worldobjects, BanditTweaks.ToggleFriendlyFire)
    if friendlyOption then
        local toolTip = ISWorldObjectContextMenu.addToolTip()
        toolTip.description = "When disabled you cannot damage friendly bandits."
        toolTip:setName("Enable Friendly Fire")
        friendlyOption.toolTip = toolTip
    end

    local indicatorLabel = BanditTweaks.Config.indicatorEnabled and "Disable Enemy Indicators" or "Enable Enemy Indicators"
    local indicatorOption = context:addOption("[Bandit Tweaks] " .. indicatorLabel, worldobjects, BanditTweaks.ToggleEnemyIndicators)
    if indicatorOption then
        local toolTip = ISWorldObjectContextMenu.addToolTip()
        toolTip.description = "Show or hide the hostile bandit indicator above enemies."
        toolTip:setName("Enemy Indicator")
        indicatorOption.toolTip = toolTip
    end

    local styleLabel = BanditTweaks.Config.indicatorOutline and "Use Filled Enemy Indicator" or "Use Outline Enemy Indicator"
    local styleOption = context:addOption("[Bandit Tweaks] " .. styleLabel, worldobjects, BanditTweaks.ToggleIndicatorStyle)
    if styleOption then
        local toolTip = ISWorldObjectContextMenu.addToolTip()
        toolTip.description = "Switch between a filled or outline indicator for hostile bandits."
        toolTip:setName("Enemy Indicator Style")
        styleOption.toolTip = toolTip
    end
end
Events.OnFillWorldObjectContextMenu.Add(addBanditTweaksOptions)

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

        if not BanditTweaks.Config.indicatorEnabled then
            return
        end

        local zoom = getCore():getZoom(player:getPlayerNum())
        local size = math.max(4, math.floor(10 / zoom))
        local verticalOffset = 85 / zoom

        for zombie in pairs(trackedHostiles) do
            if zombie and not zombie:isDead() then
                local canSee = false
                if player.CanSee then
                    canSee = player:CanSee(zombie) and true or false
                end

                if not canSee and player.canSeeSquare then
                    local square = zombie:getCurrentSquare()
                    if square then
                        canSee = player:canSeeSquare(square)
                    end
                end

                if canSee then
                    local screenX, screenY = ISCoordConversion.ToScreen(zombie:getX(), zombie:getY(), zombie:getZ())
                    local drawX = screenX / zoom - size / 2
                    local drawY = screenY / zoom - verticalOffset - size
                    if BanditTweaks.Config.indicatorOutline then
                        self:drawRectBorder(drawX, drawY, size, size, 1, 1, 0, 0)
                    else
                        self:drawRect(drawX, drawY, size, size, 0.85, 1, 0, 0)
                        self:drawRectBorder(drawX, drawY, size, size, 1, 0.35, 0, 0)
                    end
                end
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
