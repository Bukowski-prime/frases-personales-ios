import Foundation
import Combine
import UserNotifications

struct PersonalPhrase: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var text: String
}

private struct SavedSettings: Codable {
    var phrases: [PersonalPhrase]
    var intervalMinutes: Int
    var startMinute: Int
    var endMinute: Int
    var notificationsEnabled: Bool
}

@MainActor
final class PhraseStore: ObservableObject {
    static let possibleIntervals = [5, 10, 15, 20, 30, 45, 60, 90, 120, 180, 240, 360, 720, 1440]
    static let maxDailyNotifications = 64
    private static let defaultsKey = "FrasesPersonales.settings.v1"
    private static let notificationPrefix = "personal-phrase-slot-"

    @Published var phrases: [PersonalPhrase] = [] { didSet { persist() } }
    @Published var intervalMinutes: Int = 30 { didSet { persist() } }
    @Published var startMinute: Int = 8 * 60 { didSet { persist() } }
    @Published var endMinute: Int = 22 * 60 { didSet { persist() } }
    @Published var notificationsEnabled: Bool = false { didSet { persist() } }

    @Published private(set) var statusMessage = "Agrega frases, activa los avisos y pulsa «Guardar y programar»."
    @Published private(set) var scheduledCount = 0
    @Published private(set) var isApplying = false
    @Published private(set) var hasError = false

    init() {
        if let raw = UserDefaults.standard.data(forKey: Self.defaultsKey),
           let saved = try? JSONDecoder().decode(SavedSettings.self, from: raw) {
            phrases = saved.phrases
            intervalMinutes = Self.possibleIntervals.contains(saved.intervalMinutes) ? saved.intervalMinutes : 30
            startMinute = min(max(saved.startMinute, 0), 1439)
            endMinute = min(max(saved.endMinute, 0), 1439)
            notificationsEnabled = saved.notificationsEnabled
        }
    }

    var dailyTimes: [Int] {
        let duration: Int
        if endMinute > startMinute {
            duration = endMinute - startMinute
        } else {
            // Inicio == fin significa 24 horas; también admite horarios nocturnos.
            duration = (1440 - startMinute) + endMinute
        }
        return stride(from: 0, to: duration, by: max(1, intervalMinutes))
            .map { (startMinute + $0) % 1440 }
    }

    var configurationSummary: String {
        let count = dailyTimes.count
        return "\(count) aviso\(count == 1 ? "" : "s") diario\(count == 1 ? "" : "s") · máximo \(Self.maxDailyNotifications)"
    }

    func addPhrase(_ rawText: String) {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        phrases.append(PersonalPhrase(text: text))
    }

    func updatePhrase(id: UUID, text rawText: String) {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let index = phrases.firstIndex(where: { $0.id == id }) else { return }
        phrases[index].text = text
    }

    func deletePhrases(at offsets: IndexSet) {
        phrases.remove(atOffsets: offsets)
    }

    func date(for minute: Int) -> Date {
        let today = Calendar.current.startOfDay(for: Date())
        return Calendar.current.date(byAdding: .minute, value: minute, to: today) ?? today
    }

    func minute(of date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    func refreshScheduledCount() async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        scheduledCount = requests.filter { $0.identifier.hasPrefix(Self.notificationPrefix) }.count
        if scheduledCount > 0 {
            statusMessage = "Hay \(scheduledCount) horarios diarios programados."
            hasError = false
        } else if notificationsEnabled {
            statusMessage = "Todavía no hay avisos programados. Pulsa «Guardar y programar»."
            hasError = true
        }
    }

    func applySchedule() async {
        guard !isApplying else { return }
        isApplying = true
        defer { isApplying = false }
        persist()
        let center = UNUserNotificationCenter.current()

        // Comprueba primero la nueva configuración: si falla, conserva el horario anterior.
        if notificationsEnabled {
            guard !phrases.isEmpty else {
                reportError("Primero agrega al menos una frase.")
                return
            }
            guard dailyTimes.count <= Self.maxDailyNotifications else {
                reportError("Esta configuración necesita \(dailyTimes.count) avisos diarios. Cambia el intervalo o acorta el horario para no superar 64.")
                return
            }
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound])
                guard granted else {
                    reportError("Las notificaciones están desactivadas. Actívalas en Ajustes del iPhone para esta app.")
                    return
                }
            } catch {
                reportError("No se pudo solicitar permiso: \(error.localizedDescription)")
                return
            }
        }

        let old = await center.pendingNotificationRequests()
            .filter { $0.identifier.hasPrefix(Self.notificationPrefix) }
            .map(\.identifier)
        center.removePendingNotificationRequests(withIdentifiers: old)
        if !notificationsEnabled {
            scheduledCount = 0
            hasError = false
            statusMessage = "Notificaciones desactivadas y avisos pendientes eliminados."
            return
        }

        // Cada solicitud se repite todos los días a una hora fija.
        // Una misma hora conserva su frase hasta que el usuario reprograme.
        var shuffledBag: [PersonalPhrase] = []
        var previousID: UUID?
        var successfullyAdded: [String] = []
        do {
            for (index, minute) in dailyTimes.enumerated() {
                if shuffledBag.isEmpty {
                    shuffledBag = phrases.shuffled()
                    // Evita repetir dos veces seguidas al reiniciar la bolsa si es posible.
                    if shuffledBag.count > 1, shuffledBag.last?.id == previousID {
                        shuffledBag.swapAt(0, shuffledBag.count - 1)
                    }
                }
                let phrase = shuffledBag.removeLast()
                previousID = phrase.id

                let content = UNMutableNotificationContent()
                content.title = "Frases Personales"
                content.body = phrase.text
                content.sound = .default

                var components = DateComponents()
                components.hour = minute / 60
                components.minute = minute % 60
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let id = Self.notificationPrefix + String(index)
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                try await center.add(request)
                successfullyAdded.append(id)
            }
            scheduledCount = successfullyAdded.count
            hasError = false
            statusMessage = "Programados \(scheduledCount) avisos diarios. Funcionan con la app cerrada."
        } catch {
            // No dejar un conjunto incompleto en caso de error.
            center.removePendingNotificationRequests(withIdentifiers: successfullyAdded)
            scheduledCount = 0
            reportError("No se pudo terminar la programación: \(error.localizedDescription). Intenta de nuevo.")
        }
    }

    private func reportError(_ text: String) {
        hasError = true
        statusMessage = text
    }

    private func persist() {
        let settings = SavedSettings(
            phrases: phrases,
            intervalMinutes: intervalMinutes,
            startMinute: startMinute,
            endMinute: endMinute,
            notificationsEnabled: notificationsEnabled
        )
        if let raw = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(raw, forKey: Self.defaultsKey)
        }
    }
}
