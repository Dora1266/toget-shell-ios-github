import Capacitor
import SafariServices
import UIKit

@objc(ToGetBrowserPlugin)
public class ToGetBrowserPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "ToGetBrowserPlugin"
    public let jsName = "ToGetBrowser"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "open", returnType: CAPPluginReturnPromise)
    ]

    @objc func open(_ call: CAPPluginCall) {
        let raw = String(call.getString("url") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: raw), !raw.isEmpty else {
            call.reject("missing_url")
            return
        }

        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:]) { ok in
                if ok {
                    call.resolve(["ok": true])
                } else {
                    call.reject("open_failed")
                }
            }
        }
    }
}

