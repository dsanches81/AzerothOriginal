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
| Janela do jogo que não é traduzida | `Core.lua` (lista `alvos` e `instalarHooks`) |

**Não edite o `Data.lua` à mão**: ele é gerado pelo script e é sobrescrito a cada atualização.

## Pull requests

1. Faça um fork e crie um branch (`git checkout -b corrige-nome-x`).
2. Teste no jogo com `/reload` e confira se não aparecem erros (recomendo o addon BugSack).
3. Descreva no PR o que mudou e um exemplo de frase antes/depois.
