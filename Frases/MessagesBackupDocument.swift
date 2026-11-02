import Foundation
import SwiftUI
import UniformTypeIdentifiers

// El respaldo incluye solamente mensajes: no cambia el horario ni la frecuencia.
// Formato JSON versionado, legible desde la app Archivos.
private struct MessagesBackupPayload: Codable {
    let format: String
    let version: Int
    let exportedAt: Date
    let messages: [String]
}

enum MessagesBackupError: LocalizedError {
    case notAFile
    case unsupportedFormat
    case invalidMessages
    case fileTooLarge

    var errorDescription: String? {
        switch self {
        case .notAFile:
            return "El archivo seleccionado está vacío o no se puede leer."
        case .unsupportedFormat:
            return "Este archivo no es un respaldo compatible de Avisos (versión 1)."
        case .invalidMessages:
            return "El respaldo no contiene mensajes válidos o supera el límite de 10,000 mensajes."
        case .fileTooLarge:
            return "El respaldo supera el tamaño máximo permitido de 5 MB."
        }
    }
}

struct MessagesBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    static var writableContentTypes: [UTType] { [.json] }

    var messages: [String]

    init(messages: [String]) {
        self.messages = messages
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw MessagesBackupError.notAFile
        }
        messages = try Self.decodeMessages(from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let payload = MessagesBackupPayload(
            format: "com.personal.frases.backup",
            version: 1,
            exportedAt: Date(),
            messages: messages
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(payload)
        guard messages.count <= 10_000 else { throw MessagesBackupError.invalidMessages }
        guard data.count <= 5_000_000 else { throw MessagesBackupError.fileTooLarge }
        return FileWrapper(regularFileWithContents: data)
    }

    static func decodeMessages(from data: Data) throws -> [String] {
        guard !data.isEmpty else { throw MessagesBackupError.notAFile }
        guard data.count <= 5_000_000 else { throw MessagesBackupError.fileTooLarge }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload: MessagesBackupPayload
        do {
            payload = try decoder.decode(MessagesBackupPayload.self, from: data)
        } catch {
            throw MessagesBackupError.unsupportedFormat
        }
        guard payload.format == "com.personal.frases.backup", payload.version == 1 else {
            throw MessagesBackupError.unsupportedFormat
        }
        guard !payload.messages.isEmpty, payload.messages.count <= 10_000 else {
            throw MessagesBackupError.invalidMessages
        }
        let trimmed = payload.messages.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard trimmed.allSatisfy({ !$0.isEmpty }) else {
            throw MessagesBackupError.invalidMessages
        }
        return trimmed
    }
}

// La lista publicada por PhraseStore activa su guardado existente y marca
// los avisos como pendientes de reprogramación. No se pierden las preferencias.
@MainActor
extension PhraseStore {
    func restoreMessages(_ incoming: [String], replacing: Bool) -> (imported: Int, total: Int) {
        func key(_ message: String) -> String {
            message.trimmingCharacters(in: .whitespacesAndNewlines)
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "es_MX"))
        }

        var seen: Set<String> = replacing ? [] : Set(phrases.map { key($0.text) })
        let additions: [PersonalPhrase] = incoming.compactMap { message in
            let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, seen.insert(key(trimmed)).inserted else { return nil }
            return PersonalPhrase(text: trimmed)
        }

        if replacing {
            phrases = additions
        } else if !additions.isEmpty {
            phrases.append(contentsOf: additions)
        }
        return (additions.count, phrases.count)
    }
}
