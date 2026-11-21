# Como contribuir

Toda ajuda é bem-vinda, principalmente de quem joga e encontra casos reais.

## Reportar um problema

Abra uma *issue* com:
- **A frase original** (em português, como apareceu no jogo) e como ficou depois do addon.
- **Onde apareceu**: missão, diálogo de NPC, Talking Head ou chat.
- Se tiver, um print.

Dica: `/nomes teste <frase>` mostra no chat como o addon trata um texto.

## Tipos de correção

| Problema | Onde corrigir |
|---|---|
| Palavra comum sendo trocada (falso positivo) | Adicione em `ignorar` no `Config.lua` |
| Nome faltando ou com o original errado | Adicione em `ns.extra` no `Config.lua` |
| Lixo nos dados gerados (entradas internas/teste) | Filtros em `tools/gerar_dados.py` (`valido()`) |
| Janela do jogo que não é traduzida | `Core.lua` (lista `alvos`, `RASTREADORES` e `instalarHooks`) |
| Nome de NPC errado | Corrija no QuestieDB (fonte) ou adicione em `ns.extra` no `Config.lua` |

**Não edite o `Data.lua` nem o `DataQuestie.lua` à mão**: eles são gerados por `tools/gerar_dados.py` e `tools/gerar_questie.py` e sobrescritos a cada atualização.

Ao contribuir, você concorda em licenciar sua contribuição sob a GPLv3, a licença do projeto.

## Pull requests

1. Faça um fork e crie um branch (`git checkout -b corrige-nome-x`).
2. Teste no jogo com `/reload` e confira se não aparecem erros (recomendo o addon BugSack).
3. Descreva no PR o que mudou e um exemplo de frase antes/depois.

## Para mantenedores: atualizando os dados (a cada patch grande)

```
cd tools
python gerar_dados.py      # lugares, a partir das tabelas do jogo (wago.tools)
python gerar_questie.py    # zonas do Questie e nomes de NPCs, a partir do Questie/QuestieDB
```

Os nomes de NPCs e as zonas do rastreador vêm dos projetos [Questie](https://github.com/Questie/Questie) e [QuestieDB](https://github.com/Questie/QuestieDB), que mantêm o Forever em inglês e pt-BR.

Precisa só de Python 3 (biblioteca padrão). Se o download falhar, baixe os CSVs à mão no [wago.tools](https://wago.tools) e use `python gerar_dados.py --pasta <pasta>` (instruções no topo do script).

Depois de gerar, faça commit dos arquivos `Data.lua` e `DataQuestie.lua`: eles vão dentro do pacote publicado, e os jogadores não precisam rodar nada.
