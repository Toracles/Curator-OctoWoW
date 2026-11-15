# Curator OctoWoW

Portage de Curator 1.14.3, adapté par CloudNine_Ex pour OctoWoW 1.18.1 sur le client 1.12.1. Cette version de test reprend le moteur original de collection et d’ouverture des boosters. Elle s’installe manuellement et utilise une sauvegarde locale.

## Installation de la version de test

1. Télécharger [Curator-OctoWoW-test-1.12.1.zip](https://github.com/Toracles/Curator-OctoWoW/releases/download/v0.2.0-alpha.2/Curator-OctoWoW-test-1.12.1.zip).
2. Quitter le jeu, extraire le dossier Curator dans Interface/AddOns, puis appliquer [le correctif cumulatif alpha.20](https://github.com/Toracles/Curator-OctoWoW/releases/tag/v0.2.0-alpha.20) au même emplacement.
3. Relancer le jeu, activer **Curator OctoWoW** à la sélection des personnages et taper `/curator`.

Les tests hors jeu couvrent les 221 fichiers Lua, le chargement, la connexion simulée, trente commandes d’interface et une ouverture complète jusqu’au retournement des huit cartes. Sur OctoWoW, le rendu, les cinématiques, les événements de combat, la sauvegarde après reconnexion et les échanges entre joueurs restent à valider.

Le port intègre 20 albums OctoWoW et 1 269 cartes associées, en plus des albums Vanilla vérifiés avec Questie-Octo. La synchronisation et la Bourse officielle restent hors périmètre.

## Rattrapage d’un personnage existant

Le panneau apparaît après la connexion lorsqu’un rattrapage est disponible. Il détaille les niveaux, les découvertes, les points, les récompenses à choisir, les boosters de zone et la progression de la barre. Récupérer ou refuser demande une confirmation. Fermer le panneau reporte le choix. Un refus confirmé est définitif pour les récompenses affichées. Pour rouvrir le panneau, taper `/curator rattrapage` ou `/curator catchup`.

Les anciennes versions ne mémorisaient pas quels passages de niveau avaient déjà rapporté des points. Si l’ancien addon t’a déjà crédité jusqu’au niveau 30, lance `/curator rattrapage 30` la première fois. Les lieux déjà enregistrés et les niveaux suivis depuis alpha.15 sont dédupliqués. Les cartes sans données d’exploration, les lieux qu’une portion de carte ne permet pas de distinguer et l’historique des combats d’élite restent hors import.

Le registre des crédits est écrit dans la sauvegarde Curator du compte et dans une sauvegarde Curator propre au personnage, sous `WTF`. Curator fusionne les deux copies et reprend les crédits des versions précédentes.

## Prix et langues

Les prix locaux en rubis sont divisés par deux. Les clés de caisse sont divisées par quatre, soit 250 rubis au prix de base. Les prix positifs sont arrondis au rubis le plus proche avec un minimum d’un rubis.

La langue de Curator se choisit dans `/curator options`. La galerie est un addon séparé, disponible dans la [release alpha.17](https://github.com/Toracles/Curator-OctoWoW/releases/tag/v0.2.0-alpha.17). Après avoir extrait `CuratorOctoGalerie` dans `Interface/AddOns`, relancer complètement le jeu, ouvrir `/curatorgalerie` ou `/curatorgallery`, puis utiliser le bouton **English / Français**. Les intitulés repris du catalogue gardent leur nom de référence.

## Barre de boosters

Ouvrir `/curator boosters` et cliquer sur **Tester** à gauche du booster pour jouer l’animation de l’album affiché. Cet aperçu ne dépense aucun booster et ne rapporte ni carte ni expérience.

Survoler la barre et tourner la molette pour modifier sa largeur. Ctrl + molette règle son échelle. Maj + glisser déplace la barre. Utiliser `/curator bar width 240` pour une largeur précise et `/curator bar reset` pour rétablir les réglages par défaut.

## Sources et archives

- [curator-test](curator-test) contient les scripts exacts de la version corrigée, avec le fichier TOC et les licences. Les textures et les sons sont inclus dans le ZIP de base alpha.2.
- [full-port](full-port) et [tools](tools) contiennent les adaptations et les outils de construction et de test.
- [docs/PORTAGE-COMPLET.md](docs/PORTAGE-COMPLET.md) décrit le suivi par fonctionnalité.
- [data](data) contient le catalogue issu de Questie-Octo et ses notices.
- [OctoDisplayIDs.tsv](data/OctoDisplayIDs.tsv) associe les PNJ aux modèles de la base OctoWoW et de l’export Turtle WoW de ShellLab. Les correspondances ShellLab ont été vérifiées par ID et par nom. Chaque modèle ajouté est présent dans `CreatureDisplayInfo.dbc` du client OctoWoW. [Base OctoWoW](https://octowow.st/db/), [export ShellLab](https://github.com/oplancelot/ShellLab/blob/main/data/shelllab.db)
- [addon/CuratorOcto](addon/CuratorOcto) conserve le prototype de collection et d’ouverture.

Les médias et le code d’origine de Curator conservent les droits indiqués dans les licences incluses.

![Aperçu de la galerie initiale](docs/Apercu.png)
