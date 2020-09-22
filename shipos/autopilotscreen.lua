-- Autopilot Screen
-- This is for managing autopilot information.
-- 1. Bookmark current location, with 5-character name
-- 2. List of bookmarks to go to.

local AutoPilotScreen = {
    name = "Autopilot",
    CHOICES = {},
    Choice = 1,
    inNameEntry = false,
    deleteat = 0
}

AutoPilotScreen.reset = function()
    AutoPilotScreen.CHOICES = {
        {namer = true, name = "Bookmark Current Location"},
        {clearer = true, name = "Clear set destination"}
    }
    AutoPilotScreen.Choice = 1
    AutoPilotScreen.inNameEntry = false

    local bms = AutoPilotScreen.getBookmarks()
    for _, bm in ipairs(bms) do
        table.insert(AutoPilotScreen.CHOICES, bm)
    end
end

AutoPilotScreen.getBookmarks = function()
    if databank.hasKey("bookmarks") then
        local ret = nil
        if
            pcall(
                function()
                    local s = databank.getStringValue("bookmarks")
                    ret = json.decode(s)
                end
            )
         then
            if type(ret) == "table" then
                return ret
            end
        end
    end
    return {}
end

AutoPilotScreen.addBookmark = function(bm)
    local bms = AutoPilotScreen.getBookmarks()
    table.insert(bms, bm)
    databank.setStringValue("bookmarks", json.encode(bms))
    AutoPilotScreen.reset()
end

AutoPilotScreen.deleteBookmark = function(idx, todel)
    local bms = AutoPilotScreen.getBookmarks()
    local newbms = {}
    local done = false
    for _, bm in ipairs(bms) do
        if not done and bm.position[1] == todel.position[1] and bm.name == todel.name and bm.altitude == todel.altitude then
            done = true
        else
            table.insert(newbms, bm)
        end
    end
    databank.setStringValue("bookmarks", json.encode(newbms))
    AutoPilotScreen.reset()
end

local BMState = {
    chars = {"A"},
    pos = 1
}

local BMMAP_DOWN = {
    ["A"] = "B", ["B"] = "C", ["C"] = "D", ["D"] = "E", ["E"] = "F",
    ["F"] = "G", ["G"] = "H", ["H"] = "I", ["I"] = "J", ["J"] = "K",
    ["K"] = "L", ["L"] = "M", ["M"] = "N", ["N"] = "O", ["O"] = "P",
    ["P"] = "Q", ["Q"] = "R", ["R"] = "S", ["S"] = "T", ["T"] = "U",
    ["U"] = "V", ["V"] = "W", ["W"] = "X", ["X"] = "Y", ["Y"] = "Z",
    ["Z"] = "1", ["1"] = "2", ["2"] = "3", ["3"] = "4", ["4"] = "5",
    ["5"] = "6", ["6"] = "7", ["7"] = "8", ["8"] = "9", ["9"] = "0",
    ["0"] = " ", [" "] = "A"
}

local BMMAP_UP = {
    ["A"] = " ", ["B"] = "A", ["C"] = "B", ["D"] = "C", ["E"] = "D",
    ["F"] = "E", ["G"] = "F", ["H"] = "G", ["I"] = "H", ["J"] = "I",
    ["K"] = "J", ["L"] = "K", ["M"] = "L", ["N"] = "M", ["O"] = "N",
    ["P"] = "O", ["Q"] = "P", ["R"] = "Q", ["S"] = "R", ["T"] = "S",
    ["U"] = "T", ["V"] = "U", ["W"] = "V", ["X"] = "W", ["Y"] = "X",
    ["Z"] = "Y", ["1"] = "Z", ["2"] = "1", ["3"] = "2", ["4"] = "3",
    ["5"] = "4", ["6"] = "5", ["7"] = "6", ["8"] = "7", ["9"] = "8",
    ["0"] = "9", [" "] = "0"
}

BMState.render = function()
    local chars = {}
    for p, char in ipairs(BMState.chars) do
        table.insert(chars, el("div", {class = (p == BMState.pos and "sel ch" or "ch")}, char))
    end

    return el(
        "div",
        {class = "namer"},
        [[<p>Enter a name: A = prev char D = next char, S = abc, W = zyx.</p>]] ..
            table.concat(chars, "") .. [[<p>Press space to add bookmark</p>]]
    )
end

BMState.up = function()
    local cur = BMState.chars[BMState.pos]
    cur = BMMAP_UP[cur]
    BMState.chars[BMState.pos] = cur
end

BMState.down = function()
    local cur = BMState.chars[BMState.pos]
    cur = BMMAP_DOWN[cur]
    BMState.chars[BMState.pos] = cur
end

BMState.left = function()
    BMState.pos = BMState.pos - 1
    if BMState.pos < 1 then
        BMState.pos = 1
    end
end

BMState.right = function()
    BMState.pos = BMState.pos + 1
    if BMState.pos > 20 then
        BMState.pos = 20
    end
    if BMState.pos > #BMState.chars then
        table.insert(BMState.chars, "A")
    end
end

AutoPilotScreen.Style =
    el(
    "style",
    [[
	    .namer { position: fixed; width: 20vw; height: 20vh; padding: 2em; display: block; left: 45vw; top: 45vh; font-size: 3vh; color: white; background-color: #666699ee; }
	    .ch { display: inline-block; width: 3vh; height: 3vh; text-align: center; }
	    .sel { background-color: #669966ee; }
	    .bookmarks { position: fixed; display: block; left: 40vw; top: 35vh; }
	    .estab { display: block; width: 15vw; height: 4vh; margin: 0; padding: 5px; background-color: grey; font-size: 1.5vh; color: white; }
	    .essel { background-color: yellow; color: black; }
    ]]
)

AutoPilotScreen.onFORWARD = function()
    if AutoPilotScreen.inNameEntry then
        BMState.up()
        return
    end
    AutoPilotScreen.Choice = AutoPilotScreen.Choice - 1
    if AutoPilotScreen.Choice < 1 then
        AutoPilotScreen.Choice = #AutoPilotScreen.CHOICES
    end
end

AutoPilotScreen.onBACKWARD = function()
    if AutoPilotScreen.inNameEntry then
        BMState.down()
        return
    end
    AutoPilotScreen.Choice = AutoPilotScreen.Choice + 1
    if AutoPilotScreen.Choice > #AutoPilotScreen.CHOICES then
        AutoPilotScreen.Choice = 1
    end
end

AutoPilotScreen.onYAWLEFT = function()
    if AutoPilotScreen.inNameEntry then
        BMState.left()
        return
    end
end

AutoPilotScreen.onYAWRIGHT = function()
    if AutoPilotScreen.inNameEntry then
        BMState.right()
        return
    end
end

AutoPilotScreen.onLEFT = function()
    if AutoPilotScreen.inNameEntry then
        AutoPilotScreen.inNameEntry = false
        return
    end
    local choice = AutoPilotScreen.CHOICES[AutoPilotScreen.Choice]
    if not choice.position then
        return
    end
    local now = system.getTime()
    if now - AutoPilotScreen.deleteat < 2.0 then
        AutoPilotScreen.deleteBookmark(AutoPilotScreen.Choice, choice)
    else
        AutoPilotScreen.deleteat = now
    end
end

AutoPilotScreen.bookmark = function(name)
    local bm = {
        name = name,
        position = core.getConstructWorldPos(),
        altitude = PHYSICS.altitude,
        inatmo = PHYSICS.inAtmo,
    }
    AutoPilotScreen.addBookmark(bm)
end

function clearDestination()
    databank.setStringValue("destination", "{}")
    MainScreen.destination = {}
end

AutoPilotScreen.onUP = function()
    if AutoPilotScreen.inNameEntry then
        AutoPilotScreen.bookmark(table.concat(BMState.chars, ""))
        return
    end
    local choice = AutoPilotScreen.CHOICES[AutoPilotScreen.Choice]
    if choice.namer then
        AutoPilotScreen.inNameEntry = true
        BMState.chars = {"A"}
        BMState.pos = 1
        return
    end
    if choice.clearer then
        clearDestination()
    end
    if not choice.position then
        return
    end
    databank.setStringValue("destination", json.encode(choice))
    MainScreen.destination = choice
end

AutoPilotScreen.render = function()
    local tabs = {}
    local chosen = nil
    for i, engine in ipairs(AutoPilotScreen.CHOICES) do
        local cls = "estab"
        if i == AutoPilotScreen.Choice then
            cls = "estab essel"
            chosen = engine
        end
        table.insert(tabs, el("div", {class = cls}, engine.name))
    end
    local bmname = ""
    if AutoPilotScreen.inNameEntry then
        bmname = BMState.render()
    end
    return AutoPilotScreen.Style .. el("div", {class = "bookmarks"}, tabs) .. bmname
end
