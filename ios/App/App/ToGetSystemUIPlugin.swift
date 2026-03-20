import Capacitor

@objc(ToGetSystemUIPlugin)
public class ToGetSystemUIPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "ToGetSystemUIPlugin"
    public let jsName = "ToGetSystemUI"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "setStatusBar", returnType: CAPPluginReturnPromise)
    ]

    @objc func setStatusBar(_ call: CAPPluginCall) {
        let style = String(call.getString("style") ?? "dark").trimmingCharacters(in: .whitespacesAndNewlines)
        let backgroundColor = String(call.getString("backgroundColor") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        DispatchQueue.main.async {
            ToGetSystemUIState.shared.update(styleName: style, backgroundColorHex: backgroundColor)
            call.resolve(["ok": true])
        }
    }
}

