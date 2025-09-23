if isServer() then return end

local CivilianBehavior = {}

local CIVILIAN_CID = "c167d1e0-c077-4ee5-b353-88b374de193d"
CivilianBehavior.CIVILIAN_ROLE_KEY = "BanditTweaksCivilianRole"
CivilianBehavior.ROLE_FIGHTER = "fighter"
CivilianBehavior.ROLE_COWARD = "coward"
CivilianBehavior.ROLE_HIDER = "hider"
CivilianBehavior.ROLE_PANICKED = "panicked"
CivilianBehavior.ROLE_SHADOW = "shadow"

local originalAreEnemies
local originalNeedResupply
local voiceTracker = {}
CivilianBehavior._roleRevision = 0

local voicePools = {
    random = {
        {text = "Oh God... what is happening?"},
        {text = "This wasn't supposed to be our story."},
        {text = "Stay calm, stay calm..."},
        {text = "Anyone still out there?"},
        {text = "Why won't this end?!"},
        {text = "I should have stayed in bed today."},
        {text = "Breathe. Just breathe."},
        {text = "Please tell me someone has a plan."},
        {text = "We should have left sooner..."},
        {text = "This feels like the end of the world."},
        {text = "They're everywhere..."},
        {text = "Keep it together, keep it together."},
        {text = "I can't believe this is real."},
        {text = "How did it spread so fast?"},
        {text = "We need walls. We need doors shut."},
        {text = "My hands won't stop shaking."},
        {text = "I hear them... they're close."},
        {text = "Somebody answer me!"},
        {text = "I didn't sign up for this."},
        {text = "Just keep moving. Don't freeze."},
        {text = "Please don't let me end up like them."},
        {text = "I miss the sound of traffic."},
        {text = "Anyone got ammo? No? Great."},
        {text = "Where are the soldiers?"},
        {text = "How many of us are left?"},
        {text = "This town used to be quiet..."},
        {text = "Why did we split up?"},
        {text = "I can still smell the smoke."},
        {text = "Doors open mean death out here."},
        {text = "Keep talking, keep sane."},
        {text = "I don't think I can sleep again."},
        {text = "Did you hear that?"},
        {text = "We're sitting ducks out here."},
        {text = "I hope the bandits keep their word."},
        {text = "If we hide maybe they'll pass."},
        {text = "Stay with me, please!"},
        {text = "I'm not cut out for this."},
        {text = "Why won't the radios work?"},
        {text = "Too quiet... way too quiet."},
        {text = "I should have barricaded that door."},
        {text = "Don't leave me alone!"},
        {text = "Is there anyone we can trust?"},
        {text = "They said the military was coming..."},
        {text = "We need more hands. And more courage."},
        {text = "I'm not going back out there alone."},
        {text = "Please let this barricade hold."},
        {text = "Every shadow looks like a walker."},
        {text = "I hate the sound of breaking glass now."},
        {text = "I can't lose anyone else."},
        {text = "Do you think they'll find us?"},
        {text = "Keep your head down and pray."},
        {text = "We lock every door. Every single one."},
    },
    hurt = {
        {text = "It hurts! Oh God, it hurts!"},
        {text = "I'm bleeding! Somebody help!"},
        {text = "No no no, stay back!"},
        {text = "I can't stop the bleeding!"},
        {text = "They got me!"},
        {text = "I'm hit! I'm hit!"},
        {text = "Please, I don't wanna die like this!"},
        {text = "My arm! It feels broken!"},
        {text = "I need bandages! Anything!"},
        {text = "I can't feel my fingers!"},
        {text = "That was too close!"},
        {text = "Keep them off me!"},
        {text = "They're tearing through us!"},
        {text = "I'm not okay! I'm not okay!"},
        {text = "Stitches... I need stitches..."},
        {text = "I can taste blood..."},
        {text = "Somebody cover me!"},
        {text = "Get it off! Get it off!"},
        {text = "My leg! I can't run!"},
        {text = "Stay with me, stay with me!"},
    },
    panic = {
        {text = "They're coming! Move!"},
        {text = "Run! Don't look back!"},
        {text = "They're everywhere!"},
        {text = "Shut the doors! Shut them now!"},
        {text = "Why won't they stop?!"},
        {text = "Keep moving! Keep moving!"},
        {text = "Please tell me you can fight!"},
        {text = "We can't stay here!"},
        {text = "They're breaking through!"},
        {text = "Someone grab a weapon!"},
        {text = "I hear more of them!"},
        {text = "Don't let them corner us!"},
        {text = "They're right behind me!"},
        {text = "We need help!"},
        {text = "Don't you dare leave me!"},
    }
}

local function clampPercent(value, default)
    if type(value) ~= "number" then
        return default
    end
    if value < 0 then
        return 0
    elseif value > 100 then
        return 100
    end
    return value
end

local function getWorldHours()
    local gameTime = getGameTime()
    if not gameTime then
        return 0
    end
    return gameTime:getWorldAgeHours() or 0
end

local function getConfig()
    local config = BanditTweaks and BanditTweaks.Config
    local defaults = BanditTweaks and BanditTweaks.Defaults
    return config or defaults or {}
end

local function getRolePercents()
    local config = getConfig()
    local defaults = BanditTweaks and BanditTweaks.Defaults or {}
    local fighter = clampPercent(config.civilianFighterPercent or defaults.civilianFighterPercent or 20, defaults.civilianFighterPercent or 20)
    local hider = clampPercent(config.civilianHidePercent or defaults.civilianHidePercent or 20, defaults.civilianHidePercent or 20)
    local panic = clampPercent(config.civilianPanicPercent or defaults.civilianPanicPercent or 20, defaults.civilianPanicPercent or 20)
    local shadow = clampPercent(config.civilianSeekProtectionPercent or defaults.civilianSeekProtectionPercent or 20, defaults.civilianSeekProtectionPercent or 20)

    local totalSpecial = hider + panic + shadow
    if totalSpecial > 100 and totalSpecial > 0 then
        local scale = 100 / totalSpecial
        hider = math.floor(hider * scale + 0.5)
        panic = math.floor(panic * scale + 0.5)
        shadow = math.floor(shadow * scale + 0.5)
        local adjusted = hider + panic + shadow
        if adjusted > 100 then
            local overflow = adjusted - 100
            if shadow >= overflow then
                shadow = shadow - overflow
            elseif panic >= overflow then
                panic = panic - overflow
            else
                hider = math.max(0, hider - overflow)
            end
        end
    end

    return fighter, hider, panic, shadow
end

local function getProgramNameForRole(role)
    if role == CivilianBehavior.ROLE_HIDER then
        return "CivilianHider"
    elseif role == CivilianBehavior.ROLE_PANICKED then
        return "CivilianPanicked"
    elseif role == CivilianBehavior.ROLE_SHADOW then
        return "CivilianShadow"
    end
    return "CivilianCoward"
end

local function getBrainRole(brain)
    if not brain then
        return nil
    end
    if brain._BanditTweaksCivilianRole then
        return brain._BanditTweaksCivilianRole
    end
    if brain._BanditTweaksCivilianCoward then
        return CivilianBehavior.ROLE_COWARD
    end
    return nil
end

local function isCivilianBrain(brain)
    return brain and brain.cid == CIVILIAN_CID
end
CivilianBehavior.isCivilianBrain = isCivilianBrain

local function isNonCombatCivilian(brain)
    local role = getBrainRole(brain)
    return role and role ~= CivilianBehavior.ROLE_FIGHTER
end
CivilianBehavior.isCowardBrain = isNonCombatCivilian

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

local function applyCivilianDisarm(zombie, brain)
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

local function findNearestThreat(bandit)
    if not BanditZombie then
        return nil
    end

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

    local selfId = BanditUtils and BanditUtils.GetZombieID and BanditUtils.GetZombieID(bandit)
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
    return nil
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
    for _ = 1, 10 do
        local step = baseDist + ZombRand(4)
        local tx = math.floor(bx + dirX * step + (ZombRand(5) - 2))
        local ty = math.floor(by + dirY * step + (ZombRand(5) - 2))
        local square = cell and cell:getGridSquare(tx, ty, bz)
        if square and square:isFree(false) and not square:isSolidTrans() and not (BanditUtils and BanditUtils.IsWater and BanditUtils.IsWater(square)) then
            local dist = math.sqrt((bx - tx) * (bx - tx) + (by - ty) * (by - ty))
            return tx + 0.5, ty + 0.5, bz, dist
        end
    end
end

local function getRandomHideTarget(bandit)
    local bx, by, bz = bandit:getX(), bandit:getY(), bandit:getZ()
    local cell = getCell()
    for _ = 1, 10 do
        local radius = 5 + ZombRand(6)
        local angle = ZombRandFloat(0, math.pi * 2)
        local tx = math.floor(bx + math.cos(angle) * radius)
        local ty = math.floor(by + math.sin(angle) * radius)
        local square = cell and cell:getGridSquare(tx, ty, bz)
        if square and square:isFree(false) and not square:isSolidTrans() and not (BanditUtils and BanditUtils.IsWater and BanditUtils.IsWater(square)) then
            local dist = math.sqrt((bx - tx) * (bx - tx) + (by - ty) * (by - ty))
            return tx + 0.5, ty + 0.5, bz, dist
        end
    end
end

local function pickSquareInRoom(room)
    if not room then
        return nil
    end
    local roomDef = room:getRoomDef()
    if not roomDef then
        return nil
    end

    for _ = 1, 12 do
        local rx = ZombRand(roomDef:getX(), roomDef:getX2() + 1)
        local ry = ZombRand(roomDef:getY(), roomDef:getY2() + 1)
        local square = getCell() and getCell():getGridSquare(rx, ry, roomDef:getZ())
        if square and square:isFree(false) and not square:isSolidTrans() then
            return {x = rx + 0.5, y = ry + 0.5, z = roomDef:getZ()}
        end
    end

    return nil
end

local function findShelterSquare(bandit)
    local current = bandit:getSquare()
    if current and current:getRoom() then
        return {x = current:getX() + 0.5, y = current:getY() + 0.5, z = current:getZ(), dist = 0}
    end

    local bx, by, bz = bandit:getX(), bandit:getY(), bandit:getZ()
    local cell = getCell()
    local bestSquare
    local bestDistSq = math.huge

    for radius = 2, 14 do
        for attempt = 1, 8 do
            local angle = ZombRandFloat(0, math.pi * 2)
            local tx = math.floor(bx + math.cos(angle) * radius)
            local ty = math.floor(by + math.sin(angle) * radius)
            local square = cell and cell:getGridSquare(tx, ty, bz)
            if square and square:getRoom() and square:isFree(false) and not square:isSolidTrans() then
                local dx = bx - tx
                local dy = by - ty
                local distSq = dx * dx + dy * dy
                if distSq < bestDistSq then
                    bestDistSq = distSq
                    bestSquare = square
                end
            end
        end
        if bestSquare then
            break
        end
    end

    if bestSquare then
        return {x = bestSquare:getX() + 0.5, y = bestSquare:getY() + 0.5, z = bestSquare:getZ(), dist = math.sqrt(bestDistSq)}
    end

    return nil
end

local function findProtectionTarget(bandit)
    local bx, by = bandit:getX(), bandit:getY()
    local best
    local bestDistSq = math.huge

    if BanditZombie and BanditZombie.CacheLightB then
        local selfId = BanditUtils and BanditUtils.GetZombieID and BanditUtils.GetZombieID(bandit)
        for id, entry in pairs(BanditZombie.CacheLightB) do
            if id ~= selfId then
                local zombie = BanditZombie.Cache and BanditZombie.Cache[id]
                if zombie then
                    local brain = entry.brain or (BanditBrain and BanditBrain.Get and BanditBrain.Get(zombie))
                    if brain and not brain.hostile and not brain.hostileP then
                        local role = getBrainRole(brain)
                        local canFight = not role or role == CivilianBehavior.ROLE_FIGHTER
                        if brain.cid ~= CIVILIAN_CID or canFight then
                            local dx = bx - entry.x
                            local dy = by - entry.y
                            local distSq = dx * dx + dy * dy
                            if distSq < bestDistSq then
                                bestDistSq = distSq
                                best = {x = entry.x + 0.5, y = entry.y + 0.5, z = entry.z, dist = math.sqrt(distSq)}
                            end
                        end
                    end
                end
            end
        end
    end

    if getNumActivePlayers then
        for i = 0, getNumActivePlayers() - 1 do
            local player = getSpecificPlayer(i)
            if player then
                local dx = bx - player:getX()
                local dy = by - player:getY()
                local distSq = dx * dx + dy * dy
                if distSq < bestDistSq then
                    bestDistSq = distSq
                    best = {x = player:getX(), y = player:getY(), z = player:getZ(), dist = math.sqrt(distSq)}
                end
            end
        end
    end

    return best
end

local function defineCivilianPrograms()
    ZombiePrograms = ZombiePrograms or {}

    if not ZombiePrograms.CivilianCoward then
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

    if not ZombiePrograms.CivilianPanicked then
        ZombiePrograms.CivilianPanicked = {}

        function ZombiePrograms.CivilianPanicked.Prepare(bandit)
            return {status = true, next = "Sprint", tasks = {}}
        end

        function ZombiePrograms.CivilianPanicked.Sprint(bandit)
            local tasks = {}
            local threat = findNearestThreat(bandit)
            local tx, ty, tz, dist = findRetreatTarget(bandit, threat)
            if not tx then
                tx, ty, tz, dist = getRandomHideTarget(bandit)
            end

            if tx then
                table.insert(tasks, BanditUtils.GetMoveTask(0.04, tx, ty, tz, "Run", dist or 5, false))
            end

            table.insert(tasks, {action = "Time", time = 60 + ZombRand(40)})
            return {status = true, next = "CatchBreath", tasks = tasks}
        end

        function ZombiePrograms.CivilianPanicked.CatchBreath(bandit)
            local tasks = {}
            table.insert(tasks, {action = "Time", time = 70 + ZombRand(60)})
            return {status = true, next = "Sprint", tasks = tasks}
        end
    end

    if not ZombiePrograms.CivilianHider then
        ZombiePrograms.CivilianHider = {}

        function ZombiePrograms.CivilianHider.Prepare(bandit)
            return {status = true, next = "FindShelter", tasks = {}}
        end

        function ZombiePrograms.CivilianHider.FindShelter(bandit)
            local tasks = {}
            local target = findShelterSquare(bandit)
            if target then
                local walkType = target.dist and target.dist > 4 and "Run" or "Walk"
                table.insert(tasks, BanditUtils.GetMoveTask(0.02, target.x, target.y, target.z, walkType, math.max(2, target.dist or 2), false))
                table.insert(tasks, {action = "Time", time = 80 + ZombRand(80)})
                return {status = true, next = "Secure", tasks = tasks}
            end

            table.insert(tasks, {action = "Time", time = 120 + ZombRand(60)})
            return {status = true, next = "FindShelter", tasks = tasks}
        end

        function ZombiePrograms.CivilianHider.Secure(bandit)
            local threat = findNearestThreat(bandit)
            if threat and threat.dist and threat.dist < 8 then
                return {status = true, next = "FindShelter", tasks = {}}
            end

            local tasks = {}
            local square = bandit:getSquare()
            if square and square:getRoom() then
                local roam = pickSquareInRoom(square:getRoom())
                if roam and ZombRand(100) < 60 then
                    table.insert(tasks, BanditUtils.GetMoveTask(0, roam.x, roam.y, roam.z, "Walk", 1.5, false))
                end
            end
            table.insert(tasks, {action = "Time", time = 200 + ZombRand(160)})
            return {status = true, next = "Secure", tasks = tasks}
        end
    end

    if not ZombiePrograms.CivilianShadow then
        ZombiePrograms.CivilianShadow = {}

        function ZombiePrograms.CivilianShadow.Prepare(bandit)
            return {status = true, next = "SeekProtection", tasks = {}}
        end

        function ZombiePrograms.CivilianShadow.SeekProtection(bandit)
            local tasks = {}
            local target = findProtectionTarget(bandit)
            if target then
                local dist = target.dist or 0
                local walkType = dist > 7 and "Run" or "Walk"
                local offsetX = ZombRandFloat(-1.0, 1.0)
                local offsetY = ZombRandFloat(-1.0, 1.0)
                table.insert(tasks, BanditUtils.GetMoveTask(0.02, target.x + offsetX, target.y + offsetY, target.z, walkType, math.max(1.5, dist * 0.6), false))
                table.insert(tasks, {action = "Time", time = 100 + ZombRand(80)})
                return {status = true, next = "SeekProtection", tasks = tasks}
            end

            table.insert(tasks, {action = "Time", time = 120 + ZombRand(60)})
            return {status = true, next = "Fallback", tasks = tasks}
        end

        function ZombiePrograms.CivilianShadow.Fallback(bandit)
            local tasks = {}
            local threat = findNearestThreat(bandit)
            local tx, ty, tz, dist = findRetreatTarget(bandit, threat)
            if tx then
                table.insert(tasks, BanditUtils.GetMoveTask(0.02, tx, ty, tz, "Run", dist or 4, false))
            else
                tx, ty, tz, dist = getRandomHideTarget(bandit)
                if tx then
                    table.insert(tasks, BanditUtils.GetMoveTask(0.02, tx, ty, tz, "Walk", dist or 4, false))
                end
            end
            table.insert(tasks, {action = "Time", time = 80 + ZombRand(60)})
            return {status = true, next = "SeekProtection", tasks = tasks}
        end
    end
end

local function ensureCivilianSystems()
    if CivilianBehavior._civilianSystemsReady then
        return true
    end

    if not (BanditUtils and BanditZombie and Bandit and BanditBrain) then
        return false
    end

    if not originalAreEnemies and BanditUtils.AreEnemies then
        originalAreEnemies = BanditUtils.AreEnemies
        BanditUtils.AreEnemies = function(brain1, brain2)
            if isNonCombatCivilian(brain1) or isNonCombatCivilian(brain2) then
                return false
            end
            return originalAreEnemies(brain1, brain2)
        end
    end

    if not originalNeedResupply and BanditBrain.NeedResupplySlot then
        originalNeedResupply = BanditBrain.NeedResupplySlot
        BanditBrain.NeedResupplySlot = function(brain, slot)
            if isNonCombatCivilian(brain) then
                return false
            end
            return originalNeedResupply(brain, slot)
        end
    end

    defineCivilianPrograms()

    CivilianBehavior._civilianSystemsReady = true
    return true
end
CivilianBehavior.ensureCivilianSystems = ensureCivilianSystems

local function setFriendlyState(zombie, brain)
    brain.hostile = false
    brain.hostileP = false
    brain._BanditTweaksCivilianCoward = true

    if Bandit.SetHostile then
        Bandit.SetHostile(zombie, false)
    end
    if Bandit.SetHostileP then
        Bandit.SetHostileP(zombie, false)
    end

    if Bandit.ClearTasks then
        Bandit.ClearTasks(zombie)
    end
end

local function applyRole(zombie, brain, role)
    if not ensureCivilianSystems() then
        return false
    end
    if not zombie or not brain then
        return false
    end

    local modData = zombie:getModData()
    modData[CivilianBehavior.CIVILIAN_ROLE_KEY] = role
    modData._BanditTweaksCivilianRoleRevision = CivilianBehavior._roleRevision

    brain._BanditTweaksCivilianRole = role

    if role == CivilianBehavior.ROLE_FIGHTER then
        brain._BanditTweaksCivilianCoward = nil
        return true
    end

    applyCivilianDisarm(zombie, brain)
    setFriendlyState(zombie, brain)

    local programName = getProgramNameForRole(role)
    brain.programFallback = programName

    if Bandit.SetProgram then
        local program = Bandit.GetProgram and Bandit.GetProgram(zombie)
        if not program or program.name ~= programName then
            Bandit.SetProgram(zombie, programName, {})
        else
            Bandit.SetProgramStage(zombie, "Prepare")
        end
    end

    if BanditBrain.Update then
        BanditBrain.Update(zombie, brain)
    end

    return true
end

local function rollCivilianRole(brain)
    local fighter, hider, panic, shadow = getRolePercents()
    local roll = (brain and brain.rnd and brain.rnd[3]) or ZombRand(100)
    if roll < fighter then
        return CivilianBehavior.ROLE_FIGHTER
    end

    local nonFighterRoll = ZombRand(100)
    if nonFighterRoll < hider then
        return CivilianBehavior.ROLE_HIDER
    elseif nonFighterRoll < hider + panic then
        return CivilianBehavior.ROLE_PANICKED
    elseif nonFighterRoll < hider + panic + shadow then
        return CivilianBehavior.ROLE_SHADOW
    end

    return CivilianBehavior.ROLE_COWARD
end

local function ensureRoleActive(zombie, brain, role)
    if role == CivilianBehavior.ROLE_FIGHTER then
        brain._BanditTweaksCivilianRole = role
        return
    end

    if not brain._BanditTweaksCivilianRole or brain._BanditTweaksCivilianRole ~= role then
        applyRole(zombie, brain, role)
        return
    end

    local programName = getProgramNameForRole(role)
    if Bandit.GetProgram then
        local program = Bandit.GetProgram(zombie)
        if not program or program.name ~= programName then
            applyRole(zombie, brain, role)
        end
    end
end

local function pickVoiceLine(pool, lastLine)
    if not pool or #pool == 0 then
        return nil
    end
    local line
    for attempt = 1, 4 do
        line = pool[ZombRand(#pool) + 1]
        if not lastLine or lastLine.text ~= line.text then
            break
        end
    end
    return line
end

local function sayVoiceLine(zombie, category, data)
    local config = getConfig()
    if config.civilianVoicesEnabled == false then
        return
    end
    local pool = voicePools[category]
    if not pool then
        return
    end

    local lastLine
    if category == "random" then
        lastLine = data.lastRandomLine
    elseif category == "hurt" then
        lastLine = data.lastHurtLine
    elseif category == "panic" then
        lastLine = data.lastPanicLine
    end

    local line = pickVoiceLine(pool, lastLine)
    if not line then
        return
    end

    if zombie and line.text and zombie.Say then
        zombie:Say(line.text)
    elseif zombie and line.text then
        zombie:Say(line.text)
    end

    if category == "random" then
        data.lastRandomLine = line
    elseif category == "hurt" then
        data.lastHurtLine = line
    elseif category == "panic" then
        data.lastPanicLine = line
    end
end

local function updateCivilianVoices(zombie, brain, role)
    if not zombie then
        return
    end

    local config = getConfig()
    if config.civilianVoicesEnabled == false then
        voiceTracker[zombie] = nil
        return
    end

    local data = voiceTracker[zombie]
    if not data then
        data = {lastHealth = zombie:getHealth() or 1, nextRandom = 0, nextHurt = 0, nextPanic = 0}
        voiceTracker[zombie] = data
    end

    local now = getWorldHours()
    local health = zombie:getHealth() or data.lastHealth or 1
    local healthDelta = (data.lastHealth or health) - health
    local randomInterval = math.max(config.civilianRandomVoiceIntervalHours or (BanditTweaks.Defaults and BanditTweaks.Defaults.civilianRandomVoiceIntervalHours) or 0, 0)
    local hurtCooldown = math.max(config.civilianHurtVoiceCooldownHours or (BanditTweaks.Defaults and BanditTweaks.Defaults.civilianHurtVoiceCooldownHours) or 0, 0)

    if healthDelta > 0.04 and now >= (data.nextHurt or 0) then
        sayVoiceLine(zombie, "hurt", data)
        data.nextHurt = now + hurtCooldown
    end

    if role ~= CivilianBehavior.ROLE_FIGHTER then
        local threat = findNearestThreat(zombie)
        if threat and threat.dist and threat.dist < 6 and now >= (data.nextPanic or 0) then
            sayVoiceLine(zombie, "panic", data)
            data.nextPanic = now + math.max(0.02, randomInterval * 0.5)
        end
    end

    if randomInterval > 0 and now >= (data.nextRandom or 0) then
        sayVoiceLine(zombie, "random", data)
        data.nextRandom = now + randomInterval * (0.75 + ZombRandFloat(0, 0.75))
    end

    data.lastHealth = health
end

local function updateCivilianBehavior(zombie, brain)
    if not ensureCivilianSystems() then
        return
    end

    local modData = zombie:getModData()
    local storedRevision = modData._BanditTweaksCivilianRoleRevision or 0
    if storedRevision ~= CivilianBehavior._roleRevision then
        modData[CivilianBehavior.CIVILIAN_ROLE_KEY] = nil
        brain._BanditTweaksCivilianRole = nil
        modData._BanditTweaksCivilianRoleRevision = CivilianBehavior._roleRevision
    end

    local role = modData[CivilianBehavior.CIVILIAN_ROLE_KEY]
    if not role then
        role = rollCivilianRole(brain)
        applyRole(zombie, brain, role)
    else
        ensureRoleActive(zombie, brain, role)
    end

    updateCivilianVoices(zombie, brain, role)
end

local function onZombieUpdate(zombie)
    if not zombie or not zombie:getVariableBoolean("Bandit") then
        voiceTracker[zombie] = nil
        return
    end

    local brain = BanditBrain and BanditBrain.Get and BanditBrain.Get(zombie)
    if not brain then
        return
    end

    updateCivilianBehavior(zombie, brain)
end

local function onZombieDead(zombie)
    voiceTracker[zombie] = nil
end

local function initializeCivilianTweaks()
    CivilianBehavior._roleRevision = (CivilianBehavior._roleRevision or 0) + 1
    ensureCivilianSystems()
end

Events.OnGameStart.Add(initializeCivilianTweaks)
Events.OnLoad.Add(initializeCivilianTweaks)
if Events.OnSandboxOptionsChanged then
    Events.OnSandboxOptionsChanged.Add(initializeCivilianTweaks)
end
Events.OnZombieUpdate.Add(onZombieUpdate)
Events.OnZombieDead.Add(onZombieDead)

function CivilianBehavior.ensureCowardState(zombie, brain)
    return applyRole(zombie, brain, CivilianBehavior.ROLE_COWARD)
end

function CivilianBehavior.convertFollowerToCivilian(zombie, brain)
    local role = rollCivilianRole(brain)
    return applyRole(zombie, brain, role)
end

BanditTweaks.Civilians = CivilianBehavior
return CivilianBehavior
