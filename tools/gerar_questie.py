#!/usr/bin/env python3
"""
Gera o DataQuestie.lua do Azeroth Original, tirado dos projetos Questie e
QuestieDB (que já mantêm o WoW: Forever em inglês e pt-BR):

  ns.zonasQuestie  nomes de zona/categoria como o Questie mostra no rastreador
                   ("Sítio de Escavação: Pantanal" -> "Excavation Site: Wetlands")
  ns.npcs          nomes de NPCs pt-BR -> inglês, cruzados pelo ID do NPC
  ns.itens         nomes de itens pt-BR -> inglês, cruzados pelo ID do item

Uso:
    python gerar_questie.py                                        # baixa do GitHub
    python gerar_questie.py --questie <pasta> --questiedb <pasta>  # clones locais

Só usa a biblioteca padrão do Python.
"""
import argparse, collections, os, re, sys, urllib.request

RAW_QUESTIEDB = "https://raw.githubusercontent.com/Questie/QuestieDB/master/"
RAW_QUESTIE = "https://raw.githubusercontent.com/Questie/Questie/master/"
SAIDA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "DataQuestie.lua")

# Arquivos em inglês na ordem em que o QuestieDB os aplica (o último vence)
NPCS_EN = [
    "data/Forever/foreverNpcDB.lua",
    "src/corrections/Forever/legacy/classicNPCFixes.lua",
    "src/corrections/Forever/generated/foreverBaseNpc.lua",
    "src/corrections/Forever/traces/foreverNpcTraces.lua",
    "src/corrections/Forever/foreverNPCFixes.lua",
]
NPCS_PT = [
    "l10n/Forever/lookupNpcs/ptBR.lua",
    "l10n/Forever/traces/lookupNpcs/ptBR.lua",
]
ITENS_EN = [
    "data/Forever/foreverItemDB.lua",
    "src/corrections/Forever/legacy/classicItemFixes.lua",
    "src/corrections/Forever/generated/foreverBaseItem.lua",
    "src/corrections/Forever/traces/foreverItemTraces.lua",
    "src/corrections/Forever/foreverItemFixes.lua",
]
ITENS_PT = [
    "l10n/Forever/lookupItems/ptBR.lua",
    "l10n/Forever/traces/lookupItems/ptBR.lua",
]
ZONAS_QUESTIE = [
    "Localization/Translations/Zones/" + n + ".lua" for n in (
        "EasternKingdoms", "Kalimdor", "ZephrasIsle", "Dungeons", "Raids",
        "Battlegrounds", "ZoneSections", "Outland", "Northrend", "Cataclysm",
        "TheMaelstrom", "Pandaria", "Scenarios")
]

LIXO = ("(", "[", "<", "DND", "DNT", "Only GM", "UNUSED", "zz", "TEST", "Test ",
        "Trigger", "Bunny", "Invisible", "Deprecated", "OLD", "Monster -")

RE_BASE = re.compile(r"^\[(\d+)\] = \{'((?:[^'\\]|\\.)*)'")                 # [id] = {'Name', ...
RE_BLOCO = re.compile(r"^\s*\[(\d+)\] = \{")                                 # início de bloco de correção
RE_NOME = re.compile(r"\[(?:npcKeys|itemKeys)\.name\] = \"((?:[^\"\\]|\\.)*)\"")
RE_PT = re.compile(r"^\[(\d+)\] = \{?\"((?:[^\"\\]|\\.)*)\"")               # [id] = {"Nome"... ou [id] = "Nome"
RE_CHAVE = re.compile(r'^\s*\["((?:[^"\\]|\\.)+)"\] = \{\s*$')
RE_PTBR = re.compile(r'^\s*\["ptBR"\] = "((?:[^"\\]|\\.)*)"')


def ler(caminho, pasta, raw):
    if pasta:
        p = os.path.join(pasta, caminho)
        if not os.path.exists(p):
            return ""
        with open(p, encoding="utf-8") as f:
            return f.read()
    print(f"  baixando {caminho}...")
    try:
        req = urllib.request.Request(raw + caminho, headers={"User-Agent": "AzerothOriginal-gerador/1.0"})
        with urllib.request.urlopen(req, timeout=120) as r:
            return r.read().decode("utf-8")
    except Exception as e:
        print(f"  aviso: não consegui ler {caminho}: {e}")
        return ""


def unescape(s):
    return s.replace("\\'", "'").replace('\\"', '"').replace("\\\\", "\\")


def nomes_ingles(pasta, arquivos):
    nomes = {}
    for i, arq in enumerate(arquivos):
        texto = ler(arq, pasta, RAW_QUESTIEDB)
        if i == 0:
            for linha in texto.splitlines():
                m = RE_BASE.match(linha)
                if m:
                    nomes[int(m.group(1))] = unescape(m.group(2))
        else:
            atual = None
            for linha in texto.splitlines():
                m = RE_BLOCO.match(linha)
                if m:
                    atual = int(m.group(1))
                m = RE_NOME.search(linha)
                if m and atual is not None:
                    nomes[atual] = unescape(m.group(1))
    return nomes


def nomes_pt(pasta, arquivos):
    nomes = {}
    for arq in arquivos:
        for linha in ler(arq, pasta, RAW_QUESTIEDB).splitlines():
            m = RE_PT.match(linha)
            if m:
                nomes[int(m.group(1))] = unescape(m.group(2))
    return nomes


def zonas_questie(pasta):
    zonas = {}
    for arq in ZONAS_QUESTIE:
        chave = None
        for linha in ler(arq, pasta, RAW_QUESTIE).splitlines():
            m = RE_CHAVE.match(linha)
            if m:
                chave = unescape(m.group(1))
                continue
            m = RE_PTBR.match(linha)
            if m and chave:
                pt = unescape(m.group(1))
                if pt and pt != chave and pt[0].isupper():
                    zonas[pt] = chave
    return zonas


def valido(pt, en):
    if not pt or not en or pt == en:
        return False
    if len(pt) < 4 or not pt[0].isupper():
        return False
    if any(x in pt or x in en for x in LIXO):
        return False
    if any(ch.isdigit() for ch in pt + en):
        return False
    return True


def cruzar(en, pt, rotulo):
    """Cruza pelo ID. Retorna (mapa pt->en, nomes iguais nos dois idiomas, nº de ambíguos)."""
    if not en or not pt:
        sys.exit(f"Não consegui ler os nomes de {rotulo}. Verifique a conexão ou a pasta do QuestieDB.")
    votos = collections.defaultdict(collections.Counter)
    iguais = set()
    for id_, nome_pt in pt.items():
        nome_en = en.get(id_)
        if not nome_en:
            continue
        if nome_pt == nome_en and " " in nome_pt and not any(x in nome_pt for x in LIXO):
            iguais.add(nome_pt)
        if valido(nome_pt, nome_en):
            votos[nome_pt][nome_en] += 1
    final, ambiguos = {}, 0
    for nome_pt, c in votos.items():
        maior = max(c.values())
        empatados = sorted(n for n, v in c.items() if v == maior)
        if len(empatados) > 1:
            ambiguos += 1       # ex.: "Guarda de Ventobravo" = Stormwind Guard / Stormwind City Guard
        final[nome_pt] = empatados[0]
    return final, iguais, ambiguos


def lua_str(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ") + '"'


def escrever_mapa(f, nome, mapa):
    f.write(f"ns.{nome} = {{\n")
    for k in sorted(mapa):
        f.write(f"    [{lua_str(k)}] = {lua_str(mapa[k])},\n")
    f.write("}\n")


def escrever_lista(f, nome, lista):
    f.write(f"ns.{nome} = {{\n")
    for k in sorted(lista):
        f.write(f"    {lua_str(k)},\n")
    f.write("}\n")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--questiedb", help="pasta de um clone local do QuestieDB")
    ap.add_argument("--questie", help="pasta de um clone local do Questie")
    ap.add_argument("--saida", default=SAIDA)
    args = ap.parse_args()

    zonas = zonas_questie(args.questie)
    npcs, npcsIguais, ambN = cruzar(nomes_ingles(args.questiedb, NPCS_EN), nomes_pt(args.questiedb, NPCS_PT), "NPCs")
    itens, itensIguais, ambI = cruzar(nomes_ingles(args.questiedb, ITENS_EN), nomes_pt(args.questiedb, ITENS_PT), "itens")

    with open(args.saida, "w", encoding="utf-8", newline="\n") as f:
        f.write("-- ARQUIVO GERADO por tools/gerar_questie.py a partir do Questie/QuestieDB. Não edite; use Config.lua.\n")
        f.write("local _, ns = ...\n")
        escrever_mapa(f, "zonasQuestie", zonas)
        escrever_mapa(f, "npcs", npcs)
        escrever_lista(f, "npcsIguais", npcsIguais)
        escrever_mapa(f, "itens", itens)
        escrever_lista(f, "itensIguais", itensIguais)

    print(f"OK: {len(zonas)} zonas do Questie, {len(npcs)} NPCs e {len(itens)} itens gravados em "
          f"{os.path.normpath(args.saida)} ({ambN + ambI} nomes com mais de um original; escolhido o primeiro)")


if __name__ == "__main__":
    main()
