local CivilianGroups = {}

CivilianGroups.FIGHTER_CID = "c167d1e0-c077-4ee5-b353-88b374de193d"
CivilianGroups.COWARD_CID = "c3b0a7ac-6ae0-45cc-bf7b-0492ca0d21e3"

CivilianGroups._cidLookup = {
    [CivilianGroups.FIGHTER_CID] = true,
    [CivilianGroups.COWARD_CID] = true,
}

function CivilianGroups.IsCivilianCID(cid)
    return cid ~= nil and CivilianGroups._cidLookup[cid] == true
end

return CivilianGroups
