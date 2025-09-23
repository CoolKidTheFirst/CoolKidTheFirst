if isServer() then return end

local DoorDiscipline = {}
local doorMemory = {}

local function getWorldHours()
    local gameTime = getGameTime()
    if not gameTime then
        return 0
    end
    return gameTime:getWorldAgeHours() or 0
end

local function isDoorObject(object)
    return object and (instanceof(object, "IsoDoor") or (instanceof(object, "IsoThumpable") and object:isDoor() == true))
end

local function isDoorOpen(door)
    if not door then
        return false
    end
    if door.IsOpen then
        return door:IsOpen()
    elseif door.isOpen then
        return door:isOpen()
    end
    return false
end

local function getDoorSquares(door)
    if not door then
        return nil, nil
    end
    local square = door:getSquare()
    local opposite
    if door.getOppositeSquare then
        opposite = door:getOppositeSquare()
    end
    return square, opposite
end

local function getSquareBuilding(square)
    if not square then
        return nil
    end
    local room = square:getRoom()
    if room and room:getBuilding() then
        return room:getBuilding()
    end
    return nil
end

local function doorLeadsOutside(door, building)
    if not door or not building then
        return false
    end
    local square, opposite = getDoorSquares(door)
    local squareBuilding = getSquareBuilding(square)
    local oppositeBuilding = getSquareBuilding(opposite)
    if squareBuilding == building and oppositeBuilding ~= building then
        return true
    end
    if oppositeBuilding == building and squareBuilding ~= building then
        return true
    end
    return false
end

local function closeDoor(zombie, door)
    if not door or not isDoorOpen(door) then
        return false
    end

    if instanceof(door, "IsoDoor") then
        local doubleIndex = IsoDoor.getDoubleDoorIndex(door)
        if doubleIndex and doubleIndex > -1 then
            IsoDoor.toggleDoubleDoor(door, false)
        else
            door:ToggleDoor(zombie)
        end
    else
        door:ToggleDoor(zombie)
    end

    return true
end

local function getOrCreateMemory(zombie)
    local info = doorMemory[zombie]
    if not info then
        info = {}
        doorMemory[zombie] = info
    end
    return info
end

local function collectDoorsFromSquare(square, result)
    if not square then
        return
    end
    local objects = square:getSpecialObjects()
    if objects then
        for i = 0, objects:size() - 1 do
            local object = objects:get(i)
            if isDoorObject(object) then
                table.insert(result, object)
            end
        end
    end
    local all = square:getObjects()
    if all then
        for i = 0, all:size() - 1 do
            local object = all:get(i)
            if isDoorObject(object) then
                table.insert(result, object)
            end
        end
    end
end

local function getDoorBetweenSquares(prevSquare, currentSquare)
    if not prevSquare or not currentSquare then
        return nil
    end
    local candidates = {}
    collectDoorsFromSquare(prevSquare, candidates)
    for _, door in ipairs(candidates) do
        local _, opposite = getDoorSquares(door)
        if opposite == currentSquare then
            return door
        end
    end
    candidates = {}
    collectDoorsFromSquare(currentSquare, candidates)
    for _, door in ipairs(candidates) do
        local _, opposite = getDoorSquares(door)
        if opposite == prevSquare then
            return door
        end
    end
    return nil
end

local function findNearbyExteriorDoor(square, building)
    if not square or not building then
        return nil
    end
    local z = square:getZ()
    local cell = getCell()
    local candidates = {}
    collectDoorsFromSquare(square, candidates)
    local x = square:getX()
    local y = square:getY()
    local offsets = {{1,0}, {-1,0}, {0,1}, {0,-1}}
    for _, offset in ipairs(offsets) do
        local neighbor = cell and cell:getGridSquare(x + offset[1], y + offset[2], z)
        collectDoorsFromSquare(neighbor, candidates)
    end

    for _, door in ipairs(candidates) do
        if doorLeadsOutside(door, building) then
            return door
        end
    end

    return nil
end

local function isInHurry(zombie, brain)
    if zombie.isSprinting and zombie:isSprinting() then
        return true
    end
    if zombie.isRunning and zombie:isRunning() then
        return true
    end
    if zombie.getTarget and zombie:getTarget() then
        return true
    end
    if brain then
        if brain.target or brain.targetBandit or brain.targetZombie then
            return true
        end
    end
    return false
end

local function getCooldownHours()
    local defaults = BanditTweaks and BanditTweaks.Defaults
    local config = BanditTweaks and BanditTweaks.Config
    local value = config and config.doorCloseCooldownHours
    if value == nil and defaults then
        value = defaults.doorCloseCooldownHours
    end
    value = value or 0.02
    if value < 0.01 then
        value = 0.01
    end
    return value
end

local function onZombieUpdate(zombie)
    if not (BanditTweaks and BanditTweaks.Config and BanditTweaks.Config.doorDisciplineEnabled) then
        return
    end

    if not zombie or not zombie:getVariableBoolean("Bandit") then
        doorMemory[zombie] = nil
        return
    end

    local square = zombie:getSquare()
    if not square then
        return
    end

    local brain = BanditBrain and BanditBrain.Get and BanditBrain.Get(zombie)
    local info = getOrCreateMemory(zombie)
    local now = getWorldHours()
    local building = getSquareBuilding(square)
    local lastSquare = info.lastSquare
    local lastBuilding = info.lastBuilding
    local closedDoor = false

    if building and lastSquare and lastBuilding ~= building then
        local entryDoor = getDoorBetweenSquares(lastSquare, square)
        if entryDoor and isDoorOpen(entryDoor) and not isInHurry(zombie, brain) then
            closedDoor = closeDoor(zombie, entryDoor) or closedDoor
        end
    end

    if building and not closedDoor then
        if not isInHurry(zombie, brain) then
            if not info.nextSweep or now >= info.nextSweep then
                local door = findNearbyExteriorDoor(square, building)
                if door and isDoorOpen(door) then
                    closedDoor = closeDoor(zombie, door) or closedDoor
                    info.nextSweep = now + getCooldownHours()
                else
                    info.nextSweep = now + 0.05
                end
            end
        end
    end

    if closedDoor then
        info.lastCloseTime = now
    end

    info.lastSquare = square
    info.lastBuilding = building
end
Events.OnZombieUpdate.Add(onZombieUpdate)

local function onZombieDead(zombie)
    doorMemory[zombie] = nil
end
Events.OnZombieDead.Add(onZombieDead)

DoorDiscipline.isInHurry = isInHurry
DoorDiscipline.closeDoor = closeDoor
DoorDiscipline.getDoorBetweenSquares = getDoorBetweenSquares

BanditTweaks.DoorDiscipline = DoorDiscipline
return DoorDiscipline
