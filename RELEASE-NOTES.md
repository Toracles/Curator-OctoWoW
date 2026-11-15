## Compatibilité des interfaces avec le client 1.12.1

- Adaptation des scripts des fenêtres et boutons aux événements 1.12.1. Les nouveaux gestionnaires conservent les scripts déjà installés sur le même objet.
- Adaptation des mesures de texte et de cadres, ainsi que des appels optionnels sur les boutons, textures et champs de saisie.
- Fond opaque pour les fenêtres sur le client 1.12.1 afin que les éléments du HUD restent derrière leur contenu.

Les 221 fichiers compilent en Lua 5.0. Les tests simulés couvrent trente commandes d’interface, l’inventaire de boosters vide, le redimensionnement de la barre à la molette et une ouverture de booster jusqu’au retournement des cartes. Le rendu, les cinématiques et les interactions entre joueurs restent à valider dans OctoWoW.

Installer d’abord [le ZIP de base alpha.2](https://github.com/Toracles/Curator-OctoWoW/releases/tag/v0.2.0-alpha.2), puis extraire ce correctif cumulatif dans `Interface/AddOns`, jeu fermé. Si Curator est déjà installé depuis le ZIP de base, appliquer directement ce correctif.
