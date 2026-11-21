# Azeroth Original

Addon para **World of Warcraft: Forever** que mantém o jogo em **português (ptBR)**, mas mostra os **nomes de lugares originais em inglês** nos textos de missões e diálogos.

Feito para quem joga desde antes da tradução e se acostumou com *Stormwind*, *Ironforge* e *Elwynn Forest*.

> Leve esta carta ao ferreiro em Vila d'Ouro, na Floresta de Elwynn, e depois siga para Ventobravo.
>
> **vira**
>
> Leve esta carta ao ferreiro em Goldshire, na Elwynn Forest, e depois siga para Stormwind.

## Onde ele atua

- Texto de missões: descrição, objetivos, progresso e recompensa (janela do NPC e diário de missões)
- Diálogos de NPC (gossip): fala inicial e opções
- Talking Head (o quadro com o rosto do NPC)
- Falas de NPC no chat: diz, grita, sussurra, emotes de chefe
- Mapas: minimapa, aviso ao entrar numa zona, mapa-múndi e mapa de voo
- Tooltips: pinos do mapa, pontos de voo, pedra de regresso etc.

Não altera: áudio dublado, livros e cartas do jogo, rastreador de objetivos e chat de jogadores.

## Instalação

1. Baixe o repositório (botão **Code → Download ZIP**) ou a release mais recente.
2. Copie a pasta `AzerothOriginal` para `World of Warcraft\_forever_\Interface\AddOns\` (a pasta precisa se chamar exatamente `AzerothOriginal`).
3. Entre no jogo e digite `/nomes` para ver quantos nomes foram carregados.

### Comandos

| Comando | O que faz |
|---|---|
| `/nomes` ou `/azo` | Status e quantidade de nomes carregados |
| `/nomes on` / `/nomes off` | Liga / desliga |
| `/nomes teste <texto>` | Mostra como um texto ficaria |

## Como funciona

O `Data.lua` tem cerca de 7.500 pares *nome em português → nome original*, gerados a partir das tabelas do próprio jogo (`AreaTable`, `Map`, `UiMap`), cruzando a versão enUS com a ptBR pelo ID. O addon procura esses nomes no texto exibido (do mais longo para o mais curto, respeitando limites de palavra, códigos de cor e links) e troca pelo original.

Regras extras:
- Se o original começa com "The" e já existe um artigo antes no português ("as Terras Agrestes"), o "The" é removido ("as Hinterlands").
- Nomes em português com artigo ("A Vila de Brisabela") também são encontrados sem ele ("na Vila de Brisabela").
- Palavras comuns que também são nome de subzona (Inferno, Refúgio, Continente…) ficam bloqueadas em `Config.lua`.

## Atualizando os dados (a cada patch grande)

```
cd tools
python gerar_dados.py
```

Precisa só de Python 3 (biblioteca padrão). Se o download falhar, baixe os CSVs à mão no [wago.tools](https://wago.tools) e use `python gerar_dados.py --pasta <pasta>` (instruções no topo do script).

## Contribuindo

Achou um nome trocado errado, um nome faltando ou uma janela que não é traduzida? Veja o [CONTRIBUTING.md](CONTRIBUTING.md).

## Licença

[MIT](LICENSE). World of Warcraft e os nomes do jogo são marcas da Blizzard Entertainment. Este projeto não é afiliado à Blizzard.
