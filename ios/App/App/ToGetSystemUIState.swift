import UIKit

private final class WeakBridgeController {
    weak var value: ToGetBridgeViewController?

    init(_ value: ToGetBridgeViewController? = nil) {
        self.value = value
    }
}

final class ToGetSystemUIState {
    static let shared = ToGetSystemUIState()

    static let prefsName = "toget_system_ui"
    static let prefStatusBarColor = "status_bar_color"
    static let prefStatusBarStyle = "status_bar_style"

    private let controllerRef = WeakBridgeController()
    private let defaults = UserDefaults.standard
    private let lock = NSLock()
    private var backgroundColorHex: String
    private var styleName: String

    private init() {
        self.backgroundColorHex = defaults.string(forKey: Self.prefStatusBarColor) ?? ""
        self.styleName = defaults.string(forKey: Self.prefStatusBarStyle) ?? ""
    }

    func attach(controller: ToGetBridgeViewController) {
        lock.lock()
        controllerRef.value = controller
        let style = styleName
        let colorHex = backgroundColorHex
        lock.unlock()
        controller.applyStatusBar(styleName: style, backgroundColorHex: colorHex)
    }

    func update(styleName: String, backgroundColorHex: String) {
        lock.lock()
        self.styleName = styleName
        self.backgroundColorHex = backgroundColorHex
        defaults.set(styleName, forKey: Self.prefStatusBarStyle)
        defaults.set(backgroundColorHex, forKey: Self.prefStatusBarColor)
        let controller = controllerRef.value
        lock.unlock()
        controller?.applyStatusBar(styleName: styleName, backgroundColorHex: backgroundColorHex)
    }

    func snapshot() -> (styleName: String, backgroundColorHex: String) {
        lock.lock()
        let value = (styleName: styleName, backgroundColorHex: backgroundColorHex)
        lock.unlock()
        return value
    }
}

