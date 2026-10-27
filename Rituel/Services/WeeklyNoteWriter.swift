import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// « Un mot pour ta semaine », écrit par le modèle d'Apple sur l'appareil (iOS 26 et Apple Intelligence).
/// Sur les appareils qui ne l'ont pas, le bloc est masqué.
enum WeeklyNoteWriter {
    enum Failure: Error {
        case unavailable
    }

    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let model = SystemLanguageModel.default
            guard case .available = model.availability else { return false }
            return model.supportsLocale(.rituel)
        }
        #endif
        return false
    }

    static func write(prompt: String) async throws -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let session = LanguageModelSession(instructions: """
            Tu es un compagnon doux et bienveillant dans une app d'habitudes. Tu tutoies, tu écris en français, \
            tu ne culpabilises jamais et tu n'utilises pas d'emoji.
            """)
            let response = try await session.respond(to: prompt)
            return RecapEngine.cleanNote(response.content)
        }
        #endif
        throw Failure.unavailable
    }
}
