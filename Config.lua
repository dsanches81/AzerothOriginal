-- Ajustes manuais. Este arquivo NÃO é sobrescrito pelo gerador.
local _, ns = ...

-- Pares extras ou correções: ["nome em português"] = "nome original"
ns.extra = {
    ["Ventobravo"] = "Stormwind",   -- o gerador escolhe "Stormwind City"
}

-- Nomes que NUNCA devem ser trocados: palavras comuns em português que
-- também são nome de alguma subzona (evita falso positivo no texto).
local ignorar = {
    "Abrigo", "Alvorada", "Amparo", "Anoitecer", "Bazar", "Bastião", "Cascatas",
    "Catacumbas", "Cocheiras", "Coliseu", "Colmeia", "Confins", "Continente",
    "Desalento", "Despensa", "Elevador", "Ermos", "Estaleiro", "Estufa",
    "Eternidade", "Familiares", "Fogueira", "Fosso", "Furnas", "Fórum",
    "Guarnição", "Ilhas", "Imersões", "Incubadora", "Inferno", "Junção",
    "Labirinto", "Malogro", "Minas", "Mirante", "Mortífero", "Naufrágio",
    "Necrópole", "Nove", "Ossário", "Pedreira", "Penúria", "Perfídia",
    "Pestilência", "Precipício", "Prefeitura", "Promontório", "Protótipo",
    "Pórtico", "Quadra", "Refinaria", "Refúgio", "Reserva", "Retiro", "Serra",
    "Sucataria", "Subárea", "Testando", "Tocas", "Triunfo",
    "Loch",   -- subzona "The Loch"; sem isso "Loch Modan" vira "The Loch Modan"
}
ns.ignorar = {}
for _, n in ipairs(ignorar) do ns.ignorar[n] = true end
