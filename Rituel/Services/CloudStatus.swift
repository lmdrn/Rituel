import CloudKit

/// État réel de la synchro iCloud, pour l'afficher dans les réglages.
enum CloudStatus {
    /// Vrai si la base a été ouverte avec CloudKit et qu'un compte iCloud est disponible.
    static func isSyncing() async -> Bool {
        guard RituelStore.syncsWithCloud, FileManager.default.ubiquityIdentityToken != nil else { return false }
        let status = try? await CKContainer(identifier: AppConfig.cloudKitContainer).accountStatus()
        return status == .available
    }
}
