BanditTweaks = BanditTweaks or {}
BanditTweaks.FollowerOverrides = BanditTweaks.FollowerOverrides or {}

local overrideState = BanditTweaks.FollowerOverrides

local function isDayOneActive()
    if not BanditTweaks or not BanditTweaks.IsModActive then
        return false
    end
    return BanditTweaks.IsModActive("BanditsDayOne")
end

local function startingFollowersEnabled()
    if not BanditTweaks or not BanditTweaks.Config then
        return true
    end
    local enabled = BanditTweaks.Config.startingFollowersEnabled
    if enabled == nil then
        return true
    end
    return enabled and true or false
end

local function ensureDayOneOverride()
    if not isDayOneActive() then
        return
    end

    local phases = rawget(_G, "DOPhases")
    if not phases or type(phases.SpawnFamilly) ~= "function" then
        return
    end

    if phases.SpawnFamilly ~= overrideState.overrideFn then
        overrideState.originalFn = phases.SpawnFamilly
        if not overrideState.overrideFn then
            overrideState.overrideFn = function(player, ...)
                if startingFollowersEnabled() and overrideState.originalFn then
                    return overrideState.originalFn(player, ...)
                end
            end
        end
        phases.SpawnFamilly = overrideState.overrideFn
    end
end

local function maintainDayOneOverride()
    ensureDayOneOverride()
end

ensureDayOneOverride()

if Events then
    if Events.OnTick then
        Events.OnTick.Add(maintainDayOneOverride)
    end
    if Events.OnGameStart then
        Events.OnGameStart.Add(ensureDayOneOverride)
    end
    if Events.OnServerStarted then
        Events.OnServerStarted.Add(ensureDayOneOverride)
    end
    if Events.OnLoad then
        Events.OnLoad.Add(ensureDayOneOverride)
    end
    if Events.OnSandboxOptionsChanged then
        Events.OnSandboxOptionsChanged.Add(ensureDayOneOverride)
    end
end
