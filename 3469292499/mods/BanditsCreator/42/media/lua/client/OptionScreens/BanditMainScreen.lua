
local function onEnterCreator(item, x, y)
    if item.internal == "CREATOR" then
        local mainScreen = MainScreen.instance

        -- hide menu options
        mainScreen.bottomPanel:setVisible(false)

        -- show the creator

        local screenWidth, screenHeight = getCore():getScreenWidth(), getCore():getScreenHeight()
        local margin = screenWidth > 1900 and 100 or 0
        local modalWidth, modalHeight = screenWidth - margin, screenHeight - margin
        local modalX = (screenWidth / 2) - (modalWidth / 2)
        local modalY = (screenHeight / 2) - (modalHeight / 2)

        mainScreen.creatorModal = BanditClansMain:new(modalX, modalY, modalWidth, modalHeight)
        mainScreen.creatorModal:initialise()
        mainScreen.creatorModal:addToUIManager()
        mainScreen.creatorModal:setAlwaysOnTop(true)
        mainScreen.creatorModal:bringToTop()
        mainScreen.creatorModal:setVisible(true)

        -- play click sound
        getSoundManager():playUISound("UIActivateMainMenuItem")
    end
end

--[[
local function onKeyPressed(key)
    if key ~= Keyboard.KEY_F then return end
    onMainMenuEnter()
end
]]

local function getModel(bid)

    local desc = SurvivorFactory.CreateSurvivor(SurvivorType.Neutral, false)
    local px, py, pz = 0, 0, 0
    local model = IsoPlayer.new(getCell(), desc, px, py, pz)
    -- model:setSceneCulled(false)
    model:setVariable("BanditAvatar", true)
    model:setIsAiming(true)
    model:setNPC(true)
    model:setGodMod(true)
    model:setInvisible(true)
    model:setGhostMode(true)
    model:setFemale(false)
    model:getHumanVisual():setSkinTextureIndex(0)
    model:getHumanVisual():setHairModel(Bandit.GetHairStyle(false, 1))
    model:getHumanVisual():setBeardModel(Bandit.GetBeardStyle(false, 1))

    local data = BanditCustom.Get(bid)
    if data.general then
        if data.general.female then
            model:setFemale(true)
        else
            model:setFemale(false)
        end

        model:getHumanVisual():setSkinTextureIndex(data.general.skin - 1)
        model:getHumanVisual():setHairModel(Bandit.GetHairStyle(data.general.female, data.general.hairType))

        if not data.general.female then
            model:getHumanVisual():setBeardModel(Bandit.GetBeardStyle(data.general.female, data.general.beardType))
        end

        local color = Bandit.GetHairColor(data.general.hairColor)
        local immutableColor = ImmutableColor.new(color.r, color.g, color.b, 1)
        model:getHumanVisual():setHairColor(immutableColor)
        model:getHumanVisual():setBeardColor(immutableColor)
        model:getHumanVisual():setNaturalHairColor(immutableColor)
        model:getHumanVisual():setNaturalBeardColor(immutableColor)
    end

    if data.clothing then
        for bodyLocation, itemType in pairs(data.clothing) do
            model:setWornItem(bodyLocation, nil)
            local item = BanditCompatibility.InstanceItem(itemType)
            if item then
                if data.tint and data.tint[bodyLocation] then
                    local visual = item:getVisual()
                    if visual then
                        local cint = data.tint[bodyLocation]
                        local color = BanditUtils.dec2rgb(cint)
                        local immutableColor = ImmutableColor.new(color.r, color.g, color.b, 1)
                        visual:setTint(immutableColor)
                    end
                end
                model:setWornItem(bodyLocation, item)
            end
        end
    end

    if data.weapons then
        if data.weapons.primary then
            local item = BanditCompatibility.InstanceItem(data.weapons.primary)
            if item then
                model:setAttachedItem("Rifle On Back", item)
            end
        else
            model:setAttachedItem("Rifle On Back", nil)
        end

        if data.weapons.secondary then
            local item = BanditCompatibility.InstanceItem(data.weapons.secondary)
            if item then
                model:setAttachedItem("Holster Right", item)
            end
        else
            model:setAttachedItem("Holster Right", nil)
        end
    end

    if data.bag then
        local item = BanditCompatibility.InstanceItem(data.bag.name)
        if item then
            local visual = item:getVisual()
            if visual then
                local immutableColor = ImmutableColor.new(0.1, 0.1, 0.1, 1)
                visual:setTint(immutableColor)
            end
            model:setWornItem(item:canBeEquipped(), item)
        end
    end
    return model
end

local READY = false
local TICK = 0
local function OnFETick()
    local mainScreen = MainScreen.instance
    if mainScreen.inGame and isClient() then return end

    TICK = TICK + 1

    if TICK == 10 then
        -- local sm = getSoundManager()
        -- sm:playUISound("BCMusicMenu")
    end

    if TICK == 300 then
        local screenWidth, screenHeight = getCore():getScreenWidth(), getCore():getScreenHeight()
        local avatarWidth = 360
        local avatarHeight = 720
        mainScreen.model = getModel("f7d0e294-2da4-4d07-8e58-22fecbface66")
    
        mainScreen.avatarPanel = BanditCreationAvatar:new((screenWidth / 2) - (avatarWidth / 2), screenHeight - avatarHeight - 100, avatarWidth, avatarHeight)
        mainScreen.avatarPanel.controls = true
        mainScreen.avatarPanel.clickable = false
        mainScreen.avatarPanel.controls = false
        mainScreen.avatarPanel:noBackground()
        mainScreen:addChild(mainScreen.avatarPanel)
        mainScreen.avatarPanel:setCharacter(mainScreen.model)
        mainScreen.avatarPanel.avatarPanel:setVariable("BanditAvatar", true)
    
        local uis = {
            "scoreboard",
            "serverList",
            "multiplayer",
            "joinPublicServer",
            "connectToServer",
            "onlineCoopScreen",
            "soloScreen",
            "loadScreen",
            "sandOptions",
            "worldSelect",
            -- "mapSpawnSelect",
            "charCreationProfession",
            "charCreationMain",
            "inviteFriends",
            "modSelect",
            "lastStandPlayerSelect",
            "mainOptions",
            "workshopSubmit",
            "serverWorkshopItem",
            "serverSettingsScreen"
        }
    
        for _, v in pairs(uis) do
            if mainScreen[v] then mainScreen[v]:bringToTop() end
        end
    end
end


local function onMainMenuEnter()
    local mainScreen = MainScreen.instance
    -- mainScreen.logoTexture = getTexture("media/ui/null.png")

    if mainScreen.inGame and isClient() then return end

    BanditCustom.Load()

    local labelHgt = getTextManager():getFontHeight(UIFont.Large) + 8 * 2
    local labelX = 0
    local labelY = 0
    local labelSeparator = 16

    if mainScreen.exitOption then
        -- read position of the exit option and move it down
        local exitOptionY = mainScreen.exitOption:getY()
        mainScreen.exitOption:setY(exitOptionY + labelHgt)

        -- add creator option in place of exit option
        mainScreen.creatorOption = ISLabel:new(labelX, exitOptionY - labelSeparator, labelHgt, "BANDIT CREATOR", 1, 1, 1, 1, UIFont.Large, true)
        mainScreen.creatorOption.internal = "CREATOR"
        mainScreen.creatorOption:initialise()
        mainScreen.bottomPanel:addChild(mainScreen.creatorOption)
        mainScreen.creatorOption.onMouseDown = onEnterCreator

        mainScreen.creatorOption.fade = UITransition.new()
        mainScreen.creatorOption.fade:setFadeIn(false)
        mainScreen.creatorOption.prerender = MainScreen.prerenderBottomPanelLabel

        -- update the total panel height with the height of the new option
        local bottomPanelHgt = mainScreen.bottomPanel:getHeight()
        mainScreen.bottomPanel:setHeight(bottomPanelHgt + labelHgt)
    end
end

Events.OnMainMenuEnter.Add(onMainMenuEnter)
-- Events.OnKeyPressed.Add(onKeyPressed)
-- Events.OnFETick.Add(OnFETick)


