import Testing
import SwiftUI
@testable import Rituel

struct DesignSystemTests {
    @Test func paletteHasSixteenDistinctColors() {
        #expect(HabitColor.allCases.count == 16)
        #expect(Set(HabitColor.allCases.map(\.hex)).count == 16)
    }

    @Test func paletteKeysMatchTheWebVersion() {
        #expect(HabitColor(key: "lilas") == .lilas)
        #expect(HabitColor(key: "ciel").hex == 0x9CCBE6)
        #expect(HabitColor(key: "mandarine").name == "Mandarine")
    }

    @Test func legacyAndUnknownKeysFallBack() {
        #expect(HabitColor(key: "sauge") == .menthe)
        #expect(HabitColor(key: "lavande") == .lilas)
        #expect(HabitColor(key: "inconnue") == .menthe)
    }

    @Test func colorTokensExistInTheAssetCatalog() {
        let names = ["Canvas", "Surface", "Surface2", "Line", "Ink", "Ink2", "Ink3", "Accent", "AccentSoft",
                     "AccentInk", "AccentText", "Sun", "SunText", "Ok", "OkSoft", "Edge", "EdgeSoft", "Over", "OverSoft"]
        for name in names {
            #expect(UIColor(named: name, in: .main, compatibleWith: nil) != nil, "Couleur manquante : \(name)")
        }
    }

    @Test func fontsAreRegistered() {
        for face in [RituelFontFace.title, .titleMedium, .regular, .semibold, .bold] {
            #expect(UIFont(name: face.rawValue, size: 15) != nil, "Police manquante : \(face.rawValue)")
        }
    }
}
