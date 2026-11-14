## Curator OctoWoW 1.12.1

Première préversion de test fondée sur le code original de Curator 1.14.3.

- Six albums OctoWoW et 903 cartes issues de Questie-Octo. Zephras Isle a été retiré.
- Moteur d’origine pour les albums, les tirages de boosters et la sauvegarde locale. Les scripts originaux de la scène d’ouverture et des cinématiques sont inclus.
- Adaptations Lua 5.0 pour le chargement, les événements, les effets d’interface, les temporisations et les messages entre addons.
- Sources exactes du ZIP, outils de reconstruction, tests et suivi du portage dans le dépôt.

### Installation

Télécharger **Curator-OctoWoW-test-1.12.1.zip**, extraire le dossier Curator dans Interface/AddOns, redémarrer OctoWoW et taper `/curator`.

### Vérification

Les 226 scripts passent la compilation Lua 5.0.3. Un banc de test a vérifié les tirages et une ouverture complète avec les API du jeu simulées. Le rendu, les cinématiques, les événements de combat, la sauvegarde après reconnexion et les échanges en jeu restent à valider sur OctoWoW. La révision du reste du catalogue Forever se poursuit.

L’installation est manuelle, avec sauvegarde locale. La synchronisation en ligne et la Bourse officielle relèvent de l’application compagnon, hors périmètre.
