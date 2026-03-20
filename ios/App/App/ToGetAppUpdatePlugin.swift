import Capacitor
import UIKit

@objc(ToGetAppUpdatePlugin)
public class ToGetAppUpdatePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "ToGetAppUpdatePlugin"
    public let jsName = "ToGetAppUpdate"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "getInstalledVersion", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "downloadAndInstall", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "openInstallPermissionSettings", returnType: CAPPluginReturnPromise)
    ]

    @objc func getInstalledVersion(_ call: CAPPluginCall) {
        let packageName = String(Bundle.main.bundleIdentifier ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let versionName = String(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")
        let versionCodeText = String(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0")
        let versionCode = Int(versionCodeText) ?? 0
        call.resolve([
            "packageName": packageName,
            "versionName": versionName,
            "versionCode": versionCode,
            "canRequestPackageInstalls": false
        ])
    }

    @objc func downloadAndInstall(_ call: CAPPluginCall) {
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

    @objc func openInstallPermissionSettings(_ call: CAPPluginCall) {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            call.reject("open_settings_failed")
            return
        }
        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:]) { ok in
                if ok {
                    call.resolve(["ok": true])
                } else {
                    call.reject("open_settings_failed")
                }
            }
        }
    }
}
