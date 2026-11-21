-- Azeroth Original: troca nomes de lugares em PT-BR pelos originais em inglês
-- no texto de missões, diálogos de NPC (gossip), Talking Head e falas de NPC no chat.
local ADDON, ns = ...

----------------------------------------------------------------------
-- Índice: primeira palavra -> lista de candidatos (mais longos primeiro)
----------------------------------------------------------------------
local byte, sub, find = string.byte, string.sub, string.find
local index = {}
local total, totalLugares, totalNpcs = 0, 0, 0

local function isLetter(b)
    -- letras ASCII ou qualquer byte de caractere UTF-8 (acentos)
    return b and ((b >= 65 and b <= 90) or (b >= 97 and b <= 122) or b >= 128)
end

local function firstWord(s)
    local j = 1
    while j <= #s and isLetter(byte(s, j)) do j = j + 1 end
    return sub(s, 1, j - 1)
end

local function add(pt, en, npc)
    if ns.ignorar and ns.ignorar[pt] then return end
    if type(pt) ~= "string" or type(en) ~= "string" or pt == en or pt == "" then return end
    if en == pt .. " City" then return end   -- "Dalaran" continua "Dalaran", não "Dalaran City"
    if not isLetter(byte(pt, 1)) then return end
    local w = firstWord(pt)
    if w == "" then return end
    local list = index[w]
    if not list then list = {}; index[w] = list end
    -- NPC de uma palavra só ("Ovelha", "Fardo") não é trocado no início de
    -- frase, onde costuma ser palavra comum e não o nome do NPC.
    list[#list + 1] = { pt = pt, en = en, len = #pt, soMeio = npc and not find(pt, " ", 1, true) }
    total = total + 1
end

-- Nomes que já estão no original ("Dalaran City", "Loch Modan") entram no índice
-- apontando para si mesmos. Como o mais longo vence, "Dalaran City" nunca é
-- confundido com "Dalaran" de novo: a troca fica estável, por mais vezes que
-- o mesmo texto passe pelo addon.
local function addIdentidade(nome, merged)
    if type(nome) ~= "string" or nome == "" or merged[nome] then return end
    if not isLetter(byte(nome, 1)) then return end
    local w = firstWord(nome)
    if w == "" then return end
    local list = index[w]
    if not list then list = {}; index[w] = list end
    list[#list + 1] = { pt = nome, en = nome, len = #nome, ident = true }
end

local ARTIGOS = { O = true, A = true, Os = true, As = true }

local function buildIndex()
    wipe(index); total = 0
    local merged = {}
    for pt, en in pairs(ns.data or {}) do merged[pt] = en end
    -- nomes do Questie são mais precisos para os cabeçalhos dele
    -- ("Sítio de Escavação: Pantanal" -> "Excavation Site: Wetlands")
    for pt, en in pairs(ns.zonasQuestie or {}) do merged[pt] = en end
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
    totalLugares = total
    -- NPCs (opcional, /azo npcs). Lugares têm prioridade se o nome coincidir.
    local npcs = {}
    if AzerothOriginalDB and AzerothOriginalDB.npcs then
        for pt, en in pairs(ns.npcs or {}) do
            if not merged[pt] then npcs[pt] = en; add(pt, en, true) end
        end
        for _, nome in ipairs(ns.npcsIguais or {}) do addIdentidade(nome, merged) end
    end
    totalNpcs = total - totalLugares
    local vistos = {}
    for _, en in pairs(npcs) do
        if not vistos[en] and not npcs[en] then vistos[en] = true; addIdentidade(en, merged) end
    end
    for _, en in pairs(merged) do
        if not vistos[en] then
            vistos[en] = true
            addIdentidade(en, merged)
            if sub(en, 1, 4) == "The " then addIdentidade(sub(en, 5), merged) end  -- forma sem "The"
        end
    end
    for _, nome in ipairs(ns.iguais or {}) do addIdentidade(nome, merged) end
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

-- true se a posição i está no começo do texto ou logo após . ! ? : ou quebra de linha
local function inicioDeFrase(text, i)
    local k = i - 1
    while k >= 1 do
        local b = byte(text, k)
        if b ~= 32 and b ~= 9 then
            return b == 46 or b == 33 or b == 63 or b == 58 or b == 10
                or (b == 110 and byte(text, k - 1) == 124)       -- |n
        end
        k = k - 1
    end
    return true
end

-- Textos "lacrados" (secret values) do motor novo não podem ser lidos,
-- medidos nem comparados por addons. Todo texto passa por aqui ANTES de
-- qualquer operação; o lacre é checado primeiro.
local function legivel(v)
    if issecretvalue and issecretvalue(v) then return false end
    return type(v) == "string"
end
ns.legivel = legivel

-- true se depois do nome vem mais frase (" perdida!", " de feno"): espaço e
-- letra minúscula. Um nome sozinho (nameplate, tooltip, objetivo) não conta.
local function seguidoDeFrase(text, j)
    if byte(text, j) ~= 32 then return false end
    local b = byte(text, j + 1)
    return b ~= nil and ((b >= 97 and b <= 122) or (b == 195 and (byte(text, j + 2) or 0) >= 160))
end

local function Translate(text)
    if not legivel(text) or text == "" then return text end
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
                        if sub(text, i, i + c.len - 1) == c.pt and not isLetter(byte(text, i + c.len))
                           and not (c.soMeio and inicioDeFrase(text, i) and seguidoDeFrase(text, i + c.len)) then
                            hit = c; break
                        end
                    end
                end
                if hit then
                    out = out or {}
                    out[o + 1] = sub(text, copyFrom, i - 1)
                    local en = hit.en
                    -- "as The Hinterlands" -> "as Hinterlands" quando já há artigo/contração antes
                    if not hit.ident and sub(en, 1, 4) == "The " then
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

-- Áreas que o usuário pode ligar/desligar na janela de opções
ns.AREAS = {
    { chave = "missoes",    nome = "Missões e diálogos de NPC" },
    { chave = "mapas",      nome = "Mapas, minimapa e aviso de zona" },
    { chave = "tooltips",   nome = "Tooltips" },
    { chave = "chat",       nome = "Chat: falas de NPC e mensagens do sistema" },
    { chave = "rastreador", nome = "Rastreador de missões (Questie e outros)" },
    { chave = "outros",     nome = "Modo abrangente: textos de outros addons (EllesmereUI etc.)" },
}
do  -- versão vem do .toc (o empacotador troca @project-version@ pela tag)
    local get = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
    local v = get and get(ADDON, "Version")
    ns.VERSAO = (v and not v:find("@", 1, true)) and v or "dev"
end
local function areaOn(a)
    if not enabled() then return false end
    local areas = AzerothOriginalDB.areas
    return not (a and areas and areas[a] == false)
end

-- Cada texto encontrado ganha um "gancho" no SetText: a partir daí, toda vez
-- que o jogo (ou outro addon) reescrever esse texto, a troca acontece na hora.
-- Isso resolve textos que mudam o tempo todo (rótulo do mapa, coordenadas,
-- rastreador de missões).
local comGancho = setmetatable({}, { __mode = "k" })
local reescrevendo = false

local function aoMudarTexto(fs)
    if reescrevendo or not areaOn(comGancho[fs]) then return end
    local ok, t = pcall(fs.GetText, fs)
    if not ok or not legivel(t) then return end
    local nt = Translate(t)
    if nt ~= t then
        reescrevendo = true
        fs:SetText(nt)
        reescrevendo = false
    end
end

local function fixFontString(fs, area)
    if not fs or not fs.GetText then return end
    if not comGancho[fs] and fs.SetText then
        comGancho[fs] = area or "geral"
        hooksecurefunc(fs, "SetText", aoMudarTexto)
        if fs.SetFormattedText then hooksecurefunc(fs, "SetFormattedText", aoMudarTexto) end
    end
    aoMudarTexto(fs)
end

-- Modo abrangente: um gancho único no SetText de TODOS os textos da interface.
-- Pega o que outros addons escrevem (EllesmereUI, minimapas, rastreadores...)
-- sem precisar saber o nome de cada quadro. O chat fica de fora.
local globalAtivo, globalChamadas, globalTrocas = false, 0, 0
local function trocarGlobal(fs)
    if fs.IsForbidden and fs:IsForbidden() then return end
    globalChamadas = globalChamadas + 1
    local t = fs:GetText()
    if not legivel(t) or #t < 4 then return end
    local p = fs.GetParent and fs:GetParent()
    if p and p.GetObjectType and p:GetObjectType() == "ScrollingMessageFrame" then return end
    local nt = Translate(t)
    if nt ~= t then
        reescrevendo = true
        fs:SetText(nt)
        reescrevendo = false
        globalTrocas = globalTrocas + 1
    end
end

-- Roda dentro do SetText de outros addons: NUNCA pode deixar escapar erro,
-- senão o erro aparece como se fosse do addon que estava escrevendo o texto.
local function aoMudarTextoGlobal(fs)
    if reescrevendo or comGancho[fs] or not areaOn("outros") then return end
    local ok = pcall(trocarGlobal, fs)
    if not ok then reescrevendo = false end
end

local function instalarGlobal()
    if globalAtivo then return end
    local amostra = UIParent:CreateFontString(nil, "OVERLAY")
    local mt = getmetatable(amostra)
    local idx = mt and mt.__index
    if type(idx) == "table" and idx.SetText then
        hooksecurefunc(idx, "SetText", aoMudarTextoGlobal)
        if idx.SetFormattedText then hooksecurefunc(idx, "SetFormattedText", aoMudarTextoGlobal) end
        globalAtivo = true
    end
end

local function walk(frame, depth, area)
    if not frame or depth > 8 then return end
    if frame.IsForbidden and frame:IsForbidden() then return end
    if frame.GetRegions then
        for _, r in ipairs({ frame:GetRegions() }) do
            if r.GetObjectType and r:GetObjectType() == "FontString" then fixFontString(r, area) end
        end
    end
    if frame.GetChildren then
        for _, c in ipairs({ frame:GetChildren() }) do
            if not (c.IsForbidden and c:IsForbidden()) and c.IsShown and c:IsShown() then walk(c, depth + 1, area) end
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
    if not areaOn("missoes") then return end
    for _, get in ipairs(alvos) do
        local f = get()
        if f and f.IsShown and f:IsShown() then walk(f, 0, "missoes") end
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
local function chatFilter(_, _, msg, autor, ...)
    if not areaOn("chat") or not legivel(msg) then return false end
    local nm = Translate(msg)
    local mudou = nm ~= msg
    local na = autor
    if AzerothOriginalDB.npcs and legivel(autor) then
        na = Translate(autor)
        mudou = mudou or na ~= autor
    end
    if mudou then return false, nm, na, ... end
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
        -- mensagens do sistema: "Você descobriu Monte Corvo", experiência, etc.
        "CHAT_MSG_SYSTEM", "CHAT_MSG_COMBAT_XP_GAIN",
    }) do
        addFilter(ev, chatFilter)
    end
    -- Canais: só as mensagens do próprio jogo (Defesa Local: "Estão atacando
    -- Floresta do Crepúsculo!"), que chegam sem autor. Conversa de jogador não.
    addFilter("CHAT_MSG_CHANNEL", function(self, event, msg, autor, ...)
        if not legivel(msg) or (autor ~= nil and (not legivel(autor) or autor ~= "")) then return false end
        return chatFilter(self, event, msg, autor, ...)
    end)
end

----------------------------------------------------------------------
-- Mapas: minimapa, aviso de zona, mapa-múndi e tooltips
----------------------------------------------------------------------
local function corrigirZona()
    if not areaOn("mapas") then return end
    fixFontString(ZoneTextString, "mapas")
    fixFontString(SubZoneTextString, "mapas")
    fixFontString(PVPInfoTextString, "mapas")
    fixFontString(MinimapZoneText, "mapas")
    if MinimapCluster then walk(MinimapCluster, 0, "mapas") end
end

local function agendarZona()
    C_Timer.After(0, corrigirZona)
    C_Timer.After(0.2, corrigirZona)   -- o aviso de zona às vezes é preenchido um pouco depois
end

-- Revisão periódica dos quadros que criam linhas novas o tempo todo (mapas,
-- registro de missões, rastreadores). O gancho no SetText cuida das mudanças
-- de texto; esta revisão só serve para achar textos recém-criados.
-- Como a troca é estável, revisar de novo um texto já trocado não muda nada.
-- Cada parte roda isolada: se uma falhar, as outras continuam, e o erro
-- aparece uma vez no chat (em vez de desligar tudo em silêncio).
local errosVistos = {}
ns.erros = {}
local function seguro(nome, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok and not errosVistos[nome] then
        errosVistos[nome] = true
        table.insert(ns.erros, nome .. ": " .. tostring(err))
        print("|cff33ff99Azeroth Original|r: erro em " .. nome .. ": " .. tostring(err))
    end
end

local integrarQuestie, hookTooltipsPorNome, corrigirTooltipRef
local RASTREADORES = { "ObjectiveTrackerFrame", "QuestWatchFrame", "WatchFrame", "Questie_BaseFrame",
                       "TrackedQuestsScrollChildFrame",
                       "EUI_CustomQuestTracker",   -- EllesmereUI Quest Tracker
}

-- Questie: as linhas do rastreador (linePool1..250) ficam num quadro de rolagem
-- que não é filho do Questie_BaseFrame, por isso vão pelo nome. Basta pôr o
-- gancho uma vez em cada linha; depois toda escrita do Questie já sai trocada.
local questieOk = false
local linhasQuestie = 0
local ultimaVarredura = -100

-- Sobe pelos "pais" de um quadro procurando um que seja do Questie
local function eDoQuestie(f)
    local n = 0
    while f and n < 8 do
        local nome = f.GetName and f:GetName()
        if nome and (nome:find("^Questie") or nome:find("^TrackedQuests") or nome:find("^linePool")) then
            return true
        end
        f = f.GetParent and f:GetParent()
        n = n + 1
    end
    return false
end

integrarQuestie = function()
    if questieOk or not areaOn("rastreador") then return end
    local n = 0
    -- 1) versões do Questie que dão nome às linhas (linePool1..250)
    local i = 1
    while _G["linePool" .. i] do
        local linha = _G["linePool" .. i]
        if linha.label then fixFontString(linha.label, "rastreador"); n = n + 1 end
        i = i + 1
    end
    -- 2) outras versões: varre os quadros do jogo e pega as linhas (quadros com
    --    um texto "label") que pertencem ao Questie. Roda a cada 5 s até achar.
    if n == 0 and EnumerateFrames and GetTime and GetTime() - ultimaVarredura > 5 then
        ultimaVarredura = GetTime()
        local f = EnumerateFrames()
        while f do
            if not (f.IsForbidden and f:IsForbidden()) then
                local lbl = rawget(f, "label")
                if type(lbl) == "table" and lbl.GetText and eDoQuestie(f) then
                    fixFontString(lbl, "rastreador"); n = n + 1
                end
            end
            f = EnumerateFrames(f)
        end
    end
    if Questie_HeaderFrame then walk(Questie_HeaderFrame, 0, "rastreador") end
    if n > 0 then
        linhasQuestie = n
        questieOk = true
    end
end

-- Tooltips de addons criadas mais tarde (ex.: a do rastreador do Questie)
local TOOLTIPS_EXTRAS = { "QuestieTrackerQuestTooltip" }
hookTooltipsPorNome = function()
    for _, nome in ipairs(TOOLTIPS_EXTRAS) do
        local tt = _G[nome]
        if tt and not tt.azoHooked and corrigirTooltipRef then
            tt.azoHooked = true
            hooksecurefunc(tt, "Show", corrigirTooltipRef)
        end
    end
end

local revisor = CreateFrame("Frame")
local tRapido, tLento = 0, 0
revisor:SetScript("OnUpdate", function(_, dt)
    if not enabled() then return end
    tRapido, tLento = tRapido + dt, tLento + dt
    if tRapido >= 0.15 then
        tRapido = 0
        for _, f in ipairs({ WorldMapFrame, FlightMapFrame, TaxiFrame }) do
            if f and f:IsShown() and areaOn("mapas") then seguro("mapa", walk, f, 0, "mapas") end
        end
    end
    if tLento >= 0.5 then
        tLento = 0
        seguro("Questie", integrarQuestie)
        seguro("tooltips", hookTooltipsPorNome)
        for _, nome in ipairs(RASTREADORES) do
            local f = _G[nome]
            if f and f.IsShown and f:IsShown() then seguro(nome, walk, f, 0, "rastreador") end
        end
        for nome in pairs(AzerothOriginalDB.quadros or {}) do
            local f = _G[nome]
            if f and f.IsShown and f:IsShown() then seguro(nome, walk, f, 0, "rastreador") end
        end
    end
end)

local function hookMapa(frame)
    if not frame or frame.azoHooked then return end
    frame.azoHooked = true
    frame:HookScript("OnShow", function() tRapido = 1 end)
end

-- Quadro sob o mouse, subindo até o quadro principal com nome (para /azo add)
local function quadroSobMouse()
    local f = GetMouseFoci and GetMouseFoci()[1] or (GetMouseFocus and GetMouseFocus())
    local achado
    while f and f ~= UIParent and f ~= WorldFrame do
        if f.GetName and f:GetName() then achado = f end
        f = f.GetParent and f:GetParent()
    end
    return achado
end

-- Tooltips: pinos do mapa, pontos de voo, pedra de regresso ("Lar: ...") etc.
local ajustandoTooltip = false
local function corrigirTooltip(tt)
    if ajustandoTooltip or not areaOn("tooltips") or not tt or not tt.GetName then return end
    if tt.IsForbidden and tt:IsForbidden() then return end
    local nome = tt:GetName()
    if not nome then return end
    local mudou = false
    for i = 1, tt:NumLines() do
        for _, lado in ipairs({ "TextLeft", "TextRight" }) do
            local fs = _G[nome .. lado .. i]
            if fs then
                local ok, t = pcall(fs.GetText, fs)
                if ok and legivel(t) then
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

corrigirTooltipRef = corrigirTooltip

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
            AzerothOriginalDB.areas = AzerothOriginalDB.areas or {}
            if AzerothOriginalDB.npcs == nil then AzerothOriginalDB.npcs = false end
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
        seguro("modo abrangente", instalarGlobal)
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
----------------------------------------------------------------------
-- API usada pela janela de opções (UI.lua)
----------------------------------------------------------------------
local function questieCarregado()
    if C_AddOns and C_AddOns.IsAddOnLoaded then return C_AddOns.IsAddOnLoaded("Questie") end
    return IsAddOnLoaded and IsAddOnLoaded("Questie") or false
end

ns.Status = function()
    return {
        ligado = enabled() and true or false,
        lugares = totalLugares,
        npcs = AzerothOriginalDB.npcs and totalNpcs or 0,
        questieCarregado = questieCarregado() and true or false,
        questieOk = questieOk,
        linhasQuestie = linhasQuestie,
        erros = ns.erros,
        global = globalAtivo,
        globalChamadas = globalChamadas,
        globalTrocas = globalTrocas,
    }
end

-- Reconstrói o índice (ao ligar/desligar NPCs) e reaplica no que está na tela
ns.Reaplicar = function()
    buildIndex()
    agendar()
    agendarZona()
end

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
    elseif cmd == "npcs" then
        local arg = rest:lower()
        if arg == "on" then AzerothOriginalDB.npcs = true
        elseif arg == "off" then AzerothOriginalDB.npcs = false
        else AzerothOriginalDB.npcs = not AzerothOriginalDB.npcs end
        buildIndex()
        print(tag .. "nomes de NPCs " .. (AzerothOriginalDB.npcs and ("ligados (" .. totalNpcs .. " nomes)") or "desligados")
              .. ". Reabra as janelas ou use /reload para ver em tudo.")
        agendar()
    elseif cmd == "diag" then
        print(tag .. "versão " .. ns.VERSAO .. ", modo abrangente " .. (globalAtivo and "ativo" or "INATIVO")
              .. " (" .. globalChamadas .. " textos vistos, " .. globalTrocas .. " trocados)")
        for _, nome in ipairs(RASTREADORES) do
            local f = _G[nome]
            if f then
                local nFs, nGancho, exemplo = 0, 0, nil
                local function conta(fr, d)
                    if not fr or d > 8 or (fr.IsForbidden and fr:IsForbidden()) then return end
                    for _, r in ipairs({ fr:GetRegions() }) do
                        if r.GetObjectType and r:GetObjectType() == "FontString" then
                            nFs = nFs + 1
                            if comGancho[r] then nGancho = nGancho + 1 end
                            local t = r:GetText()
                            if not exemplo and legivel(t) and #t > 3 then exemplo = t end
                        end
                    end
                    for _, c in ipairs({ fr:GetChildren() }) do conta(c, d + 1) end
                end
                pcall(conta, f, 0)
                print("  " .. nome .. ": visível=" .. tostring(f:IsShown()) .. ", textos=" .. nFs
                      .. ", com gancho=" .. nGancho .. (exemplo and (", ex.: " .. exemplo:sub(1, 40)) or ""))
            end
        end
        for _, e in ipairs(ns.erros) do print("  erro: " .. e) end
    elseif cmd == "onde" then
        local f = GetMouseFoci and GetMouseFoci()[1] or (GetMouseFocus and GetMouseFocus())
        if not f or f == WorldFrame then
            print(tag .. "nada sob o mouse (passe o mouse sobre uma linha e use uma macro ou tecla com /azo onde)")
        else
            print(tag .. "sob o mouse:")
            local nivel = 0
            while f and f ~= UIParent and nivel < 12 do
                local nome = f.GetName and f:GetName() or "(sem nome)"
                local tipo = f.GetObjectType and f:GetObjectType() or "?"
                local texto = ""
                if f.label and f.label.GetText then texto = " texto=\"" .. tostring(f.label:GetText()) .. "\"" end
                print(string.rep("  ", nivel) .. nome .. " [" .. tipo .. "]" .. texto
                      .. (comGancho[f.label or {}] and " (com gancho)" or ""))
                f = f.GetParent and f:GetParent()
                nivel = nivel + 1
            end
        end
    elseif cmd == "add" then
        local f = quadroSobMouse()
        if not f then
            print(tag .. "passe o mouse sobre o texto que não foi trocado e digite /azo add de novo")
        else
            AzerothOriginalDB.quadros = AzerothOriginalDB.quadros or {}
            AzerothOriginalDB.quadros[f:GetName()] = true
            print(tag .. "agora também reviso o quadro " .. f:GetName())
        end
    elseif cmd == "" and ns.AbrirJanela then
        ns.AbrirJanela()
    elseif cmd == "quadros" then
        for nome in pairs(AzerothOriginalDB.quadros or {}) do print("  " .. nome) end
    else
        print(tag .. (enabled() and "ligado" or "desligado") .. ": " .. totalLugares .. " lugares, NPCs "
              .. (AzerothOriginalDB.npcs and (totalNpcs .. " nomes") or "desligados (/azo npcs on)") .. ".")
        if C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Questie") or (IsAddOnLoaded and IsAddOnLoaded("Questie")) then
            print("  Questie: " .. (questieOk and ("integrado (" .. linhasQuestie .. " linhas)")
                  or ("carregado, mas linhas do rastreador não encontradas (linePool1 = " .. tostring(_G.linePool1 ~= nil) .. ")")))
        end
        print("  /azo (janela) | status | diag | on | off | npcs on|off | teste <texto> | onde | add | quadros")
    end
end
