## Rattrapage de l’exploration et des niveaux

La commande `/curator rattrapage` crédite les niveaux atteints et les lieux déjà révélés que ClassicAPI permet d’identifier. Les anciens niveaux sans zone associée donnent des récompenses à choisir lorsque la barre se remplit. Les découvertes alimentent l’album de leur zone.

Pour une sauvegarde plus ancienne ayant déjà reçu des points de niveau, le premier lancement peut préciser le dernier niveau crédité, par exemple `/curator rattrapage 30`. Le suivi déduplique les crédits du rattrapage, les niveaux suivis depuis cette version et les lieux déjà présents dans la sauvegarde. Le jeu ne fournit pas l’historique des combats d’élite.

Les 221 scripts compilent en Lua 5.0. Les tests simulés couvrent le niveau 37, les découvertes déjà créditées, les portions de carte ambiguës, une seconde exécution et la récompense de la barre.

Installer [le ZIP de base alpha.2](https://github.com/Toracles/Curator-OctoWoW/releases/tag/v0.2.0-alpha.2), puis appliquer ce correctif cumulatif dans `Interface/AddOns`. Si Curator est déjà installé depuis le ZIP de base, appliquer directement le correctif et taper `/reload`.
