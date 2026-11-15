## Rattrapage au choix

Un panneau s’ouvre lorsqu’un personnage a des récompenses rétroactives à récupérer. Il présente les niveaux, les découvertes, les points de booster, les récompenses à choisir, les boosters de zone et la progression de la barre après récupération. Chaque décision demande une confirmation. Fermer le panneau reporte le choix. Un refus confirmé est définitif pour les récompenses affichées.

`/curator rattrapage` et `/curator catchup` rouvrent le panneau. Pour un ancien Curator qui a déjà crédité des niveaux sans les journaliser, ajouter le dernier niveau déjà crédité à la commande, par exemple `/curator rattrapage 30`.

Le registre du compte et celui du personnage sont fusionnés afin d’éviter les doubles crédits après une mise à jour. Le rattrapage couvre les niveaux et les découvertes confirmées par le client. L’historique des élites tués est indisponible.

## Prix et langues

- Prix locaux en rubis divisés par deux et clés de caisse divisées par quatre. Une clé coûte 250 rubis au tarif de base après arrondi. Les tarifs de reprise et de rachat ont aussi été ajustés.
- Français et anglais dans l’addon principal via `/curator options`.
- Français et anglais dans la galerie via le bouton **English / Français**. Chaque version contient les 259 cartes illustrées. Ouvrir la galerie avec `/curatorgalerie` ou `/curatorgallery`.

## Installation

Quitter complètement OctoWoW. Sur une installation existante, extraire le correctif cumulatif dans `Interface/AddOns`. Pour une première installation, extraire d’abord [le ZIP de base alpha.2](https://github.com/Toracles/Curator-OctoWoW/releases/tag/v0.2.0-alpha.2). Le ZIP de la galerie installe le dossier séparé `CuratorOctoGalerie` au même emplacement.

Les tests automatisés Lua 5.0 vérifient notamment les deux confirmations, le crédit unique sur un personnage niveau 37, les tarifs de base et la sélection des textures française et anglaise.
