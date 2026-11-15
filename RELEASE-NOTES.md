## Modèles des cartes OctoWoW

- 784 cartes supplémentaires ont un modèle. Le catalogue OctoWoW passe de 467 à 1 251 cartes avec un identifiant de modèle sur 1 269. Balor passe de 0 à 55 sur 57.
- 687 identifiants de PNJ proviennent des fiches de la base publique OctoWoW et 96 de l’export Turtle WoW de ShellLab. Les correspondances ShellLab ont été vérifiées par nom et par ID de PNJ. Les modèles ajoutés sont présents dans la table `CreatureDisplayInfo.dbc` du client installé.
- Les 18 cartes restantes conservent leur présentation sans modèle.

Les 221 scripts compilent en Lua 5.0. Les tests simulés couvrent l’affichage de toutes les cartes de Balor et une ouverture de booster. Le rendu des modèles reste à vérifier en jeu.

Installer [le ZIP de base alpha.2](https://github.com/Toracles/Curator-OctoWoW/releases/tag/v0.2.0-alpha.2), puis appliquer ce correctif cumulatif dans `Interface/AddOns`. Si Curator est déjà installé depuis le ZIP de base, appliquer directement ce correctif et taper `/reload`.
