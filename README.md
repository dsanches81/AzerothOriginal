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
- Rastreador do **Questie**: cabeçalhos de zona e objetivos
- **Nomes de NPCs** (opcional, `/azo npcs on`): "Magistrado Salomão" → "Magistrate Solomon", também nas tooltips, objetivos e no chat

Não altera: áudio dublado, livros e cartas do jogo, rastreador de objetivos e chat de jogadores.

## Instalação

1. Baixe o repositório (botão **Code → Download ZIP**) ou a release mais recente.
2. Copie a pasta `AzerothOriginal` para `World of Warcraft\_forever_\Interface\AddOns\` (a pasta precisa se chamar exatamente `AzerothOriginal`).
3. Entre no jogo e digite `/azo` para abrir as opções.

Tudo já vem pronto: os mais de 7.800 nomes de lugares e 8.200 de NPCs estão incluídos no addon. Não é preciso instalar nem rodar mais nada.

### Opções

Digite `/azo` para abrir a janela de opções (também em **Opções → AddOns → Azeroth Original**): liga/desliga por área (missões, mapas, tooltips, chat, rastreador), nomes de NPCs, status da integração com o Questie e uma caixa para testar frases.

### Comandos

| Comando | O que faz |
|---|---|
| `/azo` | Abre a janela de opções |
| `/azo status` | Status no chat |
| `/nomes on` / `/nomes off` | Liga / desliga |
| `/nomes teste <texto>` | Mostra como um texto ficaria |
| `/azo npcs on` / `/azo npcs off` | Liga / desliga a troca dos **nomes de NPCs** (desligada por padrão) |
| `/azo add` | Com o mouse sobre um texto que não foi trocado, passa a revisar aquele quadro (útil para outros addons) |
| `/azo quadros` | Lista os quadros adicionados com `/azo add` |

## Como funciona

O `Data.lua` tem cerca de 7.500 pares *nome em português → nome original*, gerados a partir das tabelas do próprio jogo (`AreaTable`, `Map`, `UiMap`), cruzando a versão enUS com a ptBR pelo ID. O addon procura esses nomes no texto exibido (do mais longo para o mais curto, respeitando limites de palavra, códigos de cor e links) e troca pelo original.

Regras extras:
- Se o original começa com "The" e já existe um artigo antes no português ("as Terras Agrestes"), o "The" é removido ("as Hinterlands").
- Nomes em português com artigo ("A Vila de Brisabela") também são encontrados sem ele ("na Vila de Brisabela").
- Palavras comuns que também são nome de subzona (Inferno, Refúgio, Continente…) ficam bloqueadas em `Config.lua`.

## Contribuindo

Achou um nome trocado errado, um nome faltando ou uma janela que não é traduzida? Veja o [CONTRIBUTING.md](CONTRIBUTING.md).

## Apoie o projeto

O Azeroth Original é feito pelo **Party de Dois**, um casal que joga e faz lives. Se o addon deixou suas jornadas mais com cara de 2005 e você quiser ajudar a mantê-lo atualizado a cada patch:

- 💙 **Doação via PayPal:** [paypal.me/partydedois](https://paypal.me/partydedois)
- 🎮 **Twitch:** [twitch.tv/partydedois](https://www.twitch.tv/partydedois)
- 📱 **TikTok:** [tiktok.com/@partydedois](https://www.tiktok.com/@partydedois)

Reportar bugs ou nomes errados nas *issues* ajuda tanto quanto!

## Licença

[GPLv3](LICENSE), a mesma licença do Questie e do QuestieDB, de onde vêm os dados de NPCs e de zonas do rastreador. World of Warcraft e os nomes do jogo são marcas da Blizzard Entertainment. Este projeto não é afiliado à Blizzard.
