# Curator sur OctoWoW

## Catalogue de départ

Candidats-cartes.csv contient 422 associations PNJ-album tirées des fichiers de données bruts de pfQuest-octo (commit dd3dc1fb80afe7a71e5c8ca8c31ca2a3ef57af67). Les corrections Lua de pfQuest-octo ne sont pas appliquées. Les noms sont ceux de la base anglaise. La liste peut inclure des PNJ neutres et un même PNJ peut apparaître dans plusieurs zones.

Les coordonnées et identifiants de zone suffisent pour proposer un album. La rareté, le modèle, le portrait et les boss de fin restent à renseigner à partir de données adaptées au client 1.12.1. Northwind (5581) est nommé dans la base, mais le fichier brut des PNJ ne fournit aucun point d'apparition directement rattaché à cet identifiant. Vérifier les sous-zones et une source de données complémentaire avant d'ajouter cet album.

## Retraits et adaptations

- Reconstituer les albums à partir des PNJ présents dans la zone sur OctoWoW. Comparer l'identifiant, le nom et la zone ensemble, car un identifiant seul peut désigner des créatures différentes selon le client.
- Retirer Zephras Isle et passer en revue les cartes et références de Forever dans les albums classiques, les récompenses, les portraits, les cinématiques et les quêtes.
- Remplacer le chargement Lua moderne (espace de noms passé via `...`) et les signatures modernes des événements. Reprendre les API de zone, de quêtes et de dialogue, puis les mécanismes de classement des activités (XP, boss, découvertes).
- Adapter les temporisations et revoir les modèles d'interface, les masques et les atlas. Vérifier que le client charge les textures et les sons retenus.
- Garder les sauvegardes OctoWoW séparées des sauvegardes Forever pendant la validation.

## Tests en jeu après portage

1. Lancer sur un profil OctoWoW 1.12.1 vierge, activer Curator et vérifier que la commande et l'album s'ouvrent sans erreur Lua.
2. Contrôler les albums classiques et les cinq albums proposés, ainsi que l'absence de Zephras Isle. Vérifier un nom et une illustration de carte dans chaque album.
3. Gagner de l'XP sur un monstre, rendre une quête, changer de zone et terminer un donjon avec un album. Vérifier la barre concernée et le booster obtenu.
4. Ouvrir un booster, vérifier la collection, exécuter /reload, puis quitter et reconnecter pour confirmer la persistance.
5. Tester au minimum les clients français et anglais pour la reconnaissance des zones et des événements.

Source du catalogue : https://github.com/paokkerkir/pfQuest-octo/tree/dd3dc1fb80afe7a71e5c8ca8c31ca2a3ef57af67
Référence de l'audit : Curator 1.14.3 pour Forever 1.60.1, archive CurseForge 9473112. La licence incluse soumet la modification du code et des médias à l'accord écrit de l'auteur. Le dossier Data porte une licence GPL-3.0.
