## Bouton de test dans la page des boosters

- **Tester** lance l’animation du booster affiché, même lorsque le stock est vide.
- L’aperçu ne dépense aucun booster et ne rapporte ni cartes ni XP. Le bouton de retour rouvre la page des boosters.

Les tests simulés sous Lua 5.0 couvrent le clic, le retournement des huit cartes et le retour vers la page, avec un stock vide ou positif. Le rendu en jeu reste à vérifier.

Installer [le ZIP de base alpha.2](https://github.com/Toracles/Curator-OctoWoW/releases/tag/v0.2.0-alpha.2), puis appliquer ce correctif cumulatif dans `Interface/AddOns`. Si Curator est déjà installé depuis le ZIP de base, appliquer directement ce correctif et taper `/reload`.
