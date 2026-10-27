# Rituel, app iOS native (SwiftUI)

Tu vas construire **Rituel**, une app iOS native de suivi d'habitudes, douce et bienveillante, pensée pour installer une routine et baisser l'anxiété. Une version web existe déjà et sert de référence fonctionnelle et visuelle : `reference/rituel.html` (ouvre-la et lis-la en entier avant de commencer). Les assets du logo sont dans `reference/logo/`.

Travaille par étapes (voir « Plan de travail » en bas). À la fin de chaque étape : compile, lance les tests, puis fais-moi un court résumé avant de passer à la suite.

---

## 1. Contraintes techniques

- **Swift 6, SwiftUI, iOS 17 minimum**, iPhone en priorité (iPad compatible sans travail spécifique).
- **SwiftData** pour le stockage, avec **synchronisation iCloud (CloudKit)**. Le modèle doit rester compatible CloudKit : toutes les propriétés optionnelles ou avec valeur par défaut, pas de contrainte `unique`, relations optionnelles.
- **App Group** partagé entre l'app et le widget (`group.<bundle-id>.shared`) pour que le widget lise et écrive les mêmes données.
- **WidgetKit + App Intents** pour des widgets interactifs (iOS 17).
- **HealthKit** en lecture seule pour importer le sommeil (optionnel, activable dans les réglages).
- **UserNotifications** pour les rappels locaux.
- Aucune dépendance tierce. Pas de compte, pas de serveur, pas de tracking.
- Interface en **français** (String Catalog `Localizable.xcstrings`, prêt pour l'anglais plus tard).
- Architecture simple et lisible : modèles SwiftData, une couche `HabitEngine` pure (calculs de périodes, statuts, récap) entièrement testée, et des vues SwiftUI.
- Mets le bundle id, le Team ID et le nom de l'App Group dans un seul fichier de config (`Config.xcconfig`) pour que je les remplace facilement.

Si le projet Xcode n'existe pas encore, génère-le avec **XcodeGen** (`project.yml`) pour qu'il soit reproductible : cibles `Rituel` (app), `RituelWidgets` (extension widget), `RituelTests` (tests unitaires).

---

## 2. Modèle de données

### Habit
| Champ | Type | Détail |
|---|---|---|
| id | UUID | |
| name | String | max 40 caractères |
| kind | enum `limit` / `goal` | limite = « pas plus de », objectif = « au moins » |
| target | Double | quantité visée |
| period | enum `day` / `week` / `month` | |
| colorKey | String | clé de la palette (section 5) |
| measure | enum `count` / `amount` | des fois (je coche) ou une quantité |
| unit | String? | pour `amount` : `h`, `ml`, `min`, `km`, `pas`, ou libre |
| entryMode | enum `set` / `add` | `set` = valeur du jour (sommeil), `add` = j'additionne (eau) |
| presets | [Double] | choix rapides, 8 maximum |
| sortIndex | Int | ordre d'affichage |
| reminder | heure optionnelle | rappel quotidien |
| createdAt | Date | |

### Entry
Une entrée par habitude et par jour : `habitID`, `day` (date normalisée à minuit, fuseau local), `value` (Double). Valeur 0 = on supprime l'entrée.

### Habitudes par défaut au premier lancement
| Nom | Type | Cible | Période | Couleur | Mesure |
|---|---|---|---|---|---|
| Sommeil | objectif | 8 | jour | lilas | quantité, `h`, `set`, presets 6 / 6.5 / 7 / 7.5 / 8 / 9 |
| Eau | objectif | 2000 | jour | ciel | quantité, `ml`, `add`, presets 250 / 500 / 1000 |
| Café froid | limite | 1 | jour | bleu | fois |
| Croissant | limite | 1 | semaine | mandarine | fois |
| Sport | objectif | 3 | semaine | menthe | fois |
| Fast-food | limite | 1 | mois | violet | fois |

---

## 3. Règles métier (HabitEngine, à tester unitairement)

- **La semaine commence le lundi.** Le mois est le mois civil.
- `count(habit, période)` = somme des valeurs des entrées dans la période qui contient le jour sélectionné.

### Statut d'une carte (c = total de la période, t = cible)
- Limite : `c < t` → « Encore X possible » (vert) ; `c == t` → « Limite atteinte » (ambre) ; `c > t` → « Dépassé de X » (corail). Si `t == 0` et `c == 0` : « Rien noté, bravo ».
- Objectif : `c >= t` → « Objectif atteint » ou « Objectif dépassé, +X » (vert) ; sinon « Encore X » (neutre).

### Saisie
- `count` : un tap sur le bouton rond = +1 pour le jour sélectionné ; un bouton « − » apparaît si le jour a au moins 1.
- `amount` + `set` : rangée de boutons presets. Un tap fixe la valeur du jour, retaper la même valeur l'efface. Le dernier preset s'affiche avec un « + » (ex. « 9h+ »). Un bouton × efface le jour.
- `amount` + `add` : boutons « +250 », « +500 », « +1L ». Un bouton ↺ remet le jour à zéro.
- On peut noter pour n'importe quel jour passé de la semaine affichée (pas dans le futur).
- Retour haptique léger à chaque saisie.

### Formatage des quantités
- `h` : 7.5 → « 7h30 », 8 → « 8h ».
- `ml` : ≥ 1000 → « 1,5L » ; en version courte (petites cases), < 1000 → « 750 » sans unité.
- `min` en version courte : ≥ 60 → « 1h15 ».
- Décimales avec une virgule (format français).

### Récap hebdomadaire (pour une semaine lundi → dimanche, jusqu'à aujourd'hui si en cours)
Pour chaque habitude, un état `tenu` / `en cours` / `à travailler`, un score entre 0 et 1, une valeur affichée et une phrase :
- **Période jour** : on évalue chaque jour écoulé. Pour un objectif, aujourd'hui n'est compté que s'il est déjà atteint. Tenu si aucun jour raté. Score = jours OK / jours évalués. Valeur « 5/6 jours ». Phrase « Respecté chaque jour. », « Dépassé 2 jours sur 6. », « Manqué 1 jour sur 6. ». Pour les quantités, ajoute « Moyenne 7h15 par jour. ».
- **Période semaine** : limite tenue si `c <= t` (score `t/c` sinon) ; objectif tenu si `c >= t`, « en cours » si la semaine n'est pas finie, sinon à travailler (score `c/t`).
- **Période mois** : on regarde le mois jusqu'à la fin de la semaine évaluée. Limite tenue si `c <= t`. Objectif : tenu si atteint, « en bonne voie » (en cours) si `c >= t × jours écoulés / jours du mois`, sinon à travailler.
- **Score d'équilibre** = moyenne des scores × 100, arrondi.
- Titre selon le score : ≥ 85 « Une semaine douce et tenue », ≥ 60 « Une belle semaine, avec de la marge », ≥ 35 « Une semaine en demi-teinte », sinon « On repart en douceur ».
- Chaque habitude à travailler reçoit un conseil, choisi de façon stable (hash de l'id + semaine) dans ces listes :
  - Limite dépassée : « Repère le moment où l'envie arrive et prépare une alternative à portée de main. » / « Décide à l'avance du jour où tu te l'accordes, ça le rend plus savoureux. » / « Note ce que tu ressens juste avant. Souvent c'est de la fatigue, pas de la faim. » / « Rends-le un peu moins accessible : un détour, un autre trajet, un autre café. »
  - Objectif manqué : « Bloque des créneaux précis dans ton agenda dès lundi, comme un rendez-vous. » / « Commence plus petit : dix minutes comptent, l'important c'est de cocher. » / « Associe-le à une habitude que tu as déjà, juste après le café du matin par exemple. » / « Prépare tout la veille pour qu'il n'y ait plus qu'à y aller. »

### Ton des messages
Toujours bienveillant, jamais culpabilisant, tutoiement. Phrase d'accueil sous « Bonjour Léa » / « Bonsoir Léa » (après 18h) :
- aucune limite dépassée : « Tout est en équilibre. Continue à ton rythme. »
- une limite dépassée : « Une limite a été dépassée. Ce n'est qu'un moment, la suite reste à écrire. »
- plusieurs : « N limites ont été dépassées. Respire, on regarde ça calmement dans le récap. »
Le prénom est réglable dans les réglages (vide = « Bonjour » seul).

---

## 4. Écrans

Barre d'onglets flottante en forme de pilule, 3 onglets : **Aujourd'hui**, **Récap**, **Habitudes**.

**En-tête commun** : marque (carré pervenche arrondi avec la marguerite blanche et le cœur soleil, puis « Rituel » en Fraunces) à gauche, pastille « Semaine 44 » (numéro ISO) à droite. Une forme organique floue jaune soleil et lilas « respire » doucement derrière le titre (animation lente de 9 s, désactivée si Réduire les animations est activé).

**Aujourd'hui**
- Surtitre avec la date longue (« lundi 26 octobre »), grand titre de salutation, phrase d'accueil.
- Frise de la semaine collante en haut : 7 jours (L M M J V S D + numéro), jour sélectionné en pastille pervenche, point sous les jours qui ont des saisies, jours futurs grisés. Flèches pour changer de semaine.
- Cartes groupées par période, avec titres « Par jour » / « Par semaine » / « Par mois » et sous-titre (« aujourd'hui », « semaine du 26 oct. », « octobre »).
- Carte : nom + point de couleur, règle (« Pas plus de 1 par semaine », « Au moins 8h par jour »), pastille de statut, bouton rond à droite avec « total / cible ». Léger halo de la couleur de l'habitude en haut à droite de la carte.
- Sous la carte : pour la période jour, une mini-frise des 7 jours (case verte si OK, corail si raté, pointillés pour le futur, valeur dedans) ; pour semaine et mois, des petites pilules (une par unité de la cible, remplies quand c'est utilisé, corail au-delà d'une limite, petites vertes en bonus au-delà d'un objectif) ou une barre de progression si la cible dépasse 12 ou pour les quantités.

**Récap**
- Navigation semaine par semaine.
- Carte score : grand chiffre en Fraunces pervenche (« 72 % »), « 2 sur 6 habitudes tenues », pastilles « 2 tenues / 3 en cours / 1 à travailler », puis une rangée de 20 petits points (pervenche, les derniers en jaune soleil).
- Sections « Ce que tu as tenu », « En cours », « Où progresser » (avec le conseil dans une bulle).
- Grille « Jour par jour » : habitudes en lignes, L→D en colonnes, cases colorées selon le statut.
- Bloc « Un mot pour ta semaine » : si le framework **Foundation Models** (modèle Apple sur l'appareil, iOS 26+) est disponible, génère 3 à 4 phrases douces à partir du récap (salue une réussite précise, propose une seule petite action, tutoiement, pas d'emoji). Sinon, masque ce bloc. Utilise `#available` et un repli propre.

**Habitudes**
- Liste réordonnable par glisser, bouton « Nouvelle habitude ».
- Feuille de création/édition (sheet avec grabber) : Nom ; Type (segmenté Limite « pas plus de » / Objectif « au moins ») ; Je suis (Des fois « je coche » / Une quantité « heures, ml, min… ») ; si quantité : Unité, Comment je note (Valeur du jour « ex. sommeil » / J'additionne « ex. eau »), Combien (champ décimal), Choix rapides (champ texte séparé par des espaces, presets par défaut selon l'unité : h → 6 6.5 7 7.5 8 9, ml → 250 500 1000, min → 10 20 30 45 60, km → 2 5 8 10, pas → 2000 5000 8000 10000) ; sinon Combien (stepper). Période (Jour / Semaine / Mois). Couleur (grille de 16 pastilles rondes). Rappel optionnel (heure). Aperçu en phrase (« Sommeil : au moins 8h par jour. »). Suppression avec confirmation intégrée.
- Section Réglages : prénom, synchro iCloud (état affiché), import du sommeil depuis Santé (interrupteur), rappels.

---

## 5. Design system

Style **doux, arrondi, lumineux et apaisant**, ni masculin ni rose. Référence exacte : `reference/rituel.html`.

### Couleurs (mode clair / mode sombre)
| Token | Clair | Sombre |
|---|---|---|
| bg | #F6F5FB | #14132A |
| surface | #FFFFFF | #1D1B38 |
| surface2 | #ECEBF8 | #292749 |
| line | #E0DEF1 | #33305A |
| ink | #25223E | #EEEDFA |
| ink2 | #5E5A7C | #B4B1D3 |
| ink3 | #928EAF | #7D7AA0 |
| accent (pervenche) | #5B5BD6 | #A4A6FF |
| accentSoft | #E7E6FC | #2D2B5C |
| sun | #F5B53F | #FFC95C |
| ok / okSoft | #2F9E78 / #DCF2E8 | #6FD3AC / #1D3A33 |
| edge / edgeSoft | #D48A1E / #FCEBCB | #F2BA5C / #3E3220 |
| over / overSoft | #D8604F / #FBE0DA | #F2917F / #432A2B |

Mets ces couleurs dans l'Asset Catalog avec variantes clair/sombre.

### Palette des habitudes (16)
Citron #F7DC4A, Soleil #FFB627, Mandarine #FF8A3D, Tomate #F2553D, Pivoine #FF7AB6, Lilas #B9A2FF, Violet #7B61FF, Pervenche #7C93FF, Bleu #2F6BFF, Ciel #6CC8FF, Lagon #19B8B0, Menthe #3DD598, Pomme #A3DB4D, Sable #D8C29C, Ardoise #7A8296, Encre #2A2A2E.

### Typo
- Titres : **Fraunces** (axe SOFT à 100, graisse 400 ; 300 pour le grand chiffre du score). Grand titre 34 pt, titres de section 22 pt.
- Texte : **Figtree** 400 / 600 / 700, 15 pt de base.
- Chiffres en chiffres tabulaires.
- Les deux polices sont sous licence OFL : télécharge-les depuis Google Fonts, embarque-les dans l'app et déclare-les dans `Info.plist`. Respecte le Dynamic Type (`relativeTo:`).

### Formes
Rayon des cartes 20 pt, des champs 14 pt, boutons en pilule, ombre très légère teintée pervenche (`0 10 26 -12` à 18 %). Bouton rond de saisie 62 pt, 68 pt pour les quantités.

### Icône et logo
- Icône d'app : `reference/logo/png/rituel-icone-app-1024.png` (marguerite blanche, cœur soleil, fond pervenche #4B4BF0). Génère l'AppIcon (clair, sombre et teinté iOS 18 si possible, avec des variantes de la marguerite).
- Symbole vectoriel : `reference/logo/rituel-symbole.svg` et variantes, à mettre en asset vectoriel pour l'en-tête et le widget.

---

## 6. Widgets (le plus important pour moi)

Utilise le même design system. Les widgets lisent les données dans l'App Group et écrivent via des **App Intents** (`Button(intent:)`) puis rechargent leurs timelines. L'app doit aussi recharger les widgets à chaque saisie (`WidgetCenter.shared.reloadAllTimelines()`).

1. **Petit** : une habitude au choix (widget configurable via `AppIntentConfiguration`) : nom, total / cible, statut en pastille, et un gros bouton +1 (ou le preset le plus courant pour une quantité).
2. **Moyen** : 3 ou 4 habitudes du jour avec leur bouton de saisie rapide.
3. **Grand** : toutes les habitudes du jour + mini-score d'équilibre de la semaine.
4. **Écran verrouillé** (`accessoryCircular` / `accessoryRectangular`) : progression d'une habitude au choix (ex. eau 1,2L / 2L).

Mise à jour de la timeline à minuit pour changer de jour. Les données doivent rester justes même si l'app n'a pas été ouverte.

---

## 7. Fonctions natives

- **Rappels** : notifications locales par habitude (ex. « As-tu bu ton eau ? » à 15h), avec action rapide « +250 ml » ou « Fait » directement depuis la notification (catégories de notification + App Intent). Demande la permission seulement quand on active un premier rappel.
- **Santé** : si l'import est activé, lis `HKCategoryTypeIdentifier.sleepAnalysis` (phases de sommeil réel, pas le temps au lit) et remplis l'habitude Sommeil pour la nuit qui se termine ce matin, en heures arrondies au quart d'heure. Une saisie manuelle garde toujours la priorité.
- **Raccourcis / Siri** : expose les App Intents « Noter une habitude » et « Ajouter de l'eau » via `AppShortcutsProvider`.

---

## 8. App Store

- Ajoute un `PrivacyInfo.xcprivacy` correct (API UserDefaults, aucune donnée collectée).
- Textes d'usage en français : `NSHealthShareUsageDescription` (« Rituel lit ton temps de sommeil pour remplir ton habitude Sommeil automatiquement. ») et la description pour les notifications.
- Capabilities : iCloud (CloudKit), App Groups, HealthKit, Push (pour la synchro CloudKit en arrière-plan), Background Modes (remote notifications).
- Prépare un dossier `AppStore/` avec : description courte et longue en français, mots-clés, texte « Nouveautés », URL de politique de confidentialité à remplir (et une page `privacy.md` simple : aucune donnée ne quitte l'appareil hors iCloud de l'utilisatrice), et la liste des captures d'écran à faire (6,9" et 6,5").
- L'app doit être utile et native (widgets, rappels, Santé, Siri) pour passer la règle 4.2 d'Apple sur la fonctionnalité minimale.

---

## 9. Qualité

- Tests unitaires du `HabitEngine` : périodes (lundi, changement de mois, passage à l'heure d'hiver), statuts limite/objectif, formatage (7.5 h → 7h30, 1500 ml → 1,5L), récap (cas de la semaine en cours, objectif du jour non atteint aujourd'hui, mois en bonne voie).
- Accessibilité : VoiceOver sur toutes les cartes (« Café froid, 2 sur 1, dépassé de 1, bouton noter »), contrastes AA, Dynamic Type jusqu'à XXL sans texte coupé.
- Mode sombre complet, Réduire les animations respecté.
- Previews SwiftUI pour chaque écran et chaque taille de widget, avec des données d'exemple.

---

## 10. Plan de travail (une étape à la fois, arrête-toi après chacune)

1. **Projet** : `project.yml` XcodeGen, cibles, App Group, config, polices, couleurs, icône. Ça compile et ça affiche un écran vide aux bonnes couleurs.
2. **Modèle + HabitEngine + tests** : SwiftData, habitudes par défaut, toute la logique de la section 3, tests verts.
3. **Écran Aujourd'hui** complet, avec saisie (fois, set, add).
4. **Écran Habitudes** et feuille d'édition.
5. **Écran Récap**.
6. **Widgets** interactifs + écran verrouillé.
7. **Rappels**, **Santé**, **Raccourcis**.
8. **Synchro iCloud**, accessibilité, polish, dossier `AppStore/`.

Pour chaque étape, si un choix n'est pas couvert ici, prends l'option la plus simple et cohérente avec `reference/rituel.html`, et note-la dans `DECISIONS.md`.
