# Curator OctoWoW

**English** · [Français](README.fr.md)

Curator 1.14.3 ported by CloudNine_Ex to **OctoWoW 1.18.1 on the WoW 1.12.1 client**. Collect creature cards, fill regional albums, open boosters and cases, and trade with other players. The current prerelease is **alpha.38**. Collection saves are local. [License scope](LICENSE-SCOPE.md)

## Requirements

| Feature | Requirement |
| --- | --- |
| Base addon | OctoWoW on the WoW 1.12.1 client, the base ZIP and the cumulative patch. The TOC declares zero mandatory addon dependencies. |
| Available 3D creature models and exploration catch-up | Load `ClassicAPI.dll` through your OctoWoW launcher. The reference installation uses **ClassicAPI 1.20.6**. For manual setup, place the DLL alongside `WoW.exe`, add it to `dlls.txt`, and launch through VanillaFixes. [ClassicAPI](https://github.com/brues-code/ClassicAPI#installation) · [OctoWoW Modernization Tool](https://octowow.st/git/Dusk/Modernization-Tool/src/branch/main/README.md) |
| Quest catch-up | Confirmed turn-in history from the client or [Questie-Octo](https://github.com/SandreaSub/Questie-Octo). |
| Live trades | Curator OctoWoW **alpha.23 or later** on both players’ clients. |
| Optional Mythic voices | **SoftSpoken** with public API v1 (the reference installation uses **0.8.1-beta**) and the separate bilingual voice pack. |
| Optional gallery | The separate English/French gallery ZIP. |

Hoard is optional and handles legacy save migration. DXVK, HD packs, SuperWoW and Nampower are separate client options. The release ZIPs install directly into the game. Node.js, Python, Lua, Piper and FFmpeg are used for maintenance, testing or asset generation.

## Install or update

1. For a fresh installation, quit OctoWoW and extract the [base ZIP](https://github.com/Toracles/Curator-OctoWoW/releases/download/v0.2.0-alpha.2/Curator-OctoWoW-test-1.12.1.zip) into `Interface/AddOns`. This contains the full addon, artwork, and sounds.
2. Close OctoWoW before applying the [cumulative alpha.38 patch](https://github.com/Toracles/Curator-OctoWoW/releases/download/v0.2.0-alpha.38/Curator-OctoWoW-correctif-alpha.38.zip). Extract it into the same directory and merge the `Curator` folders. If Curator is already installed from the base ZIP, this patch is all you need. Keep your character and account saves in `WTF`.
3. Launch OctoWoW, enable **Curator** on the character selection screen, and enter `/curator`. Set English or French in `/curator options`.

For the optional bilingual gallery, extract [the gallery ZIP](https://github.com/Toracles/Curator-OctoWoW/releases/download/v0.2.0-alpha.17/Curator-OctoWoW-Galerie-FR-EN.zip) into `Interface/AddOns` and restart the game. Open it with `/curatorgallery` or `/curatorgalerie` and use **English / Français**. The gallery includes 259 illustrated cards in each language.

## What’s in the port

- **Catalogue and collection.** Vanilla albums plus 20 OctoWoW albums with 1,269 cards across zones, dungeons, and raids. The port replaces the previous server-specific catalogue and removes retired beta screens and achievements. Creature display IDs were matched to the OctoWoW client where available.
- **Boosters and cases.** Animated openings, an adjustable booster bar, and a free **Test** button that automatically reveals the cards. Available 3D models follow the card as it moves or flips. Case previews show available NPC models without hovering. The collection also includes card finishes, appraisal, protective cases, and restoration.
- **Inspection and Mythic entrances.** Inspect a revealed card to turn it, flip it or zoom in. Mythic entrances play on reveal when cinematics are enabled, with a title banner adapted for the 1.12.1 client. Eligible cards can replay the entrance from the inspection view.
- **Progress and economy.** Collector levels, quests, achievements, talents, duplicate contracts, and the innkeeper’s loyalty card, visas, and bets. Local ruby prices are halved, and a case key costs 250 rubies at the base rate.
- **Player trades.** Start a live invitation from the blue **Trade (Curator)** entry on a player portrait. After they accept the invitation, both players can preview the cards and boosters being offered. The initiator sends the final offer, and the recipient reviews and accepts it before the transfer. Both players need alpha.23 or later for the live preview. Classic offers remain available through `/curator trade`.
- **Vanilla interface fixes.** Startup and model API compatibility, a reorganized album header and Guide button, and corrected case artwork layering. Alerts, bank panels, and the ruby ledger have opaque backgrounds. Innkeeper actions sit in the native dialogue, with fixes for loyalty stamp animations, dates, and overlapping bet windows. Player tooltips use the game’s own content.

## Optional Mythic voices

Extract `Curator-SoftSpoken-Mythic-Voices-EN-FR.zip` from the [Curator release](https://github.com/Toracles/Curator-OctoWoW/releases/tag/v0.2.0-alpha.38) into `Interface/AddOns` with the game closed. Relaunch the game with SoftSpoken enabled, then enable **Mythic voices via SoftSpoken** in Curator options.

The pack covers 75 Mythic cards with 74 distinct lines recorded in both English and French. Curator's interface language selects the recording and captions. Curator uses its original audio when SoftSpoken cannot start the clip immediately. On the 1.12.1 client, skipping a line SoftSpoken is playing may briefly interrupt other sound effects. The pack includes credits for the two Piper voice models.

## Catch up on earlier progress

Enter `/curator catchup` to preview uncredited levels, discoveries, and game quests turned in. Claiming and declining each ask for confirmation. Closing the panel postpones the choice. The addon keeps a receipt in both the account and character saves to prevent repeat credits after updates.

Each verified quest turn-in grants **20 booster points** and can advance active Curator objectives that ask you to turn in quests. Completed objectives count toward the corresponding achievements. The client or Questie-Octo supplies the quest history. Past quest-board periods, original turn-in rubies, and past elite kills are outside the import. If an early build already granted levels without recording them, use `/curator catchup 30` with the last level it credited in place of `30`.

## Quick controls

| Action | Control |
| --- | --- |
| Open the collection | `/curator` |
| Save the collection | Click the scroll in the title bar or use `/curator save`. Confirm the return to character selection to save. Curator confirms the save when you log back in shortly afterward. |
| Preview a booster opening | `/curator boosters` → **Test**. Uses no booster and grants no rewards. |
| Inspect a revealed card | Click a revealed booster card or select **Inspect** after a case. Drag to rotate, click to flip, and scroll to zoom. Use **Replay its entrance** where available. |
| Open collection cases | Open one case at its normal speed, or choose **5×**, **10×** or **20×** for faster consecutive reveals. Closing the scene stops the remaining openings. |
| Resize or move the booster bar | Mouse wheel over the bar to change width, Ctrl + wheel to scale, Shift + drag to move. Use `/curator bar width 240` for an exact width or `/curator bar reset` to reset it. |
| Trade duplicates for a higher-rarity card | **Contracts** or `/curator contract`. The parchment burns away before the reward appears. For case contracts, the reward details appear when you flip the card. |
| Open the player trade interface | Target a player and enter `/curator trade`, or use `/curator trade Name`. With no target, the command opens the trade list. |
| Open language and interface settings | `/curator options` |
| Redeem a gift code | `/curator gift` or **Boosters → Gift code**. Paste the code, check the rewards, then select **Redeem**. |

## Issuing gift codes

The maintainer can issue an OctoWoW gift for a specific character and realm or a 16-digit hexadecimal collection ID. Issuing requires Node.js and the private key that matches the public key shipped in the addon. On Windows the default private key location is `%LOCALAPPDATA%\Curator-OctoWoW\gift-signing.pem`. Keep the private key out of the repository. Codes expire after 30 days by default.

```powershell
node tools/gift-code.cjs issue --to "Character-Realm" --zone 1 --rubies 100 --days 30
```

Other reward options are `--dungeon`, `--raid`, `--xp` and `--display ALBUM:COUNT` for an eligible album key. Use `--note` to include a message.

## Prerelease status and sources

The automated Lua 5.0 suite checks all 221 loaded Lua files and exercises startup, inspection, full-screen and compact booster reveals, case batches and cancellation, contracts, catch-up, gift redemption, trade invitations, and Mythic voice selection in both languages. The optional pack was checked for **148 audio files** and matching manifest entries. Live graphical rendering, in-game audio playback and a complete trade between two players still need verification on OctoWoW.

Collection saves stay local. The Windows companion, online sync and restore, and the official Exchange are outside the port’s scope.

- [Release notes and downloads](https://github.com/Toracles/Curator-OctoWoW/releases)
- [Addon scripts and licenses](curator-test) · [Port source](full-port) · [Build and test tools](tools) · [Porting notes in French](docs/PORTAGE-COMPLET.md)
- [Questie-Octo catalogue data and notices](data) · [Creature display ID mappings](data/OctoDisplayIDs.tsv)

## License

The marked standalone port utilities use [GNU GPL version 3](LICENSE). See the [license scope and upstream notices](LICENSE-SCOPE.md) for the original Curator addon, artwork, data and the optional voice pack.

![Preview of the original OctoWoW gallery](docs/Apercu.png)
