## Comptoir et pari de l’aubergiste

- Le calcul d’échelle des textures passe par leur cadre parent sur le client 1.12.1. Cela répare notamment l’animation qui envoie l’icône du plat du jour vers la barre de boosters.
- L’horloge locale prend le relais si l’horloge serveur renvoie une date invalide. Les anciens visas gardent leur état et affichent un tiret si leur date est inconnue. Un tampon enregistré avec une ancienne horloge invalide reste pris jusqu’au prochain reset.
- Le comptoir et le menu de dialogue Curator s’effacent pendant le pari. Ils se réaffichent à sa fermeture si le dialogue avec l’aubergiste est toujours ouvert.

Les 221 scripts compilent en Lua 5.0. Le dialogue avec Allison, le tampon et son animation, ainsi que l’ouverture et la fermeture du pari passent les tests simulés. Le rendu reste à vérifier en jeu.

Installer [le ZIP de base alpha.2](https://github.com/Toracles/Curator-OctoWoW/releases/tag/v0.2.0-alpha.2), puis appliquer ce correctif cumulatif dans `Interface/AddOns`. Si Curator est déjà installé depuis le ZIP de base, appliquer directement ce correctif et taper `/reload`.
