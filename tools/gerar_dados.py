#!/usr/bin/env python3
"""
Gera o Data.lua do addon Azeroth Original cruzando os nomes de lugares do jogo
em enUS e ptBR (tabelas AreaTable, Map e UiMap), pelo mesmo ID.

Uso:
    python gerar_dados.py                 # baixa do wago.tools (precisa de internet)
    python gerar_dados.py --pasta csv     # usa CSVs já baixados à mão

No modo --pasta, salve os arquivos com estes nomes:
    AreaTable.enUS.csv  AreaTable.ptBR.csv
    Map.enUS.csv        Map.ptBR.csv
    UiMap.enUS.csv      UiMap.ptBR.csv
(no wago.tools: abra a tabela, escolha o idioma e clique em "Download CSV")

Só usa a biblioteca padrão do Python.
"""
import argparse, collections, csv, io, os, sys, urllib.request

TABELAS = ["AreaTable", "Map", "UiMap"]
EXTRA = ""  # ex.: "&build=1.60.1.12345" para puxar de um build específico
URL = "https://wago.tools/db2/{tabela}/csv?locale={loc}{extra}"
SAIDA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Data.lua")

# Palavras/frases comuns demais para trocar sozinhas (geram falso positivo).
# Edite à vontade; para ajustes finos use também Config.lua no jogo.
GENERICOS = {
    "Lar", "Casa", "Porto", "Ponte", "Torre", "Mina", "Vale", "Lago", "Forte",
    "Caverna", "Floresta", "Templo", "Ruínas", "Cemitério", "Estábulo",
    "Estábulos", "Taverna", "Estalagem", "Ferraria", "Banco", "Arena", "Prisão",
    "Ninho", "Jardim", "Fazenda", "Mercado", "Praça", "Cripta", "Covil",
    "Acampamento", "Posto", "Cais", "Doca", "Docas", "Farol", "Moinho",
    "Serraria", "Biblioteca", "Catedral", "Capela", "Igreja", "Quartel",
    "Muralha", "Portão", "Fortaleza", "Cidadela", "Abismo", "Ilha", "Costa",
    "Praia", "Colina", "Colinas", "Montanha", "Planalto", "Pântano", "Deserto",
    "Bosque", "Clareira", "Gruta", "Túnel", "Túneis", "Esgoto", "Esgotos",
    "Celeiro", "Oficina", "Laboratório", "Santuário", "Altar", "Trono",
    "Câmara", "Salão", "Pátio", "Jardins", "Ruína", "Base", "Oásis",
    "Mosteiro", "Estrada", "Passagem", "Caminho", "Encruzilhada", "Vila",
    "Aldeia", "Cidade", "Rio", "Mar", "Oceano", "Cachoeira", "Fonte",
    "Poço", "Tumba", "Túmulo", "Mausoléu", "Ossuário", "Torreão",
    "Casa de Leilões", "Banco Real", "Taverna", "Arena", "Ateliê",
}
LIXO = ("UNUSED", "DNT", "[", "zz", "TEST", "Test ", "Dev ", "(old)", "OLD ")


def ler_csv(texto):
    return list(csv.DictReader(io.StringIO(texto)))


def baixar(tabela, loc):
    url = URL.format(tabela=tabela, loc=loc, extra=EXTRA)
    req = urllib.request.Request(url, headers={"User-Agent": "AzerothOriginal-gerador/1.0"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read().decode("utf-8-sig")


def carregar(tabela, loc, pasta):
    if pasta:
        with open(os.path.join(pasta, f"{tabela}.{loc}.csv"), encoding="utf-8-sig") as f:
            return ler_csv(f.read())
    print(f"  baixando {tabela} ({loc})...")
    return ler_csv(baixar(tabela, loc))


def coluna_nome(linhas):
    cols = list(linhas[0].keys())
    for c in cols:
        if c.endswith("_lang") and "Name" in c:
            return c
    for c in cols:
        if c.endswith("_lang"):
            return c
    raise SystemExit(f"Não achei coluna de nome (_lang). Colunas: {cols}")


def coluna_id(linhas):
    for c in linhas[0].keys():
        if c.lower() == "id":
            return c
    return list(linhas[0].keys())[0]


def mapear(linhas):
    cid, cnome = coluna_id(linhas), coluna_nome(linhas)
    return {l[cid]: (l[cnome] or "").strip() for l in linhas}


def valido(pt, en):
    if not pt or not en or pt == en:
        return False
    if len(pt) < 4 or not pt[0].isupper():
        return False
    if any(x in en for x in LIXO) or any(x in pt for x in LIXO):
        return False
    if pt in GENERICOS:
        return False
    if any(ch.isdigit() for ch in pt + en):            # Guilnéas3, Testing02...
        return False
    if any(x in en for x in ("EnvArt", "Phase", "Testing", "Sub zone")):
        return False
    if " " not in pt and any(ch.isupper() for ch in pt[1:]) and "'" not in pt and "-" not in pt:
        return False                                    # VelhaAltaforja, AreadefuntaDe...
    if pt.isupper():                                    # AVIN, MEGAMINA
        return False
    return True


def lua_str(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ") + '"'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--pasta", help="pasta com os CSVs baixados à mão")
    ap.add_argument("--saida", default=SAIDA)
    ap.add_argument("--build", help="build do wago.tools (ex.: o build do Forever)")
    args = ap.parse_args()
    global EXTRA
    if args.build:
        EXTRA = "&build=" + args.build

    votos = collections.defaultdict(collections.Counter)
    for t in TABELAS:
        try:
            en = mapear(carregar(t, "enUS", args.pasta))
            pt = mapear(carregar(t, "ptBR", args.pasta))
        except Exception as e:
            print(f"  aviso: pulei {t}: {e}")
            continue
        iguais = sum(1 for k in pt if k in en and pt[k] == en[k])
        if pt and iguais / len(pt) > 0.9:
            sys.exit(f"{t}: ptBR e enUS vieram quase idênticos; o idioma não foi aplicado no download.")
        for k, nome_pt in pt.items():
            nome_en = en.get(k)
            if valido(nome_pt, nome_en):
                votos[nome_pt][nome_en] += 1

    final, conflitos = {}, []
    for nome_pt, c in votos.items():
        (melhor, n1), *resto = c.most_common()
        if resto and resto[0][1] == n1:
            conflitos.append((nome_pt, dict(c)))
            continue
        final[nome_pt] = melhor

    if not final:
        sys.exit("Nenhum nome gerado. Verifique os downloads/CSVs.")

    with open(args.saida, "w", encoding="utf-8", newline="\n") as f:
        f.write("-- ARQUIVO GERADO por tools/gerar_dados.py. Não edite; use Config.lua.\n")
        f.write("local _, ns = ...\nns.data = {\n")
        for k in sorted(final):
            f.write(f"    [{lua_str(k)}] = {lua_str(final[k])},\n")
        f.write("}\n")

    print(f"OK: {len(final)} nomes gravados em {os.path.normpath(args.saida)}")
    if conflitos:
        print(f"{len(conflitos)} nomes ambíguos ignorados (mesmo nome PT, originais diferentes), ex.:")
        for nome, c in conflitos[:10]:
            print(f"   {nome}: {c}")


if __name__ == "__main__":
    main()
