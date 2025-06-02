playerExitedGame = false

CoeffOfIdentify = CoeffOfIdentify or 0

Stepik = Stepik or 0

AlreadyDeleted = AlreadyDeleted or false

local function escapeString(str)
    -- Экранируем базовые символы, чтобы не ломать JSON-формат
    str = str:gsub("\\", "\\\\")
    str = str:gsub("\"", "\\\"")
    str = str:gsub("\n", "\\n")
    str = str:gsub("\r", "\\r")
    str = str:gsub("\t", "\\t")
    return str
end

local function encodeJSON(value)
    local t = type(value)

    -- nil -> "null"
    if t == "nil" then
        return "null"

    -- boolean -> "true"/"false"
    elseif t == "boolean" then
        return value and "true" or "false"

    -- number -> "число" (без кавычек)
    elseif t == "number" then
        return tostring(value)

    -- string -> "строка" (с экранированием)
    elseif t == "string" then
        return "\"" .. escapeString(value) .. "\""

    -- table -> либо "[]" (массив), либо "{}" (объект/словарь)
    elseif t == "table" then
        -- Проверим, является ли таблица массивом (ключи 1..n без дыр)
        local isArray = true
        local count = 0

        -- Сначала найдём максимальный числовой ключ
        for k, _ in pairs(value) do
            if type(k) ~= "number" then
                isArray = false
                break
            else
                if k > count then
                    count = k
                end
            end
        end

        if isArray then
            -- Сериализация массива: [ val1, val2, ... ]
            local items = {}
            for i = 1, count do
                table.insert(items, encodeJSON(value[i]))
            end
            return "[" .. table.concat(items, ",") .. "]"
        else
            -- Сериализация словаря: { "key": value, "key2": value2, ... }
            local props = {}
            for k, v in pairs(value) do
                -- Ключи в JSON должны быть строками
                local key = "\"" .. escapeString(tostring(k)) .. "\":"
                table.insert(props, key .. encodeJSON(v))
            end
            return "{" .. table.concat(props, ",") .. "}"
        end
    end

    -- Если ничего из вышеперечисленного не подошло, вернём "null"
    return "null"
end

-- ------------------------------------------------------
-- Пример использования SavedVariables для хранения данных
-- ------------------------------------------------------

-- Если при загрузке аддона нет сохранённой таблицы, создаём новую
PlayerData = PlayerData or {
    ["time_in_dungeons"]  = 0,
    ["Kills"]       = 0,
    ["Messages"]    = 0,
    ["Stones,Grass,Meals and etc."] = 0
}

-- В эту переменную мы будем записывать результат сериализации в JSON
PlayerDataJSON = PlayerDataJSON or ""

-- ------------------------------------------------------
-- Пример: Функция, сериализующая PlayerData -> JSON
-- ------------------------------------------------------

local maxValues = {
    ["time_in_dungeons"] = 480,
    ["Kills"] = 50,
    ["Messages"] = 300,
    ["Stones,Grass,Meals and etc."] = 400
}

local function NormalizePlayerData()

    local normalizedSum = 0

    for key, value in pairs(PlayerData) do
        local max = maxValues[key] or 1
        local normalizedValue = math.min(value / max, 1)
        normalizedSum = normalizedSum + normalizedValue
    end
    
    CoeffOfIdentify = normalizedSum

    if normalizedSum >= 1 then
        if Stepik == 0 then
	        print("Данных достаточно для составления рекомендаций. Перезагрузите игру.")
        elseif Stepik == 1 then
		    print("Система определила новые игровые стили. Если хотите изменить рекомендации напишите /recalculate")
		end
    else
        if Stepik == 0 then 
            print("Продолжайте играть для идентификациии игрового стиля") 
		else 
		     print("Продолжая играть ваши рекомендации могут измениться")
		end
    end
end

local function savePlayerDataAsJSON()
    if CoeffOfIdentify < 1 then
        local jsonString = encodeJSON(PlayerData)
        PlayerDataJSON = jsonString  -- сохраняем результат в глобальную переменную

        -- Выводим в чат для наглядности
        print("|cff00ff00[PlayersData]|r Сериализовано в JSON:")
        print(jsonString)
	end
        NormalizePlayerData()
end

local DungeonsAndRaids = {
    "Искроварня",
    "Расселина Темного Пламени",
    "Приорат Священного Пламени",
    "Каменный Свод",
    "Гнездовье",
    "Сияющий Рассвет",
    "Город Нитей",
    "Ара-Кара, Город Отголосков",
    "Неруб'арский Дворец"
}

local Professions =   		
{
    "Сбор трав",
    "Снятие шкур",
    "Горное дело",
    "Горное дело Каз Алгара",
    "Рыбная ловля"
}

local AllNeedsEvents = {}

local startTime = 0
local currentInstName = nil
local currentDiff = nil
local currentInstType = nil


local function IsCurrentProffesion(SpellName)
    for _, profa in ipairs(Professions) do
        if profa == SpellName then
            return true
        end
    end
    return false
end

local function IsDungeonOrRaid(instanceName)
    for _, dungeon in ipairs(DungeonsAndRaids) do
        if dungeon == instanceName then
            return true
        end
    end
    return false
end


local function DungeonRaidCheck()
    local isInstance, instanceType = IsInInstance()
    if isInstance and (instanceType == "raid" or instanceType == "party") then
        local name, _, _, diffname = GetInstanceInfo()
        
        if currentInstName then
            local elapsedTime = GetTime() - startTime
            PlayerData["Эпохальный"] = PlayerData["Эпохальный"] + (elapsedTime / 60)
            savePlayerDataAsJSON()
        end
        
        if not IsDungeonOrRaid(name) then
            return
        end


        startTime = GetTime()
        currentInstName = name
        currentDiff = diffname
        currentInstType = instanceType
        print(name, diffname, instanceType, "OPEN") -- DEBUG

    elseif currentInstName then

        local elapsedTime = GetTime() - startTime
        PlayerData["Эпохальный"] = PlayerData["Эпохальный"] + (elapsedTime / 60)

        currentInstName = nil
        currentDiff = nil
        currentInstType = nil
        savePlayerDataAsJSON()
    end
end

function AllNeedsEvents.ZONE_CHANGED_NEW_AREA(...)
    DungeonRaidCheck()
end

function AllNeedsEvents.ZONE_CHANGED(...)

end

function AllNeedsEvents.COMBAT_LOG_EVENT_UNFILTERED(...)
    local timestamp, subevent, hideCaster,
          sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
          destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()

    if subevent == "PARTY_KILL" and sourceGUID == UnitGUID("player") then

        if bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0 then
            PlayerData["Kills"] = PlayerData["Kills"] + 1
            savePlayerDataAsJSON()
        end
    end
end



function AllNeedsEvents.UNIT_SPELLCAST_SUCCEEDED(unitID, castGUID, spellID)
        name = C_Spell.GetSpellName(spellID)
        if IsCurrentProffesion(name) then
            PlayerData["Stones,Grass,Meals and etc."] = PlayerData["Stones,Grass,Meals and etc."] + 1
            savePlayerDataAsJSON()
		end
end

function AllNeedsEvents.ADDON_LOADED()
    if Stepik == 1 and AlreadyDeleted == false then
	    PlayerData = {
        ["time_in_dungeons"]  = 0,
        ["Kills"]       = 0,
        ["Messages"]    = 0,
        ["Stones,Grass,Meals and etc."] = 0
        }
        CoeffOfIdentify = 0
        AlreadyDeleted = true
    end
end



function AllNeedsEvents.GROUP_ROSTER_UPDATE(...)
    savePlayerDataAsJSON()
end


hooksecurefunc("SendChatMessage", function(msg, chatType, language, channel)
    PlayerData["Messages"] = PlayerData["Messages"] + 1;
    savePlayerDataAsJSON()
end)



function AllNeedsEvents.PLAYER_LOGOUT()
    playerExitedGame = true
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("CHAT_MSG_WHISPER")          
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("ZONE_CHANGED")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("LOOT_OPENED")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
frame:RegisterEvent("PLAYER_LOGOUT")

frame:SetScript("OnEvent", function(self, event, ...)
    if AllNeedsEvents[event] then
        AllNeedsEvents[event](...)
    end
end)

SLASH_SAVE1 = "/save"
SlashCmdList["SAVE"] = function(msg)
    print(Stepik)
    print(CoeffOfIdentify)
end


local function sendReloadMessage()
    print("Перезагрузите игру") 
end

SLASH_RESET1 = "/reset"
SlashCmdList["RESET"] = function(msg)
    Stepik = 0
    PlayerData = {
        ["time_in_dungeons"]  = 0,
        ["Kills"]       = 0,
        ["Messages"]    = 0,
        ["Stones,Grass,Meals and etc."] = 0
    }
    CoeffOfIdentify = 0
    AlreadyDeleted = false
    C_Timer.NewTicker(1, sendReloadMessage)
end

SLASH_RECALCULATE1 = "/recalculate"
SlashCmdList["RECALCULATE"] = function(msg)
    if CoeffOfIdentify >= 1 and Stepik == 1 then
        Stepik = 2
        C_Timer.NewTicker(1, sendReloadMessage)
        AlreadyDeleted = false
    end
end




