if isServer() then return end

require "ISUI/ISWorldObjectContextMenu"

local FriendlyFire = {}
local trackedFriendlyHealth = {}

local function shouldTrackFriendly()
    return not BanditTweaks.Config.friendlyFireEnabled
end

local function clearFriendlyHealth()
    for zombie in pairs(trackedFriendlyHealth) do
        trackedFriendlyHealth[zombie] = nil
    end
end
FriendlyFire.clearFriendlyHealth = clearFriendlyHealth

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

local function onZombieUpdate(zombie)
    if not zombie then
        return
    end

    if not zombie:getVariableBoolean("Bandit") then
        trackedFriendlyHealth[zombie] = nil
        return
    end

    local brain = BanditBrain and BanditBrain.Get(zombie)
    if not brain or brain.hostile or brain.hostileP then
        trackedFriendlyHealth[zombie] = nil
        return
    end

    if shouldTrackFriendly() then
        trackedFriendlyHealth[zombie] = zombie:getHealth()
    else
        trackedFriendlyHealth[zombie] = nil
    end
end
Events.OnZombieUpdate.Add(onZombieUpdate)

local function onZombieDead(zombie)
    trackedFriendlyHealth[zombie] = nil
end
Events.OnZombieDead.Add(onZombieDead)

local function restoreFriendlyState(zombie)
    local previous = trackedFriendlyHealth[zombie]
    if previous then
        zombie:setHealth(previous)
        trackedFriendlyHealth[zombie] = previous
    end

    local bodyDamage = zombie:getBodyDamage()
    if bodyDamage and bodyDamage.RestoreToFullHealth then
        bodyDamage:RestoreToFullHealth()
    end

    zombie:setHitReaction("")
    zombie:setTarget(nil)
    zombie:setTargetSeenTime(0)
    zombie:setAttackedBy(nil)
    zombie:setBumpType(nil)

    if Bandit.SetHostile then
        Bandit.SetHostile(zombie, false)
    end
    if Bandit.SetHostileP then
        Bandit.SetHostileP(zombie, false)
    end
end

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

    restoreFriendlyState(zombie)
end
Events.OnHitZombie.Add(onHitZombie)

local function patchFriendlyFireCheck()
    if FriendlyFire._patchedFriendlyFireCheck then
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
        FriendlyFire._patchedFriendlyFireCheck = true
        Events.OnTick.Remove(patchFriendlyFireCheck)
    end
end
Events.OnTick.Add(patchFriendlyFireCheck)

function FriendlyFire.forget(zombie)
    trackedFriendlyHealth[zombie] = nil
end

BanditTweaks.FriendlyFire = FriendlyFire
return FriendlyFire
