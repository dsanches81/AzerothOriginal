# Azeroth Original

**English** · [Português](#português)

An addon for **World of Warcraft: Forever** for Brazilian Portuguese (ptBR) players: keep the game in Portuguese, but see the **original English names** of places (and, optionally, NPCs and items) everywhere in the interface.

Made for veterans who played before the Portuguese localization existed and still think of *Stormwind*, *Ironforge* and *Elwynn Forest*, not *Ventobravo*, *Altaforja* and *Floresta de Elwynn*.

> Leve esta carta ao ferreiro em Vila d'Ouro, na Floresta de Elwynn, e depois siga para Ventobravo.
>
> **becomes**
>
> Leve esta carta ao ferreiro em Goldshire, na Elwynn Forest, e depois siga para Stormwind.

### Where it works
- Quest text, objectives and rewards, NPC dialogue (gossip) and Talking Heads
- Maps: world map titles and hover labels, minimap, zone text, flight map
- Tooltips, NPC speech and system messages in chat ("You discovered Raven Hill")
- Questie tracker and other addons' text (e.g. EllesmereUI) via the comprehensive mode
- **Optional:** NPC names ("Magistrado Salomão" → "Magistrate Solomon") and item names ("Escamas Cristalizadas" → "Crystalized Scales"), handy for searching international sites like Wowhead

Player chat is never changed.

### Limitations
- **Names floating above NPCs' heads** are drawn by the game engine, and no API lets an addon change that text.
- **Voiced audio** (including voice addons like Spoken) keeps the Portuguese names.
- **Names painted into the map artwork** are part of the image and cannot be changed.

### Usage
Type `/azo` to open the options window (also under Options → AddOns). Everything is included: over 7,800 place names, 8,200 NPC names and 16,000 item names. No setup needed.

### Support
Made by **Party de Dois**: [PayPal](https://paypal.me/partydedois) · [Twitch](https://www.twitch.tv/partydedois) · [TikTok](https://www.tiktok.com/@partydedois)

License: GPLv3. World of Warcraft is a trademark of Blizzard Entertainment; this project is not affiliated with Blizzard.

---

## Português

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
- **Nomes de itens** (opcional, `/azo itens on`): "Escamas Cristalizadas" → "Crystalized Scales". Útil para pesquisar em sites internacionais como o Wowhead

Não altera o chat de jogadores, por escolha.

### Limitações (o que nenhum addon consegue mudar)

- **Nomes flutuando sobre a cabeça dos NPCs e jogadores**: são desenhados direto pelo motor do jogo no mundo 3D, não pela interface. A Blizzard não oferece nenhuma API que permita a um addon alterar esse texto (só a fonte). Alternativa: desligue os nomes do jogo e use nameplates de NPCs amigáveis de um addon (ex.: EllesmereUI); essas o Azeroth Original consegue trocar, fora de masmorras e raides.
- **Áudio dublado** (falas dos NPCs e de addons de voz como o Spoken): o áudio é gravado, então o NPC continua falando o nome em português.
- **Textos "lacrados" pelo jogo**: em algumas situações o motor entrega certos textos aos addons de forma protegida (secret values); esses são ignorados por segurança.
- **Nomes pintados na arte do mapa** (ex.: "BOCA DA MATA", "MORRO DA SENTINELA" no mapa de zona): fazem parte da imagem do mapa, que o jogo carrega só no idioma instalado. Nenhum addon consegue trocá-los. Os nomes que são texto (títulos, rótulos ao passar o mouse, legendas e tooltips) são trocados normalmente. `/azo mapa` lista quais nomes do mapa aberto são texto.

## Instalação

1. Baixe o repositório (botão **Code → Download ZIP**) ou a release mais recente.
2. Copie a pasta `AzerothOriginal` para `World of Warcraft\_forever_\Interface\AddOns\` (a pasta precisa se chamar exatamente `AzerothOriginal`).
3. Entre no jogo e digite `/azo` para abrir as opções.

Tudo já vem pronto: os mais de 7.800 nomes de lugares, 8.200 de NPCs e 16.000 de itens estão incluídos no addon. Não é preciso instalar nem rodar mais nada.

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
| `/azo itens on` / `/azo itens off` | Liga / desliga a troca dos **nomes de itens** (desligada por padrão) |
| `/azo mapa` | Com o mapa aberto, lista os textos do mapa (para diagnóstico) |
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
