import Capacitor
import UIKit

final class ToGetBridgeViewController: CAPBridgeViewController {
    private let statusBarBackgroundView = UIView()
    private var statusBarStyleOverride: UIStatusBarStyle = .darkContent

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return statusBarStyleOverride
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        statusBarBackgroundView.isUserInteractionEnabled = false
        statusBarBackgroundView.translatesAutoresizingMaskIntoConstraints = true
        statusBarBackgroundView.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        view.addSubview(statusBarBackgroundView)
        view.bringSubviewToFront(statusBarBackgroundView)
        ToGetSystemUIState.shared.attach(controller: self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutStatusBarBackground()
    }

    func applyStatusBar(styleName: String, backgroundColorHex: String) {
        let style = String(styleName).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if style == "light" {
            statusBarStyleOverride = .darkContent
        } else {
            if #available(iOS 13.0, *) {
                statusBarStyleOverride = .lightContent
            } else {
                statusBarStyleOverride = .default
            }
        }

        let color = Self.parseColor(backgroundColorHex) ?? .clear
        statusBarBackgroundView.backgroundColor = color
        layoutStatusBarBackground()
        setNeedsStatusBarAppearanceUpdate()
    }

    private func layoutStatusBarBackground() {
        let topInset = view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? view.safeAreaInsets.top
        statusBarBackgroundView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: max(0, topInset))
    }

    private static func parseColor(_ raw: String) -> UIColor? {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return nil }
        var hex = text
        if hex.hasPrefix("#") { hex.removeFirst() }
        var value: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&value) else { return nil }

        switch hex.count {
        case 6:
            let r = CGFloat((value & 0xFF0000) >> 16) / 255.0
            let g = CGFloat((value & 0x00FF00) >> 8) / 255.0
            let b = CGFloat(value & 0x0000FF) / 255.0
            return UIColor(red: r, green: g, blue: b, alpha: 1.0)
        case 8:
            let a = CGFloat((value & 0xFF000000) >> 24) / 255.0
            let r = CGFloat((value & 0x00FF0000) >> 16) / 255.0
            let g = CGFloat((value & 0x0000FF00) >> 8) / 255.0
            let b = CGFloat(value & 0x000000FF) / 255.0
            return UIColor(red: r, green: g, blue: b, alpha: a)
        default:
            return nil
        }
    }
}
