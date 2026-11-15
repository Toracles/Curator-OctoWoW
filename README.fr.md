# Curator OctoWoW

[English](README.md) · **Français**

Portage de Curator 1.14.3 adapté par CloudNine_Ex à **OctoWoW 1.18.1 sur le client WoW 1.12.1**. Collectionne les cartes de créatures, complète les albums par zone et ouvre des boosters avec les animations originales de Curator. Cette préversion fonctionne entièrement dans le jeu et utilise des sauvegardes locales.

## Prérequis

- **Installation de base.** Utilise le client OctoWoW 1.12.1 et installe le ZIP de base avant le correctif cumulatif. Le fichier TOC de Curator ne déclare aucun autre addon obligatoire.
- **Modèles 3D et rattrapage de l’exploration.** Active `ClassicAPI.dll` pour disposer des API de modèles de créatures et d’exploration. Démarre OctoWoW avec le launcher configuré pour charger ClassicAPI. En installation manuelle, place la DLL à côté de `WoW.exe`, ajoute-la dans `dlls.txt`, puis lance le jeu avec `VanillaFixes.exe`. [Installation de ClassicAPI](https://github.com/brues-code/ClassicAPI#installation) · [Modernization Tool d’OctoWoW](https://octowow.st/git/Dusk/Modernization-Tool/src/branch/main/README.md)
- **Rattrapage des quêtes.** Il utilise l’historique des quêtes rendues du client ou celui de Questie-Octo. Questie-Octo est facultatif si le client fournit déjà cet historique. [Questie-Octo](https://github.com/SandreaSub/Questie-Octo)
- **Échanges en direct.** Les deux joueurs doivent utiliser Curator OctoWoW alpha.23 ou une version ultérieure.

Hoard est facultatif et sert uniquement à importer une ancienne sauvegarde. DXVK, les packs HD, SuperWoW et Nampower sont des options distinctes du client. L’installation par ZIP se suffit à elle-même pour les fichiers de Curator, sans application Windows compagnon ni outils de développement.

## Installer ou mettre à jour

1. Pour une première installation, quitte OctoWoW et extrais le [ZIP de base](https://github.com/Toracles/Curator-OctoWoW/releases/download/v0.2.0-alpha.2/Curator-OctoWoW-test-1.12.1.zip) dans `Interface/AddOns`. Il contient l’addon complet, les illustrations et les sons.
2. Quitte OctoWoW avant d’appliquer le [correctif cumulatif alpha.33](https://github.com/Toracles/Curator-OctoWoW/releases/download/v0.2.0-alpha.33/Curator-OctoWoW-correctif-alpha.33.zip). Extrais-le au même endroit et fusionne les dossiers `Curator`. Si Curator est déjà installé depuis le ZIP de base, le correctif suffit. Garde tes sauvegardes de compte et de personnage dans `WTF`.
3. Lance OctoWoW, active **Curator** à la sélection des personnages et tape `/curator`. Choisis le français ou l’anglais dans `/curator options`.

Pour installer la galerie bilingue facultative, extrais le [ZIP de la galerie](https://github.com/Toracles/Curator-OctoWoW/releases/download/v0.2.0-alpha.17/Curator-OctoWoW-Galerie-FR-EN.zip) dans `Interface/AddOns` et relance le jeu. Ouvre-la avec `/curatorgalerie` ou `/curatorgallery`, puis utilise **English / Français**. La galerie contient 259 cartes illustrées dans chaque langue.

## Ce que contient le portage

- **Catalogue et collection.** Les albums Vanilla et 20 albums OctoWoW regroupant 1 269 cartes de zones, donjons et raids. Le portage remplace l’ancien catalogue propre au serveur d’origine et retire les interfaces et hauts faits de bêta. Les modèles de créatures ont été associés aux identifiants disponibles dans le client OctoWoW.
- **Boosters et caisses.** Des ouvertures animées, une barre ajustable et un bouton **Tester** gratuit qui retourne automatiquement les cartes. Les modèles 3D disponibles suivent les cartes pendant leurs déplacements et retournements. Les aperçus de caisses affichent les modèles de PNJ disponibles sans survol. La collection comprend aussi les finitions, l’expertise, les boîtiers de protection et la restauration.
- **Progression et économie.** Niveaux de collectionneur, quêtes, hauts faits, talents, contrats de doublons, fidélité à l’auberge, visas et paris. Les prix locaux en rubis sont divisés par deux et le prix de base d’une clé de caisse est de 250 rubis.
- **Échanges entre joueurs.** Le bouton bleu **Échange (Curator)** du menu de portrait envoie une invitation. Une fois celle-ci acceptée, chacun voit les cartes et les boosters proposés par l’autre. La personne qui invite envoie l’offre finale, puis le destinataire en vérifie le contenu avant de l’accepter. L’aperçu en direct demande alpha.23 ou une version ultérieure des deux côtés. Les offres classiques restent accessibles avec `/curator trade`.
- **Correctifs d’interface Vanilla.** Compatibilité au démarrage et pour les modèles, en-tête des albums réorganisé avec bouton Guide et ordre d’affichage des illustrations de caisse corrigé. Les notifications, les panneaux de banque et le registre des rubis ont un fond opaque. Les actions Curator sont intégrées au dialogue natif de l’aubergiste, avec des correctifs pour l’animation des tampons, les dates et le chevauchement du panneau de pari. Les infobulles de joueurs reprennent le format du jeu.

## Rattraper la progression d’un personnage

Tape `/curator rattrapage` pour voir les niveaux, découvertes et quêtes du jeu rendues qui restent à créditer. Récupérer ou refuser demande une confirmation. Fermer le panneau reporte le choix. Curator conserve deux copies du registre, dans la sauvegarde du compte et celle du personnage, pour éviter les doubles crédits après une mise à jour.

Chaque quête rendue confirmée par le client ou Questie-Octo rapporte **20 points de booster** et peut avancer les objectifs Curator actifs qui demandent de rendre des quêtes. Les objectifs terminés comptent pour les hauts faits associés. Les anciennes périodes de quêtes, les rubis de rendu d’origine et les anciens combats d’élite restent hors de l’import. Si une ancienne version a déjà récompensé des niveaux sans les enregistrer, tape `/curator rattrapage 30` en remplaçant `30` par le dernier niveau crédité.

## Commandes utiles

| Action | Commande ou raccourci |
| --- | --- |
| Ouvrir la collection | `/curator` |
| Sauvegarder la collection | Clique sur le parchemin dans l’en-tête ou tape `/curator save`. Confirme le retour à la sélection des personnages pour sauvegarder. Curator confirme la sauvegarde si tu te reconnectes peu après. |
| Essayer une ouverture de booster | `/curator boosters` → **Tester**. L’aperçu est gratuit et ne donne aucune récompense. |
| Ouvrir des caisses de collection | Ouvre une caisse à vitesse normale ou choisis **5×**, **10×** ou **20×** pour enchaîner les révélations en accéléré. Fermer la fenêtre arrête les ouvertures restantes. |
| Redimensionner ou déplacer la barre de boosters | Molette sur la barre pour la largeur, Ctrl + molette pour l’échelle, Maj + glisser pour la déplacer. Utilise `/curator bar width 240` pour une largeur précise ou `/curator bar reset` pour réinitialiser. |
| Échanger des doublons contre une carte plus rare | **Contrats** ou `/curator contrat`. Le parchemin finit de brûler avant l’arrivée de la récompense. Pour les contrats de caisses, les détails s’affichent lorsque tu retournes la carte. |
| Ouvrir l’interface des échanges entre joueurs | Cible un joueur et tape `/curator trade`, ou utilise `/curator trade Nom`. Sans cible, la commande ouvre la liste des échanges. |
| Choisir la langue et régler l’interface | `/curator options` |
| Utiliser un code cadeau | `/curator gift` ou **Boosters → Code cadeau**. Colle le code, vérifie les récompenses, puis valide. |

## Émettre des codes cadeaux

Le mainteneur peut créer un cadeau OctoWoW pour un personnage et son royaume ou pour un identifiant de collection de 16 caractères hexadécimaux. L’émission requiert Node.js et la clé privée correspondant à la clé publique de l’addon. Sous Windows, son emplacement par défaut est `%LOCALAPPDATA%\Curator-OctoWoW\gift-signing.pem`. Garde la clé privée hors du dépôt. Les codes expirent au bout de 30 jours par défaut.

```powershell
node tools/gift-code.cjs issue --to "Personnage-Royaume" --zone 1 --rubies 100 --days 30
```

Les autres options de récompense sont `--dungeon`, `--raid`, `--xp` et `--display ALBUM:NOMBRE` pour une clé d’album éligible. L’option `--note` ajoute un message.

## État de la préversion et sources

Les tests automatisés Lua 5.0 couvrent le chargement, les écrans de collection, le retournement des cartes, le rattrapage et les invitations et aperçus d’échange simulés. Le rendu et un échange complet entre deux joueurs restent à vérifier en jeu. Le portage utilise des sauvegardes locales. L’application Windows d’origine, la synchronisation et la restauration en ligne, ainsi que la Bourse officielle restent hors périmètre.

- [Notes de version et téléchargements](https://github.com/Toracles/Curator-OctoWoW/releases)
- [Scripts et licences de l’addon](curator-test) · [Sources du portage](full-port) · [Outils de construction et de test](tools) · [Notes techniques](docs/PORTAGE-COMPLET.md)
- [Données du catalogue Questie-Octo et notices](data) · [Correspondances entre créatures et modèles](data/OctoDisplayIDs.tsv)

Le code, les illustrations et les données d’origine conservent les droits indiqués dans la [licence de l’addon](curator-test/LICENSE.txt) et la [notice des données](curator-test/Data/NOTICE.txt).

![Aperçu de la galerie OctoWoW initiale](docs/Apercu.png)
