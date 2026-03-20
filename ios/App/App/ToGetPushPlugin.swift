import Capacitor
import UIKit

@objc(ToGetPushPlugin)
public class ToGetPushPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "ToGetPushPlugin"
    public let jsName = "ToGetPush"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "getToken", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getDeviceId", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getAppVersion", returnType: CAPPluginReturnPromise)
    ]

    @objc func getToken(_ call: CAPPluginCall) {
        ToGetPushState.shared.getToken { result in
            switch result {
            case .success(let token):
                call.resolve(["token": token])
            case .failure(let error):
                call.reject(String(error.localizedDescription), nil, error)
            }
        }
    }

    @objc func getDeviceId(_ call: CAPPluginCall) {
        let value = UIDevice.current.identifierForVendor?.uuidString ?? ""
        call.resolve(["deviceId": value])
    }

    @objc func getAppVersion(_ call: CAPPluginCall) {
        let version = String(
            Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? ""
        )
        call.resolve(["appVersion": version])
    }
}

