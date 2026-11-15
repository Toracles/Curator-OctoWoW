
# Portage complet de Curator 1.14.3

Suivi de la préversion alpha.33 pour OctoWoW sur le client 1.12.1. L’installation associe le ZIP de base au correctif cumulatif. La galerie bilingue s’installe séparément.

| Fonction | État |
| --- | --- |
| Chargement et connexion | 221 fichiers Lua compilés avec Lua 5.0. Le chargement et les événements `ADDON_LOADED` et `PLAYER_LOGIN` sont simulés. |
| Albums, inventaire et sauvegarde | Moteur original et sauvegardes locales. Le bouton de sauvegarde demande de confirmer le retour à la sélection des personnages. 20 albums OctoWoW et 1 269 cartes en plus des albums Vanilla. Le catalogue propre au serveur d’origine et les éléments de bêta ont été retirés. |
| Boosters et ouverture | Distribution, retournement automatique en mode test et ancrage des modèles à la fenêtre des cartes vérifiés avec les API simulées. Aperçu d’ouverture gratuit et barre ajustable. Le rendu reste à vérifier en jeu. |
| Progression et économie | Contrats, talents, hauts faits, quêtes, finitions, expertise et restauration adaptés. Tarifs locaux en rubis divisés par deux et clés de caisse par quatre. |
| Rattrapage | Niveaux, découvertes et quêtes rendues confirmés. Le registre du compte et celui du personnage préviennent les doubles crédits. Les objectifs Curator actifs de rendu de quêtes progressent après confirmation. |
| Interface | Correctifs de modèles, de fonds et de superpositions. Guide dans l’en-tête, actions Curator intégrées au dialogue Vanilla des aubergistes et infobulles de joueurs au format du jeu. |
| Échanges entre joueurs | Canal Vanilla, invitation depuis le portrait et aperçu partagé testés en simulation. La validation complète à deux joueurs reste à faire sur OctoWoW. |
| Langues et galerie | Anglais et français dans l’addon principal. La galerie propose 259 cartes illustrées dans chaque langue. |
| Application Windows et services associés | Hors périmètre. La synchronisation et la restauration en ligne ainsi que la Bourse officielle reposent sur ce service. |

Depuis le dépôt, préparer le chantier avec `tools/stage_full_port.py`, `tools/convert_full_port.cjs` puis `tools/generate_full_catalogue.py`. Exécuter `tools/verify_full_port.py` pour les tests simulés et `tools/check_lua50.py` puis `tools/run_lua50_smoke.py` avec Lua 5.0. Le convertisseur utilise luaparse 0.3.1 dans `.port-runtime/package`. Le banc de test utilise Lupa avec Lua 5.1 dans `.test-runtime`. L’archive d’origine reste à la racine de l’espace de travail. Les sources converties et le relevé des médias et API sont générés dans `full-port-work`.

Pour reproduire le parcours en jeu, ouvrir l’inventaire et plusieurs albums, utiliser l’aperçu de booster, tester le rattrapage, puis vérifier la sauvegarde après une reconnexion. Tester l’invitation, l’aperçu et la confirmation d’un échange avec deux clients.
