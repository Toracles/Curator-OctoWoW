# Curator OctoWoW

**English** · [Français](README.fr.md)

Curator 1.14.3 ported by CloudNine_Ex to **OctoWoW 1.18.1 on the WoW 1.12.1 client**. Collect creature cards, fill regional albums, and open boosters with Curator’s original reveal animations. The port is a prerelease with local saves and runs entirely in the game client.

## Install or update

1. For a fresh installation, quit OctoWoW and extract the [base ZIP](https://github.com/Toracles/Curator-OctoWoW/releases/download/v0.2.0-alpha.2/Curator-OctoWoW-test-1.12.1.zip) into `Interface/AddOns`. This contains the full addon, artwork, and sounds.
2. Extract the [cumulative alpha.25 patch](https://github.com/Toracles/Curator-OctoWoW/releases/download/v0.2.0-alpha.25/Curator-OctoWoW-correctif-alpha.25.zip) into the same directory and merge the `Curator` folders. If Curator is already installed from the base ZIP, this patch is all you need. Keep your character and account saves in `WTF`.
3. Launch OctoWoW, enable **Curator** on the character selection screen, and enter `/curator`. Set English or French in `/curator options`.

For the optional bilingual gallery, extract [the gallery ZIP](https://github.com/Toracles/Curator-OctoWoW/releases/download/v0.2.0-alpha.17/Curator-OctoWoW-Galerie-FR-EN.zip) into `Interface/AddOns` and restart the game. Open it with `/curatorgallery` or `/curatorgalerie` and use **English / Français**. The gallery includes 259 illustrated cards in each language.

## What’s in the port

- **Catalogue and collection.** Vanilla albums plus 20 OctoWoW albums with 1,269 cards across zones, dungeons, and raids. The port replaces the previous server-specific catalogue and removes retired beta screens and achievements. Creature display IDs were matched to the OctoWoW client where available.
- **Boosters and cases.** The original booster-opening and card-reveal flow, an adjustable booster bar, and a free **Test** button in the booster screen. The collection also includes cases, card finishes, appraisal, protective cases, and restoration.
- **Progress and economy.** Collector levels, quests, achievements, talents, duplicate contracts, and the innkeeper’s loyalty card, visas, and bets. Local ruby prices are halved, and a case key costs 250 rubies at the base rate.
- **Player trades.** Start a live invitation from the blue **Trade (Curator)** entry on a player portrait. After they accept the invitation, both players can preview the cards and boosters being offered. The initiator sends the final offer, and the recipient reviews and accepts it before the transfer. Both players need alpha.23 or later for the live preview. Classic offers remain available through `/curator trade`.
- **Vanilla interface fixes.** Startup and model API compatibility, a reorganized album header and Guide button, and corrected case artwork layering. Alerts, bank panels, and the ruby ledger have opaque backgrounds. Innkeeper actions sit in the native dialogue, with fixes for loyalty stamp animations, dates, and overlapping bet windows. Player tooltips use the game’s own content.

## Catch up on earlier progress

Enter `/curator catchup` to preview uncredited levels, discoveries, and game quests turned in. Claiming and declining each ask for confirmation. Closing the panel postpones the choice. The addon keeps a receipt in both the account and character saves to prevent repeat credits after updates.

Each verified quest turn-in grants **20 booster points** and can advance active Curator objectives that ask you to turn in quests. Completed objectives count toward the corresponding achievements. The client or Questie-Octo supplies the quest history. Past quest-board periods, original turn-in rubies, and past elite kills are outside the import. If an early build already granted levels without recording them, use `/curator catchup 30` with the last level it credited in place of `30`.

## Quick controls

| Action | Control |
| --- | --- |
| Open the collection | `/curator` |
| Preview a booster opening | `/curator boosters` → **Test**. Uses no booster and grants no rewards. |
| Resize or move the booster bar | Mouse wheel over the bar to change width, Ctrl + wheel to scale, Shift + drag to move. Use `/curator bar width 240` for an exact width or `/curator bar reset` to reset it. |
| Trade duplicates for a higher-rarity card | **Contracts** or `/curator contract` |
| Open the player trade interface | Target a player and enter `/curator trade`, or use `/curator trade Name`. With no target, the command opens the trade list. |
| Open language and interface settings | `/curator options` |

## Prerelease status and sources

The automated Lua 5.0 suite covers loading, collection screens, booster reveals, catch-up, and simulated trade invitations and previews. Rendering and a complete trade between two players still need live client verification. This port uses local saves. The original Windows companion, online sync and restore, and the official Exchange are outside its scope.

- [Release notes and downloads](https://github.com/Toracles/Curator-OctoWoW/releases)
- [Addon scripts and licenses](curator-test) · [Port source](full-port) · [Build and test tools](tools) · [Porting notes in French](docs/PORTAGE-COMPLET.md)
- [Questie-Octo catalogue data and notices](data) · [Creature display ID mappings](data/OctoDisplayIDs.tsv)

The original Curator code, artwork, and data retain the rights stated in the [addon license](curator-test/LICENSE.txt) and [data notice](curator-test/Data/NOTICE.txt).

![Preview of the original OctoWoW gallery](docs/Apercu.png)
