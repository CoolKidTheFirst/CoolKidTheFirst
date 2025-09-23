if isServer() then return end

require "ISUI/ISWorldObjectContextMenu"

local FollowerControl = {}
local dismissedFollowers = {}

local function getWorldHours()
    local gameTime = getGameTime()
    if not gameTime then
        return 0
    end
    return gameTime:getWorldAgeHours() or 0
end

local function getLocalPlayer()
    return getSpecificPlayer(0)
end

local function getLocalPlayerId(player)
    if not player or not BanditUtils or not BanditUtils.GetCharacterID then
        return nil
    end
    return BanditUtils.GetCharacterID(player)
end

local function isFriendlyFollower(zombie, brain, playerId)
    if not playerId then
        return false
    end
    if not brain or brain.hostile or brain.hostileP then
        return false
    end
    local master = Bandit.GetMaster and Bandit.GetMaster(zombie)
    if not master then
        return false
    end
    return master == playerId
end

local function removeFromServerQueue(player, brain)
    if not (player and brain and brain.id) then
        return
    end
    sendClientCommand(player, 'Commands', 'BanditRemove', {id = brain.id})
end

local function attemptConversion(zombie, brain, info)
    if not info or info.done then
        return
    end

    local now = getWorldHours()
    if info.nextAttempt and now < info.nextAttempt then
        return
    end

    local converted = false
    if BanditTweaks.Civilians then
        local civilians = BanditTweaks.Civilians
        if civilians.convertFollowerToCivilian then
            converted = civilians.convertFollowerToCivilian(zombie, brain)
        elseif civilians.ensureCowardState then
            converted = civilians.ensureCowardState(zombie, brain)
        end
    end

    if converted then
        info.done = true
        info.nextAttempt = nil
    else
        info.nextAttempt = now + 0.05
    end
end

local function dismissFollower(zombie, brain, player)
    local now = getWorldHours()
    local info = dismissedFollowers[zombie]

    if info and info.done then
        return
    end
    if info and info.nextAttempt and now < info.nextAttempt then
        return
    end

    if not info then
        info = {}
        dismissedFollowers[zombie] = info
    end

    if Bandit.SetMaster and not info.masterCleared then
        Bandit.SetMaster(zombie, nil)
        info.masterCleared = true
    end
    if brain then
        brain.master = nil
        brain.hostile = false
        brain.hostileP = false
        if Bandit.SetHostile then
            Bandit.SetHostile(zombie, false)
        end
        if Bandit.SetHostileP then
            Bandit.SetHostileP(zombie, false)
        end
        BanditBrain.Update(zombie, brain)
    end

    attemptConversion(zombie, brain, info)

    if Bandit.ClearTasks and not info.tasksCleared then
        Bandit.ClearTasks(zombie)
        info.tasksCleared = true
    end

    if BanditTweaks.FriendlyFire and BanditTweaks.FriendlyFire.forget and not info.cleanedFriendly then
        BanditTweaks.FriendlyFire.forget(zombie)
        info.cleanedFriendly = true
    end

    if BanditTweaks.Indicator and BanditTweaks.Indicator.untrackZombie and not info.indicatorCleared then
        BanditTweaks.Indicator.untrackZombie(zombie)
        info.indicatorCleared = true
    end

    if not info.removed then
        removeFromServerQueue(player, brain)
        info.removed = true
    end
end

local function dismissFollowersInWorld()
    local player = getLocalPlayer()
    local playerId = getLocalPlayerId(player)
    if not playerId then
        return
    end

    for _, entry in pairs(BanditZombie.CacheLightB or {}) do
        local zombie = BanditZombie.Cache and BanditZombie.Cache[entry.id]
        if zombie then
            local brain = entry.brain or (BanditBrain and BanditBrain.Get(zombie))
            if isFriendlyFollower(zombie, brain, playerId) then
                dismissFollower(zombie, brain, player)
            end
        end
    end
end
FollowerControl.dismissFollowersInWorld = dismissFollowersInWorld

function BanditTweaks.ToggleStartingFollowers()
    local newState = not BanditTweaks.Config.startingFollowersEnabled
    BanditTweaks.SetStartingFollowersEnabled(newState)

    if not newState then
        dismissedFollowers = {}
        dismissFollowersInWorld()
    else
        dismissedFollowers = {}
    end

    local player = getLocalPlayer()
    if player then
        local message
        if newState then
            message = "Starting followers enabled"
        else
            message = "Starting followers disabled"
        end
        player:Say(message)
    end
end

local function addFollowerOption(playerNum, context, worldobjects, test)
    local label
    if BanditTweaks.Config.startingFollowersEnabled then
        label = "Disable Starting Followers"
    else
        label = "Enable Starting Followers"
    end

    local option = context:addOption("[Bandit Tweaks] " .. label, worldobjects, BanditTweaks.ToggleStartingFollowers)
    if option then
        local toolTip = ISWorldObjectContextMenu.addToolTip()
        toolTip.description = "Removes friendly followers that spawn with you so they do not trail the player."
        toolTip:setName("Starting Followers")
        option.toolTip = toolTip
    end
end
Events.OnFillWorldObjectContextMenu.Add(addFollowerOption)

local function onGameStartOrLoad()
    if BanditTweaks.Config.startingFollowersEnabled then
        dismissedFollowers = {}
        return
    end

    dismissedFollowers = {}
    dismissFollowersInWorld()
end
Events.OnGameStart.Add(onGameStartOrLoad)
Events.OnLoad.Add(onGameStartOrLoad)

local function onZombieUpdate(zombie)
    if BanditTweaks.Config.startingFollowersEnabled then
        return
    end

    if not zombie or not zombie:getVariableBoolean("Bandit") then
        return
    end

    local brain = BanditBrain and BanditBrain.Get(zombie)
    if not brain then
        return
    end

    local info = dismissedFollowers[zombie]
    if info and not info.done then
        attemptConversion(zombie, brain, info)
    end

    local player = getLocalPlayer()
    local playerId = getLocalPlayerId(player)
    if not playerId then
        return
    end

    if isFriendlyFollower(zombie, brain, playerId) then
        dismissFollower(zombie, brain, player)
    end
end
Events.OnZombieUpdate.Add(onZombieUpdate)

local function onZombieDead(zombie)
    dismissedFollowers[zombie] = nil
end
Events.OnZombieDead.Add(onZombieDead)

BanditTweaks.FollowerControl = FollowerControl
return FollowerControl
