-- MyAddon.lua — All Sections in One Window (No Tabs) – Including Killers Category with Fixed Gray Background
local addonName, addon = ...

-- Forward declaration функции, чтобы она была доступна в других функциях
local CreateListElements

-- Reference to main frame и его содержимого
local FRAME_CONTENT = MyAddonFrameScrollFrameContent
local TT = Routes and Routes:GetModule("TomTom") -- Проверка на наличие TomTom

identifyCoef = identifyCoef or 0

-- Backdrop для главного окна
local backdropInfo = {
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile     = true,
    tileSize = 32,
    edgeSize = 32,
    insets   = { left = 11, right = 12, top = 12, bottom = 11 }
}

playerTypeData = playerTypeData or {
    ["Explorers"] = 25,
    ["Achievers"] = 25,
    ["Killers"] = 25,
    ["Socializers"] = 25,
}

local totalActivities = 10

userCoefficients = userCoefficients or {
    goal = 0,
    slozhnost = 0,
    communication = 0,
}
completedTasks = completedTasks or {}

-- Функция вычисления рейтинговой оценки для активности
local function ComputeActivityScore(activity, category)
    local score = (activity.goal * userCoefficients.goal +
                   activity.slozhnost * userCoefficients.slozhnost +
                   activity.communication * userCoefficients.communication)
    return score
end

-- Сортировка активностей по рейтингу в категории
local function SortActivitiesByRating(activityList, category)
    local sorted = {}
    for i, act in ipairs(activityList) do
        if act.goal and act.slozhnost and act.communication then
            act.score = ComputeActivityScore(act, category)
        else
            act.score = 0
        end
        table.insert(sorted, act)
    end
    table.sort(sorted, function(a, b) return a.score > b.score end)
    return sorted
end

-- Функция генерации уникального идентификатора для задания
local function getTaskUID(task)
    if task.zone and task.name then
        return "exp-" .. task.zone .. "-" .. task.name
    elseif task.id then
        if task.difficulty then
            return "inst-" .. task.id .. "-" .. task.difficulty
        elseif task.pvp then
            return "pvp-" .. task.id
        else
            return "ach-" .. task.id
        end
    else
        return task.name
    end
end

-- Пример списков данных
local instanceList = {
    { id = 1267, name = "Приорат Священного Пламени", difficulty = 1, isRaid = false, goal = 4, slozhnost = 2, communication = 3 },
    { id = 1269, name = "Каменный Свод", difficulty = 1, isRaid = false, goal = 4, slozhnost = 2, communication = 3 },
    { id = 1268, name = "Гнездье", difficulty = 1, isRaid = false, goal = 4, slozhnost = 2, communication = 3 },
    { id = 1278, name = "Каз Алгар", difficulty = 0, isRaid = true, goal = 6, slozhnost = 4, communication = 5 },
    { id = 1273, name = "Неруб'арский Дворец", difficulty = 14, isRaid = true, goal = 6, slozhnost = 4, communication = 6},
    { id = 1210, name = "Расселина Темного Пламени", difficulty = 1, isRaid = false, goal = 4, slozhnost = 2, communication = 3 },
    { id = 1271, name = "Ара-Кара, Город Отголосков", difficulty = 1, isRaid = false, goal = 4, slozhnost = 2, communication = 3 },
    { id = 1270, name = "Сияющий Рассвет", difficulty = 1, isRaid = false, goal = 4, slozhnost = 2, communication = 3 },
    { id = 1272, name = "Искроварня", difficulty = 1, isRaid = false, goal = 4, slozhnost = 2, communication = 3 },
    { id = 1274, name = "Город Нитей", difficulty = 1, isRaid = false, goal = 4, slozhnost = 2, communication = 3 },
    -- Heroic
    { id = 1267, name = "Приорат Священного Пламени", difficulty = 2, isRaid = false, goal = 5, slozhnost = 4, communication = 4},
    { id = 1269, name = "Каменный Свод", difficulty = 2, isRaid = false, goal = 5, slozhnost = 4, communication = 4 },
    { id = 1268, name = "Гнездоье", difficulty = 2, isRaid = false, goal = 5, slozhnost = 4, communication = 4 },
    { id = 1273, name = "Неруб'арский Дворец", difficulty = 15, isRaid = true, goal = 8, slozhnost = 8, communication = 7 },
    { id = 1210, name = "Расселина Темного Пламени", difficulty = 2, isRaid = false, goal = 5, slozhnost = 4, communication = 4 },
    { id = 1271, name = "Ара-Кара, Город Отголосков", difficulty = 2, isRaid = false, goal = 5, slozhnost = 4, communication = 4 },
    { id = 1270, name = "Сияющий Рассвет", difficulty = 2, isRaid = false, goal = 5, slozhnost = 4, communication = 4 },
    { id = 1272, name = "Искроварня", difficulty = 2, isRaid = false, goal = 5, slozhnost = 4, communication = 4 },
    { id = 1274, name = "Город Нитей", difficulty = 2, isRaid = false, goal = 5, slozhnost = 4, communication = 4 },
    -- Epic
    { id = 1267, name = "Приорат Священного Пламени", difficulty = 23, isRaid = false, goal = 8, slozhnost = 7, communication = 10 },
    { id = 1269, name = "Каменный Свод", difficulty = 23, isRaid = false, goal = 8, slozhnost = 7, communication = 10 },
    { id = 1268, name = "Гнездье", difficulty = 23, isRaid = false, goal = 8, slozhnost = 7, communication = 10 },
    { id = 1273, name = "Неруб'арский Дворец", difficulty = 16, isRaid = true, goal = 10, slozhnost = 9, communication = 8 },
    { id = 1210, name = "Расселина Темного Пламени", difficulty = 23, isRaid = false, goal = 8, slozhnost = 7, communication = 10 },
    { id = 1271, name = "Ара-Кара, Город Отголосков", difficulty = 23, isRaid = false, goal = 8, slozhnost = 7, communication = 10 },
    { id = 1270, name = "Сияющий Рассвет", difficulty = 23, isRaid = false, goal = 8, slozhnost = 9, communication = 7 },
    { id = 1272, name = "Искроварня", difficulty = 23, isRaid = false, goal = 8, slozhnost = 7, communication = 10 },
    { id = 1274, name = "Город Нитей", difficulty = 23, isRaid = false, goal = 8, slozhnost = 7, communication = 10 },
}

local achievementList = {
    { id = 40138, name = "Master of Algar Dungeons", goal = 7, slozhnost = 6, communication = 7 },
    { id = 40140, name = "Algar Dungeon Healer", goal = 5, slozhnost = 4, communication = 6 },
    { id = 40141, name = "Algar Dungeon Tank", goal = 5, slozhnost = 4, communication = 6 },
    { id = 40604, name = "Epic Mode: Radiant Dawn", goal = 3, slozhnost = 3, communication = 5 },
    { id = 40139, name = "Algar Dungeon Fighter", goal = 5, slozhnost = 4, communication = 6 },
    { id = 40643, name = "Stone Vault", goal = 1, slozhnost = 1, communication = 3 },
    { id = 40590, name = "Priory of the Sacred Flame", goal = 1, slozhnost = 1, communication = 3 },
    { id = 40379, name = "Epic Mode: City of Threads", goal = 3, slozhnost = 3, communication = 5 },
    { id = 40637, name = "Heroic Mode: Nest", goal = 2, slozhnost = 2, communication = 4 },
    { id = 40621, name = "Nest", goal = 1, slozhnost = 1, communication = 3 },
    { id = 40648, name = "Epic Mode: Stone Vault", goal = 3, slozhnost = 3, communication = 5 },
    { id = 40363, name = "Heroic Mode: Spark Furnace", goal = 2, slozhnost = 2, communication = 4 },
    { id = 40375, name = "Epic Mode: Ara-Kara, City of Echoes", goal = 3, slozhnost = 3, communication = 5 },
    { id = 40642, name = "Epic Mode: Nest", goal = 3, slozhnost = 3, communication = 5 },
    { id = 40428, name = "Heroic Mode: Chasm of Dark Flame", goal = 2, slozhnost = 2, communication = 4 },
    { id = 40361, name = "Spark Furnace", goal = 1, slozhnost = 1, communication = 3 },
    { id = 40429, name = "Epic Mode: Chasm of Dark Flame", goal = 3, slozhnost = 3, communication = 5 },
    { id = 40601, name = "Heroic Mode: Radiant Dawn", goal = 2, slozhnost = 2, communication = 4 },
    { id = 40427, name = "Chasm of Dark Flame", goal = 1, slozhnost = 1, communication = 3 },
    { id = 40376, name = "City of Threads", goal = 1, slozhnost = 1, communication = 3 },
    { id = 40592, name = "Priory of the Sacred Flame (Heroic)", goal = 2, slozhnost = 2, communication = 4 },
    { id = 40599, name = "Radiant Dawn", goal = 1, slozhnost = 1, communication = 3 },
    { id = 40374, name = "Heroic Mode: Ara-Kara, City of Echoes", goal = 1, slozhnost = 1, communication = 3 },
    { id = 40366, name = "Epic Mode: Spark Furnace", goal = 3, slozhnost = 3, communication = 5 },
    { id = 40377, name = "Heroic Mode: City of Threads", goal = 2, slozhnost = 2, communication = 4 },
    { id = 40596, name = "Epic Mode: Priory of the Sacred Flame", goal = 3, slozhnost = 3, communication = 5 },
    { id = 40370, name = "Ara-Kara, City of Echoes", goal = 1, slozhnost = 1, communication = 3 },
    { id = 40644, name = "Heroic Mode: Stone Vault", goal = 3, slozhnost = 3, communication = 5 },
    { id = 40730, name = "Love Nest", goal = 4, slozhnost = 5, communication = 6 },
    { id = 40262, name = "Kavabanga", goal = 4, slozhnost = 6, communication = 6 },
    { id = 40261, name = "Slippery but Useful", goal = 4, slozhnost = 6, communication = 6},
    { id = 40260, name = "I'm Invisible", goal = 3, slozhnost = 6, communication = 6 },
    { id = 40263, name = "Would You Love Me if I Were a Worm...", goal = 4, slozhnost = 6, communication = 7 },
    { id = 40266, name = "Close Call", goal = 5, slozhnost = 7, communication = 7 },
    { id = 40264, name = "Murder Series", goal = 4, slozhnost = 3, communication = 6 },
    { id = 40255, name = "Sik'ran's Wound", goal = 3, slozhnost = 4, communication = 5 },
    { id = 40243, name = "Epic Mode: Queen Ansurak", goal = 8, slozhnost = 8, communication = 8 },
    { id = 40247, name = "Prowess of the Roaming Paws", goal = 4, slozhnost = 6, communication = 7 },
    { id = 40242, name = "Epic Mode: Silk Palace", goal = 7, slozhnost = 7, communication = 8 },
    { id = 40246, name = "Epic Mode: Nerub'ar Palace", goal = 9, slozhnost = 9, communication = 10},
    { id = 40249, name = "Falling of the Queen", goal = 5, slozhnost = 6, communication = 7 },
    { id = 40245, name = "Heroic Mode: Nerub'ar Palace", goal = 7, slozhnost = 7, communication = 7 },
    { id = 40244, name = "Nerub'ar Palace", goal = 6, slozhnost = 6, communication = 6 },
    { id = 40239, name = "Epic Mode: Rasha'naan", goal = 8, slozhnost = 7, communication = 7 },
    { id = 40241, name = "Epic Mode: Princess Nexusa", goal = 7, slozhnost = 7, communication = 8 },
    { id = 40236, name = "Epic Mode: Ulgrak the Devourer", goal = 8, slozhnost = 7, communication = 7 },
    { id = 40237, name = "Epic Mode: Bloodbound Horror", goal = 7, slozhnost = 9, communication = 8 },
    { id = 40248, name = "Secrets of Nerub'ar Palace", goal = 4, slozhnost = 5, communication = 5 },
    { id = 40240, name = "Epic Mode: Ovinax Egg Twister", goal = 7, slozhnost = 7, communication = 7 },
    { id = 40238, name = "Epic Mode: Captain Suraki Sik'ran", goal = 7, slozhnost = 8, communication = 7 },
}

local explorerRoutes = {
    { zone = 2214, name = "The Ringing Deeps- Long Route", routeKey = "The Ringing Deeps- Long Route - ShyRaiGaming", goal = 3, slozhnost = 5, communication = 1 },
    { zone = 2215, name = "Hollowfall - ShortRoute", routeKey = "Hallowfall - Short Route - ShyRaiGaming", goal = 3, slozhnost = 4, communication = 1 },
    { zone = 2255, name = "Azj-Kahet - Short Route", routeKey = "Azj-Kahet - Short Route - ShyRaiGaming", goal = 5, slozhnost = 6, communication = 1},
    { zone = 2255, name = "Azj-Kahet - Long Route", routeKey = "Azj-Kahet - Long Route ShyRaiGaming", goal = 5, slozhnost = 7, communication = 1},
    { zone = 2248, name = "Isle of Dorn - Short Route", routeKey = "Isle of Dorn - Short Route - ShyRaiGaming", goal = 1, slozhnost = 1, communication = 1 },
    { zone = 2248, name = "Isle of Dorn - Long Route", routeKey = "Isle of Dorn - Long Route - ShyRaiGaming", goal = 2, slozhnost = 1, communication = 1 },
    { zone = 2248, name = "Hollowfall - LongRoute", routeKey = "Short Version2 - xScarlife Gaming", goal = 4, slozhnost = 5, communication = 1 },
}

local killerActivities = {
    { id = 1, name = "Случайные поля боя (не рейтинг)", pvp = true, pvpType = "battleground", goal = 4, slozhnost = 3, communication = 2 },
    { id = 2, name = "Случайное эпическое поле боя (не рейтинг)", pvp = true, pvpType = "battleground", goal = 5, slozhnost = 2, communication = 1 },
    { id = 3, name = "Стычка на арене (не рейтинг)", pvp = true, pvpType = "arena", goal = 3, slozhnost = 5, communication = 2 },
    { id = 4, name = "Соло арена (рейтинг)", pvp = true, pvpType = "arena", goal = 7, slozhnost = 7, communication = 3 },
    { id = 5, name = "Соло поле боя", pvp = true, pvpType = "battleground", goal = 7, slozhnost = 8, communication = 6 },
    { id = 6, name = "2x2 (рейтинг)", pvp = true, pvpType = "arena", goal = 10, slozhnost = 10, communication = 8 },
    { id = 7, name = "3x3 (рейтинг)", pvp = true, pvpType = "arena", goal = 8, slozhnost = 9, communication = 9 },
    { id = 8, name = "10x10 (рейтинг)", pvp = true, pvpType = "battleground", goal = 8, slozhnost = 10, communication = 10 },
}

local transitionPoints = {
    [2214] = {
        [2215] = {
            { x = 0.4072, y = 0.2403, zone = 2214 },
            { x = 0.7889, y = 0.4218, zone = 2215 },
        },
        [2248] = {
            { x = 0.4212, y = 0.2835, zone = 2214 },
            { x = 0.2877, y = 0.3298, zone = 2385 },
            { x = 0.7095, y = 0.7709, zone = 2385 },
            { x = 0.6991, y = 0.3007, zone = 2385 },
            { x = 0.3415, y = 0.5952, zone = 2385 },
            { x = 0.3612, y = 0.8179, zone = 2339 },
        },
    },
    [2215] = {
        [2214] = {
            { x = 0.7807, y = 0.4278, zone = 2215 },
            { x = 0.7889, y = 0.4218, zone = 2215 },
            { x = 0.4072, y = 0.2403, zone = 2214 },
        },
    },
    [2248] = {
        [2214] = {
            { x = 0.3537, y = 0.6032, zone = 2339 },
            { x = 0.4000, y = 0.5990, zone = 2339 },
            { x = 0.4767, y = 0.5964, zone = 2339 },
            { x = 0.5012, y = 0.7129, zone = 2339 },
            { x = 0.2252, y = 0.4427, zone = 2339 },
            { x = 0.3083, y = 0.3107, zone = 2385 },
            { x = 0.4262, y = 0.2836, zone = 2214 },
        },
        [2255] = {
            { x = 0.6391, y = 0.5225, zone = 2339 },
        }
    },
    [2255] = {
         [2248] = {
            { x = 0.5765, y = 0.4130, zone = 2255 },
         },
         [2214] = {
            { x = 0.6563, y = 0.2497, zone = 2255 },
            { x = 0.6995, y = 0.2460, zone = 2255 },
            { x = 0.4253, y = 0.6719, zone = 2214 },
         },
    },
}

local function GetDifficultyName(diff)
    if diff == 0 then
        return ""
    elseif diff == 1 or diff == 14 then
        return "обычный режим"
    elseif diff == 2 or diff == 15 then
        return "героический режим"
    elseif diff == 16 then
        return "эпохальный режим"
    elseif diff == 23 then
        return "эпохальный ключ"
    else
        return tostring(diff)
    end
end

local function ClearFrameContent(frame)
    for i = frame:GetNumChildren(), 1, -1 do
        local child = select(i, frame:GetChildren())
        child:Hide()
        child:SetParent(nil)
    end
end

local surveyStep = 1

local function Recalculate()
    print("Пересчитываем рейтинги активностей с учетом новых коэффициентов...")
    local function updateActivityScores(activityList)
        for _, activity in ipairs(activityList) do
            activity.score = activity.goal * userCoefficients.goal +
                             activity.slozhnost * userCoefficients.slozhnost +
                             activity.communication * userCoefficients.communication
            print(activity.name .. " - новый рейтинг: " .. string.format("%.2f", activity.score))
        end
    end
    updateActivityScores(instanceList)
    updateActivityScores(achievementList)
    updateActivityScores(explorerRoutes)
    updateActivityScores(killerActivities)
    print("Рейтинги пересчитаны.")
end

local function CreateSurveyStep(step)
    local surveyFrame = CreateFrame("Frame", "MySurveyFrame", UIParent, "BackdropTemplate")
    surveyFrame:SetSize(400, 200)
    surveyFrame:SetPoint("CENTER")
    surveyFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    surveyFrame:SetBackdropColor(0.3, 0.3, 0.3, 1) -- Серый фон с полной непрозрачностью
    surveyFrame:SetMovable(true)
    surveyFrame:EnableMouse(true)
    surveyFrame:RegisterForDrag("LeftButton")
    surveyFrame:SetScript("OnDragStart", surveyFrame.StartMoving)
    surveyFrame:SetScript("OnDragStop", surveyFrame.StopMovingOrSizing)

    local title = surveyFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", 0, -10)
    title:SetText("Опрос после завершения активности")

    local questionText, buttons, callback
    if step == 1 then
        questionText = "Насколько вам было сложно ?"
        buttons = {"Было просто", "Нормально", "Хочу легче"}
        callback = function(answer)
            if answer == 1 then
                userCoefficients.slozhnost = math.min(userCoefficients.slozhnost + 0.1, 1)
            elseif answer == 3 then
                userCoefficients.slozhnost = math.max(userCoefficients.slozhnost - 0.1, -1)
            end
        end
    elseif step == 2 then
        questionText = "Хватило ли вам общения ?"
        buttons = {"Нет, хочу больше общения", "Да вполне", "Слишком много, хочу общаться меньше"}
        callback = function(answer)
            if answer == 1 then
                userCoefficients.communication = math.min(userCoefficients.communication + 0.1, 1)
            elseif answer == 3 then
                userCoefficients.communication = math.max(userCoefficients.communication - 0.1, -1)
            end
        end
    elseif step == 3 then
        questionText = "Хватило ли вам соревновательного аспекта ?"
        buttons = {"Нет, хотелось бы больше", "Да вполне", "Слишком много соревнований, я хочу просто чиллить"}
        callback = function(answer)
            if answer == 1 then
                userCoefficients.goal = math.max(userCoefficients.goal - 0.1, -1)
            elseif answer == 3 then
                userCoefficients.goal = math.min(userCoefficients.goal + 0.1, 1)
            end
        end
    end

    local question = surveyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    question:SetPoint("TOP", 0, -40)
    question:SetText(questionText)

    local buttonOffset = -80
    local buttonsTable = {}
    for i, buttonText in ipairs(buttons) do
        local btn = CreateFrame("Button", nil, surveyFrame, "UIPanelButtonTemplate")
        btn:SetSize(400, 30)
        btn:SetPoint("TOP", 0, buttonOffset)
        btn:SetText(buttonText)
        btn:SetScript("OnClick", function()
            callback(i)
            surveyFrame:Hide()
            if surveyStep < 3 then
                surveyStep = surveyStep + 1
                CreateSurveyStep(surveyStep)
            else
                surveyFrame:Hide()
                Recalculate()
                ClearFrameContent(FRAME_CONTENT)
                CreateListElements()
                MyAddonFrame:Show()
            end
        end)
        buttonOffset = buttonOffset - 40
        table.insert(buttonsTable, btn)
    end
    surveyFrame:Show()
end

function StartSurvey()
    surveyStep = 1
    CreateSurveyStep(surveyStep)
end

local function OpenEncounterJournal(instanceID, difficulty)
    local name, _, _, _, _, _, _, link = EJ_GetInstanceInfo(instanceID)
    if not link or link == "" then
        print("No link for instance", instanceID, "or invalid ID.")
        return
    end
    local color = link:match("^|cff(%x%x%x%x%x%x)")
    if not color then
        print("Failed to extract color from link:", link)
        return
    end
    local oldLinkPart, displayName = link:match("|H(.-)|h%[(.-)%]|h")
    if not oldLinkPart or not displayName then
        print("Failed to extract linkPart/displayName from link:", link)
        return
    end
    local prefix, oldDiff = oldLinkPart:match("^(.*):(%d+)$")
    if not prefix or not oldDiff then
        print("Link does not have expected format:", oldLinkPart)
        return
    end
    local newLinkPart = prefix .. ":" .. tostring(difficulty or oldDiff)
    local newFullLink = "|cff" .. color .. "|H" .. newLinkPart .. "|h[" .. displayName .. "]|h|r"
    ChatFrame_OnHyperlinkShow(DEFAULT_CHAT_FRAME, newLinkPart, newFullLink, "LeftButton")
end

local function OpenAchievement(achievementID)
    local achLink = GetAchievementLink(achievementID)
    if achLink then
        if not AchievementFrame then
            AchievementFrame_LoadUI()
        end
        if AchievementFrame_SelectAchievement then
            AchievementFrame:Show()
            AchievementFrame_SelectAchievement(achievementID)
        else
            SetItemRef(achLink, achLink, "LeftButton")
        end
        C_ContentTracking.StartTracking(2, achievementID)
    else
        print("Failed to get achievement link for ID:", achievementID)
    end
end

-- Новая функция для всплывающей инструкции PvP
function ShowPvPGuideFrame(pvpName, pvpType)
    PVEFrame_ShowFrame("PVPUIFrame", HonorFrame) -- Открываем интерфейс PvP
    local guideFrame = CreateFrame("Frame", "MyPvPGuideFrame", UIParent, "BackdropTemplate")
    guideFrame:SetSize(500, 180) -- Увеличиваем высоту для дополнительных инструкций
    guideFrame:SetPoint("TOP", MyAddonFrame, "BOTTOM", 0, -5)
    guideFrame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile     = true,
        tileSize = 32,
        edgeSize = 32,
        insets   = { left = 8, right = 8, top = 8, bottom = 8 },
    })
    guideFrame:SetBackdropColor(0.3, 0.3, 0.3, 1) -- Серый фон с полной непрозрачностью
    guideFrame:SetMovable(true)
    guideFrame:EnableMouse(true)
    guideFrame:RegisterForDrag("LeftButton")
    guideFrame:SetScript("OnDragStart", guideFrame.StartMoving)
    guideFrame:SetScript("OnDragStop", guideFrame.StopMovingOrSizing)

    local text = guideFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("TOP", 0, -14)
    local typeText = "Хз"
    local instruction = ""

    -- Определяем вкладку и инструкции в зависимости от активности
    if pvpName:find("Случайные поля боя") or pvpName:find("Случайные эпические поля боя") or pvpName:find("Стычка на арене") then
        typeText = "Быстрый матч"
        instruction = ("Как присоединиться к '%s':\n1) Открыто окно PvP\n2) Выберите вкладку '%s'\n3) Найдите '%s' в списке\n4) Нажмите 'Вступить в бой'"):format(pvpName, typeText, pvpName)
    elseif pvpName:find("2x2") or pvpName:find("3x3") or pvpName:find("10x10") then
        typeText = "Рейтинговые"
        instruction = ("Как присоединиться к '%s':\n1) Соберите группу или присоединитесь к существующей в \n 'Заранее собранных группах': Выбрав Арены для режима 3x3 и 2x2 \n или Рейтинговые поля боя для 10x10 \n3) Перейдите на вкладку Рейтинговые и выберите '%s'\n4) Нажмите 'Вступить в бой'"):format(pvpName, pvpName, typeText, pvpName)
    elseif pvpName:find("Соло поле боя") or pvpName:find("Соло арена") then
        typeText = "Рейтинговые"
        instruction = ("Как присоединиться к '%s':\n1) Открыто окно PvP\n2) Выберите вкладку '%s'\n3) Найдите '%s' в списке\n4) Нажмите 'Вступить в бой'"):format(pvpName, typeText, pvpName)
    end

    text:SetText(instruction)

    local closeBtn = CreateFrame("Button", nil, guideFrame, "UIPanelButtonTemplate")
    closeBtn:SetSize(80, 22)
    closeBtn:SetPoint("BOTTOM", 0, 10)
    closeBtn:SetText("Закрыть")
    closeBtn:SetScript("OnClick", function() guideFrame:Hide() end)
end

local function OpenPvPInterface(task)
    if task.pvp then
        -- Проверка для рейтинговых активностей 2x2, 3x3, 10x10
        if task.name:find("2x2") or task.name:find("3x3") or task.name:find("10x10") then
            local inParty = UnitInParty("player") -- Проверяем, есть ли игрок в группе
            if not inParty then
                print("Для '" .. task.name .. "' требуется группа! Соберите группу в 'Заранее собранных группах'.")
            end
        end
        ShowPvPGuideFrame(task.name, task.pvpType)
    end
end

function ShowGuideFrame(instanceName, difficulty)
    PVEFrame_ShowFrame("GroupFinderFrame")
    local guideFrame = CreateFrame("Frame", "MyGuideFrame", UIParent, "BackdropTemplate")
    guideFrame:SetSize(500, 140)
    guideFrame:SetPoint("TOP", MyAddonFrame, "BOTTOM", 0, -5)
    guideFrame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile     = true,
        tileSize = 32,
        edgeSize = 32,
        insets   = { left = 8, right = 8, top = 8, bottom = 8 },
    })
    guideFrame:SetBackdropColor(0.3, 0.3, 0.3, 1) -- Серый фон с полной непрозрачностью
    guideFrame:SetMovable(true)
    guideFrame:EnableMouse(true)
    guideFrame:RegisterForDrag("LeftButton")
    guideFrame:SetScript("OnDragStart", guideFrame.StartMoving)
    guideFrame:SetScript("OnDragStop", guideFrame.StopMovingOrSizing)
    local text = guideFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("TOP", 0, -14)
    local type = ""
    if instanceName == "Неруб'арский Дворец" then
        type = "Рейды - The War Within"
    else
        type = "Подземелья"
    end
    local diffName = GetDifficultyName(difficulty)
    local diffText = diffName ~= "" and (" (" .. diffName .. ")") or ""
    text:SetText(
        ("Как найти группу для '%s'%s:\n1) Выберите вкладку 'Заранее собранные группы'\n2) Выберите категорию: %s\n3) Вставьте '%s' в строку поиска\n4) Нажмите 'Искать'")
        :format(instanceName, diffText, type, instanceName)
    )
    local editBox = CreateFrame("EditBox", nil, guideFrame, "InputBoxTemplate")
    editBox:SetSize(400, 20)
    editBox:SetPoint("TOP", text, "BOTTOM", 0, -20)
    editBox:SetAutoFocus(false)
    local combinedText = instanceName
    if diffName ~= "" then
        combinedText = combinedText .. " (" .. diffName .. ")"
    end
    editBox:SetText(combinedText)
    editBox:HighlightText()
    local closeBtn = CreateFrame("Button", nil, guideFrame, "UIPanelButtonTemplate")
    closeBtn:SetSize(80, 22)
    closeBtn:SetPoint("BOTTOM", 0, 10)
    closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function() guideFrame:Hide() end)
end

local function CreateSectionHeading(parent, text, point, relativeTo, offsetX, offsetY)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    header:SetPoint(point, relativeTo, offsetX, offsetY)
    header:SetText(text)
    return header
end

local activeTask = nil
local trackingFrame = nil

local function CancelTaskTracking()

    
    if orderedRouteTicker then
        orderedRouteTicker:Cancel()
        orderedRouteTicker = nil
    end
    if currentOrderedWaypointID then
        TomTom:RemoveWaypoint(currentOrderedWaypointID)
        currentOrderedWaypointID = nil
    end
    
    if TT then TT:RemoveQueuedNode() end

    HideAllRoutes()


    if trackingFrame then
        trackingFrame:Hide()
    end
    activeTask = nil
    MyAddonFrame:Show()
    ClearFrameContent(FRAME_CONTENT)
    CreateListElements()
end

function CompleteTaskTracking()

     if orderedRouteTicker then
        orderedRouteTicker:Cancel()
        orderedRouteTicker = nil
    end
    if currentOrderedWaypointID then
        TomTom:RemoveWaypoint(currentOrderedWaypointID)
        currentOrderedWaypointID = nil
    end
    
    if TT then TT:RemoveQueuedNode() end

    HideAllRoutes()

    if activeTask then
        local uid = getTaskUID(activeTask)
        completedTasks[uid] = true
        print("Задание выполнено: " .. activeTask.name)
    end
    activeTask = nil
    if trackingFrame then
        trackingFrame:Hide()
    end
    StartSurvey()
end

local function StartTaskTracking(task, actionFunc)
    activeTask = task
    MyAddonFrame:Hide()
    if not trackingFrame then
        trackingFrame = CreateFrame("Frame", "MyAddonTrackingFrame", UIParent, "BackdropTemplate")
        trackingFrame:SetSize(250, 70)
        trackingFrame:SetPoint("LEFT", UIParent, "LEFT", 50, 0)
        trackingFrame:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile     = true,
            tileSize = 32,
            edgeSize = 16,
            insets   = { left = 5, right = 5, top = 5, bottom = 5 }
        })
        trackingFrame:SetBackdropColor(0.3, 0.3, 0.3, 1) -- Серый фон с полной непрозрачностью
        trackingFrame.text = trackingFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        trackingFrame.text:SetPoint("TOP", trackingFrame, "TOP", 0, -10)
        
        trackingFrame.cancelBtn = CreateFrame("Button", nil, trackingFrame, "UIPanelButtonTemplate")
        trackingFrame.cancelBtn:SetSize(80, 25)
        trackingFrame.cancelBtn:SetPoint("BOTTOMLEFT", trackingFrame, "BOTTOMLEFT", 10, 10)
        trackingFrame.cancelBtn:SetText("Отменить")
        trackingFrame.cancelBtn:SetScript("OnClick", function()
            CancelTaskTracking()
        end)
        
        trackingFrame.completeBtn = CreateFrame("Button", nil, trackingFrame, "UIPanelButtonTemplate")
        trackingFrame.completeBtn:SetSize(80, 25)
        trackingFrame.completeBtn:SetPoint("BOTTOMRIGHT", trackingFrame, "BOTTOMRIGHT", -10, 10)
        trackingFrame.completeBtn:SetText("Завершено")
        trackingFrame.completeBtn:SetScript("OnClick", function()
            CompleteTaskTracking()
        end)
    end

    trackingFrame.text:SetText("Активное задание: " .. task.name)
    trackingFrame:Show()

    if actionFunc and type(actionFunc) == "function" then
        actionFunc(task)
    end
end

function HideAllRoutes()
    if not (Routes and Routes.db and Routes.db.global and Routes.db.global.routes) then
        return
    end
    for zone, routesTable in pairs(Routes.db.global.routes) do
        for routeKey, routeData in pairs(routesTable) do
            routeData.hidden = true
        end
    end
    if Routes.DrawAllWorldmapLines then Routes:DrawAllWorldmapLines(true) end
    if Routes.DrawMinimapLines then Routes:DrawMinimapLines(true) end
    if Routes.UpdateHiddenRoutes then Routes:UpdateHiddenRoutes() end
end

function UnregisterZoneChangeEvent()
    if zoneChangeFrame then
        zoneChangeFrame:UnregisterEvent("ZONE_CHANGED")
        zoneChangeFrame:SetScript("OnEvent", nil)
        zoneChangeFrame = nil
    end
end

local orderedWaypoints = {}
local currentOrderedIndex = 1
local currentOrderedWaypointID = nil
local orderedRouteTicker = nil
local orderedDistanceThreshold = 0.08

function StartOrderedRoute(waypoints)
    if orderedRouteTicker then
        orderedRouteTicker:Cancel()
        orderedRouteTicker = nil
    end
    if currentOrderedWaypointID then
        TomTom:RemoveWaypoint(currentOrderedWaypointID)
        currentOrderedWaypointID = nil
    end
    orderedWaypoints = waypoints or {}
    currentOrderedIndex = 1
    if #orderedWaypoints == 0 then
        return
    end

    local wp = orderedWaypoints[currentOrderedIndex]
    currentOrderedWaypointID = TomTom:AddWaypoint(wp.zone, wp.x, wp.y, {
        title = "Waypoint " .. currentOrderedIndex,
        persistent = false,
        minimap = true,
        world = true,
    })

    orderedRouteTicker = C_Timer.NewTicker(0.5, function()
        local playerMap = C_Map.GetBestMapForUnit("player")
        if not playerMap then return end
        local playerPos = C_Map.GetPlayerMapPosition(playerMap, "player")
        if not playerPos then return end
        local px, py = playerPos:GetXY()
        local currentWP = orderedWaypoints[currentOrderedIndex]
        if not currentWP then return end
        local dx = currentWP.x - px
        local dy = currentWP.y - py
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist < orderedDistanceThreshold then
            TomTom:RemoveWaypoint(currentOrderedWaypointID)
            currentOrderedIndex = currentOrderedIndex + 1
            if currentOrderedIndex > #orderedWaypoints then
                orderedRouteTicker:Cancel()
                orderedRouteTicker = nil
            else
                local nextWP = orderedWaypoints[currentOrderedIndex]
                currentOrderedWaypointID = TomTom:AddWaypoint(nextWP.zone, nextWP.x, nextWP.y, {
                    title = "Waypoint " .. currentOrderedIndex,
                    persistent = false,
                    minimap = true,
                    world = true,
                })
            end
        end
    end)
end

local function ActivateMultiZoneRoute(routeData)
    if orderedRouteTicker then
        orderedRouteTicker:Cancel()
        orderedRouteTicker = nil
    end
    if currentOrderedWaypointID then
        TomTom:RemoveWaypoint(currentOrderedWaypointID)
        currentOrderedWaypointID = nil
    end
    orderedWaypoints = {}
    currentOrderedIndex = 1

    local targetZone = routeData.zone
    local currentZone = C_Map.GetBestMapForUnit("player") or 0
    if TT then TT:RemoveQueuedNode() end
    HideAllRoutes()
    if Routes and Routes.db and Routes.db.global and Routes.db.global.routes[targetZone] and Routes.db.global.routes[targetZone][routeData.routeKey] then
        Routes.db.global.routes[targetZone][routeData.routeKey].hidden = false
        if Routes.DrawAllWorldmapLines then
            Routes:DrawAllWorldmapLines(true)
        elseif Routes.DrawWorldmapLines then
            Routes:DrawWorldmapLines(true)
        end
        print("Route '" .. routeData.name .. "' is now visible.")
    else
        print("Route not found in Routes:", targetZone, routeData.routeKey)
        return
    end

    if currentZone == targetZone then
        if TT then 
            TT:QueueFirstNode() 
        end
    else
        local zoneTransitions = transitionPoints[currentZone] or {}
        local points = zoneTransitions[targetZone]
        if not points or #points == 0 then
            return
        end

        StartOrderedRoute(points)

        zoneChangeFrame = CreateFrame("Frame")
        zoneChangeFrame:RegisterEvent("ZONE_CHANGED")
        zoneChangeFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        zoneChangeFrame:SetScript("OnEvent", function(self, event, ...)
            local newZone = C_Map.GetBestMapForUnit("player") or 0
            if newZone == targetZone then
                if Routes and Routes.db and Routes.db.global and Routes.db.global.routes[targetZone] and Routes.db.global.routes[targetZone][routeData.routeKey] then
                    if orderedRouteTicker then
                        orderedRouteTicker:Cancel()
                        orderedRouteTicker = nil
                    end
                    if currentOrderedWaypointID then
                        TomTom:RemoveWaypoint(currentOrderedWaypointID)
                        currentOrderedWaypointID = nil
                    end
                    orderedWaypoints = {}
                    currentOrderedIndex = 1
                    if TT then TT:QueueFirstNode() end
                end
                self:UnregisterEvent("ZONE_CHANGED")
                self:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
            end
        end)
    end
end

local function IsTaskCompleted(task)
    return completedTasks[getTaskUID(task)] == true
end

CreateListElements = function()
    local yOffset = 10
    HideAllRoutes()

    local countInvestigator = math.floor(totalActivities * playerTypeData["Explorers"] / 100 + 0.5)
    local countAchiever = math.floor(totalActivities * playerTypeData["Achievers"] / 100 + 0.5)
    local countKiller = math.floor(totalActivities * playerTypeData["Killers"] / 100 + 0.5)
    local countSocial = totalActivities - countInvestigator - countAchiever - countKiller

    --------------------------------------------------
    -- Socializer (Подземелья)
    --------------------------------------------------
    local headerSocial = CreateSectionHeading(FRAME_CONTENT, "Socializer", "TOPLEFT", FRAME_CONTENT, 0, -yOffset)
    local resetBtn = CreateFrame("Button", nil, FRAME_CONTENT, "UIPanelButtonTemplate")
    resetBtn:SetSize(120, 20)
    resetBtn:SetPoint("TOPLEFT", headerSocial, "TOPRIGHT", 10, 0)
    resetBtn:SetText("Reset Socializer")
    resetBtn:SetScript("OnClick", function()
        for _, task in ipairs(instanceList) do
            local uid = getTaskUID(task)
            if uid:find("^inst%-") then
                completedTasks[uid] = nil
            end
        end
        ClearFrameContent(FRAME_CONTENT)
        CreateListElements()
    end)
    yOffset = yOffset + 30
    local sortedSocial = SortActivitiesByRating(instanceList, "socializer")
    local filteredSocial = {}
    for i, task in ipairs(sortedSocial) do
        if not IsTaskCompleted(task) then
            table.insert(filteredSocial, task)
        end
    end
    for i = 1, math.min(countSocial, #filteredSocial) do
        local btn = CreateFrame("Button", nil, FRAME_CONTENT)
        btn:SetSize(400, 20)
        btn:SetPoint("TOPLEFT", headerSocial, "BOTTOMLEFT", 0, -((i - 1) * 25))
        local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        txt:SetPoint("LEFT")
        local diffName = GetDifficultyName(filteredSocial[i].difficulty)
        local diffText = (filteredSocial[i].difficulty ~= 0 and diffName ~= "" and " (" .. diffName .. ")") or ""
        local label = filteredSocial[i].name .. diffText .. " - Score: " .. string.format("%.2f", filteredSocial[i].score)
        if filteredSocial[i].isRaid then
            label = label .. " (Raid)"
        else
            label = label .. " (Dungeon)"
        end
        txt:SetText(label)
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Click to open Encounter Journal\nand view group-finder instructions.")
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        btn:SetScript("OnClick", function()
            StartTaskTracking(filteredSocial[i], function(task)
                OpenEncounterJournal(task.id, task.difficulty)
                ShowGuideFrame(task.name, task.difficulty)
            end)
        end)
    end
    yOffset = yOffset + (countSocial * 25) + 20

    --------------------------------------------------
    -- Achiever (Достижения)
    --------------------------------------------------
    local headerAch = CreateSectionHeading(FRAME_CONTENT, "Achiever", "TOPLEFT", FRAME_CONTENT, 0, -yOffset)
    yOffset = yOffset + 30
    local sortedAch = SortActivitiesByRating(achievementList, "achiever")
    local filteredAch = {}
    for i, task in ipairs(sortedAch) do
        local _, _, _, completed = GetAchievementInfo(task.id)
        if not completed and not IsTaskCompleted(task) then
            table.insert(filteredAch, task)
        end
    end
    for i = 1, math.min(countAchiever, #filteredAch) do
        local btn = CreateFrame("Button", nil, FRAME_CONTENT)
        btn:SetSize(400, 20)
        btn:SetPoint("TOPLEFT", headerAch, "BOTTOMLEFT", 0, -((i - 1) * 25))
        local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        txt:SetPoint("LEFT")
        txt:SetText(filteredAch[i].name .. " - Score: " .. string.format("%.2f", filteredAch[i].score))
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Click to open Achievements and start tracking.")
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        btn:SetScript("OnClick", function()
            StartTaskTracking(filteredAch[i], function(task)
                OpenAchievement(task.id)
            end)
        end)
    end
    yOffset = yOffset + (countAchiever * 25) + 20

    --------------------------------------------------
    -- Investigator (Маршруты-исследователи)
    --------------------------------------------------
    local headerInv = CreateSectionHeading(FRAME_CONTENT, "Investigator", "TOPLEFT", FRAME_CONTENT, 0, -yOffset)
    yOffset = yOffset + 30
    local sortedInv = SortActivitiesByRating(explorerRoutes, "investigator")
    local filteredInv = sortedInv
    for i = 1, math.min(countInvestigator, #filteredInv) do
        local btn = CreateFrame("Button", nil, FRAME_CONTENT)
        btn:SetSize(400, 20)
        btn:SetPoint("TOPLEFT", headerInv, "BOTTOMLEFT", 0, -((i - 1) * 25))
        local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        txt:SetPoint("LEFT")
        txt:SetText(filteredInv[i].name .. " - Score: " .. string.format("%.2f", filteredInv[i].score))
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Click to activate the route.\nTransition waypoints will be used if necessary.")
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        btn:SetScript("OnClick", function()
            StartTaskTracking(filteredInv[i], function(task)
                ActivateMultiZoneRoute(task)
            end)
        end)
    end
    yOffset = yOffset + (countInvestigator * 25) + 20

    --------------------------------------------------
    -- Killers (PvP и боевые активности)
    --------------------------------------------------
    local headerKill = CreateSectionHeading(FRAME_CONTENT, "Killers", "TOPLEFT", FRAME_CONTENT, 0, -yOffset)
    yOffset = yOffset + 30
    local sortedKill = SortActivitiesByRating(killerActivities, "killers")
    local filteredKill = {}
    for i, task in ipairs(sortedKill) do
        if not IsTaskCompleted(task) then
            table.insert(filteredKill, task)
        end
    end
    for i = 1, math.min(countKiller, #filteredKill) do
        local btn = CreateFrame("Button", nil, FRAME_CONTENT)
        btn:SetSize(400, 20)
        btn:SetPoint("TOPLEFT", headerKill, "BOTTOMLEFT", 0, -((i - 1) * 25))
        local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        txt:SetPoint("LEFT")
        txt:SetText(filteredKill[i].name .. " - Score: " .. string.format("%.2f", filteredKill[i].score))
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Click to open PvP interface and view instructions.")
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        btn:SetScript("OnClick", function()
            StartTaskTracking(filteredKill[i], function(task)
                OpenPvPInterface(task)
            end)
        end)
    end
    yOffset = yOffset + (countKiller * 25) + 20

    -- Установка высоты контента
    FRAME_CONTENT:SetHeight(yOffset)
end

-- On ADDON_LOADED: Инициализация MyAddonFrame и создание UI
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, name)
    if name == addonName then
        MyAddonFrame:SetWidth(550)
        MyAddonFrame:SetHeight(400)
        MyAddonFrame:ClearAllPoints()
        MyAddonFrame:SetPoint("CENTER")
        if not MyAddonFrame.SetBackdrop then
            Mixin(MyAddonFrame, BackdropTemplateMixin)
        end
        MyAddonFrame:SetBackdrop(backdropInfo)
        
        print(identifyCoef)
        if identifyCoef == 0 then
            completedTasks = {}
            userCoefficients.goal = 0
            userCoefficients.slozhnost = 0
            userCoefficients.communication = 0
        end
            
        if userCoefficients.goal == 0 and userCoefficients.slozhnost == 0 and userCoefficients.communication == 0 and identifyCoef >= 1 then
            userCoefficients.goal = playerTypeData["Killers"] * 0.01 + playerTypeData["Socializers"] * 0.5 * 0.01 + playerTypeData["Achievers"] * (-0.5) * 0.01 + playerTypeData["Explorers"] * (-1) * 0.01
            userCoefficients.slozhnost = playerTypeData["Achievers"] * 0.01 + playerTypeData["Killers"] * 0.5 * 0.01 + playerTypeData["Socializers"] * (-0.5) * 0.01 + playerTypeData["Explorers"] * (-1) * 0.01
            userCoefficients.communication = playerTypeData["Socializers"] * 0.01 + playerTypeData["Achievers"] * 0.5 * 0.01 + playerTypeData["Explorers"] * (-0.5) * 0.01 + playerTypeData["Killers"] * (-1) * 0.01
        end
        CreateListElements()
        MyAddonFrame:Show()
        if identifyCoef < 1 and identifyCoef ~= 1 then
            MyAddonFrame:SetShown(not MyAddonFrame:IsShown())
        end
    end
end)

-- Слэш-команды
SLASH_MYADDON1 = "/myaddon"
SlashCmdList["MYADDON"] = function()
    if identifyCoef >= 1 then
        MyAddonFrame:SetShown(not MyAddonFrame:IsShown())
	end
end

SLASH_MYADDONCOMPLETED1 = "/myaddoncompleted"
SlashCmdList["MYADDONCOMPLETED"] = function()
    print("Выполненные задания:")
    for uid, _ in pairs(completedTasks) do
        print(uid)
    end
end

function MyAddonFrameScrollFrame_OnVerticalScroll(self, offset)
    self:SetVerticalScroll(offset)
end

SLASH_OPENDANJ1 = "/opendanj"
SlashCmdList["OPENDANJ"] = function(msg)
    print(C_Map.GetBestMapForUnit("player"))
end

SLASH_OPENACH1 = "/openach"
SlashCmdList["OPENACH"] = function(msg)
    print(userCoefficients.goal, userCoefficients.slozhnost, userCoefficients.communication)
end

SLASH_SHOWGUIDE1 = "/showguide"
SlashCmdList["SHOWGUIDE"] = function(msg)
    local raidName = msg ~= "" and msg or "Ice Throne"
    ShowGuideFrame(raidName, 2)
end