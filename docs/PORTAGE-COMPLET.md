
# Portage complet de Curator 1.14.3

La cible est Curator en jeu sur OctoWoW, avec une installation manuelle. La galerie et l'alpha simplifiée servent de prototypes. Le chantier principal convertit l'archive officielle dans l'ordre de son fichier TOC.

| Fonction | État |
| --- | --- |
| Chargement et connexion | 226 fichiers compilés par Lua 5.0.3. Chargement et événements ADDON_LOADED et PLAYER_LOGIN simulés en Lua 5.1. |
| Albums, inventaire et sauvegarde | Moteur original chargé. Six albums OctoWoW et 903 cartes ajoutés. Zephras retiré du TOC. Sauvegarde avec des variables propres au port. Les autres données Forever restent à comparer aux données OctoWoW. |
| Boosters et ouverture | Le moteur original atteint la fin de la distribution et du retournement des huit cartes avec Lua 5.0.3 et Lua 5.1, avec les API du jeu simulées. Les cartes, le rendu des effets et les cinématiques restent à valider sur le client 1.12.1. |
| Progression, contrats, talents, hauts faits, quêtes, finitions, restauration et autres vues de collection | Modules conservés. Les messages Vanilla de quête et de découverte créditent les points une fois dans les tests. Les autres événements et interfaces restent à tester en jeu. |
| Échanges entre joueurs, guilde, commerce et revente | Adaptateur du canal Vanilla ajouté. Un envoi a été simulé. Le protocole et les échanges complets restent à valider entre deux joueurs. |
| Application Windows et services associés | Hors périmètre. La synchronisation et la restauration en ligne ainsi que la Bourse officielle reposent sur ce service. |

Depuis le dépôt, préparer le chantier avec tools/stage_full_port.py, tools/convert_full_port.cjs puis tools/generate_full_catalogue.py. Exécuter tools/verify_full_port.py depuis le dossier du dépôt. Le convertisseur utilise luaparse 0.3.1 dans .port-runtime/package, le banc de test utilise Lupa avec Lua 5.1 dans .test-runtime. L'archive d'origine reste à la racine de l'espace de travail. Les sources converties et le relevé des médias et API sont générés dans full-port-work.

Le banc de test simule les appels d'interface et les événements. La suite consiste à valider les API et les fichiers médias sur le client 1.12.1, puis ouvrir les albums et jouer les séquences originales jusqu'à l'enregistrement de la collection. Vérifier ensuite les fonctions multijoueurs avec deux clients.





