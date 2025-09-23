if isServer() then return end

require "ISUI/ISUIElement"

local Indicator = {}
local trackedHostiles = {}

local function trackZombie(zombie)
    trackedHostiles[zombie] = true
end

local function untrackZombie(zombie)
    trackedHostiles[zombie] = nil
end
Indicator.untrackZombie = untrackZombie

local function onZombieUpdate(zombie)
    if not zombie then
        return
    end

    if not zombie:getVariableBoolean("Bandit") then
        untrackZombie(zombie)
        return
    end

    local brain = BanditBrain and BanditBrain.Get(zombie)
    if not brain then
        untrackZombie(zombie)
        return
    end

    if brain.hostile or brain.hostileP then
        trackZombie(zombie)
    else
        untrackZombie(zombie)
    end
end
Events.OnZombieUpdate.Add(onZombieUpdate)

local function onZombieDead(zombie)
    untrackZombie(zombie)
end
Events.OnZombieDead.Add(onZombieDead)

local function ensureIndicatorPanel()
    if BanditTweaks.IndicatorPanel then
        return BanditTweaks.IndicatorPanel
    end

    local width = getCore():getScreenWidth()
    local height = getCore():getScreenHeight()
    local panel = ISUIElement:new(0, 0, width, height)
    panel:initialise()
    panel:setAnchorRight(true)
    panel:setAnchorBottom(true)
    panel.bConsumeMouseEvents = false
    BanditTweaks.IndicatorPanel = panel
    return panel
end
Events.OnGameStart.Add(ensureIndicatorPanel)

local function renderIndicatorOverlay()
    local player = getSpecificPlayer(0)
    if not player then
        return
    end

    local panel = BanditTweaks.IndicatorPanel or ensureIndicatorPanel()
    if not panel then
        return
    end

    local zoom = getCore():getZoom(player:getPlayerNum())
    local size = math.max(4, math.floor(10 / zoom))
    local verticalOffset = 85 / zoom
    local originX = panel:getX()
    local originY = panel:getY()

    for zombie in pairs(trackedHostiles) do
        if zombie and not zombie:isDead() then
            local screenX, screenY = ISCoordConversion.ToScreen(zombie:getX(), zombie:getY(), zombie:getZ())
            local drawX = screenX / zoom - size / 2
            local drawY = screenY / zoom - verticalOffset - size
            panel:drawRect(drawX - originX, drawY - originY, size, size, 0.85, 1, 0, 0)
            panel:drawRectBorder(drawX - originX, drawY - originY, size, size, 1, 0.35, 0, 0)
        end
    end
end
Events.OnPreUIDraw.Add(renderIndicatorOverlay)

local function updatePanelSize()
    if not BanditTweaks.IndicatorPanel then
        return
    end

    BanditTweaks.IndicatorPanel:setWidth(getCore():getScreenWidth())
    BanditTweaks.IndicatorPanel:setHeight(getCore():getScreenHeight())
end
Events.OnResolutionChange.Add(updatePanelSize)

BanditTweaks.Indicator = Indicator
return Indicator
