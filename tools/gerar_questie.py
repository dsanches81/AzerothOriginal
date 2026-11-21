#!/usr/bin/env python3
"""
Gera o DataQuestie.lua do Azeroth Original com duas listas, tiradas dos
projetos Questie e QuestieDB (que já mantêm o WoW: Forever em inglês e pt-BR):

  ns.zonasQuestie  nomes de zona/categoria como o Questie mostra no rastreador
                   ("Sítio de Escavação: Pantanal" -> "Excavation Site: Wetlands")
  ns.npcs          nomes de NPCs pt-BR -> inglês, cruzados pelo ID do NPC

Uso:
    python gerar_questie.py                                   # baixa do GitHub
    python gerar_questie.py --questie <pasta> --questiedb <pasta>  # clones locais

Só usa a biblioteca padrão do Python.
"""
import argparse, collections, os, re, sys, urllib.request

RAW = "https://raw.githubusercontent.com/Questie/QuestieDB/master/"
RAW_QUESTIE = "https://raw.githubusercontent.com/Questie/Questie/master/"
SAIDA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "DataQuestie.lua")

ZONAS_QUESTIE = [
    "Localization/Translations/Zones/" + n + ".lua" for n in (
        "EasternKingdoms", "Kalimdor", "ZephrasIsle", "Dungeons", "Raids",
        "Battlegrounds", "ZoneSections", "Outland", "Northrend", "Cataclysm",
        "TheMaelstrom", "Pandaria", "Scenarios")
]
RE_CHAVE = re.compile(r'^\s*\["((?:[^"\\]|\\.)+)"\] = \{\s*$')
RE_PTBR = re.compile(r'^\s*\["ptBR"\] = "((?:[^"\\]|\\.)*)"')

# Ordem em que o QuestieDB aplica os dados (o último vence)
INGLES = [
    "data/Forever/foreverNpcDB.lua",
    "src/corrections/Forever/legacy/classicNPCFixes.lua",
    "src/corrections/Forever/generated/foreverBaseNpc.lua",
    "src/corrections/Forever/traces/foreverNpcTraces.lua",
    "src/corrections/Forever/foreverNPCFixes.lua",
]
PORTUGUES = [
    "l10n/Forever/lookupNpcs/ptBR.lua",
    "l10n/Forever/traces/lookupNpcs/ptBR.lua",
]

LIXO = ("(", "[", "<", "DND", "DNT", "Only GM", "UNUSED", "zz", "TEST", "Test ", "Trigger", "Bunny", "Invisible")

RE_BASE = re.compile(r"^\[(\d+)\] = \{'((?:[^'\\]|\\.)*)'")
RE_BLOCO = re.compile(r"^\s*\[(\d+)\] = \{")
RE_NOME = re.compile(r"\[npcKeys\.name\] = \"((?:[^\"\\]|\\.)*)\"")
RE_PT = re.compile(r"^\[(\d+)\] = \{\"((?:[^\"\\]|\\.)*)\"")


def ler(caminho, pasta, raw=RAW):
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


def nomes_ingles(pasta):
    nomes = {}
    for i, arq in enumerate(INGLES):
        texto = ler(arq, pasta)
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


def nomes_pt(pasta):
    nomes = {}
    for arq in PORTUGUES:
        for linha in ler(arq, pasta).splitlines():
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


def lua_str(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ") + '"'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--questiedb", help="pasta de um clone local do QuestieDB")
    ap.add_argument("--questie", help="pasta de um clone local do Questie")
    ap.add_argument("--saida", default=SAIDA)
    args = ap.parse_args()

    en = nomes_ingles(args.questiedb)
    pt = nomes_pt(args.questiedb)
    if not en or not pt:
        sys.exit("Não consegui ler os nomes. Verifique a conexão ou a pasta do QuestieDB.")

    votos = collections.defaultdict(collections.Counter)
    iguais = set()
    for npc_id, nome_pt in pt.items():
        nome_en = en.get(npc_id)
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
            ambiguos += 1          # ex.: "Guarda de Ventobravo" = Stormwind Guard / Stormwind City Guard
        final[nome_pt] = empatados[0]

    zonas = zonas_questie(args.questie)

    with open(args.saida, "w", encoding="utf-8", newline="\n") as f:
        f.write("-- ARQUIVO GERADO por tools/gerar_questie.py a partir do Questie/QuestieDB. Não edite; use Config.lua.\n")
        f.write("local _, ns = ...\nns.zonasQuestie = {\n")
        for k in sorted(zonas):
            f.write(f"    [{lua_str(k)}] = {lua_str(zonas[k])},\n")
        f.write("}\nns.npcs = {\n")
        for k in sorted(final):
            f.write(f"    [{lua_str(k)}] = {lua_str(final[k])},\n")
        f.write("}\nns.npcsIguais = {\n")
        for k in sorted(iguais):
            f.write(f"    {lua_str(k)},\n")
        f.write("}\n")
    print(f"OK: {len(zonas)} zonas do Questie e {len(final)} nomes de NPC gravados em {os.path.normpath(args.saida)} ({ambiguos} com mais de um original; escolhido o primeiro em ordem alfabética)")


if __name__ == "__main__":
    main()
