--
-- ********************************
-- *** Bandits Creator          ***
-- ********************************
-- *** Coded by: Slayer         ***
-- ********************************
--

BCMenu = BCMenu or {}

function BCMenu.BanditCreator(player)
    local screenWidth, screenHeight = getCore():getScreenWidth(), getCore():getScreenHeight()
    local margin = screenWidth > 1900 and 100 or 0
    local modalWidth, modalHeight = screenWidth - margin, screenHeight - margin
    local modalX = (screenWidth / 2) - (modalWidth / 2)
    local modalY = (screenHeight / 2) - (modalHeight / 2)
    local modal = BanditClansMain:new(modalX, modalY, modalWidth, modalHeight)
    modal:initialise()
    modal:addToUIManager()
end

function BCMenu.WorldContextMenuPre(playerID, context, worldobjects, test)
    local player = getSpecificPlayer(playerID)
    local square = BanditCompatibility.GetClickedSquare()

    if isDebugEnabled() or isAdmin() then
        context:addOption("Bandit Creator", player, BCMenu.BanditCreator)
    end
end

Events.OnPreFillWorldObjectContextMenu.Add(BCMenu.WorldContextMenuPre)