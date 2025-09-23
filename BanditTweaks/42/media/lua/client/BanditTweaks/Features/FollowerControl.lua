if isServer() then return end

require "ISUI/ISWorldObjectContextMenu"

local FollowerControl = {}
local dismissedFollowers = {}

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

local function dismissFollower(zombie, brain, player)
    if dismissedFollowers[zombie] then
        return
    end

    if Bandit.SetMaster then
        Bandit.SetMaster(zombie, nil)
    end
    if brain then
        brain.master = nil
        BanditBrain.Update(zombie, brain)
    end

    if BanditTweaks.Civilians and BanditTweaks.Civilians.ensureCowardState then
        BanditTweaks.Civilians.ensureCowardState(zombie, brain)
    end

    if Bandit.ClearTasks then
        Bandit.ClearTasks(zombie)
    end

    if BanditTweaks.FriendlyFire and BanditTweaks.FriendlyFire.forget then
        BanditTweaks.FriendlyFire.forget(zombie)
    end

    if BanditTweaks.Indicator and BanditTweaks.Indicator.untrackZombie then
        BanditTweaks.Indicator.untrackZombie(zombie)
    end

    removeFromServerQueue(player, brain)

    dismissedFollowers[zombie] = true
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
