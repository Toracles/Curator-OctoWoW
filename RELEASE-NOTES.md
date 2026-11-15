## Placement du comptoir de l’aubergiste

Le comptoir se place à droite du menu Curator lorsque celui-ci est visible. Le placement se met à jour lorsque le jeu rafraîchit le menu ou quand celui-ci revient après un pari.

Les tests Lua 5.0 vérifient le placement lorsque le dialogue du jeu et le menu Curator sont ouverts ensemble, puis après rafraîchissement du menu et fermeture du pari. Le rendu reste à vérifier en jeu.

Installer [le ZIP de base alpha.2](https://github.com/Toracles/Curator-OctoWoW/releases/tag/v0.2.0-alpha.2), puis appliquer ce correctif cumulatif dans `Interface/AddOns`. Si Curator est déjà installé depuis le ZIP de base, appliquer directement le correctif et taper `/reload`.
