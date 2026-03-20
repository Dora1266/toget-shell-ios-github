import Foundation
import FirebaseCore
import FirebaseMessaging
import UIKit
import UserNotifications

final class ToGetPushState: NSObject, MessagingDelegate {
    static let shared = ToGetPushState()

    private let lock = NSLock()
    private var currentToken = ""
    private var firebaseConfigured = false

    private override init() {
        super.init()
    }

    func configure(application: UIApplication) {
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            return
        }
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        firebaseConfigured = true
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
    }

    func getToken(completion: @escaping (Result<String, Error>) -> Void) {
        lock.lock()
        let cached = currentToken
        let configured = firebaseConfigured
        lock.unlock()

        if !cached.isEmpty {
            completion(.success(cached))
            return
        }
        guard configured else {
            completion(.failure(NSError(domain: "ToGetPush", code: 1, userInfo: [NSLocalizedDescriptionKey: "token_unavailable"])))
            return
        }

        Messaging.messaging().token { token, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            let value = String(token ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if value.isEmpty {
                completion(.failure(NSError(domain: "ToGetPush", code: 2, userInfo: [NSLocalizedDescriptionKey: "token_empty"])))
                return
            }
            self.lock.lock()
            self.currentToken = value
            self.lock.unlock()
            completion(.success(value))
        }
    }

    func setApnsToken(_ deviceToken: Data) {
        guard firebaseConfigured else { return }
        Messaging.messaging().apnsToken = deviceToken
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        let value = String(fcmToken ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        lock.lock()
        currentToken = value
        lock.unlock()
    }
}
