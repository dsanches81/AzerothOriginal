-- Janela de opções do Azeroth Original (/azo) e entrada no menu Opções > AddOns.
local ADDON, ns = ...

local LARGURA, ALTURA = 460, 610
local janela

local function criarFrame()
    local ok, f = pcall(CreateFrame, "Frame", "AzerothOriginalFrame", UIParent, "BasicFrameTemplateWithInset")
    if not ok then
        f = CreateFrame("Frame", "AzerothOriginalFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
        if f.SetBackdrop then
            f:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                            tile = true, tileSize = 32, edgeSize = 32,
                            insets = { left = 8, right = 8, top = 8, bottom = 8 } })
        end
        local fechar = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        fechar:SetPoint("TOPRIGHT", -4, -4)
    end
    f:SetSize(LARGURA, ALTURA)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    f:Hide()
    tinsert(UISpecialFrames, "AzerothOriginalFrame") -- fecha com ESC
    return f
end

local function texto(pai, fonte, str)
    local fs = pai:CreateFontString(nil, "OVERLAY", fonte or "GameFontHighlight")
    fs:SetJustifyH("LEFT")
    if str then fs:SetText(str) end
    return fs
end

local function caixa(pai, rotulo, dica, aoMudar)
    local cb = CreateFrame("CheckButton", nil, pai, "UICheckButtonTemplate")
    cb:SetSize(26, 26)
    local fs = texto(pai, "GameFontHighlight", rotulo)
    fs:SetPoint("LEFT", cb, "RIGHT", 4, 1)
    cb.rotulo = fs
    cb:SetScript("OnClick", function(self) aoMudar(self:GetChecked() and true or false) end)
    if dica then
        cb:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(rotulo, 1, 1, 1)
            GameTooltip:AddLine(dica, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    return cb
end

local function construir()
    local f = criarFrame()
    local db = AzerothOriginalDB

    local titulo = f.TitleText or f.title or texto(f, "GameFontNormal")
    if not (f.TitleText or f.title) then titulo:SetPoint("TOP", 0, -14) end
    titulo:SetText("Azeroth Original")

    local y = -34
    local function linha(obj, dx, altura)
        obj:SetPoint("TOPLEFT", f, "TOPLEFT", 16 + (dx or 0), y)
        y = y - (altura or 28)
    end

    local sub = texto(f, "GameFontDisableSmall",
        "Jogo em português, nomes originais em inglês.")
    linha(sub, 4, 22)

    -- Geral
    f.cbLigado = caixa(f, "Ativar o addon", "Desliga tudo de uma vez.", function(v)
        db.enabled = v; ns.Reaplicar(); f:Atualizar()
    end)
    linha(f.cbLigado)

    f.cbNpcs = caixa(f, "Trocar também os nomes de NPCs",
        "\"Magistrado Salomão\" vira \"Magistrate Solomon\". Vale para missões, objetivos, tooltips e chat.",
        function(v) db.npcs = v; ns.Reaplicar(); f:Atualizar() end)
    linha(f.cbNpcs, 0, 36)

    -- Áreas
    local cab = texto(f, "GameFontNormal", "Onde trocar os nomes")
    linha(cab, 4, 22)
    f.cbAreas = {}
    for _, a in ipairs(ns.AREAS) do
        local cb = caixa(f, a.nome, nil, function(v)
            db.areas[a.chave] = v; ns.Reaplicar(); f:Atualizar()
        end)
        cb.chave = a.chave
        linha(cb)
        table.insert(f.cbAreas, cb)
    end
    y = y - 4

    -- Teste
    local cabT = texto(f, "GameFontNormal", "Testar uma frase")
    linha(cabT, 4, 22)
    local eb = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    eb:SetSize(LARGURA - 50, 22)
    eb:SetAutoFocus(false)
    eb:SetText("Vá a Vila d'Ouro, na Floresta de Elwynn.")
    linha(eb, 8, 26)
    local resultado = texto(f, "GameFontHighlightSmall")
    resultado:SetWidth(LARGURA - 44)
    resultado:SetTextColor(0.6, 1, 0.6)
    linha(resultado, 6, 34)
    local function testar() resultado:SetText(ns.Translate(eb:GetText() or "")) end
    eb:SetScript("OnTextChanged", testar)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    eb:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    f.testar = testar

    -- Status
    local cabS = texto(f, "GameFontNormal", "Status")
    linha(cabS, 4, 20)
    f.status = texto(f, "GameFontHighlightSmall")
    f.status:SetWidth(LARGURA - 44)
    linha(f.status, 6, 74)
    f.erros = texto(f, "GameFontRedSmall")
    f.erros:SetWidth(LARGURA - 44)
    f.erros:SetPoint("TOPLEFT", f.status, "BOTTOMLEFT", 0, -4)

    -- Rodapé
    local credito = texto(f, "GameFontDisableSmall",
        "Feito por |cffb48cffParty de Dois|r  ·  Twitch e TikTok: |cffffffffpartydedois|r")
    credito:SetPoint("BOTTOMLEFT", 18, 70)

    local aviso = texto(f, "GameFontDisableSmall",
        "Ao desligar algo, o que já foi trocado na tela volta ao português depois de Recarregar.")
    aviso:SetWidth(LARGURA - 40)
    aviso:SetPoint("BOTTOMLEFT", 18, 42)

    local recarregar = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    recarregar:SetSize(150, 24)
    recarregar:SetPoint("BOTTOMLEFT", 16, 12)
    recarregar:SetText("Recarregar interface")
    recarregar:SetScript("OnClick", ReloadUI)

    local fechar = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    fechar:SetSize(100, 24)
    fechar:SetPoint("BOTTOMRIGHT", -16, 12)
    fechar:SetText("Fechar")
    fechar:SetScript("OnClick", function() f:Hide() end)

    function f:Atualizar()
        self.cbLigado:SetChecked(db.enabled)
        self.cbNpcs:SetChecked(db.npcs)
        for _, cb in ipairs(self.cbAreas) do
            cb:SetChecked(db.areas[cb.chave] ~= false)
            cb:SetEnabled(db.enabled and true or false)
            cb.rotulo:SetFontObject(db.enabled and "GameFontHighlight" or "GameFontDisable")
        end
        local st = ns.Status()
        local q
        if not st.questieCarregado then q = "|cff999999não instalado|r"
        elseif st.questieOk then q = "|cff33ff33integrado|r (" .. st.linhasQuestie .. " linhas do rastreador)"
        else q = "|cffffcc00carregado, aguardando o rastreador|r" end
        self.status:SetText(
            "Addon: " .. (st.ligado and "|cff33ff33ligado|r" or "|cffff3333desligado|r") ..
            "\nNomes de lugares: " .. st.lugares ..
            "\nNomes de NPCs: " .. (db.npcs and st.npcs or "|cff999999desligado|r") ..
            "\nQuestie: " .. q ..
            "\nModo abrangente: " .. (st.global and ("|cff33ff33ativo|r (" .. st.globalTrocas .. " textos trocados)") or "|cffff3333inativo|r") ..
            "   |cff999999v" .. (ns.VERSAO or "?") .. "|r")
        if #st.erros > 0 then
            self.erros:SetText("Erros:\n" .. table.concat(st.erros, "\n"))
        else
            self.erros:SetText("")
        end
        self.testar()
    end

    -- mantém o status vivo enquanto a janela está aberta
    local t = 0
    f:SetScript("OnUpdate", function(self, dt)
        t = t + dt
        if t > 1 then t = 0; self:Atualizar() end
    end)
    f:SetScript("OnShow", function(self) self:Atualizar() end)
    return f
end

function ns.AbrirJanela()
    janela = janela or construir()
    if janela:IsShown() then janela:Hide() else janela:Show() end
end

-- Entrada em Opções > AddOns, com um botão que abre a janela
local function registrarNasOpcoes()
    if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then return end
    local painel = CreateFrame("Frame")
    local t = texto(painel, "GameFontNormalLarge", "Azeroth Original")
    t:SetPoint("TOPLEFT", 16, -16)
    local d = texto(painel, "GameFontHighlight",
        "Jogo em português com os nomes originais em inglês.\nAs opções ficam numa janela própria (também abre com /azo).")
    d:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -8)
    local b = CreateFrame("Button", nil, painel, "UIPanelButtonTemplate")
    b:SetSize(160, 26)
    b:SetPoint("TOPLEFT", d, "BOTTOMLEFT", 0, -12)
    b:SetText("Abrir opções")
    b:SetScript("OnClick", function()
        if SettingsPanel and SettingsPanel:IsShown() then HideUIPanel(SettingsPanel) end
        ns.AbrirJanela()
    end)
    local cat = Settings.RegisterCanvasLayoutCategory(painel, "Azeroth Original")
    Settings.RegisterAddOnCategory(cat)
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function() pcall(registrarNasOpcoes) end)
