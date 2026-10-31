import UIKit
import BackgroundTasks

/// Renovación oportunista: iOS decide si/cuándo ejecutar esta tarea.
final class BackgroundRefreshController {
    static let shared = BackgroundRefreshController()
    static let identifier = "com.personal.frases.refresh"

    private init() {}

    func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.identifier, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self.handle(refreshTask)
        }
    }

    func requestRefresh() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.identifier)
        let request = BGAppRefreshTaskRequest(identifier: Self.identifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 8 * 60 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // Es normal que iOS limite los trabajos en segundo plano.
            print("No fue posible solicitar actualización en segundo plano: \(error)")
        }
    }

    func cancelRefresh() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.identifier)
    }

    private func handle(_ backgroundTask: BGAppRefreshTask) {
        // Solicitar la siguiente oportunidad antes de finalizar la actual.
        requestRefresh()
        let operation = Task { @MainActor in
            await PhraseStore().replenishIfNeeded(isBackground: true)
            backgroundTask.setTaskCompleted(success: !Task.isCancelled)
        }
        backgroundTask.expirationHandler = {
            operation.cancel()
        }
    }
}

final class ApplicationDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        BackgroundRefreshController.shared.register()
        return true
    }
}
