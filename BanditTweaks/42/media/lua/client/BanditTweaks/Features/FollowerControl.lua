if isServer() then return end

require "ISUI/ISWorldObjectContextMenu"

local FollowerControl = {}

local function getLocalPlayer()
    return getSpecificPlayer(0)
end

local function announceState(enabled)
    local player = getLocalPlayer()
    if not player then
        return
    end

    local message
    if enabled then
        message = "Starting followers enabled"
    else
        message = "Day One starting followers disabled for new games"
    end
    player:Say(message)
end

function BanditTweaks.ToggleStartingFollowers()
    local newState = not BanditTweaks.Config.startingFollowersEnabled
    BanditTweaks.SetStartingFollowersEnabled(newState)
    announceState(newState)
end

local function addFollowerOption(playerNum, context, worldobjects, test)
    if test then
        return
    end

    local label
    if BanditTweaks.Config.startingFollowersEnabled then
        label = "Disable Starting Followers"
    else
        label = "Enable Starting Followers"
    end

    local option = context:addOption("[Bandit Tweaks] " .. label, worldobjects, BanditTweaks.ToggleStartingFollowers)
    if option then
        local toolTip = ISWorldObjectContextMenu.addToolTip()
        toolTip.description = "When disabled, Bandits Day One will no longer assign friendly followers at the start of new games."
        toolTip:setName("Starting Followers")
        option.toolTip = toolTip
    end
end
Events.OnFillWorldObjectContextMenu.Add(addFollowerOption)

BanditTweaks.FollowerControl = FollowerControl
return FollowerControl
