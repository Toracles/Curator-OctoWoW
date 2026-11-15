## Sauvegarde des crédits de rattrapage

Curator conserve les crédits de niveau et d’exploration dans la collection et dans un registre par personnage. Lors de la migration depuis alpha.15, Curator reprend les crédits existants. Si une copie manque, l’autre fournit les crédits qui doivent être ignorés lors d’un nouveau rattrapage.

Le premier lancement de `/curator rattrapage` crédite les niveaux et les découvertes retrouvées. Le test Lua 5.0 couvre un personnage niveau 37 sans crédit préalable et vérifie qu’aucun crédit ne s’ajoute lors d’une nouvelle exécution après perte de l’une des deux copies.

Installer [le ZIP de base alpha.2](https://github.com/Toracles/Curator-OctoWoW/releases/tag/v0.2.0-alpha.2), puis appliquer le correctif cumulatif dans `Interface/AddOns`. Sur une installation existante, appliquer uniquement le correctif. Quitter puis relancer complètement OctoWoW pour activer la nouvelle sauvegarde par personnage.
