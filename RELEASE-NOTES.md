## Affichage des cartes dans les albums

- Correction du blocage dans la grille des cartes quand le client ne dispose pas de `SetPortraitZoom` ou des autres réglages facultatifs de caméra et d’animation.
- Les cartes sans identifiant de modèle s’affichent avec leur cadre. Le jeu conserve le cadrage par défaut lorsque les réglages de caméra sont indisponibles.
- Le retournement standard reste disponible quand la cinématique de créature ne peut pas démarrer.

Les 221 scripts compilent en Lua 5.0. Les tests simulés couvrent les 57 cartes de Balor, la première page de chaque album et l’ouverture standard des boosters. Le rendu en jeu reste à vérifier.

Installer [le ZIP de base alpha.2](https://github.com/Toracles/Curator-OctoWoW/releases/tag/v0.2.0-alpha.2), puis appliquer ce correctif cumulatif dans `Interface/AddOns`. Si Curator est déjà installé depuis le ZIP de base, appliquer directement ce correctif et taper `/reload`.
