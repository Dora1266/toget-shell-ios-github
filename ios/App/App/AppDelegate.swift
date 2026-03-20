import UIKit
import Capacitor
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        ToGetPushState.shared.configure(application: application)
        UNUserNotificationCenter.current().delegate = self
        dispatchLaunchNotificationOpen(launchOptions)
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        dispatchOauthTicket(url)
        // Called when the app was launched with a url. Feel free to add additional processing here,
        // but if you want the App API to support tracking app url opens, make sure to keep this call
        return ApplicationDelegateProxy.shared.application(app, open: url, options: options)
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        // Called when the app was launched with an activity, including Universal Links.
        // Feel free to add additional processing here, but if you want the App API to support
        // tracking app url opens, make sure to keep this call
        return ApplicationDelegateProxy.shared.application(application, continue: userActivity, restorationHandler: restorationHandler)
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        ToGetPushState.shared.setApnsToken(deviceToken)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .list, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        dispatchPushOpen(response.notification.request.content.userInfo)
        completionHandler()
    }

    private func dispatchLaunchNotificationOpen(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        guard let remote = launchOptions?[.remoteNotification] as? [AnyHashable: Any] else {
            return
        }
        dispatchPushOpen(remote)
    }

    private func dispatchPushOpen(_ userInfo: [AnyHashable: Any]) {
        let sessionId = normalizedPushField(userInfo["sessionId"])
        let messageId = normalizedPushField(userInfo["assistantMessageId"])
        if sessionId.isEmpty { return }
        dispatchEventWhenWebReady(
            name: "toget.push.open",
            detail: [
                "sessionId": sessionId,
                "messageId": messageId
            ]
        )
    }

    private func normalizedPushField(_ value: Any?) -> String {
        switch value {
        case let string as String:
            return string.trimmingCharacters(in: .whitespacesAndNewlines)
        case let number as NSNumber:
            return number.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        case .none:
            return ""
        default:
            return String(describing: value!).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private func dispatchOauthTicket(_ url: URL) {
        if url.scheme?.lowercased() != "toget" { return }
        if url.host?.lowercased() != "oauth" { return }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let ticket = String(components?.queryItems?.first(where: { $0.name == "ticket" })?.value ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if ticket.isEmpty { return }
        dispatchEventWhenWebReady(
            name: "toget.oauth.ticket",
            detail: ["ticket": ticket]
        )
    }

    private func dispatchEventWhenWebReady(name: String, detail: [String: String], attempt: Int = 0) {
        if attempt > 80 { return }
        guard let controller = bridgeViewController(),
              let webView = controller.webView else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.dispatchEventWhenWebReady(name: name, detail: detail, attempt: attempt + 1)
            }
            return
        }

        webView.evaluateJavaScript("(function(){try{return (window.__TOGET_WEB_READY__===true);}catch(e){return false;}})()") { value, _ in
            let ready = (value as? Bool) == true
            if !ready {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.dispatchEventWhenWebReady(name: name, detail: detail, attempt: attempt + 1)
                }
                return
            }

            let payload = self.serializeJson(detail) ?? "{}"
            let js = "try{window.dispatchEvent(new CustomEvent('\(name)',{detail:\(payload)}));}catch(e){}"
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    private func bridgeViewController() -> ToGetBridgeViewController? {
        if let controller = window?.rootViewController as? ToGetBridgeViewController {
            return controller
        }
        if let navigation = window?.rootViewController as? UINavigationController {
            return navigation.viewControllers.first as? ToGetBridgeViewController
        }
        return nil
    }

    private func serializeJson(_ value: [String: String]) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: value, options: []),
              let text = String(data: data, encoding: .utf8)
        else {
            return nil
        }
        return text
    }

}
