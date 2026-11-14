# Curator OctoWoW

Portage de Curator 1.14.3, créé par Clément Hudson, vers OctoWoW et Turtle WoW 1.18.1 sur le client 1.12.1. Cette version de test reprend le moteur original de collection et d’ouverture des boosters. Elle s’installe manuellement et utilise une sauvegarde locale.

## Installation de la version de test

1. Télécharger [Curator-OctoWoW-test-1.12.1.zip](https://github.com/Toracles/Curator-OctoWoW/releases/download/v0.2.0-alpha.2/Curator-OctoWoW-test-1.12.1.zip).
2. Quitter le jeu. Extraire le dossier Curator dans Interface/AddOns. Vérifier que Curator.toc se trouve directement dans Interface/AddOns/Curator. Si ce dossier existe déjà, sauvegarder l’ancienne copie avant de la remplacer.
3. Relancer le jeu, activer **Curator** à la sélection des personnages et taper `/curator`.

Les tests hors jeu couvrent les 226 fichiers Lua, le chargement, la connexion simulée, les tirages d’origine et une ouverture complète jusqu’au retournement des huit cartes. Sur OctoWoW, le rendu, les cinématiques, les événements de combat, la sauvegarde après reconnexion et les échanges entre joueurs restent à valider.

Le port ajoute six albums OctoWoW et 903 cartes. Zephras Isle a été retiré. Le reste du catalogue Forever doit encore être comparé aux données d’OctoWoW. La synchronisation en ligne et la Bourse officielle reposent sur l’application compagnon, hors périmètre de ce portage.

## Sources et archives

- [curator-test](curator-test) contient les scripts exacts de la version de test, avec le fichier TOC et les licences. Les textures et les sons sont inclus dans le ZIP de la préversion.
- [full-port](full-port) et [tools](tools) contiennent les adaptations et les outils de construction et de test.
- [docs/PORTAGE-COMPLET.md](docs/PORTAGE-COMPLET.md) décrit le suivi par fonctionnalité.
- [data](data) contient le catalogue issu de Questie-Octo et ses notices.
- [addon/CuratorOcto](addon/CuratorOcto) conserve le prototype de collection et d’ouverture. La galerie statique reste disponible dans la première préversion.

Les médias et le code d’origine de Curator conservent les droits indiqués dans les licences incluses.

![Aperçu de la galerie initiale](docs/Apercu.png)
