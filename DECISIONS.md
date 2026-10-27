# Décisions

Choix faits là où le brief ne tranchait pas. Classés par étape.

## Étape 1 — Projet

- **Structure** : `Rituel/` (app), `RituelWidgets/` (extension), `RituelTests/`, et `Shared/` compilé dans l'app **et** le widget (design system, polices, config). Le `HabitEngine` et les modèles iront aussi dans `Shared/` à l'étape 2.
- **Config** : tout est dans `Config.xcconfig` (`APP_BUNDLE_ID`, `DEVELOPMENT_TEAM`, `APP_GROUP`, `ICLOUD_CONTAINER`, versions). Le widget est `$(APP_BUNDLE_ID).widgets`, les tests `$(APP_BUNDLE_ID).tests`. L'App Group et le conteneur iCloud sont recopiés dans les Info.plist (`RituelAppGroup`, `RituelCloudKitContainer`) et lus par `AppConfig`, pour qu'aucun identifiant ne soit écrit en dur dans le code.
- **Bundle id provisoire** : `com.leamedrano.rituel`, à remplacer.
- **Polices** : Google Fonts ne distribue Fraunces et Figtree qu'en polices variables. Plutôt que de piloter les axes à l'exécution (ce qui casse `Font.custom(_:size:relativeTo:)` et donc le Dynamic Type), j'ai généré des **instances statiques** avec fontTools :
  - `FrauncesSoft-Display` : graisse 400, SOFT 100, opsz 72 (titres 22 et 34 pt) ;
  - `FrauncesSoft-Text` : graisse 400, SOFT 100, opsz 24 (marque 19 pt, « Un mot pour ta semaine » 17 pt) ;
  - `FrauncesSoft-Light` : graisse 300, SOFT 100, opsz 144 (grand chiffre du score) ;
  - `Figtree-Regular` / `-SemiBold` / `-Bold` (400 / 600 / 700).
  WONK reste à sa valeur par défaut, comme sur le web. La licence OFL ne réserve aucun nom pour ces deux polices, on peut donc renommer les instances. Les fichiers OFL sont embarqués. Les polices variables d'origine sont dans `reference/fonts-variables/`.
- **Couleurs** : les 17 tokens sont dans `Shared/DesignSystem/DesignSystem.xcassets` avec leurs variantes clair et sombre. J'ai ajouté `AccentInk` (texte sur fond pervenche : #FFFFFF / #17163A), repris de la version web. Le token `bg` s'appelle `Canvas` / `.canvas`, parce que SwiftUI a déjà un `.background`. La génération automatique des symboles d'assets est désactivée et les tokens sont exposés à la main dans `Theme.swift` (`.foregroundStyle(.ink2)`).
- **Palette des habitudes** : elle est en code (`HabitColor`) et non dans l'Asset Catalog, parce que les 16 teintes sont les mêmes en clair et en sombre (comme sur le web). Les anciennes clés du web (`sauge`, `lavande`…) sont converties, et une clé inconnue retombe sur menthe.
- **Ombre** : l'ombre CSS `0 10 26 -12` n'a pas d'équivalent pour le `spread` négatif. Je l'approche par deux `shadow` (rayon 1 et 13, décalage vertical 1 et 10), en noir en mode sombre comme sur le web.
- **Icône** : l'icône claire est le PNG fourni. Les variantes sombre et teintée (iOS 18) sont générées à partir de la même géométrie, sur fond transparent : marguerite pervenche #8C8CFF avec le cœur soleil pour le sombre, marguerite blanche avec le cœur gris pour le teinté.
- **Logo vectoriel** : `Symbol` (marguerite seule, variante sombre en #8C8CFF) et `BrandMark` (carré pervenche) sont des SVG avec « Preserve Vector Data ».
- **Dates** : l'interface est en français, donc la locale de formatage est forcée à `fr_FR` (`Locale.rituel`), quelle que soit la langue de l'appareil.
- **Forme qui respire** : le `border-radius` asymétrique du web est reproduit par une `Shape`, avec un léger flou (6 pt) pour l'effet « flou » demandé. Cycle de 9 s (4,5 s aller, 4,5 s retour), coupé si Réduire les animations est activé.
- **Orientation** : portrait sur iPhone, toutes les orientations sur iPad.
- **Tests** : Swift Testing plutôt que XCTest.
- **`PrivacyInfo.xcprivacy`** : ajouté dès maintenant (UserDefaults pour l'app et l'App Group, aucune donnée collectée). Il sera vérifié à l'étape 8.
- **`Rituel.xcodeproj` versionné** : il est régénéré par `xcodegen generate`, mais on le garde dans le dépôt pour pouvoir ouvrir le projet directement après un clone. Après toute modification de `project.yml`, relancer `xcodegen generate`.
- **Sécurité / CVE** : aucune dépendance tierce (exigence du brief), donc aucune bibliothèque externe à surveiller. La surface se limite à Xcode et au SDK iOS, à garder à jour. `ENABLE_USER_SCRIPT_SANDBOXING` est activé, Swift 6 vérifie la concurrence de façon stricte, et le `.gitignore` exclut les builds, les certificats, les profils et les clés App Store Connect. Le Team ID et le bundle id ne sont pas des secrets.

## Étape 2 — Modèle et HabitEngine

- **Moteur pur** : `HabitEngine`, `RecapEngine`, `RituelCalendar`, `QuantityFormat` et `EntryLog` (dans `Shared/Engine/`) ne dépendent ni de SwiftData ni de SwiftUI. Ils travaillent sur `HabitSpec` (copie immuable d'une habitude) et `EntryRecord`, ce qui les rend testables avec un calendrier et un « aujourd'hui » fixés (tests sur Europe/Paris).
- **Modèle SwiftData** : énumérations stockées en texte (`kindRaw`, `periodRaw`…), rappel stocké en minutes depuis minuit (`reminderMinutes`). `Entry.habitID` est optionnel, comme CloudKit l'exige, et il n'y a pas de relation avec `Habit` : à la suppression d'une habitude, ses entrées seront effacées à la main (étape 4).
- **`Entry.updatedAt`** (ajouté) : sans contrainte `unique`, la synchro iCloud peut créer deux entrées pour le même jour. `EntryLog` garde alors la plus récente, et `EntryWriter` supprime les doublons à la prochaine saisie.
- **Habitudes par défaut** : identifiants fixes (`6A1C0000-…-00000000000N`), pour pouvoir repérer les doublons si deux appareils les créent avant la synchro (traité à l'étape 8). Elles ne sont créées qu'une fois (drapeau dans l'App Group).
- **Base** : `Rituel.store` dans l'App Group. CloudKit est désactivé (`cloudKitDatabase: .none`) jusqu'à l'étape 8.
- **« Rien noté, bravo »** (limite à 0, rien noté) : en vert plutôt qu'en ambre comme sur le web, parce que c'est une réussite.
- **Conseil stable** : somme des caractères de l'identifiant + numéro de semaine ISO. `hashValue` n'est pas utilisable : il change à chaque lancement.
- **Récap mensuel** : on suit la version web, c'est-à-dire le mois du dernier jour évalué (aujourd'hui si la semaine est en cours, sinon le dimanche).
- **Moyenne d'une quantité quotidienne** : divisée par tous les jours écoulés de la semaine, aujourd'hui compris (comme sur le web).
- **Grands nombres** : pas de séparateur de milliers (« 10000 pas »), comme sur le web.

## Étape 3 — Aujourd'hui

- **Données chargées** : seules les entrées de la semaine et du mois du jour sélectionné sont lues (`@Query` filtré).
- **Changement de jour** : si l'app reste ouverte après minuit, l'écran passe au nouveau jour (notification `NSCalendarDayChanged` et retour au premier plan).
- **Barre d'onglets** : pilule maison avec des symboles SF (`checkmark.circle`, `chart.bar`, `list.bullet`) proches des icônes du web. Les onglets Récap et Habitudes affichent un écran d'attente jusqu'aux étapes 4 et 5.
- **Prénom** : lu dans l'App Group (`firstName`), vide par défaut, donc « Bonjour » seul tant qu'il n'est pas réglé (étape 4).
- **Dynamic Type** : le rond de saisie grandit avec le texte, jusqu'à 1,35 fois sa taille.
- **Retour haptique** : `sensoryFeedback(.impact(weight: .light))` à chaque saisie, `.selection` en changeant de jour.

## Thème « soft clay » (demandé le 27 octobre 2026, remplace la section 5 du brief)

- **Pourquoi** : Léa a choisi une référence pastel en relief doux (claymorphism). Ses choix : les pastels de la référence plutôt que pervenche et soleil, et **le logo et l'icône gardés tels quels** (carré pervenche, marguerite).
- **Couleurs** : fond sable rosé #F4EEE9, surfaces crème #FFFBF7, accent pêche #E9A68C avec texte prune #4A2A22 par-dessus, terracotta #A8533B pour le texte accentué, bleu brumeux et rose poudré pour les formes. Il existe une variante sombre prune pour chaque couleur. Statuts : sauge, miel et brique, assez foncés pour passer le contraste AA sur leur fond doux. Toutes les paires texte/fond ont été vérifiées : 4,5:1 au moins, sauf `ink3` sur `surface2` (4,3:1, seulement dans les petites cases de la mini-frise).
- **Nouveaux tokens** : `SurfaceHigh` (haut des surfaces en relief), `AccentText`, `Mist`, `Blush`.
- **Palette des habitudes** : mêmes 16 clés et mêmes noms, en versions pastel pour s'accorder au thème. Les clés stockées ne changent pas, donc rien à migrer.
- **Relief** : les cartes et la barre d'onglets ont un dégradé vertical, un liseré lumineux en haut et une ombre chaude diffuse (`ClaySurface`). Les boutons sont des galets bombés avec un reflet en haut à gauche (`Pebble`).
- **Vagues** : rose poudré et bleu brumeux, fixes en haut de l'écran. La frise de la semaine ne prend un fond opaque qu'une fois collée en haut, pour ne pas couper les vagues au repos.
- **Forme qui respire** : pêche vers bleu brumeux, au lieu de soleil vers lilas.
- **Données d'exemple** : l'argument de lancement `-RituelSampleData` (debug seulement) ouvre l'app sur les données des previews, en mémoire. Utile pour les captures.

## Étape 4 — Habitudes et feuille d'édition

- **Logique du formulaire** dans `HabitDraft` (testé) : les mêmes réflexes que le web. Passer en quantité met « h » par défaut, et avec une petite cible en heures, propose un objectif de 8 h. Les choix rapides suivent l'unité tant qu'on ne les a pas modifiés. L'unité « ml » passe en « J'additionne ». Une cible en nombre de fois va de 1 (objectif) ou 0 (limite) à 99. Repasser une quantité en nombre de fois efface l'unité et les choix rapides.
- **Couleur d'une nouvelle habitude** : la première couleur de la palette pas encore utilisée (le web prenait toujours citron).
- **Unité** : 8 caractères au plus.
- **Liste** : une carte par habitude plutôt qu'une seule carte pour toute la liste. Le glisser-déposer de SwiftUI soulève une ligne à la fois, et une carte par ligne rend mieux. On réordonne d'un appui long. VoiceOver a les actions « Monter » et « Descendre ».
- **Suppression** : confirmation dans la feuille, comme sur le web. Les saisies de l'habitude sont effacées avec elle et l'ordre est resserré.
- **Rappel** : 20 h par défaut quand on l'active. La notification et la demande de permission arrivent à l'étape 7.
- **Réglages** : le prénom (40 caractères au plus) et les interrupteurs « Sommeil depuis Santé » et « Rappels » sont enregistrés dans l'App Group. Les deux interrupteurs n'ont pas encore d'effet : ils seront branchés à l'étape 7. L'état de synchro affiche « Enregistré sur cet appareil » jusqu'à l'étape 8.
- **Écran Aujourd'hui vide** : le bouton « Créer une habitude » ouvre l'onglet Habitudes avec la feuille déjà ouverte.
- **Options de lancement en debug** : `-RituelTab habits|recap` et `-RituelNewHabit YES`, pour les captures.

## Étape 5 — Récap

- **Données chargées** : du 1er du mois du lundi jusqu'au dimanche. Le mois évalué est celui du dernier jour de la semaine, qui peut commencer avant le lundi affiché.
- **Grille « Jour par jour »** (`RecapEngine.heatCell`, testé) : pour une habitude quotidienne, vert si le jour est tenu, corail s'il est raté. Pour un objectif quotidien pas encore atteint, la case prend la couleur de l'habitude, sans jugement. Pour les habitudes à la semaine ou au mois, la case prend la couleur de l'habitude dès qu'il y a une saisie. Comme sur le web.
- **Grand chiffre du score** : en terracotta `accentText` (le pêche n'est pas assez contrasté pour du texte). Les 20 points sont en pêche, et en soleil à partir du 15ᵉ.
- **« Un mot pour ta semaine »** : `WeeklyNoteWriter` utilise Foundation Models (`LanguageModelSession`) sous `#if canImport(FoundationModels)` et `if #available(iOS 26.0, *)`. Le bloc n'apparaît que si le modèle est disponible (Apple Intelligence activé) **et** qu'il gère le français. Sinon il est masqué, comme le demande le brief. Le mot n'est écrit que sur demande (bouton « Écrire mon mot »), jamais automatiquement : la génération prend quelques secondes. Le tiret cadratin est remplacé par une virgule, comme sur le web. La consigne est construite par `RecapEngine.notePrompt` (testé). Sans prénom réglé, elle parle d'« une personne ».
- **VoiceOver** : la carte score se lit d'un bloc. Chaque ligne de la grille se lit en une phrase (« Sommeil : lundi 7h30, mardi 8h »).
