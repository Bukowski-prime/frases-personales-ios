import Foundation
import Combine
import UserNotifications

struct PersonalPhrase: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var text: String
}

struct UpcomingNotice: Identifiable {
    let id: String
    let date: Date
    let text: String
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
    static let maxPendingNotifications = 64

    // Mismo identificador de almacenamiento que v1.0: conserva los mensajes.
    private static let defaultsKey = "FrasesPersonales.settings.v1"
    private static let appliedKey = "FrasesPersonales.appliedSettings.v1.3"
    private static let notificationPrefix = "personal-phrase-slot-"

    @Published var phrases: [PersonalPhrase] = [] { didSet { settingsChanged() } }
    @Published var intervalMinutes: Int = 30 { didSet { settingsChanged() } }
    @Published var startMinute: Int = 7 * 60 { didSet { settingsChanged() } }
    @Published var endMinute: Int = 20 * 60 { didSet { settingsChanged() } }
    @Published var notificationsEnabled: Bool = false { didSet { settingsChanged() } }

    @Published private(set) var statusMessage = "Agrega mensajes y pulsa «Guardar y programar»."
    @Published private(set) var scheduledCount = 0
    @Published private(set) var scheduledUntil: Date?
    @Published private(set) var isApplying = false
    private var isRefreshing = false
    @Published private(set) var hasError = false
    @Published private(set) var needsProgramming = false
    @Published private(set) var upcomingNotices: [UpcomingNotice] = []

    init() {
        if let raw = UserDefaults.standard.data(forKey: Self.defaultsKey),
           let saved = try? JSONDecoder().decode(SavedSettings.self, from: raw) {
            phrases = saved.phrases
            intervalMinutes = Self.possibleIntervals.contains(saved.intervalMinutes) ? saved.intervalMinutes : 30
            startMinute = min(max(saved.startMinute, 0), 1439)
            endMinute = min(max(saved.endMinute, 0), 1439)
            notificationsEnabled = saved.notificationsEnabled
        }
        // No reponer automáticamente datos editados que no se han programado.
        needsProgramming = UserDefaults.standard.string(forKey: Self.appliedKey) != settingsSignature()
    }

    private var duration: Int {
        if endMinute > startMinute { return endMinute - startMinute }
        return 1440 - startMinute + endMinute
    }

    private var offsets: [Int] {
        let step = max(1, intervalMinutes)
        if startMinute == endMinute {
            return Array(stride(from: 0, to: duration, by: step))
        }
        return Array(stride(from: 0, through: duration, by: step))
    }

    var dailyTimes: [Int] { offsets.map { (startMinute + $0) % 1440 } }

    var configurationSummary: String {
        "\(dailyTimes.count) avisos diarios · hasta \(Self.maxPendingNotifications) programados"
    }

    func addPhrase(_ rawText: String) {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard !phrases.contains(where: { Self.sameText($0.text, text) }) else {
            reportError("Ese mensaje ya existe.")
            return
        }
        phrases.append(PersonalPhrase(text: text))
    }

    func updatePhrase(id: UUID, text rawText: String) {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let index = phrases.firstIndex(where: { $0.id == id }) else { return }
        guard !phrases.contains(where: { $0.id != id && Self.sameText($0.text, text) }) else {
            reportError("Ya existe otro mensaje con ese texto.")
            return
        }
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

    /// Al abrir la app y cuando iOS concede una actualización en segundo plano:
    /// agrega avisos futuros sin tocar los existentes ni repetirlos.
    func replenishIfNeeded(isBackground: Bool = false) async {
        guard !isApplying && !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        let center = UNUserNotificationCenter.current()
        let pending = await existingRequests(center: center)

        if !notificationsEnabled {
            if !isBackground { await refreshPending(using: pending) }
            return
        }
        // Tras actualizar desde v1.2 puede haber solicitudes repetitivas antiguas.
        // Sólo se sustituyen al pulsar Guardar y programar.
        if needsProgramming || pending.contains(where: { $0.trigger?.repeats == true }) {
            if !isBackground {
                await refreshPending(using: pending)
                needsProgramming = true
                statusMessage = "Pulsa «Guardar y programar» para activar la rotación entre días."
                hasError = false
            }
            return
        }
        guard !phrases.isEmpty, dailyTimes.count <= Self.maxPendingNotifications else { return }
        let missing = Self.maxPendingNotifications - pending.count
        if missing > 0 {
            do {
                try await appendNotices(count: missing, existing: pending, center: center)
            } catch {
                if !isBackground { reportError("No se pudo renovar los avisos: \(error.localizedDescription)") }
                return
            }
        }
        if !isBackground {
            await refreshPending()
            statusMessage = "Avisos preparados. Se renovarán al abrir la app; iOS también puede renovarlos en segundo plano."
            hasError = false
        }
        BackgroundRefreshController.shared.requestRefresh()
    }

    func applySchedule() async {
        guard !isApplying else { return }
        isApplying = true
        defer { isApplying = false }
        persist()
        let center = UNUserNotificationCenter.current()

        if notificationsEnabled {
            guard !phrases.isEmpty else {
                reportError("Primero agrega al menos un mensaje.")
                return
            }
            guard dailyTimes.count <= Self.maxPendingNotifications else {
                reportError("Este horario requiere \(dailyTimes.count) avisos al día, más de 64. Amplía el intervalo.")
                return
            }
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound])
                guard granted else {
                    reportError("Activa las notificaciones de Avisos en Configuración.")
                    return
                }
            } catch {
                reportError("No se pudo solicitar permiso: \(error.localizedDescription)")
                return
            }
        }

        let pending = await existingRequests(center: center)
        center.removePendingNotificationRequests(withIdentifiers: pending.map(\.identifier))
        if !notificationsEnabled {
            BackgroundRefreshController.shared.cancelRefresh()
            rememberAppliedSettings()
            scheduledCount = 0
            scheduledUntil = nil
            upcomingNotices = []
            needsProgramming = false
            hasError = false
            statusMessage = "Notificaciones desactivadas."
            return
        }

        do {
            try await appendNotices(count: Self.maxPendingNotifications, existing: [], center: center)
            rememberAppliedSettings()
            needsProgramming = false
            hasError = false
            await refreshPending()
            statusMessage = "Rotación aleatoria entre días activada. Abre la app cada 1–2 días para asegurar la renovación."
            BackgroundRefreshController.shared.requestRefresh()
        } catch {
            let added = await existingRequests(center: center)
            center.removePendingNotificationRequests(withIdentifiers: added.map(\.identifier))
            await refreshPending()
            reportError("No se pudo completar la programación: \(error.localizedDescription). Vuelve a intentarlo.")
        }
    }

    private func appendNotices(
        count: Int,
        existing: [UNNotificationRequest],
        center: UNUserNotificationCenter
    ) async throws {
        guard count > 0 else { return }
        let now = Date()
        let latestDate = existing.compactMap { $0.trigger?.nextTriggerDate() }.max()
        let afterDate = max(now, latestDate ?? now)
        let futureDates = nextScheduledDates(after: afterDate, limit: count)
        let lastText = existing.compactMap { request -> (Date, String)? in
            guard let date = request.trigger?.nextTriggerDate() else { return nil }
            return (date, request.content.body)
        }.max(by: { $0.0 < $1.0 })?.1
        let texts = randomTexts(count: futureDates.count, avoidingFirst: lastText)
        let calendar = Calendar.current
        for (date, text) in zip(futureDates, texts) {
            let content = UNMutableNotificationContent()
            content.body = text
            content.sound = .default
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let identifier = Self.notificationPrefix + String(Int(date.timeIntervalSince1970))
            try await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
        }
    }

    // Fecha concreta para cada aviso; no se reutiliza el contenido al día siguiente.
    private func nextScheduledDates(after reference: Date, limit: Int) -> [Date] {
        guard limit > 0 else { return [] }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: reference)
        var dates: [Date] = []
        // El caso más espaciado (24 h) requiere mirar al menos 64 días.
        for dayOffset in 0..<130 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            for offset in offsets {
                let absoluteMinute = startMinute + offset
                guard let actualDay = calendar.date(byAdding: .day, value: absoluteMinute / 1440, to: day),
                      let date = calendar.date(bySettingHour: (absoluteMinute % 1440) / 60,
                                               minute: absoluteMinute % 60,
                                               second: 0, of: actualDay,
                                               matchingPolicy: .nextTime) else { continue }
                // Incluye sólo horarios estrictamente futuros.
                if date > reference.addingTimeInterval(2) { dates.append(date) }
            }
            if dates.count >= limit {
                return Array(dates.sorted().prefix(limit))
            }
        }
        return Array(dates.sorted().prefix(limit))
    }

    private func randomTexts(count: Int, avoidingFirst previousText: String?) -> [String] {
        var seen = Set<String>()
        let choices = phrases.map(\.text).filter { seen.insert(Self.normalized($0)).inserted }
        guard !choices.isEmpty else { return [] }
        if choices.count == 1 { return Array(repeating: choices[0], count: count) }
        var lastText = previousText.map(Self.normalized)
        var bag: [String] = []
        var sequence: [String] = []
        for _ in 0..<count {
            if bag.isEmpty {
                bag = choices.shuffled()
                if Self.normalized(bag[0]) == lastText,
                   let index = bag.indices.dropFirst().first(where: { Self.normalized(bag[$0]) != lastText }) {
                    bag.swapAt(0, index)
                }
            }
            let next = bag.removeFirst()
            sequence.append(next)
            lastText = Self.normalized(next)
        }
        return sequence
    }

    private func existingRequests(center: UNUserNotificationCenter) async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests()
            .filter { $0.identifier.hasPrefix(Self.notificationPrefix) }
    }

    private func refreshPending(using known: [UNNotificationRequest]? = nil) async {
        let requests: [UNNotificationRequest]
        if let known { requests = known }
        else { requests = await existingRequests(center: UNUserNotificationCenter.current()) }
        let sorted = requests.compactMap { request -> UpcomingNotice? in
            guard let date = request.trigger?.nextTriggerDate() else { return nil }
            return UpcomingNotice(id: request.identifier, date: date, text: request.content.body)
        }.sorted { $0.date < $1.date }
        scheduledCount = requests.count
        scheduledUntil = sorted.last?.date
        upcomingNotices = Array(sorted.prefix(3))
    }

    private func rememberAppliedSettings() {
        UserDefaults.standard.set(settingsSignature(), forKey: Self.appliedKey)
    }

    private func currentSettings() -> SavedSettings {
        SavedSettings(phrases: phrases, intervalMinutes: intervalMinutes,
                      startMinute: startMinute, endMinute: endMinute,
                      notificationsEnabled: notificationsEnabled)
    }

    private func settingsSignature() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return (try? encoder.encode(currentSettings()).base64EncodedString()) ?? ""
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(currentSettings()) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }
    }

    private func settingsChanged() {
        persist()
        needsProgramming = true
        hasError = false
        statusMessage = "Cambios pendientes: pulsa «Guardar y programar»."
    }

    private func reportError(_ text: String) {
        statusMessage = text
        hasError = true
    }

    private static func normalized(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "es_MX"))
    }

    private static func sameText(_ a: String, _ b: String) -> Bool {
        normalized(a) == normalized(b)
    }
}
