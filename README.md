# Curator OctoWoW

Portage de Curator 1.14.3, adapté par CloudNine_Ex pour OctoWoW 1.18.1 sur le client 1.12.1. Cette version de test reprend le moteur original de collection et d’ouverture des boosters. Elle s’installe manuellement et utilise une sauvegarde locale.

## Installation de la version de test

1. Télécharger [Curator-OctoWoW-test-1.12.1.zip](https://github.com/Toracles/Curator-OctoWoW/releases/download/v0.2.0-alpha.2/Curator-OctoWoW-test-1.12.1.zip).
2. Quitter le jeu, extraire le dossier Curator dans Interface/AddOns, puis appliquer [le correctif cumulatif alpha.10](https://github.com/Toracles/Curator-OctoWoW/releases/tag/v0.2.0-alpha.10) au même emplacement.
3. Relancer le jeu, activer **Curator OctoWoW** à la sélection des personnages et taper `/curator`.

Les tests hors jeu couvrent les 221 fichiers Lua, le chargement, la connexion simulée, trente commandes d’interface et une ouverture complète jusqu’au retournement des huit cartes. Sur OctoWoW, le rendu, les cinématiques, les événements de combat, la sauvegarde après reconnexion et les échanges entre joueurs restent à valider.

Le port intègre 20 albums OctoWoW et 1 269 cartes associées, en plus des albums Vanilla vérifiés avec Questie-Octo. La synchronisation et la Bourse officielle restent hors périmètre.

## Barre de boosters

Ouvrir `/curator boosters` et cliquer sur **Tester** à gauche du booster pour jouer l’animation de l’album affiché. Cet aperçu ne dépense aucun booster et ne rapporte ni carte ni expérience.

Survoler la barre et tourner la molette pour modifier sa largeur. Ctrl + molette règle son échelle. Maj + glisser déplace la barre. Utiliser `/curator bar width 240` pour une largeur précise et `/curator bar reset` pour rétablir les réglages par défaut.

## Sources et archives

- [curator-test](curator-test) contient les scripts exacts de la version corrigée, avec le fichier TOC et les licences. Les textures et les sons sont inclus dans le ZIP de base alpha.2.
- [full-port](full-port) et [tools](tools) contiennent les adaptations et les outils de construction et de test.
- [docs/PORTAGE-COMPLET.md](docs/PORTAGE-COMPLET.md) décrit le suivi par fonctionnalité.
- [data](data) contient le catalogue issu de Questie-Octo et ses notices.
- [OctoDisplayIDs.tsv](data/OctoDisplayIDs.tsv) associe les PNJ aux modèles de la base OctoWoW et de l’export Turtle WoW de ShellLab. Les correspondances ShellLab ont été vérifiées par ID et par nom. Chaque modèle ajouté est présent dans `CreatureDisplayInfo.dbc` du client OctoWoW. [Base OctoWoW](https://octowow.st/db/), [export ShellLab](https://github.com/oplancelot/ShellLab/blob/main/data/shelllab.db)
- [addon/CuratorOcto](addon/CuratorOcto) conserve le prototype de collection et d’ouverture. La galerie statique reste disponible dans la première préversion.

Les médias et le code d’origine de Curator conservent les droits indiqués dans les licences incluses.

![Aperçu de la galerie initiale](docs/Apercu.png)
