BanditCreationMain = ISPanel:derive("BanditCreationMain")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local UI_BORDER_SPACING = 10
local BUTTON_HGT = FONT_HGT_SMALL + 6

function BanditCreationMain:initialise()
    ISPanel.initialise(self)

    local btnCancelWidth = 100 -- getTextManager():MeasureStringX(UIFont.Small, "Cancel") + 64
    local btnSaveWidth = 100 -- getTextManager():MeasureStringX(UIFont.Small, "Save") + 64
    local btnCloneWidth = 100 -- getTextManager():MeasureStringX(UIFont.Small, "Clone") + 64
    local btnCancelX = math.floor(self:getWidth() / 2) - ((btnCancelWidth + btnSaveWidth) / 2) - UI_BORDER_SPACING
    local btnCancelY = math.floor(self:getWidth() / 2) - ((btnCancelWidth + btnSaveWidth) / 2) + btnCancelWidth + UI_BORDER_SPACING

    local leftX = (self.width / 2) - 500
    
    self.backgroundTexture = getTexture("media/ui/creatorbg2.png")

    self.cancel = ISButton:new(btnCancelX, self:getHeight() - UI_BORDER_SPACING - BUTTON_HGT - UI_BORDER_SPACING, btnCancelWidth, BUTTON_HGT, getText("UI_BanditsCreator_Cancel"), self, BanditCreationMain.onClick)
    self.cancel.internal = "CANCEL"
    self.cancel.anchorTop = false
    self.cancel.anchorBottom = true
    self.cancel:initialise()
    self.cancel:instantiate()
    if BanditCompatibility.GetGameVersion() >= 42 then
        self.cancel:enableCancelColor()
    end
    self:addChild(self.cancel)

    self.save = ISButton:new(btnCancelY, self:getHeight() - UI_BORDER_SPACING - BUTTON_HGT - UI_BORDER_SPACING, btnSaveWidth, BUTTON_HGT, getText("UI_BanditsCreator_Save"), self, BanditCreationMain.onClick)
    self.save.internal = "SAVE"
    self.save.anchorTop = false
    self.save.anchorBottom = true
    self.save:initialise()
    self.save:instantiate()
    if BanditCompatibility.GetGameVersion() >= 42 then
        self.save:enableAcceptColor()
    end
    self:addChild(self.save)

    local topY = 60
    local iconSize = 40
    local avatarHeight = self.height - 260
    local avatarWidth = avatarHeight / 2
    
    self.avatarPanel = BanditCreationAvatar:new((self.width / 2) - (360 / 2), topY, avatarWidth, avatarHeight)
    self.avatarPanel.controls = true
    self.avatarPanel.clickable = false
    self.avatarPanel:noBackground()
    self:addChild(self.avatarPanel)

    self.clone = ISButton:new((self.width / 2)  - (btnCloneWidth / 2), topY + avatarHeight + UI_BORDER_SPACING + 4, btnCloneWidth, BUTTON_HGT, getText("UI_BanditsCreator_Clone"), self, BanditCreationMain.onClick)
    self.clone.internal = "CLONE"
    self.clone.anchorTop = false
    self.clone.anchorBottom = true
    self.clone:initialise()
    self.clone:instantiate()
    self:addChild(self.clone)

    local player = getSpecificPlayer(0)
    local px, py, pz = 0, 0, 0
    if player then
        px, py, pz = player:getX(), player:getY(), player:getZ()
    end

    self.desc = SurvivorFactory.CreateSurvivor(SurvivorType.Neutral, false)
    self.model = IsoPlayer.new(getCell(), self.desc, px, py, pz)
    -- self.model:setSceneCulled(false)
    self.model:setIsAiming(true)
    self.model:setNPC(true)
    self.model:setGodMod(true)
    self.model:setInvisible(true)
    self.model:setGhostMode(true)
    self.model:setFemale(false)
    self.model:getHumanVisual():setSkinTextureIndex(0)
    self.model:getHumanVisual():setHairModel(Bandit.GetHairStyle(false, 1))
    self.model:getHumanVisual():setBeardModel(Bandit.GetBeardStyle(false, 1))
    -- self.model:getHumanVisual():randomDirt()

    -- self.avatarPanel:setSurvivorDesc(self.desc)

    self.avatarPanel:setCharacter(self.model)

    
    local lbl
    local rowY = 0

    -- REQUIREMENTS

    self.requirements = {}

    -- MODID

    local mods = BanditCustom.GetMods()

    lbl = ISLabel:new(leftX - UI_BORDER_SPACING, topY + rowY, BUTTON_HGT, getText("UI_BanditsCreator_Save_To"), 1, 1, 1, 1, UIFont.Small, false)
    lbl:initialise()
    lbl:instantiate()
    self:addChild(lbl)

    local tooltip = getText("UI_BanditsCreator_Save_To_Tooltip")
    local tooltipMap = {}
    self.modCombo = ISComboBox:new(leftX, topY + rowY, 240, BUTTON_HGT, self, nil)
    self.modCombo:initialise()
    self.modCombo:addOption("LOCAL")
    tooltipMap["LOCAL"] = tooltip

    for i=1, #mods do
        self.modCombo:addOption(mods[i])
        tooltipMap[mods[i]] = tooltip
    end

    self.modCombo:setToolTipMap(tooltipMap)

    self.modCombo.borderColor = {r=0.4, g=0.4, b=0.4, a=1};
    self:addChild(self.modCombo)
    rowY = rowY + BUTTON_HGT + 18


    -- APPEARANCE
    lbl = ISLabel:new(leftX - UI_BORDER_SPACING, topY + rowY, BUTTON_HGT, getText("UI_BanditsCreator_Appearance"), 1, 1, 1, 1, UIFont.Medium, false)
    lbl:initialise()
    lbl:instantiate()
    self:addChild(lbl)
    rowY = rowY + BUTTON_HGT + 8

    -- NAME
    lbl = ISLabel:new(leftX - UI_BORDER_SPACING, topY + rowY, BUTTON_HGT, getText("UI_BanditsCreator_Name"), 1, 1, 1, 1, UIFont.Small, false)
    lbl:initialise()
    lbl:instantiate()
    self:addChild(lbl)

    self.nameEntry = ISTextEntryBox:new("", leftX, topY + rowY, 240, BUTTON_HGT)
    self.nameEntry:initialise()
    self.nameEntry:instantiate()
    self:addChild(self.nameEntry)
    rowY = rowY + BUTTON_HGT + 8

    -- GENDER

    lbl = ISLabel:new(leftX - UI_BORDER_SPACING, topY + rowY, BUTTON_HGT, getText("UI_BanditsCreator_Gender_And_Skin"), 1, 1, 1, 1, UIFont.Small, false)
    lbl:initialise()
    lbl:instantiate()
    self:addChild(lbl)

    self.genderCombo = ISComboBox:new(leftX, topY + rowY, 240 - BUTTON_HGT - UI_BORDER_SPACING, BUTTON_HGT, self, BanditCreationMain.onGenderSelected)
    self.genderCombo:initialise();
    self.genderCombo:addOption(getText("IGUI_char_Female"))
    self.genderCombo:addOption(getText("IGUI_char_Male"))
    self.genderCombo.borderColor = {r=0.4, g=0.4, b=0.4, a=1};
    self:addChild(self.genderCombo)

    -- SKIN
    self.skinColors = { {r=1,g=0.91,b=0.72},
        {r=0.98,g=0.79,b=0.49},
        {r=0.8,g=0.65,b=0.45},
        {r=0.54,g=0.38,b=0.25},
        {r=0.36,g=0.25,b=0.14} }

    local skinColorBtn = ISButton:new(leftX + 240 - BUTTON_HGT, topY + rowY, BUTTON_HGT, BUTTON_HGT, "", self, BanditCreationMain.onSkinColorSelected)
    skinColorBtn:initialise()
    skinColorBtn:instantiate()
    local color = self.skinColors[1]
    skinColorBtn.backgroundColor = {r = color.r, g = color.g, b = color.b, a = 1}
    self:addChild(skinColorBtn)
    self.skinColorButton = skinColorBtn

    self.colorPickerSkin = ISColorPicker:new(0, 0, nil)
    self.colorPickerSkin:initialise()
    self.colorPickerSkin.keepOnScreen = true
    self.colorPickerSkin.pickedTarget = self
    self.colorPickerSkin.resetFocusTo = self
    self.colorPickerSkin:setColors(self.skinColors, #self.skinColors, 1)
    rowY = rowY + BUTTON_HGT + 8

    -- CHEST HAIR

    -- todo

    -- HAIR STYLE

    lbl = ISLabel:new(leftX - UI_BORDER_SPACING, topY + rowY, BUTTON_HGT, getText("UI_BanditsCreator_Hair"), 1, 1, 1, 1, UIFont.Small)
    lbl:initialise()
    lbl:instantiate()
    self:addChild(lbl)

    self.hairTypeCombo = ISComboBox:new(leftX, topY + rowY, 240 - BUTTON_HGT - UI_BORDER_SPACING, BUTTON_HGT, self, BanditCreationMain.onHairTypeSelected)
    self.hairTypeCombo:initialise();
    self:addChild(self.hairTypeCombo)

    -- HAIR/BEARD COLOR

    local hairColors = self.desc:getCommonHairColor();
    self.hairColors = {}
    local info = ColorInfo.new()
    for i=1, hairColors:size() do
        local color = hairColors:get(i-1)
        info:set(color:getRedFloat(), color:getGreenFloat(), color:getBlueFloat(), 1)
        table.insert(self.hairColors, { r=info:getR(), g=info:getG(), b=info:getB() })
    end

    local hairColorBtn = ISButton:new(leftX + 240 - BUTTON_HGT, topY + rowY, BUTTON_HGT, BUTTON_HGT, "", self, BanditCreationMain.onHairColorMouseDown)
    hairColorBtn:initialise()
    hairColorBtn:instantiate()
    local color = self.hairColors[1]
    hairColorBtn.backgroundColor = {r=color.r, g=color.g, b=color.b, a=1}
    self:addChild(hairColorBtn)
    self.hairColorButton = hairColorBtn

    self.colorPickerHair = ISColorPicker:new(0, 0, nil)
    self.colorPickerHair:initialise()
    self.colorPickerHair.keepOnScreen = true
    self.colorPickerHair.pickedTarget = self
    self.colorPickerHair.resetFocusTo = self
    self.colorPickerHair:setColors(self.hairColors, math.min(#self.hairColors, 10), math.ceil(#self.hairColors / 10))
    rowY = rowY + BUTTON_HGT + 8

    -- BEARD STYLE

    lbl = ISLabel:new(leftX - UI_BORDER_SPACING, topY + rowY, BUTTON_HGT, getText("UI_BanditsCreator_Beard"), 1, 1, 1, 1, UIFont.Small)
    lbl:initialise()
    lbl:instantiate()
    self:addChild(lbl)

    self.beardTypeCombo = ISComboBox:new(leftX, topY + rowY, 240 - BUTTON_HGT - UI_BORDER_SPACING, BUTTON_HGT, self, BanditCreationMain.onBeardTypeSelected)
    self.beardTypeCombo:initialise()
    self:addChild(self.beardTypeCombo)
    rowY = rowY + BUTTON_HGT + 8

    lbl = ISLabel:new(leftX - UI_BORDER_SPACING, topY + rowY, BUTTON_HGT, getText("UI_BanditsCreator_Makeup"), 1, 1, 1, 1, UIFont.Small)
    lbl:initialise()
    lbl:instantiate()
    self:addChild(lbl)
    self.MakeupFaceCombo = ISComboBox:new(leftX, topY + rowY, 113, BUTTON_HGT, self, BanditCreationMain.onClothingChanged)
    self.MakeupFaceCombo:initialise()
    self.MakeupFaceCombo.internal = "MakeUp_FullFace"
    self:addChild(self.MakeupFaceCombo)

    self.MakeupEyesCombo = ISComboBox:new(leftX + 126, topY + rowY, 113, BUTTON_HGT, self, BanditCreationMain.onClothingChanged)
    self.MakeupEyesCombo:initialise()
    self.MakeupEyesCombo.internal = "MakeUp_Eyes"
    self:addChild(self.MakeupEyesCombo)
    rowY = rowY + BUTTON_HGT + 8

    self.MakeupEyeShadowCombo = ISComboBox:new(leftX, topY + rowY, 113, BUTTON_HGT, self, BanditCreationMain.onClothingChanged)
    self.MakeupEyeShadowCombo:initialise()
    self.MakeupEyeShadowCombo.internal = "MakeUp_EyesShadow"
    self:addChild(self.MakeupEyeShadowCombo)

    self.MakeupLipsCombo = ISComboBox:new(leftX + 126, topY + rowY, 113, BUTTON_HGT, self, BanditCreationMain.onClothingChanged)
    self.MakeupLipsCombo:initialise()
    self.MakeupLipsCombo.internal = "MakeUp_Lips"
    self:addChild(self.MakeupLipsCombo)

    rowY = rowY + BUTTON_HGT + 18

    self:updateHairCombo()

    -- WEAPONS & AMMO

    lbl = ISLabel:new(leftX - UI_BORDER_SPACING, topY + rowY, BUTTON_HGT, getText("UI_BanditsCreator_Carriables"), 1, 1, 1, 1, UIFont.Medium, false)
    lbl:initialise()
    lbl:instantiate()
    self:addChild(lbl)
    rowY = rowY + BUTTON_HGT + 8

    self.weapons = {}

    lbl = ISLabel:new(leftX - UI_BORDER_SPACING, topY + rowY, iconSize, getText("UI_BanditsCreator_Primary_Gun"), 1, 1, 1, 1, UIFont.Small)
    lbl:initialise()
    lbl:instantiate()
    self:addChild(lbl)

    self.weapons.primary = BanditItemDropBox:new(leftX, topY + rowY, iconSize, iconSize, true, self, BanditCreationMain.addItem, BanditCreationMain.removeItem, BanditCreationMain.verifyItem, nil)
    self.weapons.primary:initialise()
    self.weapons.primary:setToolTip(true, getText("UI_BanditsCreator_Primary_Gun_Tooltip"))
    self.weapons.primary.internal = "primary"
    self.weapons.primary.mode = "carriable"
    self:addChild(self.weapons.primary)

    self.ammo = {}

    self.ammo.primary = BanditButtonCounter:new(leftX + iconSize + 20, topY + rowY, iconSize, iconSize, "1", self, self.onClick, self.onRightClick)
    self.ammo.primary.internal = "AMMO"
    self.ammo.primary.slot = "primary"
    self.ammo.primary.value = 1
    self.ammo.primary.sounds.add = "MagazineInsertAmmo"
    self.ammo.primary.sounds.substract = "MagazineEjectAmmo"
    self.ammo.primary.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    self.ammo.primary:initialise()
    self.ammo.primary:instantiate()
    self.ammo.primary:setVisible(false)
    self.ammo.primary:setTooltip(getText("UI_BanditsCreator_Primary_Ammo_Tooltip"))
    self:addChild(self.ammo.primary)
    rowY = rowY + iconSize + 4

    lbl = ISLabel:new(leftX - UI_BORDER_SPACING, topY + rowY, iconSize, getText("UI_BanditsCreator_Secondary_Gun"), 1, 1, 1, 1, UIFont.Small)
    lbl:initialise()
    lbl:instantiate()
    self:addChild(lbl)

    self.weapons.secondary = BanditItemDropBox:new(leftX, topY + rowY, iconSize, iconSize, true, self, BanditCreationMain.addItem, BanditCreationMain.removeItem, BanditCreationMain.verifyItem, nil)
    self.weapons.secondary:initialise()
    self.weapons.secondary:setToolTip(true, getText("UI_BanditsCreator_Secondary_Gun_Tooltip"))
    self.weapons.secondary.internal = "secondary"
    self.weapons.secondary.mode = "carriable"
    self:addChild(self.weapons.secondary)

    self.ammo.secondary = BanditButtonCounter:new(leftX + iconSize + 20, topY + rowY, iconSize, iconSize, "1", self, self.onClick, self.onRightClick)
    self.ammo.secondary.internal = "AMMO"
    self.ammo.secondary.slot = "secondary"
    self.ammo.secondary.value = 1
    self.ammo.secondary.sounds.add = "MagazineInsertAmmo"
    self.ammo.secondary.sounds.substract = "MagazineEjectAmmo"
    self.ammo.secondary.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    self.ammo.secondary:initialise()
    self.ammo.secondary:instantiate()
    self.ammo.secondary:setVisible(false)
    self.ammo.secondary:setTooltip(getText("UI_BanditsCreator_Secondary_Ammo_Tooltip"))
    self:addChild(self.ammo.secondary)
    rowY = rowY + iconSize + 4

    lbl = ISLabel:new(leftX - UI_BORDER_SPACING, topY + rowY, iconSize, getText("UI_BanditsCreator_Melee"), 1, 1, 1, 1, UIFont.Small)
    lbl:initialise()
    lbl:instantiate()
    self:addChild(lbl)

    self.weapons.melee = BanditItemDropBox:new(leftX, topY + rowY, iconSize, iconSize, true, self, BanditCreationMain.addItem, BanditCreationMain.removeItem, BanditCreationMain.verifyItem, nil)
    self.weapons.melee:initialise()
    self.weapons.melee:setToolTip(true, getText("UI_BanditsCreator_Melee_Tooltip"))
    self.weapons.melee.internal = "melee"
    self.weapons.melee.mode = "carriable"
    self:addChild(self.weapons.melee)
    rowY = rowY + iconSize + 4

    lbl = ISLabel:new(leftX - UI_BORDER_SPACING, topY + rowY, iconSize, getText("UI_BanditsCreator_Bag"), 1, 1, 1, 1, UIFont.Small)
    lbl:initialise()
    lbl:instantiate()
    self:addChild(lbl)

    self.bag = BanditItemDropBox:new(leftX, topY + rowY, iconSize, iconSize, true, self, BanditCreationMain.addItem, BanditCreationMain.removeItem, BanditCreationMain.verifyItem, nil)
    self.bag:initialise()
    self.bag:setToolTip(true, getText("UI_BanditsCreator_Bag_Tooltip"))
    self.bag.internal = "bag"
    self.bag.mode = "carriable"
    self:addChild(self.bag)
    rowY = rowY + iconSize + 18

    -- CHARACTER

    lbl = ISLabel:new(leftX - UI_BORDER_SPACING, topY + rowY, BUTTON_HGT, getText("UI_BanditsCreator_Properties"), 1, 1, 1, 1, UIFont.Medium, false)
    lbl:initialise()
    lbl:instantiate()
    self:addChild(lbl)
    rowY = rowY + BUTTON_HGT + 8

    -- EXPERTISE

    self.expertise = {}

    for i=1, 3 do
        lbl = ISLabel:new(leftX - UI_BORDER_SPACING, topY + rowY, BUTTON_HGT, getText("UI_BanditsCreator_Expertise") .. " " .. i, 1, 1, 1, 1, UIFont.Small, false)
        lbl:initialise()
        lbl:instantiate()
        lbl.tooltip = getText("UI_BanditsCreator_Expertise_Tooltip")
        self:addChild(lbl)

        self.expertise[i] = ISComboBox:new(leftX, topY + rowY, 200, BUTTON_HGT, self, BanditCreationMain.onExpertiseSelected)
        self.expertise[i]:initialise();
        
        for j=0, 16 do
            local option = {text=getText("UI_BanditsCreator_Expertise_" .. j), tooltip=getText("UI_BanditsCreator_Expertise_" .. j .. "_Tooltip")}
            self.expertise[i]:addOption(option)
        end
        self.expertise[i].borderColor = {r=0.4, g=0.4, b=0.4, a=1};
        self:addChild(self.expertise[i])
        rowY = rowY + BUTTON_HGT + 8
    end

    -- SLIDERS

    lbl = ISLabel:new(leftX - UI_BORDER_SPACING, topY + rowY, BUTTON_HGT, getText("UI_BanditsCreator_Health"), 1, 1, 1, 1, UIFont.Small, false)
    lbl:initialise()
    lbl:instantiate()
    lbl.tooltip = getText("UI_BanditsCreator_Health_Tooltip")
    self:addChild(lbl)

    self.healthSlider = ISSliderPanel:new(leftX, topY + rowY, 200, BUTTON_HGT);
    self.healthSlider:initialise()
    self.healthSlider:instantiate()
    self.healthSlider:setValues(1.0, 9.0, 1, 2)
    self.healthSlider:setCurrentValue(5, true)
    self:addChild(self.healthSlider)
    rowY = rowY + BUTTON_HGT + 8

    lbl = ISLabel:new(leftX - UI_BORDER_SPACING, topY + rowY, BUTTON_HGT, getText("UI_BanditsCreator_Strength"), 1, 1, 1, 1, UIFont.Small, false)
    lbl:initialise()
    lbl:instantiate()
    lbl.tooltip = getText("UI_BanditsCreator_Strength_Tooltip")
    self:addChild(lbl)

    self.strengthSlider = ISSliderPanel:new(leftX, topY + rowY, 200, BUTTON_HGT);
    self.strengthSlider:initialise()
    self.strengthSlider:instantiate()
    self.strengthSlider:setValues(1.0, 9.0, 1, 2)
    self.strengthSlider:setCurrentValue(5, true)
    self:addChild(self.strengthSlider)
    rowY = rowY + BUTTON_HGT + 8

    lbl = ISLabel:new(leftX - UI_BORDER_SPACING, topY + rowY, BUTTON_HGT, getText("UI_BanditsCreator_Endurance"), 1, 1, 1, 1, UIFont.Small, false)
    lbl:initialise()
    lbl:instantiate()
    lbl.tooltip = getText("UI_BanditsCreator_Endurance_Tooltip")
    self:addChild(lbl)

    self.enduranceSlider = ISSliderPanel:new(leftX, topY + rowY, 200, BUTTON_HGT);
    self.enduranceSlider:initialise()
    self.enduranceSlider:instantiate()
    self.enduranceSlider:setValues(1.0, 9.0, 1, 2)
    self.enduranceSlider:setCurrentValue(5, true)
    self:addChild(self.enduranceSlider)
    rowY = rowY + BUTTON_HGT + 8

    lbl = ISLabel:new(leftX - UI_BORDER_SPACING, topY + rowY, BUTTON_HGT, getText("UI_BanditsCreator_Sight"), 1, 1, 1, 1, UIFont.Small, false)
    lbl:initialise()
    lbl:instantiate()
    lbl.tooltip = getText("UI_BanditsCreator_Sight_Tooltip")
    self:addChild(lbl)

    self.sightSlider = ISSliderPanel:new(leftX, topY + rowY, 200, BUTTON_HGT, self, BanditCreationMain.onClothingChanged)
    self.sightSlider:initialise()
    self.sightSlider:instantiate()
    self:addChild(self.sightSlider)
    rowY = rowY + BUTTON_HGT + 8
    
    
    -- CLOTHING

    local clothingX = leftX + 820

    self.clothingX = clothingX

    local bodyLocations = BanditCompatibility.GetBodyLocations()

    lbl = ISLabel:new(clothingX, topY, BUTTON_HGT, getText("UI_BanditsCreator_Outfit"), 1, 1, 1, 1, UIFont.Medium, false)
    lbl:initialise()
    lbl:instantiate()
    self:addChild(lbl)

    local toolSize = 32
    local toolOffset = getTextManager():MeasureStringX(UIFont.Medium, getText("UI_BanditsCreator_Outfit"))

    local m1 = "C"
    local m2 = "T"
    if BanditCompatibility.GetGameVersion() >= 42 then
        m1 = ""
        m2 = ""
    end

    self.modePick = ISButton:new(clothingX + 10, topY - 4, toolSize, toolSize, m1, self, BanditCreationMain.onClick)
    self.modePick.internal = "MODEPICK"
    self.modePick.anchorTop = false
    self.modePick.anchorBottom = true
    self.modePick:initialise()
    self.modePick:instantiate()
    self.modePick.borderColor = {r=0.0, g=1.0, b=0.0, a=1.0}
    self.modePick.textureBackground = getTexture("media/ui/mode-pick.png")
    self.modePick.status = true
    self.modePick.tooltip = "Clothing picker"
    self:addChild(self.modePick)

    self.modeTint = ISButton:new(clothingX + 10 + toolSize + 4, topY - 4, toolSize, toolSize, m2, self, BanditCreationMain.onClick)
    self.modeTint.internal = "MODETINT"
    self.modeTint.anchorTop = false
    self.modeTint.anchorBottom = true
    self.modeTint:initialise()
    self.modeTint:instantiate()
    self.modeTint.borderColor = {r=0.0, g=0.0, b=0.0, a=1.0}
    self.modeTint.textureBackground = getTexture("media/ui/mode-tint.png")
    self.modeTint.status = false
    self.modeTint.tooltip = "Tint modifier"
    self:addChild(self.modeTint)

    self.clothingColors = {
        -- Row 1: Grayscale
        {r=0.1, g=0.1, b=0.1},       -- Black
        {r=0.2, g=0.2, b=0.2},       -- Dark Gray
        {r=0.4, g=0.4, b=0.4},       -- Medium Gray
        {r=0.6, g=0.6, b=0.6},       -- Light Gray
        {r=0.8, g=0.8, b=0.8},       -- Very Light Gray
        {r=1.0, g=1.0, b=1.0},       -- White
    
        -- Row 2: Reds
        {r=0.4, g=0.0, b=0.0},       -- Deep Burgundy
        {r=0.6, g=0.1, b=0.1},       -- Burgundy
        {r=0.8, g=0.0, b=0.0},       -- True Red
        {r=1.0, g=0.2, b=0.2},       -- Bright Red
        {r=1.0, g=0.4, b=0.4},       -- Blush Red
        {r=1.0, g=0.6, b=0.6},       -- Soft Red
    
        -- Row 3: Oranges
        {r=0.5, g=0.2, b=0.0},       -- Clay
        {r=0.7, g=0.3, b=0.1},       -- Terracotta
        {r=0.9, g=0.4, b=0.1},       -- Burnt Orange
        {r=1.0, g=0.5, b=0.2},       -- Pumpkin
        {r=1.0, g=0.6, b=0.3},       -- Apricot
        {r=1.0, g=0.7, b=0.4},       -- Peach
    
        -- Row 4: Yellows
        {r=0.6, g=0.5, b=0.0},       -- Olive Yellow
        {r=0.8, g=0.6, b=0.1},       -- Dijon
        {r=0.95, g=0.8, b=0.2},      -- Mustard
        {r=1.0, g=0.9, b=0.4},       -- Lemon
        {r=1.0, g=1.0, b=0.4},       -- Pale Yellow
        {r=1.0, g=1.0, b=0.7},       -- Creamy Yellow
    
        -- Row 5: Greens
        {r=0.0, g=0.3, b=0.1},       -- Dark Evergreen
        {r=0.1, g=0.4, b=0.2},       -- Forest Green
        {r=0.2, g=0.5, b=0.2},       -- Moss
        {r=0.3, g=0.6, b=0.4},       -- Olive
        {r=0.5, g=0.8, b=0.5},       -- Sage
        {r=0.6, g=1.0, b=0.6},       -- Fresh Green
    
        -- Row 6: Blues
        {r=0.0, g=0.2, b=0.6},       -- Navy
        {r=0.1, g=0.3, b=0.5},       -- Deep Blue
        {r=0.2, g=0.4, b=0.6},       -- Slate Blue
        {r=0.3, g=0.5, b=0.8},       -- Denim
        {r=0.5, g=0.7, b=1.0},       -- Sky Blue
        {r=0.7, g=0.9, b=1.0},       -- Powder Blue
    
        -- Row 7: Purples
        {r=0.3, g=0.0, b=0.4},       -- Eggplant
        {r=0.4, g=0.2, b=0.5},       -- Plum
        {r=0.6, g=0.4, b=0.7},       -- Heather
        {r=0.7, g=0.5, b=0.8},       -- Lavender
        {r=0.8, g=0.6, b=0.9},       -- Orchid
        {r=0.9, g=0.8, b=1.0},       -- Lilac
    
        -- Row 8: Pinks
        {r=0.5, g=0.2, b=0.3},       -- Dusty Rose
        {r=0.7, g=0.3, b=0.4},       -- Antique Pink
        {r=0.9, g=0.4, b=0.6},       -- Dusty Pink
        {r=1.0, g=0.6, b=0.7},       -- Rose
        {r=1.0, g=0.75, b=0.8},      -- Pastel Pink
        {r=1.0, g=0.9, b=0.9},       -- Blush
    
        -- Row 9: Browns
        {r=0.2, g=0.1, b=0.05},      -- Espresso
        {r=0.3, g=0.2, b=0.1},       -- Coffee
        {r=0.5, g=0.3, b=0.2},       -- Chestnut
        {r=0.6, g=0.4, b=0.3},       -- Taupe
        {r=0.7, g=0.5, b=0.3},       -- Sand
        {r=0.8, g=0.6, b=0.4},       -- Tan
    
        -- Row 10: Extras / Muted Fashion Neutrals
        {r=0.2, g=0.2, b=0.25},      -- Charcoal Blue
        {r=0.3, g=0.35, b=0.3},      -- Army Green
        {r=0.6, g=0.5, b=0.5},       -- Rose Taupe
        {r=0.7, g=0.7, b=0.6},       -- Driftwood
        {r=0.8, g=0.75, b=0.7},      -- Warm Gray
        {r=0.85, g=0.8, b=0.8},      -- Fog
    }
    

    self.colorPickerClothing = ISColorPicker:new(0, 0, nil)
    self.colorPickerClothing:initialise()
    self.colorPickerClothing.keepOnScreen = true
    self.colorPickerClothing.pickedTarget = self
    self.colorPickerClothing.resetFocusTo = self
    self.colorPickerClothing:setColors(self.clothingColors, 6, 10)

    self.clothing = {}
    local row = 1
    for groupName, group in pairs(bodyLocations) do
        row = row + 1
        local y = topY + (row - 1) * (iconSize + 4) - 4

        local label = ISLabel:new(clothingX, y, iconSize, getText("UI_BanditsCreator_BodyLocation_" .. groupName), 1, 1, 1, 1, UIFont.Small)
        label:initialise()
        self:addChild(label)

        for col, bodyLocation in pairs(group) do
            local x = clothingX + (col - 1) * (iconSize + 4) + 10

            self.clothing[bodyLocation] = BanditItemDropBox:new(x, y, iconSize, iconSize, true, self, BanditCreationMain.addItem, BanditCreationMain.removeItem, BanditCreationMain.verifyItem, nil)
            self.clothing[bodyLocation]:initialise()
            self.clothing[bodyLocation]:setToolTip(true, bodyLocation)
            self.clothing[bodyLocation].internal = bodyLocation
            self.clothing[bodyLocation].mode = "outfit"
            self:addChild(self.clothing[bodyLocation])
        end
    end

    self.sightSlider:setValues(1.0, 9.0, 1, 2)
    self.sightSlider:setCurrentValue(5, true)

    self:loadConfig()
    
end

function BanditCreationMain:onClothingChanged()
    self.model:reportEvent("EventWearClothing")

    -- reset
    for bodyLocation, dropbox in pairs(self.clothing) do
        self.model:setWornItem(bodyLocation, nil)
    end
    self.model:setWornItem("Back", nil)
    self.model:clearAttachedItems()

    -- makeup
    local combos = {"MakeupFaceCombo", "MakeupEyesCombo",
                    "MakeupEyeShadowCombo", "MakeupLipsCombo"}

    for i=1, #combos do
        local combo = self[combos[i]]
        if combo then
            self.model:setWornItem(combo.internal, nil)
            local itemType = combo:getOptionData(combo.selected)
            if itemType then
                local makeup = BanditCompatibility.InstanceItem(itemType)
                if makeup then
                    self.model:setWornItem(makeup:getBodyLocation(), makeup)
                end
            end
        end
    end

    -- clothing
    for bodyLocation, dropbox in pairs(self.clothing) do
        local item = dropbox.storedItem
        if item then
            local color = dropbox.backgroundColor
            if color.r > 0 or color.g > 0 or color.b > 0 then
                local visual = item:getVisual()
                local immutableColor = ImmutableColor.new(color.r, color.g, color.b, 1)
                visual:setTint(immutableColor)
            end
            self.model:setWornItem(bodyLocation, item)
        end
    end

    for _, def in pairs(ISHotbarAttachDefinition) do
        if def.name == "Holster" or def.name == "Back" then
            for k, v in pairs(def.attachments) do
                self.model:setAttachedItem(v, nil)
            end
        end
    end

    local bag = self.bag.storedItem
    if bag then
        local replacement = bag:getAttachmentReplacement()
        local immutableColor = ImmutableColor.new(0.1, 0.1, 0.1, 1)
        local visual = bag:getVisual()
        visual:setTint(immutableColor)
        self.model:setWornItem(bag:canBeEquipped(), bag)
    end

    for _, slot in pairs({"primary", "secondary", "melee"}) do
        if self.ammo[slot] then
            self.ammo[slot]:setVisible(false)
        end
        local weapon = self.weapons[slot].storedItem
        if weapon then

            local partList = weapon:getAllWeaponParts()
            for i=1, partList:size() do
                local part = partList:get(i-1)
                weapon:detachWeaponPart(part)
            end

            local sight = self.sightSlider:getCurrentValue()
            local scopeItem
            if sight == 6 or sight == 7 then
                scopeItem = BanditCompatibility.InstanceItem("Base.x2Scope")
            elseif sight == 8 then
                scopeItem = BanditCompatibility.InstanceItem("Base.x4Scope")
            elseif sight == 9 then
                scopeItem = BanditCompatibility.InstanceItem("Base.x8Scope")
            end

            if scopeItem then
                local mountList = scopeItem:getMountOn()
                for i=1, mountList:size() do
                    local mount = mountList:get(i-1)
                    if mount == weapon:getFullType() then
                        weapon:attachWeaponPart(scopeItem)
                    end
                end
            end

            local attachmentType = weapon:getAttachmentType()
            -- local magazineType = weapon:getMagazineType()
            local ammoType = weapon:getAmmoType()
            local ammoBoxType = weapon:getAmmoBox()
            local ammoBox
            if ammoType and ammoBoxType then
                local mod = ammoType:match("([^%.]+)")
                ammoBoxType = mod .. "." .. ammoBoxType
                ammoBox = BanditCompatibility.InstanceItem(ammoBoxType)
            end
            
            for _, def in pairs(ISHotbarAttachDefinition) do
                if def.type == "HolsterRight" or def.type == "Back" or def.type == "SmallBeltLeft" then
                    if def.attachments then
                        for k, v in pairs(def.attachments) do
                            if k == attachmentType then
                                self.model:setAttachedItem(v, weapon)
                                if self.ammo[slot] then
                                    self.ammo[slot].textureBackground = ammoBox:getTexture()
                                    self.ammo[slot]:setTitle(tostring(tostring(self.ammo[slot].value)))
                                    self.ammo[slot]:setVisible(true)
                                end
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    self.avatarPanel:setCharacter(self.model)

end

function BanditCreationMain:updateHairCombo()
    self.hairTypeCombo.options = {}
    local hairStyles = getAllHairStyles(self.model:isFemale())
    for i=1, hairStyles:size() do
        local styleId = hairStyles:get(i-1)
        local hairStyle = self.model:isFemale() and getHairStylesInstance():FindFemaleStyle(styleId) or getHairStylesInstance():FindMaleStyle(styleId)
        local label = styleId
        if label == "" then
            label = getText("IGUI_Hair_Bald")
        else
            label = getText("IGUI_Hair_" .. label);
        end
        if not hairStyle:isNoChoose() then
            self.hairTypeCombo:addOptionWithData(label, hairStyles:get(i-1))
        end
    end
    
    self.beardTypeCombo.options = {}
    if self.model:isFemale() then
        -- no bearded ladies
    else
        local beardStyles = getAllBeardStyles()
        for i=1,beardStyles:size() do
            local label = beardStyles:get(i-1)
            if label == "" then
                label = getText("IGUI_Beard_None")
            else
                label = getText("IGUI_Beard_" .. label);
            end
            self.beardTypeCombo:addOptionWithData(label, beardStyles:get(i-1))
        end
    end

    self.MakeupFaceCombo.options = {}
    self.MakeupFaceCombo:addOptionWithData("None", nil)

    self.MakeupEyesCombo.options = {}
    self.MakeupEyesCombo:addOptionWithData("None", nil)

    self.MakeupEyeShadowCombo.options = {}
    self.MakeupEyeShadowCombo:addOptionWithData("None", nil)

    self.MakeupLipsCombo.options = {}
    self.MakeupLipsCombo:addOptionWithData("None", nil)

    for i, makeup in pairs(MakeUpDefinitions.makeup) do
        if makeup.category == "FullFace" then
            self.MakeupFaceCombo:addOptionWithData(makeup.name, makeup.item)
        elseif makeup.category == "Eyes" then
            self.MakeupEyesCombo:addOptionWithData(makeup.name, makeup.item)
        elseif makeup.category == "EyesShadow" then
            self.MakeupEyeShadowCombo:addOptionWithData(makeup.name, makeup.item)
        elseif makeup.category == "Lips" then
            self.MakeupLipsCombo:addOptionWithData(makeup.name, makeup.item)
        end
    end
end

function BanditCreationMain:onGenderSelected(combo)
    if combo.selected == 1 then
        -- self.avatar:setFemale(true)
        self.model:setFemale(true)
        self.model:getHumanVisual():removeBodyVisualFromItemType("Base.M_Hair_Stubble")
        self.model:getHumanVisual():removeBodyVisualFromItemType("Base.M_Beard_Stubble")
    else
        -- self.avatar:setFemale(false)
        self.model:setFemale(false)
        self.model:getHumanVisual():removeBodyVisualFromItemType("Base.F_Hair_Stubble")
        self.model:getHumanVisual():setBeardModel(Bandit.GetBeardStyle(false, 1))
    end
    self.avatarPanel:setCharacter(self.model)
    self:updateHairCombo()
end

function BanditCreationMain:onSkinColorSelected(button, x, y)
    self.colorPickerSkin:setX(button:getAbsoluteX())
    self.colorPickerSkin:setY(button:getAbsoluteY() + button:getHeight())
    self.colorPickerSkin:setPickedFunc(BanditCreationMain.onSkinColorPicked)
    local color = button.backgroundColor
    self.colorPickerSkin:setInitialColor(ColorInfo.new(color.r, color.g, color.b, 1))
    self:showColorPicker(self.colorPickerSkin)
end

function BanditCreationMain:onSkinColorPicked(color, mouseUp)
    self.skinColorButton.backgroundColor = { r=color.r, g=color.g, b=color.b, a = 1 }
    self.model:getHumanVisual():setSkinTextureIndex(self.colorPickerSkin.index - 1)
    self.avatarPanel:setCharacter(self.model)
end

function BanditCreationMain:onChestHairSelected(index, selected)
    self.model:getHumanVisual():setBodyHairIndex(selected and 0 or -1)
    self.avatarPanel:setCharacter(self.model)
end

function BanditCreationMain:onHairTypeSelected(combo)
    self.hairType = combo.selected - 1
    local hair = combo:getOptionData(combo.selected)
    self.model:getHumanVisual():setHairModel(hair)
    self.avatarPanel:setCharacter(self.model)
end

function BanditCreationMain:onBeardTypeSelected(combo)
    local beard = combo:getOptionData(combo.selected)
    self.model:getHumanVisual():setBeardModel(beard)
    self.avatarPanel:setCharacter(self.model)
end

function BanditCreationMain:onHairColorMouseDown(button, x, y)
    self.colorPickerHair:setX(button:getAbsoluteX())
    self.colorPickerHair:setY(button:getAbsoluteY() + button:getHeight())
    self.colorPickerHair:setPickedFunc(BanditCreationMain.onHairColorPicked)
    local color = button.backgroundColor
    self.colorPickerHair:setInitialColor(ColorInfo.new(color.r, color.g, color.b, 1))
    self:showColorPicker(self.colorPickerHair)
end

function BanditCreationMain:onHairColorPicked(color, mouseUp)
    self.hairColorButton.backgroundColor = { r=color.r, g=color.g, b=color.b, a = 1 }
    local immutableColor = ImmutableColor.new(color.r, color.g, color.b, 1)
    self.model:getHumanVisual():setHairColor(immutableColor)
    self.model:getHumanVisual():setBeardColor(immutableColor)
    self.model:getHumanVisual():setNaturalHairColor(immutableColor)
    self.model:getHumanVisual():setNaturalBeardColor(immutableColor)
    self.avatarPanel:setCharacter(self.model)
end

function BanditCreationMain:onClothingColorPicked(color, mouseUp)
    local dropbox = self.colorPickerClothing.dropbox
    dropbox.backgroundColor = { r=color.r, g=color.g, b=color.b, a = 1 }
    self:onClothingChanged()
end

function BanditCreationMain:addItem(dropbox)
    if self.modePick.status == true then
        local listBox = BanditItemsListTable:new(self.clothingX - 60, 60, 600, self.height - 60, self, dropbox)
        listBox:initialise()
        listBox:addToUIManager()
    elseif self.modeTint.status == true then
        self.colorPickerClothing.dropbox = dropbox
        self.colorPickerClothing:setX(dropbox:getAbsoluteX())
        self.colorPickerClothing:setY(dropbox:getAbsoluteY() + dropbox:getHeight())
        self.colorPickerClothing:setPickedFunc(BanditCreationMain.onClothingColorPicked)
        local color = dropbox.backgroundColor
        self.colorPickerClothing:setInitialColor(ColorInfo.new(color.r, color.g, color.b, 1))
        self:showColorPicker(self.colorPickerClothing)

        --[[
        local tintModal = BanditTintModal:new(1100, 200, 600, 600, self, dropbox)
        tintModal:initialise()
        tintModal:addToUIManager()]]
    end
end

function BanditCreationMain:removeItem(dropbox)
    dropbox:setStoredItem(nil)
    dropbox.backgroundColor = {r=0, g=0, b=0, a=1}
    self:onClothingChanged()
end

function BanditCreationMain:showColorPicker(picker)
    picker:removeFromUIManager()
    picker:addToUIManager()
end

function BanditCreationMain:onClick(button)
    local player = getSpecificPlayer(0)
    local screenWidth, screenHeight = getCore():getScreenWidth(), getCore():getScreenHeight()
    local margin = screenWidth > 1900 and 100 or 0
    local modalWidth, modalHeight = screenWidth - margin, screenHeight - margin
    local modalX = (screenWidth / 2) - (modalWidth / 2)
    local modalY = (screenHeight / 2) - (modalHeight / 2)
    if button.internal == "SAVE" then
        self:saveConfig()
        self.avatarPanel:setCharacter(nil)
        if self.model then
            self.model:removeFromSquare()
            if player then
                self.model:removeFromWorld()
            end
            self.model:removeSaveFile()
            self.model = nil
        end
        local modal = BanditClanMain:new(modalX, modalY, modalWidth, modalHeight, self.cid)
        modal:initialise()
        modal:addToUIManager()
        self:removeFromUIManager()
        self:close()
    elseif button.internal == "CANCEL" then
        self.avatarPanel:setCharacter(nil)
        if self.model then
            self.model:removeFromSquare()
            if player then
                self.model:removeFromWorld()
            end
            self.model:removeSaveFile()
            self.model = nil
        end
        local modal = BanditClanMain:new(modalX, modalY, modalWidth, modalHeight, self.cid)
        modal:initialise()
        modal:addToUIManager()
        self:removeFromUIManager()
        self:close()
    elseif button.internal == "CLONE" then
        self:saveConfig()
        self:cloneConfig()
        self.avatarPanel:setCharacter(nil)
        if self.model then
            self.model:removeFromSquare()
            if player then
                self.model:removeFromWorld()
            end
            self.model:removeSaveFile()
            self.model = nil
        end
        local modal = BanditClanMain:new(modalX, modalY, modalWidth, modalHeight, self.cid)
        modal:initialise()
        modal:addToUIManager()
        self:removeFromUIManager()
        self:close()
    elseif button.internal == "AMMO" then
        button.value = button.value + 1
        if button.value > 20 then button.value = 20 end
        button:setTitle(tostring(button.value))
    elseif button.internal == "MODEPICK" then
        self.modePick.borderColor = {r = 0.0, g = 1, b = 0.0, a = 1}
        self.modePick.status = true
        self.modeTint.borderColor = {r = 0.0, g = 0.0, b = 0.0, a = 1}
        self.modeTint.status = false
    elseif button.internal == "MODETINT" then
        self.modePick.borderColor = {r = 0.0, g = 0.0, b = 0.0, a = 1}
        self.modePick.status = false
        self.modeTint.borderColor = {r = 0.0, g = 1, b = 0.0, a = 1}
        self.modeTint.status = true
    end
    
    
end

function BanditCreationMain:onRightClick(button)

    if button.internal == "AMMO" then
        button.value = button.value - 1
        if button.value < 1 then button.value = 1 end
        button:setTitle(tostring(button.value))
    end
    
    
end

function BanditCreationMain:update()
    ISPanel.update(self)
end

function BanditCreationMain:prerender()
    ISPanel.prerender(self);
    self:drawTextureScaled(self.backgroundTexture, (self.width/2)-610, 1, 1220, 813, 1, 1, 1, 1, 1)
    self:drawTextCentre(getText("UI_BanditsCreator_Bandit_Creator"), self.width / 2, UI_BORDER_SPACING + 5, 1, 1, 1, 1, UIFont.Title);
end

function BanditCreationMain:loadConfig()
    BanditCustom.Load()

    local data = BanditCustom.Get(self.bid)
    if not data then 
        self.genderCombo.selected = 2
        self.colorPickerSkin.index = 1
        self.hairTypeCombo.selected = 1
        self.beardTypeCombo.selected = 1
        self.colorPickerHair.index = 1
        return
    end

    if data.general then

        if data.general.modid then
            for i=1, #self.modCombo.options do
                if self.modCombo.options[i] == data.general.modid then
                    self.modCombo.selected = i
                end
            end
        end

        self.nameEntry:setText(data.general.name)

        if data.general.female then
            self.genderCombo.selected = 1
        else
            self.genderCombo.selected = 2
        end
        self:onGenderSelected(self.genderCombo)

        if data.general.skin then
            self.colorPickerSkin.index = data.general.skin
            local color = self.skinColors[data.general.skin]
            self:onSkinColorPicked(color)
        end

        if data.general.hairType then
            self.hairTypeCombo.selected = data.general.hairType
            self:onHairTypeSelected(self.hairTypeCombo)
        end

        if data.general.beardType then
            self.beardTypeCombo.selected = data.general.beardType
            self:onBeardTypeSelected(self.beardTypeCombo)
        end

        if data.general.hairColor then
            self.colorPickerHair.index = data.general.hairColor
            local color = self.hairColors[data.general.hairColor]
            self:onHairColorPicked(color)
        end

        if data.general.health then
            self.healthSlider:setCurrentValue(data.general.health)
        end

        if data.general.strength then
            self.strengthSlider:setCurrentValue(data.general.strength)
        end

        if data.general.endurance then
            self.enduranceSlider:setCurrentValue(data.general.endurance)
        end

        if data.general.sight then
            self.sightSlider:setCurrentValue(data.general.sight)
        end

        if data.general.exp1 then
            self.expertise[1].selected = data.general.exp1 + 1
        end

        if data.general.exp2 then
            self.expertise[2].selected = data.general.exp2 + 1
        end

        if data.general.exp3 then
            self.expertise[3].selected = data.general.exp3 + 1
        end
    end

    if data.clothing then

        local combos = {"MakeupFaceCombo", "MakeupEyesCombo",
                        "MakeupEyeShadowCombo", "MakeupLipsCombo"}

        for bodyLocation, itemType in pairs(data.clothing) do
            -- clothing
            for _, dropbox in pairs(self.clothing) do
                if dropbox.internal == bodyLocation then
                    local item = BanditCompatibility.InstanceItem(itemType)

                    if data.tint and data.tint[bodyLocation] then
                        local cint = data.tint[bodyLocation] 
                        local color = BanditUtils.dec2rgb(cint)
                        dropbox.backgroundColor = {r=color.r, g=color.g, b=color.b, a=1}
                    end
                    dropbox:setStoredItem(item)
                    break
                end
            end

            -- makeup
            for i=1, #combos do
                local combo = self[combos[i]]
                if combo then
                    if combo.internal == bodyLocation then
                        combo:selectData(itemType)
                    end
                end
            end
        end
    end

    if data.weapons then
        for _, slot in pairs({"primary", "secondary", "melee"}) do
            if data.weapons[slot] then
                local item = BanditCompatibility.InstanceItem(data.weapons[slot])
                self.weapons[slot]:setStoredItem(item)
                if data.ammo then
                    if self.ammo[slot] then
                        self.ammo[slot].value = data.ammo[slot]
                    end
                end
            end
        end
    end

    if data.bag then
        local item = BanditCompatibility.InstanceItem(data.bag.name)
        self.bag:setStoredItem(item)
    end
    self:onClothingChanged()

    if ZombRand(100) == 0 then
        local gender = "Male"
        local voice = BanditUtils.Choice({"1", "2", "3", "4"})
        local variant = 1 + ZombRand(4)
        if data.general.female then 
            gender = "Female"
            vocie = BanditUtils.Choice({"1", "2", "4"})
        end
        getSoundManager():playUISound("ZSDefender_Spot_" .. gender .. "_" .. voice .. "_" .. variant)
    end

end

function BanditCreationMain:saveConfig(clone)
    
    local function incrementSuffix(str)
        local base, num = str:match("^(.-)_(%d+)$")
        if base and num then
            return base .. "_" .. string.format("%02d", tonumber(num) + 1)
        else
            return str .. "_01"
        end
    end

    if clone then
        self.bid = BanditCustom.GetNextId()
    end
    
    local data = BanditCustom.Create(self.bid)

    data.general = {}

    data.general.modid = self.modCombo:getSelectedText()
    data.general.cid = self.cid
    data.general.name = BanditUtils.SanitizeString(self.nameEntry:getText())

    if clone then
        data.general.name = incrementSuffix(data.general.name)
    end

    if self.genderCombo.selected == 1 then
        data.general.female = true
    else
        data.general.female = false
    end

    data.general.skin = self.colorPickerSkin.index
    data.general.hairType = self.hairTypeCombo.selected
    data.general.beardType = self.beardTypeCombo.selected
    data.general.hairColor = self.colorPickerHair.index

    data.general.health = self.healthSlider:getCurrentValue()
    data.general.strength = self.strengthSlider:getCurrentValue()
    data.general.endurance = self.enduranceSlider:getCurrentValue()
    data.general.sight = self.sightSlider:getCurrentValue()

    data.general.exp1 = self.expertise[1].selected - 1
    data.general.exp2 = self.expertise[2].selected - 1
    data.general.exp3 = self.expertise[3].selected - 1

    data.clothing = {}
    data.tint = {}
    for _, dropbox in pairs(self.clothing) do
        local item = dropbox:getStoredItem()
        if item then
            data.clothing[dropbox.internal] = item:getFullType()
            local color = dropbox.backgroundColor
            if color.r > 0 or color.g > 0 or color.b > 0 then
                local cint = BanditUtils.rgb2dec(color.r, color.g, color.b)
                data.tint[dropbox.internal] = cint
            end
        end
    end

    local combos = {"MakeupFaceCombo", "MakeupEyesCombo",
                    "MakeupEyeShadowCombo", "MakeupLipsCombo"}

    for i=1, #combos do
        local combo = self[combos[i]]
        if combo then
            local selected = combo:getOptionData(combo.selected)
            if selected then
                data.clothing[combo.internal] = selected
            end
        end
    end

    data.weapons = {}
    data.ammo = {}
    for _, slot in pairs({"primary", "secondary", "melee"}) do
        local item = self.weapons[slot]:getStoredItem()
        if item then
            data.weapons[slot] = item:getFullType()
            if self.ammo[slot] then
                data.ammo[slot] = tonumber(self.ammo[slot].value)
            end
        end
    end

    data.bag = {}
    local bag = self.bag:getStoredItem()
    if bag then
        data.bag.name = bag:getFullType()
    end

    BanditCustom.Save()
end

function BanditCreationMain:cloneConfig()
    self:saveConfig(true)
end

function BanditCreationMain:new(x, y, width, height, bid, cid)
    local o = {}
    x = getCore():getScreenWidth() / 2 - (width / 2);
    y = getCore():getScreenHeight() / 2 - (height / 2);
    o = ISPanel:new(x, y, width, height);
    setmetatable(o, self)
    self.__index = self
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1};
    o.backgroundColor = {r=0, g=0, b=0, a=0.8};
    o.width = width;
    o.height = height;
    o.bid = bid
    o.cid = cid
    o.moveWithMouse = true;
    BanditCreationMain.instance = o;
    ISDebugMenu.RegisterClass(self);
    return o;
end
