if isServer() then return end

require "ISUI/ISWorldObjectContextMenu"
require "ISUI/ISUIElement"

local trackedHostiles = {}
local trackedFriendlyHealth = {}

local CIVILIAN_CID = "c167d1e0-c077-4ee5-b353-88b374de193d"
local CIVILIAN_ROLE_KEY = "BanditTweaksCivilianRole"
local CIVILIAN_ROLE_FIGHTER = "fighter"
local CIVILIAN_ROLE_COWARD = "coward"

local function getDefaultFighterPercent()
    local defaults = BanditTweaks and BanditTweaks.Defaults
    if defaults and defaults.civilianFighterPercent then
        return defaults.civilianFighterPercent
    end
    return 20
end

local function clampPercent(value)
    if type(value) ~= "number" then
        return getDefaultFighterPercent()
    end
    if value < 0 then
        return 0
    elseif value > 100 then
        return 100
    end
    return value
end

local function getConfiguredFighterPercent()
    local config = BanditTweaks and BanditTweaks.Config
    local percent = config and config.civilianFighterPercent or getDefaultFighterPercent()
    return clampPercent(percent)
end

local function isCivilianBrain(brain)
    return brain and brain.cid == CIVILIAN_CID
end

local function isCowardBrain(brain)
    return brain and brain._BanditTweaksCivilianCoward == true
end

local originalAreEnemies
local originalNeedResupply

local function removeInventoryItemByFullType(inventory, fullType)
    if not inventory or not fullType then
        return
    end
    local items = inventory:getItems()
    for index = items:size() - 1, 0, -1 do
        local item = items:get(index)
        if item and item:getFullType() == fullType then
            inventory:Remove(item)
        end
    end
end

local function applyCowardLoadout(zombie, brain)
    if not brain then
        return
    end

    brain.weapons = brain.weapons or {}
    brain.weapons.primary = brain.weapons.primary or {}
    brain.weapons.secondary = brain.weapons.secondary or {}

    local inventory = zombie and zombie:getInventory()

    local function clearSlot(slotData)
        if not slotData then
            return
        end
        local weaponName = slotData.name
        slotData.name = nil
        slotData.bulletsLeft = 0
        slotData.magCount = 0
        slotData.ammoCount = 0
        slotData.racked = false
        slotData.type = slotData.type or "nomag"
        slotData.ammoSize = slotData.ammoSize or 0
        slotData.magSize = slotData.magSize or 0
        if inventory and weaponName then
            removeInventoryItemByFullType(inventory, weaponName)
        end
    end

    clearSlot(brain.weapons.primary)
    clearSlot(brain.weapons.secondary)

    if brain.weapons.melee and brain.weapons.melee ~= "Base.BareHands" then
        if inventory then
            removeInventoryItemByFullType(inventory, brain.weapons.melee)
        end
    end
    brain.weapons.melee = "Base.BareHands"

    if zombie then
        zombie:setPrimaryHandItem(nil)
        zombie:setSecondaryHandItem(nil)
        zombie:resetEquippedHandsModels()
    end
end

local function defineCivilianCowardProgram()
    if not ZombiePrograms or ZombiePrograms.CivilianCoward then
        return
    end

    local function findNearestThreat(bandit)
        local bx, by = bandit:getX(), bandit:getY()
        local bestDistSq = math.huge
        local best

        for _, entry in pairs(BanditZombie.CacheLightZ or {}) do
            local dx = bx - entry.x
            local dy = by - entry.y
            local distSq = dx * dx + dy * dy
            if distSq < bestDistSq then
                bestDistSq = distSq
                best = entry
            end
        end

        local selfId = BanditUtils.GetZombieID(bandit)
        for id, entry in pairs(BanditZombie.CacheLightB or {}) do
            if id ~= selfId then
                local otherBrain = entry.brain
                if otherBrain and (otherBrain.hostile or otherBrain.hostileP) then
                    local dx = bx - entry.x
                    local dy = by - entry.y
                    local distSq = dx * dx + dy * dy
                    if distSq < bestDistSq then
                        bestDistSq = distSq
                        best = entry
                    end
                end
            end
        end

        if best then
            return {x = best.x, y = best.y, z = best.z, dist = math.sqrt(bestDistSq)}
        end
    end

    local function findRetreatTarget(bandit, threat)
        local bx, by, bz = bandit:getX(), bandit:getY(), bandit:getZ()
        local dirX, dirY

        if threat then
            dirX = bx - threat.x
            dirY = by - threat.y
        end

        if not dirX or (math.abs(dirX) < 0.001 and math.abs(dirY) < 0.001) then
            local angle = ZombRandFloat(0, math.pi * 2)
            dirX = math.cos(angle)
            dirY = math.sin(angle)
        end

        local length = math.sqrt(dirX * dirX + dirY * dirY)
        if length < 0.001 then
            return
        end

        dirX = dirX / length
        dirY = dirY / length

        local cell = getCell()
        local baseDist = 7 + ZombRand(5)
        for attempt = 1, 10 do
            local step = baseDist + ZombRand(4)
            local tx = math.floor(bx + dirX * step + (ZombRand(5) - 2))
            local ty = math.floor(by + dirY * step + (ZombRand(5) - 2))
            local square = cell:getGridSquare(tx, ty, bz)
            if square and square:isFree(false) and not square:isSolidTrans() and not BanditUtils.IsWater(square) then
                local dist = math.sqrt((bx - tx) * (bx - tx) + (by - ty) * (by - ty))
                return tx + 0.5, ty + 0.5, bz, dist
            end
        end
    end

    local function getRandomHideTarget(bandit)
        local bx, by, bz = bandit:getX(), bandit:getY(), bandit:getZ()
        local cell = getCell()
        for attempt = 1, 10 do
            local radius = 5 + ZombRand(6)
            local angle = ZombRandFloat(0, math.pi * 2)
            local tx = math.floor(bx + math.cos(angle) * radius)
            local ty = math.floor(by + math.sin(angle) * radius)
            local square = cell:getGridSquare(tx, ty, bz)
            if square and square:isFree(false) and not square:isSolidTrans() and not BanditUtils.IsWater(square) then
                local dist = math.sqrt((bx - tx) * (bx - tx) + (by - ty) * (by - ty))
                return tx + 0.5, ty + 0.5, bz, dist
            end
        end
    end

    ZombiePrograms.CivilianCoward = {}

    function ZombiePrograms.CivilianCoward.Prepare(bandit)
        return {status = true, next = "Panic", tasks = {}}
    end

    function ZombiePrograms.CivilianCoward.Panic(bandit)
        local tasks = {}
        local threat = findNearestThreat(bandit)
        local tx, ty, tz, dist = findRetreatTarget(bandit, threat)
        if not tx then
            tx, ty, tz, dist = getRandomHideTarget(bandit)
        end

        if tx then
            local walkType = dist and dist > 4 and "Run" or "Walk"
            table.insert(tasks, BanditUtils.GetMoveTask(0.02, tx, ty, tz, walkType, dist or 4, false))
        else
            table.insert(tasks, {action = "Time", time = 120})
        end

        table.insert(tasks, {action = "Time", time = 80 + ZombRand(80)})
        return {status = true, next = "Hide", tasks = tasks}
    end

    function ZombiePrograms.CivilianCoward.Hide(bandit)
        local threat = findNearestThreat(bandit)
        if threat and threat.dist and threat.dist < 6 then
            return {status = true, next = "Panic", tasks = {}}
        end

        local tasks = {}
        table.insert(tasks, {action = "Time", time = 180 + ZombRand(120)})
        return {status = true, next = "Panic", tasks = tasks}
    end
end

local function ensureCivilianSystems()
    if BanditTweaks._civilianSystemsReady then
        return true
    end

    if not (BanditUtils and BanditZombie and Bandit and BanditBrain and ZombiePrograms) then
        return false
    end

    if not originalAreEnemies and BanditUtils.AreEnemies then
        originalAreEnemies = BanditUtils.AreEnemies
        BanditUtils.AreEnemies = function(brain1, brain2)
            if isCowardBrain(brain1) or isCowardBrain(brain2) then
                return false
            end
            return originalAreEnemies(brain1, brain2)
        end
    end

    if not originalNeedResupply and BanditBrain.NeedResupplySlot then
        originalNeedResupply = BanditBrain.NeedResupplySlot
        BanditBrain.NeedResupplySlot = function(brain, slot)
            if isCowardBrain(brain) then
                return false
            end
            return originalNeedResupply(brain, slot)
        end
    end

    defineCivilianCowardProgram()

    if ZombiePrograms.CivilianCoward then
        BanditTweaks._civilianSystemsReady = true
        return true
    end

    return false
end

local function ensureCowardState(zombie, brain)
    if not ensureCivilianSystems() then
        return
    end

    applyCowardLoadout(zombie, brain)

    brain._BanditTweaksCivilianCoward = true
    brain.programFallback = "CivilianCoward"
    brain.hostile = false
    brain.hostileP = false

    if Bandit.SetHostile then
        Bandit.SetHostile(zombie, false)
    end
    if Bandit.SetHostileP then
        Bandit.SetHostileP(zombie, false)
    end

    if Bandit.ClearTasks then
        Bandit.ClearTasks(zombie)
    end

    if Bandit.SetProgram then
        local program = Bandit.GetProgram and Bandit.GetProgram(zombie)
        if not program or program.name ~= "CivilianCoward" then
            Bandit.SetProgram(zombie, "CivilianCoward", {})
        else
            Bandit.SetProgramStage(zombie, "Prepare")
        end
    end

    BanditBrain.Update(zombie, brain)
end

local function updateCivilianBehavior(zombie, brain)
    if not isCivilianBrain(brain) then
        return
    end

    if not ensureCivilianSystems() then
        return
    end

    local modData = zombie:getModData()
    local role = modData[CIVILIAN_ROLE_KEY]

    if role == CIVILIAN_ROLE_COWARD then
        if not isCowardBrain(brain) then
            ensureCowardState(zombie, brain)
        else
            local program = Bandit.GetProgram and Bandit.GetProgram(zombie)
            if not program or program.name ~= "CivilianCoward" then
                ensureCowardState(zombie, brain)
            end
        end
        return
    elseif role == CIVILIAN_ROLE_FIGHTER then
        return
    end

    local percent = getConfiguredFighterPercent()
    local roll = (brain.rnd and brain.rnd[3]) or ZombRand(100)
    if roll < percent then
        modData[CIVILIAN_ROLE_KEY] = CIVILIAN_ROLE_FIGHTER
    else
        modData[CIVILIAN_ROLE_KEY] = CIVILIAN_ROLE_COWARD
        ensureCowardState(zombie, brain)
    end
end

local function initializeCivilianTweaks()
    ensureCivilianSystems()
end

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
        updateCivilianBehavior(zombie, brain)
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

Events.OnGameStart.Add(initializeCivilianTweaks)
Events.OnLoad.Add(initializeCivilianTweaks)
if Events.OnSandboxOptionsChanged then
    Events.OnSandboxOptionsChanged.Add(initializeCivilianTweaks)
end

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
