require "ISUI/ISPanel"

BanditItemsListTable = ISPanel:derive("BanditItemsListTable");

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local UI_BORDER_SPACING = 10
local BUTTON_HGT = FONT_HGT_SMALL + 6
local LABEL_HGT = FONT_HGT_MEDIUM + 6

local function getItems(mode, internal, search)
    local items = {}
    if mode == "outfit" then
        items = getAllItemsForBodyLocation(internal)
    elseif mode == "carriable" then
        local all = getAllItems()
        for i=0, all:size()-1 do
            local item = all:get(i)
            if not item:getObsolete() and not item:isHidden() then
                local itemType = item:getFullName()
                local invItem = BanditCompatibility.InstanceItem(itemType)
                if invItem then
                    if instanceof(invItem, "HandWeapon") then
                        local invItemType = WeaponType.getWeaponType(invItem)
                        if internal == "primary" and invItemType == WeaponType.firearm then
                            table.insert(items, itemType)
                        elseif internal == "secondary" and invItemType == WeaponType.handgun then
                            table.insert(items, itemType)
                        elseif internal == "melee" and invItemType ~= WeaponType.firearm and invItemType ~= WeaponType.handgun then
                            table.insert(items, itemType)
                        end
                    elseif instanceof(invItem, "InventoryContainer") then
                        if internal == "bag"  then
                            if invItem:canBeEquipped() == "Back" then
                                table.insert(items, itemType)
                            end
                        end
                    end
                end
            end
        end
    end

    if search and search ~= "" then
        local search = string.lower(search)
        for i = #items, 1, -1 do
            local item = string.lower(items[i])
            
            if not string.find(item, search, 1, true) then
                table.remove(items, i)
            end
        end
    end

    table.sort(items, function(a,b) return not string.sort(a, b) end)
    return items
end

function BanditItemsListTable:initialise()
    ISPanel.initialise(self);

    local btnCancelWidth = 100 -- getTextManager():MeasureStringX(UIFont.Small, "Close") + 64
    local btnCancelX = math.floor(self:getWidth() / 2) - (btnCancelWidth / 2)

    self.cancel = ISButton:new(btnCancelX, self:getHeight() - UI_BORDER_SPACING - BUTTON_HGT - 1, btnCancelWidth, BUTTON_HGT, getText("UI_BanditsCreator_Close"), self, BanditItemsListTable.onClick)
    self.cancel.internal = "CLOSE"
    self.cancel.anchorTop = false
    self.cancel.anchorBottom = true
    self.cancel:initialise()
    self.cancel:instantiate()
    if BanditCompatibility.GetGameVersion() >= 42 then
        self.cancel:enableCancelColor()
    end
    self:addChild(self.cancel)

    self.searchEntry = ISTextEntryBox:new("", UI_BORDER_SPACING, self:getHeight() - UI_BORDER_SPACING - BUTTON_HGT - 1, 100, BUTTON_HGT)
    self.searchEntry:initialise()
    self.searchEntry:instantiate()
    self.searchEntry.onCommandEntered = BanditItemsListTable.changeFilter 
    self:addChild(self.searchEntry)
    self.searchEntry:focus()

    self.datas = ISScrollingListBox:new(0, 0, self.width, self.height - BUTTON_HGT - 24)
    self.datas:initialise()
    self.datas:instantiate()
    self.datas.itemheight = 48
    self.datas.selected = 0
    self.datas.joypadParent = self
    self.datas.font = UIFont.NewSmall
    self.datas.doDrawItem = self.drawDatas
    self.datas.drawBorder = false
--    self.datas.parent = self;
    self.datas:addColumn("Icon", 0)
    self.datas:addColumn("Type", self.datas.itemheight)
    self.datas:addColumn("Name", 384)
    self.datas:setOnMouseDoubleClick(self, BanditItemsListTable.addItem)
    self:addChild(self.datas)

    local internal = self.dropbox.internal
    local mode = self.dropbox.mode
    local items = getItems(mode, internal)

    for i, itemType in pairs(items) do
        local item = BanditCompatibility.InstanceItem(itemType)
        self.datas:addItem(item:getDisplayName(), item)
    end


    self.buttons = {}

end

function BanditItemsListTable:changeFilter()
    local search = self:getText()
    self.parent.datas:clear()
    local internal = self.parent.dropbox.internal
    local mode = self.parent.dropbox.mode

    local items = getItems(mode, internal, search)

    for i, itemType in pairs(items) do
        local item = BanditCompatibility.InstanceItem(itemType)
        self.parent.datas:addItem(item:getDisplayName(), item)
    end
end

function BanditItemsListTable:addItem(item)
    local sound
    if instanceof (item, "Clothing") then
        sound = "PutItemInBag"
    elseif instanceof(item, "HandWeapon") then
        sound = item:getRackSound()
        if not sound then
            sound = item:getBringToBearSound()
        end
        if not sound then
            sound = "PutItemInBag"
        end
    end
    self.dropbox:setStoredItem(item)
    if sound then
        getSoundManager():playUISound(sound)
    end
    self.parent:onClothingChanged()
end

function BanditItemsListTable:drawDatas(y, item, alt)
    if y + self:getYScroll() + self.itemheight < 0 or y + self:getYScroll() >= self.height then
        return y + self.itemheight
    end
    
    local a = 0.9;

    if self.selected == item.index then
        self:drawRect(0, (y), self:getWidth(), self.itemheight, 0.3, 0.7, 0.35, 0.15);
    end

    if alt then
        self:drawRect(0, (y), self:getWidth(), self.itemheight, 0.3, 0.6, 0.5, 0.5);
    end

    self:drawRectBorder(0, (y), self:getWidth(), self.itemheight, a, self.borderColor.r, self.borderColor.g, self.borderColor.b);

    local iconX = 4
    local iconSize = self.itemheight - 8
    local xoffset = 4
    local x = self.columns[1].size
    local icon = item.item:getTexture()
    --[[
    if item.item:getIconsForTexture() and not item.item:getIconsForTexture():isEmpty() then
        icon = item.item:getIconsForTexture():get(0)
    end]]
    if icon then
        self:drawTextureScaledAspect2(icon, x + xoffset, y + 3, iconSize, iconSize, 1, 1, 1, 1)
    end

    x = self.columns[2].size
    self:drawText(item.item:getFullType(), x + xoffset, y + 3, 1, 1, 1, a, self.font)

    x = self.columns[3].size
    self:drawText(item.item:getDisplayName(), x + xoffset, y + 3, 1, 1, 1, a, self.font)
   
    return y + self.itemheight;

end

function BanditItemsListTable:initList(module)
end


function BanditItemsListTable:prerender()
    ISPanel.prerender(self);
end

function BanditItemsListTable:render()
    ISPanel.render(self);
end

function BanditItemsListTable:onClick(button)
    if button.internal == "CLOSE" then
        self:close()
    end
end


function BanditItemsListTable:render()
    ISPanel.render(self);
    
end

function BanditItemsListTable:new (x, y, width, height, parent, dropbox)
    local o = ISPanel:new(x, y, width, height);
    setmetatable(o, self)
    self.__index = self
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1};
    o.backgroundColor = {r=0, g=0, b=0, a=0.8};
    o.width = width;
    o.height = height;
    o.moveWithMouse = true;
    o.parent = parent
    o.dropbox = dropbox
    BanditItemsListTable.instance = o;
    return o;
end

