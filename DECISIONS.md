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
