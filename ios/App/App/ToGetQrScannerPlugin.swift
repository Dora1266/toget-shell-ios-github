import AVFoundation
import Capacitor
import UIKit

final class ToGetQrScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    enum ScannerError: Error {
        case unavailable
        case cancelled
    }

    var onFinish: ((Result<String, Error>) -> Void)?
    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let promptLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private var finished = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupScanner()
        setupOverlay()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func setupScanner() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(input)
        else {
            finish(.failure(ScannerError.unavailable))
            return
        }

        let output = AVCaptureMetadataOutput()
        guard captureSession.canAddOutput(output) else {
            finish(.failure(ScannerError.unavailable))
            return
        }

        captureSession.addInput(input)
        captureSession.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        output.metadataObjectTypes = [.qr]

        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.layer.bounds
        view.layer.addSublayer(layer)
        previewLayer = layer
    }

    private func setupOverlay() {
        promptLabel.translatesAutoresizingMaskIntoConstraints = false
        promptLabel.text = "将二维码放入框内"
        promptLabel.textColor = .white
        promptLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        promptLabel.textAlignment = .center
        promptLabel.numberOfLines = 2
        view.addSubview(promptLabel)

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setTitle("关闭", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        closeButton.layer.cornerRadius = 18
        closeButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            promptLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            promptLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            promptLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            promptLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    @objc private func closeTapped() {
        finish(.failure(ScannerError.cancelled))
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              object.type == .qr,
              let text = object.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty
        else {
            return
        }
        finish(.success(text))
    }

    private func finish(_ result: Result<String, Error>) {
        if finished { return }
        finished = true
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
        dismiss(animated: true) {
            self.onFinish?(result)
        }
    }
}

@objc(ToGetQrScannerPlugin)
public class ToGetQrScannerPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "ToGetQrScannerPlugin"
    public let jsName = "ToGetQrScanner"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "scan", returnType: CAPPluginReturnPromise)
    ]

    @objc func scan(_ call: CAPPluginCall) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            presentScanner(call)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.presentScanner(call)
                    } else {
                        call.reject("camera_permission_denied")
                    }
                }
            }
        default:
            call.reject("camera_permission_denied")
        }
    }

    private func presentScanner(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            let scanner = ToGetQrScannerViewController()
            scanner.modalPresentationStyle = .fullScreen
            scanner.onFinish = { result in
                switch result {
                case .success(let text):
                    call.resolve(["text": text])
                case .failure(let error):
                    if let scannerError = error as? ToGetQrScannerViewController.ScannerError,
                       scannerError == .cancelled {
                        call.reject("scan_cancelled")
                    } else {
                        call.reject("scan_failed")
                    }
                }
            }
            guard let controller = self.bridge?.viewController else {
                call.reject("scanner_unavailable")
                return
            }
            controller.present(scanner, animated: true)
        }
    }
}
