-- Azeroth Original: troca nomes de lugares em PT-BR pelos originais em inglês
-- no texto de missões, diálogos de NPC (gossip), Talking Head e falas de NPC no chat.
local ADDON, ns = ...

----------------------------------------------------------------------
-- Índice: primeira palavra -> lista de candidatos (mais longos primeiro)
----------------------------------------------------------------------
local byte, sub, find = string.byte, string.sub, string.find
local index = {}
local total = 0

local function isLetter(b)
    -- letras ASCII ou qualquer byte de caractere UTF-8 (acentos)
    return b and ((b >= 65 and b <= 90) or (b >= 97 and b <= 122) or b >= 128)
end

local function firstWord(s)
    local j = 1
    while j <= #s and isLetter(byte(s, j)) do j = j + 1 end
    return sub(s, 1, j - 1)
end

local function add(pt, en)
    if ns.ignorar and ns.ignorar[pt] then return end
    if type(pt) ~= "string" or type(en) ~= "string" or pt == en or pt == "" then return end
    if not isLetter(byte(pt, 1)) then return end
    local w = firstWord(pt)
    if w == "" then return end
    local list = index[w]
    if not list then list = {}; index[w] = list end
    list[#list + 1] = { pt = pt, en = en, len = #pt }
    total = total + 1
end

local ARTIGOS = { O = true, A = true, Os = true, As = true }

local function buildIndex()
    wipe(index); total = 0
    local merged = {}
    for pt, en in pairs(ns.data or {}) do merged[pt] = en end
    -- "A Vila de Brisabela": também casa "na Vila de Brisabela" (sem o artigo)
    local semArtigo = {}
    for pt, en in pairs(merged) do
        local art, resto = pt:match("^(%a+) (.+)$")
        if art and ARTIGOS[art] then
            if ns.ignorar and ns.ignorar[resto] then
                merged[pt] = nil                       -- "O Refúgio" etc.
            elseif not merged[resto] then
                semArtigo[resto] = (en:gsub("^The ", ""))
            end
        end
    end
    for pt, en in pairs(semArtigo) do merged[pt] = en end
    for pt, en in pairs(ns.extra or {}) do merged[pt] = en end
    for pt, en in pairs(merged) do add(pt, en) end
    for _, list in pairs(index) do
        table.sort(list, function(a, b) return a.len > b.len end)
    end
end

----------------------------------------------------------------------
-- Tradução de uma string (respeita códigos de cor, links e ícones)
----------------------------------------------------------------------
local function skipEscape(text, i, n)
    -- text[i] == "|"; retorna a posição logo após o código de escape
    local c = sub(text, i + 1, i + 1)
    if c == "c" then
        if sub(text, i + 2, i + 2) == "n" then          -- |cnNOME_DA_COR:
            local e = find(text, ":", i + 3, true)
            return e and e + 1 or i + 2
        end
        return i + 10                                    -- |cAARRGGBB
    elseif c == "H" then                                 -- |H<payload>|h
        local e = find(text, "|h", i + 2, true)
        return e and e + 2 or i + 2
    elseif c == "T" then                                 -- |T...|t textura
        local e = find(text, "|t", i + 2, true)
        return e and e + 2 or i + 2
    elseif c == "A" then                                 -- |A...|a atlas
        local e = find(text, "|a", i + 2, true)
        return e and e + 2 or i + 2
    elseif c == "K" then                                 -- |K...|k nome protegido
        local e = find(text, "|k", i + 2, true)
        return e and e + 2 or i + 2
    end
    return i + 2                                         -- |r, |n, |h, ||, etc.
end

local PREPS = {}
for w in ("o a os as no na nos nas do da dos das ao aos pelo pela pelos pelas num numa "
       .. "\195\160 \195\160s"):gmatch("%S+") do PREPS[w] = true end   -- à, às

local function Translate(text)
    if type(text) ~= "string" or text == "" then return text end
    if issecretvalue and issecretvalue(text) then return text end
    local n = #text
    local out, o = nil, 0
    local i, copyFrom = 1, 1
    local prevLetter = false
    while i <= n do
        local b = byte(text, i)
        if b == 124 then -- "|"
            i = skipEscape(text, i, n)
            prevLetter = false
        elseif isLetter(b) then
            if prevLetter then
                i = i + 1
            else
                local j = i
                while j <= n and isLetter(byte(text, j)) do j = j + 1 end
                local cands = index[sub(text, i, j - 1)]
                local hit
                if cands then
                    for k = 1, #cands do
                        local c = cands[k]
                        if sub(text, i, i + c.len - 1) == c.pt and not isLetter(byte(text, i + c.len)) then
                            hit = c; break
                        end
                    end
                end
                if hit then
                    out = out or {}
                    out[o + 1] = sub(text, copyFrom, i - 1)
                    local en = hit.en
                    -- "as The Hinterlands" -> "as Hinterlands" quando já há artigo/contração antes
                    if sub(en, 1, 4) == "The " then
                        local antes = sub(text, 1, i - 1):match("(%S+)%s+$")
                        if antes and PREPS[antes:lower()] then en = sub(en, 5) end
                    end
                    out[o + 2] = en
                    o = o + 2
                    i = i + hit.len
                    copyFrom = i
                    prevLetter = true
                else
                    i = j
                    prevLetter = true
                end
            end
        else
            prevLetter = false
            i = i + 1
        end
    end
    if not out then return text end
    out[o + 1] = sub(text, copyFrom)
    return table.concat(out)
end
ns.Translate = Translate

----------------------------------------------------------------------
-- Aplicação nos quadros da interface
----------------------------------------------------------------------
local function enabled() return AzerothOriginalDB and AzerothOriginalDB.enabled end

local function fixFontString(fs)
    if not fs or not fs.GetText then return end
    local ok, t = pcall(fs.GetText, fs)
    if not ok or type(t) ~= "string" then return end
    local nt = Translate(t)
    if nt ~= t then fs:SetText(nt) end
end

local function walk(frame, depth)
    if not frame or depth > 8 then return end
    if frame.IsForbidden and frame:IsForbidden() then return end
    if frame.GetRegions then
        for _, r in ipairs({ frame:GetRegions() }) do
            if r.GetObjectType and r:GetObjectType() == "FontString" then fixFontString(r) end
        end
    end
    if frame.GetChildren then
        for _, c in ipairs({ frame:GetChildren() }) do
            if c.IsShown and c:IsShown() then walk(c, depth + 1) end
        end
    end
end

local alvos = {
    function() return QuestFrame end,
    function() return GossipFrame end,
    function() return QuestMapFrame and QuestMapFrame.DetailsFrame end,
    function() return QuestLogPopupDetailFrame end,
    function() return TalkingHeadFrame end,
}

local pendente = false
local function refresh()
    if not enabled() then return end
    for _, get in ipairs(alvos) do
        local f = get()
        if f and f.IsShown and f:IsShown() then walk(f, 0) end
    end
end

-- roda no próximo frame (depois da Blizzard preencher os textos) e mais uma
-- vez logo depois, porque listas com ScrollBox criam linhas de forma atrasada
local function agendar()
    if pendente then return end
    pendente = true
    C_Timer.After(0, function()
        pendente = false
        refresh()
        C_Timer.After(0.1, refresh)
    end)
end

local function hookFrame(f, method)
    if f and f[method] then hooksecurefunc(f, method, agendar) end
end

local function instalarHooks()
    if QuestInfo_Display then hooksecurefunc("QuestInfo_Display", agendar) end
    if QuestFrame then QuestFrame:HookScript("OnShow", agendar) end
    if GossipFrame then
        GossipFrame:HookScript("OnShow", agendar)
        hookFrame(GossipFrame, "Update")
    end
    if QuestMapFrame and QuestMapFrame.DetailsFrame then
        QuestMapFrame.DetailsFrame:HookScript("OnShow", agendar)
    end
    if QuestLogPopupDetailFrame then QuestLogPopupDetailFrame:HookScript("OnShow", agendar) end
end

local function hookTalkingHead()
    if ns.thHooked or not TalkingHeadFrame then return end
    ns.thHooked = true
    hookFrame(TalkingHeadFrame, "PlayCurrent")
    TalkingHeadFrame:HookScript("OnShow", agendar)
end

-- Falas de NPC no chat (diz, grita, sussurra, emotes de chefe)
local function chatFilter(_, _, msg, ...)
    if not enabled() then return false end
    local nm = Translate(msg)
    if nm ~= msg then return false, nm, ... end
    return false
end

local function instalarChat()
    local addFilter = ChatFrame_AddMessageEventFilter
        or (ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter)
    if not addFilter then return end
    for _, ev in ipairs({
        "CHAT_MSG_MONSTER_SAY", "CHAT_MSG_MONSTER_YELL", "CHAT_MSG_MONSTER_WHISPER",
        "CHAT_MSG_MONSTER_EMOTE", "CHAT_MSG_MONSTER_PARTY",
        "CHAT_MSG_RAID_BOSS_EMOTE", "CHAT_MSG_RAID_BOSS_WHISPER",
    }) do
        addFilter(ev, chatFilter)
    end
end

----------------------------------------------------------------------
-- Mapas: minimapa, aviso de zona, mapa-múndi e tooltips
----------------------------------------------------------------------
local function corrigirZona()
    if not enabled() then return end
    fixFontString(ZoneTextString)
    fixFontString(SubZoneTextString)
    fixFontString(PVPInfoTextString)
    fixFontString(MinimapZoneText)
    if MinimapCluster then walk(MinimapCluster, 0) end
end

local function agendarZona()
    C_Timer.After(0, corrigirZona)
    C_Timer.After(0.2, corrigirZona)   -- o aviso de zona às vezes é preenchido um pouco depois
end

-- O mapa-múndi recria rótulos ao passar o mouse e ao trocar de mapa, então
-- enquanto ele estiver aberto revisamos os textos algumas vezes por segundo.
-- O custo é baixo: depois da troca o texto já está em inglês e nada muda.
local mapaTicker = CreateFrame("Frame")
mapaTicker:Hide()
local acumulado = 0
mapaTicker:SetScript("OnUpdate", function(self, dt)
    acumulado = acumulado + dt
    if acumulado < 0.15 then return end
    acumulado = 0
    if not enabled() then return end
    if WorldMapFrame and WorldMapFrame:IsShown() then walk(WorldMapFrame, 0) end
    if FlightMapFrame and FlightMapFrame:IsShown() then walk(FlightMapFrame, 0) end
    if TaxiFrame and TaxiFrame:IsShown() then walk(TaxiFrame, 0) end
end)

local function hookMapa(frame)
    if not frame or frame.azoHooked then return end
    frame.azoHooked = true
    frame:HookScript("OnShow", function() acumulado = 1; mapaTicker:Show() end)
    frame:HookScript("OnHide", function()
        if not ((WorldMapFrame and WorldMapFrame:IsShown())
             or (FlightMapFrame and FlightMapFrame:IsShown())
             or (TaxiFrame and TaxiFrame:IsShown())) then
            mapaTicker:Hide()
        end
    end)
    if frame:IsShown() then mapaTicker:Show() end
end

-- Tooltips: pinos do mapa, pontos de voo, pedra de regresso ("Lar: ...") etc.
local ajustandoTooltip = false
local function corrigirTooltip(tt)
    if ajustandoTooltip or not enabled() or not tt or not tt.GetName then return end
    if tt.IsForbidden and tt:IsForbidden() then return end
    local nome = tt:GetName()
    if not nome then return end
    local mudou = false
    for i = 1, tt:NumLines() do
        for _, lado in ipairs({ "TextLeft", "TextRight" }) do
            local fs = _G[nome .. lado .. i]
            if fs then
                local ok, t = pcall(fs.GetText, fs)
                if ok and type(t) == "string" then
                    local nt = Translate(t)
                    if nt ~= t then fs:SetText(nt); mudou = true end
                end
            end
        end
    end
    if mudou then           -- reajusta a largura da tooltip ao texto novo
        ajustandoTooltip = true
        tt:Show()
        ajustandoTooltip = false
    end
end

local function hookTooltips()
    for _, tt in ipairs({ GameTooltip, ItemRefTooltip }) do
        if tt and not tt.azoHooked then
            tt.azoHooked = true
            hooksecurefunc(tt, "Show", corrigirTooltip)
        end
    end
end

----------------------------------------------------------------------
-- Eventos
----------------------------------------------------------------------
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
for _, e in ipairs({ "QUEST_DETAIL", "QUEST_PROGRESS", "QUEST_COMPLETE", "QUEST_GREETING",
                     "GOSSIP_SHOW", "TALKINGHEAD_REQUESTED" }) do
    ev:RegisterEvent(e)
end
local EVENTOS_ZONA = { ZONE_CHANGED = true, ZONE_CHANGED_INDOORS = true,
                       ZONE_CHANGED_NEW_AREA = true, PLAYER_ENTERING_WORLD = true }
for e in pairs(EVENTOS_ZONA) do ev:RegisterEvent(e) end

ev:SetScript("OnEvent", function(_, event, arg1)
    if EVENTOS_ZONA[event] then
        agendarZona()
    elseif event == "ADDON_LOADED" then
        if arg1 == ADDON then
            AzerothOriginalDB = AzerothOriginalDB or { enabled = true }
            buildIndex()
        elseif arg1 == "Blizzard_TalkingHeadUI" then
            hookTalkingHead()
        elseif arg1 == "Blizzard_WorldMap" then
            hookMapa(WorldMapFrame)
        elseif arg1 == "Blizzard_FlightMap" then
            hookMapa(FlightMapFrame)
        end
    elseif event == "PLAYER_LOGIN" then
        instalarHooks()
        hookTalkingHead()
        instalarChat()
        hookMapa(WorldMapFrame)
        hookMapa(FlightMapFrame)
        hookMapa(TaxiFrame)
        hookTooltips()
        if total == 0 then
            print("|cff33ff99Azeroth Original|r: nenhum nome carregado. Rode tools/gerar_dados.py para gerar o Data.lua.")
        end
    else
        agendar()
    end
end)

----------------------------------------------------------------------
-- /nomes
----------------------------------------------------------------------
SLASH_AZEROTHORIGINAL1 = "/nomes"
SLASH_AZEROTHORIGINAL2 = "/azo"
SlashCmdList.AZEROTHORIGINAL = function(msg)
    msg = strtrim(msg or "")
    local cmd, rest = msg:match("^(%S*)%s*(.-)$")
    cmd = (cmd or ""):lower()
    local tag = "|cff33ff99Azeroth Original|r: "
    if cmd == "on" then
        AzerothOriginalDB.enabled = true; print(tag .. "ligado"); agendar()
    elseif cmd == "off" then
        AzerothOriginalDB.enabled = false; print(tag .. "desligado (reabra a janela para ver o texto original)")
    elseif cmd == "teste" and rest ~= "" then
        print(tag .. Translate(rest))
    else
        print(tag .. (enabled() and "ligado" or "desligado") .. ", " .. total .. " nomes carregados.")
        print("  /nomes on | off | teste <texto>")
    end
end
