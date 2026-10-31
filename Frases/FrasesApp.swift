import SwiftUI
import UserNotifications

@main
struct FrasesApp: App {
    @StateObject private var store = PhraseStore()

    init() {
        // Permite que también se muestre un aviso cuando la app está abierta.
        UNUserNotificationCenter.current().delegate = ForegroundNotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
        }
    }
}

final class ForegroundNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = ForegroundNotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }
}
