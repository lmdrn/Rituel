import Foundation

/// Identifiants lus depuis Info.plist, eux-mêmes renseignés par Config.xcconfig.
enum AppConfig {
    static let appGroup: String = infoString("RituelAppGroup") ?? "group.com.leamedrano.rituel.shared"
    static let cloudKitContainer: String = infoString("RituelCloudKitContainer") ?? "iCloud.com.leamedrano.rituel"

    private static func infoString(_ key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              !value.isEmpty, !value.contains("$(") else { return nil }
        return value
    }
}
